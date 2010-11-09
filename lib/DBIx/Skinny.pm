package DBIx::Skinny;
use strict;
use warnings;

our $VERSION = '0.0727';

use DBI;
use DBIx::Skinny::Iterator;
use DBIx::Skinny::DBD;
use DBIx::Skinny::Row;
use DBIx::Skinny::Transaction;
use Digest::SHA1 ();
use Carp ();
use Storable ();

sub import {
    my ($class, %opt) = @_;

    return if $class ne 'DBIx::Skinny';

    my $caller = caller;
    my $connect_info = $opt{connect_info};
    if (! $connect_info ) {
        if ( $connect_info = $opt{setup} ) {
            Carp::carp( "use DBIx::Skinny setup => { ... } has been deprecated. Please use connect_info instead" );
        } else {
            $connect_info = {};
        }
    }

    my $profiler = $opt{profiler};
    if (! $profiler ) {
        if ( $profiler = $connect_info->{profiler} ) {
            Carp::carp( "use DBIx::Skinny connect_info => { profiler => ... } has been deprecated. Please use use DBIx::Skinny profiler => ... instead" );
        } elsif ($ENV{SKINNY_TRACE}) {
            require DBIx::Skinny::Profiler::Trace;
            $profiler = DBIx::Skinny::Profiler::Trace->new;
        } elsif ($ENV{SKINNY_PROFILE}) {
            require DBIx::Skinny::Profiler;
            $profiler = DBIx::Skinny::Profiler->new;
        }
    }
                
    my $schema = $opt{schema} || "$caller\::Schema";

    my $dbd_type = _dbd_type($connect_info);
    my $_attributes = +{
        check_schema    => defined $connect_info->{check_schema} ? $connect_info->{check_schema} : 1,
        dsn             => $connect_info->{dsn},
        username        => $connect_info->{username},
        password        => $connect_info->{password},
        connect_options => $connect_info->{connect_options},
        on_connect_do   => $connect_info->{on_connect_do},
        dbh             => $connect_info->{dbh}||undef,
        dbd             => $dbd_type ? DBIx::Skinny::DBD->new($dbd_type) : undef,
        schema          => $schema,
        profiler        => $profiler,
        klass           => $caller,
        row_class_map   => +{},
        active_transaction => 0,
        suppress_row_objects => 0,
        last_pid => $$,
    };

    {
        no strict 'refs';
        push @{"${caller}::ISA"}, $class;
        *{"$caller\::_attributes"} = sub { ref $_[0] ? $_[0] : $_attributes };
        *{"$caller\::attribute"} = sub { Carp::carp("attribute has been deprecated."); $_[0]->_attributes };
    }

    eval "use $schema"; ## no critic
    if ( $@ ) {
        # accept schema class declaration within base class.
        (my $schema_file = $schema) =~ s|::|/|g;
        die $@ if $@ && $@ !~ /Can't locate $schema_file\.pm in \@INC/;
    }

    if ($opt{auto_row_class}) {
        my $schema_info = $schema->schema_info;
        for my $table (keys %$schema_info) {
            my $row_class = join '::', $caller, 'Row', _camelize($table);

            eval "use $row_class"; ## no critic
            if ($@) { no strict 'refs'; @{"$row_class\::ISA"} = ('DBIx::Skinny::Row') };

            $_attributes->{row_class_map}->{$table} = $row_class;
        }
    }

    strict->import;
    warnings->import;
}

sub new {
    my ($class, $connection_info) = @_;
    my $attr = $class->_attributes;

    $attr->{last_pid} = $$;

    my %unstorable_attribute;
    for my $key ( qw/dbd profiler dbh connect_options on_connect_do / ) {
        $unstorable_attribute{$key} = delete $attr->{$key};
    }

    my $self = bless Storable::dclone($attr), $class;

    # restore.
    for my $key ( keys %unstorable_attribute ) {
        $attr->{$key} = $unstorable_attribute{$key};
    }


    if ($connection_info) {

        $self->_attributes->{profiler} = $unstorable_attribute{profiler};

        if ( $connection_info->{on_connect_do} ) {
            $self->_attributes->{on_connect_do} = $connection_info->{on_connect_do};
        } else {
            $self->_attributes->{on_connect_do} = $unstorable_attribute{on_connect_do};
        }

        if ($connection_info->{dbh}) {
            $self->connect_info($connection_info);
            $self->set_dbh($connection_info->{dbh});
        } else {
            $self->connect_info($connection_info);
            $self->reconnect;
        }

    } else {
        for my $key ( keys %unstorable_attribute ) {
            $self->_attributes->{$key} = $unstorable_attribute{$key};
        }
    }

    return $self;
}

