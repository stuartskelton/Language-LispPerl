#! perl

use strict;
use warnings;

use Test::More;

use Language::LispPerl;

#use Log::Any::Adapter qw/Stderr/;

ok( my $lisp = Language::LispPerl::Evaler->new() );
ok( my $var = $lisp->new_var( 'foo', 123 ) );
is( $var->value() , 123 );

done_testing();
