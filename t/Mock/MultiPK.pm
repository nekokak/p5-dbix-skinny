package Mock::MultiPK;
use DBIx::Skinny connect_info => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
};

sub setup_test_db {
    my $self = shift;

    for my $table ( qw( a_multi_pk_table c_multi_pk_table ) ) {
        $self->do(qq{
            DROP TABLE IF EXISTS $table
        });
    }

    {
        $self->do(q{
            CREATE TABLE a_multi_pk_table (
                id_a  integer,
                id_b  integer,
                memo  integer default 'foobar',
                primary key( id_a, id_b )
            )
        });
        $self->do(q{
            CREATE TABLE c_multi_pk_table (
                id_c  integer,
                id_d  integer,
                memo  integer default 'foobar',
                primary key( id_c, id_d )
            )
        });
    }
}

1;

