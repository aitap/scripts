#!/usr/bin/perl
use warnings;
use strict;
use 5.014;
# HTTP client
use HTTP::Tiny;
# XML reader
use XML::Simple;
# decode strings from XML
use Encode 'decode';
use URI::Escape 'uri_unescape';
# encode to system locale
use Encode::Locale;
# weather icons and degree sign
use utf8;
use charnames ':full';

my $place_id = $ARGV[0] // 27612;
my $url = "http://informer.gismeteo.ru/xml/${place_id}_1.xml";

my $data = XMLin(HTTP::Tiny::->new->get($url)->{content}) or die "Failed to download or parse $url";

binmode STDOUT, ":encoding(locale)";

my %phenomena = (
	cloudiness => {name => "облачность", 0 => "\N{BLACK SUN WITH RAYS}", 1 => "\x{1f324}", 2 => "\x{1f325}", 3 => "\N{CLOUD}"},
	precipitation => {name => "осадки", 4 => "\N{UMBRELLA}", 5 => "\N{UMBRELLA WITH RAIN DROPS}", 6 => "\N{SNOWFLAKE}", 7 => "\N{SNOWFLAKE}", 8 => "\x{1f329}", 9 => "?", 10 => " "},
	rpower => {0 => "\x{1f327}?", 1 => "\x{1f327}!"},
	spower => {0 => "\x{26c8}?", 1 => "\x{26c8}!"},
);


my @wind = (qw(N NE E SE S SW W NW));

print "Прогноз для: ", decode(cp1251 => uri_unescape($data->{REPORT}{TOWN}{sname})), ", широта $data->{REPORT}{TOWN}{latitude}, долгота $data->{REPORT}{TOWN}{longitude}\n";
for my $forecast (@{$data->{REPORT}{TOWN}{FORECAST}}) {
	printf "%04d-%02d-%02d:%02d", $forecast->{year}, $forecast->{month}, $forecast->{day}, $forecast->{hour}; #, $forecast->{predict};
	
	for (qw(cloudiness precipitation)) {
		print(" $phenomena{$_}{$forecast->{PHENOMENA}{$_}}" // "неправильный код прогноза");
	}
	print " $phenomena{rpower}{$forecast->{PHENOMENA}{rpower}}\n" unless $forecast->{PHENOMENA}{precipitation} == 10;
	print " $phenomena{spower}{$forecast->{PHENOMENA}{spower}}\n" if $forecast->{PHENOMENA}{precipitation} == 8;
	
	printf " %03d..%03d мм.рт.ст.", $forecast->{PRESSURE}{min}, $forecast->{PRESSURE}{max};
	printf ' %+02d..%+02d°C '."\N{RIGHTWARDS DOUBLE ARROW}".' %+02d..%+02d°C',
		$forecast->{TEMPERATURE}{min}, $forecast->{TEMPERATURE}{max},
		$forecast->{HEAT}{min}, $forecast->{HEAT}{max};
	
	print " $wind[$forecast->{WIND}{direction}] $forecast->{WIND}{min}..$forecast->{WIND}{max} м/с";
	
	print " $forecast->{RELWET}{min}..$forecast->{RELWET}{max}%";

	print "\n";
}
