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
    my $pid = fork();
    if ($pid) {
        wait;
        my $row = Mock::Basic->single('mock_basic',{name => 'ruby'});
        is $row->id, 2, "Found row with id 2 in parent";
        is $dbh, +Mock::Basic->dbh, "Found the same dbh in parent";

        unlink $db;
        done_testing;
    } else {
        my $txn = Mock::Basic->txn_scope;

            isnt $dbh, Mock::Basic->dbh, "dbh is different than main in child";
            isnt $dbh, $txn->[1]->{dbh}, "dbh from txn is different than main in child";

            my $row = Mock::Basic->insert('mock_basic',{
                id   => 2,
                name => 'ruby',
            });
            isa_ok $row, 'DBIx::Skinny::Row', "Inserted row in child";
            is $row->name, 'ruby', "Inserted row has name 'ruby'";

        $txn->commit;
    }
