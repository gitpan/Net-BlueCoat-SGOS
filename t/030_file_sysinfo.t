#!/usr/bin/perl
#
#
use strict;
use Net::BlueCoat::SGOS;
use Test::More;
no warnings;

BEGIN { chdir 't' if -d 't' }

my %testparams;
my $osregex = $ARGV[0];

opendir(D, "sysinfos/");
my @files = readdir(D);

my $totaltests = 0;
foreach my $file (@files) {
	if ($file =~ m/\.parameters$/) {
		open(F, "<sysinfos/$file");
		while (<F>) {
			my $line = $_;
			chomp($line);
			my @s = split(/;/, $line);
			if ($#s < 1) { next }
			if ($osregex) {
				if ($s[0] !~ /$osregex/) { next }
			}
			$testparams{$s[0]}{$s[1]} = $s[2];
		}
		close F;
	}
}

#calculate tests
foreach (keys %testparams) {
	my $sgosversion = $_;
	my %data        = %{$testparams{$sgosversion}};
	$totaltests = $totaltests + 3;
	$totaltests = $totaltests + (keys %data);
}

plan tests => $totaltests;

foreach (keys %testparams) {
	my $version = $_;
	my %data    = %{$testparams{$version}};
	note("Begin SGOS $version");
	my $bc = Net::BlueCoat::SGOS->new('debuglevel' => 0);

	# test 1 - do we have an object
	ok($bc, 'have an object');

	# test 2 - can we get a sysinfo from file
	ok($bc->get_sysinfo_from_file("sysinfos/$version.sysinfo"), 'got sysinfo from file');

	# test 3 - is the size of the sysinfo greater than 10
	ok(length($bc->{'_sgos_sysinfo'}) > 10, 'sysinfo size gt 10');

	foreach (sort keys %data) {
		my $k     = $_;
		my $value = $data{$k};

		if ($k =~ m/int-/) {
			my ($interface, $configitem) = $k =~ m/int-(.+)-(.+)/;
			ok($bc->{'interface'}{$interface}{$configitem} eq $value,
				"expected $interface $configitem ($value), got ($bc->{'interface'}{$interface}{$configitem})");
		}
		elsif ($k =~ m/length-/) {
			my ($var) = $k =~ m/length-(.+)/;
			my $length = length($bc->{$var});
			ok($length == $value, "length($var), expected ($value), got ($length)");
		}
		else {
			ok($bc->{$k} eq $value, "$k: expected ($value), got ($bc->{$k})");
		}
	}
	note("End SGOS $version");
}

