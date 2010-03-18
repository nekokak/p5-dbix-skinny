use inc::Module::Install;
name 'DBIx-Skinny';
all_from 'lib/DBIx/Skinny.pm';

requires 'UNIVERSAL::require';
requires 'Carp';
requires 'DBI';
requires 'Digest::SHA1';
requires 'Scalar::Util';

author_tests('xt');

build_requires 'Test::More' => '0.94';
build_requires 'Test::Exception';
build_requires 'Test::Output';

use_test_base;
auto_include;
auto_set_repository;
WriteAll;