my $schema_checked = 0;
sub schema { 
    my $attribute = $_[0]->_attributes;
    my $schema = $attribute->{schema};
    if ( $attribute->{check_schema} && !$schema_checked ) {
        do {
            no strict 'refs';
            unless ( defined *{"@{[ $schema ]}::schema_info"} ) {
                die "Cannot use schema $schema ( is it really loaded? )";
            }
        };
        $schema_checked++;
    }
    return $schema;
}

sub profiler {
    my ($class, $sql, $bind) = @_;
    my $attr = $class->_attributes;
    if ($attr->{profiler} && $sql) {
        $attr->{profiler}->record_query($sql, $bind);
    }
    return $attr->{profiler};
}

sub suppress_row_objects {
    my ($class, $mode) = @_;
    return $class->_attributes->{suppress_row_objects} unless defined $mode;
    $class->_attributes->{suppress_row_objects} = $mode;
}

#--------------------------------------------------------------------------------
# for transaction
sub txn_scope {
    DBIx::Skinny::Transaction->new( @_ );
}

sub txn_begin {
    my $class = shift;
    return if ( ++$class->_attributes->{active_transaction} > 1 );
    $class->profiler("BEGIN WORK");
    $class->dbh->begin_work;
}

sub txn_rollback {
    my $class = shift;
    return unless $class->_attributes->{active_transaction};

    if ( $class->_attributes->{active_transaction} == 1 ) {
        $class->profiler("ROLLBACK WORK");
        $class->dbh->rollback;
        $class->txn_end;
    }
    elsif ( $class->_attributes->{active_transaction} > 1 ) {
        $class->_attributes->{active_transaction}--;
        $class->_attributes->{rollbacked_in_nested_transaction}++;
    }

}

sub txn_commit {
    my $class = shift;
    return unless $class->_attributes->{active_transaction};

    if ( $class->_attributes->{rollbacked_in_nested_transaction} ) {
        Carp::croak "tried to commit but already rollbacked in nested transaction.";
    }
    elsif ( $class->_attributes->{active_transaction} > 1 ) {
        $class->_attributes->{active_transaction}--;
        return;
    }

    $class->profiler("COMMIT WORK");
    $class->dbh->commit;
    $class->txn_end;
}

sub txn_end {
    $_[0]->_attributes->{active_transaction} = 0;
    $_[0]->_attributes->{rollbacked_in_nested_transaction} = 0;
}

#--------------------------------------------------------------------------------
# db handling
sub connect_info {
    my ($class, $connect_info) = @_;

    my $attr = $class->_attributes;
    $attr->{dsn} = $connect_info->{dsn};
    $attr->{username} = $connect_info->{username};
    $attr->{password} = $connect_info->{password};
    $attr->{connect_options} = $connect_info->{connect_options};

    $class->setup_dbd($connect_info);
}

sub connect {
    my $class = shift;

    $class->connect_info(@_) if scalar @_ >= 1;

    my $attr = $class->_attributes;
    my $do_connected;
    if ( !$attr->{dbh} ) {
        $do_connected++;
    }
    $attr->{dbh} ||= DBI->connect(
        $attr->{dsn},
        $attr->{username},
        $attr->{password},
        { RaiseError => 1, PrintError => 0, AutoCommit => 1, %{ $attr->{connect_options} || {} } }
    ) or Carp::croak("Connection error: " . $DBI::errstr);

    if ( $do_connected && $attr->{on_connect_do} ) {
        $class->do_on_connect;
    }

    $attr->{dbh};
}

sub reconnect {
    my $class = shift;
    $class->disconnect();
    $class->connect(@_);
}

sub do_on_connect {
    my $class = shift;

    my $on_connect_do = $class->_attributes->{on_connect_do};
    if (not ref($on_connect_do)) {
        $class->do($on_connect_do);
    } elsif (ref($on_connect_do) eq 'CODE') {
        $on_connect_do->($class);
    } elsif (ref($on_connect_do) eq 'ARRAY') {
        $class->do($_) for @$on_connect_do;
    } else {
        Carp::croak('Invalid on_connect_do: '.ref($on_connect_do));
    }
}

sub disconnect {
    my $class = shift;
    $class->_attributes->{dbh} = undef;
}

sub set_dbh {
    my ($class, $dbh) = @_;
    $class->_attributes->{dbh} = $dbh;
    $class->setup_dbd({dbh => $dbh});
}

sub setup_dbd {
    my ($class, $args) = @_;
    my $dbd_type = _dbd_type($args);
    $class->_attributes->{dbd} = DBIx::Skinny::DBD->new($dbd_type);
}

sub dbd {
    $_[0]->_attributes->{dbd} or do {
        require Data::Dumper;
        Carp::croak("attribute dbd does not exist. does it connected? attribute: @{[ Data::Dumper::Dumper($_[0]->_attributes) ]}");
    };
}

