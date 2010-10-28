package Mock::NoCheckSchema;
use DBIx::Skinny connect_info => +{
    check_schema => 0,
};

1;
