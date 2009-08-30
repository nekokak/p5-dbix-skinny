package Mock::Inclusion;
use DBIx::Skinny setup => +{
};

sub setup_test_db {
    shift->do(q{
        CREATE TABLE mock_inclusion (
            id   INT,
            name TEXT
        )
    });
}

package Mock::Inclusion::Schema;
use DBIx::Skinny::Schema;

install_table mock_inclusion => schema {
    pk 'id';
    columns qw/
        id
        name
    /;
};

1;
