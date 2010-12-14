use t::Utils;
use Mock::Basic;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

subtest q{Can't locate object method "_make_row_class" via package} => sub {
    is +Mock::Basic->_mk_row_class('SQL'), 'Mock::Basic::Row';

    done_testing;
};

done_testing;
