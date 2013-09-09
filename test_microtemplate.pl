use Modern::Perl;
use Text::MicroTemplate qw(render_mt);
 
my $html = render_mt('Hello, <?= $_[0] ?>', 'John')->as_string;
say $html;
