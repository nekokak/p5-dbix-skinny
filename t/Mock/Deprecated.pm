package Mock::Deprecated;
use DBIx::Skinny setup => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
    connect_options => { AutoCommit => 1 },
};

sub setup_test_db {
    shift->do(q{
        CREATE TABLE mock_deprecated (
            id   integer,
            name text,
            delete_fg int(1) default 0,
            primary key ( id )
        )
    });
}

1;
