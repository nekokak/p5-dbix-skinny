use strict;
use Test::More;
use xt::Utils::mysql;
use t::Utils;
use Mock::Basic;
use Test::More;

subtest "fork, don't do anything, then see if the parent works" => sub {
    my $dbh = t::Utils->setup_dbh();
#    my $dbh = DBI->connect('dbi:mysql:dbname=scrooge', 'root', undef, {RaiseError => 1});
    my $db  = Mock::Basic->new( { dbh => $dbh } );
    $db->setup_test_db;


    my $pid = fork();
    if (! $pid) {
        undef $db;
        sleep 1;
        exit 0;
    } else {
        wait;
    }

    my $row = $db->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    isa_ok $row, 'DBIx::Skinny::Row';
    is $row->name, 'perl';
};

done_testing;


__END__
use strict;
use warnings;
use utf8;
use xt::Utils::mysql;
use Test::More;
use Test::SharedFork;
use lib './t';
use Mock::BasicMySQL;

my $dbh = t::Utils->setup_dbh;
Mock::BasicMySQL->set_dbh($dbh);
Mock::BasicMySQL->setup_test_db;

# XXX: Correct operation is not done for set_dbh.
{
    Mock::BasicMySQL->txn_begin;
    ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 1});

    if ( fork ) {
        wait;
        Mock::BasicMySQL->txn_rollback;
        ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 1});
        Mock::BasicMySQL->cleanup_test_db;
        done_testing;
    }
    else {
        # child
        eval {
            Mock::BasicMySQL->insert('mock_basic_mysql',{
                name => 'perl',
            });
        };
        ok $@;
    }
    
}

