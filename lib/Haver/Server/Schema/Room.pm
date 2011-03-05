package Haver::Server::Schema::Room;
use Moose;
use namespace::autoclean;

use KiokuDB::Util 'set';

with 'Haver::Server::Role::Named',
     'KiokuDB::Role::ID';

has '_users' => (
    init_arg => undef,
    is      => 'ro',
    default => sub { set() },
    handles => {
        users => 'elements',

        # for User to call
        _add_user    => 'insert',
        _remove_user => 'delete',
    },
);

sub kiokudb_object_id {
    my ($self) = @_;
    return 'room:' . lc $self->name;
}

__PACKAGE__->meta->make_immutable;
1;
