#!/usr/bin/perl -w

# Compile testing for Params::Util

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
}

use Test::More tests => 3;

# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Does the module load
use_ok('Params::Util');

# Check for refaddr
ok( defined &Scalar::Util::refaddr, 'Scalar::Util has a refaddr implementation' );

exit(0);
