use t::Utils;
use Mock::DB;
use Test::Declare;
use DBI;

plan tests => blocks;

describe 'basic test' => run {
    init {
        my $dbh = DBI->connect('dbi:SQLite:', '', '');
        Mock::DB->set_dbh($dbh);
        Mock::DB->setup_test_db;
    };
    test 'dbh info' => run {
        isa_ok +Mock::DB->dbh, 'DBI::db';
    };

    test 'insert' => run {
        Mock::DB->insert('mock_db',{id => 1 ,name => 'nekokak'});
        is +Mock::DB->count('mock_db','id',{name => 'nekokak'}), 1;
    };
};

