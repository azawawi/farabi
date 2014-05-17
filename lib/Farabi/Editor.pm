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
my $build_menu   = '03.Build';
my $tools_menu = '04.Tools';
my $help_menu  = '05.Help';

my %actions = (
	'action-new-file' => {
		name  => 'New File - Alt+N',
		help  => "Opens a new file in an editor tab",
		menu  => $file_menu,
		order => 1,
	},

#	'action-new-project' => {
#		name  => 'New Project',
#		help  => "Creates a new project using Module::Starter",
#		menu  => $file_menu,
#		order => 2,
#	},
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
	'action-repl' => {
		name  => 'REPL - Read-Print-Eval-Loop',
		help  => 'Opens the Read-Print-Eval-Loop dialog',
		menu  => $tools_menu,
		order => 9,
	},
	'action-run' => {
		name  => 'Run - Alt+Enter',
		help  => 'Run the current editor source file using the run dialog',
		menu  => $build_menu,
		order => 5,
	},
	'action-help' => {
		name  => 'Getting Started',
		help  => 'A quick getting started help dialog',
		menu  => $help_menu,
		order => 1,
	},
#	'action-perl-doc' => {
#		name  => 'Perl Documentation',
#		help  => 'Opens the Perl help documentation dialog',
#		menu  => $help_menu,
#		order => 2,
#	},
	'action-about' => {
		name  => 'About Farabi',
		help  => 'Opens an dialog about the current application',
		menu  => $help_menu,
		order => 3,
	},
);

sub menus {
	my $self = shift;
	my $menus = ();

	if($self->app->support_can_be_enabled('Perl::Critic')) {
		$actions{'action-perl-critic'} = {
			name  => 'Perl Critic',
			help  => 'Run the Perl::Critic tool on the current editor tab',
			menu  => $tools_menu,
			order => 4,
		};
		$actions{'action-dump-ppi-tree'} = {
			name  => 'Dump the PPI tree',
			help  => "Dumps the PPI tree into the output pane",
			menu  => $tools_menu,
			order => 11,
		};
	};

	if($self->app->support_can_be_enabled('Perl::Tidy')) {
		$actions{'action-perl-tidy'} = {
			name  => 'Perl Tidy',
			help  => 'Run the Perl::Tidy tool on the current editor tab',
			menu  => $tools_menu,
			order => 3,
		};
	};

	if($self->app->support_can_be_enabled('Perl::Strip')) {
		$actions{'action-perl-strip'} = {
			name  => 'Perl Strip',
			help  => 'Run Perl::Strip on the current editor tab',
			menu  => $tools_menu,
			order => 5,
		};
	};

	if($self->app->support_can_be_enabled('Spellunker')) {
		$actions{'action-spellunker'} = {
			name  => 'Spellunker',
			help  => "Checks current tab spelling using Spellunker",
			menu  => $tools_menu,
			order => 10,
		};
	};

	if($self->app->support_can_be_enabled('Code::CutNPaste')) {
		$actions{'action-code-cutnpaste'} = {
			name  => 'Find Cut and Paste code...',
			help  => 'Finds any duplicate Perl code in the current lib folder',
			menu  => $tools_menu,
			order => 7,
		};
	};

	if($self->app->support_can_be_enabled('App::Midgen')) {
		$actions{'action-midgen'} = {
			name  => 'Find package dependencies (midgen)',
			help  => 'Find package dependencies in the current lib folder and outputs a sample Makefile DSL',
			menu  => $tools_menu,
			order => 7,
		};
	};

	if($self->app->support_can_be_enabled('Minilla')) {
		$actions{'action-minil-test'} = {
			name  => 'minil test',
			help  => "Runs 'minil test' on the current project",
			menu  => $build_menu,
			order => 2,
		};
	};

	if($self->app->support_can_be_enabled('Dist::Zilla')) {
		$actions{'action-dzil-test'} = {
			name  => 'dzil test',
			help  => "Runs 'dzil test' on the current project",
			menu  => $build_menu,
			order => 2,
		};
	};

	require File::Which;
	if(defined File::Which::which('jshint')) {
		$actions{'action-jshint'} = {
			name  => 'JSHint',
			help  => 'Run JSHint on the current editor tab',
			menu  => $tools_menu,
			order => 6,
		};
	}
	
	if(defined File::Which::which('git')) {
		$actions{'action-git-diff'} = {
			name  => 'Git Diff',
			help  => 'Show Git changes between commits',
			menu  => $tools_menu,
			order => 8,
		};
	}

	if(defined File::Which::which('ack')) {
		$actions{'action-ack'} = {
			name  => 'Find in files (ack)',
			help  => 'Find the current selected text using Ack and displays results in the search tab',
			menu  => $tools_menu,
			order => 2,
		};
	}

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

	$self->render(json => \@results);
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
	my $source = $self->param('source');
	my $input  = $self->param('input');

	my $o = $self->_capture_cmd_output( $^X, [], $source, $input );

	$self->render(json => $o);
}


sub run_perlbrew_exec {
	my $self   = shift;
	my $source = $self->param('source');
	my $input  = $self->param('input');

	my $o = $self->_capture_cmd_output( 'perlbrew', [ 'exec', 'perl' ],
		$source, $input );

	$self->render(json => $o);
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

	$self->render(json => \%result);
}

# i.e. Autocompletion
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

	$self->render(json => \@help_results);
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
	my $source =$self->param('source') // '';
	my $style = $self->param('style') // 'metacpan';

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
	$self->render(text => $html, format => 'html');
}

sub _pod2html {
	my $pod = shift;

	require Pod::Simple::HTML;
	my $psx = Pod::Simple::HTML->new;
	#$psx->no_errata_section(1);
	#$psx->no_whining(1);
	$psx->output_string( \my $html );
	$psx->parse_string_document($pod);

	return $html;
}

