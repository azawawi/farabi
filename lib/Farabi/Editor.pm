package Farabi::Editor;

# ABSTRACT: Controller
# VERSION

use Mojo::Base 'Mojolicious::Controller';
use Capture::Tiny qw(capture);
use IPC::Run qw( start pump finish timeout );
use Path::Tiny;

# The actions

my $file_menu  = '01.File';
my $edit_menu  = '02.Edit';
my $run_menu   = '03.Run';
my $tools_menu = '04.Tools';
my $help_menu  = '05.Help';

my %actions = (
	'action-new-file' => {
		name  => 'New File - Alt+N',
		help  => "Opens a new file in an editor tab",
		menu  => $file_menu,
		order => 1,
	},

	'action-new-project' => {
		name  => 'New Project',
		help  => "Creates a new project using Module::Starter",
		menu  => $file_menu,
		order => 2,
	},
	'action-open-file' => {
		name  => 'Open File(s) - Alt+O',
		help  => "Opens one or more files in an editor tab",
		menu  => $file_menu,
		order => 3,
	},
	'action-save-file' => {
		name  => 'Save File - Alt+S',
		help  => "Saves the current file ",
		menu  => $file_menu,
		order => 4,
	},
	'action-close-file' => {
		name  => 'Close File - Alt+W',
		help  => "Closes the current open file",
		menu  => $file_menu,
		order => 5,
	},
	'action-close-all-files' => {
		name  => 'Close All Files',
		help  => "Closes all of the open files",
		menu  => $file_menu,
		order => 6,
	},
	'action-goto-line' => {
		name  => 'Goto Line - Alt+L',
		help  => 'A dialog to jump to the needed line',
		menu  => $edit_menu,
		order => 1,
	},
	'action-options' => {
		name  => 'Options',
		help  => 'Open the options dialog',
		menu  => $tools_menu,
		order => 1,
	},
	'action-perl-tidy' => {
		name  => 'Perl Tidy',
		help  => 'Run the Perl::Tidy tool on the current editor tab',
		menu  => $tools_menu,
		order => 3,
	},
	'action-perl-critic' => {
		name  => 'Perl Critic',
		help  => 'Run the Perl::Critic tool on the current editor tab',
		menu  => $tools_menu,
		order => 4,
	},
	'action-perl-strip' => {
		name  => 'Perl Strip',
		help  => 'Run Perl::Strip on the current editor tab',
		menu  => $tools_menu,
		order => 5,
	},
	'action-jshint' => {
		name  => 'JSHint',
		help  => 'Run JSHint on the current editor tab',
		menu  => $tools_menu,
		order => 6,
	},
	'action-find-duplicate-perl-code' => {
		name  => 'Find Duplicate Perl Code',
		help  => 'Finds any duplicate perl code in the current lib folder',
		menu  => $tools_menu,
		order => 7,
	},
	'action-git-diff' => {
		name  => 'Git Diff',
		help  => 'Show Git changes between commits',
		menu  => $tools_menu,
		order => 8,
	},
	'action-repl' => {
		name  => 'REPL - Read-Print-Eval-Loop',
		help  => 'Opens the Read-Print-Eval-Loop dialog',
		menu  => $tools_menu,
		order => 9,
	},
	'action-spell-check' => {
		name  => 'Check Spelling',
		help  => "Checks current tab spelling using Spellunker",
		menu  => $tools_menu,
		order => 10,
	},
	'action-dump-ppi-tree' => {
		name  => 'Dump the PPI tree',
		help  => "Dumps the PPI tree into the output pane",
		menu  => $tools_menu,
		order => 11,
	},
#	'action-debug-step-in' => {
#		name  => 'Step In',
#		help  => '',
#		menu  => $run_menu,
#		order => 1,
#	},
#	'action-debug-step-over' => {
#		name  => 'Step Over',
#		help  => '',
#		menu  => $run_menu,
#		order => 2,
#	},
#	'action-debug-step-out' => {
#		name  => 'Step Out',
#		help  => '',
#		menu  => $run_menu,
#		order => 3,
#	},
#	'action-debug-stop' => {
#		name  => 'Stop Debugging',
#		help  => '',
#		menu  => $run_menu,
#		order => 4,
#	},
	'action-run' => {
		name  => 'Run - Alt+Enter',
		help  => 'Run the current editor source file using the run dialog',
		menu  => $run_menu,
		order => 5,
	},
	'action-syntax-check' => {
		name  => 'Syntax Check',
		help  => 'Run the syntax check tool on the current editor tab',
		menu  => $run_menu,
		order => 6,
	},
	'action-help' => {
		name  => 'Help - Getting Started',
		help  => 'A quick getting started help dialog',
		menu  => $help_menu,
		order => 1,
	},
	'action-perl-doc' => {
		name  => 'Help - Perl Documentation',
		help  => 'Opens the Perl help documentation dialog',
		menu  => $help_menu,
		order => 2,
	},
	'action-about' => {
		name  => 'About Farabi',
		help  => 'Opens an dialog about the current application',
		menu  => $help_menu,
		order => 3,
	},
);

