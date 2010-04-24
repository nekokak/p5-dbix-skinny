use t::Utils;
use Mock::Basic;
use Test::More;

subtest '' => sub {
    ok(Mock::Basic->attribute->{connect_options}, "connect_options should exist");
    Mock::Basic->new;
    ok(Mock::Basic->attribute->{connect_options}, "connect_options should not loose");

    done_testing;
};

done_testing;

