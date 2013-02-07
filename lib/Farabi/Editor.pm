package Farabi::Editor;

use Mojo::Base 'Mojolicious::Controller';
use Capture::Tiny qw(capture);
use IPC::Run qw( start pump finish timeout );

our $VERSION = '0.32';

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

	$self->render( json => \@results );
}

sub _capture_cmd_output {
	my $self   = shift;
	my $cmd    = shift;
	my $source = $self->param('source');

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

	my ( $stdout, $stderr, $exit ) = capture {
		system( $cmd, $tmp->filename );
	};
	my $result = {
		stdout => $stdout,
		stderr => $stderr,
		'exit' => $exit & 128,
	};

	$self->render( json => $result );
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

	return $self->render( json => \@problems );
}

# Find a list of matched actions
sub find_action {
	my $self = shift;

	# Quote every special regex character
	my $query = quotemeta( $self->param('action') // '' );

	# The actions
	my %actions = (
		'action-about' => {
			name => 'About Farabi',
			help => 'Opens an dialog about the current application',
		},
		'action-close-file' => {
			name => 'Close File',
			help => "Closes the current open file",
		},
		'action-close-all-files' => {
			name => 'Close All Files',
			help => "Closes all of the open files",
		},
		'action-dump-ppi-tree' => {
			name => 'Dump the PPI tree',
			help => "Dumps the PPI tree into the output pane",
		},
		'action-find-duplicate-perl-code' => {
			name => 'Find Duplicate Perl Code',
			help => 'Finds any duplicate perl code in the current lib folder',
		},
		'action-help' => {
			name => 'Help - Getting Started',
			help => 'A quick getting started help dialog',
		},
		'action-open-file' => {
			name => 'Open File(s)',
			help => "Opens one or more files in an editor tab",
		},
		'action-new-file' => {
			name => 'New File',
			help => "Opens a new file in an editor tab",
		},
		'action-options' => {
			name => 'Options',
			help => 'Open the options dialog',
		},
		'action-perl-tidy' => {
			name => 'Perl Tidy',
			help => 'Run the Perl::Tidy tool on the current editor tab',
		},
		'action-perl-critic' => {
			name => 'Perl Critic',
			help => 'Run the Perl::Critic tool on the current editor tab',
		},
		'action-plugin-manager' => {
			name => 'Plugin Manager',
			help => 'Opens the plugin manager',
		},
		'action-save-file' => {
			name => 'Save File',
			help => "Saves the current file ",
		},
		'action-syntax-check' => {
			name => 'Syntax Check',
			help => 'Run the syntax check tool on the current editor tab',
		},
		'action-perl-doc' => {
			name => 'Help - Perl Documentation',
			help => 'Opens the Perl help documentation dialog',
		},
		'action-repl' => {
			name => 'REPL - Read-Print-Eval-Loop',
			help => 'Opens the Read-Print-Eval-Loop dialog',
		},
		'action-run' => {
			name => 'Run',
			help => 'Run the current editor source file using the run dialog',
		},
	);

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

	# And return as JSON
	return $self->render( json => \@matches );
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

	require File::Basename;
	my @matches;
	for my $file (@files) {
		push @matches,
		  {
			id   => $file,
			name => File::Basename::basename($file),
		  };
	}

	# Sort so that shorter matches appear first
	@matches = sort { $a->{name} cmp $b->{name} } @matches;

	my $MAX_RESULTS = 100;
	if ( scalar @files > $MAX_RESULTS ) {
		@matches = @matches[ 0 .. $MAX_RESULTS - 1 ];
	}

	# And return as JSON
	return $self->render( json => \@matches );
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
		require File::Basename;
		$result{filename} = File::Basename::basename($filename);

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
	return $self->render( json => \%result );
}

# Add or update record file record
sub _add_or_update_recent_file_record {
	my $self     = shift;
	my $filename = shift;

	require DBIx::Simple;
	my $db = DBIx::Simple->connect('dbi:SQLite:dbname=farabi.db');

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

		say "Update '$filename' in recent_list";
	}
	else {
		# Not found... Add new recent file record
		$sql = <<'SQL';
INSERT INTO recent_list(name, type, last_used)
VALUES(?, 'file', datetime('now'))
SQL
		$db->query( $sql, $filename );

		say "Add '$filename' to recent_list";
	}

	$db->disconnect;
}

