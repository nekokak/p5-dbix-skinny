use t::Utils;
use Mock::Basic;
use Test::More;
use Test::SharedFork;

my $db = './test.db';

unlink $db;
Mock::Basic->connect_info(+{
    dsn      => "dbi:SQLite:$db",
    username => '',
    password => '',
});

if (fork) {
    wait;
    my $dbh1 = Mock::Basic->dbh;
    my $dbh2 = Mock::Basic->dbh;
    is $dbh1, $dbh2, 'Reuse connection';
    ok ! $dbh1->{InactiveDestroy}, "Don't set InactiveDestroy on parent (1)";
    ok ! $dbh2->{InactiveDestroy}, "Don't set InactiveDestroy on parent (2)";
    done_testing;
} else {
    my $dbh1 = Mock::Basic->dbh;
    my $dbh2 = Mock::Basic->dbh;
    is $dbh1, $dbh2, 'Reuse connection';
    ok ! $dbh1->{InactiveDestroy}, "Don't set InactiveDestroy on child (1)";
    ok ! $dbh2->{InactiveDestroy}, "Don't set InactiveDestroy on child (2)";
    exit;
}

unlink $db;
