# This is intended to be equivalent to the Module::Install version below

use 5.00503;
use ExtUtils::MakeMaker;
use Config;

for (@ARGV) {
    /^-pm/ and $no_xs = 1;
    /^-xs/ and $no_xs = 0;
}

sub init {
    my $hash = $_[1];
    if ($no_xs) {
	@{$hash}{XS,C} = ( {}, [] );
    }
    $hash;
}

sub no_cc {
    $no_xs = 1;
    print <<"EDQ";

I cannot determine if you have a C compiler
so I will install a perl-only implementation

You can force installation of the XS version with

perl Makefile.PL -xs

EDQ
    write_makefile();
    exit;
}

sub write_makefile {
	WriteMakefile(
		# We created out own META.yml
		NO_META       => 1,
		NAME          => 'Params::Util',
		VERSION_FROM  => 'lib/Params/Util.pm',
		PREREQ_PM     => {
			'Scalar::Util' => '1.18',
			'Test::More'   => '0.42',
			'File::Spec'   => '0.80',
		},

		ABSTRACT_FROM => 'lib/Params/Util.pm', 
		AUTHOR	      => 'Adam Kennedy <adamk@cpan.org>',

		# otherwise 'cxinc' isn't defined
		DEFINE	      => '-DPERL_EXT', 
		CONFIGURE     => \&init,
		clean         => { FILES => 'test.c' }
	);
}

write_makefile();

exit if defined $no_xs;

print "Testing if you have a C compiler\n";

open F, ">test.c" or no_cc();
print F "int main() { return 0; }\n";
close F or no_cc();
system ("$Config{make} test$Config{obj_ext}") and no_cc();

#use inc::Module::Install 0.74;

#all_from      'lib/Params/Util.pm';
#requires      'Scalar::Util' => '1.18';
#test_requires 'Test::More'   => '0.42';
#test_requires 'File::Spec'   => '0.80';

#WriteAll;
