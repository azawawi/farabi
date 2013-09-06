use Modern::Perl;
use File::Temp ();
use EV;
use AnyEvent ();
use Data::Printer;
use IO::All;
use Dancer2;

my $pid;
our $w;
our $c;
our $cv;
$cv = AnyEvent->condvar;
my @results;

get '/' => sub {
    return <<HTML;
<!DOCTYPE html>
<html>
<head>
<style>
table {
	width: 100%;
	border: 1px solid black;
}
iframe {
	border: 1px solid black;
	width: 100%;
}
</style>
<script>


function start() {
	document.getElementById("out1").src = "/run/0";
//	document.getElementById("out2").src = "/run/1";
//	document.getElementById("out3").src = "/run/2";
	
	var interval = setInterval(function() {
		document.getElementById("out1").src = "/result/0";
//		document.getElementById("out2").src = "/result/1";
//		document.getElementById("out3").src = "/result/2";
	}, 5000);
}
</script>
</head>
<body>
<button id="start" onClick="start()">Start!</button>
<table>
	<tr>
		<td><iframe id="out1"></iframe></td>
		<td><iframe id="out2"></iframe></td>
		<td><iframe id="out3"></iframe></td>
	</tr>
</table>
</body>
</html>
HTML
};

my %cmds = (

    '0' => 'ls',
    '1' => 'ls -a',
    '2' => 'ls -al',
    #'0' => 'dir',
    #'1' => 'dir -B',
    #'2' => 'dir -D',
);

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

    $w = AnyEvent->timer(
        after    => 0,
        interval => 1,
        cb       => sub {
            my $stdout = io($stdout_fname)->slurp;
            my $stderr = io($stderr_fname)->slurp;

            my $running = kill 0, $pid;
            unless ($running) {

                # Process terminated, return its result
                my $result = [ $pid, $stdout, $stderr ];
                $cv->send($result);
                undef $w;
            }

        }
    );
    $c = AnyEvent->timer(
        after => 1,
        cb    => sub {
            push @results, $cv->recv;
            undef $c;
        }
    );

    return "Running $cmd";

};

get '/result/:index' => sub {
    my $index = param('index');

    return "Invalid index" unless defined $index;
    if ( $index >= scalar @results ) {
        return "Out of bounds index";
    }

    my $result = $results[$index];
	return '<pre>' . $result->[1] . $result->[2] . '</pre>';
};

dance;
