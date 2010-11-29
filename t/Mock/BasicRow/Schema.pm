package Mock::BasicRow::Schema;
use utf8;
use DBIx::Skinny::Schema;

install_table mock_basic_row => schema {
    pk 'id';
    columns qw/
        id
        name
    /;
};

install_table mock_basic_row_foo => schema {
    pk 'id';
    columns qw/
        id
        name
    /;
    row_class 'Mock::BasicRow::FooRow';
};

1;

