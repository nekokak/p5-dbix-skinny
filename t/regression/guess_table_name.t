use t::Utils;
use Mock::Basic;
use Test::Declare;

plan tests => blocks;

describe '_guess_table_name method bug' => run {
    test 'do _guess_table_name' => run {
        is +Mock::Basic->_guess_table_name(q{SELECT * FROM hoo, bar  WHERE name = 'nekokak'}), 'hoo';
    };
};

