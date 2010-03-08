package DBIx::Skinny::DBD::Pg;
use strict;
use warnings;
use base 'DBIx::Skinny::DBD::Base';

sub last_insert_id {
    my ($self, $dbh, $sth, $args) = @_;
    $dbh->last_insert_id(undef, undef, $args->{table}, undef);
}

sub sql_for_unixtime { "TRUNC(EXTRACT('epoch' from NOW()))" }

sub quote    { '"' }
sub name_sep { '.' }

1;

