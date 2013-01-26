use Modern::Perl;
use MediaWiki::API;

binmode STDOUT, ':utf8';

my $mw = MediaWiki::API->new;
$mw->{config}->{api_url} = 'http://rosettacode.org/mw/api.php';

# get a list of articles in category
my $articles = $mw->list(
    {
        action  => 'query',
        list    => 'categorymembers',
        cmtitle => 'Category:Perl',
        cmlimit => 'max'
    }
) || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};

use Data::Dumper;


# and print the article titles
for my $article (@$articles ) {
#    say $article->{title};
#	say Dumper($article);

	my $page = $mw->get_page( { title => $article->{title} } );
	print $page->{'*'};

	last;
	
}

