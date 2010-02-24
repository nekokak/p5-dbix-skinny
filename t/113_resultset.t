use t::Utils;
use Mock::Basic;
use Mock::DB;
use Test::More;
use Test::Exception;

Mock::Basic->setup_test_db;
Mock::Basic->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});

subtest 'resultset' => sub {
    my $rs = Mock::Basic->resultset;
    isa_ok $rs, 'DBIx::Skinny::SQL';

    $rs->add_select('name');
    $rs->from(['mock_basic']);
    $rs->add_where(id => 1);

    my $itr = $rs->retrieve;
    
    isa_ok $itr, 'DBIx::Skinny::Iterator';

    my $row = $itr->first;
    isa_ok $row, 'DBIx::Skinny::Row';

    is $row->name, 'perl';

    done_testing;
};

subtest 'no connection test' => sub {
    throws_ok(sub { Mock::DB->resultset }, qr/attribute dbd is not exist/);
    done_testing;
};

done_testing;
