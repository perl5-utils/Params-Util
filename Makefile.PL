use inc::Module::Install;

name          'Params-Util';
abstract      'Utility funcions to aid in parameter checking';
author        'Adam Kennedy <cpan@ali.as>';
version_from  'lib/Params/Util.pm';
license       'perl';

requires      'perl'             => '5.005';
requires      'Scalar::Util'     => '1.11';

build_requires 'Test::More'       => '0.47';
build_requires 'File::Spec'       => '0.82';

auto_install;

WriteAll;
