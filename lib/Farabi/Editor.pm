package Farabi::Editor;
use Mojo::Base 'Mojolicious::Controller';

use Capture::Tiny qw(capture);
use IPC::Run qw( start pump finish timeout );

our $VERSION = '0.20';

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

# Find a list of matched actions
sub find_action {
	my $self = shift;
	
	# Quote every special regex character
	my $query = quotemeta( $self->param('action') // '' );

	# The actions
	my %actions = (
		'action-open-file'   => {
			name=>'Open File',
			help=>"Opens a file in a new editor tab",
		},
		'action-open-url'   => {
			name=> 'Open URL',
			help=>  'Opens a file from a URL is new editor tab',
		},
		'action-perl-tidy'   => {
			name=> 'Perl Tidy',
			help=>'Run the Perl::Tidy tool on the current editor tab',
		},
		'action-perl-critic' => {
			name=> 'Perl Critic',
			help=> 'Run the Perl::Critic tool on the current editor tab',
		},
		'action-syntax-check' => {
			name=>'Syntax Check',
			help=>'Run the syntax check tool on the current editor tab',
		},
		'action-run'          => {
			name=>'Run',
			help=> 'Run the current editor source file using the run dialog',
		},
		'action-options'      => {
			name=> 'Options',
			help=> 'Open the options dialog',
		},
		'action-help' => {
			name=>'Help - Getting Started',
			help=> 'A quick getting started help dialog',
		},
		'action-about'       => {
			name=> 'About Farabi',
			help=> 'Opens an dialog about the current application',
		},
		'action-perl-doc' => {
			name => 'Help - Perl Documentation',
			help =>'Opens the Perl help documentation dialog',
		},
		'action-repl' => {
			name =>'REPL - Read-Print-Eval-Loop',
			help => 'Opens the Read-Print-Eval-Loop dialog',
		},
	);

	# Find matched actions
	my @matches;
	for my $action_id ( keys %actions ) {
		my $action = $actions{$action_id};
		my $action_name = $action->{name};
		if ( $action_name =~ /^.*$query.*$/i ) {
			push @matches, { 
				id =>  $action_id, 
				name =>  $action_name,
				help => $action->{help},
			};
		}
	}
	
	# Sort so that shorter matches appear first
	@matches = sort { $a->{name} cmp $b->{name} }@matches;
	
	# And return as JSON
	return $self->render( json => \@matches );
}

# Find a list of matches files
sub find_file {
	my $self = shift;
	
	# Quote every special regex character
	my $query = quotemeta( $self->param('filename') // '' );

	require File::Find::Rule;
	my $rule = File::Find::Rule->new;
	$rule->or(
			$rule->new->directory->name( 'CVS', '.svn', '.git', 'blib', '.build' )->prune->discard,
			$rule->new
	);
	
	require Cwd;
	$rule->file->name(qr/$query/i);
	my @files = $rule->in(Cwd::getcwd);
	
	require File::Basename;
	my @matches;
	for my $file (@files) {
		push @matches, {
			id => $file,
			name => File::Basename::basename($file),
		}
	}

	# Sort so that shorter matches appear first
	@matches = sort { $a->{name} cmp $b->{name} }@matches;
	
	my $MAX_RESULTS = 100;
	if(scalar @files > $MAX_RESULTS) {
		@matches = @matches[0..$MAX_RESULTS-1];
	}

	# And return as JSON
	return $self->render( json => \@matches );
}

# Return the file contents or a failure string
sub open_file {
	my $self = shift;
	
	my $filename = $self->param('filename') // '';

	my %result = ();
	if( open my $fh, '<', $filename ) {
		# Slurp the file contents
		local $/ = undef;
		$result{value} = <$fh>;
		close $fh;
		
		# Retrieve editor mode
		$result{mode} = _find_editor_mode_from_filename($filename);
		
		# We're ok :)
		$result{ok} = 1;
	} else {
		# Error!
		$result{value} = "Could not open file: $filename";
		$result{ok} = 0;
	}
	
	# Return the file contents or the error message
	return $self->render( json => \%result );
}

# Finds the editor mode from the the filename
sub _find_editor_mode_from_filename {
	my $filename = shift;
	
	my $extension;
	if($filename =~ /\.(.+)$/) {
		# Extract file extension greedily
		$extension = $1;
	}
	
	my %extension_to_mode = (
		pl         => 'perl',
		pm         => 'perl',
		p6         => 'perl6',
		pm6        => 'perl6',
		pir        => 'pir',
		css        => 'css',
		'min.css'  => 'javascript',
		js         => 'javascript',
		json       => 'javascript',
		'min.js'   => 'javascript',
		html       => 'xml',
		'html.ep'  => 'xml',
		md         => 'markdown',
		markdown   => 'markdown',
		conf       => 'properties',
		properties => 'properties',
		yml        => 'yaml',
		yaml       => 'yaml',
	);
	
	# No extension, let us use default text mode
	return 0 if !defined $extension;
	return $extension_to_mode{$extension};
}


# Perl REPL (Read-Eval-Print-Loop)
sub perl_repl_eval {
	warn "perl_repl_eval is not implemented\n";
}

# Perl6 REPL (Read-Eval-Print-Loop)
sub repl_eval {
	my $self = shift;
	my $runtime = $self->param('runtime') // 'perl';
	my $command = $self->param('command') // '';

	# The process that we're gonna REPL
	my @perl6 = qw( perl6 );
	
	# The input, output and error strings
	my ($in, $out, $err);
	
	# Open process with a timeout
	my $h = start \@perl6, \$in, \$out, \$err, timeout( 5 );

	# Send command to process and wait for prompt
	$in .= "$command\n";
	pump $h until $out =~ /> \Z/m;
	finish $h or $err = "perl6 returned $?";
	
	# Remove prompt
	$out =~ s/> \Z//;
	
	say $out;

	# Result...
	my %result = (
		out => $out,
		err  => $err,
	);

	# Return the REPL result
	return $self->render( json => \%result );
}

# The default root handler
sub default {
	my $self = shift;

	# Stash the source parameter so it can be used inside the template
	$self->stash(source => scalar $self->param('source'));

	# Render template "editor/default.html.ep"
	$self->render;
}

1;
