#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 11;
use File::Spec::Functions ':ALL';
BEGIN {
	use_ok('Params::Util', qw(_INVOCANT));
}

my $object = bless \do { my $i } => 'Params::Util::Test::Bogus::Whatever';
my $false_obj1 = bless \do { my $i } => 0;
my $false_obj2 = bless \do { my $i } => "\0";
my $tied   = tie my $x, 'Params::Util::Test::_INVOCANT::Tied';
my $unpkg  = 'Params::Util::Test::_INVOCANT::Fake';
my $pkg    = 'Params::Util::Test::_INVOCANT::Real'; eval "package $pkg;"; ## no critic

my @data = (# I
  [ undef        , 0, 'undef' ],
  [ 1000        => 0, '1000' ],
  [ $unpkg      => 1, qq("$unpkg") ],
  [ $pkg        => 1, qq("$pkg") ],
  [ []          => 0, '[]' ],
  [ {}          => 0, '{}' ],
  [ $object     => 1, 'blessed reference' ],
  [ $false_obj1 => 1, 'blessed reference' ],
  [ $false_obj2 => 1, 'blessed reference' ],
  [ $tied       => 1, 'tied value' ],
);

for my $datum (@data) {
  is(
    _INVOCANT($datum->[0]) ? 1 : 0,
    $datum->[1],
    "$datum->[2] " . ($datum->[1] ? 'is' : "isn't") . " _IN"
  );
}

package Params::Util::Test::_INVOCANT::Tied;
sub TIESCALAR {
  my ($class, $value) = @_;
  return bless \$value => $class;
}
