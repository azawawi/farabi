#!/usr/bin/env perl
use Dancer;
use TestApp;
use AnyEvent::Loop ();
use Twiggy::Server ();

# Create a twiggy AnyEvent server
my $server = Twiggy::Server->new(
    host => '127.0.0.1',
    port => 5000,
);

# Define our dancer application
my $app = sub {
    Dancer->dance( Dancer::Request->new( env => $_[0] ) );
};

# The dancer application is run by twiggy
$server->register_service($app);

# Now we run the event loop
AnyEvent::Loop::run;
