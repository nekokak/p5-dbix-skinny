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

use DBIx::Skinny::Profiler;
Mock::Basic->_attributes->{profiler} = DBIx::Skinny::Profiler->new;

subtest 'duplicate_update' => sub {
    my $row = Mock::Basic->single('mock_basic',{
        id => 1,
    });
    Mock::Basic->profiler->reset;
    $row->update({
        name => 'ruby',
    });
    is +Mock::Basic->profiler->query_log->[0] , 'UPDATE mock_basic SET `name` = ? WHERE (id = ?) :binds ruby, 1';
    Mock::Basic->profiler->reset;
    $row->update({
        id => 1,
    });
    is +Mock::Basic->profiler->query_log->[0] , 'UPDATE mock_basic SET `id` = ? WHERE (id = ?) :binds 1, 1';
    Mock::Basic->profiler->reset;
};

done_testing;
