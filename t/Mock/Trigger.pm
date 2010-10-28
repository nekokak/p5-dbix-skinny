package Mock::Trigger;
use DBIx::Skinny connect_info => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
};

sub setup_test_db {
    my $class = shift;
    $class->do(q{
        CREATE TABLE mock_trigger_pre (
            id   INT,
            name TEXT
        )
    });
    $class->do(q{
        CREATE TABLE mock_trigger_post (
            id   INT,
            name TEXT
        )
    });
    $class->do(q{
        CREATE TABLE mock_trigger_post_delete (
            id   INT,
            name TEXT
        )
    });
}

1;

