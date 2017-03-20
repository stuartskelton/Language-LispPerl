package Language::LispPerl::Seq;

use Moose;

use Language::LispPerl::Logger;
use Language::LispPerl::Printer;

our $id      = 0;

has 'class' => ( is => 'ro', isa => 'Str', default => 'Seq' );
has 'type' => ( is => 'rw', isa => 'Str', default => 'list' );
has 'value' => ( is => 'rw', default => sub{ [] } );
has 'object_id' => ( is => 'ro', isa => 'Str', default => sub{ 'seq'.( $id++ ); } );
has 'meta_data' => ( is => 'rw' );
has 'pos' => ( is => 'rw', isa => 'HashRef', default => sub{
                   return {
                       filename => "unknown",
                       line     => 0,
                       col      => 0
                   }
               });

sub prepend {
    my $self = shift;
    my $v    = shift;
    unshift @{ $self->{value} }, $v;
}

sub append {
    my $self = shift;
    my $v    = shift;
    push @{ $self->{value} }, $v;
}

sub size {
    my $self = shift;
    return scalar @{ $self->{value} };
}

sub first {
    my $self = shift;
    return undef if ( $self->size() < 1 );
    return $self->{value}->[0];
}

sub second {
    my $self = shift;
    return undef if ( $self->size() < 2 );
    return $self->{value}->[1];
}

sub third {
    my $self = shift;
    return undef if ( $self->size() < 3 );
    return $self->{value}->[2];
}

sub fourth {
    my $self = shift;
    return undef if ( $self->size() < 4 );
    return $self->{value}->[3];
}

sub slice {
    my $self  = shift;
    my @range = @_;
    return @{ $self->{value} }[@range];
}

sub each {
    my $self = shift;
    my $blk  = shift;
    foreach my $i ( @{ $self->{value} } ) {
        $blk->($i) if defined $i;
    }
}

sub show {
    my $self   = shift;
    my $indent = shift;
    $indent = "" if !defined $indent;
    print $indent . "type: " . $self->{type} . "\n";
    print $indent . "(\n";
    $self->each( sub { $_[0]->show( $indent . "  " ); print $indent . "  ,\n"; }
    );
    print $indent . ")\n";
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
