use Modern::Perl;
use Pithub;
use Data::Printer;
use Method::Signatures;

func list_files_in_folder (Str $user, Str $repo, Str $path) {
say "Path: $path, user: $user, repo: $repo";
	my $c = Pithub::Repos::Contents->new(
		user => $user,
		repo => $repo,
	);
	
	my @files;

	# List all files/directories in the repo root
	my $result = $c->get;
	#(path => $path);
	if ( $result->success ) {
		for my $r ( $result->content ) {

			p $r;
			#say "$_ : " . $r->{$_} for qw(name type path size url);

			push @files, (
				name => $r->{name},
				type => $r->{type},
				path => $r->{path},
				size => $r->{size},
				url  => $r->{url},
			);

say "1";
			if($r->{type} eq 'dir') {
			
				say "read " . $r->{path};
				push @files, list_files_in_folder($user, $repo, $r->{path}) ;
			}

			#p $_;
			#say "-" x 80;

		}

		#say $_->{name} for @{ $result->content };
		} else {
		say "Error!";
		}

	# Get the XYZ file
	#$result = $c->get( path => '/README.md' );
	#p $result->content if $result->success;
	
	@files;
}

p list_files_in_folder( 'azawawi', 'Farabi', '/' );
