use t::Utils;
use Test::More tests => 1;

BEGIN { use_ok( 'Mock::Basic' ); }

use DBD::SQLite;
diag('DBD::SQLite versin is '.$DBD::SQLite::VERSION);

