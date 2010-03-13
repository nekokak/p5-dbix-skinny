package Mock::NoCheckSchema;
use DBIx::Skinny setup => +{
    check_schema => 0,
};

1;
