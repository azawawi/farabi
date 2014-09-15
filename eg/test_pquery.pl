
package PJQ;
use namespace::autoclean;
use Moose;
use Method::Signatures;

has selector => (
	is      => 'rw',
	isa     => 'Str',
	default => '',
);

has buffer => (
	is      => 'rw',
	isa     => 'Str',
	default => '',
);

func PJQE {
	return 'PJQ'->new(@_);
}

#func BUILDARGS {
#	my ( $class, @args ) = @_;

#	unshift @args, "selector" if @args % 2 == 1;
#
#return {@args};
#}

method BUILD ($p) {
	my $selector = $self->selector;
	my $buffer   = $self->buffer . qq{\$("$selector")};
	$self->buffer($buffer);

	$self;
}

method css ($name, $value) {
	my $buffer = $self->buffer;

	$buffer .= '.' if ( length $buffer > 0 );
	$buffer .= qq{css("$name", "$value")};
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
	$buffer .= qq!on("$event_name", function() {!;
	$buffer .= qq!});!;
	$self->buffer($buffer);

	$self;
}

method function {
	$self;
}

package main;

use Modern::Perl;

say PJQ->new( selector => '#id' )->css( 'background-color', 'blue' )
  ->add_class('hide')->buffer;
say PJQ->new( selector => "#foo" )->on( 'click', PJQ->function )->buffer;

my $JSCODE .= <<END
	$('#id').css('background-color', 'red');
END
