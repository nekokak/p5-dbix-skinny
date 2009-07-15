use t::Utils;
use Mock::Basic;
use Test::Declare;

plan tests => blocks;

describe 'delete test' => run {
    init {
        Mock::Basic->setup_test_db;
        Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
    };

    test 'delete mock_basic data' => run {
        is +Mock::Basic->count('mock_basic', 'id'), 1;

        Mock::Basic->delete('mock_basic',{id => 1});

        is +Mock::Basic->count('mock_basic', 'id'), 0;
    };

    test 'row object delete' => run {
        Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });

        is +Mock::Basic->count('mock_basic', 'id'), 1;

        my $row = Mock::Basic->single('mock_basic',{id => 1})->delete;

        is +Mock::Basic->count('mock_basic', 'id'), 0;
    };
};

