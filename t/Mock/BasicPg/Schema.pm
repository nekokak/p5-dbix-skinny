package Mock::BasicPg::Schema;
use utf8;
use DBIx::Skinny::Schema;

install_table mock_basic_pg => schema {
    pk 'id';
    columns qw/
        id
        name
    /;
};

1;

