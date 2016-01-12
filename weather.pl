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
	rpower => {0 => "?\x{1f327}", 1 => "!\x{1f327}"},
	spower => {0 => "?\x{26c8}", 1 => "!\x{26c8}"},
);


my @wind = (qw(N NE E SE S SW W NW));

print "Прогноз для: ", decode(cp1251 => uri_unescape($data->{REPORT}{TOWN}{sname})), ", широта $data->{REPORT}{TOWN}{latitude}, долгота $data->{REPORT}{TOWN}{longitude}\n";
for my $forecast (@{$data->{REPORT}{TOWN}{FORECAST}}) {
	printf '%04d-%02d-%02d:%02d %1s %1s %-2s%-2s %03d..%03d мм.рт.ст. %+3d..%+3d'."\N{RIGHTWARDS DOUBLE ARROW}".'%+3d..%+3d°C %-2s %-2d..%-2d м/с %-2d..%-2d%%'."\n",
		$forecast->{year}, $forecast->{month}, $forecast->{day}, $forecast->{hour}, # Y-m-d
		(map { "$phenomena{$_}{$forecast->{PHENOMENA}{$_}}" // "0" } (qw(cloudiness precipitation))), # one character both
		($forecast->{PHENOMENA}{precipitation} != 10 ? $phenomena{rpower}{$forecast->{PHENOMENA}{rpower}} : ""), # precipitation power, unless no precipitation
		($forecast->{PHENOMENA}{precipitation} == 8 ?  $phenomena{spower}{$forecast->{PHENOMENA}{spower}} : ""), # storm power; two characters but rare
		$forecast->{PRESSURE}{min}, $forecast->{PRESSURE}{max}, # %03d..%03d
		$forecast->{TEMPERATURE}{min}, $forecast->{TEMPERATURE}{max}, # temperature, %+02d x2
		$forecast->{HEAT}{min}, $forecast->{HEAT}{max},               # temp. as percieved, %+02d x2
		$wind[$forecast->{WIND}{direction}], $forecast->{WIND}{min}, $forecast->{WIND}{max}, # %-2s, %-2d..%-2d
		$forecast->{RELWET}{min}, $forecast->{RELWET}{max},
	;
}
