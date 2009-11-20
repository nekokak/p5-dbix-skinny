use t::Utils;
use Mock::CommonTrigger;
use Test::Declare;

plan tests => blocks;

describe 'common trigger test' => run {
    init {
        Mock::CommonTrigger->setup_test_db;
    };

    test 'common trigger' => run {
        my $row = Mock::CommonTrigger->insert('mock_common_trigger',{
            id   => 1,
        });
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->created_at, 'now_s';
    };

    test 'common and table own trigger' => run {
        my $row = Mock::CommonTrigger->insert('mock_both_triggers',{
            id   => 1,
        });
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->created_at, 'now_s(custom)';
    };

    test 'trigger operates not exists column' => run {
        my $row = Mock::CommonTrigger->insert('mock_lack_column',{
            id   => 1,
        });
        isa_ok $row, 'DBIx::Skinny::Row';
        is_deeply [qw/id/], [sort keys %{$row->{row_data}}];
    };
};

