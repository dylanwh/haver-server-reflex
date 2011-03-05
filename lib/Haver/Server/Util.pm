package Haver::Server::Util;
use strictures 1;
use Sub::Exporter (
    -setup => {
        exports => [ 'fail' ],
    }
);

use Haver::Server::Fail;

sub fail($@) {
    my ($name, @args) = @_;

    Haver::Server::Fail->throw(name => $name, args => \@args);
}

1;