sub dbh {
    my $class = shift;

    my $dbh = $class->connect;
    if ( $class->_attributes->{last_pid} != $$ ) {
        $class->_attributes->{last_pid} = $$;
        $dbh->{InactiveDestroy} = 1;
        $dbh = $class->reconnect;
    }
    unless ($dbh && $dbh->FETCH('Active') && $dbh->ping) {
        $dbh = $class->reconnect;
    }
    $dbh;
}

sub _dbd_type {
    my $args = shift;
    my $dbd_type;
    if ($args->{dbh}) {
        $dbd_type = $args->{dbh}->{Driver}->{Name};
    } elsif ($args->{dsn}) {
        (undef, $dbd_type,) = DBI->parse_dsn($args->{dsn}) or Carp::croak "can't parse DSN: @{[ $args->{dsn} ]}";
    }
    return $dbd_type;
}

#--------------------------------------------------------------------------------
# schema trigger call
sub call_schema_trigger {
    my ($class, $trigger, $schema, $table, $args) = @_;
    $schema->call_trigger($class, $table, $trigger, $args);
}

#--------------------------------------------------------------------------------
sub do {
    my ($class, $sql, $attr, @bind_vars) = @_;
    $class->profiler($sql, @bind_vars ? \@bind_vars : undef);
    eval { $class->dbh->do($sql, $attr, @bind_vars) };
    if ($@) {
        $class->_stack_trace('', $sql, @bind_vars ? \@bind_vars : '', $@);
    }
}

sub count {
    my ($class, $table, $column, $where) = @_;

    my $rs = $class->resultset(
        {
            from   => [$table],
        }
    );

    $rs->add_select("COUNT($column)" =>  'cnt');
    $class->_add_where($rs, $where);

    $rs->retrieve->first->cnt;
}

sub resultset {
    my ($class, $args) = @_;
    $args->{skinny} = $class;
    my $query_builder_class = $class->dbd->query_builder_class;
    $query_builder_class->new($args);
}

sub search {
    my ($class, $table, $where, $opt) = @_;

    my $rs = $class->search_rs($table, $where, $opt);
    $rs->retrieve;
}

sub search_rs {
    my ($class, $table, $where, $opt) = @_;

    my $cols = $opt->{select};
    unless ($cols) {
        my $column_info = $class->schema->schema_info->{$table};
        unless ( $column_info ) {
            Carp::croak("schema_info does not exist for table '$table'");
        }
        $cols = $column_info->{columns};
    }
    my $rs = $class->resultset(
        {
            select => $cols,
            from   => [$table],
        }
    );

    if ( $where ) {
        $class->_add_where($rs, $where);
    }

    $rs->limit(  $opt->{limit}  ) if $opt->{limit};
    $rs->offset( $opt->{offset} ) if $opt->{offset};

    if (my $terms = $opt->{order_by}) {
        $terms = [$terms] unless ref($terms) eq 'ARRAY';
        my @orders;
        for my $term (@{$terms}) {
            my ($col, $case);
            if (ref($term) eq 'HASH') {
                ($col, $case) = each %$term;
            } else {
                $col  = $term;
                $case = 'ASC';
            }
            push @orders, { column => $col, desc => $case };
        }
        $rs->order(\@orders);
    }

    if (my $terms = $opt->{having}) {
        for my $col (keys %$terms) {
            $rs->add_having($col => $terms->{$col});
        }
    }

    $rs->for_update(1) if $opt->{for_update};

    return $rs;
}

sub single {
    my ($class, $table, $where, $opt) = @_;
    $opt->{limit} = 1;
    $class->search($table, $where, $opt)->first;
}

sub search_named {
    my ($class, $sql, $args, $opts, $opt_table_info) = @_;

    $sql = sprintf($sql, @{$opts||[]});
    my %named_bind = %{$args};
    my @bind;
    $sql =~ s{:([A-Za-z_][A-Za-z0-9_]*)}{
        Carp::croak("$1 does not exists in hash") if !exists $named_bind{$1};
        if ( ref $named_bind{$1} && ref $named_bind{$1} eq "ARRAY" ) {
            push @bind, @{ $named_bind{$1} };
            my $tmp = join ',', map { '?' } @{ $named_bind{$1} };
            "( $tmp )";
        } else {
            push @bind, $named_bind{$1};
            '?'
        }
    }ge;

    $class->search_by_sql($sql, \@bind, $opt_table_info);
}

sub search_by_sql {
    my ($class, $sql, $bind, $opt_table_info) = @_;

    my $sth = $class->_execute($sql, $bind);
    return $class->_get_sth_iterator($sql, $sth, $opt_table_info);
}

sub find_or_new {
    my ($class, $table, $args) = @_;
    my $row = $class->single($table, $args);
    unless ($row) {
        $row = $class->hash_to_row($table, $args);
    }
    return $row;
}

