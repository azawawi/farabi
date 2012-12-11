package Farabi::Editor;
use Mojo::Base 'Mojolicious::Controller';

use Capture::Tiny qw(capture);

our $VERSION = '0.16';

# Taken from Padre::Plugin::PerlCritic
sub perl_critic {
	my $self     = shift;
	my $source   = $self->param('source');
	my $severity = $self->param('severity');

	# Check source parameter
	if ( !defined $source ) {
		$self->app->log->warn('Undefined "source" parameter');
		return;
	}

	# Check severity parameter
	if ( !defined $severity ) {
		$self->app->log->warn('Undefined "severity" parameter');
		return;
	}

	# Hand off to Perl::Critic
	require Perl::Critic;
	my @violations = Perl::Critic->new( -severity => $severity )->critique( \$source );

	my @results;
	for my $violation (@violations) {
		push @results,
			{
			policy      => $violation->policy,
			line_number => $violation->line_number,
			description => $violation->description,
			explanation => $violation->explanation,
			diagnostics => $violation->diagnostics,
			};
	}

	$self->render( json => \@results );
}

sub _capture_cmd_output {
	my $self     = shift;
	my $cmd      = shift;
	my $source   = $self->param('source');

	# Check source parameter
	unless ( defined $source ) {
		$self->app->log->warn('Undefined "source" parameter');
		return;
	}

	unless ( $self->app->unsafe_features ) {
		$self->app->log->warn('FARABI_UNSAFE not defined');
		return;
	}
	
	require File::Temp;
	my $tmp = File::Temp->new;
	print $tmp $source;
	close $tmp;

	my ($stdout, $stderr, $exit) = capture {
		system($cmd, $tmp->filename);
	};
	my $result = {
		stdout => $stdout,
		stderr => $stderr,
		'exit' => $exit & 128,
	};
	
	$self->render(json => $result);
}

sub run_perl {
	$_[0]->_capture_cmd_output($^X);
}

sub run_niecza {
	$_[0]->_capture_cmd_output('Niecza.exe');
}

sub run_rakudo {
	$_[0]->_capture_cmd_output('perl6');
}

sub run_parrot {
	$_[0]->_capture_cmd_output('parrot');
}

sub open_url {
	warn "Not implemented yet!";
}

sub search_file {
	warn "Not implemented yet!";
}

sub open_file {
	warn "Not implemented yet!";
}

# Taken from Padre::Plugin::PerlTidy
# TODO document it in 'SEE ALSO' POD section
sub perl_tidy {
	my $self   = shift;
	my $source = $self->param('source');

	# Check 'source' parameter
	unless ( defined $source ) {
		$self->app->log->warn('Undefined "source" parameter');
		return;
	}

	my %result = (
		'error'  => '',
		'source' => '',
	);

	my $destination = undef;
	my $errorfile   = undef;
	my %tidyargs    = (
		argv        => \'-nse -nst',
		source      => \$source,
		destination => \$destination,
		errorfile   => \$errorfile,
	);

	# TODO: suppress the senseless warning from PerlTidy
	eval {
		require Perl::Tidy;
		Perl::Tidy::perltidy(%tidyargs);
	};

	if ($@) {
		$result{error} = "PerlTidy Error:\n" . $@;
	}

	if ( defined $errorfile ) {
		$result{error} .= "\n$errorfile\n";
	}

	$result{source} = $destination;

	return $self->render( json => \%result );
}

