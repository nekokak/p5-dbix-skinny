package Mock::ExRow::Schema;
use utf8;
use DBIx::Skinny::Schema;

install_table mock_ex_row => schema {
    pk 'id';
    columns qw/
        id
        name
    /;
};

1;

