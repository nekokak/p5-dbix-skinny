use strict;
use warnings;
use utf8;
use Test::More;
use lib './t';
use Mock::Basic;

BEGIN {
    eval "use DBD::SQLite";
    plan skip_all => "DBD::SQLite is not installed. skip testing" if $@;
}

Mock::Basic->setup_test_db;

subtest 'do basic transaction' => sub {
    Mock::Basic->txn_begin;
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl',
    });
    is $row->id, 1;
    is $row->name, 'perl';
    Mock::Basic->txn_commit;

    is +Mock::Basic->single('mock_basic',{id => 1})->name, 'perl';
    done_testing;
};
 
subtest 'do rollback' => sub {
    Mock::Basic->txn_begin;
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl',
    });
    is $row->id, 2;
    is $row->name, 'perl';
    Mock::Basic->txn_rollback;
    
    ok not +Mock::Basic->single('mock_basic',{id => 2});
    done_testing;
};
 
subtest 'do commit' => sub {
    Mock::Basic->txn_begin;
    my $row = Mock::Basic->insert('mock_basic',{
        name => 'perl',
    });
    is $row->id, 2;
    is $row->name, 'perl';
    Mock::Basic->txn_commit;
 
    ok +Mock::Basic->single('mock_basic',{id => 2});
    done_testing;
};
 

done_testing;


