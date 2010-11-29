use t::Utils;
use Mock::Basic;
use Mock::BasicRow;
use Mock::ExRow;
use Test::More;

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

subtest 'no your row class' => sub {
    my $row = Mock::Basic->single('mock_basic',{id => 1});
    isa_ok $row, 'DBIx::Skinny::Row';
    done_testing;
};

subtest 'your row class' => sub {
    my $row = Mock::BasicRow->single('mock_basic_row',{id => 1});
    isa_ok $row, 'Mock::BasicRow::Row::MockBasicRow';
    is $row->foo, 'foo';
    is $row->id, 1;
    is $row->name, 'perl';
    done_testing;
};

subtest 'ex row class' => sub {
    my $row = Mock::ExRow->single('mock_ex_row',{id => 1});
    isa_ok $row, 'Mock::ExRow::Row';
    is $row->foo, 'foo';
    done_testing;
};

subtest 'row_class specific Schema.pm' => sub {
    is +Mock::BasicRow->_mk_row_class('key', 'mock_basic_row_foo'), 'Mock::BasicRow::FooRow';
    done_testing;
};

subtest 'handle' => sub {
    my $row = Mock::Basic->single('mock_basic',{id => 1});
    isa_ok $row->handle, 'Mock::Basic';
    can_ok $row->handle, 'single';
    done_testing;
};

done_testing;

