use strict;
use warnings;
use t::Utils;
use Mock::CustomProfiler;
use Test::More;

isa_ok(Mock::CustomProfiler->profiler, "Mock::CustomProfiler::Profiler", "it should be able to replace profiler class");
Mock::CustomProfiler->attribute->{profile} = 1;
Mock::CustomProfiler->setup_test_db;
Mock::CustomProfiler->search('mock_custom_profiler', { });
ok(Mock::CustomProfiler->profiler->query_log, 'query log recorded');

done_testing();
