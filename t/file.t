#! perl

use Test::More tests=>2;
BEGIN { use_ok('Language::LispPerl') };

my $test = Language::LispPerl::Evaler->new();

$test->load("core");
$test->load("file");
ok($test->load("t/file.clp"), 'file operations');

