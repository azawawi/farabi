#!/usr/bin/env perl
use Modern::Perl;
use AnyEvent       ();
use AnyEvent::Loop ();
use Dancer ':syntax';
use Scalar::Util   ();
use Twiggy::Server ();

my %timers;
my @results;

get '/' => sub {
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
    return <<HTML;
<form action="/calc">
	<label for="name">Number:</label>
	<input type="text" id="num" name="num"></input>
	<input type="submit" value="Calculate square root"></input>
</form>
$html
HTML
};

get '/calc' => sub {
    my $num = param('num');

    unless ( Scalar::Util::looks_like_number($num) ) {
        return "Please enter a valid number";
    }

    my $timer;
    $timer = AnyEvent->timer(
        after => 0,      # start it right away
        cb    => sub {

            # Calculate square of a number or do your expensive operation here
            my $result = [ $num, $num * $num ];
            push @results, $result;

            # Cancel timer
            delete $timers{$timer};
        }
    );
    $timers{$timer} = $timer;

    return <<HTML;
Thanks for entering <strong>$num</strong>. 
<p>
Please click <a href="/">here</a> to return to the previous form.|
</p>
HTML
};

# Create a twiggy AnyEvent server
my $server = Twiggy::Server->new(
    host => '127.0.0.1',
    port => 5000,
);

# Our dancer application
my $app = sub {
    Dancer->dance( Dancer::Request->new( env => $_[0] ) );
};
$server->register_service($app);

# Run the main event loop
AnyEvent::Loop::run;
