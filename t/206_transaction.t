use strict;
use warnings;
use utf8;
use Test::More;
use lib './t';
use Mock::BasicMySQL;

my ($dsn, $username, $password) = @ENV{map { "SKINNY_MYSQL_${_}" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{SKINNY_MYSQL_DSN}, _USER and _PASS to run this test' unless ($dsn && $username);

Mock::BasicMySQL->connect({dsn => $dsn, username => $username, password => $password});
Mock::BasicMySQL->setup_test_db;

subtest 'do basic transaction' => sub {
    Mock::BasicMySQL->txn_begin;
    my $row = Mock::BasicMySQL->insert('mock_basic_mysql',{
        name => 'perl',
    });
    is $row->id, 1;
    is $row->name, 'perl';
    Mock::BasicMySQL->txn_commit;
    
    is +Mock::BasicMySQL->single('mock_basic_mysql',{id => 1})->name, 'perl';
    done_testing;
};

subtest 'do rollback' => sub {
    Mock::BasicMySQL->txn_begin;
    my $row = Mock::BasicMySQL->insert('mock_basic_mysql',{
        name => 'perl',
    });
    is $row->id, 2;
    is $row->name, 'perl';
    Mock::BasicMySQL->txn_rollback;
    
    ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 2});
    done_testing;
};

subtest 'do commit' => sub {
    Mock::BasicMySQL->txn_begin;
    my $row = Mock::BasicMySQL->insert('mock_basic_mysql',{
        name => 'perl',
    });
    is $row->id, 3;
    is $row->name, 'perl';
    Mock::BasicMySQL->txn_commit;

    ok +Mock::BasicMySQL->single('mock_basic_mysql',{id => 3});
    done_testing;
};

subtest 'do scope commit' => sub {
    my $txn = Mock::BasicMySQL->txn_scope;
    my $row = Mock::BasicMySQL->insert('mock_basic_mysql',{
        name => 'perl',
    });
    is $row->id, 4;
    is $row->name, 'perl';
    $txn->commit;

    ok +Mock::BasicMySQL->single('mock_basic_mysql',{id => 4});
    done_testing;
};

subtest 'do scope rollback' => sub {
    my $txn = Mock::BasicMySQL->txn_scope;
    my $row = Mock::BasicMySQL->insert('mock_basic_mysql',{
        name => 'perl',
    });
    is $row->id, 5;
    is $row->name, 'perl';
    $txn->rollback;

    ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 5});
    done_testing;
};

subtest 'do scope guard for rollback' => sub {

    {
        my $txn = Mock::BasicMySQL->txn_scope;
        my $row = Mock::BasicMySQL->insert('mock_basic_mysql',{
            name => 'perl',
        });
        is $row->id, 6;
        is $row->name, 'perl';
    }

    ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 6});
    done_testing;
};

Mock::BasicMySQL->cleanup_test_db;

done_testing;

