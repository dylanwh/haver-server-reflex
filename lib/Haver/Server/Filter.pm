package Haver::Server::Filter;
use Moose;
use namespace::autoclean;

with 'MooseX::Clone';

use POE::Filter::Stackable;
use POE::Filter::Line;
use Haver::Server::Filter::JSON;

has 'filter' => (
    traits   => ['NoClone'],
    init_arg => undef,
    reader   => '_filter',
    default  => sub {
        POE::Filter::Stackable->new(
            Filters => [
                POE::Filter::Line->new( Literal   => "\n" ),
                Haver::Server::Filter::JSON->new( delimiter => 0, json_any => { allow_barekey => 1 } ),
            ],
        );
    },
    handles => [qw[ get_one_start get_one get put get_pending ]],
);

__PACKAGE__->meta->make_immutable;
1;
