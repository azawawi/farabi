#!/usr/bin/env perl 
use Modern::Perl;
use Mojolicious::Lite;
use Mojo::IOLoop ();
use Scalar::Util ();

my @results;

get '/' => sub {
    my $self = shift;

    my $html;
    if ( scalar @results > 0 ) {
        $html = 'Most recent results calculated results:<table border="1">';
        for my $result ( reverse @results ) {
            $html .=
                '<tr><td>'
              . $result->[0]
              . '</td><td>'
              . $result->[1]
              . '</td></tr>';
        }
        $html .= '</table>';
    }
    else {
        $html = '';
    }

    $self->render( text => <<HTML);
<form action="/calc">
	<label for="name">Number:</label>
	<input type="text" id="num" name="num"></input>
	<input type="submit" value="Calculate square root"></input>
</form>
$html
HTML
};

get '/calc' => sub {
    my $self = shift;
    my $num  = $self->param('num');

    unless ( Scalar::Util::looks_like_number($num) ) {
        return "Please enter a valid number";
    }

    Mojo::IOLoop->timer(
        0 => sub {

            # Calculate square of a number or do your expensive operation here
            my $result = [ $num, $num * $num ];
            push @results, $result;
        }
    );

    $self->render( text => <<HTML);
Thanks for entering <strong>$num</strong>. 
<p>
Please click <a href="/">here</a> to return to the previous form.|
</p>
HTML
};

app->start;
