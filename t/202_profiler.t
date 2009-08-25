use strict;
use warnings;
use utf8;
use Test::Declare;

use lib './t';
use DBIx::Skinny::Profiler;

plan tests => blocks;

my $profiler = DBIx::Skinny::Profiler->new;

describe 'profiler test' => run {
    test 'record query' => run {
        $profiler->record_query(q{SELECT * FROM user});
        is_deeply $profiler->query_log, [
            q{SELECT * FROM user},
        ];

    };

    test 'record query /_normalize' => run {
        $profiler->record_query(q{
            SELECT
                id, name
            FROM
                user
            WHERE
                name like "%neko%"
        });
        is_deeply $profiler->query_log, [
            q{SELECT * FROM user},
            q{SELECT id, name FROM user WHERE name like "%neko%"},
        ];
    };

    test 'reset' => run {
        $profiler->reset;
        is_deeply $profiler->query_log, [];
    };

    test 'recorde bind values' => run {
        $profiler->record_query(q{
            SELECT id FROM user WHERE id = ?
        },[1]);
        is_deeply $profiler->query_log, [
            q{SELECT id FROM user WHERE id = ? :binds 1},
        ];

        $profiler->record_query(q{
            SELECT id FROM user WHERE (id = ? OR id = ?)
        },[1, 2]);

        $profiler->record_query(q{
            INSERT INTO user (name) VALUES (?)
        },[undef]);

        is_deeply $profiler->query_log, [
            q{SELECT id FROM user WHERE id = ? :binds 1},
            q{SELECT id FROM user WHERE (id = ? OR id = ?) :binds 1, 2},
            q{INSERT INTO user (name) VALUES (?) :binds undef},
        ];
    };
};

