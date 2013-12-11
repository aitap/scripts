#!/usr/bin/perl
use feature 'say';
use warnings;
use strict;
use WWW::Mechanize;
use URI;
use JSON 'decode_json';

my $m = WWW::Mechanize::->new(autocheck => 1);

for my $arg (@ARGV) {
	my $hash = {URI::->new($arg)->query_form}->{hash};
	$m->get($arg);
	my $key = $m->post("http://disk.yandex.ru/secret-key.jsx")->decoded_content;
	my $ans = $m->post("http://disk.yandex.ru/handlers.jsx", {
		_ckey => $key,
		_name => 'getLinkFileDownload',
		hash => $hash
	})->decoded_content;
	say decode_json($ans)->{data}{url};
}
