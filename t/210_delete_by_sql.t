use t::Utils;
use Mock::Basic;
use Test::Declare;

plan tests => blocks;

describe 'delete_by_sql test' => run {
    init {
        Mock::Basic->setup_test_db;
        Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
    };

    test 'delete mock_basic data' => run {
        my $ret = Mock::Basic->delete_by_sql(q{DELETE FROM mock_basic WHERE name = ?}, ['ruby']);
        ok $ret;
    }
};

