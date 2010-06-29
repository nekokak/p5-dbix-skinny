use strict;
use warnings;
use utf8;
use Test::More;
use Test::SharedFork;
use lib './t';
use Mock::BasicMySQL;

my ($dsn, $username, $password) = @ENV{map { "SKINNY_MYSQL_${_}" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{SKINNY_MYSQL_DSN}, _USER and _PASS to run this test' unless ($dsn && $username);

Mock::BasicMySQL->connect({dsn => $dsn, username => $username, password => $password});
Mock::BasicMySQL->setup_test_db;

{
    Mock::BasicMySQL->txn_begin;

    if ( fork ) {
        wait;
        Mock::BasicMySQL->txn_rollback;
        ok +Mock::BasicMySQL->single('mock_basic_mysql',{id => 1});
        Mock::BasicMySQL->cleanup_test_db;
        done_testing;
    }
    else {
        # child
        my $row = Mock::BasicMySQL->insert('mock_basic_mysql',{
            name => 'perl',
        });
        ok +Mock::BasicMySQL->single('mock_basic_mysql',{id => 1});
    }
    
}

