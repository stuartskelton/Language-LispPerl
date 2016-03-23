#! perl

use strict;
use warnings;

use File::Temp;

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

{
    # let
    ok( my $res = $lisp->eval(q|( let [ a 1 b 2 ] ( - a b ) ( + a b ) )|) );
    is( $res->type() , 'number' );
    is( $res->value() , 3 );
}

{
    # fn
    ok( my $res = $lisp->eval(q|( (fn [a  b] ( + a b ) ) 1 2 )|) );
    is( $res->type() , 'number' );
    is( $res->value() , 3 );
}

{
    # defmacro
    ok( my $res = $lisp->eval(q|(defmacro addition [a b] ( + a b ) )|) );
    is( $res->type() , 'macro' );
    ok( $res->value()->isa('Language::LispPerl::Seq') );
    ok( $res = $lisp->eval(q|( addition 1 2 )| ) );
    is( $res->type() , 'number' );
    is( $res->value() , 3 );
}

{
    # gen-sym
    ok( my $res = $lisp->eval(q|( gen-sym "bacon" )|) );
    is( $res->type() , 'symbol');
    like( $res->value() , qr/^baconatom/ );
}

{
    # require
    ok( my $res = $lisp->eval(q|(require "core.clp")|) );
    is( $res->type() , 'macro');
    ok( $res->value()->isa('Language::LispPerl::Seq') );
}

{
    # read
    my ($fh, $filename) = File::Temp::tempfile();
    print $fh q|(+ 1 2) (+ 3 4)|;
    close($fh);
    ok( my $res = $lisp->eval('(read "'.$filename.'")') );
    is( $res->type() , 'number' );
    is( $res->value() , 7 );
}

{
    # Lists
    ok( my $res = $lisp->eval('( list 1 2 3 4 )') );
    is( $res->type() , 'list' );
    is( ref( $res->value() ) , 'ARRAY' );
    is( ref( $res->value()->[0] ) , 'Language::LispPerl::Atom' );

    ok( $res = $lisp->eval('( car ( list 3 2 1 ) )') );
    is( $res->type(), 'number' );
    is( $res->value() , 3 );

    ok( $res = $lisp->eval('( cdr ( list  3 2 1 ) )') );
    is( ref( $res->value() ) , 'ARRAY' );
    is( scalar( @{$res->value()} ) , 2 );

    ok( $res = $lisp->eval('( cons 1 (list 2 3) )') );
    is( ref($res->value() ) , 'ARRAY' );
    is( scalar( @{$res->value()} ) , 3 );
}

{
    # Flow control
    ok( my $res = $lisp->eval(q|( if (> 1 2 ) (syntax "ya") (syntax "nie"))|) );
    is( $res->value() , "nie");
    ok( $res = $lisp->eval(q|( if (> 1 2 ) (syntax "ya"))|) );
    is( $res->value() , "nil");
    ok( $res = $lisp->eval(q|( if (< 1 2 ) (syntax "ya") (syntax "nie"))|) );
    is( $res->value() , "ya");

    ok( $res = $lisp->eval(q|
(set! foo 5 )
(while (< foo 10) ( set! foo (+ foo 1 ) ) )
|));
    is( $res->value() , 10 );

    ok( $res = $lisp->eval(q|( begin ( + 1 2 ) ( + 3 4 ) )|) );
    is( $res->value(), 7 );
}

done_testing();
