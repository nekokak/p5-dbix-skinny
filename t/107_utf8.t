use t::Utils;
use Mock::UTF8;
use Mock::Basic;
use Test::More;
use Encode ();

Mock::UTF8->setup_test_db;
Mock::Basic->setup_test_db;

subtest 'insert mock_utf8 data' => sub {
    my $row = Mock::UTF8->insert('mock_utf8',{
        id   => 1,
        name => 'ぱーる',
    });

    isa_ok $row, 'DBIx::Skinny::Row';
    ok utf8::is_utf8($row->name);
    is $row->name, 'ぱーる';
    done_testing;
};

subtest 'update mock_utf8 data' => sub {
    ok +Mock::UTF8->update('mock_utf8',{name => 'るびー'},{id => 1});
    my $row = Mock::UTF8->single('mock_utf8',{id => 1});

    isa_ok $row, 'DBIx::Skinny::Row';
    ok utf8::is_utf8($row->name);
    is $row->name, 'るびー';
    done_testing;
};

subtest 'mock_basic data should not enable utf8 flag' => sub {
    ok +Mock::Basic->insert('mock_basic',{name => 'るびー'},{id => 1});
    my $row = Mock::Basic->single('mock_basic',{id => 1});

    isa_ok $row, 'DBIx::Skinny::Row';
    ok !utf8::is_utf8($row->name);
    is $row->name, Encode::encode_utf8('るびー');
    done_testing;
};

unlink qw{./db1.db};

done_testing;
