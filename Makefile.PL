use inc::Module::Install;

name           'Params-Util';
all_from       'lib/Params/Util.pm';
requires       'Scalar::Util'     => '1.11';
build_requires 'Test::More'       => '0.47';
build_requires 'File::Spec'       => '0.80';

auto_install;
WriteAll;
