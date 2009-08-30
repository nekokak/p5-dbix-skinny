use t::Utils;
use Mock::Inclusion;
use Test::Declare;

plan tests => blocks;

describe 'instance object test' => run {
    init {
        Mock::Inclusion->reconnect(
            {
                dsn => 'dbi:SQLite:./t/main.db',
                username => '',
                password => '',
            }
        );
        Mock::Inclusion->setup_test_db;
        Mock::Inclusion->insert('mock_inclusion',{
            id   => 1,
            name => 'perl',
        });
    };

    test 'search' => run {
        my $row = Mock::Inclusion->single('mock_inclusion',{id => 1});
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->id, 1;
        is $row->name, 'perl';
    };

    cleanup {
        unlink './t/main.db';
    };
};

