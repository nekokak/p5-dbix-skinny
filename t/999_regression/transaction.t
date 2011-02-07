use t::Utils;
use Mock::Basic;
use Test::More;

my $db = './test.db';

unlink $db;
Mock::Basic->connect_info(+{
    dsn      => "dbi:SQLite:$db",
    username => '',
    password => '',
});
Mock::Basic->setup_test_db;

subtest 'basic' => sub {

    if (fork) {
        wait;
        my $row = Mock::Basic->single('mock_basic');
        is $row->id, 1;
    } else {
        my $txn = Mock::Basic->txn_scope;

            my $row = Mock::Basic->insert('mock_basic',{
                id   => 1,
                name => 'perl',
            });
            isa_ok $row, 'DBIx::Skinny::Row';
            is $row->name, 'perl';

        $txn->commit;
    }
};

subtest 'use txn_scope before fork' => sub {
    my $txn = Mock::Basic->txn_scope;
    $txn->commit;

    if (fork) {
        wait;
        my $row = Mock::Basic->single('mock_basic');
        is $row->id, 1;
    } else {
        my $txn = Mock::Basic->txn_scope;

            my $row = Mock::Basic->insert('mock_basic',{
                id   => 1,
                name => 'perl',
            });
            isa_ok $row, 'DBIx::Skinny::Row';
            is $row->name, 'perl';

        $txn->commit;
    }
};

unlink $db;

done_testing;
