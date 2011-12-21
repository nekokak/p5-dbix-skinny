use strict;
use Test::More;
use t::Utils;
use Mock::Basic;

subtest 'use transaction, disconnect, reconnect and use transaction again' => sub {
    my %connect_info = (
        dsn => 'dbi:SQLite::memory:',
        connect_options => {RaiseError => 1, AutoCommit => 1},
    );
    my $model = Mock::Basic->new(\%connect_info);

    eval {
        $model->txn_begin();
        $model->txn_rollback();
    };
    ok !$@, "regular txn begin, then rollback - should be clean" . ( $@ ? ", but got $@" : '');

    ok $model->_attributes->{dbh}, "dbh should be defined";
    ok $model->_attributes->{txn_manager}, "txn manager should be defined";

    eval {
        $model->disconnect();
    };
    ok !$@, "regular disconnect - should be clean" . ( $@ ? ", but got $@" : '');

    ok ! $model->_attributes->{dbh}, "dbh should be undefined";
    if (! ok ! $model->_attributes->{txn_manager}, "txn manager should be undefined" ) {
        # What, txn_manager still exists?!
        # Emulate this: long time passes... txn_manager and its dbh is
        # still dangling... and mysql server disconnects
        my $tm = $model->_attributes->{txn_manager};
        if (my $dbh = $tm->{dbh}) {
            $dbh->disconnect;
        }
    }

    eval {
        $model->connect();
    };
    ok !$@, "regular connect - should be clean" . ( $@ ? ", but got $@" : '' );

    eval {
        $model->txn_begin();
        $model->txn_rollback();
    };
    ok !$@, "regular txn (again) - should be clean" . ($@ ? ", but got $@" : '');
};

done_testing;
