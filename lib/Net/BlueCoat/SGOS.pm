package Net::BlueCoat::SGOS;
use strict;
no warnings;
use Data::Dumper;
use LWP::UserAgent;

our %_URL = (
	'archconf_expanded'    => '/archconf_expanded.txt',
	'contentfilter_status' => '/ContentFilter/Status',
	'sysinfo'              => '/SYSINFO',
);

our %defaults = (
	'appliancehost'        => 'proxy',
	'applianceport'        => 8082,
	'applianceusername'    => 'admin',
	'appliancepassword'    => 'password',
	'applianceconnectmode' => 'https',
	'debuglevel'           => 0,
);

=head1 NAME

Net::BlueCoat::SGOS - A module to interact with Blue Coat SGOS-based devices.

=head1 VERSION

Version 0.90

=cut

our $VERSION = '0.90';

=head1 SYNOPSIS

This module interacts with Blue Coat SGOS-based devices.  Right
now, this is limited to parsing of the 'sysinfo' data from the
device.


	use strict; #always!
	use Net::BlueCoat::SGOS;
	my $bc = Net::BlueCoat::SGOS->new(
		'appliancehost'		=> 'swg.example.com',
		'applianceport'		=> 8082,
		'applianceuser'		=> 'admin',
		'appliancepassword'	=> 'password'
	);
	$bc->login();
	# or
	# my $bc = Net::BlueCoat::SGOS->new();
	# $bc->get_sysinfo_from_file('/path/to/file.sysinfo');

	my $sgosversion = $bc->{'sgosversion'};
	my $sgosreleaseid = $bc->{'sgosreleaseid'};
	my $serialnumber = $bc->{'serialnumber'};
	my $modelnumber = $bc->{'modelnumber'};
	my $sysinfotime = $bc->{'sysinfotime'};

	# Hardware section of the sysinfo file
	my $hwinfo = $bc->{'sgos_sysinfo_sect'}{'Hardware Information'};

	# Software configuration (i.e. show configuration)
	my $swconfig = $bc->{'sgos_sysinfo_sect'}{'Software Configuration'};



=head1 SUBROUTINES/METHODS

Below are methods for Net::BlueCoat::SGOS.
=cut

=head2 new

Creates a new Net::BlueCoat::SGOS object.  Can be passed one of the following:

	appliancehost
	applianceport
	applianceusername
	appliancepassword
	applianceconnectmode (one of http or https)
	debuglevel


=cut

sub new {
	my $class = shift;
	my $self  = {};
	bless($self, $class);
	my %args = (%defaults, @_);

	$self->{'_appliancehost'}     = $args{'appliancehost'};
	$self->{'_applianceport'}     = $args{'applianceport'};
	$self->{'_applianceusername'} = $args{'applianceusername'};
	$self->{'_appliancepassword'} = $args{'appliancepassword'};
	$self->{'_connectmode'}       = $args{'applianceconnectmode'};
	$self->{'_debuglevel'}        = $args{'debuglevel'};

	$self->{'_lwpua'} = LWP::UserAgent->new();
	$self->{'_lwpua'}->agent("Net::BlueCoat/$VERSION");

	return $self;
}

=head2 login

Logs into the Blue Coat appliance using the parameters given when
constructed.

=cut

