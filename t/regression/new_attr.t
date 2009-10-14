use t::Utils;
use Mock::Basic;
use Test::Declare;

plan tests => blocks;

describe 'new method bug' => run {
    test 'do new' => run {
        isa_ok +Mock::Basic->dbd, 'DBIx::Skinny::DBD::SQLite';
        my $db = Mock::Basic->new;
        isa_ok $db->dbd, 'DBIx::Skinny::DBD::SQLite';
        isa_ok +Mock::Basic->dbd, 'DBIx::Skinny::DBD::SQLite';
    };
};

