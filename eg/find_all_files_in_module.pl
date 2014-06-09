#!/usr/bin/env perl

use Modern::Perl;
use Method::Signatures;
use ElasticSearch;
use Data::Printer;

func find_files_in_module($module) {

	sub es {
		return ElasticSearch->new(
			no_refresh => 1,
			servers => 'api.metacpan.org',
			#trace_calls => \*STDOUT,
		);
	}

	my $latest = es()->search(
		index  => 'v0',
		type   => 'release',
		fields => [ 'name' ],
		size   => 1,
		query  => {
			filtered => {
				query  => { match_all => {} },
				filter => {
					and => [
						{ term => { 'release.status' => 'latest' } },
						{   terms => {
								'release.distribution' =>
									[ $module ]
							},
						},
					],
				},
			},
		},
	);

	my @releases = map { $_->{fields} } @{ $latest->{hits}->{hits} };
	die "Invalid release count: $#releases" if scalar @releases != 1;
	p @releases;
	my $release = $releases[0]->{name};

	my $files = es()->search(
		index => 'v0',
		type => 'file',
		size => 5000,
		query => {
			filtered => {
				query => { match_all => {} },
				filter => {
					bool => {
						must => {
							term => { 'file.release' => $release },
						},
						must_not => { term => { 'file.directory' => 'true' }, },
					},
				},
			},
		},
	);

	my @files = sort map { $_->{_source}->{path} } @{ $files->{hits}->{hits} };
	return \@files;
}

#p find_files_in_module('Farabi');
#p find_files_in_module('Moose');
#p find_files_in_module('Mojolicious');
p find_files_in_module('Dancer');
