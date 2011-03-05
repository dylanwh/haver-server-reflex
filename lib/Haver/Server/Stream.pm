package Haver::Server::Stream;
use Moose;
use namespace::autoclean;

use Reflex::Callbacks 'cb_method';
use Haver::Server::Bus;
use Try::Tiny;

extends 'Reflex::Base';

has 'socket' => (
    is       => 'ro',
    isa      => 'FileHandle',
    required => 1,
);

with 'Reflex::Role::Streaming' => {
    handle      => 'socket',
    method_put  => '_put',
    method_stop => 'stop',
    cb_error    => 'on_error',
    cb_data     => 'on_data',
    cb_closed   => 'on_closed',
    ev_error    => 'error',
    ev_data     => 'data',
    ev_closed   => 'closed',
};

has 'filter' => (
    is       => 'ro',
    isa      => 'Haver::Server::Filter',
    required => 1,
);

has 'user' => (
    is        => 'rw',
    isa       => 'Haver::Server::Schema::User',
    predicate => 'has_user',
    clearer   => 'clear_user',
);

sub BUILD {
    my ($self) = @_;

    $self->watch($self,
        bork => cb_method($self, 'on_bork'),
        fail => cb_method($self, 'on_fail'),
    );
}

sub put {
    my ($self, $msg) = @_;
    $self->_put( $self->filter->put([$msg])->[0] );
}

sub on_data {
    my ( $self, $args ) = @_;
    my $msgs;

    warn "$args->{data}\n";
    try {
        $msgs = $self->filter->get( [ $args->{data} ] );
    }
    catch {
        $self->emit(event => 'bork', args => { description => "invalid json" });
    };

    try {
        for my $msg (@$msgs) {
            $self->emit(event => "client_msg", args => { msg => $msg });
        }
    }
    catch {
        if (blessed $_ && $_->isa('Haver::Server::Fail')) {
            $self->emit(
                event => 'fail', 
                args => { 
                    name => $_->name, 
                    $_->has_args ? (args => $_->args) : () 
                }
            );
        }
        else {
            $self->emit(event => 'bork', args => { description => "$_" });
            warn "Bork: ", $_;
        }
    };
}

sub on_error {
    my ( $self, $args ) = @_;
    warn "$args->{errfun} error $args->{errnum}: $args->{errstr}\n";
    $self->stopped();
}

sub on_fail {
    my ($self, $args) = @_;

    $self->put(['fail', { name => $args->{name}, description => $args->{description} }]);
}

sub on_bork {
    my ($self, $args) = @_;

    $self->put(['bork', { description => $args->{description} }]);
    $self->stopped;
}

sub on_server_msg {
    my ($self, $args) = @_;
    print "server msg: $args->{msg}\n";
    $self->put($args->{msg});
}

sub DEMOLISH {
    print "Demolish\n";
}

__PACKAGE__->meta->make_immutable;
1;
