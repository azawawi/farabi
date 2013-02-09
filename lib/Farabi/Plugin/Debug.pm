package Farabi::Plugin::Debug;

# ABSTRACT: Debugger support for Farabi
use Moo;

# Plugin module dependencies
has 'deps' => (
	is      => 'ro',
	default => sub {
		[ 'Debug::Client' => '0.20', ];
	}
);

# Plugin's name
has 'name' => (
	is      => 'ro',
	default => sub {
		'Perl 5 Debugger';
	}
);

1;
