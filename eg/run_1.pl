
use Modern::Perl;
use System::Command;
use File::Which;
use Mojo::IOLoop;

my $cmd;
my $force_close = 0;
my $timer;
my @streams = ();

$timer = Mojo::IOLoop->timer(
	1 => sub {
		my $loop = shift;

		#my @cmds = ('ack', '--nopager', '--nobreak', '--noenv', 'abc');
		#my @cmds = ('ack', '--nofilter', '.');
		my @cmds = ('ack', '--nofilter', 'Hello');
		#my @cmds = ( 'perl', 'hello_world.pl' );
		$cmd = System::Command->new( @cmds, { trace => 3 } );

		# Create stdout stream reader
		for my $handle (qw(stdout stderr)) {
			my $stream = Mojo::IOLoop::Stream->new( $cmd->$handle );
			push @streams, $loop->stream($stream);
			$stream->on(
				read => sub {
					my ( $stream, $bytes ) = @_;
					say "read from $handle " . length $bytes;
					say $bytes;
					say "-" x 80;
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

=pod
my $timeout;
$timeout = Mojo::IOLoop->timer(
	3 => sub {
		my $loop = shift;

		say "Timeout!";
		$force_close = 1;

		for my $stream (@streams) {
			$loop->remove($stream);
		}
	}
);
=cut

my $interval;
$interval = Mojo::IOLoop->recurring(
	1 => sub {
		my $loop = shift;

		return unless defined $cmd;

		if ( $cmd->is_terminated or $force_close ) {

			# the handles are not closed yet
			# but $cmd->exit() et al. are available
			say "process " . $cmd->pid . " has terminated";

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

# Start event loop if necessary
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

=cut
