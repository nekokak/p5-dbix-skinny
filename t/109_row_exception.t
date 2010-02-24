use t::Utils;
use Mock::Basic;
use Test::More;
use Test::Exception;

Mock::Basic->setup_test_db;
Mock::Basic->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});

subtest 'update/delete error: no table info' => sub {
    my $row = Mock::Basic->search_by_sql(q{SELECT name FROM mock_basic})->first;

    isa_ok $row, 'DBIx::Skinny::Row';

    dies_ok( sub { $row->update({name => 'python'})} );
    throws_ok(sub { $row->update({name => 'python'}) }, qr/no table info/);

    dies_ok( sub { $row->delete } );
    throws_ok(sub { $row->delete }, qr/no table info/);
    done_testing;
};

subtest 'update/delete error: table name typo' => sub {
    my $row = Mock::Basic->single('mock_basic',{id => 1});

    isa_ok $row, 'DBIx::Skinny::Row';

    dies_ok( sub { $row->update({name => 'python'},'mock_basick')} );
    throws_ok(sub { $row->update({name => 'python'},'mock_basick') }, qr/unknown table: mock_basick/);

    dies_ok(sub { $row->delete('mock_basick') });
    throws_ok(sub { $row->delete('mock_basick') }, qr/unknown table: mock_basick/);
    done_testing;
};

subtest 'update/delete error: table have no pk' => sub {
    Mock::Basic->schema->schema_info->{mock_basic}->{pk} = undef;

    my $row = Mock::Basic->single('mock_basic',{id => 1});
    isa_ok $row, 'DBIx::Skinny::Row';

    dies_ok( sub { $row->update({name => 'python'})} );
    throws_ok(sub { $row->update({name => 'python'}) }, qr/mock_basic have no pk./);

    dies_ok( sub { $row->delete } );
    throws_ok(sub { $row->delete }, qr/mock_basic have no pk./);

    Mock::Basic->schema->schema_info->{mock_basic}->{pk} = 'id';
    done_testing;
};

subtest 'update/delete error: select column have no pk.' => sub {
    my $row = Mock::Basic->resultset(
        {
            select => [qw/name/],
            from   => [qw/mock_basic/],
        }
    )->retrieve->first;

    isa_ok $row, 'DBIx::Skinny::Row';

    dies_ok( sub { $row->update({name => 'python'})} );
    throws_ok(sub { $row->update({name => 'python'}) }, qr/can't get primary column in your query./);

    dies_ok( sub { $row->delete } );
    throws_ok(sub { $row->delete }, qr/can't get primary column in your query./);
    done_testing;
};

done_testing;

