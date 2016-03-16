package Language::LispPerl::BuiltIns;

use Moo;

use Carp;

use Language::LispPerl::Atom;

=head1 NAME

Language::LispPerl::BuiltIns - Default builtin functions collection

=cut

has 'evaler' => ( is => 'ro', required => 1, weak_ref => 1);

has 'functions' => (
    is      => 'ro',
    default => sub {
        {
            "eval"              => \&_impl_eval,
            "syntax"            => \&_impl_syntax,

            "throw"             => \&_impl_throw,
            "catch"             => \&_impl_catch,
            "exception-label"   => \&_impl_exception_label,
            "exception-message" => \&_impl_exception_message,

            "def"               => \&_impl_def,
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

sub _impl_syntax{
    my ($self, $ast) = @_;
    $ast->error("syntax expects 1 argument") if $ast->size != 2;
    return $self->evaler()->bind( $ast->second() );
}

# ( throw someexception "The message that goes with it")
sub _impl_throw {
    my ( $self, $ast ) = @_;
    $ast->error("throw expects 2 arguments") if $ast->size != 3;
    my $label = $ast->second();
    $ast->error( "throw expects a symbol as the first argument but got "
          . $label->type() )
      if $label->type() ne "symbol";
    my $msg = $self->evaler()->_eval( $ast->third() );
    $ast->error( "throw expects a string as the second argument but got "
          . $msg->type() )
      if $msg->type() ne "string";

    my $e = Language::LispPerl::Atom->new( "exception", $msg->value() );
    $e->{label}  = $label->value();
    $e->{caller} = $self->evaler()->copy_caller();
    $e->{pos} = $ast->{pos};

    $self->evaler()->exception($e);
    die $msg->value()."\n";
}


# ( catch ... ... )
sub _impl_catch{
    my ($self, $ast) = @_;
    $ast->error("catch expects 2 arguments") if $ast->size != 3;
    my $handler = $self->evaler()->_eval( $ast->third() );
    $ast->error(
        "catch expects a function/lambda as the second argument but got "
              . $handler->type() )
        if $handler->type() ne "function";

    my $res;
    my $saved_caller_depth = $self->evaler()->caller_size();
    eval { $res = $self->evaler()->_eval( $ast->second() ); };
    if ($@) {
        my $e = $self->evaler()->exception();
        if ( !defined $e ) {
            $e = Language::LispPerl::Atom->new( "exception", "unkown expection" );
            $e->{label} = "undef";
            my @ec = ();
            $e->{caller} = \@ec;
        }
        $ast->error(
            "catch expects an exception for handler but got " . $e->type() )
            if $e->type() ne "exception";
        my $i = $self->evaler()->caller_size();
        for ( ; $i > $saved_caller_depth ; $i-- ) {
            $self->evaler()->pop_caller();
        }
        my $call_handler = Language::LispPerl::Seq->new("list");
        $call_handler->append($handler);
        $call_handler->append($e);
        $self->evaler()->clear_exception();
        return $self->evaler()->_eval($call_handler);
    }
    return $res;
}

sub _impl_exception_label{
    my ($self, $ast) = @_;
    $ast->error("exception-label expects 1 argument") if $ast->size() != 2;
    my $e = $self->evaler()->_eval( $ast->second() );
    $ast->error( "exception-label expects an exception as argument but got "
                     . $e->type() )
        if $e->type() ne "exception";
    return Language::LispPerl::Atom->new( "string", $e->{label} );
}

sub _impl_exception_message{
    my ($self, $ast) = @_;
    $ast->error("exception-message expects 1 argument") if $ast->size() != 2;
    my $e = $self->evaler()->_eval( $ast->second() );
    $ast->error(
        "exception-message expects an exception as argument but got "
            . $e->type() )
        if $e->type() ne "exception";
    return Language::LispPerl::Atom->new( "string", $e->value() );
}

sub _impl_def{
    my ($self, $ast , $symbol ) = @_;
    my $size = $ast->size();

    # Function name
    my $function_name = $symbol->value();

    $ast->error( $function_name . " expects 2 arguments" ) if $size > 4 or $size < 3;

    if ( $size == 3 ) {
        $ast->error( $function_name
                         . " expects a symbol as the first argument but got "
                         . $ast->second()->type() )
            if $ast->second()->type() ne "symbol";
        my $name = $ast->second()->value();
        $ast->error( $name . " is a reserved word" ) if $self->evaler()->word_is_reserved( $name );

        # A function is stored in a variable.
        $self->evaler()->new_var($name);
        my $value = $self->evaler()->_eval( $ast->third() );
        $self->evaler()->var($name)->value($value);

        return $value;
    }

    # This is a size 4
    my $meta = $self->evaler()->_eval( $ast->second() );
    $ast->error( $function_name
                     . " expects a meta as the first argument but got "
                     . $meta->type() )
        if $meta->type() ne "meta";

    $ast->error( $function_name
                     . " expects a symbol as the first argument but got "
                     . $ast->third()->type() )
        if $ast->third()->type() ne "symbol";

    my $name = $ast->third()->value();
    $ast->error( $name . " is a reserved word" ) if $self->evaler()->word_is_reserved( $name );

    $self->evaler()->new_var($name);
    my $value = $self->evaler()->_eval( $ast->fourth() );
    $value->meta($meta);
    $self->evaler()->var($name)->value($value);
    return $value;
}

1;
