use t::Utils;
use Mock::Basic;
use Test::More;
use Test::Exception;

Mock::Basic->setup_test_db;

subtest 'get_column' => sub {
    my $row = Mock::Basic->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    isa_ok $row, 'DBIx::Skinny::Row';

    is($row->get_column('name') => 'perl', 'get_column ok');
    throws_ok(sub { $row->get_column }, qr/please specify \$col for first argument/, 'no argument get_column should raise error');

    throws_ok(sub { $row->get_column('bazbaz') }, qr/bazbaz no selected column./);

    done_testing;
};

subtest 'get_column' => sub {
    my $row = Mock::Basic->search_by_sql(
        q{SELECT id FROM mock_basic LIMIT 1}
    )->first;
    isa_ok $row, 'DBIx::Skinny::Row';

    throws_ok(sub { $row->get_column('name') }, qr/name no selected column./);

    done_testing;
};

done_testing;

