
use Modern::Perl;
use Mojolicious::Lite;
use System::Command;
use Mojo::IOLoop;
use Mojo::Util qw(xml_escape);

my %results;

get '/' => sub {
	my $self = shift;

	my $html;
	if ( scalar keys %results > 0 ) {
		$html = '<pre>Process table:<table border="1">';
		for my $result ( values %results ) {
			my $stdout = substr $result->{stdout},0,50;
			my $stderr = substr $result->{stderr},0,50;
			$stdout = xml_escape($stdout);
			$stderr = xml_escape($stderr);
			$html .=
			    '<tr><td>'
			  . $result->{pid}
			  . '</td><td>'
			  . $result->{cmd}
			  . '</td><td>'
			  . $result->{status}
			  . '</td><td>'
			  . $stdout
			  . '</td><td>'
			  . $stderr
			  . '</td></tr>';
		}
		$html .= '</table></pre>';
	}
	else {
		$html = 'Empty!';
	}

	$self->render( text => <<HTML);
	Hello
<form action="/start">
	<input type="submit" value="Run!"></input>
</form>
$html
HTML
};

get '/start' => sub {
	my $self = shift;

	# invoke an external command, and return an object
	my $cmd;
	my $timer;

	#my @cmds = ('ack', '--nopager', '--nobreak', '--noenv', 'abc');
	#my @cmds = ('ack', '--nofilter', '.');
	#my @cmds = ( 'ack', '--nofilter1', 'Hello' );
	my @cmds = ( 'ack', '--nofilter', '.' );

	#my @cmds = ( 'perl', 'hello_world.pl' );

	$timer = Mojo::IOLoop->timer(
		1 => sub {
			my $loop = shift;

			$cmd = System::Command->new( @cmds, { trace => 3 } );
			say "Create streams";

			# Create stdout stream reader
			#my @streams;
			for my $handle (qw(stdout stderr)) {
				my $stream = Mojo::IOLoop::Stream->new( $cmd->$handle );

				#push @streams,
				$loop->stream($stream);
				$stream->on(
					read => sub {
						my ( $stream, $bytes ) = @_;
						say "read from $handle " . length $bytes;

						my $pid = $cmd->pid;

						my $o      = $results{$pid};
						my $output = defined $o ? $o->{stdout} : '';
						my $error  = defined $o ? $o->{stderr} : '';
						if ( $handle eq 'stdout' ) {
							$output .= $bytes;
						}
						else {
							$error .= $bytes;
						}

						$results{$pid} = {
							pid    => $pid,
							cmd    => join( ' ', @cmds ),
							stdout => $output,
							stderr => $error,
							status => 'running',
							exit   => 0,
						};

					}
				);
				$stream->on(
					close => sub {
						my $stream = shift;
						say "close $handle!";
					}
				);
				$stream->on(
					error => sub {
						my ( $stream, $err ) = @_;
						say "error at $handle!";
					}
				);

			}

		  }

	);

	my $interval;
	$interval = Mojo::IOLoop->recurring(
		1 => sub {
			my $loop = shift;

			return unless defined $cmd;

			if ( $cmd->is_terminated ) {

				# the handles are not closed yet
				# but $cmd->exit() et al. are available
				say "process " . $cmd->pid . " has terminated";

				my $pid = $cmd->pid;
				$results{$pid}->{status} = 'stopped';
				$results{$pid}->{exit} = $cmd->exit;

				# done
				$cmd->close;

				# Stop the process watchdog
				$loop->remove($interval);

			}
			else {
				say "Still alive!";
			}
		}
	);

	$self->render( text => <<HTML);
Process has been started. 
<p>
Please click <a href="/">here</a> to return to the previous form.|
</p>
HTML
};

app->start;
