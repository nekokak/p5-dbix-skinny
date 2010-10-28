package Mock::CustomProfiler;
use t::Utils;
use Mock::CustomProfiler::Profiler;
use DBIx::Skinny connect_info => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
    profiler => Mock::CustomProfiler::Profiler->new,
};

sub setup_test_db {
    shift->do(q{
        CREATE TABLE mock_custom_profiler (
            id   INT,
            name TEXT
        )
    });
}

1;

