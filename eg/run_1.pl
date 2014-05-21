
use Modern::Perl;

package Farabi::Process;

use Mojo::Base 'Mojo::EventEmitter';

=head1 run

Runs the given commands array reference and emits the following Mojo events

=over

=item stream_read

=item stream_close

=item stream_error

=item finish

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
					'read' => sub {
						$self->emit(
							stream_read => { type => $type, bytes => $_[1] } );
					}
				);
				$stream->on(
					'close' => sub {
						$self->emit( stream_close => $type );
					}
				);
				$stream->on(
					'error' => sub {
						$self->emit(
							stream_error => { type => $type, err => $_[1] } );
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
				finish => { pid => $cmd->pid, 'exit' => $cmd->exit } );

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
	stream_read => sub {
		my $self = shift;
		my $r    = shift;
		say "stream_read $r->{type} event "
		  . length( $r->{bytes} )
		  . " (event)";
	}
);

$o->on(
	stream_close => sub {
		my $self = shift;
		my $type = shift;

		say "stream_close $type (event)";
	}
);

$o->on(
	finish => sub {
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
