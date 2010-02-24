use t::Utils;
use Mock::Basic;
use Test::More;

subtest 'do new' => sub {
    isa_ok +Mock::Basic->dbd, 'DBIx::Skinny::DBD::SQLite';
    my $db = Mock::Basic->new;
    isa_ok $db->dbd, 'DBIx::Skinny::DBD::SQLite';
    isa_ok +Mock::Basic->dbd, 'DBIx::Skinny::DBD::SQLite';
    done_testing;
};

done_testing;
