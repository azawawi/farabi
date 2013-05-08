package Farabi::Plugin::PerlCritic;

use Moo;

# ABSTRACT: Perl::Critic support for Farabi
# VERSION

# Plugin module dependencies
has 'deps' => (
	is      => 'ro',
	default => sub {
		[ 'Perl::Critic' => '1.118', ];
	}
);

# Plugin's name
has 'name' => (
	is      => 'ro',
	default => sub {
		'Perl::Critic support';
	}
);

1;
