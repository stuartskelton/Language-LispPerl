#! perl

use strict;
use warnings;

use Test::More;

use Language::LispPerl;

#use Log::Any::Adapter qw/Stderr/;

ok( my $lisp = Language::LispPerl::Evaler->new() );


done_testing();
