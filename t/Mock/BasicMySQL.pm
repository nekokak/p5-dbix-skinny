package Mock::BasicMySQL;
use DBIx::Skinny connect_info => +{};

my $table = 'mock_basic_mysql';
sub setup_test_db {
    shift->do(qq{
        CREATE TABLE $table (
            id   INT auto_increment,
            name TEXT,
            PRIMARY KEY  (id)
        ) ENGINE=InnoDB
    });
}

sub cleanup_test_db {
    shift->do(qq{DROP TABLE $table});
}

1;

