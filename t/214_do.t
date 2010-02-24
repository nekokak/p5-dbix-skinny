use t::Utils;
use Mock::Basic;
use Test::More;
use Test::Exception;

Mock::Basic->setup_test_db;

subtest 'do raise error' => sub {
    dies_ok( sub {Mock::Basic->do(q{select * from hoge}) });
    done_testing;
};

done_testing;
