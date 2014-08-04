use Modern::Perl;

#use String::InterpolatedVariables;
use PPI;
use Data::Printer;
use Method::Signatures;

my $code = <<'CODE';
use Modern::Perl;
say "Hello world";
my $double_quote =            "$bar";
my $literal = "$baz";
my $qq_quote =           qq/$foo 

$bar \$bar/;
CODE

# Load a document
my $doc = PPI::Document->new( \$code );

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
        )
/x;

func extract ($ppi_quote) {

	return
	  unless $ppi_quote->isa('PPI::Token::Quote::Double')
	  || $ppi_quote->isa('PPI::Token::Quote::Interpolate');

	my $string = $ppi_quote->content;

	my $variables = [];
	my $line       = $ppi_quote->line_number;
	my $col       = $ppi_quote->column_number;
	while ( $string =~ /$VARIABLES_REGEX/g ) {
		push( @$variables,
			( name => $1, column_number => $col + $-[0], line_number => $line )
		);
	}

	return $variables;
}

for my $string (@$strings) {

	#my $variables = String::InterpolatedVariables::extract( $string->content );
	my $variables = extract($string);
	next if ( scalar @$variables == 0 );
	say "-" x 72;
	say "String "
	  . $string->content
	  . " contains the following variables: \n@$variables";
}


