use inc::Module::Install;

name 'DBIx-Skinny';
all_from 'lib/DBIx/Skinny.pm';

requires 'UNIVERSAL::require';
requires 'Carp';
requires 'DBI';
requires 'Scalar::Util';
requires 'IO::Handle';
requires 'Class::Accessor::Lite';
requires 'Try::Tiny';
requires 'DBIx::TransactionManager' => '1.07';
requires 'Class::Load';
requires 'Pod::Markdown::Github';

author_tests('xt');

test_requires 'Test::More' => '0.96';
test_requires 'Test::SharedFork' => 0.15;
test_requires 'Test::mysqld'     if $Module::Install::AUTHOR;
test_requires 'Test::postgresql' if $Module::Install::AUTHOR;

generate_readme_md_for_github();

tests 't/*.t t/*/*.t t/*/*/*.t';

WriteAll;


use Pod::Markdown::Github;
use FindBin;
use Cwd qw(realpath);
use File::Spec::Functions;

sub generate_readme_md_for_github {

  my $skinny_pm   = catfile($FindBin::Bin, "lib", "DBIx", "Skinny.pm");
  my $readme_md   = catfile($FindBin::Bin, "README.md");

  my $parser = Pod::Markdown::Github->new( perldoc_url_prefix => 'metacpan' );

  open my $in_file,  "<", $skinny_pm or die "Failed to open '$skinny_pm': $!\n";
  open my $out_file, ">", $readme_md or die "Failed to open '$readme_md': $!\n";

  $parser->output_fh($out_file);
  $parser->parse_file($in_file);

  close $out_file;
  close $in_file;

}