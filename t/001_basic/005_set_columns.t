use t::Utils;
use Mock::Basic;
use Test::Builder;
use Test::More;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

sub _normalize_column {
    my ($cols, $column_list) = @_;

    # shallow copy
    my @column_list = @$column_list;

    my %hash;
    for my $k (@$cols) {
        my $v = $k =~ /\?/ ? shift @column_list : undef;
        if (exists $hash{$k}) {
            $hash{$k} = [sort { $a->[0] cmp $b->[1] } (@{$hash{$k}}, $v)];
        } else {
            $hash{$k} = [$v];
        }
    }

    \%hash;
}

sub _is_right_column {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my (
        $result_cols, $expect_cols, $result_column_list, $expect_column_list,
    ) = @_;
    is_deeply _normalize_column($result_cols, $result_column_list),
              _normalize_column($expect_cols, $expect_column_list);
}

subtest 'insert mode' => sub {
    my ($cols, $column_list) = Mock::Basic->_set_columns(+{id => 1, name => 'nekokak'}, 1);

    _is_right_column $cols, +['?','?'], $column_list, [
        [
            'name',
            'nekokak',
        ],
        [
            'id',
            1,
        ]
    ];
    done_testing;
};

subtest 'insert mode / scalarref' => sub {
    my ($cols, $column_list) = Mock::Basic->_set_columns(+{id => 1, name => \'NOW ()'}, 1);

    _is_right_column $cols, +[
        'NOW ()',
        '?',
    ], $column_list, [
        [
            'id',
            1,
        ]
    ];
    done_testing;
};

subtest 'update mode' => sub {
    my ($cols, $column_list) = Mock::Basic->_set_columns(+{id => 1, name => 'nekokak'}, 0);

    _is_right_column $cols, +[
        '`name` = ?',
        '`id` = ?',
    ], $column_list, [
        [
            'name',
            'nekokak',
        ],
        [
            'id',
            1,
        ]
    ];
    done_testing;
};

subtest 'update mode / scalarref' => sub {
    my ($cols, $column_list) = Mock::Basic->_set_columns(+{id => 1, name => \'NOW()'}, 0);

    _is_right_column $cols, +[
        '`name` = NOW()',
        '`id` = ?',
    ], $column_list, [
        [
            'id',
            1,
        ]
    ];
    done_testing;
};

done_testing;
