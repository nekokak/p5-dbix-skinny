package DBIx::Skinny::SQL;
use strict;
use warnings;
use DBIx::Skinny::Accessor;

mk_accessors(
    qw/
        select distinct select_map select_map_reverse
        from joins where bind limit offset group order
        having where_values column_mutator index_hint
        comment
        skinny
    /
);

sub init {
    my $self = shift;

    for my $name (qw/ select from joins bind group order where having /) {
        unless ($self->$name && ref $self->$name eq 'ARRAY') {
            $self->$name ? $self->$name([ $self->$name ]) : $self->$name([]);
        }
    }
    for my $name (qw/ select_map select_map_reverse where_values index_hint/) {
        $self->$name( {} ) unless $self->$name && ref $self->$name eq 'HASH';
    }

    $self->distinct(0) unless $self->distinct;

    $self;
}

sub add_select {
    my $self = shift;
    my($term, $col) = @_;
    $col ||= $term;
    push @{ $self->select }, $term;
    $self->select_map->{$term} = $col;
    $self->select_map_reverse->{$col} = $term;
}

sub add_join {
    my $self = shift;
    my($table, $joins) = @_;
    push @{ $self->joins }, {
        table => $table,
        joins => ref($joins) eq 'ARRAY' ? $joins : [ $joins ],
    };
}

sub add_index_hint {
    my $self = shift;
    my($table, $hint) = @_;
    $self->index_hint->{$table} = {
        type => $hint->{type} || 'USE',
        list => ref($hint->{list}) eq 'ARRAY' ? $hint->{list} : [ $hint->{list} ],
    };
}

