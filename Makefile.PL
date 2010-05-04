use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	($ExtUtils::MakeMaker::VERSION >= 6.18
		? (MM->can('signature_target') ? (SIGN => 1) : ())
		: ()),
	NAME          => 'Net::BlueCoat::SGOS',
	AUTHOR        => q{Matthew Lange <mmlange@cpan.org>},
	VERSION_FROM  => 'lib/Net/BlueCoat/SGOS.pm',
	ABSTRACT_FROM => 'lib/Net/BlueCoat/SGOS.pm',
	(
		$ExtUtils::MakeMaker::VERSION >= 6.3002
		? ('LICENSE' => 'gpl')
		: ()
	),
	PL_FILES  => {},
	PREREQ_PM => {
		'Test::More'           => '0',
		'LWP::UserAgent'       => '5.8.3.1',
		'LWP::Protocol::https' => '0',
	},
	dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
	clean => {FILES    => 'Net-BlueCoat-SGOS-*'},
);
