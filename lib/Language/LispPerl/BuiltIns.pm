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

            # Exception stuff
            "throw"             => \&_impl_throw,
            "catch"             => \&_impl_catch,
            "exception-label"   => \&_impl_exception_label,
            "exception-message" => \&_impl_exception_message,

            # Variable stuff (booo)
            "def"               => \&_impl_def,
            "set!"              => \&_impl_set_bang,
            "let"               => \&_impl_let,

            # A pure function
            "fn"                => \&_impl_fn,

            # Define macros
            "defmacro"          => \&_impl_defmacro,
            "gen-sym"           => \&_impl_gen_sym,

            # List stuff
            "list"              => \&_impl_list,
            "car"               => \&_impl_car,
            "cdr"               => \&_impl_cdr,
            "cons"              => \&_impl_cons,

            "if"                => \&_impl_if,
            "while"             => \&_impl_while,
            "begin"             => \&_impl_begin,

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

            # Numeric binary functions
            "+"                 => \&_impl_num_bin,
            "-"                 => \&_impl_num_bin,
            "*"                 => \&_impl_num_bin,
            "/"                 => \&_impl_num_bin,
            "%"                 => \&_impl_num_bin,
            # Boolean binary functions
            "=="                => \&_impl_num_bool,
            "!="                => \&_impl_num_bool,
            ">"                 => \&_impl_num_bool,
            ">="                => \&_impl_num_bool,
            "<"                 => \&_impl_num_bool,
            "<="                => \&_impl_num_bool,

            # "."                 => 1,
            # "->"                => 1,

            "eq"                => \&_impl_str_bool,
            "ne"                => \&_impl_str_bool,
            "lt"                => \&_impl_str_bool,
            "gt"                => \&_impl_str_bool,

            # "and"               => 1,
            # "or"                => 1,

            # General purpose equal function
            "equal"             => \&_impl_equal,

            # File operations.
            "require"           => \&_impl_require,
            "read"              => \&_impl_read,
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

sub _impl_set_bang{
    my ($self, $ast, $symbol) = @_;

    my $function_name = $symbol->value();

    $ast->error( $function_name . " expects 2 arguments" ) if $ast->size() != 3;
    $ast->error( $function_name
                     . " expects a symbol as the first argument but got "
                     . $ast->second()->type() )
        if $ast->second()->type() ne "symbol";

    my $name = $ast->second()->value();
    $ast->error( "undefined variable " . $name )
        if !defined $self->evaler()->var($name);
    my $value = $self->evaler->_eval( $ast->third() );

    $self->evaler()->var($name)->value($value);
    return $value;
}

sub _impl_let{
    my ($self, $ast, $symbol) = @_;

    my $function_name = $symbol->value();

    $ast->error( $function_name . " expects >=3 arguments" ) if $ast->size < 3;

    my $vars = $ast->second();
    $ast->error(
        $function_name . " expects a list [name value ...] as the first argument" )
        if $vars->type() ne "vector";
    my $varssize = $vars->size();
    $ast->error(
        $function_name . " expects [name value ...] pairs. There is a non-even amount of things here." )
        if $varssize % 2 != 0;

    my $varvs = $vars->value();

    # In a new scope, define the variables and eval the rest of the expressions.
    # Return the latest evaluated value.
    $self->evaler()->push_scope( $self->evaler()->current_scope() );
    $self->evaler()->push_caller($ast);

    for ( my $i = 0 ; $i < $varssize ; $i += 2 ) {
        my $n = $varvs->[$i];
        my $v = $varvs->[ $i + 1 ];
        $ast->error(
            $function_name . " expects a symbol as name but got " . $n->type() )
            if $n->type() ne "symbol";
        $self->evaler()->new_var( $n->value(), $self->evaler()->_eval($v) );
    }

    my @body = $ast->slice( 2 .. $ast->size - 1 );
    my $res  = $self->evaler()->nil();
    foreach my $b (@body) {
        $res = $self->evaler()->_eval($b);
    }
    $self->evaler()->pop_scope();
    $self->evaler()->pop_caller();

    return $res;
}

sub _impl_fn{
    my ($self, $ast, $symbol) = @_;
    $ast->error("fn expects >= 3 arguments") if $ast->size < 3;

    my $args     = $ast->second();
    my $argstype = $args->type();
    $ast->error("fn expects [arg ...] as formal argument list")
        if $argstype ne "vector";

    my $argsvalue = $args->value();
    my $argssize  = $args->size();
    my $i         = 0;
    foreach my $arg ( @{$argsvalue} ) {
        $arg->error(
            "formal argument should be a symbol but got " . $arg->type() )
            if $arg->type() ne "symbol";
        if (
            $arg->value() eq "&"
                and (  $argssize != $i + 2
                       or $argsvalue->[ $i + 1 ]->value() eq "&" )
            )
            {
                $arg->error("only 1 non-& should follow &");
            }
        $i++;
    }

    my $nast = Language::LispPerl::Atom->new( "function", $ast );

    $nast->{context} = $self->evaler()->copy_current_scope();

    return $nast;
}

