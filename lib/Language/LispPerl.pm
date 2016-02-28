package Language::LispPerl;

use 5.008008;
use strict;
use warnings;
use File::Basename;
use File::Spec;

require Exporter;

use Language::LispPerl::Evaler;

our @ISA = qw(Exporter);

# This allows declaration	use Language::LispPerl ':all';
our %EXPORT_TAGS = ( all => [] );

our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };

our @EXPORT = qw();


# Preloaded methods go here.

# file
sub print {
    print @_;
}

sub openfile {
    my $file = shift;
    my $cb   = shift;
    my $fh;
    open $fh, $file;
    &{$cb}($fh);
    close $fh;
}

sub puts {
    my $fh  = shift;
    my $str = shift;
    print $fh $str;
}

sub readline {
    my $fh = shift;
    return <$fh>;
}

sub readlines {
    my $file = shift;
    my $fh;
    open $fh, "<$file";
    my @lines = <$fh>;
    close $fh;
    return join( "\n", @lines );
}

sub file_exists {
    my $file = shift;
    return \( -e $file );
}

# lib search path
sub use_lib {
    my $path = shift;
    unshift @INC, $path;
}

my $lib_path = File::Spec->rel2abs( dirname(__FILE__) . "/LispPerl" );
use_lib($lib_path);

sub gen_name {
    return "gen-" . rand;
}

# regexp
sub match {
    my $regexp = shift;
    my $str    = shift;
    my @m      = ( $str =~ qr($regexp) );
    return \@m;
}

sub get_env {
    my $name = shift;
    return $ENV{$name};
}

1;

__END__

=head1 NAME

Language::LispPerl - A lisp in pure perl with Perl bindings.

