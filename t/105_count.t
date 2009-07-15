use t::Utils;
use Mock::Basic;
use Test::Declare;

plan tests => blocks;

describe 'count test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'count' => run {
        Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });

        is +Mock::Basic->count('mock_basic' => 'id'), 1;

        Mock::Basic->insert('mock_basic',{
            id   => 2,
            name => 'ruby',
        });

        is +Mock::Basic->count('mock_basic' => 'id'), 2;
        is +Mock::Basic->count('mock_basic' => 'id',{name => 'perl'}), 1;
    };

    test 'iterator count' => run {
        is +Mock::Basic->search('mock_basic',{  })->count, 2;
    };
};

