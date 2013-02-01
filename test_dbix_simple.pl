use Modern::Perl;
use DBIx::Simple;

my $db = DBIx::Simple->connect('dbi:SQLite:dbname=farabi.db');

# DDL...
$db->query(<<SQL);
CREATE TABLE IF NOT EXISTS recent_list (
	id INTEGER PRIMARY KEY AUTOINCREMENT, 
	name TEXT
)
SQL

for my $row ( $db->query('SELECT id, name FROM recent_list')->hashes ) {
	say "Id: $row->{id}, Name: $row->{name}";
}
$db->query( "INSERT INTO recent_list(name) VALUES(?)", qw(Ahmad) );

$db->disconnect;

