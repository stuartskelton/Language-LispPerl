#! perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Language::LispPerl;

#use Log::Any::Adapter qw/Stderr/;
use Data::Dumper;
use JSON;

# An empty interpreter
{
    my $lisp = Language::LispPerl::Evaler->new();
    my $packed = $lisp->to_hash();
    # This makes sure it can be turned into json (in other words, it doesnt contain any objects)
    ok( my $json = JSON::to_json($packed));

    my $other_lisp = Language::LispPerl::Evaler->from_hash( $packed );
    is_deeply( $packed, $other_lisp->to_hash() );
}

# Define some stuff
{
    my $lisp = Language::LispPerl::Evaler->new();
    $lisp->eval(q|(defmacro defn [name args & body]
  `(def ~name
     (fn ~args ~@body)))

(defn square [a b] ( * a b ))

(def somename 1)

|);
    {
        my $res = $lisp->eval(q|( type defn )|);
        is( $res->value(),  'macro' );
    }
    {
        my $res = $lisp->eval(q|( type square )|);
        is( $res->value(),  'function' );
    }
    {
        my $res = $lisp->eval(q|( type somename )|);
        is( $res->value(),  'number' );
    }

    my $pack = $lisp->to_hash();
    ok( my $json = JSON::to_json( $pack ));
    my $other_lisp = Language::LispPerl::Evaler->from_hash( $pack );
    is_deeply( $pack, $other_lisp->to_hash() );
    {
        my $res = $other_lisp->eval(q|( type defn )|);
        is( $res->value(),  'macro' );
    }
    {
        my $res = $other_lisp->eval(q|( type square)|);
        is( $res->value(),  'function' );
    }
    {
        my $res = $other_lisp->eval(q|( type somename )|);
        is( $res->value(),  'number' );
    }
}

done_testing();
