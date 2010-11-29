package DBIx::Skinny::Transaction;
use strict;
use warnings;
use Carp ();
use Try::Tiny;

sub new {
    my($class, $skinny) = @_;
    $skinny->txn_begin;
    bless [ 0, $skinny, ], $class;
}

sub rollback {
    return if $_[0]->[0];
    $_[0]->[1]->txn_rollback;
    $_[0]->[0] = 1;
}

sub commit {
    return if $_[0]->[0];
    $_[0]->[1]->txn_commit;
    $_[0]->[0] = 1;
}

sub DESTROY {
    my($dismiss, $skinny) = @{ $_[0] };
    return if $dismiss;

    Carp::carp('do rollback');

    try {
        $skinny->txn_rollback;
    } catch {
        die "Rollback failed: $_";
    };
}

1;

__END__

=head1 NAME

DBIx::Skinny::Transaction - transaction manager for DBIx::Skinny

=head1 SYNOPSIS

  sub do_work {
      my $txn = Your::Model->txn_scope; # start transaction

      my $row = Your::Model->single('user', {id => 1});
      $row->set({name => 'nekokak'});
      $row->update;

      $txn->commit; # commit
  }

=head1 SEE ALSO

L<Data::Model>

