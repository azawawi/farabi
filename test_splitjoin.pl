use Modern::Perl;
use PPI;

my $source = <<"END";
say "One" if 1;
if(1) say "One";
if(1) { say "One"; }
if(1) { say "One"; say;}
END

my $d = new PPI::Document(\$source);
$d->prune("PPI::Token::Whitespace");

my $statements = $d->find('PPI::Statement');
for my $statement (@$statements) {
#use Data::Printer;p($statement);
	if($statement->class eq 'PPI::Statement::Component') {
		say "Found if(...)";
	} else {
		say "Normal statement";
	}
}


#my @children = $d->children;
#use Data::Printer; p(@children);

require PPI::Dumper;
say PPI::Dumper->new($d)->string;
