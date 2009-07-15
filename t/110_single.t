use t::Utils;
use Mock::Basic;
use Test::Declare;

plan tests => blocks;

describe 'single test' => run {
    init {
        Mock::Basic->setup_test_db;
        Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
    };

    test 'single' => run {
        my $row = Mock::Basic->single('mock_basic',{id => 1});
        is $row->id, 1;
        is $row->name, 'perl';
    };
};

