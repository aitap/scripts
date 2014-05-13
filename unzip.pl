#!/usr/bin/perl
use warnings;
use strict;
use Encode qw(decode encode);
use Encode::Locale;
use Encode::Detect;
use Archive::Zip 'AZ_OK';

print STDERR <<"BANNER";
Unzip.pl by AITap, 2013
Published under GPLv3+ or The "Artistic License"
BANNER

die "Usage: $0 <file.zip> [another file.zip] ...\n" unless @ARGV;

for my $fname (@ARGV) {
	my $zip = Archive::Zip::->new($fname) or die "$fname: $!";
	for my $member ($zip->members) {
		my $name = $member->fileName;
		print encode locale => decode ascii => $name, Encode::FB_PERLQQ;
		my $target = encode locale => (do {
			my $ans;
			for (qw/locale Detect cp866/) {
				$ans = eval { decode $_, $name, Encode::FB_CROAK } and last;
			}
			$ans;
		} || eval { decode ascii => $name, Encode::FB_PERLQQ });
		print "\t$target\n";
		TRY: {
			($_ = $zip->extractMember($member, $target)) == AZ_OK and last TRY;
			if ($! == 36) { # file name too long
				my ($ext) = $target =~ /(\.[^.]+)$/;
				substr($target,255-length($ext))=$ext;
				redo;
			} # other errors here
			# TODO: IO::Prompt to ask what to do?
			die $_;
		}
	}
}
