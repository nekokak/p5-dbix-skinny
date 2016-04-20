use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;
Mock::Basic->_attributes->{profile} = 1;

subtest 'quote sql by sqlite' => sub {
    require DBIx::Skinny::Profiler;
    local Mock::Basic->_attributes->{profiler} = DBIx::Skinny::Profiler->new;
    my $row = Mock::Basic->insert('mock_basic',{
        id   => 1,
        name => 'perl',
    });
    ok +Mock::Basic->profiler->query_log->[0] =~ m/INSERT INTO mock_basic \(`(\w+)`, `(\w+)`\) VALUES \(\?, \?\) :binds (\w+), (\w+)/;
    is_deeply {$1 => $3, $2 => $4}, {id => 1, name => 'perl'};
    $row->update({name => 'ruby'});
    is +Mock::Basic->profiler->query_log->[1], 'UPDATE mock_basic SET `name` = ? WHERE (id = ?) :binds ruby, 1';
};

done_testing;

