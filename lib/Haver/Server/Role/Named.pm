package Haver::Server::Role::Named;
use Moose::Role;
use namespace::autoclean;

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;
