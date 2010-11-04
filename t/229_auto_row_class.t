use t::Utils;
use Mock::AutoRowClass;
use Test::More;

Mock::AutoRowClass->setup_test_db;

{
    my $row = Mock::AutoRowClass->insert('mock_table',{
        id   => 1,
        name => 'perl',
    });

    isa_ok $row, 'Mock::AutoRowClass::Row::MockTable';
}

{
    my $row = Mock::AutoRowClass->insert('mock_foo',{
        id   => 1,
        name => 'perl',
    });

    isa_ok $row, 'Mock::AutoRowClass::Row::MockFoo';
    is $row->say, 'hoo';
}

done_testing;
