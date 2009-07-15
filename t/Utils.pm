package t::Utils;
use strict;
use warnings;
use utf8;
use Test::More;
use lib './t';

BEGIN {
  eval "use DBD::SQLite";
  plan skip_all => 'needs DBD::SQLite for testing' if $@;
}

sub import {
    strict->import;
    warnings->import;
    utf8->import;
}

1;

