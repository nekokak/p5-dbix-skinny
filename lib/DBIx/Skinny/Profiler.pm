package DBIx::Skinny::Profiler;
use strict;
use warnings;
use DBIx::Skinny::Accessor;

mk_accessors(qw/ query_log /);

sub init {
    my $self = shift;
    $self->reset;
}

sub reset {
    my $self = shift;
    $self->query_log([]);
}

sub _normalize {
    my $sql = shift;
    $sql =~ s/^\s*//;
    $sql =~ s/\s*$//;
    $sql =~ s/[\r\n]/ /g;
    $sql =~ s/\s+/ /g;
    return $sql;
}

sub record_query {
    my ($self, $sql, $bind) = @_;

    my $log = _normalize($sql);
    if (ref $bind eq 'ARRAY') {
        my @binds;
        push @binds, defined $_ ? $_ : 'undef' for @$bind;
        $log .= ' :binds ' . join ', ', @binds;
    }

    push @{ $self->query_log }, $log;
}

1;

