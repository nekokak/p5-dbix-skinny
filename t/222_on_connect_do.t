use strict;
use warnings;
use t::Utils;
use Test::More;
use lib './t';
use Mock::BasicOnConnectDo;

subtest 'global level on_connect_do / coderef' => sub {
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

subtest 'instance level on_connect_do / coderef' => sub {
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

subtest 'instance level on_connect_do / scalar' => sub {
    require DBIx::Skinny::Profiler;
    local Mock::BasicOnConnectDo->attribute->{profiler} = DBIx::Skinny::Profiler->new;
    my $db = Mock::BasicOnConnectDo->new;

    $db->attribute->{on_connect_do} = 'select * from sqlite_master';
    $db->attribute->{profile} = 1;

    $db->connect;
    is_deeply $db->profiler->query_log, [
        q{select * from sqlite_master},
    ];

    $db->reconnect;
    is_deeply $db->profiler->query_log, [
        q{select * from sqlite_master},
        q{select * from sqlite_master},
    ];

    $db->profiler->reset;
    done_testing();
};

subtest 'instance level on_connect_do / array' => sub {
    require DBIx::Skinny::Profiler;
    local Mock::BasicOnConnectDo->attribute->{profiler} = DBIx::Skinny::Profiler->new;
    my $db = Mock::BasicOnConnectDo->new;

    $db->attribute->{on_connect_do} = ['select * from sqlite_master', 'select * from sqlite_master'];
    $db->attribute->{profile} = 1;

    $db->connect; 
    is_deeply $db->profiler->query_log, [
        q{select * from sqlite_master},
        q{select * from sqlite_master},
    ];

    $db->reconnect;
    is_deeply $db->profiler->query_log, [
        q{select * from sqlite_master},
        q{select * from sqlite_master},
        q{select * from sqlite_master},
        q{select * from sqlite_master},
    ];

    $db->profiler->reset;
    done_testing();
};

unlink './t/main.db';

done_testing();