sub menus {
	my $menus = ();

	for my $name ( keys %actions ) {
		my $action = $actions{$name};
		my $menu   = $action->{menu};
		$menu = ucfirst($menu);

		$menus->{$menu} = [] unless defined $menus->{$menu};

		push @{ $menus->{$menu} },
		  {
			action => $name,
			name   => $action->{name},
			order  => $action->{order},
		  };

	}

	for my $name ( keys %$menus ) {
		my $menu = $menus->{$name};

		my @sorted = sort { $a->{order} <=> $b->{order} } @$menu;
		$menus->{$name} = \@sorted;
	}

	$menus;
}

# Taken from Padre::Plugin::PerlCritic
sub perl_critic {
	my $self     = shift;
	my $source   = $_[0]->{source};
	my $severity = $_[0]->{severity};

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
	my @violations =
	  Perl::Critic->new( -severity => $severity )->critique( \$source );

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

	return \@results;
}

sub _capture_cmd_output {
	my $self   = shift;
	my $cmd    = shift;
	my $opts   = shift;
	my $source = shift;
	my $input  = shift;

	require File::Temp;

	# Source is stored in a temporary file
	my $source_fh;
	if ( defined $source ) {
		$source_fh = File::Temp->new;
		print $source_fh $source;
		close $source_fh;
	}

	# Input is stored in a temporary file
	my $input_fh;
	if ( defined $input ) {
		$input_fh = File::Temp->new;
		print $input_fh $input;
		close $input_fh;
	}

	my ( $stdout, $stderr, $exit ) = capture {
		if ( defined $input_fh ) {

			if ( defined $source_fh ) {
				system( $cmd, @$opts, $source_fh->filename,
					"<" . $input_fh->filename );
			}
			else {
				system( $cmd, @$opts, "<" . $input_fh->filename );
			}
		}
		else {
			if ( defined $source_fh ) {
				system( $cmd, @$opts, $source_fh->filename );
			}
			else {
				system( $cmd, @$opts );
			}
		}
	};
	my $result = {
		stdout => $stdout,
		stderr => $stderr,
		'exit' => $exit >> 8,
	};

	return $result;
}

sub run_perl {
	my $self   = shift;
	my $params = shift;
	my $source = $params->{source};
	my $input  = $params->{input};
	$self->_capture_cmd_output( $^X, [], $source, $input );
}

sub run_rakudo {
	my $self   = shift;
	my $params = shift;
	my $source = $params->{source};
	my $input  = $params->{input};
	$self->_capture_cmd_output( 'perl6', [], $source, $input );
}

sub run_parrot {
	my $self   = shift;
	my $params = shift;
	my $source = $params->{source};
	my $input  = $params->{input};
	$self->_capture_cmd_output( 'parrot', [], $source, $input );
}

sub run_perlbrew_exec {
	my $self   = shift;
	my $params = shift;
	my $source = $params->{source};
	my $input  = $params->{input};
	$self->_capture_cmd_output( 'perlbrew', [ 'exec', 'perl' ],
		$source, $input );
}

# Taken from Padre::Plugin::PerlTidy
# TODO document it in 'SEE ALSO' POD section
sub perl_tidy {
	my $self   = shift;
	my $source = shift->{source};

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

	return \%result;
}

# i.e. Autocompletion
sub help_search {
	my $self = shift;
	my $topic = shift->{topic} // '';

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
		$self->app->log->info(
			"Finding all of *.pm and *.pod files in Perl search path");
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

	return \@help_results;
}

