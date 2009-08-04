use t::Utils;
use Mock::Basic;
use Test::Declare;

plan tests => blocks;

describe 'instance object test' => run {
    init {
        Mock::Basic->reconnect(
            {
                dsn => 'dbi:SQLite:./t/main.db',
                username => '',
                password => '',
            }
        );
        Mock::Basic->setup_test_db;
        Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
        Mock::Basic->insert('mock_basic',{
            id   => 2,
            name => 'python',
        });
    };

    test 'search' => run {
        my $itr = Mock::Basic->search('mock_basic',{id => 1});
        isa_ok $itr, 'DBIx::Skinny::Iterator';

        my $row = $itr->first;
        isa_ok $row, 'DBIx::Skinny::Row';

        is $row->id, 1;
        is $row->name, 'perl';
    };

    test 'do new' => run {
        my $model = Mock::Basic->new;
        my $itr = $model->search('mock_basic');
        isa_ok $itr, 'DBIx::Skinny::Iterator';

        my $row = $itr->first;
        isa_ok $row, 'DBIx::Skinny::Row';

        is $row->id, 1;
        is $row->name, 'perl';
    };

    test 'do new other connection' => run {
        my $model = Mock::Basic->new(
            {
                dsn => 'dbi:SQLite:./t/other.db',
                username => '',
                password => '',
            }
        );
        $model->setup_test_db;
        $model->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });

        my $itr = $model->search('mock_basic');
        isa_ok $itr, 'DBIx::Skinny::Iterator';

        my $row = $itr->first;
        isa_ok $row, 'DBIx::Skinny::Row';

        is $row->id, 1;
        is $row->name, 'perl';

        is +Mock::Basic->count('mock_basic', 'id'), 2;
        is $model->count('mock_basic', 'id'), 1;
    };

    cleanup {
        unlink './t/other.db', './t/main.db';
    };
};

