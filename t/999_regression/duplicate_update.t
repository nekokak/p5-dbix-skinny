use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

Mock::Basic->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});

subtest 'duplicate_update' => sub {
    my $row = Mock::Basic->single('mock_basic',{
        id => 1,
    });
    is $row->name => 'perl';
    $row->update({
        name => 'ruby',
    });

    my $row2 = Mock::Basic->single('mock_basic',{
        id => 1,
    });
    is $row2->name => 'ruby';
    $row2->update({
        name => 'python'
    });
    is $row2->name => 'python';

    # please dont update `name`!
    $row->update({
        id => 1,
    });

    is +Mock::Basic->single('mock_basic',{
        id => 1,
    })->name => 'python';
};

done_testing;
