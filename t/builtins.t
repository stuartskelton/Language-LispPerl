#! perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Language::LispPerl;

#use Log::Any::Adapter qw/Stderr/;

use Data::Dumper;

ok( my $lisp = Language::LispPerl::Evaler->new() );


{
    # Eval.
    my $res = $lisp->eval(q|( eval "( + 1 2 )" )| );
    is( $res->value() , 3 );
    throws_ok { $lisp->eval(q|( eval 1 2 3 )|); } qr/expects 1/ ;
}

done_testing();
