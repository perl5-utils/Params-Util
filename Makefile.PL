use inc::Module::Install 0.74;

all_from      'lib/Params/Util.pm';
requires      'Scalar::Util' => '1.18';
test_requires 'Test::More'   => '0.42';
test_requires 'File::Spec'   => '0.80';

WriteAll;
