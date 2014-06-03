package Farabi::MIME;

# ABSTRACT: CodeMirror editor MIME type mapping
# VERSION

use Mojo::Base -strict;
use Method::Signatures;

=head1 find_editor_mode_and_mime_type

Finds the editor mode and mime type from the filename

=cut

func find_editor_mode_and_mime_type (Str $filename) {

	my $extension;
	if ( $filename =~ /\.([^.]+)$/ ) {

		# Extract file extension greedily
		$extension = $1;
	}

	my %extension_to_mode = (
		pl => {
			mode      => 'perl',
			mime_type => 'text/x-perl',
		},
		pm => {
			mode      => 'perl',
			mime_type => 'text/x-perl'
		},
		t => {
			mode      => 'perl',
			mime_type => 'text/x-perl'
		},
		css => {
			mode      => 'css',
			mime_type => 'text/css'
		},
		less => {
			mode      => 'css',
			mime_type => 'text/x-less'
		},
		js => {
			mode      => 'javascript',
			mime_type => 'text/javascript'
		},
		json => {
			mode      => 'javascript',
			mime_type => 'application/json'
		},
		html => {
			mode      => 'xml',
			mime_type => 'text/html'
		},
		ep => {

			#TODO fix workaround to .ep.html
			mode      => 'xml',
			mime_type => 'text/html'
		},
		html => {
			mode      => 'xml',
			mime_type => 'application/xml'
		},
		dtd => {
			mode      => 'dtd',
			mime_type => 'application/xml-dtd'
		},
		md => {
			mode      => 'markdown',
			mime_type => 'text/x-markdown'
		},
		markdown => {
			mode      => 'markdown',
			mime_type => 'text/x-markdown'
		},
		conf => {
			mode      => 'properties',
			mime_type => 'text/x-markdown'
		},
		conf => {
			mode      => 'properties',
			mime_type => 'text/x-markdown'
		},
		ini => {
			mode      => 'properties',
			mime_type => 'text/x-ini'
		},
		txt => {
			mode      => 'null',
			mime_type => 'text/plain'
		},
		'log' => {
			mode      => 'properties',
			mime_type => 'text/plain'
		},
		yml => {
			mode      => 'yaml',
			mime_type => 'text/x-yaml'
		},
		yaml => {
			mode      => 'yaml',
			mime_type => 'text/x-yaml'
		},
		coffee => {
			mode      => 'coffeescript',
			mime_type => 'text/x-coffeescript'
		},
		diff => {
			mode      => 'diff',
			mime_type => 'text/x-diff'
		},
		patch => {
			mode      => 'diff',
			mime_type => 'text/x-diff'
		},
		sql => {
			mode      => 'sql',
			mime_type => 'text/x-sql'
		},
		py => {
			mode      => 'python',
			mime_type => 'text/x-python'
		},
		php => {
			mode      => 'php',
			mime_type => 'text/x-php'
		},
		rb => {
			mode      => 'ruby',
			mime_type => 'text/x-ruby'
		},
		c => {
			mode      => 'clike',
			mime_type => 'text/x-csrc'
		},
		cpp => {
			mode      => 'clike',
			mime_type => 'text/x-c++src'
		},
		h => {
			mode      => 'clike',
			mime_type => 'text/x-csrc'
		},
		java => {
			mode      => 'clike',
			mime_type => 'text/x-java'
		},
	);

	# No extension, let us use default text mode
	return {
		mode      => "null",
		mime_type => 'text/plain',
	  }
	  unless defined $extension;
	return $extension_to_mode{$extension};
}

1;
