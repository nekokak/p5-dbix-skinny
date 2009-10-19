use t::Utils;
use Mock::Inflate;
use Mock::Inflate::Name;
use Test::Declare;

plan tests => blocks;

describe 'inflate/deflate test' => run {
    init {
        Mock::Inflate->setup_test_db;
    };

    test 'insert mock_inflate data' => run {
        my $name = Mock::Inflate::Name->new(name => 'perl');

        my $row = Mock::Inflate->insert('mock_inflate',{
            id   => 1,
            name => $name,
        });

        isa_ok $row, 'DBIx::Skinny::Row';
        isa_ok $row->name, 'Mock::Inflate::Name';
        is $row->name->name, 'perl';
    };

    test 'update mock_inflate data' => run {
        my $name = Mock::Inflate::Name->new(name => 'ruby');

        ok +Mock::Inflate->update('mock_inflate',{name => $name},{id => 1});
        my $row = Mock::Inflate->single('mock_inflate',{id => 1});

        isa_ok $row, 'DBIx::Skinny::Row';
        isa_ok $row->name, 'Mock::Inflate::Name';
        is $row->name->name, 'ruby';
    };

    test 'update row' => run {
        my $row = Mock::Inflate->single('mock_inflate',{id => 1});
        my $name = $row->name;
        $name->name('perl');
        $row->update({ name => $name });
        isa_ok $row->name, 'Mock::Inflate::Name';
        is $row->name->name, 'perl';

        my $updated = Mock::Inflate->single('mock_inflate',{id => 1});
        isa_ok $updated->name, 'Mock::Inflate::Name';
        is $updated->name->name, 'perl';
    };
};

