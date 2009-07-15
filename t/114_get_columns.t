use t::Utils;
use Mock::Basic;
use Test::Declare;

plan tests => blocks;

describe 'get_columns test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'get_columns' => run {
        my $row = Mock::Basic->insert('mock_basic',{
            id   => 1,
            name => 'perl',
        });
        isa_ok $row, 'DBIx::Skinny::Row';

        my $data = $row->get_columns;
        ok $data;
        is $data->{id}, 1;
        is $data->{name}, 'perl';
    };

    test 'get_columns multi line' => run {
        my $row = Mock::Basic->insert('mock_basic',{
            id   => 2,
            name => 'ruby',
        });
        isa_ok $row, 'DBIx::Skinny::Row';

        my $data = [map {$_->get_columns} Mock::Basic->search('mock_basic')->all];
        is_deeply $data, [
            {
                name => 'perl',
                id   => 1,
            },
            {
                name => 'ruby',
                id   => 2,
            }
        ];
    };
};

