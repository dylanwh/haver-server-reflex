#!/usr/bin/env perl
use strict;
use warnings;
use Haver::Server::Container;

my $c        = Haver::Server::Container->new(name => 'haver');
my $acceptor = $c->resolve(type => 'Haver::Server::Acceptor');

$acceptor->run_all;
