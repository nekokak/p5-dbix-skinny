# NAME

[DBIx::Skinny](https://metacpan.org/pod/DBIx::Skinny) - simple DBI wrapper/ORMapper

# SYNOPSIS

create your db model base class.

```perl
package Your::Model;
use DBIx::Skinny connect_info => {
    dsn => 'dbi:SQLite:',
    username => '',
    password => '',
};
1;

```

create your db schema class.
See [DBIx::Skinny::Schema](https://metacpan.org/pod/DBIx::Skinny::Schema) for docs on defining schema class.

```perl
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

```

in your script.

```perl
use Your::Model;

my $skinny = Your::Model->new;
# insert new record.
my $row = $skinny->insert('user',
    {
        id   => 1,
    }
);
$row->update({name => 'nekokak'});

$row = $skinny->search_by_sql(q{SELECT id, name FROM user WHERE id = ?}, [ 1 ]);
$row->delete('user');
```

# DESCRIPTION

[DBIx::Skinny](https://metacpan.org/pod/DBIx::Skinny) is simple [DBI](https://metacpan.org/pod/DBI) wrapper and simple O/R Mapper.
It aims to be lightweight, with minimal dependencies so it's easier to install. 

# ARCHITECTURE

DBIx::Skinny classes are comprised of three distinct components:

## MODEL

The `model` is where you say 

```perl
package MyApp::Model;
use DBIx::Skinny;
```

This is the entry point to using DBIx::Skinny. You connect, insert, update, delete, select stuff using this object.

## SCHEMA

The `schema` is a simple class that describes your table definitions. Note that this is different from [DBIx::Class](https://metacpan.org/pod/DBIx::Class) terms. DBIC's schema is equivalent to DBIx::Skinny's model + schema, where the actual schema information is scattered across the result classes.

In DBIx::Skinny, you simply use [DBIx::Skinny::Schema](https://metacpan.org/pod/DBIx::Skinny::Schema)'s domain specific language to define a set of tables

```perl
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
```

## ROW

Unlike DBIx::Class, you don't need to have a set of classes that represent a row type (i.e. "result" classes in DBIC terms). In DBIx::Skinny, the row objects are blessed into anonymous classes that inherit from [DBIx::Skinny::Row](https://metacpan.org/pod/DBIx::Skinny::Row), so you don't have to create these classes if you just want to use some simple queries.

If you want to define methods to be performed by your row objects, simply create a row class like so:

```perl
package MyApp::Model::Row::CamelizedTableName;
use base qw(DBIx::Skinny::Row);
```

Note that your table name will be camelized using String::CamelCase.

# METHODS

DBIx::Skinny provides a number of methods to all your classes, 

- $skinny->new(\[\\%connection\_info\])

    create your skinny instance.
    It is possible to use it even by the class method.

    $connection\_info is optional argment.

    When $connection\_info is specified,
    new method connect new DB connection from $connection\_info.

    When $connection\_info is not specified,
    it becomes use already setup connection or it doesn't do at all.

    example:

    ```perl
    my $db = Your::Model->new;
    ```

    or

    ```perl
    # connect new database connection.
    my $db = Your::Model->new(+{
        dsn      => $dsn,
        username => $username,
        password => $password,
        connect_options => $connect_options,
    });
    ```

    or

    ```perl
    my $dbh = DBI->connect();
    my $db = Your::Model->new(+{
        dbh => $dbh,
    });
    ```

- $skinny->insert($table\_name, \\%row\_data)

    insert new record and get inserted row object.

    if insert to table has auto increment then return $row object with fill in key column by last\_insert\_id.

    example:

    ```perl
    my $row = Your::Model->insert('user',{
        id   => 1,
        name => 'nekokak',
    });
    say $row->id; # show last_insert_id()
    ```

    or

    ```perl
    my $db = Your::Model->new;
    my $row = $db->insert('user',{
        id   => 1,
        name => 'nekokak',
    });
    ```

- $skinny->create($table\_name, \\%row\_data)

    insert method alias.

- $skinny->replace($table\_name, \\%row\_data)

    The data that already exists is replaced. 

    example:

    ```perl
    Your::Model->replace('user',{
        id   => 1,
        name => 'tokuhirom',
    });
    ```

    or 

    ```perl
    my $db = Your::Model->new;
    my $row = $db->replace('user',{
        id   => 1,
        name => 'tokuhirom',
    });
    ```

- $skinny->bulk\_insert($table\_name, \\@rows\_data)

    Accepts either an arrayref of hashrefs.
    each hashref should be a structure suitable
    forsubmitting to a Your::Model->insert(...) method.

    insert many record by bulk.

    example:

    ```perl
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
    ```

- $skinny->update($table\_name, \\%update\_row\_data, \[\\%update\_condition\])

    $update\_condition is optional argment.

    update record.

    example:

    ```perl
    my $update_row_count = Your::Model->update('user',{
        name => 'nomaneko',
    },{ id => 1 });
    ```

    or 

    ```perl
    # see) L<DBIx::Skinny::Row>'s POD
    my $row = Your::Model->single('user',{id => 1});
    $row->update({name => 'nomaneko'});
    ```

- $skinny->update\_by\_sql($sql, \[\\@bind\_values\])

    update record by specific sql. return update row count.

    example:

    ```perl
    my $update_row_count = Your::Model->update_by_sql(
        q{UPDATE user SET name = ?},
        ['nomaneko']
    );
    ```

- $skinny->delete($table, \\%delete\_condition)

    delete record. return delete row count.

    example:

    ```perl
    my $delete_row_count = Your::Model->delete('user',{
        id => 1,
    });
    ```

    or

    ```perl
    # see) DBIx::Skinny::Row's POD
    my $row = Your::Model->single('user', {id => 1});
    $row->delete
    ```

- $skinny->delete\_by\_sql($sql, \\@bind\_values)

    delete record by specific sql. return delete row count.

    example:

    ```perl
    my $delete_row_count = Your::Model->delete_by_sql(
        q{DELETE FROM user WHERE id = ?},
        [1]
    });
    ```

- $skinny->find\_or\_create($table, \\%values)

    create record if not exsists record.

    return DBIx::Skinny::Row's instance object.

    example:

    ```perl
    my $row = Your::Model->find_or_create('usr',{
        id   => 1,
        name => 'nekokak',
    });
    ```

    NOTICE: find\_or\_create has bug.

    reproduction example:

    ```perl
    my $row = Your::Model->find_or_create('user',{
        id   => 1,
        name => undef,
    });
    ```

    In this case, it becomes an error by insert.

    If you want to do the same thing in this case,

    ```perl
    my $row = Your::Model->single('user', {
        id   => 1,
        name => \'IS NULL',
    })
    unless ($row) {
        Your::Model->insert('user', {
            id => 1,
        });
    }
    ```

    Because the interchangeable rear side is lost, it doesn't mend. 

- $skinny->find\_or\_insert($table, \\%values)

    find\_or\_create method alias.

- $skinny->search($table\_name, \[\\%search\_condition, \[\\%search\_attr\]\])

    simple search method.
    search method get DBIx::Skinny::Iterator's instance object.

    see [DBIx::Skinny::Iterator](https://metacpan.org/pod/DBIx::Skinny::Iterator)

    get iterator:

    ```perl
    my $itr = Your::Model->search('user',{id => 1},{order_by => 'id'});
    ```

    get rows:

    ```perl
    my @rows = Your::Model->search('user',{id => 1},{order_by => 'id'});
    ```

    See ["ATTRIBUTES"](#attributes) for more information for \\%search\_attr.

- $skinny->search\_rs($table\_name, \[\\%search\_condition, \[\\%search\_attr\]\])

    simple search method.
    search\_rs method always get DBIx::Skinny::Iterator's instance object.

    This method does the same exact thing as search() except it will always return a iterator, even in list context.

- $skinny->single($table\_name, \\%search\_condition)

    get one record.
    give back one case of the beginning when it is acquired plural records by single method.

    ```perl
    my $row = Your::Model->single('user',{id =>1});
    ```

- $skinny->resultset(\\%options)

    resultset case:

    ```perl
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
    ```

- $skinny->count($table\_name, $target\_column, \[\\%search\_condition\])

    get simple count

    ```perl
    my $cnt = Your::Model->count('user' => 'id', {age => 30});
    ```

- $skinny->search\_named($sql, \[\\%bind\_values, \[\\@sql\_parts, \[$table\_name\]\]\])

    execute named query

    ```perl
    my $itr = Your::Model->search_named(q{SELECT * FROM user WHERE id = :id}, {id => 1});
    ```

    If you give ArrayRef to value, that is expanded to "(?,?,?,?)" in SQL.
    It's useful in case use IN statement.

    ```perl
    # SELECT * FROM user WHERE id IN (?,?,?);
    # bind [1,2,3]
    my $itr = Your::Model->search_named(q{SELECT * FROM user WHERE id IN :ids}, {ids => [1, 2, 3]});
    ```

    If you give \\@sql\_parts,

    ```perl
    # SELECT * FROM user WHERE id IN (?,?,?) AND unsubscribed_at IS NOT NULL;
    # bind [1,2,3]
    my $itr = Your::Model->search_named(q{SELECT * FROM user WHERE id IN :ids %s}, {ids => [1, 2, 3]}, ['AND unsubscribed_at IS NOT NULL']);
    ```

    If you give table\_name. It is assumed the hint that makes DBIx::Skinny::Row's Object.

- $skinny->search\_by\_sql($sql, \[\\@bind\_vlues, \[$table\_name\]\])

    execute your SQL

    ```perl
    my $itr = Your::Model->search_by_sql(q{
        SELECT
            id, name
        FROM
            user
        WHERE
            id = ?
    },[ 1 ]);
    ```

    If $opt\_table\_info is specified, it set table infomation to result iterator.
    So, you can use table row class to search\_by\_sql result.

- $skinny->txn\_scope

    get transaction scope object.

    ```perl
    do {
        my $txn = Your::Model->txn_scope;

        $row->update({foo => 'bar'});

        $txn->commit;
    }
    ```

    An alternative way of transaction handling based on
    [DBIx::Skinny::Transaction](https://metacpan.org/pod/DBIx::Skinny::Transaction).

    If an exception occurs, or the guard object otherwise leaves the scope
    before `$txn->commit` is called, the transaction will be rolled
    back by an explicit ["txn\_rollback"](#txn_rollback) call. In essence this is akin to
    using a ["txn\_begin"](#txn_begin)/["txn\_commit"](#txn_commit) pair, without having to worry
    about calling ["txn\_rollback"](#txn_rollback) at the right places. Note that since there
    is no defined code closure, there will be no retries and other magic upon
    database disconnection.

- $skinny->hash\_to\_row($table\_name, $row\_data\_hash\_ref)

    make DBIx::Skinny::Row's class from hash\_ref.

    ```perl
    my $row = Your::Model->hash_to_row('user',
        {
            id   => 1,
            name => 'lestrrat',
        }
    );
    ```

- $skinny->data2itr($table\_name, \\@rows\_data)

    DBIx::Skinny::Iterator is made based on \\@rows\_data.

    ```perl
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
    ```

- $skinny->find\_or\_new($table\_name, \\%row\_data)

    Find an existing record from database.

    If none exists, instantiate a new row object and return it.

    The object will not be saved into your storage until you call "insert" in DBIx::Skinny::Row on it.

    ```perl
    my $row = Your::Model->find_or_new('user',{name => 'nekokak'});
    ```

- $skinny->do($sql, \[$option, $bind\_values\])

    execute your query.

    See) [http://search.cpan.org/dist/DBI/DBI.pm#do](http://search.cpan.org/dist/DBI/DBI.pm#do)

- $skinny->dbh

    get database handle.

- $skinny->connect(\[\\%connection\_info\])

    connect database handle.

    If you give \\%connection\_info, create new database connection.

- $skinny->reconnect(\\%connection\_info)

    re connect database handle.

    If you give \\%connection\_info, create new database connection.

- $skinny->disconnect()

    Disconnects from the currently connected database.

- $skinny->suppress\_row\_objects($flag)

    set row object creation mode.

# ATTRIBUTES

- order\_by

    ```perl
    { order_by => [ { id => 'desc' } ] }
    # or
    { order_by => { id => 'desc' } }
    # or 
    { order_by => 'name' }
    ```

- for\_update

    ```perl
    { for_update => 1 }
    ```

# ENVIRONMENT VARIABLES

## SKINNY\_PROFILE

for debugging sql.

see [DBIx::Skinny::Profile](https://metacpan.org/pod/DBIx::Skinny::Profile)

```
    $ SKINNY_PROFILE=1 perl ./your_script.pl
```

## SKINNY\_TRACE

for debugging sql.

see [DBIx::Skinny::Profiler::Trace](https://metacpan.org/pod/DBIx::Skinny::Profiler::Trace)

```
$ SKINNY_TRACE=1 perl ./your_script.pl
```

## TRIGGER

```perl
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
```

# BUGS AND LIMITATIONS

No bugs have been reported.

# AUTHOR

Atsushi Kobayashi  `<nekokak __at__ gmail.com>`

# CONTRIBUTORS

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

tokuhirom: Tokuhiro Matsuno

# SUPPORT

```
irc: #dbix-skinny@irc.perl.org

ML: http://groups.google.com/group/dbix-skinny
```

# REPOSITORY

```
git clone git://github.com/nekokak/p5-dbix-skinny.git  
```

# LICENCE AND COPYRIGHT

Copyright (c) 2010, Atsushi Kobayashi `<nekokak __at__ gmail.com>`. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic).