sub _impl_defmacro{
    my ($self, $ast, $symbol) = @_;
    $ast->error("defmacro expects >= 4 arguments") if $ast->size < 4;
    my $name = $ast->second()->value();
    my $args = $ast->third();
    $ast->error("defmacro expect [arg ...] as formal argument list")
        if $args->type() ne "vector";
    my $i = 0;
    foreach my $arg ( @{ $args->value() } ) {
        $arg->error(
            "formal argument should be a symbol but got " . $arg->type() )
            if $arg->type() ne "symbol";
        if (
            $arg->value() eq "&"
                and (  $args->size() != $i + 2
                       or $args->value()->[ $i + 1 ]->value() eq "&" )
            )
            {
                $arg->error("only 1 non-& should follow &");
            }
        $i++;
    }
    my $nast = Language::LispPerl::Atom->new( "macro", $ast );

    $nast->{context} = $self->evaler()->copy_current_scope();

    $self->evaler()->new_var( $name, $nast );
    return $nast;
}

sub _impl_gen_sym{
    my ($self, $ast, $symbol) = @_;
    $ast->error("gen-sym expects 0/1 argument") if $ast->size > 2;
    my $s = Language::LispPerl::Atom->new("symbol");
    if ( $ast->size() == 2 ) {
        my $pre = $self->evaler()->_eval( $ast->second() );
        $ast->("gen-sym expects string as argument")
            if $pre->type ne "string";
        $s->value( $pre->value() . $s->object_id() );
    }
    else {
        $s->value( $s->object_id() );
    }
    return $s;
}

sub _impl_require{
    my ($self, $ast) = @_;
    unless( $ast ){
        confess("NO AST");
    }
    $ast->error("require expects 1 argument") if $ast->size() != 2;
    my $m = $ast->second();
    unless ( $m->type() eq "symbol" or $m->type() eq "keyword" ) {
        $m = $self->evaler->_eval($m);
        $ast->error( "require expects a string but got " . $m->type() )
            if $m->type() ne "string";
    }
    return $self->evaler()->load( $m->value() );
}

sub _impl_read{
    my ($self, $ast) = @_;
    $ast->error("read expects 1 argument") if $ast->size() != 2;
    my $f = $self->evaler()->_eval( $ast->second() );
    $ast->error( "read expects a string but got " . $f->type() )
        if $f->type() ne "string";
    return $self->evaler()->read( $f->value() );
}

sub _impl_list{
    my ($self, $ast) = @_;
    return $self->evaler()->empty_list() if $ast->size == 1;
    my @vs = $ast->slice( 1 .. $ast->size - 1 );
    my $r  = Language::LispPerl::Seq->new("list");
    foreach my $i (@vs) {
        $r->append( $self->evaler()->_eval($i) );
    }
    return $r;
}

sub _impl_car{
    my ($self, $ast) = @_;
    $ast->error("car expects 1 argument") if $ast->size != 2;
    my $v = $self->evaler->_eval( $ast->second() );
    $ast->error( "car expects 1 list as argument but got " . $v->type() )
        if $v->type() ne "list";
    my $fv = $v->first();
    return $fv;
}

sub _impl_cdr{
    my ($self, $ast) = @_;
    $ast->error("cdr expects 1 argument") if $ast->size != 2;
    my $v = $self->evaler()->_eval( $ast->second() );
    $ast->error( "cdr expects 1 list as argument but got " . $v->type() )
        if $v->type() ne "list";
    return $self->evaler()->empty_list() if ( $v->size() == 0 );
    my @vs = $v->slice( 1 .. $v->size() - 1 );
    my $r  = Language::LispPerl::Seq->new("list");
    $r->value( \@vs );
    return $r;
}

sub _impl_cons{
    my ($self, $ast) = @_;
    $ast->error("cons expects 2 arguments") if $ast->size != 3;
    my $fv  = $self->evaler()->_eval( $ast->second() );
    my $rvs = $self->evaler()->_eval( $ast->third() );
    $ast->error( "cons expects 1 list as the second argument but got "
                     . $rvs->type() )
        if $rvs->type() ne "list";
    my @vs = ();
    @vs = $rvs->slice( 0 .. $rvs->size() - 1 ) if $rvs->size() > 0;
    unshift @vs, $fv;
    my $r = Language::LispPerl::Seq->new("list");
    $r->value( \@vs );
    return $r;
}

sub _impl_if{
    my ($self, $ast) = @_;
    my $size = $ast->size();
    $ast->error("if expects 2 or 3 arguments") if $size > 4 or $size < 3;
    my $cond = $self->evaler()->_eval( $ast->second() );
        $ast->error(
            "if expects a bool as the first argument but got " . $cond->type() )
            unless $cond->type() eq "bool";

    if ( $cond->value() eq "true" ) {
        return $self->evaler()->_eval( $ast->third() );
    }
    elsif ( $size == 4 ) {
        return $self->evaler()->_eval( $ast->fourth() );
    }
    else {
        return $self->evaler()->nil();
    }
}

