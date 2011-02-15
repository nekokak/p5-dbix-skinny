use strict;
use warnings;
use xt::Utils::mysql;
use t::Utils;
use Mock::Basic;
use Mock::Trigger;
use Test::More;
use Tie::IxHash;

my $dbh = t::Utils->setup_dbh;
Mock::Basic->set_dbh($dbh);
Mock::Basic->setup_test_db;

subtest 'bulk_insert method' => sub {
    my @data;
    my %row;
    tie %row, 'Tie::IxHash';
    %row = (
        id => 1,
        name => 'perl',
    );
    push @data, \%row;
    my %row2;
    tie %row2, 'Tie::IxHash';
    %row2 = (
        name => 1,
        id => 2,
    );
    push @data, \%row2;
    push @data,{
        id   => 3,
        name => 'python',
    };
    Mock::Basic->bulk_insert('mock_basic', \@data);
    is +Mock::Basic->count('mock_basic', 'id'), 3;
};

done_testing;

