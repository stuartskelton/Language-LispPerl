package Language::LispPerl::Logger;

use strict;
use warnings;

use Carp;

use Log::Any qw/$log/;

sub error {
    my $msg = shift;
    $log->error("$msg");
    confess( $msg );
}

sub info {
    my $msg = shift;
    $log->info($msg);
}

sub warn {
    my $msg = shift;
    $log->warn($msg);
}

sub debug {
    my $msg = shift;
    $log->debug($msg);
}

1;

