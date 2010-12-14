use t::Utils;
use Mock::ErrRow;
use Mock::ErrRowChild;
use Test::More;

Mock::ErrRow->setup_test_db;
Mock::ErrRowChild->setup_test_db;

eval{
    Mock::ErrRow->insert('mock_err_row',{
        id   => 1,
        name => 'perl',
    });

};
ok $@;
$@='';

eval{
    Mock::ErrRowChild->insert('mock_err_child_row',{
        id   => 1,
        name => 'perl',
    });
};
ok $@;

done_testing;

