#! perl

use Test::More;

use Language::LispPerl;

my $test = Language::LispPerl::Evaler->new();

$test->load("core");
$test->load("file");
ok($test->load("t/file.clp"), 'file operations');

done_testing();

