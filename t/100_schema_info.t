use t::Utils;
use Mock::Basic;
use Mock::BasicBindColumn;
use Test::More;

Mock::Basic->setup_test_db;

subtest 'schema info' => sub {
    is +Mock::Basic->schema, 'Mock::Basic::Schema';

    my $info = Mock::Basic->schema->schema_info;
    is_deeply $info,{
        mock_basic => {
            pk      => 'id',
            columns => [
                'id',
                'name',
                'delete_fg',
            ],
            column_types => +{},
        }
    };

    isa_ok +Mock::Basic->dbh, 'DBI::db';
    done_testing;
};

subtest 'schema info' => sub {
    is +Mock::BasicBindColumn->schema, 'Mock::BasicBindColumn::Schema';

    my $info = Mock::BasicBindColumn->schema->schema_info;
    is_deeply $info,{
        mock_basic_bind_column => {
            pk      => 'id',
            columns => [
                'id',
                'uid',
                'name',
                'body',
                'raw',
            ],
            column_types => +{
                body => 'blob',
                uid  => 'bigint',
                raw  => 'bin',
            },
        }
    };

    done_testing;
};

done_testing;
