use t::Utils;
use Test::More;
use Test::Output;

BEGIN {
    $ENV{SKINNY_TRACE} = 1;
}

use Mock::Basic;

stderr_is(
    sub { Mock::Basic->setup_test_db },
    qq{CREATE TABLE mock_basic ( id integer, name text, primary key ( id ) )\n}
);

stderr_is(
    sub {
        Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        })
    },
    qq{INSERT INTO mock_basic (`name`, `id`) VALUES (?, ?) :binds perl, 1\n}
);

done_testing;

