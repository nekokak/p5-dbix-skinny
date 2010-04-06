use t::Utils;
use Mock::Basic;
use Test::More;
use Test::Exception;

Mock::Basic->setup_test_db;
Mock::Basic->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});
Mock::Basic->insert('mock_basic',{
    id   => 2,
    name => 'python',
});
Mock::Basic->insert('mock_basic',{
    id   => 3,
    name => 'java',
});

subtest 'search' => sub {
    my $itr = Mock::Basic->search('mock_basic',{id => 1});
    isa_ok $itr, 'DBIx::Skinny::Iterator';

    my $row = $itr->first;
    isa_ok $row, 'DBIx::Skinny::Row';

    is $row->id, 1;
    is $row->name, 'perl';
    done_testing;
};

subtest 'search without where' => sub {
    my $itr = Mock::Basic->search('mock_basic');

    my $row = $itr->next;
    isa_ok $row, 'DBIx::Skinny::Row';

    is $row->id, 1;
    is $row->name, 'perl';

    my $row2 = $itr->next;

    isa_ok $row2, 'DBIx::Skinny::Row';

    is $row2->id, 2;
    is $row2->name, 'python';
    done_testing;
};

subtest 'search with order_by (originally)' => sub {
    my $itr = Mock::Basic->search('mock_basic', {}, { order_by => [ { id => 'desc' } ] });
    isa_ok $itr, 'DBIx::Skinny::Iterator';
    my $row = $itr->first;
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->id, 3;
    is $row->name, 'java';
    done_testing;
};

subtest 'search with order_by (as hashref)' => sub {
    my $itr = Mock::Basic->search('mock_basic', {}, { order_by => { id => 'desc' } });
    isa_ok $itr, 'DBIx::Skinny::Iterator';
    my $row = $itr->first;
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->id, 3;
    is $row->name, 'java';
    done_testing;
};

subtest 'search with order_by (as string)' => sub {
    my $itr = Mock::Basic->search('mock_basic', {}, { order_by => 'name' });
    isa_ok $itr, 'DBIx::Skinny::Iterator';
    my $row = $itr->first;
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->id, 3;
    is $row->name, 'java';
    done_testing;
};

subtest 'search with non-exist table' => sub {
    throws_ok(sub {
        my $itr = Mock::Basic->search('must_not_exist', {}, { order_by => 'name' });
    }, qr/schema_info does not exist for table/, 'throw reasonable error for easy debugging');
    done_testing;
};

done_testing;

