
use Modern::Perl;

package Farabi::Process;
use Mojo::IOLoop;
use Mojo::Base 'Mojo::EventEmitter';

=head1 run

Runs the given commands array reference and emits the following Mojo events

=over

=item read_stdout

=item read_stderr

=item close_stdout

=item close_stderr

=item error_stdout

=item error_stderr

=item process_exit

=item error

=back

=cut

sub run {
	my $self = shift;
	my $cmds = shift;

	my $cmd;
	my $timer;
	$timer = Mojo::IOLoop->timer(
		0 => sub {
			my $loop = shift;

			eval {
				require System::Command;
				$cmd = System::Command->new( @$cmds, { trace => 3 } );
			};

			if ($@) {
				$self->emit( error => $@ );
				return;
			}

			# Create stdout stream reader
			for my $handle (qw(stdout stderr)) {
				my $stream = Mojo::IOLoop::Stream->new( $cmd->$handle );
				$loop->stream($stream);
				$stream->on(
					read => sub {
						my ( $stream, $bytes ) = @_;

						if ( $handle eq 'stdout' ) {
							$self->emit( read_stdout => $bytes );
						}
						else {
							$self->emit( read_stderr => $bytes );
						}
					}
				);
				$stream->on(
					close => sub {
						my $stream = shift;

						if ( $handle eq 'stdout' ) {
							$self->emit( close_stdout => 1 );
						}
						else {
							$self->emit( close_stderr => 1 );
						}

					}
				);
				$stream->on(
					error => sub {
						my ( $stream, $err ) = @_;

						if ( $handle eq 'stdout' ) {
							$self->emit( error_stdout => $err );
						}
						else {
							$self->emit( error_stderr => $err );
						}

					}
				);

			}

		  }

	);

	my $watchdog;
	$watchdog = Mojo::IOLoop->recurring(
		1 => sub {
			my $loop = shift;

			unless ( defined $cmd ) {

				# Stop the process watchdog the command failed to start
				$loop->remove($watchdog);
				return;
			}

			# Dont continue if the process has not terminated
			return unless $cmd->is_terminated;

			# Process has terminated, emit event
			$self->emit(
				process_exit => { pid => $cmd->pid, 'exit' => $cmd->exit } );

			# done
			$cmd->close;

			# Stop the process watchdog
			$loop->remove($watchdog);

		}
	);
}

1;

#------------------------------------------------------------------------------
package main;

# Create nonblocking Farabi::Process
my $o = Farabi::Process->new;

# Subscribe to events
$o->on(
	read_stdout => sub {
		my ( $self, $bytes ) = @_;
		say "read_stdout event " . length($bytes) . " (event)";
	}
);

$o->on(
	close_stdout => sub {
		my $self = shift;

		say "close stdout (event)";
	}
);
$o->on(
	close_stderr => sub {
		my $self = shift;

		say "close stderr (event)";
	}
);

$o->on(
	process_exit => sub {
		my $self = shift;
		my $r    = shift;

		say "process " . $r->{pid} . " has terminated (event)";
	}
);

$o->on(
	error => sub {
		my $self = shift;
		my $err  = shift;

		say "Error (event): " . $err;
	}
);

$o->run( [ 'ack', '--nofilter', '.' ] );

# Start event loop if necessary
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
