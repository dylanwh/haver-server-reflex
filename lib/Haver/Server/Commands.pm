package Haver::Server::Commands;
use Moose;
use namespace::autoclean;

use Reflex::Callbacks;
use Haver::Server::Util 'fail';

extends 'Reflex::Base';

has 'bus' => (
    is       => 'ro',
    isa      => 'Haver::Server::Bus',
    required => 1,
);

has 'model' => (
    is       => 'ro',
    isa      => 'Haver::Server::Model',
    required => 1,
);

sub on_client_msg {
    my ($self, $args) = @_;
    my ($name, @args) = @{$args->{msg}};
    my $sender = $args->{_sender};
    my $stream = $sender->get_first_emitter;

    my $method = $self->can("cmd_\U$name");
    if ($method) {
        $self->model->txn_do(sub { $self->$method($stream, @args) }, scope => 1);
    }
    else {
        fail unknown_cmd => $name;
    }
}

sub on_stopped {
    my ($self, $args) = @_;
    my $sender = $args->{_sender};
    my $stream = $sender->get_first_emitter;
    my $model  = $self->model;
    my $scope  = $model->new_scope;

    if ($stream->user) {
        warn "logout user...\n";
        $model->logout_user($stream->user);
    }
}

sub cmd_IDENT {
    my ($self, $stream, $name) = @_;
    my $bus = $self->bus;
    my $model = $self->model;

    my $user = $model->login_user($name);

    $bus->login($name, $stream);
    $stream->user($user);
    $stream->put(['hello', $name]);
}

sub cmd_OPEN {
    my ($self, $stream, $args) = @_;
    my $model = $self->model;
    fail missing_arg => "name" unless $args->{name};

    my $room = $model->open_room(name => $args->{name}, owner => $stream->user);
    $stream->put(['open', { name => $room->name, owner => $stream->user->name }]);
}

sub cmd_JOIN {
    my ($self, $stream, $args) = @_;
    my $bus = $self->bus;
    my $model = $self->model;
    my $name = $args->{room} or fail missing_arg => "room";

    $model->join_room( $stream->user, $model->room_or_fail($name) );
    $bus->join($name, $stream);
    $bus->send_room($name, [ 'join', { user => $stream->user->name, room => $name }]);
}

sub cmd_PART {
    my ($self, $stream, $args) = @_;
    my $bus = $self->bus;
    my $model = $self->model;
    my $name = $args->{room} or fail missing_arg => "room";

    $model->part_room( $stream->user, $model->room_or_fail($name) );
    $bus->send_room($name, [ 'part', { user => $stream->user->name, room => $name }]);
    $bus->part($name, $stream);
}

sub cmd_MSG {
    my ($self, $stream, $args) = @_;
    my $bus = $self->bus;
    my $model = $self->model;

    fail missing_arg => 'target'       unless $args->{target};
    fail missing_arg => 'content'      unless $args->{content};
    fail missing_arg => 'content_type' unless $args->{content_type};

    my $target = $args->{target};

    if ( $target->{room} ) {
        $bus->send_room(
            $target->{room},
            [   
                'msg' => {
                    source => { user => $stream->user->name, room => $target->{room} },
                    content_type => $args->{content_type},
                    content      => $args->{content},
                }
            ]
        );
    }
    elsif ( $target->{user} ) {
        $bus->send_user(
            $target->{user},
            [   
                'msg' => {
                    source       => { user => $stream->user->name },
                    content_type => $args->{content_type},
                    content      => $args->{content},
                }
            ]
        );
    }
}

__PACKAGE__->meta->make_immutable;
1;
