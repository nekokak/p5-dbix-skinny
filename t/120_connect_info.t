use t::Utils;
use Mock::DB;
use Test::More;

Mock::DB->connect_info(
    {
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
    }
);

my $connect_info = Mock::DB->connect_info();

is $connect_info->{dsn}, 'dbi:SQLite:';
is $connect_info->{username}, '';
is $connect_info->{password}, '';

done_testing;
