package Farabi::Plugin::PerlTidy;

# ABSTRACT: Perl::Tidy support for Farabi

use Moo;

# Plugin module dependencies
has 'deps' => (
	is      => 'ro',
	default => sub {
		[ 'Perl::Tidy' => '20120714', ];
	}
);
s
# Plugin's name
has 'name' => (
	is      => 'ro',
	default => sub {
		'Perl::Tidy support';
	}
);

1;
