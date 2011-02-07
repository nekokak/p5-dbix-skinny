use t::Utils;
use Test::More;
use Mock::Basic;

my $row_class = Mock::Basic->_get_row_class('select * from foo', '');
isa_ok $row_class, 'Mock::Basic::Row';
isa_ok $row_class, 'DBIx::Skinny::Row';

done_testing;



