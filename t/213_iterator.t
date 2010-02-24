use t::Utils;
use Mock::Basic;
use Test::More;
use Test::Exception;
use DBI;

Mock::Basic->setup_test_db;
Mock::Basic->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});
Mock::Basic->insert('mock_basic',{
    id   => 2,
    name => 'ruby',
});

subtest 'iterator with cache' => sub {
    my $itr = Mock::Basic->search("mock_basic");
    isa_ok $itr, 'DBIx::Skinny::Iterator';

    is $itr->count, 2, "rows count";
    my @rows = $itr->all;
    is scalar(@rows), 2, "all rows";
    $itr->reset;

    my $row1 = $itr->next;
    isa_ok $row1, 'DBIx::Skinny::Row';
    my $row2 = $itr->next;
    isa_ok $row2, 'DBIx::Skinny::Row';
    ok !$itr->next, 'no more row';

    ok $itr->reset, "reset ok";
    $row1 = $itr->first;
    isa_ok $row1, 'DBIx::Skinny::Row';
    done_testing;
};

subtest 'iterator with no cache all/count' => sub {
    my $itr = Mock::Basic->search("mock_basic");
    isa_ok $itr, 'DBIx::Skinny::Iterator';
    $itr->no_cache;

    is $itr->count, 2, "rows count";
    my @rows = $itr->all;
    is scalar(@rows), 0, "cannot retrieve all rows after count";

    ok $itr->reset, "reset ok";
    ok !$itr->first, "cannot retrieve first row after count";
    done_testing;
};

subtest 'iterator with no cache' => sub {
    my $itr = Mock::Basic->search("mock_basic");
    isa_ok $itr, 'DBIx::Skinny::Iterator';
    $itr->no_cache;

    my $row1 = $itr->next;
    isa_ok $row1, 'DBIx::Skinny::Row';
    my $row2 = $itr->next;
    isa_ok $row2, 'DBIx::Skinny::Row';

    ok !$itr->next, 'no more row';
    ok $itr->reset, 'reset ok';
    ok !$itr->first, "cannot retrieve first row";
    done_testing;
};

done_testing;

