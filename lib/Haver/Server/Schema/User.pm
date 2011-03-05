package Haver::Server::Schema::User;
use Moose;
use namespace::autoclean;

use KiokuDB::Util 'set';

with 'Haver::Server::Role::Named',
     'KiokuDB::Role::ID';

has 'online' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has '_rooms' => (
    init_arg => undef,
    is       => 'ro',
    default  => sub { set() },
    handles  => {
        join_room => 'insert',
        part_room => 'delete',
        rooms     => 'elements',
        in_room   => 'contains',
    },
);

after 'join_room' => sub {
    my ($self, @rooms) = @_;

    $_->_add_user($self) foreach @rooms;
};

after 'part_room' => sub {
    my ($self, @rooms) = @_;

    $_->_remove_user($self) foreach @rooms;
};

sub kiokudb_object_id {
    my ($self) = @_;
    return 'user:' . lc $self->name;
}

__PACKAGE__->meta->make_immutable;
1;
