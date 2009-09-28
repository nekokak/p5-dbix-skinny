package DBIx::Skinny::Row;
use strict;
use warnings;
use Carp;

sub new {
    my ($class, $args) = @_;
    my $self = bless {%$args}, $class;
    $self->{select_columns} = [keys %{$self->{row_data}}];
    return $self;
}

sub setup {
    my $self = shift;
    my $class = ref $self;

    for my $alias ( @{$self->{select_columns}} ) {
        (my $col = lc $alias) =~ s/.+\.(.+)/$1/o;
        next if $class->can($col);
        no strict 'refs';
        *{"$class\::$col"} = $self->_lazy_get_data($col);
    }

    $self->{_get_column_cached} = {};
    $self->{_dirty_columns} = {};
}

sub _lazy_get_data {
    my ($self, $col) = @_;

    return sub {
        my $self = shift;

        unless ( $self->{_get_column_cached}->{$col} ) {
          my $data = $self->get_column($col);
          $self->{_get_column_cached}->{$col} = $self->{skinny}->schema->call_inflate($col, $data);
        }
        $self->{_get_column_cached}->{$col};
    };
}

sub get_column {
    my ($self, $col) = @_;

    my $data = $self->{row_data}->{$col};

    $data = $self->{skinny}->schema->utf8_on($col, $data);

    return $data;
}

sub get_columns {
    my $self = shift;

    my %data;
    for my $col ( @{$self->{select_columns}} ) {
        $data{$col} = $self->get_column($col);
    }
    return \%data;
}

sub set {
    my ($self, $args) = @_;

    for my $col (keys %$args) {
        $self->{row_data}->{$col} = $args->{$col};
        delete $self->{_get_column_cached}->{$col};
        $self->{_dirty_columns}->{$col} = 1;
    }
}

sub get_dirty_columns {
    my $self = shift;
    my %rows = map {$_ => $self->get_column($_)}
               keys %{$self->{_dirty_columns}};
    return \%rows;
}

sub insert {
    my $self = shift;
    $self->{skinny}->find_or_create($self->{opt_table_info}, $self->get_columns);
}

sub update {
    my ($self, $args, $table) = @_;
    $table ||= $self->{opt_table_info};
    $args ||= $self->get_dirty_columns;
    my $where = $self->_update_or_delete_cond($table);
    $self->set($args);
    $self->{skinny}->update($table, $args, $where);
}

sub delete {
    my ($self, $table) = @_;
    $table ||= $self->{opt_table_info};
    my $where = $self->_update_or_delete_cond($table);
    $self->{skinny}->delete($table, $where);
}

sub _update_or_delete_cond {
    my ($self, $table) = @_;

    unless ($table) {
        croak "no table info";
    }

    my $schema_info = $self->{skinny}->schema->schema_info;
    unless ( $schema_info->{$table} ) {
        croak "unknown table: $table";
    }

    # get target table pk
    my $pk = $schema_info->{$table}->{pk};
    unless ($pk) {
        croak "$table have no pk.";
    }

    unless (grep { $pk eq $_ } @{$self->{select_columns}}) {
        croak "can't get primary column in your query.";
    }

    return +{ $pk => $self->$pk };
}

1;

__END__
=head1 NAME

DBIx::Skinny::Row - DBIx::Skinny's Row class

=head1 METHODS

=head2 get_column

    my $val = $row->get_column($col);

get a column value from a row object.

=head2 get_columns

    my %data = $row->get_columns;

Does C<get_column>, for all column values.

=head2 set

    $row->set({$col => $val});

set columns data.

=head2 get_dirty_columns

returns those that have been changed.

=head2 insert

insert row data. call find_or_create method.

=head2 update

update is executed for instance record.

It works by schema in which primary key exists.

=head2 delete

delete is executed for instance record.

It works by schema in which primary key exists.

