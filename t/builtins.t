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
    # eval
    my $res = $lisp->eval(q|( eval "( + 1 2 )" )| );
    is( $res->value() , 3 );
    throws_ok { $lisp->eval(q|( eval 1 2 3 )|); } qr/expects 1/ ;
}

{
    # syntax
    my $res = $lisp->eval(q|( syntax true )| );
    is( $res->type() , 'bool' );
    is( $res->value() , 'true' );
}

{
    # Exception
    throws_ok{ $lisp->eval(q|( throw wtf "This is exceptional")|) }  qr/This is exceptional/ ;
    ok( $lisp->exception() );
    is( $lisp->exception()->{label} , 'wtf' );

    {
        ok( my $res = $lisp->eval(q|(catch (throw aaa "bbb") (fn [e] ( syntax e )))|) );
        ok( $res->type() , 'exception' );
        ok( $res->value(), 'bbb' );
    }

    {
        ok( my $res = $lisp->eval(q|(catch (throw aaa "bbb") (fn [e] ( exception-label  e )))|) );
        ok( $res->type() , 'string' );
        ok( $res->value(), 'aaa' );
    }

    {
        ok( my $res = $lisp->eval(q|(catch (throw aaa "bbb") (fn [e] ( exception-message  e )))|) );
        ok( $res->type() , 'string' );
        ok( $res->value(), 'bbb' );
    }
}

{
    # Def, set
    ok( $lisp->eval(q|(def somename true)|) );
    is( $lisp->var('somename')->name(), '#somename' );
    is( $lisp->var('somename')->value()->type(), 'bool');
    is( $lisp->var('somename')->value()->value(), 'true');

    ok( $lisp->eval(q|(def ^{:k "v"} foo "bar")|) );
    is( $lisp->var('foo')->name(), '#foo' );
    is( $lisp->var('foo')->value()->type(), 'string');
    is( $lisp->var('foo')->value()->value(), 'bar');
    is( $lisp->var('foo')->value()->meta()->type() , "meta");
    is( $lisp->var('foo')->value()->meta()->type() , "meta");
    is( $lisp->var('foo')->value()->meta()->value()->{k}->type , "string");
    is( $lisp->var('foo')->value()->meta()->value()->{k}->value , "v");

    ok( $lisp->eval(q|(set! foo "baz")|) );
    is( $lisp->var('foo')->name(), '#foo' );
    is( $lisp->var('foo')->value()->type(), 'string');
    is( $lisp->var('foo')->value()->value(), 'baz');

}

done_testing();
