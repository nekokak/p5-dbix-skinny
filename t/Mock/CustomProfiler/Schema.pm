package Mock::CustomProfiler::Schema;
use utf8;
use DBIx::Skinny::Schema;

install_table mock_custom_profiler => schema {
    pk 'id';
    columns qw/
        id
        name
    /;
};

1;

