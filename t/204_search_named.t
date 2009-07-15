use t::Utils;
use Mock::Basic;
use Test::Declare;

plan tests => blocks;

describe 'search_named test' => run {
    init {
        Mock::Basic->setup_test_db;
        Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
        Mock::Basic->insert('mock_basic',{
            id   => 2,
            name => 'ruby',
        });
    };

    test 'search_named' => run {
        my $itr = Mock::Basic->search_named(q{SELECT * FROM mock_basic WHERE id = :id}, {id => 1});
        isa_ok $itr, 'DBIx::Skinny::Iterator';

        my $row = $itr->first;
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->id , 1;
        is $row->name, 'perl';
    };

    test 'search_named' => run {
        my $itr = Mock::Basic->search_named(q{SELECT * FROM mock_basic WHERE id = :id OR name = :name}, {id => 1, name => 'ruby'});
        isa_ok $itr, 'DBIx::Skinny::Iterator';

        my @row = $itr->all;
        isa_ok $row[0], 'DBIx::Skinny::Row';
        is $row[0]->id , 1;
        is $row[0]->name, 'perl';
        isa_ok $row[1], 'DBIx::Skinny::Row';
        is $row[1]->id , 2;
        is $row[1]->name, 'ruby';
    };

    test 'search_named' => run {
        Mock::Basic->attribute->{profile} = 1;
        my $itr = Mock::Basic->search_named(q{SELECT * FROM mock_basic WHERE id = :id limit %d}, {id => 1},[100]);
        isa_ok $itr, 'DBIx::Skinny::Iterator';

        my $row = $itr->first;
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->id , 1;
        is $row->name, 'perl';

        is_deeply +Mock::Basic->profiler->query_log, ['SELECT * FROM mock_basic WHERE id = ? limit 100 :binds 1'];
    };
};

