use t::Utils;
use Test::Declare;

plan tests => blocks;

{
    package Mock::NoSchema;
    use DBIx::Skinny;
    1;
}

describe 'no load schema case' => run {
    test 'do test' => run {
        dies_ok( sub {Mock::NoSchema->schema} );
    };
};

