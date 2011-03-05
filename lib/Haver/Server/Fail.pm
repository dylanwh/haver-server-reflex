package Haver::Server::Fail;
use Moose;
use namespace::autoclean;

with 'Throwable';

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'args' => (
    is        => 'ro',
    isa       => 'ArrayRef[Str]',
    predicate => 'has_args',
);

__PACKAGE__->meta->make_immutable;
1;

