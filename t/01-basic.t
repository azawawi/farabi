use Mojo::Base-strict;

use Test::More tests => 3;

use Farabi;
use Test::Mojo;

my $t = Test::Mojo->new( Farabi->new );

$t->get_ok('/')->status_is(200)->content_like(qr/Farabi/);
