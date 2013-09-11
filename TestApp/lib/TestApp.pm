package TestApp;
use Dancer ':syntax';

use Modern::Perl;
use File::Temp ();
use AnyEvent ();
use Data::Printer;
use IO::All;
use Dancer;
use Dancer::Plugin::WebSocket;

our $VERSION = '0.1';

my $pid;
my %timers  = ();
my %results = ();

my $IS_WIN32 = $^O eq 'MSWin32';

my %cmds;
if ($IS_WIN32) {
    %cmds = (
        '0' => 'dir',
        '1' => 'dir -B',
        '2' => 'dir -D',
    );
}
else {
    %cmds = (

        '0' => 'ls',
        '1' => 'ls -a',
        '2' => 'ls -al',
    );
}

get '/' => sub {
    return template 'index';
};

get '/run/:cmd_id' => sub {
    my $cmd_id = param('cmd_id');
    my $cmd = $cmds{$cmd_id} or return "Invalid $cmd_id";

    my $stdout_fh    = File::Temp->new;
    my $stderr_fh    = File::Temp->new;
    my $stdout_fname = $stdout_fh->filename;
    my $stderr_fname = $stderr_fh->filename;
    $stdout_fh->unlink_on_destroy(0);
    $stderr_fh->unlink_on_destroy(0);
    $stdout_fh->close;
    $stderr_fh->close;

    my @cmd = ("$cmd >$stdout_fname 2>$stderr_fname");

    if ( $^O eq 'MSWin32' ) {

        # Windows OS
        $pid = system( 1, @cmd );
    }
    else {
        # Non-windows OS
        $pid = fork();
        if ( !$pid ) {
            exec(@cmd);
            exit;
        }
    }

    # Make sure the old result is dead
    delete $results{$cmd_id};

    my $timer;
    $timer = AnyEvent->timer(
        after    => 0,
        interval => 0.5,
        cb       => sub {
            my $stdout = io($stdout_fname)->slurp;
            my $stderr = io($stderr_fname)->slurp;

            # Update the process result record
            $results{$cmd_id} = [ $pid, $stdout, $stderr ];

            my $running = kill 0, $pid;

            # Cancel timer if process is dead
            delete $timers{$timer} unless ($running);
        }
    );
    $timers{$timer} = $timer;

    return "Running `$cmd`";

};

get '/result/:index' => sub {
    my $index = param('index');

    return "Invalid index" unless defined $index;

    my $result = $results{$index};

    return "No result for `$index`" unless defined $result;
    return '<pre>' . $result->[1] . $result->[2] . '</pre>';
};

true;