sub _module_pod {
	my $self     = shift;
	my $filename = shift;

	$self->app->log->info("Opening '$filename'");
	my $pod = '';
	if ( open my $fh, '<', $filename ) {
		$pod = do { local $/ = <$fh> };
		close $fh;
	}
	else {
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
		next if $path eq '.';    # Traversing this is a bad idea
		                         # as it may be the root of the file
		                         # system or the home directory
		foreach
		  my $file ( File::Find::Rule->name( '*.pm', '*.pod' )->in($path) )
		{
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
	my $source = $_[0]->{source} // '';
	my $style = $_[0]->{style} // '';

	my %stylesheets = (
    'cpan'=> [
        'assets/podstyle/orig/cpan.css',
        'assets/podstyle/cpan.css'
    ],
    'metacpan'=> [
        'assets/podstyle/orig/metacpan.css',
        'assets/podstyle/metacpan/shCore.css',
        'assets/podstyle/metacpan/shThemeDefault.css',
        'assets/podstyle/metacpan.css'
    ],
    'github'=> [
        'assets/podstyle/orig/github.css',
        'assets/podstyle/github.css'
    ],
    'none'=> []
	);

	my $html = _pod2html($source);
	my $t = '';
	for my $style (@{$stylesheets{$style}}) {
		$t .= qq{<link class="pod-stylesheet" rel="stylesheet" type="text/css" href="$style">\n};
	}
	$html =~ s{(</head>)}{</head>$t$1};
	say $t;

	return $html;
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
	my $source = shift->{source} // '';

	require Pod::Checker;
	require IO::String;

	my $checker = Pod::Checker->new;
	my $output  = '';
	$checker->parse_from_file( IO::String->new($source),
		IO::String->new($output) );

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

	return \@problems;
}

# Find a list of matched actions
sub find_action {
	my $self = shift;

	# Quote every special regex character
	my $query = quotemeta( shift->{action} // '' );

	# Find matched actions
	my @matches;
	for my $action_id ( keys %actions ) {
		my $action      = $actions{$action_id};
		my $action_name = $action->{name};
		if ( $action_name =~ /^.*$query.*$/i ) {
			push @matches,
			  {
				id   => $action_id,
				name => $action_name,
				help => $action->{help},
			  };
		}
	}

	# Sort so that shorter matches appear first
	@matches = sort { $a->{name} cmp $b->{name} } @matches;

	# And return matches array reference
	return \@matches;
}

# Find a list of matches files
sub find_file {
	my $self = shift;

	# Quote every special regex character
	my $query = quotemeta( shift->{filename} // '' );

	# Determine directory
	require Cwd;
	my $dir = $self->param('dir');
	if ( !$dir || $dir eq '' ) {
		$dir = Cwd::getcwd;
	}

	require File::Find::Rule;
	my $rule = File::Find::Rule->new;
	$rule->or(
		$rule->new->directory->name( 'CVS', '.svn', '.git', 'blib', '.build' )
		  ->prune->discard,
		$rule->new
	);

	$rule->file->name(qr/$query/i);
	my @files = $rule->in($dir);

	my @matches;
	for my $file (@files) {
		push @matches,
		  {
			id   => $file,
			name => path($file)->basename,
		  };
	}

	# Sort so that shorter matches appear first
	@matches = sort { $a->{name} cmp $b->{name} } @matches;

	my $MAX_RESULTS = 100;
	if ( scalar @files > $MAX_RESULTS ) {
		@matches = @matches[ 0 .. $MAX_RESULTS - 1 ];
	}

	# Return the matched file array reference
	return \@matches;
}

# Return the file contents or a failure string
sub open_file {
	my $self = shift;

	my $filename = shift->{filename} // '';

	my %result = ();
	if ( open my $fh, '<', $filename ) {

		# Slurp the file contents
		local $/ = undef;
		$result{value} = <$fh>;
		close $fh;

		# Retrieve editor mode
		$result{mode} = _find_editor_mode_from_filename($filename);

		# Simplify filename
		$result{filename} = path($filename)->basename;

		# Add or update record file record
		$self->_add_or_update_recent_file_record($filename);

		# We're ok :)
		$result{ok} = 1;
	}
	else {
		# Error!
		$result{value} = "Could not open file: $filename";
		$result{ok}    = 0;
	}

	# Return the file contents or the error message
	return \%result;
}

# Add or update record file record
sub _add_or_update_recent_file_record {
	my $self     = shift;
	my $filename = shift;

	require DBIx::Simple;
	my $db_name = $self->app->db_name;
	my $db      = DBIx::Simple->connect("dbi:SQLite:dbname=$db_name");

	my $sql = <<'SQL';
SELECT id, name, datetime(last_used,'localtime')
FROM recent_list
WHERE name = ? and type = 'file'
SQL

	my ( $id, $name, $last_used ) = $db->query( $sql, $filename )->list;

	if ( defined $id ) {

		# Found recent file record, update last used timestamp;
		$db->query(
			q{UPDATE recent_list SET last_used = datetime('now') WHERE id = ?},
			$id
		);

		$self->app->log->info("Update '$filename' in recent_list");
	}
	else {
		# Not found... Add new recent file record
		$sql = <<'SQL';
INSERT INTO recent_list(name, type, last_used)
VALUES(?, 'file', datetime('now'))
SQL
		$db->query( $sql, $filename );

		$self->app->log->info("Add '$filename' to recent_list");
	}

	$db->disconnect;
}

# Finds the editor mode from the filename
sub _find_editor_mode_from_filename {
	my $filename = shift;

	my $extension;
	if ( $filename =~ /\.([^.]+)$/ ) {

		# Extract file extension greedily
		$extension = $1;
	}

	my %extension_to_mode = (
		pl         => 'perl',
		pm         => 'perl',
		t          => 'perl',
		p6         => 'perl6',
		pm6        => 'perl6',
		pir        => 'pir',
		css        => 'css',
		js         => 'javascript',
		json       => 'javascript',
		html       => 'xml',
		ep         => 'xml',
		md         => 'markdown',
		markdown   => 'markdown',
		conf       => 'properties',
		properties => 'properties',
		ini        => 'properties',
		txt        => 'plain',
		'log'      => 'plain',
		yml        => 'yaml',
		yaml       => 'yaml',
		coffee     => 'coffeescript',
		diff       => 'diff',
		patch      => 'diff',
	);

	# No extension, let us use default text mode
	return 'plain' unless defined $extension;
	return $extension_to_mode{$extension};
}

# Generic REPL (Read-Eval-Print-Loop)
sub repl_eval {
	my $self       = shift;
	my $runtime_id = $_[0]->{runtime} // 'perl';
	my $command    = $_[0]->{command} // '';

	# The Result object
	my %result = (
		out => '',
		err => '',
	);

	# TODO make these configurable?
	my %runtimes = (
		'perl' => {

			# Special case that uses an internal inprocess Devel::REPL object
		},
		'rakudo' => {
			cmd    => 'perl6',
			prompt => '> \Z',
		},
		'niecza' => {
			cmd    => 'Niecza.exe',
			prompt => 'niecza> \Z',
		},
	);

	# The process that we're gonna REPL
	my $runtime = $runtimes{$runtime_id};

	# Handle the special case for Devel::REPL
	if ( $runtime_id eq 'perl' ) {
		return $self->_devel_repl_eval($command);
	}

	# Get the REPL prompt
	my $prompt = $runtime->{prompt};

	# If runtime is not defined, let us report it back
	unless ( defined $runtime ) {
		my %result = ( err => "Failed to find runtime '$runtime_id'", );

		# Return the REPL result
		return \%result;
	}

	# Prepare the REPL command....
	my @cmd = ( $runtime->{cmd} );

	# The input, output and error strings
	my ( $in, $out, $err );

	# Open process with a timeout
	#TODO timeout should be configurable...
	my $h = start \@cmd, \$in, \$out, \$err, timeout(5);

	# Send command to process and wait for prompt
	$in .= "$command\n";
	pump $h until $out =~ /$prompt/m;
	finish $h or $err = "@cmd returned $?";

	# Remove current REPL prompt
	$out =~ s/$prompt//;

	# Result...
	$result{out} = $out;
	$result{err} = $err;

	# Return the REPL result
	return \%result;
}

# Global shared object at the moment
# TODO should be stored in session
my $devel_repl;

# Devel::REPL (Perl)
sub _devel_repl_eval {
	my ( $self, $code ) = @_;

	# The Result object
	my %result = (
		out => '',
		err => '',
	);

	unless ($devel_repl) {

		# Try to load Devel::REPL
		eval { require Devel::REPL; };
		if ($@) {

			# The error
			$result{err} = 'Unable to find Devel::REPL';

			# Return the REPL result
			return \%result;
		}

		# Create the REPL object
		$devel_repl = Devel::REPL->new;

		# Provide Lexical environment for a Perl repl
		# Without this, it wont remember :)
		$devel_repl->load_plugin('LexEnv');
	}

	if ( $code eq '' ) {

		# Special case for empty input
		$result{out} = "\$\n";
	}
	else {
		my @ret = $devel_repl->eval("$code");

		if ( $devel_repl->is_error(@ret) ) {
			$result{err} = $devel_repl->format_error(@ret);
			$result{out} = "\$ $code";
		}
		else {
			$result{out} = "\$ $code\n@ret\n";
		}
	}

	# Return the REPL result
	return \%result;
}

# Save(s) the specified filename
sub save_file {
	my $self     = shift;
	my $filename = $_[0]->{filename};
	my $source   = $_[0]->{source};

	# Define output and error strings
	my %result = ( err => '', );

	# Check filename parameter
	unless ($filename) {

		# The error
		$result{err} = "filename parameter is invalid";

		# Return the result
		return \%result;
	}

	# Check contents parameter
	unless ($source) {

		# The error
		$result{err} = "source parameter is invalid";

		# Return the REPL result
		return \%result;
	}

	if ( open my $fh, ">", $filename ) {

		# Saving...
		print $fh $source;
		close $fh;
	}
	else {
		# Error: Cannot open the file for writing/saving
		$result{err} = "Cannot save $filename";
	}

	return \%result;
}

# Find duplicate Perl code in the current 'lib' folder
sub find_duplicate_perl_code {

	my $self = shift;
	my $dirs = shift->{dirs};

	my %result = (
		count  => 0,
		output => '',
		error  => '',
	);

	unless ($dirs) {

		# Return the error result
		$result{error} = "Error:\ndirs parameter is invalid";
		return \%result;
	}

	my @dirs;
	$dirs =~ s/^\s+|\s+$//g;
	if ( $dirs ne '' ) {

		# Extract search directories
		@dirs = split ',', $dirs;
	}

	my $cutnpaste;
	eval {
		# Create an cut-n-paste object
		require Code::CutNPaste;
		$cutnpaste = Code::CutNPaste->new(
			dirs         => [@dirs],
			renamed_vars => 1,
			renamed_subs => 1,
		);
	};
	if ($@) {

		# Return the error result
		$result{error} = "Code::CutNPaste validation error:\n" . $@;
		return \%result;
	}

	# Finds the duplicates
	my $duplicates = $cutnpaste->duplicates;

	# Construct the output
	my $output = '';
	foreach my $duplicate (@$duplicates) {
		my ( $left, $right ) = ( $duplicate->left, $duplicate->right );
		$output .=
		  sprintf <<'END', $left->file, $left->line, $right->file, $right->line;

	Possible duplicate code found
	Left:  %s line %d
	Right: %s line %d

END
		$output .= $duplicate->report;
	}

	# Returns the find duplicate perl code result
	$result{count}  = scalar @$duplicates;
	$result{output} = $output;
	return \%result;
}

# Dumps the PPI tree for the given source parameter
sub dump_ppi_tree {

	my $self   = shift;
	my $source = shift->{source};

	my %result = (
		output => '',
		error  => '',
	);

	# Make sure that the source parameter is not undefined
	unless ( defined $source ) {

		# Return the error JSON result
		$result{error} = "Error:\nSource parameter is undefined";
		return \%result;
	}

	# Load PPI at runtime
	require PPI;
	require PPI::Dumper;

	# Load a document
	my $module = PPI::Document->new( \$source );

	# No whitespace tokens
	$module->prune('PPI::Token::Whitespace');

	# Create the dumper
	my $dumper = PPI::Dumper->new($module);

	# Dump the document as a string
	$result{output} = $dumper->string;

	# Return the JSON result
	return \%result;
}

# Syntax check the provided source string
sub syntax_check {
	my $self   = shift;
	my $source = shift->{source};

	my $result = $self->_capture_cmd_output( "$^X", ["-c"], $source );

	require Parse::ErrorString::Perl;
	my $parser = Parse::ErrorString::Perl->new;
	my @errors = $parser->parse_string( $result->{stderr} );

	my @problems;
	foreach my $error (@errors) {
		push @problems,
		  {
			message => $error->message,
			file    => $error->file,
			line    => $error->line,
		  };
	}

	# Sort problems by line numerically
	@problems = sort { $a->{line} <=> $b->{line} } @problems;

	return \@problems;
}

# Create a project using Module::Starter
sub create_project {
	my $self = shift;
	my $opt  = shift;

	my %args = (
		distro       => $opt->{distro},
		modules      => $opt->{modules},
		dir          => $opt->{dir},
		builder      => $opt->{builder},
		license      => $opt->{license},
		author       => $opt->{author},
		email        => $opt->{email},
		ignores_type => $opt->{ignores_type},
		force        => $opt->{force},
	);

	Module::Starter->create_distro(%args);
}

## Step in code in debug mode
#sub debug_step_in {
#	my $self = shift;
#}

## Step over code in debug mode
#sub debug_step_over {
#	my $self = shift;
#}

## Step out code in debug mode
#sub debug_step_out {
#	my $self = shift;
#}

## Stop debugging
#sub debug_stop {
#	my $self = shift;
#}

# Show Git changes between commits
sub git_diff {
	my $self = shift;

	$self->_capture_cmd_output( 'git', ['diff'] );
}

sub perl_strip {
	my $self   = shift;
	my $source = shift->{source};

	my %result = (
		error  => 1,
		source => '',
	);

	# Check 'source' parameter
	unless ( defined $source ) {
		$self->app->log->warn('Undefined "source" parameter');
		return \%result;
	}

	eval {
		require Perl::Strip;
		my $ps  = Perl::Strip->new;
		$result{source} = $ps->strip($source);
	};

	return \%result;
}

sub spell_check {
	my $self = shift;
	my $source = shift->{source};
	
	my %results = (
		error => 1,
		source => '',
	);
	
	
}

# The default root handler
sub default {
	my $self = shift;

	# Stash the source parameter so it can be used inside the template
	$self->stash( source => scalar $self->param('source') );

	# Render template "editor/default.html.ep"
	$self->render;
}

# The websocket message handler
sub websocket {
	my $self = shift;

	# WebSocket Connected... Create JSON object...
	require Mojo::JSON;
	my $json = Mojo::JSON->new;

	# Disable inactivity timeout
	Mojo::IOLoop->stream( $self->tx->connection )->timeout(0);

	# Wait for a WebSocket message
	$self->on(
		message => sub {
			my ( $ws, $message ) = @_;
			my $result = $json->decode($message) or return;

			my $actions = {
				'dump-ppi-tree'            => 1,
				'find-action'              => 1,
				'find-file'                => 1,
				'open-file'                => 1,
				'run-perl'                 => 1,
				'run-rakudo'               => 1,
				'run-parrot'               => 1,
				'run-perlbrew-exec'        => 1,
				'help_search'              => 1,
				'perl-tidy'                => 1,
				'perl-critic'              => 1,
				'perl-strip'               => 1,
				'pod2html'                 => 1,
				'pod-check'                => 1,
				'save-file'                => 1,
				'syntax-check'             => 1,
				'spell-check'              => 1,
				'find-duplicate-perl-code' => 1,
				'repl-eval'                => 1,
				'new-project'              => 1,
#				'debug-step-in'            => 1,
#				'debug-step-over'          => 1,
#				'debug-step-out'           => 1,
#				'debug-stop'               => 1,
				'git-diff'                 => 1,
			};

			my $action = $result->{action} or return;
			$self->app->log->info("Processing '$action'");
			if ( defined $actions->{$action} ) {
				$action =~ s/-/_/g;
				my $o = $self->$action( $result->{params} ) or return;
				$ws->send( $json->encode($o) );
			}
			else {
				$self->app->log->warn("'$action' not found!");
			}

		}
	);
}

1;