sub hash_to_row {
    my ($class, $table, $hash) = @_;

    my $row_class = $class->_mk_row_class($table.$hash, $table);
    my $row = $row_class->new(
        {
            sql            => undef,
            row_data       => $hash,
            skinny         => $class,
            opt_table_info => $table,
        }
    );
    $row->setup;
    $row;
}

sub _get_sth_iterator {
    my ($class, $sql, $sth, $opt_table_info) = @_;

    return DBIx::Skinny::Iterator->new(
        skinny         => $class,
        sth            => $sth,
        sql            => $sql,
        row_class      => $class->_mk_row_class($sql, $opt_table_info),
        opt_table_info => $opt_table_info,
        suppress_objects => $class->suppress_row_objects,
    );
}

sub data2itr {
    my ($class, $table, $data) = @_;

    return DBIx::Skinny::Iterator->new(
        skinny         => $class,
        data           => $data,
        row_class      => $class->_mk_row_class($table.$data, $table),
        opt_table_info => $table,
        suppress_objects => $class->suppress_row_objects,
    );
}

sub _mk_anon_row_class {
    my ($class, $key) = @_;

    my $row_class = 'DBIx::Skinny::Row::C';
    $row_class .= Digest::SHA1::sha1_hex($key);

    my $attr = $class->_attributes;
    $attr->{base_row_class} ||= do {
        my $tmp_base_row_class = join '::', $attr->{klass}, 'Row';
        eval "use $tmp_base_row_class"; ## no critic
        (my $rc = $tmp_base_row_class) =~ s|::|/|g;
        die $@ if $@ && $@ !~ /Can't locate $rc\.pm in \@INC/;

        if ($@) {
            'DBIx::Skinny::Row';
        } else {
            $tmp_base_row_class;
        }
    };
    { no strict 'refs'; @{"$row_class\::ISA"} = ($attr->{base_row_class}); }

    return $row_class;
}

sub _guess_table_name {
    my ($class, $sql) = @_;

    if ($sql =~ /\sfrom\s+([\w]+)\s*/si) {
        return $1;
    }
    return;
}

sub _mk_row_class {
    my ($class, $key, $table) = @_;

    $table ||= $class->_guess_table_name($key)||'';
    my $attr = $class->_attributes;
    my $base_row_class = $attr->{row_class_map}->{$table}||'';

    if ( $base_row_class eq 'DBIx::Skinny::Row' ) {
        return $class->_mk_anon_row_class($key);
    } elsif ($base_row_class) {
        return $base_row_class;
    } elsif ($table) {
        my $tmp_base_row_class = join '::', $attr->{klass}, 'Row', _camelize($table);
        eval "use $tmp_base_row_class"; ## no critic
        (my $rc = $tmp_base_row_class) =~ s|::|/|g;
        die $@ if $@ && $@ !~ /Can't locate $rc\.pm in \@INC/;

        if ($@) {
            $attr->{row_class_map}->{$table} = 'DBIx::Skinny::Row';
            return $class->_mk_anon_row_class($key);
        } else {
            $attr->{row_class_map}->{$table} = $tmp_base_row_class;
            return $tmp_base_row_class;
        }
    } else {
        return $class->_mk_anon_row_class($key);
    }
}

sub _camelize {
    my $s = shift;
    join('', map{ ucfirst $_ } split(/(?<=[A-Za-z])_(?=[A-Za-z])|\b/, $s));
}

sub _quote {
    my ($label, $quote, $name_sep) = @_;

    return $label if $label eq '*';
    return $quote . $label . $quote if !defined $name_sep;
    return join $name_sep, map { $quote . $_ . $quote } split /\Q$name_sep\E/, $label;
}

sub bind_params {
    my($class, $table, $columns, $sth) = @_;

    my $schema = $class->schema;
    my $dbd    = $class->dbd;
    my $i = 1;
    for my $column (@{ $columns }) {
        my($col, $val) = @{ $column };
        my $type = $schema->column_type($table, $col);
        my $attr = $type ? $dbd->bind_param_attributes($type) : undef;

        my $ref = ref $val;
        if ($ref eq 'ARRAY') {
            $sth->bind_param($i++, $_, $attr) for @$val;
        } elsif (not $ref) {
            $sth->bind_param($i++, $val, $attr);
        } else {
            die "you can't set bind value, arrayref or scalar. you set $ref ref value.";
        }
    }
}

