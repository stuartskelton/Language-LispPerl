package Language::LispPerl::BuiltIns;

use Moo;

use Carp;

=head1 NAME

Language::LispPerl::BuiltIns - Default builtin functions collection

=cut

has 'evaler' => ( is => 'ro', required => 1, weak_ref => 1);

has 'functions' => (
    is      => 'ro',
    default => sub {
        {
            "eval"              => \&_impl_eval,
            # "syntax"            => \&_impl_syntax,
            # "catch"             => \&_impl_catch,
            # "exception-label"   => \&_impl_exception_label,
            # "exception-message" => 1,
            # "throw"             => 1,
            # "def"               => 1,
            # "set!"              => 1,
            # "let"               => 1,
            # "fn"                => 1,
            # "defmacro"          => 1,
            # "gen-sym"           => 1,
            # "list"              => 1,
            # "car"               => 1,
            # "cdr"               => 1,
            # "cons"              => 1,
            # "if"                => 1,
            # "while"             => 1,
            # "begin"             => 1,
            # "length"            => 1,
            # "reverse"           => 1,
            # "object-id"         => 1,
            # "type"              => 1,
            # "perlobj-type"      => 1,
            # "meta"              => 1,
            # "apply"             => 1,
            # "append"            => 1,
            # "keys"              => 1,
            # "namespace-begin"   => 1,
            # "namespace-end"     => 1,
            # "perl->clj"         => 1,
            # "clj->string"       => 1,
            # "!"                 => 1,
            # "not"               => 1,
            # "+"                 => 1,
            # "-"                 => 1,
            # "*"                 => 1,
            # "/"                 => 1,
            # "%"                 => 1,
            # "=="                => 1,
            # "!="                => 1,
            # ">"                 => 1,
            # ">="                => 1,
            # "<"                 => 1,
            # "<="                => 1,
            # "."                 => 1,
            # "->"                => 1,
            # "eq"                => 1,
            # "ne"                => 1,
            # "and"               => 1,
            # "or"                => 1,
            # "equal"             => 1,
            # "require"           => 1,
            # "read"              => 1,
            # "println"           => 1,
            # "coro"              => 1,
            # "coro-suspend"      => 1,
            # "coro-sleep"        => 1,
            # "coro-yield"        => 1,
            # "coro-resume"       => 1,
            # "coro-wake"         => 1,
            # "coro-join"         => 1,
            # "coro-current"      => 1,
            # "coro-main"         => 1,
            # "xml-name"          => 1,
            # "trace-vars"        => 1
        };
    }
);

=head2 has_function

Returns true if this BuiltIns container has got the given function.

Usage:

  if( my $f = $this->has_function( 'eval ' ) ){
     $this->call_function( $f , $ast );
  }

=cut

sub has_function{
    my ($self, $function_name ) = @_;
    return $self->functions()->{$function_name};
}


=head2 call_function

Just calls the given CODEREF with the given args.

Usage:

  $this->call_function( $self->has_function('eval') , $ast );

=cut

sub call_function{
    my ($self , $code , @args ) = @_;
    return $code->( $self, @args);
}


sub _impl_eval{
    my ($self , $ast ) = @_;
    $ast->error("eval expects 1 argument") if $ast->size != 2;
    my $s = $ast->second();
    $ast->error( "eval expects 1 string as argument but got " . $s->type() )
        if $s->type() ne "string";

    return $self->evaler()->eval( $s->value() );

}

1;