# i.e. Autocompletion
sub typeahead {
	my $self = shift;
	my $query = quotemeta( $self->param('query') // '' );

	my %items;
	if ( open my $fh, '<', 'index.txt' ) {
		while (<$fh>) {
			$items{$1} = 1 if /^(.+?)\t/;
		}
		close $fh;
	}

	if ( open my $fh, '<', 'index-modules.txt' ) {
		while (<$fh>) {
			chomp;
			my ( $module, $file ) = split /\t/;
			$items{$module} = 1;
		}
		close $fh;
	}

	my @matches;
	for my $item ( keys %items ) {
		if ( $item =~ /$query/i ) {
			push @matches, $item;
		}
	}

	# Sort so that shorter matches appear first
	@matches = sort @matches;

	return $self->render( json => \@matches );
}

sub help_search {
	my $self = shift;
	my $topic = $self->param('topic') // '';

	# Determine perlfunc POD path
	require File::Spec;
	my $pod_path;
	for my $path (@INC) {
		for (qw(pod pods)) {
			if ( -e File::Spec->catfile( $path, $_, 'perlfunc.pod' ) ) {
				$pod_path = File::Spec->catfile( $path, $_ );
				last;
			}
		}
	}

	# TODO improve this check...
	return unless defined $pod_path;

	my $pod_index_filename = 'index.txt';
	unless ( -f $pod_index_filename ) {

		# Find all the .pm and .pod files in @INC
		$self->app->log->info("Finding all of *.pm and *.pod files in Perl search path");
		require File::Find::Rule;
		my @files = File::Find::Rule->file()->name( '*.pm', '*.pod' )->in(@INC);

		# Create an index
		$self->app->log->info("Creating POD index");
		require Pod::Index::Builder;
		my $p  = Pod::Index::Builder->new;
		my $t0 = time;
		for my $file (@files) {
			$self->app->log->info("Parsing $file");
			$p->parse_from_file($file);
		}
		$self->app->log->info( "Job took " . ( time - $t0 ) . " seconds" );
		$p->print_index($pod_index_filename);
	}

	my $module_index_filename = 'index-modules.txt';
	unless ( -f $module_index_filename ) {
		$self->app->log->info("Creating Module index");
		my %modules = $self->_find_installed_modules;
		if ( open my $fh, ">", $module_index_filename ) {
			for my $module ( sort keys %modules ) {
				say $fh "$module\t" . $modules{$module};
			}
			close $fh;
		}
	}

	# Search for a keyword in the file-based index
	require Pod::Index::Search;
	my $q = Pod::Index::Search->new(
		filename => $pod_index_filename,
		filemap  => sub {
			my $podname = shift;
			if ( $podname =~ /^.+::(.+?)$/ ) {
				$podname = File::Spec->catfile( $pod_path, "$1.pod" );
				unless ( -e $podname ) {
					$podname = s/::/\//g;
					$podname .= '.pm';
				}
			}
			return $podname;
		}
	);

	my @results = $q->search($topic);
	my @help_results;
	for my $r (@results) {
		next if $r->podname =~ /perltoc/i;
		my $podname = $r->podname;
		$podname =~ s/^.+::(.+)$/$1/;
		push @help_results,
			{
			'podname' => $podname,
			'context' => $r->context,
			'html'    => _pod2html( $r->pod ),
			};
	}

	if ( open my $fh, '<', $module_index_filename ) {
		my $filter = quotemeta $topic;
		while (<$fh>) {
			chomp;
			my ( $module, $filename ) = split /\t/;
			if ( $module =~ /^$filter$/i ) {
				push @help_results,
					{
					'podname' => $module,
					'context' => '',
					'html'    => _pod2html( $self->_module_pod($filename) ),
					},
					;
			}
		}
		close $fh;
	}

	$self->render( json => \@help_results );
}

sub _module_pod {
	my $self     = shift;
	my $filename = shift;

	$self->app->log->info("Opening '$filename'");
	my $pod = '';
	if ( open my $fh, '<', $filename ) {
		$pod = do { local $/ = <$fh> };
		close $fh;
	} else {
		$self->app->log->warn("Cannot open $filename");
	}

	return $pod;
}

#
# q{Taken from Padre}... Written by AZAWAWI :)
#
# Finds installed CPAN modules via @INC
# This solution resides at:
# http://stackoverflow.com/questions/115425/how-do-i-get-a-list-of-installed-cpan-modules
sub _find_installed_modules {
	my $self = shift;

	my %modules;
	require File::Find::Rule;
	require File::Basename;
	foreach my $path (@INC) {
		next if $path eq '.'; # Traversing this is a bad idea
		                      # as it may be the root of the file
		                      # system or the home directory
		foreach my $file ( File::Find::Rule->name( '*.pm', '*.pod' )->in($path) ) {
			my $module = substr( $file, length($path) + 1 );
			$module =~ s/.(pm|pod)$//;
			$module =~ s{[\\/]}{::}g;
			$modules{$module} = $file;
		}
	}
	return %modules;
}

# Convert Perl POD source to HTML
sub pod2html {
	my $self = shift;
	my $source = $self->param('source') // '';

	my $html = _pod2html($source);
	return $self->render( json => $html );
}

sub _pod2html {
	my $pod = shift;

	require Pod::Simple::XHTML;
	my $psx = Pod::Simple::XHTML->new;
	$psx->no_errata_section(1);
	$psx->no_whining(1);
	$psx->output_string( \my $html );
	$psx->parse_string_document($pod);

	return $html;
}

# Code borrowed from Padre::Plugin::Experimento - written by me :)
sub pod_check {
	my $self = shift;
	my $source = $self->param('source') // '';

	require Pod::Checker;
	require IO::String;

	my $checker = Pod::Checker->new;
	my $output  = '';
	$checker->parse_from_file( IO::String->new($source), IO::String->new($output) );

	my $num_errors   = $checker->num_errors;
	my $num_warnings = $checker->num_warnings;
	my @problems;

	say "$num_warnings, $num_errors";

	# Handle only errors/warnings. Forget about 'No POD in current document'
	if ( $num_errors != -1 and ( $num_errors != 0 or $num_warnings != 0 ) ) {
		for ( split /^/, $output ) {
			if (/^(.+?) at line (\d+) in file \S+$/) {
				push @problems,
					{
					message => $1,
					line    => int($2),
					};
			}
		}
	}

	return $self->render( json => \@problems );
}

sub default {
	my $self = shift;

	$self->stash(source => scalar $self->param('source'));

	# Render template "editor/default.html.ep"
	$self->render;
}

1;
