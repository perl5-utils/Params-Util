#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use File::Spec::Functions ':ALL';

# Check their perl version
ok( $] >= 5.004, "Your perl is new enough" );

# Does the module load
use_ok('Params::Util');

# Double check that Scalar::Util is valid
require_ok( 'Scalar::Util' );
ok( $Scalar::Util::VERSION >= 1.14, 'Scalar::Util version is at least 1.14' );
ok( defined &Scalar::Util::refaddr, 'Scalar::Util has a refaddr implementation' );

exit(0);
