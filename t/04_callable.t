#!/usr/bin/perl -w

# Testing for _CALLABLE

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
}

use Test::More;
use Scalar::Util qw(blessed reftype);
use overload;

sub  c_ok { ok(   _CALLABLE($_[0]), "callable: $_[1]"     ) }
sub nc_ok { ok( ! _CALLABLE($_[0]), "not callable: $_[1]" ) }

my @callables = (
  "callable itself"                         => \&_CALLABLE,
  "a boring plain code ref"                 => sub {},
  'an object with overloaded &{}'           => C::O->new,
  'a object build from a coderef'           => C::C->new,
  'an object with inherited overloaded &{}' => C::O::S->new, 
  'a coderef blessed into CODE'             => (bless sub {} => 'CODE'),
);

my @uncallables = (
  "undef"                                   => undef,
  "a string"                                => "a string",
  "a number"                                => 19780720,
  "a ref to a ref to code"                  => \(sub {}),
  "a boring plain hash ref"                 => {},
  'a class that builds from coderefs'       => "C::C",
  'a class with overloaded &{}'             => "C::O",
  'a class with inherited overloaded &{}'   => "C::O::S",
  'a plain boring hash-based object'        => UC->new,
  'a non-coderef blessed into CODE'         => (bless {} => 'CODE'),
);

plan tests => (@callables + @uncallables) / 2 + 3;

# Import the function
use_ok( 'Params::Util', '_CALLABLE' );
ok( defined *_CALLABLE{CODE}, '_CALLABLE imported ok' );

my $warnings = 0;
my $expected = (scalar(@callables) + scalar(@uncallables)) / 2;
local $SIG{__WARN__} = sub {
	$warnings++;
	return;
};

while ( @callables ) {
  my ($name, $object) = splice @callables, 0, 2;
  c_ok($object, $name);
}

while ( @uncallables ) {
  my ($name, $object) = splice @uncallables, 0, 2;
  nc_ok($object, $name);
}

is( $warnings, $expected, 'Caught the expected number of warnings' );





# callable: is a blessed code ref
package C::C;
sub new { bless sub {} => shift; }





# callable: overloads &{}
# but!  only objects are callable, not class
package C::O;
sub new { bless {} => shift; }
use overload '&{}'  => sub { sub {} };
use overload 'bool' => sub () { 1 };





# callable: subclasses C::O
package C::O::S;
use base 'C::O';





# uncallable: some boring object with no codey magic
package UC;
sub new { bless {} => shift; }
