package Haver::Server::Acceptor;
use Moose;
use namespace::autoclean;

use Reflex::Collection;
use Reflex::Callbacks;
use Haver::Server::Stream;
use Haver::Server::Commands;

extends 'Reflex::Acceptor';

has_many 'streams' => ( 
    handles => { 'remember_stream' => 'remember' }, 
);

has 'stream_factory' => (
    is       => 'ro',
    isa      => 'Haver::Server::StreamFactory',
    required => 1,
);

has 'commands' => (
    is       => 'ro',
    isa      => 'Haver::Server::Commands',
    required => 1,
);

sub on_accept {
    my ( $self, $args ) = @_;
    my $stream = $self->stream_factory->produce_stream(socket => $args->{socket});
    $self->remember_stream($stream);

    my $cmds = $self->commands;
    $cmds->watch($stream, client_msg => cb_method($cmds, 'on_client_msg') );
}

sub on_error {
    my ( $self, $args ) = @_;
    warn "$args->{errfun} error $args->{errnum}: $args->{errstr}\n";
    $self->stop();
}

__PACKAGE__->meta->make_immutable;
1;
