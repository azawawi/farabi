Farabi TODO list
================

This is the project's TODO list. Please feel free to work on any item and kindly send a pull request.

- Consider using this Apache 2.0 license template http://startbootstrap.com/templates/sb-admin-2/index.html

- Consider adding users and login to prevent security concerns

- Add CREDITS, THANKS and AUTHORS file

"...Also, if you have a file called "CREDITS", "AUTHORS", or "THANKS" in your release's root directory, MetaCPAN will consider this to be an a href="https://github.com/CPAN-API/metacpan-web/blob/master/lib/MetaCPAN/Web/Model/API/Release.pm#L320">interesting file and display it on your release page (under the "Other Files" heading)..."

- Farabi should be clever about warnings under strict

		Bareword "i" not allowed while "strict subs" in use
	
	Should ask the user whether he meant ```$i```?

- Ideas for server-side PPI-based highlighting:

		FWIW, the standard strategy for high-end IDEs is: 

		1) do a fast pass (simple tokenizer)
		2) send the code to background thread/process for a full parse and return a structure that maps locations to parse info
		3) Then as you colorize in the tokenizer, you'd use your location to get the parsed token information

		It's a very efficient method that retains responsiveness and makes your tokenizer even faster (a property lookup vs regex eating). Realistically, you don't want to replicate the heuristics used to re-color certain parts of the editor, so ideally you'd just use the mechanism that modes do. I'm not sure if there's a good way to get access to your current position within the document though.

- Provide snippets support like http://ace.c9.io/build/kitchen-sink.html using Perl. Most of the work has been done as a state machine in previous experimental Padre::Plugin::Snippet

- Spell check in comments only using https://metacpan.org/pod/Spellunker::Perl when you're over a Perl mime-typed document

- If ```use Method::Signatures``` is found, enable highlighting of the following keywords:

		method func

- If ```use Moose``` is found, enable highlighting of the following keywords:

		has before after extends with around override super augment inner blessed confess

- If ```use Moops``` is found, enable highlighting of the following keywords:

		class has role namespace method fun before after around define
		From Perl 5.14: state say
		
- How to run a single test via Dist::Zilla

  http://blogs.perl.org/users/olaf_alders/2014/06/how-to-run-a-single-test-via-distzilla.html

       		dzil run prove -lv t/my-test.t

- Investigate how to track line number information in POD and Markdown Preview. The idea is to scroll the view
  as you are editing...

- All Farabi HTTP traffic should use a unique HTTP Agent

- Once MetaCPAN integration is there, we should add Farabi to https://github.com/CPAN-API/cpan-api/wiki/API-Consumers

- Add Perl::MinimumVersion action to detect current syntax of current Perl script

- Switch to Mime type based syntax highlighting support

		'text/x-perl' => {
			exts => qw(pm pl t),
			mode => 'perl',
		},

- Document PAR::Archiver settings for packing farabi as an executable

		pp --addfile="C:\strawberry\perl\site\lib\Mojo\entities.txt;lib/Mojo/entities.txt" 	--addfile="C:\strawberry\perl\site\lib\Mojolicious\Plugin;lib\Mojolicious\Plugin" --addfile="C:\strawberry\perl\site\lib\Mojolicious\Plugin.pm;lib\Mojolicious\Plugin.pm" --addfile="C:\strawberry\perl\site\lib\Mojolicious\Command;lib\Mojolicious\Command" --module=Capture::Tiny --output=farabi.exe bin\farabi

- See http://blogs.perl.org/users/rockyb/2014/05/introspection-in-develtrepan.html for AutoCompletion idea from within Perl

- Implement project tree using http://www.jstree.com/ (ALT-T or ALT-E)

- Use Mojo::Util to provide Tools/Base64 encode/decode

- Use Mojo::Util to provide Tools/JSON encode/decode and validation

- Use CodeMirror's mustache example to provide Mojo template <% %> Perl support

- Use Mousetrap to capture events like F11 and pass it to the focused editor

