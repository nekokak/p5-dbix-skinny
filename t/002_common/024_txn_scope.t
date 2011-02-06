use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

subtest 'insert using txn_scope' => sub {
    my $warning;
    local $SIG{__WARN__} = sub { $warning = $_[0] };
    {
        my $guard = Mock::Basic->txn_scope();
        my $row = Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->name, 'perl';
        $guard->rollback;
    }

    if (! ok ! $warning, "no warnings received") {
        diag "got $warning";
    }
};

subtest 'insert using txn_scope (and let the guard fire)' => sub {
    my $warning;
    local $SIG{__WARN__} = sub { $warning = $_[0] };
    {
        my $guard = Mock::Basic->txn_scope();
        my $row = Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->name, 'perl';
    }

    like $warning, qr{Transaction was aborted without calling an explicit commit or rollback. \(Guard created at};
};

done_testing;
