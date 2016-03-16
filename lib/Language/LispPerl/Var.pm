package Language::LispPerl::Var;

use Moo;

use strict;
use warnings;

has 'name' => ( is => 'ro' , required => 1 );
has 'value' => ( is => 'rw' );

1;

=head1 NAME

Language::LispPerl::Var - A variable with a name (ro) and a value (rw)

=cut
