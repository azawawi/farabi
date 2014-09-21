use Modern::Perl;
use Compiler::Lexer;
use Data::Printer;
use File::Find::Rule;
use Path::Tiny;

my @files = File::Find::Rule->file()
	->name( '*.pm' )
    ->in( @INC );

#my @files = ('~/farabi/eg/helloworld.pl');

for my $file_name (@files) {
	my $script = path($file_name)->slurp;
	my $tokens = Compiler::Lexer->new->tokenize($script);

	my $i           = 0;
	my @tokens      = @$tokens;
	if(scalar @tokens == 0) {
		say "file: $file_name has no tokens";
		next;
	}

	my $current_pkg = 'main';
	do {
		my $token = $tokens[$i];
		if ( $token->name eq 'Package' ) {

			# package Foo::Bar;

			my $j        = $i + 1;
			my $pkg_name = '';
			while ($tokens[$j]->name eq 'Namespace'
				or $tokens[$j]->name eq 'NamespaceResolver' )
			{
				$pkg_name .= $tokens[$j]->data;
				$j++;
			}
			$current_pkg = $pkg_name;

			say "--- $pkg_name";
		}
		elsif ( $token->name eq 'FunctionDecl' ) {

			# sub foo { }
			my $j = $i + 1;
			if ( $tokens[ $j ]->name eq 'Function' ) {
				my $sub_name = $tokens[$j]->data;
				say
				  "$current_pkg::$sub_name";
			}
		}

		#p $token;
		$i++;
	} while ( $i < scalar @tokens );

	say path($file_name)->basename;
}

