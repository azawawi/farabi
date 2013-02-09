package Farabi::Plugin::PerlCritic;

# ABSTRACT: Perl::Critc support for Farabi

use Moo;

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
