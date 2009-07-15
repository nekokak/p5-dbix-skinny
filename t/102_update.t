use t::Utils;
use Mock::Basic;
use Test::Declare;

plan tests => blocks;

describe 'update test' => run {
    init {
        Mock::Basic->setup_test_db;
        Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
    };

    test 'update mock_basic data' => run {
        ok +Mock::Basic->update('mock_basic',{name => 'python'},{id => 1});
        my $row = Mock::Basic->single('mock_basic',{id => 1});

        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->name, 'python';
    };

    test 'row object update' => run {
        my $row = Mock::Basic->single('mock_basic',{id => 1});
        is $row->name, 'python';

        ok $row->update({name => 'perl'});
        my $new_row = Mock::Basic->single('mock_basic',{id => 1});
        is $new_row->name, 'perl';
    };

    test 'row data set and update' => run {
        my $row = Mock::Basic->single('mock_basic',{id => 1});
        is $row->name, 'perl';

        $row->set(name => 'ruby');

        is $row->name, 'ruby';

        my $row2 = Mock::Basic->single('mock_basic',{id => 1});
        is $row2->name, 'perl';

        ok $row->update;
        my $new_row = Mock::Basic->single('mock_basic',{id => 1});
        is $new_row->name, 'ruby';
    };

    test 'scalarref update' => run {
        my $row = Mock::Basic->single('mock_basic',{id => 1});
        is $row->name, 'ruby';

        ok $row->update({name => '1'});
        my $new_row = Mock::Basic->single('mock_basic',{id => 1});
        is $new_row->name, '1';

        $new_row->update({name => \'name + 1'});

        is +Mock::Basic->single('mock_basic',{id => 1})->name, 2;
    };
};

