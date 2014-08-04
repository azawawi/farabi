use v5.18;
use String::InterpolatedVariables;
use Data::Printer;

my $code = <<'CODE';
use Modern::Perl;
say "Hello world";
my $double_quote = "$bar";
my $literal = "$bar";
my $qq_quote = qq/$foo $bar \$bar/;
CODE

# Load PPI at runtime
require PPI;
require PPI::Dumper;

# Load a document
my $doc = PPI::Document->new( \$code );

# No whitespace tokens
$doc->prune('PPI::Token::Whitespace');

# Find all can-be-interpolated strings
my $strings = $doc->find(
	sub {
		$_[1]->isa('PPI::Token::Quote::Double')
		  || $_[1]->isa('PPI::Token::Quote::Interpolate ');
	}
);
for my $string (@$strings) {

	#p $string;
	my $variables = String::InterpolatedVariables::extract( $string->content );
	next if ( scalar @$variables == 0 );
	say "-" x 72;
	say "String "
	  . $string->content
	  . " contains the following variables: \n@$variables";
}

#p $result;

#my $variables = String::InterpolatedVariables::extract(
#	'A $test->{string} $foo $bar from a PPI::Token::Quote::Double $object.');
#p $variables;

