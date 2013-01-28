use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	# Package information
	NAME          => 'Farabi',
	VERSION_FROM  => 'lib/Farabi.pm',
	ABSTRACT_FROM => 'lib/Farabi.pm',
	AUTHOR        => 'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>',
	
	# Dependencies
	PREREQ_PM     => {
		'Capture::Tiny'    => '0.21',
		'Code::CutNPaste'  => '0.04',
		'Debug::Client'    => '0.20',
		'File::Find::Rule' => '0.33',
		'File::Which'      => '1.09',
		'IO::String'       => '1.08',
		'IPC::Run'         => '0.92',
		'MediaWiki::API'   => '0.39',
		'Module::Pluggable' => '4.5',
		'Mojolicious'      => '3.36',
		'Perl::Critic'     => '1.118',
		'Perl::Tidy'       => '20120714',
		'Pod::Index'       => '0.14',
		'Pod::Parser'      => '1.51',

		# For testing
		'Test::More' => '0.98',
		'Test::EOL'  => '1.5',
	},

	# Farabi executable
	EXE_FILES  => ['bin/farabi'],

	# Tests
	test       => { TESTS => 't/*.t xt/*.t' },

	# META.yml metadata
	META_MERGE => {
		requires => { perl => '5.010001' },
		no_index => {
			directory => [ 'xt', 'lib/Farabi/files'],
		},
		resources => {
			license    => 'http://dev.perl.org/licenses',
			homepage   => 'https://github.com/azawawi/farabi',
			bugtracker => 'https://github.com/azawawi/farabi/issues',
			repository => 'git://github.com/azawawi/farabi.git',
		},
	},
);
