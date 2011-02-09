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
    $txn->commit;

    if (fork) {
        wait;
        my $row = Mock::Basic->single('mock_basic',{name => 'lestrrat'});
        ok not $row;

        is $dbh, +Mock::Basic->dbh;
        is $txn_manager, +Mock::Basic->txn_manager;

        done_testing;
    } else {
        my $txn = Mock::Basic->txn_scope;

            isnt $dbh, Mock::Basic->dbh;
            isnt $dbh, $txn->[1]->{dbh};
            isnt $txn_manager, +Mock::Basic->txn_manager;

            my $row = Mock::Basic->insert('mock_basic',{
                id   => 2,
                name => 'ruby',
            });
            isa_ok $row, 'DBIx::Skinny::Row';
            is $row->name, 'ruby';

        $txn->rollback;
    }

unlink $db;

