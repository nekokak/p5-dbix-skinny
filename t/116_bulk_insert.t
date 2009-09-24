use t::Utils;
use Mock::Basic;
use Mock::BasicMySQL;
use Mock::BasicPg;
use Test::Declare;

plan tests => blocks;

describe 'bulk insert test for sqlite' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'bulk_insert method' => run {
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
    };
};

SKIP: {
    my ($dsn, $username, $password) = @ENV{map { "SKINNY_MYSQL_${_}" } qw/DSN USER PASS/};

    skip 'Set $ENV{SKINNY_MYSQL_DSN}, _USER and _PASS to run this test', 1 unless ($dsn && $username);

    describe 'bulk insert test for mysql' => run {

        init {
            Mock::BasicMySQL->connect({dsn => $dsn, username => $username, password => $password});
            Mock::BasicMySQL->setup_test_db;
        };

        test 'bulk_insert method' => run {
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
        };
        cleanup {
            Mock::BasicMySQL->cleanup_test_db;
        };
    };
}

SKIP: {
    my ($dsn, $username, $password) = @ENV{map { "SKINNY_PG_${_}" } qw/DSN USER PASS/};

    skip 'Set $ENV{SKINNY_PG_DSN}, _USER and _PASS to run this test', 1 unless ($dsn && $username);

    describe 'bulk insert test for pg' => run {

        init {
            Mock::BasicPg->connect({dsn => $dsn, username => $username, password => $password});
            Mock::BasicPg->setup_test_db;
        };
        test 'bulk_insert method' => run {
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
        };
        cleanup {
            Mock::BasicPg->cleanup_test_db;
        };
    };
}

