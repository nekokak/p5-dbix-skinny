use t::Utils;
use Mock::Basic;
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
        }
    };

    isa_ok +Mock::Basic->dbh, 'DBI::db';
    done_testing;
};

done_testing;
