use Modern::Perl;
use HTTP::Tiny;
use Method::Signatures;
use Mojo::UserAgent;
use Data::Printer;

func download_github_repo (Str $user, Str $repo) {
	                          #if(-z '02packages.details.txt.gz') {
	                          #}
	my $url      = "https://github.com/$user/$repo/archive/master.zip";
	my $response = Mojo::UserAgent->new->max_redirects(1)->get($url)->res->body;

	$response;
}

my $archive = download_github_repo( 'azawawi', 'Farabi' );

#p $archive;
