package Farabi;
use Mojo::Base 'Mojolicious';

# ABSTRACT: Modern Perl IDE

sub startup {
	my $app = shift;

	# Change secret passphrase that is used for signed cookies
	$app->secret('Hulk, Smash!');

	# Use content from directories under lib/Farabi/files
	require File::Basename;
	require File::Spec::Functions;
	$app->home->parse(
		File::Spec::Functions::catdir(
			File::Basename::dirname(__FILE__), 'Farabi'
		)
	);
	$app->static->paths->[0]   = $app->home->rel_dir('files/public');
	$app->renderer->paths->[0] = $app->home->rel_dir('files/templates');

	# Define routes
	my $route = $app->routes;
	$route->get('/')->to('editor#default');
	$route->post('/')->to('editor#default');

	# Setup the Farabi database
	eval { $app->_setup_database; };
	if ($@) {
		warn "Database not setup, reason: $@";
	}

	# Setup websocket message handler
	$route->websocket('/websocket')->to('editor#websocket');
}

# Setup the Farabi database
sub _setup_database {

	# Connect and create the Farabi SQLite database if not found
	require DBIx::Simple;
	my $db = DBIx::Simple->connect('dbi:SQLite:dbname=farabi.db');

	# Create tables if they do not exist
	$db->query(<<SQL);
CREATE TABLE IF NOT EXISTS recent_list (
	id        INTEGER PRIMARY KEY AUTOINCREMENT, 
	name      TEXT,
	type      TEXT,
	last_used TEXT
)
SQL

	# Disconnect from database
	$db->disconnect;
}

1;
__END__

=pod

=head1 SYNOPSIS

  # Run on the default port 3000
  $ farabi daemon
  
  # Run it on port 3030
  $ farabi daemon --listen "http://*:3030"

=head1 DESCRIPTION

This is a modern web-based Perl IDE that runs inside your favorite browser.

Please run the following command and then open http://127.0.0.1:3000 in your browser:

  farabi daemon

=head1 TECHNOLOGIES USED

=over

=item *

L<Mojolicious|http://mojolicio.us> - A next generation web framework for the Perl programming language

=item *

L<jQuery|http://jquery.com/> - A new kind of JavaScript Library

=item *

L<JSHint|http://jshint.com/> - A JavaScript Code Quality Tool

=item *

L<Bootstrap|http://twitter.github.com/bootstrap> - Sleek, intuitive, and powerful front-end framework for faster and easier web development

=item *

L<CodeMirror|http://codemirror.net> - In-browser code editing made bearable

=item *

L<Perlito|http://perlito.org/> - Runtime for "Perlito" Perl5-in-Javascript

=back

=head1 SEE ALSO

L<EPIC|http://www.epic-ide.org/>, L<Kephra>, L<Padre>, L<TryPerl|http://tryperl.com/>

=head1 HISTORY

The idea started back in March 2012 as a fork of L<Padre>. I wanted to dump L<Wx> for the browser. 
The first version was in 11th April as L<Mojolicious::Plugin::Pedro>. It used the ACE Javascript
editor and jQuery UI. Then i hibernated for a while to play games :) Later I heard about L<Galileo>.
It basically used the same idea, mojolicious backend, browser for the frontend. So I stopped 
playing games and rolled my sleeves to focus on Pedro.

Later I discovered Pedro was not a good name for my project. So I chose Farabi for
L<Al-Farabi|http://en.wikipedia.org/wiki/Al-Farabi> who was a renowned scientist and philosopher
of the Islamic Golden Age. He was also a cosmologist, logician,and musician.

=head1 SUPPORT

If you find a bug, please report it in:

L<https://github.com/azawawi/farabi/issues>

If you find this module useful, please rate it in:

L<http://cpanratings.perl.org/d/Farabi>

=head1 AUTHORS

Ahmad M. Zawawi E<lt>ahmad.zawawi@gmail.comE<gt>

=head1 CONTRIBUTORS

Kevin Dawson E<lt>bowtie@cpan.orgE<gt>

=cut
