#!/usr/bin/perl

use lib qw#../lib #;
use Data::Dumper;
use Net::BlueCoat::SGOS;

my $bc = Net::BlueCoat::SGOS->new('debuglevel' => 0,);

my $file = $ARGV[0] || '../t/sysinfos/5.3.1.4.sysinfo';

$bc->get_sysinfo_from_file($file);

print "$bc->{'appliance-name'};$bc->{'modelnumber'};$bc->{'serialnumber'};$bc->{'sgosversion'};$bc->{'sgosreleaseid'}\n";

