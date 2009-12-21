package DBIx::Skinny;
use strict;
use warnings;

our $VERSION = '0.05';

use DBI;
use DBIx::Skinny::Iterator;
use DBIx::Skinny::DBD;
use DBIx::Skinny::Row;
use DBIx::Skinny::Profiler;
use DBIx::Skinny::Transaction;
use Digest::SHA1;
use Carp ();
use Storable;

sub import {
    my ($class, %opt) = @_;

    my $caller = caller;
    my $args   = $opt{setup}||+{};

    my $schema = "$caller\::Schema";

    my $dbd_type = _dbd_type($args);
    my $_attribute = +{
        dsn             => $args->{dsn},
        username        => $args->{username},
        password        => $args->{password},
        connect_options => $args->{connect_options},
        dbh             => $args->{dbh}||undef,
        dbd             => $dbd_type ? DBIx::Skinny::DBD->new($dbd_type) : undef,
        schema          => $schema,
        profiler        => DBIx::Skinny::Profiler->new,
        profile         => $ENV{SKINNY_PROFILE}||0,
        klass           => $caller,
        row_class_map   => +{},
        active_transaction => 0,
    };

    {
        no strict 'refs';
        *{"$caller\::attribute"} = sub { ref $_[0] ? $_[0] : $_attribute };

        my @functions = qw/
            new
            schema profiler
            dbh dbd connect connect_info _dbd_type reconnect set_dbh setup_dbd
            call_schema_trigger
            do resultset search single search_by_sql search_named count
            data2itr find_or_new
                _get_sth_iterator _mk_row_class _camelize _mk_anon_row_class _guess_table_name
            insert bulk_insert create update delete find_or_create find_or_insert
            update_by_sql delete_by_sql
                _add_where
            _execute _close_sth _stack_trace
            txn_scope txn_begin txn_rollback txn_commit txn_end
        /;
        for my $func (@functions) {
            *{"$caller\::$func"} = \&$func;
        }
    }

    eval "use $schema"; ## no critic
    if ( $@ ) {
        # accept schema class declaration within base class.
        (my $schema_file = $schema) =~ s|::|/|g;
        die $@ if $@ && $@ !~ /Can't locate $schema_file\.pm in \@INC/;
    }

    strict->import;
    warnings->import;
}

sub new {
    my ($class, $connection_info) = @_;
    my $attr = $class->attribute;

    my $dbd      = delete $attr->{dbd};
    my $profiler = delete $attr->{profiler};
    my $dbh      = delete $attr->{dbh};
    my $connect_options = delete $attr->{connect_options};

    my $self = bless Storable::dclone($attr), $class;
    if ($connection_info) {
        $self->connect_info($connection_info);
        $self->reconnect;
    } else {
        $self->attribute->{dbd} = $dbd;
        $self->attribute->{dbh} = $dbh;
        $self->attribute->{connect_options} = $connect_options;
    }
    $self->attribute->{profiler} = $profiler;
    $attr->{dbd}      = $dbd;
    $attr->{dbh}      = $dbh;
    $attr->{profiler} = $profiler;

    return $self;
}

sub schema { shift->attribute->{schema} }
sub profiler {
    my ($class, $sql, $bind) = @_;
    my $attr = $class->attribute;
    if ($attr->{profile} && $sql) {
        $attr->{profiler}->record_query($sql, $bind);
    }
    return $attr->{profiler};
}

#--------------------------------------------------------------------------------
# for transaction
sub txn_scope {
    Carp::croak "The 'txn_scope' method can not be performed during a transaction." if $_[0]->attribute->{active_transaction};
    DBIx::Skinny::Transaction->new( @_ );
}

sub txn_begin {
    my $class = shift;
    $class->attribute->{active_transaction} = 1;
    eval { $class->dbh->begin_work } or Carp::croak $@;
}

sub txn_rollback {
    my $class = shift;
    return unless $class->attribute->{active_transaction};
    eval { $class->dbh->rollback } or Carp::croak $@;
    $class->txn_end;
}

