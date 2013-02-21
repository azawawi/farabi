package Farabi::Plugin::Debug;

use Moo;

# ABSTRACT: Perl debugger support for Farabi
# VERSION

# Plugin module dependencies
has 'deps' => (
	is      => 'ro',
	default => sub {
		[ 'Debug::Client' => '0.24', ];
	}
);

# Plugin's name
has 'name' => (
	is      => 'ro',
	default => sub {
		'Perl debugger support';
	}
);

1;
