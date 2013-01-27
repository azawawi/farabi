package Farabi;
use Mojo::Base 'Mojolicious';

our $VERSION = '0.27';

sub startup {
	my $app = shift;

	# Change secret passphrase that is used for signed cookies
	$app->secret('Hulk, Smash!');

	# Use content from directories under lib/Farabi/files
	require File::Basename;
	require File::Spec::Functions;
	$app->home->parse( File::Spec::Functions::catdir( File::Basename::dirname(__FILE__), 'Farabi' ) );
	$app->static->paths->[0]   = $app->home->rel_dir('files/public');
	$app->renderer->paths->[0] = $app->home->rel_dir('files/templates');

	# Define routes
	my $route = $app->routes;
	$route->get('/')->to('editor#default');
	$route->post('/')->to('editor#default');
	$route->post('/help_search')->to('editor#help_search');
	$route->post('/perl-tidy')->to('editor#perl_tidy');
	$route->post('/perl-critic')->to('editor#perl_critic');
	$route->post('/typeahead')->to('editor#typeahead');
	$route->post('/pod2html')->to('editor#pod2html');
	$route->post('/pod-check')->to('editor#pod_check');
	$route->post('/open-file')->to('editor#open_file');
	$route->post('/find-file')->to('editor#find_file');
	$route->post('/save-file')->to('editor#save_file');
	$route->post('/open-url')->to('editor#open_url');
	$route->post('/find-action')->to('editor#find_action');
	$route->post('/run-perl')->to('editor#run_perl');
	$route->post('/run-rakudo')->to('editor#run_rakudo');
	$route->post('/run-niecza')->to('editor#run_niecza');
	$route->post('/run-parrot')->to('editor#run_parrot');
	$route->post('/find-duplicate-perl-code')->to('editor#find_duplicate_perl_code');
	$route->post('/dump-ppi-tree')->to('editor#dump_ppi_tree');

	# Web-based Read-Eval-Print-Loop (REPL) action
	$route->post('/repl-eval')->to('editor#repl_eval');
}

sub unsafe_features {
	# Enable unsafe features by default for now
	return 1; # defined $ENV{FARABI_UNSAFE};
}


1;
__END__

=pod

=head1 NAME

Farabi - Modern Perl editor

=head1 SYNOPSIS

  # Run on the default port 3000
  $ farabi daemon
  
  # Run it on port 3030
  $ farabi daemon --listen "http://*:3030"

=head1 DESCRIPTION

This is a modern web-based Perl editor that runs inside your favorite browser.

Please run the following command and then open http://127.0.0.1:3000 in your browser:

  farabi daemon

Please note that Farabi is purely expermintal at the moment. Things are moving fast
as I try some new ideas. Feedback is welcome.

=head1 SEE ALSO

=over

=item *

L<Mojolicious|http://mojolicio.us> - A next generation web framework for the Perl programming language

=item *

L<jQuery|http://jquery.com/> - A new kind of JavaScript Library

=item *

L<Bootstrap|http://twitter.github.com/bootstrap> - Sleek, intuitive, and powerful front-end framework for faster and easier web development

=item *

L<CodeMirror|http://codemirror.net> - In-browser code editing made bearable

=item *

L<Perlito|http://perlito.org/> - Runtime for "Perlito" Perl5-in-Javascript

=back

=head1 HISTORY

The idea started back in March 2012 as a fork of L<Padre>. I wanted to dump L<Wx> for the browser. 
The first version was in 11th April as L<Mojolicious::Plugin::Pedro>. It used the ACE Javascript
editor and jQuery UI. Then i hibernated for a while to play games :) Later I heard about L<Galileo>.
It basically used the same idea, mojolicious backend, browser for the frontend. So I stopped 
playing games and rolled my sleeves to focus on Pedro.

Later I discovered Pedro was not a good name for my project. So I chose Farabi for
L<Al-Farabi|http://en.wikipedia.org/wiki/Al-Farabi> who was a renowned scientist and philosopher
of the Islamic Golden Age. He was also a cosmologist, logician,and musician.

=head1 SUPPORT

If you find a bug, please report it in:

L<https://github.com/azawawi/farabi/issues>

If you find this module useful, please rate it in:

L<http://cpanratings.perl.org/d/Farabi>

=head1 AUTHORS

Ahmad M. Zawawi E<lt>ahmad.zawawi@gmail.comE<gt>

=head1 CONTRIBUTORS

Kevin Dawson E<lt>bowtie@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2013 by Ahmad M. Zawawi

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