sub txn_commit {
    my $class = shift;
    return unless $class->attribute->{active_transaction};
    eval { $class->dbh->commit } or Carp::croak $@;
    $class->txn_end;
}

sub txn_end {
    $_[0]->attribute->{active_transaction} = 0;
}

#--------------------------------------------------------------------------------
# db handling
sub connect_info {
    my ($class, $connect_info) = @_;

    my $attr = $class->attribute;
    $attr->{dsn} = $connect_info->{dsn};
    $attr->{username} = $connect_info->{username};
    $attr->{password} = $connect_info->{password};
    $attr->{connect_options} = $connect_info->{connect_options};

    $class->setup_dbd($connect_info);
}

sub connect {
    my $class = shift;

    $class->connect_info(@_) if scalar @_ >= 1;

    my $attr = $class->attribute;
    $attr->{dbh} ||= DBI->connect(
        $attr->{dsn},
        $attr->{username},
        $attr->{password},
        { RaiseError => 1, PrintError => 0, AutoCommit => 1, %{ $attr->{connect_options} || {} } }
    );
    $attr->{dbh};
}

sub reconnect {
    my $class = shift;
    $class->attribute->{dbh} = undef;
    $class->connect(@_);
}

sub set_dbh {
    my ($class, $dbh) = @_;
    $class->attribute->{dbh} = $dbh;
    $class->setup_dbd({dbh => $dbh});
}

sub setup_dbd {
    my ($class, $args) = @_;
    my $dbd_type = _dbd_type($args);
    $class->attribute->{dbd} = DBIx::Skinny::DBD->new($dbd_type);
}

sub dbd { shift->attribute->{dbd} }
sub dbh {
    my $class = shift;

    my $dbh = $class->connect;
    unless ($dbh && $dbh->FETCH('Active') && $dbh->ping) {
        $dbh = $class->reconnect;
    }
    $dbh;
}

sub _dbd_type {
    my $args = shift;
    my $dbd_type;
    if ($args->{dbh}) {
        $dbd_type = $args->{dbh}->{Driver}->{Name};
    } elsif ($args->{dsn}) {
        (undef, $dbd_type,) = DBI->parse_dsn($args->{dsn}) or Carp::croak "can't parse DSN: @{[ $args->{dsn} ]}";
    }
    return $dbd_type;
}

#--------------------------------------------------------------------------------
# schema trigger call
sub call_schema_trigger {
    my ($class, $trigger, $schema, $table, $args) = @_;
    $schema->call_trigger($class, $table, $trigger, $args);
}

#--------------------------------------------------------------------------------
sub do {
    my ($class, $sql) = @_;
    $class->profiler($sql);
    $class->dbh->do($sql);
}

sub count {
    my ($class, $table, $column, $where) = @_;

    my $rs = $class->resultset(
        {
            from   => [$table],
        }
    );

    $rs->add_select("COUNT($column)" =>  'cnt');
    $class->_add_where($rs, $where);

    $rs->retrieve->first->cnt;
}

sub resultset {
    my ($class, $args) = @_;
    $args->{skinny} = $class;

    my $query_builder_class = $class->dbd->query_builder_class;
    $query_builder_class->new($args);
}

sub search {
    my ($class, $table, $where, $opt) = @_;

    my $cols = $opt->{select} || $class->schema->schema_info->{$table}->{columns};
    my $rs = $class->resultset(
        {
            select => $cols,
            from   => [$table],
        }
    );

    if ( $where ) {
        $class->_add_where($rs, $where);
    }

    $rs->limit(  $opt->{limit}  ) if $opt->{limit};
    $rs->offset( $opt->{offset} ) if $opt->{offset};

    if (my $terms = $opt->{order_by}) {
        $terms = [$terms] unless ref($terms) eq 'ARRAY';
        my @orders;
        for my $term (@{$terms}) {
            my ($col, $case);
            if (ref($term) eq 'HASH') {
                ($col, $case) = each %$term;
            } else {
                $col  = $term;
                $case = 'ASC';
            }
            push @orders, { column => $col, desc => $case };
        }
        $rs->order(\@orders);
    }

    if (my $terms = $opt->{having}) {
        for my $col (keys %$terms) {
            $rs->add_having($col => $terms->{$col});
        }
    }

    $rs->retrieve;
}

