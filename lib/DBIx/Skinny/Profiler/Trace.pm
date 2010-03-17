package DBIx::Skinny::Profiler::Trace;
use strict;
use warnings;
 
sub new {
    my $class = shift;
 
    my $self = bless {}, $class;
    my $env = $ENV{SKINNY_TRACE};
 
    my $fh;
    if ( $env && $env =~ /=(.+)$/ ) {
        my $fname = $1;
        open( $fh, '>>', $fname ) or die("cannot open '$fname': $!");
    }
    else {
        $fh = *STDERR;
    }
 
    $fh->autoflush();

    $self->{fh} = $fh;

    $self;
}
 
sub record_query {
    my ( $self, $sql, $bind ) = @_;
    my $log = _normalize($sql);
 
    if ( ref $bind eq 'ARRAY' ) {
        my @binds;
        push @binds, defined $_ ? $_ : 'undef' for @$bind;
        $log .= ' :binds ' . join ', ', @binds;
    }
 
    my $fh = $self->{fh};
    print $fh $log, "\n";
}
 
sub _normalize { # copied from origianl DBIx::Skinny::Profiler
    my $sql = shift;
    $sql =~ s/^\s*//;
    $sql =~ s/\s*$//;
    $sql =~ s/[\r\n]/ /g;
    $sql =~ s/\s+/ /g;
    return $sql;
}
 
1;
