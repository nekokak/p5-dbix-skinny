package Sample::Schema;
use DBIx::Skinny::Schema;
use WWW::Shorten::TinyURL;

install_table tinyurl => schema {
    pk 'id';
    columns qw/
        id
        url
    /;
};

install_inflate_rule 'url' => callback {
    inflate {
        my $value = shift;
        return makeashorterlink($value);
    };
};

1;