sub single {
    my ($class, $table, $where, $opt) = @_;
    $opt->{limit} = 1;
    $class->search($table, $where, $opt)->first;
}

sub search_named {
    my ($class, $sql, $args, $opts, $opt_table_info) = @_;

    $sql = sprintf($sql, @{$opts||[]});
    my %named_bind = %{$args};
    my @bind;
    $sql =~ s{:([A-Za-z_][A-Za-z0-9_]*)}{
        Carp::croak("$1 is not exists in hash") if !exists $named_bind{$1};
        push @bind, $named_bind{$1};
        '?'
    }ge;

    $class->search_by_sql($sql, \@bind, $opt_table_info);
}

sub search_by_sql {
    my ($class, $sql, $bind, $opt_table_info) = @_;

    $class->profiler($sql, $bind);
    my $sth = $class->_execute($sql, $bind);
    return $class->_get_sth_iterator($sql, $sth, $opt_table_info);
}

sub find_or_new {
    my ($class, $table, $args) = @_;
    my $row = $class->single($table, $args);
    unless ($row) {
        $row = $class->data2itr($table, [$args])->first;
    }
    return $row;
}

sub _get_sth_iterator {
    my ($class, $sql, $sth, $opt_table_info) = @_;

    return DBIx::Skinny::Iterator->new(
        skinny         => $class,
        sth            => $sth,
        row_class      => $class->_mk_row_class($sql, $opt_table_info),
        opt_table_info => $opt_table_info
    );
}

sub data2itr {
    my ($class, $table, $data) = @_;

    return DBIx::Skinny::Iterator->new(
        skinny         => $class,
        data           => $data,
        row_class      => $class->_mk_row_class($table.$data, $table),
        opt_table_info => $table,
    );
}

sub _mk_anon_row_class {
    my ($class, $key, $base_row_class) = @_;

    my $row_class = "${base_row_class}::C";
    $row_class .= Digest::SHA1::sha1_hex($key);

    { no strict 'refs'; @{"$row_class\::ISA"} = ($base_row_class); }

    return $row_class;
}

sub _guess_table_name {
    my ($class, $sql) = @_;

    if ($sql =~ /^.+from\s+([\w]+)\s/i) {
        return $1;
    }
    return;
}

sub _mk_row_class {
    my ($class, $key, $table) = @_;

    $table ||= $class->_guess_table_name($key)||'';
    my $attr = $class->attribute;
    my $base_row_class = $attr->{row_class_map}->{$table}||'';

    if ( $base_row_class eq 'DBIx::Skinny::Row' ) {
        return $class->_mk_anon_row_class($key, $base_row_class);
    } elsif ($base_row_class) {
        return $base_row_class;
    } elsif ($table) {
        my $tmp_base_row_class = join '::', $attr->{klass}, 'Row', _camelize($table);
        eval "use $tmp_base_row_class"; ## no critic
        if ($@) {
            $attr->{row_class_map}->{$table} = 'DBIx::Skinny::Row';
            return $class->_mk_anon_row_class($key, $attr->{row_class_map}->{$table});
        } else {
            $attr->{row_class_map}->{$table} = $tmp_base_row_class;
            return $tmp_base_row_class;
        }
    } else {
        return $class->_mk_anon_row_class($key, 'DBIx::Skinny::Row');
    }
}

sub _camelize {
    my $s = shift;
    join('', map{ ucfirst $_ } split(/(?<=[A-Za-z])_(?=[A-Za-z])|\b/, $s));
}

