package Mock::MultiPK::Schema;
use utf8;
use DBIx::Skinny::Schema;


install_table 'a_multi_pk_table' => schema {
    pk [ qw( id_a id_b ) ];
    columns qw( id_a id_b memo );
};


1;
__END__