- Implement new UI idea in Farabi as alternative UI with a link at the top (see POC at http://feather.perl6.nl/~azawawi/)

- When the editor is focused, ```$.post``` a ```'/file_exists'``` request for all tab editors. If it is true, please show the following dialog (like Notepad++):
	
		The file "$file_name" does not exist anymore.
		Keep this file in editor?

- Update editor for **long running tasks** like 'dzil test' or 'dzil build' or 'cpanm XYZ'


- Prototype vertical scrolling and auto resize http://codemirror.net/demo/resize.html
	The idea here is that editors are laid out vertically with fullscreen and autoresize only to 10 characters.
	- Save/Close are file specific actions
	- New script is shown on the right

- Documentation, Documentation :)

	- Borrow what you have written in Padre https://metacpan.org/source/PLAVEN/Padre-1.00/lib/Padre/Document/Perl/Help.pm
	- Get https://github.com/cowens/perlopquick/blob/master/perlopquick.pod

	- Support current initial project runtime, .farabirc

		If the currently selected project folder contains .farabiirc, search for perlbrew-runtime key

			perlbrew exec --with perl-5.16.3 perldoc XYZ

- Rewrite URLs emitted by perldoc to use /perldoc? instead of search.cpan.org. 
  External URLs should be target="_blank"

- Securing Farabi by default

	Use http://mojolicio.us/perldoc/Mojolicious#before_dispatch

		jberger:	you could do a before_dispatch which checks that the request host is the same as the server, send 500 if not
		azawawi:	i want it to be accessible from the same intranet
		jberger:	so make the hook configurable

- POD::Web::View

	While i was hibernating and playig Mists of Pandaria, an interesting competing project
	happened that added the following interesting features:

	- POD::Web::View - http://blogs.perl.org/users/michal_wojciechowski/2013/10/pod-web-view.html
	- 'Borrow' and attribute copyright to 'original'' authors from https://github.com/odyniec/POD-Web-View/tree/master/public/css/pod-stylesheets/orig
	- Did not insert the scripts yet in previewed POD
	- Add "Open URL" functionality
	- Add "Upload file" functionality

- Automatic variable highlighting (VIM)

	- Highlight the variable that your cursor is currently on. Please see http://blogs.perl.org/users/ovid/2014/05/automatic-variable-highlighting-in-vim.html)
	- Add an ON/OFF option for it

- Try to secure Ack command line from injection.

- All problem source (spellunker,syntax check,jshint,perl critic,..etc) should agree on
	a central problem manager than should coordinate between them. Seriously :)

- Welcome message at startup

	Open a tab on a new installation that open Farabi Changes file

	Question: How to identify a new cpanm installation
	Answer: store in farabi database a farabi version. when the active version is higher, open a new ''changes'' and update the version table to the new version

	or we can simply a Changes menu item :)


- Server-side jshint support

	Why use client side support when it can lock on big files... Why
	keep upgrading Farabi when the updated jshint command can be simply used

	- .jshintrc is your jshint file

	- its documentation is found at http://jshint.org/docs/options/

	- Installation notes for jshint tool:

		sudo apt-get install nodejs-legacy npm
		sudo npm install -g jshint
		jshint  # should be in /usr/local/bin/jshint




	- Sample jshint run to parse:

			test.js: line 14, col 3, Unreachable '/123/' after 'return'.
			test.js: line 14, col 3, Expected an assignment or function call and instead saw an expression.
			test.js: line 15, col 14, Unexpected '@'.
			test.js: line 15, col 13, Expected an operator and instead saw '!'.
			test.js: line 15, col 13, Expected an assignment or function call and instead saw an expression.
			test.js: line 15, col 14, Missing semicolon.
			test.js: line 17, col 4, Unexpected '@'.
			test.js: line 17, col 3, Expected an assignment or function call and instead saw an expression.
			test.js: line 17, col 4, Missing semicolon.

	- Sample errors:

			ERROR: Can't open test1.js
			ERROR: Can't parse config file: /home/azawawi/farabi/.jshintrc

- Trailing space support


	Add trailing space option to Farabi since we already have it in client-side CodeMirror

	See the demo
	http://codemirror.net/demo/trailingspace.html

* AutoCompletion support

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


