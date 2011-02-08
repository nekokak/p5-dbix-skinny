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

    my $txn = Mock::Basic->txn_scope;

    if (fork) {
        wait;
        done_testing;
    } else {
        eval {
            my $txn = Mock::Basic->txn_scope;
        };
        like $@, qr/Detected disconnected database during a transaction. Refusing to proceed at/;
    }

    $txn->commit;

unlink $db;

