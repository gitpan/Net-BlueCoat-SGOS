#!/usr/bin/perl
#
#
use strict;
use Net::BlueCoat::SGOS;
use Test::More;

# If we don't have environment variables, we can't test with a live box
my $env_available =
     $ENV{BC_HOST}
  && $ENV{BC_PORT}
  && $ENV{BC_CONNECTMODE}
  && $ENV{BC_USER}
  && $ENV{BC_PASS};

if ( ! defined($env_available) ) {
	plan skip_all	=>	'author tests only',
}
else {
	plan tests	=>	8;
	# test 3 can create an object
	my $bc = Net::BlueCoat::SGOS->new(
		'appliancehost'        => $ENV{BC_HOST},
		'applianceport'        => $ENV{BC_PORT},
		'applianceconnectmode' => $ENV{BC_CONNECTMODE},
		'applianceusername'    => $ENV{BC_USER},
		'appliancepassword'    => $ENV{BC_PASS},
		'debuglevel'           => 0,
	);
	ok($bc, 'can create an object');

	# test 4 log in
	ok($bc->login(), 'log in to appliance');

	# test 5 sysinfo size gt 10
	my $sysinfosize = length($bc->{'_sgos_sysinfo'});
	ok($sysinfosize > 10);

	# Test 4
	like($bc->{'sgosversion'}, qr/\d+\.\d+\.\d+\.\d+/);

	# Test 5
	like($bc->{'sgosreleaseid'}, qr/\d+/);

	like($bc->{'serialnumber'}, qr/\d+/);

	like($bc->{'modelnumber'}, qr/\d+/);
	
	ok($bc->{'appliance-name'});
}

