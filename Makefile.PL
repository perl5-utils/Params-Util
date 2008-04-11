use strict;
use inc::Module::Install;

name           'Params-Util';
perl_version   '5.005';
all_from       'lib/Params/Util.pm';
requires       'Exporter'     => 0;
requires       'Scalar::Util' => can_cc() ? '1.14' : '1.10';
test_requires 'Test::More'   => '0.42';
test_requires 'File::Spec'   => '0.80';

WriteAll;
