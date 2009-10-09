use t::Utils;
use Mock::Basic;
use Test::Declare;

plan tests => blocks;

describe 'update_by_sql test' => run {
    init {
        Mock::Basic->setup_test_db;
        Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
    };

    test 'update mock_basic data' => run {
        my $ret = Mock::Basic->update_by_sql(q{UPDATE mock_basic SET name = ?}, ['ruby']);
        ok $ret;
        is +Mock::Basic->single('mock_basic',{})->name, 'ruby';
    }
};

