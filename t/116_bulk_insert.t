use t::Utils;
use Mock::Basic;
use Mock::BasicMySQL;
use Mock::BasicPg;
use Test::More;

Mock::Basic->setup_test_db;

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
