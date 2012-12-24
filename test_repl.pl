
use Modern::Perl;
use IPC::Run qw( start pump finish timeout );

my $runtime_id = 'niecza';
my $command = '10 + 10';

# TODO make these configurable?
my %runtimes = (
	'perl' => {
		cmd => 're.pl',
		prompt => '$\Z',
	},
	'rakudo' => {
		cmd => 'perl6',
		prompt => '> \Z',
	},
	'niecza' => {
		cmd => 'Niecza.exe',
		prompt => 'niecza>  \Z',
	},
);

# The process that we're gonna REPL
my $runtime = $runtimes{$runtime_id};
my $prompt = $runtime->{prompt};

# If runtime is not defined, let us report it back
unless(defined $runtime) {
	my %result = (
		ok  => 0,
		err => "Failed to find runtime '$runtime_id'",
	);
	# Return the REPL result
	use Data::Printer;
	p(%result);
	return;
}

# Prepare the REPL command....
my @cmd = ( $runtime->{cmd} );

# The input, output and error strings
my ($in, $out, $err);

# Open process with a timeout
#TODO timeout should be configurable...
my $h = start \@cmd, \$in, \$out, \$err, timeout( 10 );

# Send command to process and wait for prompt
$in .= "$command\n";
pump $h until $out =~ /$prompt/m;
finish $h or $err = "@cmd returned $?";

say "'$out'";

# Remove current REPL prompt
$out =~ s/$prompt//;

# Result...
my %result = (
    ok  => 1,
	out => $out,
	err  => $err,
);

use Data::Printer;
p(%result);
