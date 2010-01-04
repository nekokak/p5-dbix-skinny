use t::Utils;
use Mock::Basic;
use Test::Declare;

plan tests => blocks;

describe 'search_by_sql test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'do raise error' => run {
        dies_ok( sub {Mock::Basic->do(q{select * from hoge}) });
    };
};