=head1 SYNOPSIS

        (defmacro defn [name args & body]
          `(def ~name
             (fn ~args ~@body)))

        (defn foo [arg]
          (println arg))

        (foo "hello world!") ;comment here

=head1 DESCRIPTION

Language::LispPerl is a pure Perl lisp interpreter.
It is a fork of L<CljPerl> that focuses on making embedding
lisp code in your Perl written software straightforward.

Language::ListPerl also bridges between lisp to perl. We can program in lisp and
make use of the great resource from CPAN.

=head2 BINDING Perl function to Lisp

=head3 Lisp <-> Perl

Language::LispPerl is hosted on Perl. Any object of Language::LispPerl can be passed into Perl and vice versa including code.

Here is an example of such binding taken from this module:

=head4 Perl functions in Language::LispPerl;

	package Language::LispPerl;

	sub open {
	  my $file = shift;
	  my $cb = shift;
	  my $fh;
	  open $fh, $file;
	  &{$cb}($fh);
	  close $fh;
	}

	sub puts {
	  my $fh = shift;
	  my $str = shift;
	  print $fh $str;
	}

	sub readline {
	  my $fh = shift;
	  return <$fh>;
	}

=head4 Binding to these functions from file.clp

        ;; These lisp binding functions will live
        ;; in the namespace 'file'
	(ns file
          (. require Language::LispPerl)

	  (defn open [file cb]
	    (.Language::LispPerl open file cb))

	  (defn >> [fh str]
	    (.Language::LispPerl puts fh str))

	  (defn << [fh]
	    (.Language::LispPerl readline fh)))

=head4 Usage in lisp space:

	(file#open ">t.txt" (fn [f]
	  (file#>> f "aaa")))

	(file#open "<t.txt" (fn [f]
	  (println (perl->clj (file#<< f)))))

=head3 Importing and using any Perl package.

=head4 An example which creates a timer with AnyEvent.

	(. require AnyEvent)

	(def cv (->AnyEvent condvar))

	(def count 0)

	(def t (->AnyEvent timer
	  {:after 1
	   :interval 1
	   :cb (fn [ & args]
	         (println count)
	         (set! count (+ count 1))
	         (if (>= count 10)
	           (set! t nil)))}))

	(.AnyEvent::CondVar::Base recv cv)

=head3 This lisp implementation

=head4 Atoms

 * Reader forms

   * Symbols :

	foo, foo#bar

   * Literals
 
   * Strings :

	"foo", "\"foo\tbar\n\""

   * Numbers :

	1, -2, 2.5

   * Booleans :

	true, false
   * Nil :

        nil

   * Keywords :

	:foo

 * Lists :

	(foo bar)

 * Vectors :

	[foo bar]

 * Maps :

	{:key1 value1 :key2 value2 "key3" value3}


=head4 Macro charaters

 * Quote (') :

	'(foo bar)

 * Comment (;) :

	; comment

 *  Dispatch (#) :

   * Accessor (:) :

	#:0 ; index accessor
	#:"key" ; key accessor
	#::key  ; key accessor

   * Sender (!) :

	#!"foo"

   * XML ([) :

	#[body ^{:attr "value"}]

 * Metadata (^) :

	^{:key value}

 * Syntax-quote (`) :

	`(foo bar)

 * Unquote (~) :

	`(foo ~bar)

 * Unquote-slicing (~@) :

	`(foo ~@bar)

=head4 Builtin  lisp Functions

 * list :

	(list 'a 'b 'c) ;=> '(a b c)

 * car :

	(car '(a b c))  ;=> 'a

 * cdr :

	(cdr '(a b c))  ;=> '(b c)

 * cons :

	(cons 'a '(b c)) ;=> '(a b c)

 * key accessor :

	(#::a {:a 'a :b 'a}) ;=> 'a

 * keys :

	(keys {:a 'a :b 'b}) ;=> (:a :b)

 * index accessor :

	(#:1 ['a 'b 'c]) ;=> 'b

 * sender :

	(#:"foo" ['a 'b 'c]) ;=> (foo ['a 'b 'c])

 * xml :

	#[html ^{:class "markdown"} #[body "helleworld"]]

 * length :

	(length '(a b c)) ;=> 3
	(length ['a 'b 'c]) ;=> 3
	(length "abc") ;=> 3

 * append :

	(append '(a b) '(c d)) ;=> '(a b c d)
	(append ['a 'b] ['c 'd]) ;=> ['a 'b 'c 'd]
	(append "ab" "cd") ;=> "abcd"

 * type :

	(type "abc") ;=> "string"
	(type :abc)  ;=> "keyword"
	(type {})    ;=> "map"

 * meta :

	(meta foo ^{:m 'b})
	(meta foo) ;=> {:m 'b}

 * fn :

	(fn [arg & args]
	  (println 'a))

 * apply :

	(apply list '(a b c)) ;=> '(a b c)

 * eval :

	(eval "(+ 1 2)")

 * require :

	(require "core")

 * def :

	(def foo "bar")
	(def ^{:k v} foo "bar")

 * set! :

	(set! foo "bar")

 * let :

	(let [a 1
	      b a]
	  (println b)) 

 * defmacro :

	(defmacro foo [arg & args]
	  `(println ~arg)
	  `(list ~@args))

 * if :

	(if (> 1 0)
	  (println true)
	  (println false))

	(if true
	  (println true))

 * while :

	(while true
	  (println true))

 * begin :

	(begin
	  (println 'foo)
	  (println 'bar))

 * perl->clj :

 * ! not :

	(! true) ;=> false

 * + - * / % == != >= <= > < : only for number.

 * eq ne : only for string.

 * equal : for all objects.

 * . : (.[perl namespace] method [^meta] args ...)
	A meta can be specifed to control what type of value should be passed into perl function.
	type : "scalar" "array" "hash" "ref" "nil"
	^{:return type
	  :arguments [type ...]}

	(.Language::LispPerl print "foo")
	(.Language::LispPerl print ^{:return "nil" :arguments ["scalar"]} "foo") ; return nil and pass first argument as a scalar

 * -> : (->[perl namespace] method args ...)
   Like '.', but this will pass perl namespace as first argument to perl method.

 * println

	(println {:a 'a})

 * trace-vars : Trace the variables in current frame.

	(trace-vars)

=head4 Core Functions (defined in core.clp

 * use-lib : append path into Perl and Language::LispPerl files' searching paths.

	(use-lib "path")

 * ns : Language::LispPerl namespace.

	(ns "foo"
	  (println "bar"))

 * defn :

	(defn foo [arg & args]
	  (println arg))

 * defmulti :

 * defmethod :

 * reduce :

 * map :

 * file#open : open a file with a callback.

	(file#open ">file"
	  (fn [fh]
	    (file#>> fn "foo")))

 * file#<< : read a line from a file handler.

	(file#<< fh)

 * file#>> : write a string into a file handler.

	(file#>> fh "foo")

=head1 SEE ALSO

L<CljPerl>

=head1 AUTHOR

Current author: Jerome Eteve ( JETEVE )

Original author: Wei Hu, E<lt>huwei04@hotmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Jerome Eteve. All rights Reserved.

Copyright 2013 Wei Hu. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut