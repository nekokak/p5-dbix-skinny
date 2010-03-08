package Mock::MultiPK;
use DBIx::Skinny setup => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
};

sub setup_test_db {
    my $self = shift;

    for my $table ( qw( a_multi_pk_table ) ) {
        $self->do(qq{
            DROP TABLE IF EXISTS $table
        });
    }

    $self->do(q{
        CREATE TABLE a_multi_pk_table (
            id_a  integer,
            id_b  integer,
            memo  integer default 'foobar',
            primary key( id_a, id_b )
        )
    });

}

sub creanup_test_db {
}
1;

