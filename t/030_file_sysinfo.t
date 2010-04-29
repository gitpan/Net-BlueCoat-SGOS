#!/usr/bin/perl
#
#
use strict;
use Net::BlueCoat::SGOS;
use Test::More;
use Data::Dumper;

BEGIN { chdir 't' if -d 't' }

my %testparams;

opendir(D, "sysinfos/");
my @files = readdir(D);

my $totaltests = 0;
foreach my $file (@files) {
	if ($file =~ m/\.parameters$/ ) {
		open(F, "<sysinfos/$file");
		while(<F>){
			my $line = $_;
			chomp($line);
			my @s = split(/;/, $line);
			if ($#s < 2) { next }
			if ($s[0] && $s[1] && $s[2]) {
				$testparams{$s[0]}{$s[1]} = $s[2];
			}
		}
		close F;
	}
}

#calculate tests
foreach (keys %testparams) {
	my $sgosversion = $_;
	my %data          = %{$testparams{$sgosversion}};
	$totaltests = $totaltests + 3;
	$totaltests = $totaltests + (keys %data);
	print "totaltests=$totaltests\n";
}

plan tests => $totaltests;

foreach (keys %testparams) {
	my $version       = $_;
	my %data          = %{$testparams{$version}};
	note("Subtest for SGOS $version");
#	subtest "sysinfo $version test" => sub {
#		plan tests => $totalsubtests;
		my $bc = Net::BlueCoat::SGOS->new('debuglevel' => 0);

		# test 1 - do we have an object
		ok($bc, 'have an object');

		# test 2 - can we get a sysinfo from file
		ok($bc->get_sysinfo_from_file("sysinfos/$version.sysinfo"), 'got sysinfo from file');

		# test 3 - is the size of the sysinfo greater than 10
		ok(length($bc->{'_sgos_sysinfo'}) > 10, 'sysinfo size gt 10');

		#print "Dumper bc=" . Dumper($bc);

		foreach (sort keys %data) {
			my $k     = $_;
			my $value = $data{$k};

			if ($k =~ m/int-/) {
				my ($interface, $configitem) = $k =~ m/int-(.+)-(.+)/;
				ok($bc->{'interface'}{$interface}{$configitem} eq $value,
					"expected ($value), got ($bc->{'interface'}{$interface}{$configitem})");
			}
			else {
				my $got = $bc->{$k};
				ok($bc->{$k} eq $value, "$k: expected ($value), got ($bc->{$k})");
			}
		}
#	  }
}

