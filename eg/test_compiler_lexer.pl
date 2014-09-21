use Modern::Perl;
use Compiler::Lexer;
use Data::Printer;
use File::Find::Rule;
use Path::Tiny;

my @files = File::Find::Rule->file()->name('*.pm')->in(@INC);

#@files = ('~/farabi/eg/helloworld.pl');
#@files = ('~/farabi/lib/Farabi.pm');

warn "Parsing " . scalar @files . " .pm file(s)";

for my $file_name (@files) {
	my $script = path($file_name)->slurp;
	my $tokens = Compiler::Lexer->new->tokenize($script);

	my $i      = 0;
	my @tokens = @$tokens;
	if ( scalar @tokens == 0 ) {
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
			my $line;
			while ( $tokens[$j]->name ne 'SemiColon' ) {
				$pkg_name .= $tokens[$j]->data;
				$line = $tokens[$j]->line;
				$j++;
			}
			$current_pkg = $pkg_name;

			say "--- $pkg_name at line #${line}";
		}
		elsif ( $token->name eq 'FunctionDecl' ) {

			# sub foo { }
			my $j = $i + 1;
			if ( $tokens[$j]->name eq 'Function' ) {
				my $sub_name = $tokens[$j]->data;
				say "$current_pkg::$sub_name at line #" . $tokens[$j]->line;
			}
		}
		elsif ( $token->name eq 'Key'
			and ( $token->data eq 'func' or $token->data eq 'method' ) )
		{
			# Support Method::Signatures
			# func|method foo { }
			my $j = $i + 1;
			if ( $tokens[$j]->name eq 'Key' ) {
				my $sub_name = $tokens[$j]->data;
				say "$current_pkg::$sub_name at line #" . $tokens[$j]->line;
			}

		}

		#p $token;
		$i++;
	} while ( $i < scalar @tokens );

	say path($file_name)->basename;
}

