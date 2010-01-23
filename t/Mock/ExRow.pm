package Mock::ExRow;
use DBIx::Skinny setup => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
};

sub setup_test_db {
    shift->do(q{
        CREATE TABLE mock_ex_row (
            id   INT,
            name TEXT
        )
    });
}

1;