sub _insert_or_replace {
    my ($class, $is_replace, $table, $args) = @_;

    my $schema = $class->schema;

    # deflate
    for my $col (keys %{$args}) {
        $args->{$col} = $schema->call_deflate($col, $args->{$col});
    }

    my (@cols, @column_list);
    for my $col (keys %{ $args }) {
        push @cols, $col;
        push @column_list, [$col, $schema->utf8_off($col, $args->{$col})];
    }

    my $dbd = $class->dbd;
    my $quote = $dbd->quote;
    my $name_sep = $dbd->name_sep;
    my $sql = $is_replace ? 'REPLACE' : 'INSERT';
    $sql .= " INTO $table\n";
    $sql .= '(' . join(', ', map {_quote($_, $quote, $name_sep)} @cols) . ')' . "\n" .
            'VALUES (' . join(', ', ('?') x @cols) . ')' . "\n";

    my $sth = $class->_execute($sql, \@column_list, $table);

    my $pk = $class->schema->schema_info->{$table}->{pk};
    my $id =
        defined $pk && defined $args->{$pk} ? $args->{$pk} :
        defined $pk && (ref $pk) eq 'ARRAY' ? undef        :
            $dbd->last_insert_id($class->dbh, $sth, { table => $table })
    ;

    $class->_close_sth($sth);

    if ($id) {
        $args->{$pk} = $id;
    }

    my $row_class = $class->_mk_row_class($sql, $table);
    return $args if $class->suppress_row_objects;

    my $obj = $row_class->new(
        {
            row_data       => $args,
            skinny         => $class,
            opt_table_info => $table,
        }
    );
    $obj->setup;

    $obj;
}

*create = \*insert;
sub insert {
    my ($class, $table, $args) = @_;

    my $schema = $class->schema;
    $class->call_schema_trigger('pre_insert', $schema, $table, $args);

    my $obj = $class->_insert_or_replace(0, $table, $args);

    $class->call_schema_trigger('post_insert', $schema, $table, $obj);

    $obj;
}

sub replace {
    my ($class, $table, $args) = @_;

    my $schema = $class->schema;
    $class->call_schema_trigger('pre_insert', $schema, $table, $args);

    my $obj = $class->_insert_or_replace(1, $table, $args);

    $class->call_schema_trigger('post_insert', $schema, $table, $obj);

    $obj;
}

sub bulk_insert {
    my ($class, $table, $args) = @_;

    my $code = $class->_attributes->{dbd}->can('bulk_insert') or Carp::croak "dbd don't provide bulk_insert method";
    $code->($class, $table, $args);
}

sub update {
    my ($class, $table, $args, $where) = @_;

    my $schema = $class->schema;
    $class->call_schema_trigger('pre_update', $schema, $table, $args);

    # deflate
    my $values = {};
    for my $col (keys %{$args}) {
        $values->{$col} = $schema->call_deflate($col, $args->{$col});
    }

    my $quote = $class->dbd->quote;
    my $name_sep = $class->dbd->name_sep;
    my (@set, @column_list);
    for my $col (keys %{ $args }) {
        my $quoted_col = _quote($col, $quote, $name_sep);
        if (ref($values->{$col}) eq 'SCALAR') {
            push @set, "$quoted_col = " . ${ $values->{$col} };
        } else {
            push @set, "$quoted_col = ?";
            push @column_list, [$col, $schema->utf8_off($col, $values->{$col})];
        }
    }

    my $stmt = $class->resultset;
    $class->_add_where($stmt, $where);
    my @where_values = map {[$_ => $stmt->where_values->{$_}]} @{$stmt->bind_col};
    push @column_list, @where_values;

    my $sql = "UPDATE $table SET " . join(', ', @set) . ' ' . $stmt->as_sql_where;

    my $sth = $class->_execute($sql, \@column_list, $table);
    my $rows = $sth->rows;

    $class->_close_sth($sth);
    $class->call_schema_trigger('post_update', $schema, $table, $rows);

    return $rows;
}

sub update_by_sql {
    my ($class, $sql, $bind) = @_;

    my $sth = $class->_execute($sql, $bind);
    my $rows = $sth->rows;
    $class->_close_sth($sth);

    $rows;
}

sub delete {
    my ($class, $table, $where) = @_;

    my $schema = $class->schema;
    $class->call_schema_trigger('pre_delete', $schema, $table, $where);

    my $stmt = $class->resultset(
        {
            from => [$table],
        }
    );

    $class->_add_where($stmt, $where);

    my $sql = "DELETE " . $stmt->as_sql;
    my @where_values = map {[$_ => $stmt->where_values->{$_}]} @{$stmt->bind_col};
    my $sth = $class->_execute($sql, \@where_values, $table);
    my $rows = $sth->rows;

    $class->call_schema_trigger('post_delete', $schema, $table, $rows);

    $class->_close_sth($sth);
    $rows;
}

sub delete_by_sql {
    my ($class, $sql, $bind) = @_;

    my $sth = $class->_execute($sql, $bind);
    my $rows = $sth->rows;

    $class->_close_sth($sth);

    $rows;
}

