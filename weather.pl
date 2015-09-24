#!/usr/bin/perl
use warnings;
use strict;
# HTTP client
use HTTP::Tiny;
# XML reader
use XML::Simple;
# calculate what day it will be 12 hours later
#use Date::Calc 'Add_Delta_DHMS';
# decode strings from XML
use Encode 'decode';
use URI::Escape 'uri_unescape';
# encode to system locale
use Encode::Locale;
use utf8;

my $place_id = 27612;
my $url = "http://informer.gismeteo.ru/xml/${place_id}_1.xml";

my $data = XMLin(HTTP::Tiny::->new->get($url)->{content}) or die "Failed to download or parse $url";

#my ($year, $month, $day, $hour, $minute, $second) = (localtime)[5,4,3,2,1,0];
#$year += 1900; $month+=1;
#($year, $month, $day, $hour, $minute, $second) = Add_Delta_DHMS(
#	$year, $month, $day, $hour, $minute, $second,
#	0, 12, 0, 0
#);

## tod is 0 for night, 1 for morning, 2 for day, 3 for evening
##my $tod = int($hour/8); # int(0..23 / 8) = 0..3
#my $tod = 1; # forecast for morning only;
#
#my $forecast = (
#	sort {
#		0+!($a->{tod} == $tod) # first look for the TOD we want
#		or $a->{hour} <=> $b->{hour} # otherwise, get the earliest one
#	} grep {
#		$_->{day} == $day
#		and $_->{month} == $month
#		and $_->{year} == $year
#	} @{$data->{REPORT}{TOWN}{FORECAST}}
#)[0]
#	or die "Could not find the forecast for $year-$month-$day\n";

binmode STDOUT, ":encoding(locale)";

my %phenomena = (
	cloudiness => {name => "облачность", 0 => "ясно", 1 => "малооблачно", 2 => "облачно", 3 => "пасмурно"},
	precipitation => {name => "осадки", 4 => "дождь", 5 => "ливень", 6 => "снег", 7 => "снег", 8 => "гроза", 9 => "нет данных", 10 => "без осадков"},
	rpower => {0 => "возможны осадки", 1 => "будут осадки"},
	spower => {0 => "возможна гроза", 1 => "будет гроза"},
);
my @wind = (qw(N NE E SE S SW W NW));

print "Прогноз для: ", decode(cp1251 => uri_unescape($data->{REPORT}{TOWN}{sname})), ", широта $data->{REPORT}{TOWN}{latitude}, долгота $data->{REPORT}{TOWN}{longitude}\n";
for my $forecast (@{$data->{REPORT}{TOWN}{FORECAST}}) {
	printf "на %04d-%02d-%02d, местное время %02d, заблаговременность %d\n", $forecast->{year}, $forecast->{month}, $forecast->{day}, $forecast->{hour}, $forecast->{predict};
	
	for (qw(cloudiness precipitation)) {
		print " $phenomena{$_}{name}: ", ($phenomena{$_}{$forecast->{PHENOMENA}{$_}} // "неправильный код прогноза"), "\n";
	}
	print " $phenomena{rpower}{$forecast->{PHENOMENA}{rpower}}\n" unless $forecast->{PHENOMENA}{precipitation} == 10;
	print " $phenomena{spower}{$forecast->{PHENOMENA}{spower}}\n" if $forecast->{PHENOMENA}{precipitation} == 8;
	
	print " давление: $forecast->{PRESSURE}{min}..$forecast->{PRESSURE}{max} мм.рт.ст.\n";
	print " температура: ",
		"$forecast->{TEMPERATURE}{min}..$forecast->{TEMPERATURE}{max}°C, ",
		"комфорт $forecast->{HEAT}{min}..$forecast->{HEAT}{max}°C\n";
	
	print " ветер: $wind[$forecast->{WIND}{direction}], $forecast->{WIND}{min}..$forecast->{WIND}{max} м/с\n";
	
	print " влажность воздуха: $forecast->{RELWET}{min}..$forecast->{RELWET}{max}%\n";
}
