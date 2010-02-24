use strict;
use warnings;

package K;

sub init {
    my $self = shift;
    $self->baz('bazbaz');
}
use Test::More;

use_ok('DBIx::Skinny::Accessor');

mk_accessors(qw(foo bar baz));

ok(! $@, 'call mk_accessors');

my $k = K->new({ foo => 1, bar => 2 });
is($k->baz, 'bazbaz');
is($k->foo, 1);
is($k->foo(2), 2);
is($k->foo, 2);
is_deeply($k->foo(2, 3), [ 2, 3 ]);
is_deeply($k->foo, [ 2, 3 ]);
is($k->bar, 2);

done_testing;
