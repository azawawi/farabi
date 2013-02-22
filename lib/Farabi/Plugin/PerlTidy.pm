package Farabi::Plugin::PerlTidy;

use Moo;

# ABSTRACT: Perl::Tidy support for Farabi
# VERSION

# Plugin module dependencies
has 'deps' => (
	is      => 'ro',
	default => sub {
		[ 'Perl::Tidy' => '20120714', ];
	}
);

# Plugin's name
has 'name' => (
	is      => 'ro',
	default => sub {
		'Perl::Tidy support';
	}
);

1;
