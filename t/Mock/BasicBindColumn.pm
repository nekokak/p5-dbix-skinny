package Mock::BasicBindColumn;
use DBIx::Skinny connect_info => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
    connect_options => { AutoCommit => 1 },
};

sub setup_test_db {
    shift->do(q{
        CREATE TABLE mock_basic_bind_column (
            id   int,
            uid  bigint,
            name text,
            body blob,
            raw  bin,
            primary key ( id )
        )
    });
}

package Mock::BasicBindColumn::Schema;
use utf8;
use DBIx::Skinny::Schema;

install_table mock_basic_bind_column => schema {
    pk 'id';

    my @columns = (
        'id',
        {
            name => 'uid',
            type => 'bigint',
        },
        'name',
        {
            name => 'body',
            type => 'blob',
        },
        {
            name => 'raw',
            type => 'bin',
        },
    );
    columns @columns;
};

1;

