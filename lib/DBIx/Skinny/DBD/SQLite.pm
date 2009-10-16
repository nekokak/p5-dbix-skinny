package DBIx::Skinny::DBD::SQLite;
use strict;
use warnings;
use DBIx::Skinny::SQL;

sub last_insert_id { $_[1]->func('last_insert_rowid') }

sub sql_for_unixtime { return time() }

sub quote    { '`' }
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

sub query_builder_class { 'DBIx::Skinny::SQL' }

1;

