package Mock::AutoRowClass;
use DBIx::Skinny
auto_row_class => 1,
connect_info => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
    connect_options => { AutoCommit => 1 },
};

sub setup_test_db {
    my $db = shift;
    $db->do(q{
        CREATE TABLE mock_table (
            id   integer,
            name text,
            delete_fg int(1) default 0,
            primary key ( id )
        )
    });
    $db->do(q{
        CREATE TABLE mock_foo (
            id   integer,
            name text,
            delete_fg int(1) default 0,
            primary key ( id )
        )
    });
}

1;

