use t::Utils;
use Mock::Trigger;
use Test::Declare;

plan tests => blocks;

describe 'trigger test' => run {
    init {
        Mock::Trigger->setup_test_db;
    };

    test 'schema info' => run {
        is +Mock::Trigger->schema, 'Mock::Trigger::Schema';

        my $info = Mock::Trigger->schema->schema_info;
        is_deeply $info,{
            mock_trigger_pre => {
                pk      => 'id',
                columns => [
                    'id',
                    'name',
                ],
                trigger => {
                    pre_insert  => $info->{mock_trigger_pre}->{trigger}->{pre_insert},
                    post_insert => $info->{mock_trigger_pre}->{trigger}->{post_insert},
                    pre_update  => $info->{mock_trigger_pre}->{trigger}->{pre_update},
                    post_update => $info->{mock_trigger_pre}->{trigger}->{post_update},
                    pre_delete  => $info->{mock_trigger_pre}->{trigger}->{pre_delete},
                    post_delete => $info->{mock_trigger_pre}->{trigger}->{post_delete},
                },
            },
            mock_trigger_post => {
                pk      => 'id',
                columns => [
                    'id',
                    'name',
                ],
            },
            mock_trigger_post_delete => {
                pk      => 'id',
                columns => [
                    'id',
                    'name',
                ],
            },
        };
        isa_ok +Mock::Trigger->dbh, 'DBI::db';
    };

    test 'pre_insert/post_insert' => run {
        my $row = Mock::Trigger->insert('mock_trigger_pre',{
            id   => 1,
        });
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->name, 'pre_insert_s';

        my $p_row = Mock::Trigger->single('mock_trigger_post',{id => 1});
        isa_ok $p_row, 'DBIx::Skinny::Row';
        is $p_row->name, 'post_insert';
    };

    test 'pre_update/post_update' => run {
        ok +Mock::Trigger->update('mock_trigger_pre',{});

        my $p_row = Mock::Trigger->single('mock_trigger_post',{id => 1});
        isa_ok $p_row, 'DBIx::Skinny::Row';
        is $p_row->name, 'post_update';

    };

    test 'pre_delete/post_delete' => run {
        Mock::Trigger->delete('mock_trigger_pre',{});

        is +Mock::Trigger->count('mock_trigger_post', 'id',{}), 0;

        my $row = Mock::Trigger->single('mock_trigger_post_delete',{id => 1});
        isa_ok $row, 'DBIx::Skinny::Row';
        is $row->name, 'post_delete';
    };
};

