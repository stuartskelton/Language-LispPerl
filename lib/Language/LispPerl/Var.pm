package Language::LispPerl::Var;

use Moose;

has 'name' => ( is => 'ro' , required => 1 );
has 'value' => ( is => 'rw' );

__PACKAGE__->meta()->make_immutable();
1;

=head1 NAME

Language::LispPerl::Var - A variable with a name (ro) and a value (rw)

=cut
