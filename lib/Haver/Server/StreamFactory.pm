package Haver::Server::StreamFactory;
use Moose;
use namespace::autoclean;

use Haver::Server::Stream;

has 'filter' => (
    is       => 'ro',
    isa      => 'Haver::Server::Filter',
    required => 1,
);

sub produce_stream {
    my $self = shift;

    Haver::Server::Stream->new(@_, filter => $self->filter);
}

__PACKAGE__->meta->make_immutable;
1;