*find_or_insert = \*find_or_create;
sub find_or_create {
    my ($class, $table, $args) = @_;
    my $row = $class->single($table, $args);
    return $row if $row;
    $row = $class->insert($table, $args);
    my $pk = $class->schema->schema_info->{$table}->{pk};
    my %args;
    if (ref $pk) {
        for (@$pk) {
            $args{$_} = $row->get_column($_);
        }
    } else {
        $args{$pk} = $class->suppress_row_objects ? $row->{$pk} :$row->get_column($pk);
    }
    $class->single($table, \%args);
}

sub _add_where {
    my ($class, $stmt, $where) = @_;
    for my $col (keys %{$where}) {
        $stmt->add_where($col => $where->{$col});
    }
}

sub _execute {
    my ($class, $stmt, $args, $table) = @_;

    my ($sth, $bind);
    if ($table) {
        $bind = [map {(ref $_->[1]) eq 'ARRAY' ? @{$_->[1]} : $_->[1]} @$args];
        $class->profiler($stmt, $bind);
        eval {
            $sth = $class->dbh->prepare($stmt);
            $class->bind_params($table, $args, $sth);
            $sth->execute;
        };
    } else {
        $bind = $args;
        $class->profiler($stmt, $bind);
        eval {
            $sth = $class->dbh->prepare($stmt);
            $sth->execute(@{$args});
        };
    }

    if ($@) {
        $class->_stack_trace($sth, $stmt, $bind, $@);
    }
    return $sth;
}

# stack trace
sub _stack_trace {
    my ($class, $sth, $stmt, $bind, $reason) = @_;
    require Data::Dumper;

    if ($sth) {
        $class->_close_sth($sth);
    }

    $stmt =~ s/\n/\n          /gm;
    Carp::croak sprintf <<"TRACE", $reason, $stmt, Data::Dumper::Dumper($bind);
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@ DBIx::Skinny 's Exception @@@@@
Reason  : %s
SQL     : %s
BIND    : %s
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TRACE
}

sub _close_sth {
    my ($class, $sth) = @_;
    $sth->finish;
    undef $sth;
}

1;

__END__
=head1 NAME

DBIx::Skinny - simple DBI wrapper/ORMapper

=head1 SYNOPSIS

create your db model base class.

    package Your::Model;
    use DBIx::Skinny connect_info => {
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
    };
    1;
    
create your db schema class.
See DBIx::Skinny::Schema for docs on defining schema class.

    package Your::Model::Schema;
    use DBIx::Skinny::Schema;
    
    install_table user => schema {
        pk 'id';
        columns qw/
            id
            name
        /;
    };
    1;
    
in your execute script.

    use Your::Model;
    
    # insert new record.
    my $row = Your::Model->insert('user',
        {
            id   => 1,
        }
    );
    $row->update({name => 'nekokak'});

    $row = Your::Model->search_by_sql(q{SELECT id, name FROM user WHERE id = ?}, [ 1 ]);
    $row->delete('user');

=head1 DESCRIPTION

DBIx::Skinny is simple DBI wrapper and simple O/R Mapper.
It aims to be lightweight, with minimal dependencies so it's easier to install. 

=head1 ARCHITECTURE

DBIx::Skinny classes are comprised of three distinct components:

=head2 MODEL

The C<model> is where you say 

    package MyApp::Model;
    use DBIx::Skinny;

This is the entry point to using DBIx::Skinny. You connect, insert, update, delete, select stuff using this object.

=head2 SCHEMA

The C<schema> is a simple class that describes your table definitions. Note that this is different from DBIx::Class terms. DBIC's schema is equivalent to DBIx::Skinny's model + schema, where the actual schema information is scattered across the result classes.

In DBIx::Skinny, you simply use DBIx::Skinny::Schema's domain specific languaage to define a set of tables

    package MyApp::Model::Schema;
    use DBIx::Skinny::Schema;

    install_table $table_name => schema {
        pk $primary_key_column;
        columns qw(
            column1
            column2
            column3
        );
    }

    ... and other tables ...

=head2 ROW

Unlike DBIx::Class, you don't need to have a set of classes that represent a row type (i.e. "result" classes in DBIC terms). In DBIx::Skinny, the row objects are blessed into anonymous classes that inherit from DBIx::Skinny::Row, so you don't have to create these classes if you just want to use some simple queries.

If you want to define methods to be performed by your row objects, simply create a row class like so:

    package MyApp::Model::Row::CamelizedTableName;
    use base qw(DBIx::Skinny::Row);

Note that your table name will be camelized using String::CamelCase.

=head1 METHODS

DBIx::Skinny provides a number of methods to all your classes, 

=over

=item $skinny->new([\%connection_info])

