use strict;
use warnings;
use t::Utils;
use Test::More;
use lib './t';
use Mock::BasicOnConnectDo;

subtest 'global level on_connect_do' => sub {
    local $Mock::BasicOnConnectDo::CONNECTION_COUNTER = 0;

    my $db = Mock::BasicOnConnectDo->new(
        {
            dsn => 'dbi:SQLite:./t/main.db',
            username => '',
            password => '',
        }
    );

    $db->connect; # for do connection.
    is($Mock::BasicOnConnectDo::CONNECTION_COUNTER, 1, "counter should called");
    $db->reconnect;
    is($Mock::BasicOnConnectDo::CONNECTION_COUNTER, 2, "called after reconnect");
    $db->reconnect;
    is($Mock::BasicOnConnectDo::CONNECTION_COUNTER, 3, "called after reconnect");

    done_testing();
};

subtest 'instance level on_connect_do' => sub {
    my $counter = 0;
    my $db = Mock::BasicOnConnectDo->new(
        {
            dsn => 'dbi:SQLite:./t/main.db',
            username => '',
            password => '',
            on_connect_do => sub { $counter++ },
        }
    );

    $db->connect; # for do connection.
    is($counter, 1, "counter should called");
    $db->reconnect;
    is($counter, 2, "called after reconnect");
    $db->reconnect;
    is($counter, 3, "called after reconnect");

    done_testing();
};

done_testing();

