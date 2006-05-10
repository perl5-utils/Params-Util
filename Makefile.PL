use inc::Module::Install;

name           'Params-Util';
all_from       'lib/Params/Util.pm';
requires       'Exporter'     => 0;
requires       'Exporter'     => 0;
requires       'Scalar::Util' => '1.11';
build_requires 'Test::More'   => '0.42';
build_requires 'File::Spec'   => '0.80';

WriteAll;
