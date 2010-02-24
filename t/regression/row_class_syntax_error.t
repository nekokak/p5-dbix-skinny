use t::Utils;
use Mock::ErrRow;
use Mock::ErrRowChild;
use Test::More;
use Test::Exception;

Mock::ErrRow->setup_test_db;
Mock::ErrRowChild->setup_test_db;

dies_ok(
    sub {
        Mock::ErrRow->insert('mock_err_row',{
            id   => 1,
            name => 'perl',
        });
    }
);

dies_ok(
    sub {
        Mock::ErrRowChild->insert('mock_err_child_row',{
            id   => 1,
            name => 'perl',
        });
    }
);

done_testing;