- Accurate PPI or Compiler::Lexer syntax highlighting

	From String::InterpolatedVariables SYNOPSIS
	This is particularly useful if you are using PPI to parse Perl documents, and you want to know
	what variables would be interpolated inside the PPI::Token::Quote::Double and PPI::Token::Quote::Interpolate objects
	you find there.  A practical example of this use can be found in Perl::Critic::Policy::ValuesAndExpressions::PreventSQLInjection.
	
	See https://metacpan.org/source/SILLYMOOS/PPI-Prettify-0.06/lib/PPI/Prettify.pm
	
	See http://search.cpan.org/~adamk/PPI-HTML-1.08/lib/PPI/HTML.pm

		use Modern::Perl;
		use PPI;
		use PPI::HTML;
		  
		my $code_sample = q! 
		=head1 text
		
			Stuff...
		
		=cut
			# get todays date in Perl
		    use Time::Piece;
		    print Time::Piece->new;
		                  !;
		
		# Load your Perl file
		my $doc = PPI::Document->new( \$code_sample );
		  
		# Create a reusable syntax highlighter
		my $Highlight = PPI::HTML->new( line_numbers => 1 );
		  
		# Spit out the HTML
		my $html = $Highlight->html( $doc );
		  
		  
		$html = "
		  <style>
		  .line_number { color: red; }
		  .pod { color: gray; }
		  .comment { color: green; }
		  .keyword { color: blue; font-weight: bold; }
		  .word { color: black; font-weight: bold;  }
		  </style>
		  " . $html;
		  
		say $html;

	This is useful for Farabi to provide its own "accurate" syntax highlighting that is based on
	PI and later on the fast Compiler::Lexer

    		use v5.18;
    		use String::InterpolatedVariables;
    		use Data::Printer;
		 
    		my $variables = String::InterpolatedVariables::extract(
        		 'A $test->{string} $foo $bar from a PPI::Token::Quote::Double $object.'
    		);
    		p $variables;

* CPAN Module name support

 Use this script to "cache Module names in Farabi in $FARABI_HOME/cpan/02packages.details.txt.gz"
 courtesy of https://github.com/sharyanto/scripts/blob/master/get-tarball-path-from-local-cpan

		use v5.18;
		use HTTP::Tiny;

		if(-z '02packages.details.txt.gz') {
		my $response = HTTP::Tiny->new->get('http://www.cpan.org/modules/02packages.details.txt.gz');
			die "Failed!\n" unless $response->{success};
			print $response->{content} if length $response->{content};
		}

- Read Module Names

	Download and decompress 02packages.details.txt.gz and use in the parsing loop below:

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

- Blueish theme for Perl syntax highlighting. Please https://github.com/jasonlong/lavalamp

- Add minil new, dist, release commands. Project starter will now use Minilla

- Add support for REPL using Reply instead of ancient Devel::REPL

- Add App::Ack support through the following command:

	```
		# Please note that --nofilter is needed to prevent blocking when running it over System::Command

		ack "use 5\.0" --nofilter --sort-files --noenv --nobreak

		# no filter is needed for ack...
		ack --nofilter Hello
	```

- Add Unicode Table Search for Perl with preview!

- Fix damn bug about POD fragments

- More POD documentation in Farabi.pm and Editor.pm about current functionality

- Show progress when loading Perlito for the first time

- Show progress when building index and allow to fire a re-index operation later

- Faster search index

- Search MetaCPAN within Farabi

- Support browsing of code and selection of resources using MetaCPAN API http://api.metacpan.org/source/TEMPIRE/Mojolicious-3.41/

- Print what's that language when using the language selector

- Show me an example...

- Add favicon

- More tests for various actions in t/

- Autocomplete sections in http://perldoc.perl.org/perlpodstyle.html

- Link to POD style http://perldoc.perl.org/perlpodstyle.html

- Link to Perl style http://perldoc.perl.org/perlstyle.html

- Save scratch to Ideas folder. Basically you sometimes need a proof of concept script and do not want to pollute desktop/home/project folder

- Add Comment / Uncomment to Perl mode

- Add not_found.development.html.ep and not_found.html.ep

- Use full screen API (if enabled).

- Detect older unsupported browsers and drop them a similar message:

	unfortunately your computer or browser are out of date.
	You will not be able to view the full content of this site,
	but you may click HERE for a minified version.
	We strongly suggest that you upgrade and use one of the following browsers
	firefox, mozilla, ie, opera, safari"

- Save state in farabi

- Conserve height for wide screens. Small thumbnail-style Control menu on the left/right. Expandable on click.

- Indexer problem: Search mechanism is wrong if farabi is run in user home dir
