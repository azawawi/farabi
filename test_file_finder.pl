
use Modern::Perl;
use File::Find::Rule;
use Path::Iterator::Rule;
use Benchmark;

sub file_file_rule {
	my $dir = shift;

	my $rule = File::Find::Rule->new;
	$rule->or(
		$rule->new->directory->name( 'CVS', '.svn', '.git', 'blib', '.build' )
		  ->prune->discard,
		$rule->new
	);

	my @files = $rule->file->in($dir);
	say scalar @files;
}

sub path_iterator_rule {
	my $dir = shift;

	my %options = (
		sorted        => 0,
		depthfirst    => -1,
		error_handler => undef
	);
	my @files =
	  Path::Iterator::Rule->new->skip_dirs( 'CVS', '.svn', '.git', 'blib',
		'.build' )->file->all( $dir, \%options );

	say scalar @files;
}

my $dir = '/home/azawawi';

timethese(
	1,
	{
		'file_file_rule'     => sub { file_file_rule $dir },
		'path_iterator_rule' => sub { path_iterator_rule $dir; },
	}
);
