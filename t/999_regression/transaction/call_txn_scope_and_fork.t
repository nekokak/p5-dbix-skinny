use t::Utils;
use Mock::Basic;
use Test::More;
use Test::SharedFork;

my $db = './test.db';

unlink $db;
Mock::Basic->connect_info(+{
    dsn      => "dbi:SQLite:$db",
    username => '',
    password => '',
});
Mock::Basic->setup_test_db;

    my $dbh = Mock::Basic->dbh;
    my $txn_manager = Mock::Basic->txn_manager;

    my $txn = Mock::Basic->txn_scope;

    if (fork) {
        wait;
        is $dbh, +Mock::Basic->dbh;
        is $txn_manager, +Mock::Basic->txn_manager;

        unlink $db;
        done_testing;
    } else {
        eval {
            my $txn = Mock::Basic->txn_scope;
        };
        like $@, qr/Detected transaction while processing forked child \(last known transaction at/;
    }

    $txn->commit;
