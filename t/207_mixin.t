use t::Utils;
use Test::More;
use Mock::Mixin;

subtest 'mixin Mixin::Foo module' => sub {
    can_ok 'Mock::Mixin', 'foo';
    is +Mock::Mixin->foo, 'foo';
    done_testing;
};

done_testing;

