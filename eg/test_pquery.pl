
package PQuery;
use Moo;
use namespace::clean;
use Modern::Perl;
use Method::Signatures;

has buffer => (
	is      => 'rw',
	default => '',
);

method select ($selector) {
	my $buffer = $self->buffer . qq{\$("$selector")};
	$self->buffer($buffer);

	$self;
}

method css ($name, $value) {
	my $buffer = $self->buffer;

	$buffer .= '.' if ( length $buffer > 0 );
	$buffer .= qq{css("$name", "value")};
	$self->buffer($buffer);

	$self;
}

method add_class ($class_name) {
	my $buffer = $self->buffer;

	$buffer .= '.' if ( length $buffer > 0 );
	$buffer .= qq{addClass("$class_name")};
	$self->buffer($buffer);

	$self;
}

method on ($event_name, $callback) {
	my $buffer = $self->buffer;

	$buffer .= '.' if ( length $buffer > 0 );
	$buffer .= qq!on("$event_name", function() {"!;
	$buffer .= qq!}!;
	$self->buffer($buffer);

	$self;
}

method function {
	$self;
}

package main;

say PQuery->new->select('#id')->css( 'background-color', 'blue' )
  ->add_class('hide')->buffer;
say PQuery->new->select("#foo")->on( 'click', PQuery->function )->buffer;