create your skinny instance.
It is possible to use it even by the class method.

$connection_info is optional argment.

When $connection_info is specified,
new method connect new DB connection from $connection_info.

When $connection_info is not specified,
it becomes use already setup connection or it doesn't do at all.

example:

    my $db = Your::Model->new;

or

    # connect new database connection.
    my $db = Your::Model->new(+{
        dsn      => $dsn,
        username => $username,
        password => $password,
        connect_options => $connect_options,
    });

=item $skinny->insert($table_name, \%row_data)

insert new record and get inserted row object.

example:

    my $row = Your::Model->insert('user',{
        id   => 1,
        name => 'nekokak',
    });

or

    my $db = Your::Model->new;
    my $row = $db->insert('user',{
        id   => 1,
        name => 'nekokak',
    });

=item $skinny->create($table_name, \%row_data)

insert method alias.

=item $skinny->bulk_insert($table_name, \@rows_data)

Accepts either an arrayref of hashrefs.
each hashref should be a structure suitable
forsubmitting to a Your::Model->insert(...) method.

insert many record by bulk.

example:

    Your::Model->bulk_insert('user',[
        {
            id   => 1,
            name => 'nekokak',
        },
        {
            id   => 2,
            name => 'yappo',
        },
        {
            id   => 3,
            name => 'walf443',
        },
    ]);

=item $skinny->update($table_name, \%update_row_data, [\%update_condition])

$update_condition is optional argment.

update record.

example:

    my $update_row_count = Your::Model->update('user',{
        name => 'nomaneko',
    },{ id => 1 });

or 

    # see) DBIx::Skinny::Row's POD
    my $row = Your::Model->single('user',{id => 1});
    $row->update({name => 'nomaneko'});

=item $skinny->update_by_sql($sql, [\@bind_values])

update record by specific sql. return update row count.

example:

    my $update_row_count = Your::Model->update_by_sql(
        q{UPDATE user SET name = ?},
        ['nomaneko']
    );

=item $skinny->delete($table, \%delete_condition)

delete record. return delete row count.

example:

    my $delete_row_count = Your::Model->delete('user',{
        id => 1,
    });

or

    # see) DBIx::Skinny::Row's POD
    my $row = Your::Model->single('user', {id => 1});
    $row->delete

=item $skinny->delete_by_sql($sql, \@bind_values)

delete record by specific sql. return delete row count.

example:

    my $delete_row_count = Your::Model->delete_by_sql(
        q{DELETE FROM user WHERE id = ?},
        [1]
    });

=item $skinny->find_or_create($table, \%values)

create record if not exsists record.

return DBIx::Skinny::Row's instance object.

example:

    my $row = Your::Model->find_or_create('usr',{
        id   => 1,
        name => 'nekokak',
    });

=item $skinny->find_or_insert($table, \%values)

find_or_create method alias.

=item $skinny->search($table_name, [\%search_condition, [\%search_attr]])

simple search method.
search method get DBIx::Skinny::Iterator's instance object.

see L<DBIx::Skinny::Iterator>

get iterator:

    my $itr = Your::Model->search('user',{id => 1},{order_by => 'id'});

get rows:

    my @rows = Your::Model->search('user',{id => 1},{order_by => 'id'});

See L</ATTRIBUTES> for more information for \%search_attr.

=item $skinny->search_rs($table_name, [\%search_condition, [\%search_attr]])

simple search method.
search_rs method always get DBIx::Skinny::Iterator's instance object.

This method does the same exact thing as search() except it will always return a iterator, even in list context.

=item $skinny->single($table_name, \%search_condition)

get one record.
give back one case of the beginning when it is acquired plural records by single method.

    my $row = Your::Model->single('user',{id =>1});

=item $skinny->resultset(\%options)

resultset case:

    my $rs = Your::Model->resultset(
        {
            select => [qw/id name/],
            from   => [qw/user/],
        }
    );
    $rs->add_where('name' => {op => 'like', value => "%neko%"});
    $rs->limit(10);
    $rs->offset(10);
    $rs->order({ column => 'id', desc => 'DESC' });
    my $itr = $rs->retrieve;

=item $skinny->count($table_name, $target_column, [\%search_condition])

get simple count

    my $cnt = Your::Model->count('user' => 'id', {age => 30});

=item $skinny->search_named($sql, [\%bind_values, [\@sql_parts, [$table_name]]])

execute named query

    my $itr = Your::Model->search_named(q{SELECT * FROM user WHERE id = :id}, {id => 1});

If you give ArrayRef to value, that is expanded to "(?,?,?,?)" in SQL.
It's useful in case use IN statement.

    # SELECT * FROM user WHERE id IN (?,?,?);
    # bind [1,2,3]
    my $itr = Your::Model->search_named(q{SELECT * FROM user WHERE id IN :ids}, {id => [1, 2, 3]});

