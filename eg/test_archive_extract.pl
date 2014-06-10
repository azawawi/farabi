use Modern::Perl;
use Data::Printer;
use Path::Tiny;
use Mojo::UserAgent;

use CPAN::Common::Index::Mux::Ordered;
 
my $index = CPAN::Common::Index::Mux::Ordered->assemble(
    MetaDB => {},
    Mirror => { mirror => "http://cpan.cpantesters.org" },
);
 
 for my $pkg (qw(Moose Farabi Mojolicious Null)) {
 say $pkg;
 	my $result = $index->search_packages( { package => qr/^$pkg/ } );
 	p $result;
 }

exit 1;

my $response;
my $filename = '02packages.details.txt';
my $archive = "$filename.gz";

unless( -e $filename ) {
    my $url = "http://www.cpan.org/modules/$archive";
    say $url;
    $response = Mojo::UserAgent->new->max_redirects(1)->get($url)->res->body;
    path($archive)->spew_raw($response);

    use Archive::Extract;
    my $ae = Archive::Extract->new( archive => $archive );
    my $ok = $ae->extract;
    die "Extract of $archive failed" unless $ok;
}

open my $fh, "<", $filename or die "Cannot open $filename";
my @pkgs;
while (<$fh>) {
    next unless /\S/;
    next if /^\S+:\s/;
    chomp;
    my ( $pkg, $ver, $path ) = split /\s+/, $_;

    push @pkgs,
      {
        name    => $pkg,
        version => $ver,
        path    => $path,
      };

}
close $fh;

p @pkgs;

#use Archive::Zip qw(AZ_OK);
#my $zip = Archive::Zip->new();
#die "$archive read error" unless ( $zip->read($archive) == AZ_OK );

#my @files = $zip->memberNames();              # Lists all members in archive

#say $_ for @files;
