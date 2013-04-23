package CljPerl::Atom;

  use strict;
  use warnings;

  use CljPerl::Printer;
  use CljPerl::Logger;

  sub new {
    my $class = shift;
    my $type = shift;
    my $value = shift;
    $value = "" if !defined $value;
    my $self = {class=>"Atom",
	        type=>$type,
	        value=>$value,
                meta=>{},
	        pos=>{filename=>"unknown",
		      line=>0,
	              col=>0}};
    bless $self;
    return $self;    
  }

  sub class {
    my $self = shift;
    return $self->{class};
  }

  sub type {
    my $self = shift;
    my $type = shift;
    if(defined $type) {
      $self->{type} = $type;
    } else {
      return $self->{type};
    }
  }

  sub meta {
    my $self = shift;
    my $meta = shift;
    if(defined $meta) {
      $self->{meta} = $meta;
    } else {
      return $self->{meta};
    }
  }

  sub value {
    my $self = shift;
    my $value = shift;
    if(defined $value) {
      $self->{value} = $value;
    } else {
      return $self->{value};
    }
  }

  sub show {
    my $self = shift;
    my $indent = shift;
    $indent = "" if !defined $indent;
    #print $indent . "class: " . $self->{class} . "\n";
    print $indent . "type: " . $self->{type} . "\n";
    print $indent . "value: " . $self->{value} . "\n";
  }

  sub error {
    my $self = shift;
    my $msg = shift;
    $msg .= " [";
    $msg .= CljPerl::Printer::to_string($self);
    $msg .= "] @[file: " . $self->{pos}->{filename};
    $msg .= " ;line: " . $self->{pos}->{line};
    $msg .= " ;col: " . $self->{pos}->{col} . "]";
    CljPerl::Logger::error($msg);
  }

1;