sub _impl_while{
    my ($self, $ast) = @_;
    my $size = $ast->size();
    $ast->error("while expects >= 2 arguments") if $size < 3;

    my $res  = $self->evaler()->nil();
    my @body = $ast->slice( 2 .. $size - 1 );

    while(1){
        # Evaluates the condition a first time.
        my $cond = $self->evaler()->_eval( $ast->second() );
        $ast->error( "while expects a bool as the evaluation of the condition but got "
                         . $cond->type() )
            if $cond->type() ne "bool";

        # Condition is false. Just exit the loop
        unless( $cond->value() eq "true" ) {
            last;
        }
        # Condition is true. Eval the body
        foreach my $i (@body) {
            $res = $self->evaler()->_eval($i);
        }
    }
    return $res;
}

sub _impl_begin{
    my ($self, $ast) = @_;
    my $size = $ast->size();
    $ast->error("being expects >= 1 arguments") if $size < 2;
    my $res  = $self->evaler()->nil();
    my @body = $ast->slice( 1 .. $size - 1 );
    foreach my $i (@body) {
        $res = $self->evaler()->_eval($i);
    }
    return $res;
}

my $NUM_FUNCTIONS = {
    '+' => sub{ shift() + shift(); },
    '-' => sub{ shift() - shift(); },
    '*' => sub{ shift() * shift(); },
    '/' => sub{ shift() / shift(); },
    '%' => sub{ shift() % shift(); },

    '==' => sub{ shift() == shift(); },
    '>'  => sub{ shift() > shift(); },
    '<'  => sub{ shift() < shift(); },
    '>=' => sub{ shift() >= shift(); },
    '<=' => sub{ shift() <= shift(); },
    '!=' => sub{ shift() != shift(); },
};

sub _impl_num_bool{
    my ($self, $ast, $symbol) = @_;
    my $res = $self->_impl_num_bin( $ast , $symbol );
    if( $res->value() ){
        return $self->evaler()->true();
    }
    return $self->evaler()->false();
}

# Binary numeric operators.
sub _impl_num_bin{
    my ($self, $ast, $symbol) = @_;
    my $size = $ast->size();
    my $fn = $symbol->value();

    my $num_func = $NUM_FUNCTIONS->{$fn} or
        $ast->error("Unknown numerical function $fn");

    $ast->error( $fn . " expects 2 arguments" ) if $size != 3;
    my $v1 = $self->evaler()->_eval( $ast->second() );
    my $v2 = $self->evaler()->_eval( $ast->third() );


    $ast->error( $fn
                     . " expects number as arguments but got "
                     . $v1->type() . " and "
                     . $v2->type() )
        if $v1->type() ne "number"
        or $v2->type() ne "number";

    my $vv1 = $v1->value();
    my $vv2 = $v2->value();
    return Language::LispPerl::Atom->new( "number", $num_func->( $vv1 , $vv2 ) * 1 );
}
my $STRING_FUNCTIONS = {
    'eq' => sub{ shift() eq shift(); },
    'ne' => sub{ shift() ne shift(); },
    'lt' => sub{ shift() lt shift(); },
    'gt' => sub{ shift() gt shift(); },
};
sub _impl_str_bool{
    my ($self, $ast, $symbol) = @_;

    my $size = $ast->size();
    my $fn = $symbol->value();
    my $str_func = $STRING_FUNCTIONS->{$fn} or
        $ast->error("Unknown string function $fn");

    $ast->error( $fn . " expects 2 arguments" ) if $size != 3;
    my $v1 = $self->evaler()->_eval( $ast->second() );
    my $v2 = $self->evaler()->_eval( $ast->third() );
    $ast->error( $fn
                     . " expects string as arguments but got "
                     . $v1->type() . " and "
                     . $v2->type() )
        if $v1->type() ne "string"
        or $v2->type() ne "string";

    return $str_func->($v1->value(), $v2->value()) ? $self->evaler()->true() : $self->evaler()->false();
}

sub _impl_equal{
    my ($self, $ast, $symbol) = @_;
    my $fn = $symbol->value();

    $ast->error( $fn . " expects 2 arguments" ) if $ast->size != 3;
    my $v1 = $self->evaler()->_eval( $ast->second() );
    my $v2 = $self->evaler()->_eval( $ast->third() );

    # Different type, FALSE
    if ( $v1->type() ne $v2->type() ) {
        return $self->evaler()->false();
    }

    my $type = $v1->type();
    if( $type eq "string" or $type eq "keyword" or $type eq "quotation" or $type eq "bool" or $type eq "nil" ){
        return ( $v1->value() eq $v2->value() ) ? $self->evaler()->true() : $self->evaler()->false() ;
    }

    if ( $type eq "number" ) {
        return ( $v1->value() == $v2->value() ) ? $self->evaler()->true() : $self->evaler()->false();
    }

    return ( $v1->value() eq $v2->value() ) ? $self->evaler()->true() : $self->evaler()->false();
}

1;
