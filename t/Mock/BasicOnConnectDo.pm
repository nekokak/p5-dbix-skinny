package Mock::BasicOnConnectDo;
our $CONNECTION_COUNTER;
use DBIx::Skinny setup => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
    connect_options => { AutoCommit => 1 },
    on_connect_do => sub { $CONNECTION_COUNTER++ }
};

sub setup_test_db {
    shift->do(q{
        CREATE TABLE mock_basic_on_connect_do (
            id   integer,
            name text,
            primary key ( id )
        )
    });
}

1;

