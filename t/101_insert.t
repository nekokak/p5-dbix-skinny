use t::Utils;
use Mock::Basic;
use Test::Declare;

plan tests => blocks;

describe 'insert test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'insert mock_basic data/ insert method' => run {
        my $row = Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->name, 'perl';
    };

    test 'insert mock_basic data/ create method' => run {
        my $row = Mock::Basic->create('mock_basic',{
            id   => 2,
            name => 'ruby',
        });
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->name, 'ruby';
    };
};

