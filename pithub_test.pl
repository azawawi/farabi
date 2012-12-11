use Modern::Perl;
use Pithub;
use Data::Printer;

my $c = Pithub::Repos::Contents->new(
    repo => 'farabi',
    user => 'azawawi'
);
 
# List all files/directories in the repo root
my $result = $c->get;
if ( $result->success ) {
    p($_) for @{ $result->content };
}
 
# Get the Farabi.pm file
#$result = $c->get( path => 'lib/Farabi.pm' );
#p $result->content if $result->success;
