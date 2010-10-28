package Mock::CustomProfiler;
use t::Utils;
use Mock::CustomProfiler::Profiler;
use DBIx::Skinny 
    profiler => Mock::CustomProfiler::Profiler->new,
    connect_info => +{
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
    }
;

sub setup_test_db {
    shift->do(q{
        CREATE TABLE mock_custom_profiler (
            id   INT,
            name TEXT
        )
    });
}

1;

