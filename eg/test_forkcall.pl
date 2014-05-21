#!/usr/bin/env perl

use v5.16;
use Mojo::IOLoop;
use Mojo::IOLoop::ForkCall qw/fork_call/;
use Capture::Tiny qw(capture);

Mojo::IOLoop->recurring( 1 => sub { say 'tick' } );

fork_call {
    my ( $stdout, $stderr, $exit ) = capture {
        system( 'tasklist', () );
    };
	
	return ( $stdout, $stderr, $exit );
}
sub {
    die $@ if $@;
    use Data::Printer;
    p @_;
    Mojo::IOLoop->stop;
};

Mojo::IOLoop->start;

