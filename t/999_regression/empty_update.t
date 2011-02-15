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

subtest 'duplicate_update2' => sub {
    my $row = Mock::Basic->single('mock_basic',{
        id => 1,
    });
    is $row->name => 'perl';

    $row->set_column(name => 'ruby');
    is $row->update => 1;
    is $row->name => 'ruby';

    is $row->update => 0;
    is $row->name => 'ruby';

    is $row->update({}) => 0;
    is $row->name => 'ruby';
};

done_testing;
