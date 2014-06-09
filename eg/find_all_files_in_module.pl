#!/usr/bin/env perl

use Modern::Perl;
use Data::Printer;
use ElasticSearch;

sub es {
    return ElasticSearch->new(
        no_refresh => 1,
        servers => 'api.metacpan.org',
        #trace_calls => \*STDOUT,
    );
}

#TODO get release name from http://api.metacpan.org/v0/release/Farabi

my $files = es()->search(
    index => 'v0',
    type => 'file',
    size => 300,
    query => {
        filtered => {
            query => { match_all => {} },
            filter => {
                bool => {
                    must => {
                        term => { 'file.release' => 'Farabi-0.47' },
                    },
                    must_not => { term => { 'file.directory' => 'true' }, },
                },
            },
        },
    },
);

my @files = sort map { $_->{_source}->{path} } @{ $files->{hits}->{hits} };
p @files;
