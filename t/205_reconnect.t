use strict;
use warnings;
use utf8;
use Test::Declare;

use lib './t';
use Mock::Basic;

plan tests => blocks;

describe 'reconnect test' => run {
    init {
        Mock::Basic->reconnect(
            {
                dsn => 'dbi:SQLite:./db1.db',
                username => '',
                password => '',
            }
        );
        Mock::Basic->setup_test_db;
    };

    test 'db1.db ok' => run {
        isa_ok +Mock::Basic->dbh, 'DBI::db';
        Mock::Basic->insert('mock_basic',
            {
                id   => 1,
                name => 'perl',
            }
        );
        
        my $itr = Mock::Basic->search('mock_basic',{id => 1});
        isa_ok $itr, 'DBIx::Skinny::Iterator';

        my $row = $itr->first;
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->id , 1;
        is $row->name, 'perl';
    };

    init {
        Mock::Basic->reconnect(
            {
                dsn => 'dbi:SQLite:./db2.db',
                username => '',
                password => '',
            }
        );
        Mock::Basic->setup_test_db;
    };
    test 'db2.db ok' => run {
        isa_ok +Mock::Basic->dbh, 'DBI::db';
        Mock::Basic->insert('mock_basic',
            {
                id   => 1,
                name => 'ruby',
            }
        );

        my $itr = Mock::Basic->search('mock_basic',{id => 1});
        isa_ok $itr, 'DBIx::Skinny::Iterator';

        my $row = $itr->first;
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->id , 1;
        is $row->name, 'ruby';
    };

    init {
        Mock::Basic->reconnect(
            {
                dsn => 'dbi:SQLite:./db1.db',
                username => '',
                password => '',
            }
        );
    };
    test 'db1.db ok' => run {
        my $itr = Mock::Basic->search('mock_basic',{id => 1});
        isa_ok $itr, 'DBIx::Skinny::Iterator';

        my $row = $itr->first;
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->id , 1;
        is $row->name, 'perl';
    };

    init {
        Mock::Basic->reconnect();
    };
    test 'db1.db ok' => run {
        my $itr = Mock::Basic->search('mock_basic',{id => 1});
        isa_ok $itr, 'DBIx::Skinny::Iterator';

        my $row = $itr->first;
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->id , 1;
        is $row->name, 'perl';
    };


    cleanup {
        unlink qw{./db1.db db2.db};
    };
};