sub login {
	my $self = shift;
	my %args = (%defaults, @_);
	if (!$self->{'_appliancehost'}) {
		$self->{'_appliancehost'} = $args{'appliancehost'};
	}
	if (!$self->{'_applianceport'}) {
		$self->{'_applianceport'} = $args{'applianceport'};
	}
	if (!$self->{'_applianceusername'}) {
		$self->{'_applianceusername'} = $args{'applianceusername'};
	}
	if (!$self->{'_appliancepassword'}) {
		$self->{'_appliancepassword'} = $args{'appliancepassword'};
	}
	if (!$self->{'_applianceconnectmode'}) {
		$self->{'_applianceconnectmode'} = $args{'applianceconnectmode'};
	}
	if (!$self->{'_debuglevel'}) {
		$self->{'_debuglevel'} = $args{'debuglevel'};
	}

	if (   $self->{'_appliancehost'}
		&& $self->{'_applianceport'}
		&& $self->{'_applianceconnectmode'}
		&& $self->{'_applianceusername'}
		&& $self->{'_appliancepassword'}) {
		if ($self->{'_applianceconnectmode'} eq 'https') {
			$self->{'_applianceurlbase'} = q#https://# . $self->{'_appliancehost'} . q#:# . $self->{'_applianceport'};
		}
		elsif ($self->{'_applianceconnectmode'} eq 'http') {
			$self->{'_applianceurlbase'} = q#http://# . $self->{'_appliancehost'} . q#:# . $self->{'_applianceport'};
		}
		$self->{'_lwpnetloc'} = $self->{'_appliancehost'} . q/:/ . $self->{'_applianceport'};

		if ($self->{'_debuglevel'} > 0) {
			print 'connecting to ' . $self->{'_applianceurlbase'} . "\n";
			print 'lwpnetloc=' . $self->{'_lwpnetloc'} . "\n";
		}
		my $response = $self->{'_lwpua'}->get($self->{'_applianceurlbase'});
		my $rawrealm = $response->header('www-authenticate');
		($self->{'_appliancerealm'}) = $rawrealm =~ m/realm=\"(.*)\"$/isx;
		if ($self->{'_debuglevel'} > 0) {
			print 'rawrealm=' . $rawrealm . "\n";
			print 'appliancerealm=' . $self->{'_appliancerealm'} . "\n";
			print 'applianceusername=' . $self->{'_applianceusername'} . "\n";
			print 'appliancepassword=' . $self->{'_appliancepassword'} . "\n";
			print "passed to credentials:\n";
			print $self->{'_lwpnetloc'} . "\n";
			print $self->{'_appliancerealm'} . "\n";
			print $self->{'_applianceusername'} . "\n";
			print $self->{'_appliancepassword'} . "\n";
		}
		$self->{'_lwpua'}->credentials(
			$self->{'_lwpnetloc'},
			$self->{'_appliancerealm'},
			$self->{'_applianceusername'},
			$self->{'_appliancepassword'}
		);

	}
	my $r = $self->_get_sysinfo();
	if (!defined($r)) {
		return undef;
	}
	else {
		return 1;
	}
}

=head2 get_sysinfo_from_file

Takes one parameter: the filename of a sysinfo file on the disk.  Use this
instead of logging in over the network.

	$bc->get_sysinfo_from_file('sysinfo.filename.here');

=cut

sub get_sysinfo_from_file {
	my $self     = shift;
	my $filename = shift;
	if ($self->{'_debuglevel'} > 0) {
		print "sub:get_sysinfo_from_file, filename=$filename\n";
	}
	if (-f $filename) {
		open(FSDFLKFJ, '<' . $filename);

		# slurp
		{
			local $/ = undef;
			$self->{'_sgos_sysinfo'} = <FSDFLKFJ>;
		}
		close FSDFLKFJ;

		#$self->{'_sgos_sysinfo'} = `head -4000 "$filename"`;

		if ($self->{'_sgos_sysinfo'}) {

			# remove CR+LF
			$self->{'_sgos_sysinfo'} =~ s/\r\n/\n/gi;
			my $r = $self->_parse_sysinfo();
			if ($r) {

				# yes, if data
				return 1;
			}
			else {
				return undef;
			}
		}
		else {
			return undef;
		}
	}
	else {

		# no filename specified
		return undef;
	}

}

sub _get_sysinfo {
	my $self = shift;
	if ($self->{'_debuglevel'} > 0) {
		print 'Getting ' . $self->{'_applianceurlbase'} . $_URL{'sysinfo'} . "\n";
	}
	my $r = $self->{'_lwpua'}->get($self->{'_applianceurlbase'} . $_URL{'sysinfo'});
	if ($r->is_error) {
		return undef;
	}
	else {
		$self->{'_sgos_sysinfo'} = $r->content;
		if ($self->{'_debuglevel'} > 0) {
			print 'status=' . $r->status_line . "\n";

			#print 'sysinfo=' . $r->content . "\n";
		}
	}
	if ($self->{'_sgos_sysinfo'}) {

		# remove CR+LF
		$self->{'_sgos_sysinfo'} =~ s/\r\n/\n/gi;
		my $r = $self->_parse_sysinfo();
		if ($r) {
			return 1;
		}
		else {
			return undef;
		}
	}
	else {
		return undef;
	}
}

