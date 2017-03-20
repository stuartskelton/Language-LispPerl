package Language::LispPerl::Atom;

use Moose;

use Language::LispPerl::Printer;
use Language::LispPerl::Logger;

our $id      = 0;

has 'class' => ( is => 'ro', isa => 'Str', default => 'Atom' );
has 'type' => ( is => 'rw', isa => 'Str', required => 1 );

has 'value' => ( is => 'rw', default => '' );
has 'object_id' => ( is => 'ro', isa => 'Str', default => sub{ 'atom'.( $id++ ); } );
has 'meta_data' => ( is => 'rw' );
has 'pos' => ( is => 'ro', default => sub{
                   return {
                       filename => "unknown",
                       line     => 0,
                       col      => 0
                   };
               });


sub show {
    my $self   = shift;
    my $indent = shift;
    $indent = "" if !defined $indent;

    #print $indent . "class: " . $self->{class} . "\n";
    print $indent . "type: " . $self->{type} . "\n";
    print $indent . "value: " . $self->{value} . "\n";
}

sub error {
    my $self = shift;
    my $msg  = shift;
    $msg .= " [";
    $msg .= Language::LispPerl::Printer::to_string($self);
    $msg .= "] @[file: " . $self->{pos}->{filename};
    $msg .= " ;line: " . $self->{pos}->{line};
    $msg .= " ;col: " . $self->{pos}->{col} . "]";
    Language::LispPerl::Logger::error($msg);
}


__PACKAGE__->meta()->make_immutable();
1;

