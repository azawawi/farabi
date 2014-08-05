use Modern::Perl;

#use String::InterpolatedVariables;
use PPI;
use Data::Printer;
use Method::Signatures;

my $code = <<'CODE';
qq/$foo 
$bar 

$baz/;
#say "Hello world";
#my $double_quote =            "$bar";
#my $literal = "$baz";
CODE

# Load a document
my $doc = PPI::Document->new( \$code );
$doc->index_locations;

# Find all can-be-interpolated strings
my $strings = $doc->find(
	sub {
		$_[1]->isa('PPI::Token::Quote::Double')
		  || $_[1]->isa('PPI::Token::Quote::Interpolate');
	}
);

my $VARIABLES_REGEX = qr/
        # Ignore escaped sigils, since those wouldn't get interpreted as variables to interpolate.
        (?<!\\)
        # Allow literal, non-escapy backslashes.
        (?:\\\\)*
        (
                # The variable needs to start with a sigil.
                [\$\@]
                # Account for the dereferencing, such as "$$" or "@$".
                \$?
                # Variable name.
                (?:
                        # Note: include '::' to support package variables here.
                        \{(?:\w+|::)\} # Explicit {variable} name.
                        |
                        (?:\w|::)+     # Variable name.
                )
                # Catch nested data structures.
                (?:
                        # Allow for a dereferencing ->.
                        (?:->)?
                        # Can be followed by either a hash or an array.
                        (?:
                                \{(?:\w+|'[^']+'|"[^"]+")\}  # Hash element.
                                |
                                \[['"]?\d+['"]?\]            # Array element.
                        )
                )*
                # For counting line numbers
                |\n
        )
/x;

func extract_interp_vars ($ppi_quote) {

	return
	  unless $ppi_quote->isa('PPI::Token::Quote::Double')
	  || $ppi_quote->isa('PPI::Token::Quote::Interpolate');

	my $string = $ppi_quote->string;

	my $variables = [];
	my $line      = $ppi_quote->line_number;
	my $col       = $ppi_quote->column_number;
	say "col: $col";
	my $line_col = 0;
	while ( $string =~ /$VARIABLES_REGEX/g ) {
		if ( $1 eq "\n" ) {

			# Count line numbers
			$line++;
			$line_col = $-[0];
		}
		else {
			push(
				@$variables,
				{
					name          => $1,
					column_number => $col + $-[0] - $line_col,
					line_number   => $line
				}
			);
		}

	}

	return $variables;
}

for my $string (@$strings) {

	p $string->string;
	my $variables = extract_interp_vars($string);
	next if ( scalar @$variables == 0 );
	say "-" x 72;
	say "String \n" . $string->string . "\n contains the following variables:";
	for my $var (@$variables) {
		p( $var, output => 'stdout' );
	}
}