sub _quote {
    my ($label, $quote, $name_sep) = @_;

    return $label if $label eq '*';
    return $quote . $label . $quote if !defined $name_sep;
    return join $name_sep, map { $quote . $_ . $quote } split /\Q$name_sep\E/, $label;
}

*create = \*insert;
sub insert {
    my ($class, $table, $args) = @_;

    my $schema = $class->schema;
    $class->call_schema_trigger('pre_insert', $schema, $table, $args);

    # deflate
    for my $col (keys %{$args}) {
        $args->{$col} = $schema->call_deflate($col, $args->{$col});
    }

    my (@cols,@bind);
    for my $col (keys %{ $args }) {
        push @cols, $col;
        push @bind, $schema->utf8_off($col, $args->{$col});
    }

    my $dbd = $class->dbd;
    # TODO: INSERT or REPLACE. bind_param_attributes etc...
    my $quote = $dbd->quote;
    my $name_sep = $dbd->name_sep;
    my $sql = "INSERT INTO $table\n";
    $sql .= '(' . join(', ', map {_quote($_, $quote, $name_sep)} @cols) . ')' . "\n" .
            'VALUES (' . join(', ', ('?') x @cols) . ')' . "\n";

    $class->profiler($sql, \@bind);
    my $sth = $class->_execute($sql, \@bind);

    my $pk = $class->schema->schema_info->{$table}->{pk};
    my $id = defined $args->{$pk}
        ? $args->{$pk}
        : $dbd->last_insert_id($class->dbh, $sth, { table => $table });
    $class->_close_sth($sth);

    $args->{$pk} = $id;
    my $row_class = $class->_mk_row_class($sql, $table);
    my $obj = $row_class->new(
        {
            row_data       => $args,
            skinny         => $class,
            opt_table_info => $table,
        }
    );
    $obj->setup;

    $class->call_schema_trigger('post_insert', $schema, $table, $obj);

    $obj;
}

sub bulk_insert {
    my ($class, $table, $args) = @_;

    my $code = $class->attribute->{dbd}->can('bulk_insert') or Carp::croak "dbd don't provide bulk_insert method";
    $code->($class, $table, $args);
}

sub update {
    my ($class, $table, $args, $where) = @_;

    my $schema = $class->schema;
    $class->call_schema_trigger('pre_update', $schema, $table, $args);

    # deflate
    my $values = {};
    for my $col (keys %{$args}) {
        $values->{$col} = $schema->call_deflate($col, $args->{$col});
    }

    my $quote = $class->dbd->quote;
    my $name_sep = $class->dbd->name_sep;
    my (@set,@bind);
    for my $col (keys %{ $args }) {
        my $quoted_col = _quote($col, $quote, $name_sep);
        if (ref($values->{$col}) eq 'SCALAR') {
            push @set, "$quoted_col = " . ${ $values->{$col} };
        } else {
            push @set, "$quoted_col = ?";
            push @bind, $schema->utf8_off($col, $values->{$col});
        }
    }

    my $stmt = $class->resultset;
    $class->_add_where($stmt, $where);
    push @bind, @{ $stmt->bind };

    my $sql = "UPDATE $table SET " . join(', ', @set) . ' ' . $stmt->as_sql_where;

    $class->profiler($sql, \@bind);
    my $sth = $class->dbh->prepare($sql);
    my $rows = $sth->execute(@bind);

    $class->_close_sth($sth);
    $class->call_schema_trigger('post_update', $schema, $table, $rows);

    return $rows;
}

sub update_by_sql {
    my ($class, $sql, $bind) = @_;

    $class->profiler($sql, $bind);
    my $sth = $class->dbh->prepare($sql);
    my $rows = $sth->execute(@$bind);
    $class->_close_sth($sth);

    $rows;
}

