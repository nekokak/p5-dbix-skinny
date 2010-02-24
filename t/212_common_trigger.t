use t::Utils;
use Mock::CommonTrigger;
use Test::More;

Mock::CommonTrigger->setup_test_db;

subtest 'common trigger' => sub {
    my $row = Mock::CommonTrigger->insert('mock_common_trigger',{
        id   => 1,
    });
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->created_at, 'now_s';
    done_testing;
};

subtest 'common and table own trigger' => sub {
    my $row = Mock::CommonTrigger->insert('mock_both_triggers',{
        id   => 1,
    });
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->created_at, 'now_s(custom)';
    done_testing;
};

subtest 'trigger operates not exists column' => sub {
    my $row = Mock::CommonTrigger->insert('mock_lack_column',{
        id   => 1,
    });
    isa_ok $row, 'DBIx::Skinny::Row';
    is_deeply [qw/id/], [sort keys %{$row->{row_data}}];
    done_testing;
};

done_testing;

