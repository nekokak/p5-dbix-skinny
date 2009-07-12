package DBIx::Skinny::Iterator;
use strict;
use warnings;
use Scalar::Util qw(blessed);

sub new {
    my ($class, %args) = @_;

    my $self = bless \%args, $class;

    $self->reset;

    return wantarray ? $self->all : $self;
}

sub iterator {
    my $self = shift;

    my $potition = $self->{_potition} + 1;
    if ( my $row_cache = $self->{_rows_cache}->[$potition] ) {
        $self->{_potition} = $potition;
        return $row_cache;
    }

    my $row;
    if ($self->{sth}) {
        $row = $self->{sth}->fetchrow_hashref();
        unless ( $row ) {
            $self->{skinny}->_close_sth($self->{sth});
            $self->{sth} = undef;
            return;
        }
    } elsif ($self->{data} && ref $self->{data} eq 'ARRAY') {
        $row = shift @{$self->{data}};
        unless ( $row ) {
            return;
        }
    } else {
        return;
    }

    return $row if Scalar::Util::blessed($row);

    my $obj = $self->{row_class}->new(
        {
            row_data       => $row,
            skinny         => $self->{skinny},
            opt_table_info => $self->{opt_table_info},
        }
    );

    unless ($self->{_setup}) {
        $obj->setup;
        $self->{_setup}=1;
    }

    $self->{_rows_cache}->[$potition] = $obj;
    $self->{_potition} = $potition;

    return $obj;
}

sub first {
    my $self = shift;
    $self->reset;
    $self->next;
}

sub next { shift->iterator }

sub all {
    my $self = shift;
    my @result;
    while ( my $row = $self->next ) {
        push @result, $row;
    }
    return @result;
}

sub reset {
    my $self = shift;
    $self->{_potition} = 0;
    return $self;
}

sub count {
    my $self = shift;
    my @rows = $self->reset->all;
    $self->reset;
    scalar @rows;
}

1;

__END__
=head1 NAME

DBIx::Skinny::Iterator

=head1 DESCRIPTION

skinny iteration class.

=head1 SYNOPSIS

  my $itr = Your::Model->search('user',{});
  
  $itr->count; # show row counts
  
  my $row = $itr->first; # get first row
  
  $itr->reset; # reset itarator potision
  
  my @rows = $itr->all; # get all rows
  
  # do iteration
  while (my $row = $itr->next) { }

