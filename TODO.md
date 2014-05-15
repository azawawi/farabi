Farabi TODO list
================

This is the list of project TODO tasks.

Welcome message at startup
==========================

Open a tab on a new installation that open Farabi Changes file

Question: How to identify a new cpanm installation
Answer: store in farabi database a farabi version. when the active version is higher, open a new ''changes'' and update the version table to the new version

or we can simply a Changes menu item :)


Trailing space support
======================

Add trailing space option to Farabi since we already have it in client-side CodeMirror

See the demo
http://codemirror.net/demo/trailingspace.html

AutoCompletion support
======================

See example http://codemirror.net/addon/hint/python-hint.js

We can do it in JavaScript or alternatively pull it from Perl land to make it more relevant to script
minimum version.

Autocompletion of Perl operators is useful.
Autocompletion of Perl operation **with documentation** on the side is very useful when selected

Autocompletion of Perl functions pulled from syntax highlighted

Autocompletion of Package::Name::XYZ is done by reusing the "Module name in package name parsed from 02packages.details.txt.gz"

Question: What if the user wants to autocomplete stuff on his machine?
Use Metacpan or local perldoc if needed. Integration with perlbrew is a possibility...

The project i am working with is using v5.16 but Farabi is installed on system Perl or perlbrewed 5.18
============

From String::InterpolatedVariables SYNOPSIS
This is particularly useful if you are using PPI to parse Perl documents, and you want to know
what variables would be interpolated inside the PPI::Token::Quote::Double and PPI::Token::Quote::Interpolate objects
you find there.  A practical example of this use can be found in Perl::Critic::Policy::ValuesAndExpressions::PreventSQLInjection.

This is useful for Farabi to provide its own "accurate" syntax highlighting that is based on
PI and later on the fast Compiler::Lexer

    use v5.18;
    use String::InterpolatedVariables;
    use Data::Printer;
 
    my $variables = String::InterpolatedVariables::extract(
           'A $test->{string} $foo $bar from a PPI::Token::Quote::Double $object.'
    );
    p $variables;

#------------------------------------------------------------------------------------------------------------
#---
#--- Use this script to "cache Module names in Farabi in $FARABI_HOME/cpan/02packages.details.txt.gz"
# courtesy of https://github.com/sharyanto/scripts/blob/master/get-tarball-path-from-local-cpan
#-----------------------------------------------------------------------------------------------------------
use v5.18;
use HTTP::Tiny;

#if(-z '02packages.details.txt.gz') {
#my $response = HTTP::Tiny->new->get('http://www.cpan.org/modules/02packages.details.txt.gz');
#die "Failed!\n" unless $response->{success};
#print $response->{content} if length $response->{content};
#}

#TODO decompress 02packages.details.txt.gz and use in the parsing loop below

my $filename =
  q{C:/Users/azawawi/.cpanm/sources/http%www.cpan.org/02packages.details.txt};
open my $fh, "<", $filename or die "Cannot open $filename";
while (<$fh>) {
    next unless /\S/;
    next if /^\S+:\s/;
    chomp;
    my ( $pkg, $ver, $path ) = split /\s+/, $_;

    if ( $pkg =~ /^Moose/ ) {
        say "$pkg => $ver";
    }
}
close $fh;
----------------------------------------------------------------------------------------------------------

# Blueish theme for Perl syntax highlighting. Please https://github.com/jasonlong/lavalamp

# Add minil new, dist, release commands. Project starter will now use Minilla

Add support for REPL using Reply instead of ancient Devel::REPL

Add App::Ack support through the following command:
	ack "use 5\.0" --sort-files --noenv --nobreak

Add Unicode Table Search for Perl with preview!
Fix damn bug about POD fragments
More POD about current functionality
Show progress when loading Perlito for the first time
Show progress when building index and allow to fire a re-index operation later
Faster search index
Search MetaCPAN within Farabi
Support browsing of code and selection of resources using MetaCPAN API http://api.metacpan.org/source/TEMPIRE/Mojolicious-3.41/
Active line should change on different themes.
Print what's that language when using the language selector
Show me an example...
Add favicon
More tests for various actions in t/
Autocomplete sections in http://perldoc.perl.org/perlpodstyle.html
Link to POD style http://perldoc.perl.org/perlpodstyle.html
Link to Perl style http://perldoc.perl.org/perlstyle.html
Save scratch to Ideas folder. Basically you sometimes need a proof of concept script and do not want to pollute desktop/home/project folder
Add Comment / Uncomment to Perl mode
Add not_found.development.html.ep and not_found.html.ep
Use full screen API (if enabled).
Detect older unsupported browsers and drop them a similar message:
	unfortunately your computer or browser are out of date.
	You will not be able to view the full content of this site,
	but you may click HERE for a minified version.
	We strongly suggest that you upgrade and use one of the following browsers
	firefox, mozilla, ie, opera, safari"
Save state in farabi
Conserve height for wide screens. Small thumbnail-style Control menu on the left/right. Expandable on click.
Indexer problem: Search mechanism is wrong if farabi is run in user home dir
Investigate integrating perl6 support through the following:
	viv hello.p6 -5 | perl
	perl6 hello.p6

Rosetta code browser in "Learn" tab. You can select Task and then use the mimetype
	http://rosettacode.org/wiki/User_input/Text#Perl_6
	http://rosettacode.org/wiki/Category:Perl_6


To install Pithub, we need Net::SSLeay installed and hence
sudo apt-get install libssl-dev
