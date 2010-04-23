use t::Utils;
use Mock::DBH;
use Test::More;

Mock::DBH->setup_test_db;

subtest 'schema info' => sub {
    is +Mock::DBH->schema, 'Mock::DBH::Schema';

    my $info = Mock::DBH->schema->schema_info;
    is_deeply $info,{
        mock_dbh => {
            pk      => 'id',
            columns => [
                'id',
                'name',
            ],
            column_types => +{},
        }
    };

    isa_ok +Mock::DBH->dbh, 'DBI::db';
    done_testing;
};

subtest 'insert' => sub {
    Mock::DBH->insert('mock_dbh',{id => 1 ,name => 'nekokak'});
    is +Mock::DBH->count('mock_dbh','id',{name => 'nekokak'}), 1;
    done_testing;
};

done_testing;
