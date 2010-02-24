use t::Utils;
use Test::More;
use Test::Exception;

{
    package Mock::NoSchema;
    use DBIx::Skinny;
    1;
}

subtest 'do test' => sub {
    dies_ok( sub {Mock::NoSchema->schema} );
    done_testing;
};

done_testing;