sub md2html {
	my $self = shift;
	my $text = $self->param('text') // '';

	require Text::Markdown;
	my $m = Text::Markdown->new;
	my $html = $m->markdown($text);

	$self->render(text => $html);
}

# Code borrowed from Padre::Plugin::Experimento - written by me :)
sub pod_check {
	my $self = shift;
	my $source = $self->param('source') // '';

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

	$self->render(json => \@problems);
}

# Find a list of matched actions
sub find_action {
	my $self = shift;

	# Quote every special regex character
	my $query = quotemeta( $self->param('action') // '' );

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
	$self->render(json => \@matches);
}

# Find a list of matches files
sub find_file {
	my $self = shift;

	# Quote every special regex character
	my $query = quotemeta( $self->param('filename') // '' );

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
	$self->render(json => \@matches);
}

# Return the file contents or a failure string
sub open_file {
	my $self = shift;

	my $filename = $self->param('filename') // '';

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
	$self->render(json => \%result);
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
		txt        => 'null',
		'log'      => 'null',
		yml        => 'yaml',
		yaml       => 'yaml',
		coffee     => 'coffeescript',
		diff       => 'diff',
		patch      => 'diff',
	);

	# No extension, let us use default text mode
	return 'null' unless defined $extension;
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
		$self->render(json => \%result);
		return;
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
	$self->render(json => \%result);
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
			$self->render(json => \%result);
			return;
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
	$self->render(json => \%result);
}

# Save(s) the specified filename
sub save_file {
	my $self     = shift;
	my $filename = $self->param('filename');
	my $source   = $self->param('source');

	# Define output and error strings
	my %result = ( err => '', );

	# Check filename parameter
	unless ($filename) {

		# The error
		$result{err} = "filename parameter is invalid";

		# Return the result
		$self->render(json => \%result);
		return;
	}

	# Check contents parameter
	unless ($source) {

		# The error
		$result{err} = "source parameter is invalid";

		# Return the REPL result
		$self->render(json => \%result);
		return;
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

	$self->render(json => \%result);
}

# Find duplicate Perl code in the current 'lib' folder
sub code_cutnpaste {

	my $self = shift;
	my $dirs = $self->param('dirs');

	my %result = (
		count  => 0,
		output => '',
		error  => '',
	);

	unless ($dirs) {

		# Return the error result
		$result{error} = "Error:\ndirs parameter is invalid";
		$self->render(json => \%result);
		return;
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
		$self->render(json => \%result);
		return;
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

	$self->render(json => \%result);
}

# Dumps the PPI tree for the given source parameter
sub dump_ppi_tree {

	my $self   = shift;
	my $source = $self->param('source');

	my %result = (
		output => '',
		error  => '',
	);

	# Make sure that the source parameter is not undefined
	unless ( defined $source ) {

		# Return the error JSON result
		$result{error} = "Error:\nSource parameter is undefined";
		$self->render(json => \%result);
		return;
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
	$self->render(json => \%result);
}

# Syntax check the provided source string
sub syntax_check {
	my $self   = shift;
	my $source = $self->param('source');

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

	$self->render(json => \@problems);
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

# Show Git changes between commits
sub git_diff {
	my $self = shift;

	my $o = $self->_capture_cmd_output( 'git', ['diff'] );

	$self->render(json => $o);
}

# Search files in your current project folder for a textual pattern
sub ack {
	my $self = shift;
	my $text = $self->param('text');

	#TODO needs more thought on how to secure it again --xyz-command or escaping...
	# WARNING at the moment this is not secure
	my $o = $self->_capture_cmd_output( 'ack', [q{--literal}, q{--sort-files}, q{--match}, qq{$text}] );

	$self->render(json => $o);
}

# Check requires & test_requires of your package for CPAN inclusion.
sub midgen {
	my $self = shift;

	my $o = $self->_capture_cmd_output( 'midgen', [] );

	# Remove ansi color sequences
	$o->{stdout} =~ s/\e\[[\d;]*[a-zA-Z]//g;
	$o->{stderr} =~ s/\e\[[\d;]*[a-zA-Z]//g;

	$self->render(json => $o);
}


# Runs 'minil test' in the current project folder
sub minil_test {
	my $self = shift;

	my $o = $self->_capture_cmd_output( 'minil', ['test'] );

	$self->render(json => $o);
}

# Runs 'dzil test' in the current project folder
sub dzil_test {
	my $self = shift;

	my $o = $self->_capture_cmd_output( 'dzil', ['test'] );

	$self->render(json => $o);
}


sub perl_strip {
	my $self   = shift;
	my $source = $self->param('source');

	my %result = (
		error  => 1,
		source => '',
	);

	# Check 'source' parameter
	unless ( defined $source ) {
		$self->app->log->warn('Undefined "source" parameter');
		$self->render(json => \%result);
		return;
	}

	eval {
		require Perl::Strip;
		my $ps  = Perl::Strip->new;
		$result{source} = $ps->strip($source);
	};

	$self->render(json => \%result);
}

sub spellunker {
	my $self = shift;
	my $text = $self->param('text');

	require Spellunker::Pod;
	my $spellunker = Spellunker::Pod->new();
	my @t = $spellunker->check_text($text);

	$self->render(json => \@t);
}

# The default root handler
sub default {
	my $self = shift;

	# Stash the source parameter so it can be used inside the template
	$self->stash( source => scalar $self->param('source') );

	# Render template "editor/default.html.ep"
	$self->render;
}

sub ping {
	$_[0]->render(text => "pong");
}

1;