sub delete {
    my ($class, $table, $where) = @_;

    my $schema = $class->schema;
    $class->call_schema_trigger('pre_delete', $schema, $table, $where);

    my $stmt = $class->resultset(
        {
            from   => [$table],
        }
    );

    $class->_add_where($stmt, $where);

    my $sql = "DELETE " . $stmt->as_sql;
    $class->profiler($sql, $stmt->bind);
    my $sth = $class->_execute($sql, $stmt->bind);

    $class->call_schema_trigger('post_delete', $schema, $table);

    my $ret = $sth->rows;
    $class->_close_sth($sth);
    $ret;
}

sub delete_by_sql {
    my ($class, $sql, $bind) = @_;

    $class->profiler($sql, $bind);
    my $sth = $class->dbh->prepare($sql);
    my $ret = $sth->execute(@$bind);
    $class->_close_sth($sth);

    $ret;
}

*find_or_insert = \*find_or_create;
sub find_or_create {
    my ($class, $table, $args) = @_;
    my $row = $class->single($table, $args);
    return $row if $row;
    $row = $class->insert($table, $args);
    return $row;
}

sub _add_where {
    my ($class, $stmt, $where) = @_;
    for my $col (keys %{$where}) {
        $stmt->add_where($col => $where->{$col});
    }
}

sub _execute {
    my ($class, $stmt, $bind) = @_;

    my $sth;
    eval {
        $sth = $class->dbh->prepare($stmt);
        $sth->execute(@{$bind});
    };
    if ($@) {
        $class->_stack_trace($sth, $stmt, $bind, $@);
    }
    return $sth;
}

# stack trace
sub _stack_trace {
    my ($class, $sth, $stmt, $bind, $reason) = @_;
    require Data::Dumper;

    if ($sth) {
        $class->_close_sth($sth);
    }

    $stmt =~ s/\n/\n          /gm;
    Carp::croak sprintf <<"TRACE", $reason, $stmt, Data::Dumper::Dumper($bind);
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@ DBIx::Skinny 's Exception @@@@@
Reason  : %s
SQL     : %s
BIND    : %s
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TRACE
}

sub _close_sth {
    my ($class, $sth) = @_;
    $sth->finish;
    undef $sth;
}

1;

__END__
=head1 NAME

DBIx::Skinny - simple DBI wrapper/ORMapper

=head1 SYNOPSIS

    package Your::Model;
    use DBIx::Skinny setup => {
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
    };
    1;
    
    package Your::Model::Schema;
    use DBIx::Skinny::Schema;
    
    install_table user => schema {
        pk 'id';
        columns qw/
            id
            name
        /;
    };
    1;
    
    # in your script:
    use Your::Model;
    
    # insert    
    my $row = Your::Model->insert('user',
        {
            id   => 1,
        }
    );
    $row->update({name => 'nekokak'});

    $row = Your::Model->search_by_sql(q{SELECT id, name FROM user WHERE id = ?}, [ 1 ]);
    $row->delete('user')

=head1 DESCRIPTION

DBIx::Skinny is simple DBI wrapper and simple O/R Mapper.

=head1 METHOD

=head2 new

create your skinny instance.

It is possible to use it even by the class method.

my $db = Your::Model->new($connection_info);

$connection_info is optional argment.

When $connection_info is specified,
new method connect new DB connection from $connection_info.

When $connection_info is not specified,
it becomes use already setup connection or it doesn't do at all.

example:

    my $db = Your::Model->new;

or

    # connect new database connection.
    my $db = Your::Model->new(+{
        dsn      => $dsn,
        username => $username,
        password => $password,
        connect_options => $connect_options,
    });

=head2 insert

insert new record and get inserted row object.

my $row = Your::Model->insert($table, \%row_data);

return object is a DBIx::Skinny::Row's object.

example:

    my $row = Your::Model->insert('user',{
        id   => 1,
        name => 'nekokak',
    });

or

    my $db = Your::Model->new;
    my $row = $db->insert('user',{
        id   => 1,
        name => 'nekokak',
    });

=head2 bulk_insert

