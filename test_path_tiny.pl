use Modern::Perl;
use Path::Tiny;

my (@dirs, @files);
for my $c (Path::Tiny->new('.')->children) {
	if($c->is_dir) {
		push @dirs, $c;
	} else {
		push @files, $c;
	}
}

@dirs = sort @dirs;
@files = sort @files;

my @final = (@dirs, @files);
say "@final";