# Finds the editor mode from the the filename
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
		yml        => 'yaml',
		yaml       => 'yaml',
		coffee     => 'coffeescript'
	);

	# No extension, let us use default text mode
	return 'plain' if !defined $extension;
	return $extension_to_mode{$extension};
}

# Generic REPL (Read-Eval-Print-Loop)
sub repl_eval {
	my $self       = shift;
	my $runtime_id = $self->param('runtime') // 'perl';
	my $command    = $self->param('command') // '';

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
		return $self->render( json => \%result );
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
	return $self->render( json => \%result );
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
			return $self->render( json => \%result );
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
	return $self->render( json => \%result );
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

		# Return the REPL result
		return $self->render( json => \%result );
	}

	# Check contents parameter
	unless ($source) {

		# The error
		$result{err} = "source parameter is invalid";

		# Return the REPL result
		return $self->render( json => \%result );
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

	return $self->render( json => \%result );
}

# Find duplicate Perl code in the current 'lib' folder
sub find_duplicate_perl_code {

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
		return $self->render( json => \%result );
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
		return $self->render( json => \%result );
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
	return $self->render( json => \%result );
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
		return $self->render( json => \%result );
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
	return $self->render( json => \%result );
}

# Find all Farabi plugins
sub find_plugins {
	my $self = shift;

	# Create a non-instantiating plugin finder object
	require Module::Pluggable::Object;
	my $finder = Module::Pluggable::Object->new(
		search_path => 'Farabi::Plugin',
		require     => 1,
		inner       => 0,
	);

	# Find all plugins
	my @plugins;
	for my $plugin ( $finder->plugins ) {
		my $o;
		eval { require $plugin; $o = $plugin->new; };
		if ($@) {
			push @plugins,
			  {
				id     => $plugin,
				name   => $plugin,
				status => 'Plugin creation failure',
			  };

			# No need to process anymore
			next;
		}

		unless ( defined $o ) {
			push @plugins,
			  {
				id     => $plugin,
				name   => $plugin,
				status => 'Plugin creation failure',
			  };

			# No need to process anymore
			next;
		}

		if ( $o->can('name') ) {

			# 'name' is supported
			push @plugins,
			  {
				id     => $plugin,
				name   => $o->name,
				status => '',
			  };

		}
		else {
			# No 'name' support
			push @plugins,
			  {
				id     => $plugin,
				name   => '',
				status => q{Does not support 'name'!},
			  };

			# No need to process anymore
			next;
		}

		if ( $o->can('deps') ) {

			my $status = '';

			my $deps = $o->deps;
			for my $name ( keys %$deps ) {
				my $version = $deps->{$name};

				# Validate module dependency rule
				eval "require $name $version";
				if ($@) {

					# Dependency rule not met
					$status .= "'$name' $version or later not found\n";
				}

			}

			# deps is supported
			push @plugins,
			  {
				id     => $plugin,
				name   => $deps,
				status => $status,
			  };
		}
		else {
			# No deps support
			push @plugins,
			  {
				id     => $plugin,
				name   => '',
				status => q{Does not support 'deps'!},
			  };
		}

	}

	# Return the JSON result
	return $self->render( json => \@plugins );
}

# The default root handler
sub default {
	my $self = shift;

	# Stash the source parameter so it can be used inside the template
	$self->stash( source => scalar $self->param('source') );

	# Render template "editor/default.html.ep"
	$self->render;
}

1;

__END__

=pod

=head1 NAME

Farabi::Editor - Action Controller

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2013 by Ahmad M. Zawawi

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
