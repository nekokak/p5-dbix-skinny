use strict;
use warnings;
use Test::More;
use t::Mock::NoCheckSchema;

local $@;
eval {
    my $rs = Mock::NoCheckSchema->search('foo_bar', {id => 1});
};

unlike($@, qr/is it realy loaded/);

done_testing();
