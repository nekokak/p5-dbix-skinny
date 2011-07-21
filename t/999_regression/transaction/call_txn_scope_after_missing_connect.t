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

    {
        {
            my $txn = Mock::Basic->txn_scope;
                my $row = Mock::Basic->insert('mock_basic',{
                    id   => 2,
                    name => 'ruby',
                });
                isa_ok $row, 'DBIx::Skinny::Row';
                is $row->name, 'ruby';
            $txn->commit;
        }

        Mock::Basic->dbh->disconnect; # missing connect

        {
            my $txn = Mock::Basic->txn_scope;
                my $row = Mock::Basic->single('mock_basic',{name => 'ruby'});
                is $row->id, 2;
                $row = Mock::Basic->insert('mock_basic',{
                    id   => 3,
                    name => 'perl',
                });
                isa_ok $row, 'DBIx::Skinny::Row';
                is $row->name, 'perl';
            $txn->commit;
        }
    }

unlink $db;
done_testing;
