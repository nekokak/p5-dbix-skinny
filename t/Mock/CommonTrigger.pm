package Mock::CommonTrigger;
use DBIx::Skinny setup => +{
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
};

sub setup_test_db {
    my $db = shift;
    $db->do(q{
        CREATE TABLE mock_triggered (
            id         INT,
            created_at TEXT,
            updated_at TEXT
        )
    });
}

package Mock::CommonTrigger::Schema;
use DBIx::Skinny::Schema;

install_table mock_triggered => schema {
    pk 'id';
    columns qw/id created_at updated_at/;
};

install_common_trigger pre_insert => sub {
    my ($self, $args) = @_;
    $args->{created_at} ||= 'now';
};

install_common_trigger pre_insert => sub {
    my ($self, $args) = @_;
    $args->{created_at} .= '_s';
};

1;

