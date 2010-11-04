package Mock::AutoRowClass::Schema;
use strict;
use warnings;
use DBIx::Skinny::Schema;

install_table mock_table => schema {
    pk 'id';
    columns qw/
        id
        name
        delete_fg
    /;
};

1;
