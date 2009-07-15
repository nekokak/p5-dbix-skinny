use t::Utils;
use Mock::Basic;
use Test::Declare;

plan tests => blocks;

describe 'search test' => run {
    init {
        Mock::Basic->setup_test_db;
        Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
        Mock::Basic->insert('mock_basic',{
            id   => 2,
            name => 'python',
        });
    };

    test 'search' => run {
        my $itr = Mock::Basic->search('mock_basic',{id => 1});
        isa_ok $itr, 'DBIx::Skinny::Iterator';

        my $row = $itr->first;
        isa_ok $row, 'DBIx::Skinny::Row';

        is $row->id, 1;
        is $row->name, 'perl';
    };

    test 'search without where' => run {
        my $itr = Mock::Basic->search('mock_basic');

        my $row = $itr->next;
        isa_ok $row, 'DBIx::Skinny::Row';

        is $row->id, 1;
        is $row->name, 'perl';

        my $row2 = $itr->next;

        isa_ok $row2, 'DBIx::Skinny::Row';

        is $row2->id, 2;
        is $row2->name, 'python';
    };
};

