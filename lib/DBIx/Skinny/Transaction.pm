package DBIx::Skinny::Transaction;
use strict;
use warnings;

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

    {
        local $@;
        eval { $skinny->txn_rollback };
        my $rollback_exception = $@;
        if($rollback_exception) {
            die "Rollback failed: ${rollback_exception}";
        }
    }
}

1;

