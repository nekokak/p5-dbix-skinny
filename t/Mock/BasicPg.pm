package Mock::BasicPg;
use DBIx::Skinny connect_info => +{};

my $table = 'mock_basic_pg';
sub setup_test_db {
    shift->do(qq{
        CREATE TABLE $table (
            id   SERIAL PRIMARY KEY,
            name TEXT
        )
    });
}

sub cleanup_test_db {
    shift->do(qq{DROP TABLE $table});
}

1;

