#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 30;
use File::Spec::Functions ':ALL';
BEGIN {
	ok( ! defined &_DRIVER, '_HANDLE does not exist' );
	use_ok('Params::Util', qw(_DRIVER));
	ok( defined &_DRIVER, '_HANDLE imported ok' );
}

# Import refaddr to make certain we have it
use Scalar::Util 'refaddr';





#####################################################################
# Preparing

my $A = catfile( 't', 'driver', 'A.pm' );
ok( -f $A, 'A exists' );
my $B = catfile( 't', 'driver', 'B.pm' );
ok( -f $B, 'B exists' );
my $C = catfile( 't', 'driver', 'C.pm' );
ok( ! -f $C, 'C does not exist' );
my $D = catfile( 't', 'driver', 'D.pm' );
ok( -f $D, 'D does not exist' );
my $E = catfile( 't', 'driver', 'E.pm' );
ok( -f $E, 'E does not exist' );
my $F = catfile( 't', 'driver', 'F.pm' );
ok( -f $F, 'F does not exist' );

unshift @INC, catdir( 't', 'driver' );

	



#####################################################################
# Things that are not file handles

foreach (
	undef, '', ' ', 'foo bar', 1, 0, -1, 1.23,
	[], {}, \'', bless( {}, "foo" )
) {
	is( _DRIVER($_, 'A'), undef, 'Non-driver returns undef' );
}





#####################################################################
# Sample Classes

# The base class itself is not a driver
is( _DRIVER('A', 'A'), undef, 'A: Driver base class is undef' );
ok( $A::VERSION, 'A: Class is loaded ok' );
is( _DRIVER('B', 'A'), 'B',   'B: Good driver returns ok' );
is( _DRIVER('B', 'H'), undef, 'B: Good driver return undef for incorrect base' );
ok( $B::VERSION, 'B: Class is loaded ok' );
is( _DRIVER('C', 'A'), undef, 'C: Non-existant driver is undef' );
is( _DRIVER('D', 'A'), undef, 'D: Broken driver is undef' );
is( _DRIVER('E', 'A'), undef, 'E: Not a driver returns undef' );
is( _DRIVER('F', 'A'), 'F',   'F: Faked isa returns ok' );
