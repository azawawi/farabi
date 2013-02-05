package Farabi::Plugin::Debug;

our $VERSION = '0.30';

sub new {
	return bless {};
}

# Returns the plugin module dependencies
sub plugin_deps {
	return [
		'Debug::Client' => '0.20',
	];
}

# Returns the plugin's name
sub plugin_name {
	return 'Perl 5 Debugger';
}

1;

__END__

=pod

=head1 NAME

Farabi::Plugin::Debug - Debugger support for Farabi

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2013 by Ahmad M. Zawawi

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
