use strict;
use warnings;
use utf8;
use Test::Declare;
use lib './t';
use Mock::BasicMySQL;

my ($dsn, $username, $password) = @ENV{map { "SKINNY_MYSQL_${_}" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{SKINNY_MYSQL_DSN}, _USER and _PASS to run this test' unless ($dsn && $username);

plan tests => blocks;

describe 'transaction test' => run {
    init {
        Mock::BasicMySQL->connect({dsn => $dsn, username => $username, password => $password});
        Mock::BasicMySQL->setup_test_db;
    };

    test 'do basic transaction' => run {
        Mock::BasicMySQL->txn_begin;
        my $row = Mock::BasicMySQL->insert('mock_basic_mysql',{
            name => 'perl',
        });
        is $row->id, 1;
        is $row->name, 'perl';
        Mock::BasicMySQL->txn_commit;
        
        is +Mock::BasicMySQL->single('mock_basic_mysql',{id => 1})->name, 'perl';
    };

    test 'do rollback' => run {
        Mock::BasicMySQL->txn_begin;
        my $row = Mock::BasicMySQL->insert('mock_basic_mysql',{
            name => 'perl',
        });
        is $row->id, 2;
        is $row->name, 'perl';
        Mock::BasicMySQL->txn_rollback;
        
        ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 2});
    };

    test 'do commit' => run {
        Mock::BasicMySQL->txn_begin;
        my $row = Mock::BasicMySQL->insert('mock_basic_mysql',{
            name => 'perl',
        });
        is $row->id, 3;
        is $row->name, 'perl';
        Mock::BasicMySQL->txn_commit;

        ok +Mock::BasicMySQL->single('mock_basic_mysql',{id => 3});
    };

    test 'do scope commit' => run {
        my $txn = Mock::BasicMySQL->txn_scope;
        my $row = Mock::BasicMySQL->insert('mock_basic_mysql',{
            name => 'perl',
        });
        is $row->id, 4;
        is $row->name, 'perl';
        $txn->commit;

        ok +Mock::BasicMySQL->single('mock_basic_mysql',{id => 4});
    };

    test 'do scope rollback' => run {
        my $txn = Mock::BasicMySQL->txn_scope;
        my $row = Mock::BasicMySQL->insert('mock_basic_mysql',{
            name => 'perl',
        });
        is $row->id, 5;
        is $row->name, 'perl';
        $txn->rollback;

        ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 5});
    };

    test 'do scope guard for rollback' => run {

        {
            my $txn = Mock::BasicMySQL->txn_scope;
            my $row = Mock::BasicMySQL->insert('mock_basic_mysql',{
                name => 'perl',
            });
            is $row->id, 6;
            is $row->name, 'perl';
        }

        ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 6});
    };

    cleanup {
        Mock::BasicMySQL->cleanup_test_db;
    };
};

