use Modern::Perl;

use PPI ();
use Data::Printer;
use Method::Signatures;

my $code = <<'CODE';
print "@{[$a + 1]}";
    qq/$foo $bar 
 $baz/;
#say "Hello world";
my $double_quote =            "$bar";
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

my $INTERP_EXPR_REGEX = qr/\@\{\[ .+? \]\}/x;

# Courtesy of String::InterpolatedVariables::VARIABLES_REGEX by Guillaume Aubert
# and modified to include line number tracking
my $INTERP_VAR_REGEX = qr/
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
                # Support expression interpolation @{[ expr ]}
                | $INTERP_EXPR_REGEX
                # For counting line numbers
                | \n
        )

/x;

func parse_interp_exprs ($quote) {

	return
	  unless $quote->isa('PPI::Token::Quote::Double')
	  || $quote->isa('PPI::Token::Quote::Interpolate');

	my $exprs    = [];
	my $line     = $quote->line_number;
	my $col      = $quote->column_number;
	my $line_col = 0;
	my $string = $quote->content;
	while ( $string =~ /$INTERP_VAR_REGEX/g ) {
		if ( $1 eq "\n" ) {

			# Count line numbers
			$line++;

			# Store current line column index
			$line_col = $+[0];

			# Reset column to one
			$col = 1;
		}
		else {
			push(
				@$exprs,
				{
					# Interpolated expression takes precedence
					string        => $1,
					column_number => $col + $-[0] - $line_col,
					line_number   => $line
				}
			);
		}

	}

	return $exprs;
}

for my $string (@$strings) {

	p $string->content;
	my $exprs = parse_interp_exprs($string);
	next if ( scalar @$exprs == 0 );
	say "-" x 72;
	say "String \n"
	  . $string->content
	  . "\n contains the following interpolated expressions:";
	for my $var (@$exprs) {
		p( $var, output => 'stdout' );
	}
}

