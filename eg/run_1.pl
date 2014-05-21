
use Modern::Perl;

package Farabi::Process;

use Mojo::Base 'Mojo::EventEmitter';

=head1 run

Runs the given commands array reference and emits the following Mojo events

=over

=item process_read

=item process_error

=item process_exit

=item error

=back

=cut

sub run {
	my $self = shift;
	my $cmds = shift;

	my $cmd;
	my $timer;
	require Mojo::IOLoop;
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
			for my $type (qw(stdout stderr)) {
				my $stream = Mojo::IOLoop::Stream->new( $cmd->$type );
				$loop->stream($stream);
				$stream->on(
					read => sub {
						my $stream = shift;
						my $bytes  = shift;
						$self->emit(
							process_read => { type => $type, bytes => $bytes }
						);
					}
				);
				$stream->on(
					close => sub {
						$self->emit( process_close => $type );
					}
				);
				$stream->on(
					error => sub {
						my $stream = shift;
						my $err    = shift;

						$self->emit(
							process_error => { type => $type, err => $err } );
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
	process_read => sub {
		my $self  = shift;
		my $r  = shift;
		say "process_read $r->{type} event " . length($r->{bytes}) . " (event)";
	}
);

$o->on(
	process_close => sub {
		my $self = shift;
		my $type = shift;

		say "process_close $type (event)";
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
