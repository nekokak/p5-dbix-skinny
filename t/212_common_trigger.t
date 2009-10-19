use t::Utils;
use Mock::CommonTrigger;
use Test::Declare;

plan tests => blocks;

describe 'common trigger test' => run {
    init {
        Mock::CommonTrigger->setup_test_db;
    };

    test 'common trigger' => run {
        my $row = Mock::CommonTrigger->insert('mock_triggered',{
            id   => 1,
        });
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->created_at, 'now_s';
    };
};

