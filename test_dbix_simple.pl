use Modern::Perl;
use DBIx::Simple;

my $db = DBIx::Simple->connect('dbi:SQLite:dbname=farabi.db');

eval { $db->query("SELECT * FROM recent_list") };

if ($@) {
	say "Creating table...";
	$db->query(<<SQL);
CREATE TABLE recent_list (
	id INTEGER PRIMARY KEY AUTOINCREMENT, 
	name TEXT
)
SQL
	say "Table created";
}
else {

	for my $row ( $db->query('SELECT id, name FROM recent_list')->hashes ) {
		say "Id: $row->{id}, Name: $row->{name}";
	}
	$db->query( "INSERT INTO recent_list(name) VALUES(?)", qw(Ahmad) );
}

$db->disconnect;

