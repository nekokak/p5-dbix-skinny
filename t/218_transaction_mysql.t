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

subtest 'do nested scope rollback-rollback' => sub {
    my $txn = Mock::BasicMySQL->txn_scope;
    {
        my $txn2 = Mock::BasicMySQL->txn_scope;
        my $row2 = Mock::BasicMySQL->insert('mock_basic_mysql',{
            name => 'perl5.10',
        });
        is $row2->id, 7;
        is $row2->name, 'perl5.10';
        $txn2->rollback;
    }
    my $row = Mock::BasicMySQL->insert('mock_basic_mysql',{
        name => 'perl5.12',
    });
    is $row->id, 8;
    is $row->name, 'perl5.12';
    $txn->rollback;

    ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 7});
    ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 8});
    done_testing;
};

subtest 'do nested scope commit-rollback' => sub {
    my $txn = Mock::BasicMySQL->txn_scope;
    {
        my $txn2 = Mock::BasicMySQL->txn_scope;
        my $row2 = Mock::BasicMySQL->insert('mock_basic_mysql',{
            name => 'perl5.10',
        });
        is $row2->id, 9;
        is $row2->name, 'perl5.10';
        $txn2->commit;
    }
    my $row = Mock::BasicMySQL->insert('mock_basic_mysql',{
        name => 'perl5.12',
    });
    is $row->id, 10;
    is $row->name, 'perl5.12';
    $txn->rollback;

    ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 9});
    ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 10});
    done_testing;
};

subtest 'do nested scope rollback-commit' => sub {
    my $txn = Mock::BasicMySQL->txn_scope;
    {
        my $txn2 = Mock::BasicMySQL->txn_scope;
        my $row2 = Mock::BasicMySQL->insert('mock_basic_mysql',{
            name => 'perl5.10',
        });
        is $row2->id, 11;
        is $row2->name, 'perl5.10';
        $txn2->rollback;
    }
    my $row = Mock::BasicMySQL->insert('mock_basic_mysql',{
        name => 'perl5.12',
    });
    is $row->id, 12;
    is $row->name, 'perl5.12';

    eval { $txn->commit };

    like( $@, qr/tried to commit but alreay rollbacked in nested transaction./, "error message" );

    $txn->rollback;

    ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 11});
    ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 12});
    done_testing;
};

subtest 'do nested scope commit-commit' => sub {
    my $txn = Mock::BasicMySQL->txn_scope;
    {
        my $txn2 = Mock::BasicMySQL->txn_scope;
        my $row2 = Mock::BasicMySQL->insert('mock_basic_mysql',{
            name => 'perl5.10',
        });
        is $row2->id, 13;
        is $row2->name, 'perl5.10';
        $txn2->commit;
    }
    my $row = Mock::BasicMySQL->insert('mock_basic_mysql',{
        name => 'perl5.12',
    });
    is $row->id, 14;
    is $row->name, 'perl5.12';
    $txn->commit;

    ok +Mock::BasicMySQL->single('mock_basic_mysql',{id => 13});
    ok +Mock::BasicMySQL->single('mock_basic_mysql',{id => 14});
    done_testing;
};

subtest 'do nested scope rollback-commit-rollback' => sub {
    my $txn = Mock::BasicMySQL->txn_scope;
    {
        my $txn2 = Mock::BasicMySQL->txn_scope;
        my $row2 = Mock::BasicMySQL->insert('mock_basic_mysql',{
            name => 'perl5.10',
        });
        is $row2->id, 15;
        is $row2->name, 'perl5.10';

        {
            my $txn3 = Mock::BasicMySQL->txn_scope;
            my $row3 = Mock::BasicMySQL->insert('mock_basic_mysql',{
                name => 'perl',
            });
            is $row3->id, 16;
            is $row3->name, 'perl';
        }

        eval { $txn2->commit };
        like( $@, qr/tried to commit but alreay rollbacked in nested transaction./, "error message" );
    }
    my $row = Mock::BasicMySQL->insert('mock_basic_mysql',{
        name => 'perl5.12',
    });
    is $row->id, 17;
    is $row->name, 'perl5.12';
    $txn->rollback;

    ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 15});
    ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 16});
    ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 17});
    done_testing;
};


subtest 'do nested scope rollback-commit-commit' => sub {
    my $txn = Mock::BasicMySQL->txn_scope;
    {
        my $txn2 = Mock::BasicMySQL->txn_scope;
        my $row2 = Mock::BasicMySQL->insert('mock_basic_mysql',{
            name => 'perl5.10',
        });
        is $row2->id, 18;
        is $row2->name, 'perl5.10';

        {
            my $txn3 = Mock::BasicMySQL->txn_scope;
            my $row3 = Mock::BasicMySQL->insert('mock_basic_mysql',{
                name => 'perl',
            });
            is $row3->id, 19;
            is $row3->name, 'perl';
        }
    }
    my $row = Mock::BasicMySQL->insert('mock_basic_mysql',{
        name => 'perl5.12',
    });
    is $row->id, 20;
    is $row->name, 'perl5.12';

    eval { $txn->commit };
    like( $@, qr/tried to commit but alreay rollbacked in nested transaction./, "error message" );
    $txn->rollback;

    ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 18});
    ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 19});
    ok not +Mock::BasicMySQL->single('mock_basic_mysql',{id => 20});
    done_testing;
};

Mock::BasicMySQL->cleanup_test_db;

done_testing;


