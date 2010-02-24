use t::Utils;
use Mock::Basic;
use Test::More;

Mock::Basic->setup_test_db;
Mock::Basic->insert('mock_basic',{
    id   => 1,
    name => 'perl',
});

subtest 'single' => sub {
    my $row = Mock::Basic->single('mock_basic',{id => 1});
    is $row->id, 1;
    is $row->name, 'perl';
    done_testing;
};

done_testing;
