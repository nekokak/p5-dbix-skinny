use t::Utils;
use Mock::UTF8;
use Test::Declare;

plan tests => blocks;

describe 'utf8 test' => run {
    init {
        Mock::UTF8->setup_test_db;
    };

    test 'insert mock_utf8 data' => run {
        my $row = Mock::UTF8->insert('mock_utf8',{
            id   => 1,
            name => 'ぱーる',
        });

        isa_ok $row, 'DBIx::Skinny::Row';
        ok utf8::is_utf8($row->name);
        is $row->name, 'ぱーる';
    };

    test 'update mock_utf8 data' => run {
        ok +Mock::UTF8->update('mock_utf8',{name => 'るびー'},{id => 1});
        my $row = Mock::UTF8->single('mock_utf8',{id => 1});

        isa_ok $row, 'DBIx::Skinny::Row';
        ok utf8::is_utf8($row->name);
        is $row->name, 'るびー';
    };
};

