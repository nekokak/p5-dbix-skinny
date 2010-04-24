use t::Utils;
use Mock::Basic;
use Test::More;

subtest 'connect_options should not loose after new' => sub {
    ok(Mock::Basic->attribute->{connect_options}, "connect_options should exist");
    Mock::Basic->new;
    ok(Mock::Basic->attribute->{connect_options}, "connect_options should not loose");

    done_testing;
};

done_testing;