sub _parse_sysinfo {
	my $self = shift;
	if ($self->{'_debuglevel'} > 0) {
		print "_parse_sysinfo\n";
	}
	my @split_sysinfo =
	  split(/__________________________________________________________________________/, $self->{'_sgos_sysinfo'});
	$self->{'_sgos_sysinfo_split_count'} = $#split_sysinfo;

	# init the % var
	$self->{'sgos_sysinfo_sect'}{'_ReportInfo'} = $split_sysinfo[0];
	foreach (1 .. $#split_sysinfo) {
		my $chunk = $split_sysinfo[$_];
		my @section = split(/\n/, $chunk);
		chomp @section;

		# the first 2 lines are junk
		shift @section;
		shift @section;
		my $sectionname = shift @section;

		if ($sectionname eq 'Software Configuration') {

			# get rid of 3 lines from top and 1 from bottom
			shift @section;
			shift @section;
			shift @section;
			pop @section;
		}
		if ($sectionname eq 'TCP/IP Routing Table') {
			shift @section;
			shift @section;
			shift @section;
			shift @section;
			shift @section;
		}

		# throw away the next line, it contains the URL for the source data
		shift @section;
		my $data = join("\n", @section);
		$self->{'sgos_sysinfo_sect'}{$sectionname} = $data;
	}

	# parse  SGOS version, SGOS releaseid, and serial number
	if ($self->{'_debuglevel'} > 0) {
		print "VERSION INFO SECTION:\n";
		print $self->{'sgos_sysinfo_sect'}{'Version Information'} . "\n";
	}

	# SGOS version
	# #Version Information
	# URL_Path /SYSINFO/Version
	# Blue Coat Systems, Inc., ProxySG Appliance Version Information
	# Version: SGOS 4.2.10.1
	#
	($self->{'sgosversion'}) = $self->{'sgos_sysinfo_sect'}{'Version Information'} =~ m/Version:\sSGOS\s(\d+\.\d+\.\d+\.\d+)/im;
	if ($self->{'_debuglevel'} > 0) {
		print "SGOS version = $self->{'sgosversion'}\n";
	}

	# SGOS release ID
	($self->{'sgosreleaseid'}) = $self->{'sgos_sysinfo_sect'}{'Version Information'} =~ m/Release\sid:\s(\d+)/isx;

	# Serial number
	($self->{'serialnumber'}) = $self->{'sgos_sysinfo_sect'}{'Version Information'} =~ m/Serial\snumber\sis\s(\d+)/isx;

	# sysinfo time
	# time on this file
	# The current time is Mon Nov 23, 2009 18:48:38 GMT (SystemTime 438547718)
	# The current time is Sat Mar 7, 2009 16:57:30 GMT (SystemTime 415990650)
	#
	#
	($self->{'sysinfotime'}) = $self->{'sgos_sysinfo_sect'}{'Version Information'} =~ m/^The current time is (.+) \(/im;

	# model
	# Model: 200-B
	($self->{'modelnumber'}) = $self->{'sgos_sysinfo_sect'}{'Hardware Information'} =~ m/Model:\s(.+)/im;

	if ($self->{'sgos_sysinfo_sect'}{'Software Configuration'}) {
		my $r = $self->_parse_swconfig;
	}
	else {
		# e.g. probably a sysinfo-snapshot
		return undef;
	}
	
	# Find appliance-name
	# located in the Software Configuration
	# looks like:
	# appliance-name "ProxySG 210 4609077777"
	# limited to 127 characters
	# e.g.: % String exceeds allowed length (127)
	#
	(undef, $self->{'appliance-name'}) =
	$self->{'sgos_sysinfo_sect'}{'Software Configuration'} =~ m/(appliance-name|hostname) (.+)$/im;
	$self->{'appliance-name'} =~ s/^\"//;
	$self->{'appliance-name'} =~ s/\"$//;

	if ($self->{'_debuglevel'} > 0) {
		print "appliancename=$self->{'appliance-name'}\n";
	}

	# get network
	# Network:
	#   Interface 0:0: Bypass 10/100     with no link  (MAC 00:d0:83:04:ae:fc)
	#   Interface 0:1: Bypass 10/100     running at 100 Mbps full duplex (MAC 00:d0:83:04:ae:fd)
	my ($netinfo) = $self->{'sgos_sysinfo_sect'}{'Hardware Information'} =~ m/Network:(.+)Accelerators/ism;
	my @s = split(/\n/, $netinfo);
	chomp @s;
	foreach (@s) {
		my $line = $_;
		my ($interface) = $line =~ m/Interface\s+(.+)\:\s/im;
		my ($mac)       = $line =~ m/\(MAC\s(.+)\)/im;
		my ($running)   = $line =~ m/running\sat\s(.+)\s\(MAC/im;
		my $capabilities;

		#Interface 0:0: Intel Gigabit     running at 1 Gbps full duplex (MAC 00:e0:81:79:a5:1a)
		#Interface 2:0: Bypass 10/100/1000 with no link  (MAC 00:e0:ed:0b:67:e6)
		if ($line =~ m/running at/) {
			($capabilities) = $line =~ m/Interface\s$interface\:\s\w+(.+)\s+running at/;
		}
		if ($line =~ m/with no link/) {
			($capabilities) = $line =~ m/Interface\s$interface\:\s\w+(.+)\s+with no link/;
		}
		if ($capabilities) {
			$capabilities =~ s/\s+//ig;
		}
		if ($interface && $capabilities) {
			$self->{'interface'}{$interface}{'capabilities'} = $capabilities;
		}

		#print "Running=$running\n";
		if ($interface && $mac) {
			$self->{'interface'}{$interface}{'mac'} = $mac;
		}
		if ($interface && $running) {
			$self->{'interface'}{$interface}{'linkstatus'} = $running;
		}
		if ($interface && !$running) {
			$self->{'interface'}{$interface}{'linkstatus'} = 'no link';
		}

		#print "interface=$interface, mac=$mac\n";
	}

	# supplement from swconfig/networking
	#print "getting supplemental networking info\n";
	my @t = split(/\n/, $self->{'sgos_swconfig_section'}{'networking'});
	chomp @t;
	if ($#t < 2) {
		@t = split(/\n/, $self->{'sgos_sysinfo_sect'}{'Software Configuration'});
	}

	my $interface;
	my ($ip, $netmask);
	foreach (@t) {
		my $line = $_;

		#print "line=$line\n";
		if ($line =~ m/interface (.+)\;/i) {

			#print "line has interface in it, line=$line\n";
			($interface) = $line =~ m/^interface (\d+\:?\d*\.*\d*)/i;

			#print "found an interface, it is=$interface=\n";
		}

		# sgos4, ip address and subnet mask are on separate lines
		# sgos5, ip address and subnet mask are on SAME line
		if ($line =~ m/ip-address/) {

			($ip, $netmask) =
			  $line  =~ m/^ip-address *(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})*/i;
			$ip      =~ s/\s+//gi;
			$netmask =~ s/\s+//gi;

			#print "MATCHED ip=$ip, netmask=$netmask\n";
		}
		if ($line =~ m/subnet-mask/) {

			#print "line has subnet-mask in it, line=$line\n";
			#($netmask) = $line =~ m/^subnet-mask (.{1,3}\..{1,3}\..{1,3}\..{1,3})/i;
			($netmask) = $line =~ m/^subnet-mask *(.{1,3}\..{1,3}\..{1,3}\..{1,3})/i;
			$netmask =~ s/\s+//gi;

			#print "matched netmask=$netmask\n";
		}

		if (length($interface) > 1 && $ip && $netmask) {

			#print "===Got interface and ip and netmask...\n";
			#print "interface=$interface, ip=$ip, netmask=$netmask\n";
			$self->{'interface'}{$interface}{'ip'}      = $ip;
			$self->{'interface'}{$interface}{'netmask'} = $netmask;
			$interface                                  = undef;
			$ip                                         = undef;
		}

		#print "pm: interface 0:0 netmask = $self->{'interface'}{$interface}{'netmask'}\n";

	}

	# SSL Accelerators
	# looks like:
	# Accelerators: none
	# or
	# Accelerators:
	#  Internal: Cavium CN1010 Security Processor
	#  Internal: Cavium CN501 Security Processor
	#  Internal: Broadcom 5825 Security Processor
	#
	my ($acceleratorinfo) = $self->{'sgos_sysinfo_sect'}{'Hardware Information'} =~ m/(Accelerators\:.+)/ism;
	my @a = split(/\n/, $acceleratorinfo);

	#print "There are $#a lines\n";
	# if 1 line, then no SSL accelerator
	if ($#a == 0) {
		$self->{'ssl-accelerator'} = 'none';
	}
	if ($#a > 0) {
		($self->{'ssl-accelerator'}) = $a[1] =~ m/\s+(.+)/;
	}

	#	print "DEBUG: acceleratorinfo=$acceleratorinfo\n";
	#print "DEBUG: ssl-accelerator=$self->{'ssl-accelerator'}\n";

	my $r = $self->_parse_default_gateway();
	$r = $self->_parse_route_table();

	return 1;
}

sub _parse_swconfig {
	my $self = shift;
	if ($self->{'_debuglevel'} > 0) {
		print "_parse_swconfig\n";
	}
	my @split_swconfig =
	  split(/\n/, $self->{'sgos_sysinfo_sect'}{'Software Configuration'});

	# only applies to SGOS >5
	my $sectionname = '';
	foreach (1 .. $#split_swconfig) {
		my $line = $split_swconfig[$_];
		chomp $line;
		if ($line =~ m/!- BEGIN/) {
			($sectionname) = $line =~ m/!- BEGIN (.+)/;

			#print "sectionname begin=$sectionname\n";
		}
		elsif ($line =~ m/!- END/) {

			#			print "sectionname end=$sectionname\n";
			next;
		}
		else {
			$self->{'sgos_swconfig_section'}{$sectionname} = $self->{'sgos_swconfig_section'}{$sectionname} . $line . "\n";

		}

	}

	# on a 5.3.1.4 box:
	#inline policy vpm-cpl end-415990651-inline
	#inline policy vpm-xml end-415990651-inline

	# policy display varies per SGOS version
	if ($self->{'sgosversion'} =~ m/5.3.1.4/) {
		my ($endmarker) = $self->{'sgos_swconfig_section'}{'policy'} =~ m/inline\spolicy\svpm-cpl\send-(\d+)-inline/isx;

		#print "ENDMARKER=$endmarker\n";
		($self->{'cpl'}) =
		  $self->{'sgos_swconfig_section'}{'policy'} =~
		  m/inline\spolicy\svpm-cpl\send-$endmarker-inline(.+)end-$endmarker-inline\ninline\spolicy\svpm-xml/isx;
		($self->{'vpm-xml'}) =
		  $self->{'sgos_swconfig_section'}{'policy'} =~
		  m/\ninline\spolicy\svpm-xml\send-$endmarker-inline\n(.+)end-$endmarker-inline/isx;

		#print "CPL=" . $self->{'cpl'} . "\n";
		#print "ENDCPL\n";
		#print "xml=$self->{'vpm-xml'}\n";
		#print "endxml\n";
	}

	# get vpm
	# inline policy vpm
	#inline policy vpm end-451370228-inline end-451370228-inline-xmlA
	# cpl
	#end-451370228-inline
	# xml
	#end-451370228-inline-xml
	if ($self->{'sgosversion'} =~ m/5.4.\d.\d/) {
		my ($endmarker) = $self->{'sgos_swconfig_section'}{'policy'} =~ m/inline\spolicy\svpm\send-(\d+)-inline/isx;

		#print "ENDMARKER=$endmarker\n";
		($self->{'cpl'}) =
		  $self->{'sgos_swconfig_section'}{'policy'} =~
		  m/inline\spolicy\svpm\send-$endmarker-inline\send-$endmarker-inline-xml(.+)end-$endmarker-inline\n/isx;
		($self->{'vpm-xml'}) =
		  $self->{'sgos_swconfig_section'}{'policy'} =~ m/\nend-$endmarker-inline\n(.+)end-$endmarker-inline-xml/isx;

		#print "CPL=" . $self->{'cpl'} . "\n";
		#print "ENDCPL\n";
		#print "xml=$self->{'vpm-xml'}\n";
		#print "endxml\n";
	}

	# 4.x
	if ($self->{'sgosversion'} =~ m/4\.2\.\d\.\d/) {
		my ($endmarker) =
		  $self->{'sgos_sysinfo_sect'}{'Software Configuration'} =~ m/inline\spolicy\svpm-cpl\s\"end-(\d+)-inline\"/isx;
		($self->{'cpl'}) =
		  $self->{'sgos_sysinfo_sect'}{'Software Configuration'} =~
		  m/inline\spolicy\svpm-cpl\s\"end-$endmarker-inline\"(.+)end-$endmarker-inline\n/isx;

		($self->{'vpm-xml'}) =
		  $self->{'sgos_sysinfo_sect'}{'Software Configuration'} =~
		  m/inline\spolicy\svpm-xml\s\"end-$endmarker-inline\"(.+)end-$endmarker-inline\n/isx;
	}

}

sub _parse_default_gateway {
	my $self = shift;
	if ($self->{'_debuglevel'} > 0) {
	}

	my @s = split(/\n/, $self->{'sgos_swconfig_section'}{'networking'});
	chomp @s;
	if ($#s < 2) {
		@s = split(/\n/, $self->{'sgos_sysinfo_sect'}{'Software Configuration'});
	}
	foreach my $line (@s) {
		if ($line =~ m/ip-default-gateway/) {
			($self->{'ip-default-gateway'}) = $line =~ m/^ip-default-gateway +(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/;
		}
	}

}

sub _parse_route_table {
	my $self = shift;
	if ($self->{'_debuglevel'} > 0) {
	}

	#inline static-route-table "end-398382495-inline"
	#; IP-Address Subnet Mask Gateway
	#172.16.0.0 255.240.0.0 172.20.144.1
	#end-398382495-inline
	my @r;
	if ($self->{'sgos_sysinfo_sect'}{'TCP/IP Routing Table'}) {
		$self->{'routetable'} = $self->{'sgos_sysinfo_sect'}{'TCP/IP Routing Table'};
	}
	else {
		@r = split(/\n/, $self->{'sgos_sysinfo_sect'}{'Software Configuration'});
	}
	my $marker;
	foreach my $line (@r) {
		if ($line =~ m/inline static-route-table \"end-\d+-inline\"/i) {
			($marker) = $line =~ m/inline static-route-table \"end-(\d+)-inline\"/i;
		}
		if ($line =~ m/end-$marker-inline/) {
			$marker = undef;
		}
		if ($marker && $line !~ /$marker/i) {
			if ($line =~ m/^\s*?\;/) { next }
			if ($line =~
m/\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
			  ) {
				$self->{'static-route-table'} = $self->{'static-route-table'} . $line . "\n";
			}
		}
	}

}

=head2 Other Data

Other data that is directly accessible in the object:

	Appliance Name:   $bc->{'appliance-name'}
	Model Number:     $bc->{'modelnumber'}
	Serial Number:    $bc->{'serialnumber'}
	SGOS Version:     $bc->{'sgosversion'}
	Release ID:       $bc->{'sgosreleaseid'}
	Default Gateway:  $bc->{'ip-default-gateway'}

	The details for interface 0:0 are stored here:
		IP address:   $bc->{'interface'}{'0:0'}{'ip'} 
		Netmask:      $bc->{'interface'}{'0:0'}{'netmask'} 
		MAC address:  $bc->{'interface'}{'0:0'}{'mac'} 
		Link status:  $bc->{'interface'}{'0:0'}{'linkstatus'} 
		Capabilities: $bc->{'interface'}{'0:0'}{'capabilities'} 

	You can retrieve the interface names like this:
		my @interfaces = keys %{$bc->{'interface'}};

	The route table can	be retrieved as follows:
		$bc->{'sgos_sysinfo_sect'}{'TCP/IP Routing Table'}

	The static route table can be retrieved as follows:
		$bc->{'static-route-table'}

	The WCCP configuration can be retrieved as follows:
		$bc->{'sgos_sysinfo_sect'}{'WCCP Configuration'}


=cut


=head1 AUTHOR

Matthew Lange <mmlange@cpan.org>

=head1 BUGS

Please report any bugs or feature requests through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-BlueCoat-SGOS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::BlueCoat::SGOS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-BlueCoat-SGOS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-BlueCoat-SGOS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-BlueCoat-SGOS>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-BlueCoat-SGOS/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008-2010 Matthew Lange.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # End of Net::BlueCoat::SGOS

__DATA__