If you give \@sql_parts,

    # SELECT * FROM user WHERE id IN (?,?,?) AND unsubscribed_at IS NOT NULL;
    # bind [1,2,3]
    my $itr = Your::Model->search_named(q{SELECT * FROM user WHERE id IN :ids %s}, {id => [1, 2, 3]}, ['AND unsubscribed_at IS NOT NULL']);

If you give table_name. It is assumed the hint that makes DBIx::Skinny::Row's Object.

=item $skinny->search_by_sql($sql, [\@bind_vlues, [$table_name]])

execute your SQL

    my $itr = Your::Model->search_by_sql(q{
        SELECT
            id, name
        FROM
            user
        WHERE
            id = ?
    },[ 1 ]);

If $opt_table_info is specified, it set table infomation to result iterator.
So, you can use table row class to search_by_sql result.

=item $skinny->txn_scope

get transaction scope object.

    do {
        my $txn = Your::Model->txn_scope;
        # some process
        $txn->commit;
    }

=item $skinny->hash_to_row($table_name, $row_data_hash_ref)

make DBIx::Skinny::Row's class from hash_ref.

    my $row = Your::Model->hash_to_row('user',
        {
            id   => 1,
            name => 'lestrrat',
        }
    );

=item $skinny->data2itr($table_name, \@rows_data)

DBIx::Skinny::Iterator is made based on \@rows_data.

    my $itr = Your::Model->data2itr('user',[
        {
            id   => 1,
            name => 'nekokak',
        },
        {
            id   => 2,
            name => 'yappo',
        },
        {
            id   => 3,
            name => 'walf43',
        },
    ]);

    my $row = $itr->first;
    $row->insert; # inser data.

=item $skinny->find_or_new($table_name, \%row_data)

Find an existing record from database.

If none exists, instantiate a new row object and return it.

The object will not be saved into your storage until you call "insert" in DBIx::Skinny::Row on it.

    my $row = Your::Model->find_or_new('user',{name => 'nekokak'});

=item $skinny->do($sql, [$option, $bind_values])

execute your query.

See) L<http://search.cpan.org/dist/DBI/DBI.pm#do>

=item $skinny->dbh

get database handle.

=item $skinny->connect([\%connection_info])

connect database handle.

If you give \%connection_info, create new database connection.

=item $skinny->reconnect(\%connection_info)

re connect database handle.

If you give \%connection_info, create new database connection.

=item $skinny->disconnect()

Disconnects from the currently connected database.

=item $skinny->suppress_row_objects($flag)

set row object creation mode.

=back

=head1 ATTRIBUTES

=over

=item order_by

    { order_by => [ { id => 'desc' } ] }
    # or
    { order_by => { id => 'desc' } }
    # or 
    { order_by => 'name' }

=item for_update

    { for_update => 1 }

=back

=head1 ENVIRONMENT VARIABLES

=head2 SKINNY_PROFILE

for debugging sql.

see L<DBIx::Skinny::Profile>

        $ SKINNY_PROFILE=1 perl ./your_script.pl

=head2 SKINNY_TRACE

for debugging sql.

see L<DBIx::Skinny::Profiler::Trace>

    $ SKINNY_TRACE=1 perl ./your_script.pl

=head2 TRIGGER

    my $row = $db->insert($args);
    # pre_insert: ($db, $args, $table_name)
    # post_insert: ($db, $row, $table_name)

    my $updated_rows_count = $db->update($args);
    my $updated_rows_count = $row->update(); # example $args: +{ id => $row->id }
    # pre_update: ($db, $args, $table_name)
    # post_update: ($db, $updated_rows_count, $table_name)

    my $deleted_rows_count = $db->delete($args);
    my $deleted_rows_count = $row->delete(); # example $args: +{ id => $row->id }
    # pre_delete: ($db, $args, $table_name)
    # post_delete: ($db, $deleted_rows_count, $table_name)

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Atsushi Kobayashi  C<< <nekokak __at__ gmail.com> >>

=head1 CONTRIBUTORS

walf443 : Keiji Yoshimi

TBONE : Terrence Brannon

nekoya : Ryo Miyake

oinume: Kazuhiro Oinuma

fujiwara: Shunichiro Fujiwara

pjam: Tomoyuki Misonou

magicalhat

Makamaka Hannyaharamitu

nihen: Masahiro Chiba

lestrrat: Daisuke Maki

=head1 SUPPORT

  irc: #dbix-skinny@irc.perl.org

  ML: http://groups.google.com/group/dbix-skinny

=head1 REPOSITORY

  git clone git://github.com/nekokak/p5-dbix-skinny.git  

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Atsushi Kobayashi C<< <nekokak __at__ gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

