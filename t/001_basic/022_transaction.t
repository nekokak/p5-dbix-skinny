use t::Utils;
use Test::More;
use Mock::Basic;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
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
};

subtest 'error occurred in transaction' => sub {
    eval {
        local $SIG{__WARN__} = sub {};
        my $txn = Mock::Basic->txn_scope;
        Mock::Basic->reconnect;
    };
    my $e = $@;
    my $file = __FILE__;
    like $e, qr{Detected transaction during a reconnect operation \(last known transaction at $file line 48, pid $$\)};
};
 
subtest 'error occurred in transaction / nested' => sub {
    eval {
        local $SIG{__WARN__} = sub {};
        my $txn = Mock::Basic->txn_scope;
            my $txn2 = Mock::Basic->txn_scope;
        Mock::Basic->reconnect;
    };
    my $e = $@;
    my $file = __FILE__;
    like $e, qr{Detected transaction during a reconnect operation \(last known transaction at $file line 59, pid $$\)};
};
done_testing;

