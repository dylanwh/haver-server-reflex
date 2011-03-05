package Haver::Server::Model;
use Moose;
use namespace::autoclean;

use Haver::Server::Schema::User;
use Haver::Server::Schema::Room;
use Haver::Server::Util 'fail';

use MooseX::Params::Validate;

extends 'KiokuX::Model', 'Reflex::Base';

sub make_user {
    my ( $self, $name ) = @_;

    my $user = Haver::Server::Schema::User->new( name => $name );
    $self->store($user);

    return $user;
}

sub room {
    my ( $self, $name ) = @_;
    return $self->lookup("room:$name");
}

sub user {
    my ( $self, $name ) = @_;
    return $self->lookup("user:$name");
}

sub room_or_fail {
    my ( $self, $name ) = @_;
    return $self->room($name) || fail not_found => 'room', $name;
}

sub user_or_fail {
    my ( $self, $name ) = @_;
    return $self->user($name) || fail not_found => 'user', $name;
}

sub login_user {
    my ( $self, $name ) = @_;
    my $user = $self->user($name) || $self->make_user($name);

    if ( not $user->online ) {
        $user->online(1);
        $self->update($user);
        return $user;
    }
    else {
        fail 'exists';
    }
}

sub logout_user {
    my ( $self, $user ) = @_;

    $user->online(0);
    $self->update($user);
}

sub open_room {
    my ( $self, %args ) = @_;

    fail(exists => $args{name}) if $self->room( $args{name} );

    my $room = Haver::Server::Schema::Room->new(%args) or die "wtf";
    $self->store($room);

    return $room || die "pants";
}

sub join_room {
    my $self = shift;
    my ( $user, $room ) = pos_validated_list(
        \@_,
        { isa => 'Haver::Server::Schema::User' },
        { isa => 'Haver::Server::Schema::Room' },
    );

    fail already_joined => $room->name if $user->in_room($room);

    $user->join_room($room);
    $self->deep_update($user);
}

sub part_room {
    my ( $self, $user, $room ) = @_;

    fail not_joined => $room->name unless $user->in_room($room);

    $user->part_room($room);
    $self->deep_update($user);
}

__PACKAGE__->meta->make_immutable;
1;
