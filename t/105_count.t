use t::Utils;
use Mock::Basic;
use Test::More;

Mock::Basic->setup_test_db;

subtest 'count' => sub {
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
    done_testing;
};

subtest 'iterator count' => sub {
    is +Mock::Basic->search('mock_basic',{  })->count, 2;
    done_testing;
};

done_testing;
