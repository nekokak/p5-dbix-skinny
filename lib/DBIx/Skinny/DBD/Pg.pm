package DBIx::Skinny::DBD::Pg;
use strict;
use warnings;
use base 'DBIx::Skinny::DBD::Base';
use DBD::Pg qw(:pg_types);

sub sql_for_unixtime { "TRUNC(EXTRACT('epoch' from NOW()))" }

sub quote    { '"' }
sub name_sep { '.' }

sub bind_param_attributes {
    my($self, $data_type) = @_;
    if ($data_type) {
        if ($data_type eq  'bytea' ) {
            return { pg_type => DBD::Pg::PG_BYTEA };
        }
    }
    return;
}

1;

