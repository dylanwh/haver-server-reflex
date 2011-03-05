package Haver::Server::Container;
use Moose;
use namespace::autoclean;

use Haver::Server::Stream;
use Haver::Server::StreamFactory;
use Haver::Server::Acceptor;
use Haver::Server::Filter;
use Socket;
use IO::Socket;

use Bread::Board;

extends 'Bread::Board::Container';

sub BUILD {
    my ($self) = @_;

    container $self => as {
        service 'port' => 7575;
        service 'socket' => (
            block => sub {
                my $s = shift;
                return IO::Socket::INET->new(
                    Listen    => 1,
                    ReuseAddr => 1,
                    Type      => SOCK_STREAM,
                    LocalPort => $s->param('port'),
                    Blocking  => 0,
                );
            },
            dependencies => wire_names('port'),
        );

        typemap 'Haver::Server::Stream'   => infer;
        typemap 'Haver::Server::Filter'   => infer;
        typemap 'Haver::Server::Acceptor' => infer(
            dependencies => { listener => depends_on('socket') },
        );
      };
}

__PACKAGE__->meta->make_immutable;
1;
