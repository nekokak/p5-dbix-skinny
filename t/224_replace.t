use t::Utils;
use Mock::Basic;
use Test::More;

Mock::Basic->setup_test_db;

subtest 'replace mock_basic data' => sub {
    my $row = Mock::Basic->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->name, 'perl';

    my $replaced_row = Mock::Basic->replace('mock_basic',{
        id   => 1,
        name => 'ruby',
    });
    isa_ok $replaced_row, 'DBIx::Skinny::Row';
    is $replaced_row->name, 'ruby';

    done_testing;
};

done_testing;
