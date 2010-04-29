#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::BlueCoat::SGOS' ) || print "Bail out!
";
}

diag( "Testing Net::BlueCoat::SGOS $Net::BlueCoat::SGOS::VERSION, Perl $], $^X" );
