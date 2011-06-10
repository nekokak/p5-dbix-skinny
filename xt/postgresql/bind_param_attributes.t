use strict;
use warnings;
use t::Utils;
use xt::Utils::postgresql;
use Test::More;


{
    package Mock::PgBindColumn;
    use DBIx::Skinny;

    sub setup_test_db {
        my $skinny = shift;

        $skinny->do(
            q{DROP TABLE IF EXISTS mock_pg_bind_column}
        );

        $skinny->do(q{
            CREATE TABLE mock_pg_bind_column (
                id   SERIAL PRIMARY KEY,
                data BYTEA
            )
        });
    }
}

{
    package Mock::PgBindColumn::Schema;
    use DBIx::Skinny::Schema;

    install_table mock_pg_bind_column => schema {
        pk 'id';

        my @columns = (
            'id',
            {
                name => 'data',
                type => 'bytea',
            },
        );
        columns @columns;
    };
}

my $dbh = t::Utils->setup_dbh;
Mock::PgBindColumn->set_dbh($dbh);
Mock::PgBindColumn->setup_test_db;

my $null = "\0";
my $bin  = "123${null}456${null}789";


my $row = Mock::PgBindColumn->insert('mock_pg_bind_column',{
    id   => 1,
    data => $bin,
});

is( $row->id, 1 );
is( $row->data, $bin );

$row = Mock::PgBindColumn->single('mock_pg_bind_column', { id => 1 });

is( $row->id, 1 );
is( $row->data, $bin );

done_testing;


1;

