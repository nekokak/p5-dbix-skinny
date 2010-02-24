use t::Utils;
use Mock::UTF8;
use Test::More;

Mock::UTF8->setup_test_db;

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

done_testing;
