package Mock::BasicMySQL;
use DBIx::Skinny setup => +{
    dsn      => "dbi:mysql:test",
    username => 'test',
    password => '',
};

my $table = 'mock_basic_mysql';
sub setup_test_db {
    shift->do(qq{
        CREATE TABLE $table (
            id   INT,
            name TEXT
        ) ENGINE=InnoDB
    });
}

sub cleanup_test_db {
    shift->do(qq{DROP TABLE $table});
}

1;

