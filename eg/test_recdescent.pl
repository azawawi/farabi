use Parse::RecDescent;
use Modern::Perl;

$::RD_HINT = 1;
#$::RD_TRACE = 1;

my $grammar = q~
	start:
		statement(s /;/)
		{
			$return = join(";\n", @{$item[1]});
		}

	statement:
		expr |
		var_decl
		{
			$return = $item[1];
		}

	var_decl:
		'my' id '=' expr
		{
			$return = 'var ' . $item[2] . ' = ' . $item[4]
		}

	expr:
		sub_block

	sub_block:
		{
			$return = $item[1];
		}

	sub_block:
		'sub' param_list block
		{
			$return ='function' . $item[2] . $item[3];
			1;
		}

	param_list:
		'(' param(s /,/) ')'
		{
			$return = '(' . join(',', @{$item[2]}) . ')';
		}

	param:
		id
		{
			$return = $item[1];
			1;
		}

	id:
		/[\$]?\w+/
		{
			$return = $item[1];
		}

	block:
		"{" "}"
		{
			$return = " {\n}";
		}
~;

my $text = <<'END';
my $foo = sub($a,$b) {
};
my $bar = sub($a,$b) {
};
END

my $x = <<'EXPR';

$('#foo').on('click', function() {
	alert("Hello world");
});


-->

{#foo}->on "click", sub $p1, p2 {
	alert "Hello world";
};
EXPR


my $parser = new Parse::RecDescent($grammar) or die "Bad grammar!\n";
say "Input PerlJSCode";
say "-" x 40;
say $text;
say "-" x 40;
my $p = $parser->start($text);
if ( defined $p ) {
	say "Generated JS Code";
	say "-" x 40;
	say $p;
}
else {
	say "Bad text!";
}
