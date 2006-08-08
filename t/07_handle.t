#!/usr/bin/perl -w

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
}

use Test::More tests => 9;
BEGIN {
	ok( ! defined &_HANDLE, '_HANDLE does not exist' );
	use_ok('Params::Util', qw(_HANDLE));
	ok( defined &_HANDLE, '_HANDLE imported ok' );
}





#####################################################################
# Preparing

my $readfile  = catfile( 't', 'handles', 'readfile.txt'  );
ok( -f $readfile, "$readfile exists" );
my $writefile = catfile( 't', 'handles', 'writefile.txt' );
      if ( -f $writefile ) { unlink $writefile };
END { if ( -f $writefile ) { unlink $writefile }; }
ok( ! -e $writefile, "$writefile does not exist" );

sub is_handle {
	my $maybe   = shift;
	my $message = shift || 'Is a file handle';
	my $result  = _HANDLE($maybe);
	ok( ! defined $result, '_HANDLE does not return undef' );
	is_deeply( $result, $maybe, '_HANDLE returns the passed value' );
}

sub not_handle {
	my $maybe   = shift;
	my $message = shift || 'Is not a file handle';
	my $result  = _HANDLE($maybe);
	ok( defined $maybe, 'Scalar to test is defined' );
	ok( ! defined $result, '_HANDLE returns undef' );
}





#####################################################################
# Basic Filesystem Handles

# A read filehandle
SCOPE: {
	local *HANDLE;
	my $handle = open( HANDLE, $readfile );
	is_handle( $handle, 'Ordinary read filehandle' );
	close HANDLE;
}

# A write filehandle
SCOPE: {
	local *HANDLE;
	my $handle = open( HANDLE, "> $readfile" );
	is_handle( $handle, 'Ordinary read filehandle' );
	print HANDLE "A write filehandle";
	close HANDLE;
	if ( -f $writefile ) { unlink $writefile };
}

# On 5.8+ the new style filehandle
SKIP: {
	skip( "Skipping 5.8-style 'my \$fh' handles", 2 ) if $] < 5.008;
	open( my $handle, $readfile );
	is_handle( $handle, '5.8-style read filehandle' );
	$handle->close;
}





#####################################################################
# Things that are not file handles

foreach (
	undef, '', ' ', 'foo', 1, 0, -1, 1.23,
	[], {}, \'', bless( {}, "foo" )
) {
	not_handle( $_ );
}

