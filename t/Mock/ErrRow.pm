package Mock::ErrRow;
use DBIx::Skinny setup => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
};

sub setup_test_db {
    shift->do(q{
        CREATE TABLE mock_err_row (
            id   INT,
            name TEXT
        )
    });
}

1;

