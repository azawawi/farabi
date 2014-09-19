package JSCode;
use namespace::autoclean;
use Moose;
use Method::Signatures;

has 'buffer' => ( is => 'rw', isa => 'Str', default => '' );
has 'indent' => ( is => 'rw', isa => 'Str', default => '' );

method emit ($str) {
	$self->buffer( $self->buffer . $str );
}

method emit_newline {
	$self->emit(";\n") if length $self->buffer > 0;
}

method query ($selector) {
	my $indent = $self->indent;
	$self->emit_newline;
	$self->emit(qq{${indent}\$("$selector")});

	$self;
}

method css ($name, $value) {
	$self->emit(qq{.css("$name", "$value")});

	$self;
}

method on ($event_name, $event_handler) {
	my $handler = JSCode->new( indent => $self->indent . ' ' x 4 );
	&$event_handler($handler);
	my $code = $handler->to_string;

	my $indent = $self->indent;
	$self->emit(<<JS);
.on("$event_name", function() {
$indent$code
});
JS

	$self;
}

method custom ($code) {
	my $indent = $self->indent;
	$self->emit_newline;
	$self->emit($code);

	$self
}

method alert ($message) {
	my $indent = $self->indent;
	$self->emit_newline;
	$self->emit(qq{${indent}alert("$message");});

	$self;
}

method to_string {
	$self->buffer;
}

no Moose;

1;

#-------------------------------------------------------------------

package main;
use JSCode;
use Modern::Perl;

my $p = JSCode->new;

$p->query('#foo')->css( 'border', '1px solid red' );
$p->on(
	'click',
	sub {
		my $click = shift;
		$click->query('#foo')->css( 'border', '1px solid blue' );
		$click->query('#foo')->css( 'border', '1px solid blue' );
		$click->alert('You clicked me :)');
	}
);

my $code = $p->to_string;

say "code:\n$code";

# TODO stash it in the template!

