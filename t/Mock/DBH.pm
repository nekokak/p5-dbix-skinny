package Mock::DBH;
use DBI;
use DBIx::Skinny connect_info => +{
    dbh => DBI->connect('dbi:SQLite:', '', ''),
};

sub setup_test_db {
    shift->do(q{
        CREATE TABLE mock_dbh (
            id   INT,
            name TEXT
        )
    });
}

1;

