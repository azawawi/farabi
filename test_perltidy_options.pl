use Modern::Perl;
use File::Which;
use Path::Tiny;
use Pod::POM;

# Parse perltidy executable for POD options
my $perltidy = which("perltidy");
my $parser   = Pod::POM->new;
my $pom      = $parser->parse_file($perltidy)
  || die $parser->error();

# print each section
my $options_head1;
my $formatting_options_head1;
foreach my $head1 ( $pom->head1 ) {
	if ( $head1->title eq 'OPTIONS - OVERVIEW' ) {
		$options_head1 = $head1;
	}
	if ( $head1->title eq 'FORMATTING OPTIONS' ) {
		$formatting_options_head1 = $head1;
	}
}

die "Cannot find options head1"            unless $options_head1;
die "Cannot find formatting options head1" unless $formatting_options_head1;

say "1";
foreach my $head2 ( $options_head1->head2 ) {
	say $head2->title;
	find_options($head2);

}

say "2P";

foreach my $head2 ( $formatting_options_head1->head2 ) {
	find_options($head2);
}

sub find_options {
	my $head2 = shift or die "head2 undefined";

	foreach my $item ( $head2->over->[0]->item ) {
		say $item->title;
	}
}

__END__
