#!/usr/bin/env perl
use Dancer;
use TestApp;
use EV             ();
use Twiggy::Server ();

# Create a twiggy AnyEvent server
my $server = Twiggy::Server->new(
    host => '127.0.0.1',
    port => 5000,
);

# Define our dancer application
my $app = sub {
    my $env = shift;
    Dancer->dance( Dancer::Request->new( env => $env ) );
};

# The dancer application is run by twiggy
$server->register_service($app);

# Now we run the event loop
EV::loop;

