package Mock::Inflate;
use DBIx::Skinny connect_info => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
};

sub setup_test_db {
    shift->do(q{
        CREATE TABLE mock_inflate (
            id   INT,
            name TEXT
        )
    });
}

1;

