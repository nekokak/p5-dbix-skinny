use t::Utils;
use Mock::Basic;
use Mock::Trigger;
use Mock::BasicMySQL;
use Mock::BasicPg;
use Test::More;

Mock::Basic->setup_test_db;
Mock::Trigger->setup_test_db;

subtest 'bulk_insert method' => sub {
    Mock::Basic->bulk_insert('mock_basic',[
        {
            id   => 1,
            name => 'perl',
        },
        {
            id   => 2,
            name => 'ruby',
        },
        {
            id   => 3,
            name => 'python',
        },
    ]);
    is +Mock::Basic->count('mock_basic', 'id'), 3;

    subtest 'pre_insert trigger should not work in bulk_insert' => sub {
        Mock::Trigger->bulk_insert('mock_trigger_pre' => [
            {
                id   => 1,
                name => 'perl',
            },
            {
                id   => 2,
                name => 'ruby',
            },
            {
                id   => 3,
                name => 'python',
            },
        ]);

        is +Mock::Trigger->count('mock_trigger_pre', 'id'), 3;
        my $item = Mock::Trigger->single(mock_trigger_pre => +{ id => 1});
        ok($item->name ne "pre_insert_s", "pre_insert should not work");
        is($item->name, "perl", "pre_insert should not work");

        done_testing()
    };

    subtest 'post_insert trigger should not work in bulk_insert' => sub {
        Mock::Trigger->bulk_insert('mock_trigger_pre' => [
            {
                id   => 1,
                name => 'perl',
            },
            {
                id   => 2,
                name => 'ruby',
            },
            {
                id   => 3,
                name => 'python',
            },
        ]);

        is +Mock::Trigger->count('mock_trigger_post', 'id'), 0, "post_insert trigger should not work";

        done_testing()
    };

    done_testing;
};

SKIP: {
    my ($dsn, $username, $password) = @ENV{map { "SKINNY_MYSQL_${_}" } qw/DSN USER PASS/};

    skip 'Set $ENV{SKINNY_MYSQL_DSN}, _USER and _PASS to run this test', 1 unless ($dsn && $username);

        Mock::BasicMySQL->connect({dsn => $dsn, username => $username, password => $password});
        Mock::BasicMySQL->setup_test_db;

        subtest 'bulk_insert method' => sub {
            Mock::BasicMySQL->bulk_insert('mock_basic_mysql',[
                {
                    id   => 1,
                    name => 'perl',
                },
                {
                    id   => 2,
                    name => 'ruby',
                },
                {
                    id   => 3,
                    name => 'python',
                },
            ]);
            is +Mock::BasicMySQL->count('mock_basic_mysql', 'id'), 3;
            done_testing;
        };

        subtest 'no die (illigal division by zero?) / regression test' => sub {
            eval {
                Mock::Basic->bulk_insert('mock_basic',[ ]);
            };
            ok not $@;
            done_testing;
        };

        Mock::BasicMySQL->cleanup_test_db;
}

SKIP: {
    my ($dsn, $username, $password) = @ENV{map { "SKINNY_PG_${_}" } qw/DSN USER PASS/};

    skip 'Set $ENV{SKINNY_PG_DSN}, _USER and _PASS to run this test', 1 unless ($dsn && $username);

        Mock::BasicPg->connect({dsn => $dsn, username => $username, password => $password});
        Mock::BasicPg->setup_test_db;

        subtest 'bulk_insert method' => sub {
            Mock::BasicPg->bulk_insert('mock_basic_pg',[
                {
                    id   => 1,
                    name => 'perl',
                },
                {
                    id   => 2,
                    name => 'ruby',
                },
                {
                    id   => 3,
                    name => 'python',
                },
            ]);
            is +Mock::BasicPg->count('mock_basic_pg', 'id'), 3;
            done_testing;
        };
        Mock::BasicPg->cleanup_test_db;
}

done_testing;
