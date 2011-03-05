package Haver::Server::Commands;
use Moose;
use namespace::autoclean;

use Reflex::Callbacks;

extends 'Reflex::Base';

has 'bus' => (
    is       => 'ro',
    isa      => 'Haver::Server::Bus',
    required => 1,
);

sub on_client_msg {
    my ($self, $args) = @_;
    my ($name, @args) = @{$args->{msg}};
    my $sender = $args->{_sender};
    my $stream = $sender->get_first_emitter;

    my $method = $self->can("cmd_\U$name");
    if ($method) {
        $self->$method($stream, @args);
    }
    else {
        $stream->emit(event => 'fail', args => { name => "unknown_cmd", description => "$name" });
    }
}

sub cmd_HAVER {
    my ($self, $stream, $args) = @_;
    $stream->put(['haver', { server_name => 'Haver::Server (Reflex)' }]);
}

sub cmd_IDENT {
    my ($self, $stream, $args) = @_;

}

__PACKAGE__->meta->make_immutable;
1;
