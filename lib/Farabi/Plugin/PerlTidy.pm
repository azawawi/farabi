package Farabi::Plugin::PerlTidy;

our $VERSION = '0.29';

sub new {
	return bless {};
}

# Returns the plugin's name
sub plugin_name {
	return 'Perl::Tidy support';
}

1;

__END__

=pod
s
=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2013 by Ahmad M. Zawawi

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
