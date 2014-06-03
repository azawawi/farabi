package Farabi;

use Mojo::Base 'Mojolicious';
use Path::Tiny;
use Method::Signatures;

# ABSTRACT: Modern Perl IDE
# VERSION

=pod

=head1 SYNOPSIS

  # Run on the default port 4040
  $ farabi
  
  # Run it on port 5050
  $ farabi --port 5050

=head1 DESCRIPTION

This is a modern web-based Perl IDE that runs inside your favorite browser.

Please run the following command and then open http://127.0.0.1:4040 in your browser:

  farabi

=head1 SECURITY WARNING

B<Farabi is an experiment in progress>. It is a web-based user interface with a backend Perl web server.
Please B<DO NOT> serve it on the Internet unless you jail it in an isolated uber-secure 
environment that has proper CPU and I/O limits and non-root access.

You have been warned, young padawan :)

=head1 FEATURES

=over

=item Open File(s)

The dialog provides partial filename search inside the directory where Farabi was started.
Matched single or multiple file selections can then be opened in one batch.

B<WARNING:> Please do not start farabi in a folder with too many files like your home directory
because this feature's performance will eventually suffer.

=back

=head1 METHODS

=cut

# Application SQLite database and projects are stored in this directory
has 'home_dir';

# Projects are stored in this directory
has 'projects_dir';

# The database name and location
has 'db_name';

method startup {

	# Change secret passphrase that is used for signed cookies
	$self->secrets( ['Hulk, Smash!'] );

	# Use content from directories under lib/Farabi/files
	$self->home->parse( path( path(__FILE__)->dirname, 'Farabi' ) );
	$self->static->paths->[0]   = $self->home->rel_dir('files/public');
	$self->renderer->paths->[0] = $self->home->rel_dir('files/templates');

	# Define routes
	my $route = $self->routes;
	$route->get('/')->to('editor#default');
	$route->post("/syntax_check")->to('editor#syntax_check');
	$route->post('/pod2html')->to('editor#pod2html');
	$route->post("/md2html")->to('editor#md2html');
	$route->post("/perl_critic")->to('editor#perl_critic');
	$route->post("/perl_tidy")->to('editor#perl_tidy');
	$route->post("/perl_strip")->to('editor#perl_strip');
	$route->post("/spellunker")->to('editor#spellunker');
	$route->post("/code_cutnpaste")->to('editor#code_cutnpaste');
	$route->post("/git")->to('editor#git');
	$route->post("/open_file")->to('editor#open_file');
	$route->post("/save_file")->to('editor#save_file');
	$route->post("/find_file")->to('editor#find_file');
	$route->post("/find_action")->to('editor#find_action');
	$route->post("/run_perl")->to('editor#run_perl');
	$route->post("/run_perlbrew_exec")->to('editor#run_perlbrew_exec');
	$route->post("/dump_ppi_tree")->to('editor#dump_ppi_tree');
	$route->post("/repl_eval")->to('editor#repl_eval');
	$route->post("/ping")->to('editor#ping');
	$route->post("/ack")->to('editor#ack');
	$route->post("/midgen")->to('editor#midgen');
	$route->post("/project")->to('editor#project');
	$route->post("/cpanm")->to('editor#cpanm');
	$route->post("/help")->to('editor#help');

	eval { $self->_setup_dirs };
	if ($@) {
		die "Failure to create \$HOME/.farabi directory structure, reason: $@";
	}

	# The database name
	$self->db_name( path( $self->home_dir, 'farabi.db' ) );

	# Setup the Farabi database
	eval { $self->_setup_database };
	if ($@) {
		warn "Database not setup, reason: $@";
	}
}

=head1 support_can_be_enabled

Returns 1 when a required C<module> with a specific version is found otherwise returns 0.

It can be used in the future to toggle feature XYZ runtime support

=cut

method support_can_be_enabled ($module) {

	my %REQUIRED_VERSION = (
		'Perl::Critic'          => '1.118',
		'Perl::Tidy::Sweetened' => '0.24',
		'Perl::Strip'           => '1.1',
		'Spellunker'            => '0.0.17',
		'Code::CutNPaste'       => '0.04',
		'App::Midgen'           => '0.32',
		'Dist::Zilla'           => '5.016',
	);

	my $version = $REQUIRED_VERSION{$module};
	return 0 unless defined $version;

	eval qq{use $module $version;};
	if ($@) {
		$self->log->warn(
"$module support is disabled. Please install $module $version or later."
		);
		return 0;
	}
	else {
		$self->log->info("$module support is enabled");
		return 1;
	}
}

#
# Create the following directory structure:
# .farabi
# .farabi/projects
#
method _setup_dirs {

	require File::HomeDir;

	$self->home_dir( path( File::HomeDir->home, ".farabi" ) );
	$self->projects_dir( path( $self->home_dir, "projects" ) );
	$self->projects_dir->mkpath;
}

# Setup the Farabi database
method _setup_database {

	# Connect and create the Farabi SQLite database if not found
	require DBIx::Simple;
	my $db_name = $self->db_name;
	my $db      = DBIx::Simple->connect("dbi:SQLite:dbname=$db_name");

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
