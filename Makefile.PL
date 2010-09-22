use inc::Module::Install;
name 'DBIx-Skinny';
all_from 'lib/DBIx/Skinny.pm';

requires 'UNIVERSAL::require';
requires 'Carp';
requires 'DBI';
requires 'Digest::SHA1';
requires 'Scalar::Util';
requires 'IO::Handle';

author_tests('xt');

test_requires 'Test::More' => '0.94';
test_requires 'Test::Exception';
test_requires 'Test::Output';
test_requires 'Test::SharedFork' => 0.15;

tests 't/*.t t/*/*.t';

auto_set_repository;
WriteAll;
