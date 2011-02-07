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

subtest 'txn_scope before fork' => sub {
    my $txn = Mock::Basic->txn_scope;
    $txn->commit;

    if (fork) {
        wait;
        my $row = Mock::Basic->single('mock_basic',{name => 'ruby'});
        is $row->id, 2;
        done_testing;
    } else {
        Mock::Basic->txn_manager_reset;
        my $txn = Mock::Basic->txn_scope;

            my $row = Mock::Basic->insert('mock_basic',{
                id   => 2,
                name => 'ruby',
            });
            isa_ok $row, 'DBIx::Skinny::Row';
            is $row->name, 'ruby';

        $txn->commit;
    }
};

unlink $db;

done_testing;

