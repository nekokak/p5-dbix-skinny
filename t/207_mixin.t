use t::Utils;
use Test::Declare;
use Mock::Mixin;

plan tests => blocks;

describe 'mixin test' => run {

    test 'mixin Mixin::Foo module' => run {
        can_ok 'Mock::Mixin', 'foo';
        is +Mock::Mixin->foo, 'foo';
    };
};

