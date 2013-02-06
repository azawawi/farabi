package Farabi::Plugin::PerlCritic;

use Moo;

our $VERSION = '0.31';

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

__END__

=pod

=head1 NAME

Farabi::Plugin::PerlCritic - Perl::Critc support for Farabi

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2013 by Ahmad M. Zawawi

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
