use strict;
use warnings;

use Test::More;

BEGIN {

	# Don't run tests for installs
	unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
		plan( skip_all => "Author tests not required for installation" );
	}

}

use Test::EOL;
use File::Find::Rule;

my @files =
	File::Find::Rule->file->name( '*.pm', '*.pod', '*.pl', '*.t', '*.ep', '*.js', '*.css' )->in( 'lib', 't' );
@files = ( @files, 'README.md', 'CREDITS.md', 'TODO', 'MANIFEST.SKIP', 'LICENSE', 'Changes' );
plan( tests => scalar @files );
foreach my $file (@files) {
	eol_unix_ok( $file, "$file is ^M free" );
}
