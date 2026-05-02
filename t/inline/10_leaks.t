#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN
{
    eval { require Test::LeakTrace; 1 }
      or plan skip_all => "Test::LeakTrace required for leak testing";
    Test::LeakTrace->import;
}

use Params::Util qw(
  _STRING _IDENTIFIER _CLASS _NUMBER _POSINT _NONNEGINT
  _SCALAR _SCALAR0 _ARRAY _ARRAY0 _ARRAYLIKE
  _HASH _HASH0 _HASHLIKE _CODE _CODELIKE
  _REGEX _INVOCANT _INVOCANTCAN
  _CLASSISA _CLASSDOES _CLASSCAN _SUBCLASS
  _INSTANCE _INSTANCEDOES _INSTANCECAN
);

# Set up test classes
{

    package Leak::Foo;
    sub new { bless {}, shift }
    sub foo { 1 }
}
{

    package Leak::Bar;
    our @ISA = ('Leak::Foo');
}

my $obj = Leak::Foo->new;

# Group 1: String validators
no_leaks_ok { _STRING("hello") } '_STRING(valid) no leak';
no_leaks_ok { _STRING(undef) } '_STRING(undef) no leak';
no_leaks_ok { _IDENTIFIER("foo") } '_IDENTIFIER(valid) no leak';
no_leaks_ok { _IDENTIFIER("4bad") } '_IDENTIFIER(invalid) no leak';
no_leaks_ok { _CLASS("Foo::Bar") } '_CLASS(valid) no leak';
no_leaks_ok { _CLASS("4bad") } '_CLASS(invalid) no leak';

# Group 2: Numeric validators
no_leaks_ok { _NUMBER(42) } '_NUMBER(valid) no leak';
no_leaks_ok { _NUMBER("abc") } '_NUMBER(invalid) no leak';
no_leaks_ok { _POSINT(1) } '_POSINT(valid) no leak';
no_leaks_ok { _POSINT(0) } '_POSINT(zero) no leak';
no_leaks_ok { _NONNEGINT(0) } '_NONNEGINT(zero) no leak';
no_leaks_ok { _NONNEGINT(-1) } '_NONNEGINT(negative) no leak';

# Group 3: Class dispatchers (call_method path)
no_leaks_ok { _CLASSISA("Leak::Bar", "Leak::Foo") } '_CLASSISA(valid) no leak';
no_leaks_ok { _CLASSISA("Leak::Foo", "Leak::Bar") } '_CLASSISA(invalid) no leak';
no_leaks_ok { _CLASSISA("4bad",      "Leak::Foo") } '_CLASSISA(bad class) no leak';
no_leaks_ok { _CLASSDOES("Leak::Foo", "Leak::Foo") } '_CLASSDOES(valid) no leak';
no_leaks_ok { _CLASSDOES("Leak::Foo", "NoSuch") } '_CLASSDOES(invalid) no leak';
no_leaks_ok { _CLASSCAN("Leak::Foo", "foo") } '_CLASSCAN(valid) no leak';
no_leaks_ok { _CLASSCAN("Leak::Foo", "nope") } '_CLASSCAN(invalid) no leak';
no_leaks_ok { _SUBCLASS("Leak::Bar", "Leak::Foo") } '_SUBCLASS(valid) no leak';
no_leaks_ok { _SUBCLASS("Leak::Foo", "Leak::Foo") } '_SUBCLASS(same) no leak';

# Group 4: Instance dispatchers (call_method path)
no_leaks_ok { _INSTANCE($obj,     "Leak::Foo") } '_INSTANCE(valid) no leak';
no_leaks_ok { _INSTANCE($obj,     "NoSuch") } '_INSTANCE(invalid) no leak';
no_leaks_ok { _INSTANCE("notref", "Leak::Foo") } '_INSTANCE(non-ref) no leak';
no_leaks_ok { _INSTANCEDOES($obj, "Leak::Foo") } '_INSTANCEDOES(valid) no leak';
no_leaks_ok { _INSTANCEDOES($obj, "NoSuch") } '_INSTANCEDOES(invalid) no leak';
no_leaks_ok { _INSTANCECAN($obj, "foo") } '_INSTANCECAN(valid) no leak';
no_leaks_ok { _INSTANCECAN($obj, "nope") } '_INSTANCECAN(invalid) no leak';

# Group 5: Invocant dispatchers
no_leaks_ok { _INVOCANT($obj) } '_INVOCANT(object) no leak';
no_leaks_ok { _INVOCANT("Leak::Foo") } '_INVOCANT(class) no leak';
no_leaks_ok { _INVOCANT(undef) } '_INVOCANT(undef) no leak';
no_leaks_ok { _INVOCANTCAN($obj,        "foo") } '_INVOCANTCAN(obj valid) no leak';
no_leaks_ok { _INVOCANTCAN("Leak::Foo", "foo") } '_INVOCANTCAN(class valid) no leak';
no_leaks_ok { _INVOCANTCAN($obj,        "nope") } '_INVOCANTCAN(obj invalid) no leak';
no_leaks_ok { _INVOCANTCAN(undef,       "foo") } '_INVOCANTCAN(undef) no leak';

# Container types
no_leaks_ok { _SCALAR(\"hello") } '_SCALAR(valid) no leak';
no_leaks_ok { _SCALAR0(\"") } '_SCALAR0(valid) no leak';
no_leaks_ok { _ARRAY([1, 2, 3]) } '_ARRAY(valid) no leak';
no_leaks_ok { _ARRAY0([]) } '_ARRAY0(valid) no leak';
no_leaks_ok { _HASH({a => 1}) } '_HASH(valid) no leak';
no_leaks_ok { _HASH0({}) } '_HASH0(valid) no leak';
no_leaks_ok
{
    _CODE(sub { })
}
'_CODE(valid) no leak';
no_leaks_ok
{
    _CODELIKE(sub { })
}
'_CODELIKE(valid) no leak';
no_leaks_ok { _REGEX(qr//) } '_REGEX(valid) no leak';

done_testing;
