package Haver::Server::Bus;
use Moose;
use namespace::autoclean;

use Reflex::Callbacks;

extends 'Reflex::Base';

sub join {
    my ($self, $room, $client) = @_;

    $client->watch($self, '#'.$room, cb_method($client, 'on_server_msg'));
}

sub part {
    my ($self, $room, $client) = @_;

    $client->ignore($self, '#'.$room);
}

sub login {
    my ($self, $name, $client) = @_;
    $client->watch($self, '@'.$name, cb_method($client, 'on_server_msg'));
}

sub logout {
    my ($self, $name, $client) = @_;
    $client->ignore($self, '@'.$name);
}

sub send_msg {
    my ($self, $target, $msg) = @_;
    $self->emit(event => $target, args => { msg => $msg });
}

__PACKAGE__->meta->make_immutable;
1;
