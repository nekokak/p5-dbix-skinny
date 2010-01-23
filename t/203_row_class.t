use t::Utils;
use Mock::Basic;
use Mock::BasicRow;
use Mock::ExRow;
use Test::Declare;

plan tests => blocks;

describe 'search test' => run {
    init {
        Mock::Basic->setup_test_db;
        Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
        Mock::BasicRow->setup_test_db;
        Mock::BasicRow->insert('mock_basic_row',{
            id   => 1,
            name => 'perl',
        });
        Mock::ExRow->setup_test_db;
        Mock::ExRow->insert('mock_ex_row',{
            id   => 1,
            name => 'perl',
        });
    };

    test 'no your row class' => run {
        my $row = Mock::Basic->single('mock_basic',{id => 1});
        isa_ok $row, 'DBIx::Skinny::Row';
    };

    test 'your row class' => run {
        my $row = Mock::BasicRow->single('mock_basic_row',{id => 1});
        isa_ok $row, 'Mock::BasicRow::Row::MockBasicRow';
        is $row->foo, 'foo';
        is $row->id, 1;
        is $row->name, 'perl';
    };

    test 'ex row class' => run {
        my $row = Mock::ExRow->single('mock_ex_row',{id => 1});
        isa_ok $row, 'Mock::ExRow::Row';
        is $row->foo, 'foo';
    };
};

