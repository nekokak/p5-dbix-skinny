package DBIx::Skinny::DBD::Oracle;
use strict;
use warnings;
use DBIx::Skinny::SQL::Oracle;

sub last_insert_id {
    return;
}

sub sql_for_unixtime {
    "(cast(SYS_EXTRACT_UTC(current_timestamp) as date) - date '1900-01-01') * 24 * 60 * 60";
}

sub quote    { '"' }
sub name_sep { '.' }

sub bulk_insert {
    my ($skinny, $table, $args) = @_;

    $skinny->dbh->begin_work;

        for my $arg ( @{$args} ) {
            $skinny->insert($table, $arg);
        }

    $skinny->dbh->commit;

    return 1;
}

sub query_builder_class { 'DBIx::Skinny::SQL::Oracle' }

1;