sub as_sql {
    my $self = shift;
    my $sql = '';
    if (@{ $self->select }) {
        $sql .= 'SELECT ';
        $sql .= 'DISTINCT ' if $self->distinct;
        $sql .= join(', ',  map {
            my $alias = $self->select_map->{$_};
            !$alias                         ? $_ :
            $alias && /(?:^|\.)\Q$alias\E$/ ? $_ : "$_ $alias";
        } @{ $self->select }) . "\n";
    }

    $sql .= 'FROM ';

    ## Add any explicit JOIN statements before the non-joined tables.
    if ($self->joins && @{ $self->joins }) {
        my $initial_table_written = 0;
        for my $j (@{ $self->joins }) {
            my($table, $joins) = map { $j->{$_} } qw( table joins );
            $table = $self->_add_index_hint($table); ## index hint handling
            $sql .= $table unless $initial_table_written++;
            for my $join (@{ $j->{joins} }) {
                $sql .= ' ' .
                        uc($join->{type}) . ' JOIN ' . $join->{table} . ' ON ' .
                        $join->{condition};
            }
        }
        $sql .= ', ' if @{ $self->from };
    }

    if ($self->from && @{ $self->from }) {
        $sql .= join ', ', map { $self->_add_index_hint($_) } @{ $self->from };
    }

    $sql .= "\n";
    $sql .= $self->as_sql_where;

    $sql .= $self->as_aggregate('group');
    $sql .= $self->as_sql_having;
    $sql .= $self->as_aggregate('order');

    $sql .= $self->as_limit;
    my $comment = $self->comment;
    if ($comment && $comment =~ /([ 0-9a-zA-Z.:;()_#&,]+)/) {
        $sql .= "-- $1" if $1;
    }
    return $sql;
}

sub as_limit {
    my $self = shift;
    my $n = $self->limit or
        return '';
    die "Non-numerics in limit clause ($n)" if $n =~ /\D/;
    return sprintf "LIMIT %d%s\n", $n,
           ($self->offset ? " OFFSET " . int($self->offset) : "");
}

sub as_aggregate {
    my ($self, $set) = @_;

    return '' unless my $attribute = $self->$set();

    my $ref = ref $attribute;

    if ($ref eq 'ARRAY' && scalar @$attribute == 0) {
        return '';
    }

    my $elements = ($ref eq 'ARRAY') ? $attribute : [ $attribute ];
    return uc($set)
           . ' BY '
           . join(', ', map { $_->{column} . ($_->{desc} ? (' ' . $_->{desc}) : '') } @$elements)
           . "\n";
}

sub as_sql_where {
    my $self = shift;
    $self->where && @{ $self->where } ?
        'WHERE ' . join(' AND ', @{ $self->where }) . "\n" :
        '';
}

sub as_sql_having {
    my $self = shift;
    $self->having && @{ $self->having } ?
        'HAVING ' . join(' AND ', @{ $self->having }) . "\n" :
        '';
}

sub add_where {
    my $self = shift;
    ## xxx Need to support old range and transform behaviors.
    my($col, $val) = @_;
    Carp::croak("Invalid/unsafe column name $col") unless $col =~ /^[\w\.]+$/;
    my($term, $bind, $tcol) = $self->_mk_term($col, $val);
    push @{ $self->{where} }, "($term)";
    push @{ $self->{bind} }, @$bind;
    $self->where_values->{$tcol} = $val;
}

sub add_complex_where {
    my $self = shift;
    my ($terms) = @_;
    my ($where, $bind) = $self->_parse_array_terms($terms);
    push @{ $self->{where} }, $where;
    push @{ $self->{bind} }, @$bind;
}

sub _parse_array_terms {
    my $self = shift;
    my ($term_list) = @_;

    my @out;
    my $logic = 'AND';
    my @bind;
    foreach my $t ( @$term_list ) {
        if (! ref $t ) {
            $logic = $1 if uc($t) =~ m/^-?(OR|AND|OR_NOT|AND_NOT)$/;
            $logic =~ s/_/ /;
            next;
        }
        my $out;
        if (ref $t eq 'HASH') {
            # bag of terms to apply $logic with
            my @out;
            foreach my $t2 ( keys %$t ) {
                my ($term, $bind, $col) = $self->_mk_term($t2, $t->{$t2});
                $self->where_values->{$col} = $t->{$t2};
                push @out, $term;
                push @bind, @$bind;
            }
            $out .= '(' . join(" AND ", @out) . ")";
        }
        elsif (ref $t eq 'ARRAY') {
            # another array of terms to process!
            my ($where, $bind) = $self->_parse_array_terms( $t );
            push @bind, @$bind;
            $out = '(' . $where . ')';
        }
        push @out, (@out ? ' ' . $logic . ' ' : '') . $out;
    }
    return (join("", @out), \@bind);
}

sub has_where {
    my $self = shift;
    my($col, $val) = @_;

    # TODO: should check if the value is same with $val?
    exists $self->where_values->{$col};
}

sub add_having {
    my $self = shift;
    my($col, $val) = @_;

    if (my $orig = $self->select_map_reverse->{$col}) {
        $col = $orig;
    }

    my($term, $bind) = $self->_mk_term($col, $val);
    push @{ $self->{having} }, "($term)";
    push @{ $self->{bind} }, @$bind;
}

sub _mk_term {
    my $self = shift;
    my($col, $val) = @_;
    my $term = '';
    my (@bind, $m);
    if (ref($val) eq 'ARRAY') {
        if (ref $val->[0] or (($val->[0] || '') eq '-and')) {
            my $logic = 'OR';
            my @values = @$val;
            if ($val->[0] eq '-and') {
                $logic = 'AND';
                shift @values;
            }

            my @terms;
            for my $v (@values) {
                my($term, $bind) = $self->_mk_term($col, $v);
                push @terms, "($term)";
                push @bind, @$bind;
            }
            $term = join " $logic ", @terms;
        } else {
            $col = $m->($col) if $m = $self->column_mutator;
            $term = "$col IN (".join(',', ('?') x scalar @$val).')';
            @bind = @$val;
        }
    } elsif (ref($val) eq 'HASH') {
        my $c = $val->{column} || $col;
        $c = $m->($c) if $m = $self->column_mutator;

        my($op, $v) = (%{ $val });
        $op = uc($op);
        if (($op eq 'IN' || $op eq 'NOT IN') && ref($v) eq 'ARRAY') {
            $term = "$c $op (".join(',', ('?') x scalar @$v).')';
            @bind = @$v;
        } else {
            $term = "$c $op ?";
            push @bind, $v;
        }
    } elsif (ref($val) eq 'SCALAR') {
        $col = $m->($col) if $m = $self->column_mutator;
        $term = "$col $$val";
    } else {
        $col = $m->($col) if $m = $self->column_mutator;
        $term = "$col = ?";
        push @bind, $val;
    }
    ($term, \@bind, $col);
}

sub _add_index_hint {
    my $self = shift;
    my ($tbl_name) = @_;
    my $hint = $self->index_hint->{$tbl_name};
    return $tbl_name unless $hint && ref($hint) eq 'HASH';
    if ($hint->{list} && @{ $hint->{list} }) {
        return $tbl_name . ' ' . uc($hint->{type} || 'USE') . ' INDEX (' . 
                join (',', @{ $hint->{list} }) .
                ')';
    }
    return $tbl_name;
}

sub retrieve {
    my $self = shift;
    $self->skinny->search_by_sql($self->as_sql, $self->bind, $self->from->[0]);
}

'base code from Data::ObjectDriver::SQL';
