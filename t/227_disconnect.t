use t::Utils;
use Mock::Basic;
use Test::More;

use File::Temp qw(tempdir);
my $tempdir = tempdir(CLEANUP => 1);
my $file    = File::Spec->catfile($tempdir, 'disconnect.db');
Mock::Basic->connect_info( {
    dsn => "dbi:SQLite:dbname=$file",
    username => '',
    password => '',
    connect_options => { AutoCommit => 1 },
});

Mock::Basic->setup_test_db;

subtest 'insert mock_basic data/ insert method' => sub {
    my $row = Mock::Basic->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->name, 'perl';
    done_testing;
};

subtest 'disconnect' => sub {
    Mock::Basic->disconnect();
    ok ! defined Mock::Basic->_attributes->{dbh}, "dbh is undef";
    done_testing;
};

subtest 'insert after disconnect trigger a connect' => sub {
    my $row = Mock::Basic->create('mock_basic',{
        id   => 2,
        name => 'ruby',
    });
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->name, 'ruby';
    done_testing;
};

done_testing;