insert many record.

Your::Model->bulk_insert($table, \@rows);

example:

    Your::Model->bulk_insert('user',[
        {
            id   => 1,
            name => 'nekokak',
        },
        {
            id   => 2,
            name => 'yappo',
        },
        {
            id   => 3,
            name => 'walf443',
        },
    ]);

=head2 create

insert method alias.

=head2 update

update record. return update row count.

my $cnt = Your::Model->update($table, \%update_column);

example:

    my $update_row_count = Your::Model->update('user',{
        name => 'nomaneko',
    },{ id => 1 });

=head2 update_by_sql

update record by specific sql. return update row count.

example:
    my $update_row_count = Your::Model->update_by_sql(
        q{UPDATE user SET name = ?},
        'nomaneko'
    );

=head2 delete

delete record. return delete row count.

my $cnt = Your::Model->delete($table, \%delete_where_condition);

example:
    my $delete_row_count = Your::Model->delete('user',{
        id => 1,
    });

=head2 delete_by_sql

delete record by specific sql. return delete row count.

example:

    my $delete_row_count = Your::Model->delete_by_sql(
        q{DELETE FROM user WHERE id = ?},
        [1]
    });

=head2 find_or_create

create record if not exsists record.

my $row = Your::Model->find_or_create($table, \%row);

return object is a DBIx::Skinny::Row's object.

example:

    my $row = Your::Model->find_or_create('usr',{
        id   => 1,
        name => 'nekokak',
    });

=head2 find_or_insert

find_or_create method alias.

=head2 search

simple search method.

get iterator:

    my $itr = Your::Model->search('user',{id => 1},{order_by => 'id'});

get rows:

    my @rows = Your::Model->search('user',{id => 1},{order_by => 'id'});

=head2 single

get one record

    my $row = Your::Model->single('user',{id =>1});

=head2 resultset

result set case:

    my $rs = Your::Model->resultset(
        {
            select => [qw/id name/],
            from   => [qw/user/],
        }
    );
    $rs->add_where('name' => {op => 'like', value => "%neko%"});
    $rs->limit(10);
    $rs->offset(10);
    $rs->order({ column => 'id', desc => 'DESC' });
    my $itr = $rs->retrieve;

=head2 count

get simple count

    my $cnt = Your::Model->count('user', 'id');

=head2 search_named

execute named query

    my $itr = Your::Model->search_named(q{SELECT * FROM user WHERE id = :id}, {id => 1});

=head2 search_by_sql

execute your SQL

    my $itr = Your::Model->search_by_sql(q{
        SELECT
            id, name
        FROM
            user
        WHERE
            id = ?
    },[ 1 ]);

=head2 txn_scope

get transaction scope object.

    do {
        my $txn = Your::Model->txn_scope;
        # some process
        $txn->commit;
    }

=head2 data2itr

    my $itr = Your::Model->data2itr('user',[
        {
            id   => 1,
            name => 'nekokak',
        },
        {
            id   => 2,
            name => 'yappo',
        },
        {
            id   => 3,
            name => 'walf43',
        },
    ]);

    my $row = $itr->first;
    $row->insert; # inser data.

=head2 find_or_new

    my $row = Your::Model->find_or_new('user',{name => 'nekokak'});

=head2 do

execute your query.

=head2 dbh

get database handle.

=head2 connect

connect database handle.

=head2 reconnect

re connect database handle.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Atsushi Kobayashi  C<< <nekokak __at__ gmail.com> >>

=head1 CONTRIBUTORS

walf443 : Keiji Yoshimi

TBONE : Terrence Brannon

nekoya : Ryo Miyake

oinume: Kazuhiro Oinuma

fujiwara: Shunichiro Fujiwara

pjam: Tomoyuki Misonou

=head1 REPOSITORY

  git clone git://github.com/nekokak/p5-dbix-skinny.git  

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Atsushi Kobayashi C<< <nekokak __at__ gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

