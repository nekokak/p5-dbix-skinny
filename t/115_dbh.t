use t::Utils;
use Mock::DBH;
use Test::Declare;

plan tests => blocks;

describe 'basic test' => run {
    init {
        Mock::DBH->setup_test_db;
    };
    test 'schema info' => run {
        is +Mock::DBH->schema, 'Mock::DBH::Schema';

        my $info = Mock::DBH->schema->schema_info;
        is_deeply $info,{
            mock_dbh => {
                pk      => 'id',
                columns => [
                    'id',
                    'name',
                ],
            }
        };

        isa_ok +Mock::DBH->dbh, 'DBI::db';
    };

    test 'insert' => run {
        Mock::DBH->insert('mock_dbh',{id => 1 ,name => 'nekokak'});
        is +Mock::DBH->count('mock_dbh','id',{name => 'nekokak'}), 1;
    };
};

