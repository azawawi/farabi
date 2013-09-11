use Modern::Perl;
use AnyEvent;
use AnyEvent::Loop;
use System::Command;

my @cmd = ( 'ls -al' );

# invoke an external command, and return an object
my $cmd = System::Command->new(@cmd);

# $cmd is basically a hash, with keys / accessors
my $timer;
$timer = AnyEvent->timer(
    interval => 0.5,
    cb       => sub {

		
        #$cmd->stdin();     # filehandle to the process' stdin (write)
        #$cmd->stdout();    # filehandle to the process' stdout (read)
        #$cmd->stderr();    # filehandle to the process' stdout (read)
        #$cmd->pid();       # pid of the child process
        # find out if the child process died
        if ( $cmd->is_terminated() ) {

            # the handles are not closed yet
            # but $cmd->exit() et al. are available
            say "process " . $cmd->pid . " has terminated";

            # exit information
            #$cmd->exit();      # exit status
            #$cmd->signal();    # signal
            #$cmd->core();      # core dumped? (boolean)

            # done!
            $cmd->close();

            undef $timer;
        } else {
			say "Still alive!";
		}
    },
);

# cut to the chase
#my ( $pid, $in, $out, $err ) = System::Command->spawn(@cmd);

AnyEvent::Loop::run;

