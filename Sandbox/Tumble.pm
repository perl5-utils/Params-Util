package Sandbox::Tumble;

use strict;
use warnings;

use Cwd        qw();
use File::Spec qw();
use Test::WriteVariants 0.014;

use FindBin qw();

$| = 1;

sub tumble
{
    my ($class, $output_dir) = @_;

    my $template_dir = Cwd::abs_path(File::Spec->catdir($FindBin::RealBin, "t"));
    my $test_writer  = Test::WriteVariants->new();
    $test_writer->allow_dir_overwrite(1);
    $test_writer->allow_file_overwrite(1);

    $test_writer->write_test_variants(
        input_tests => $test_writer->find_input_inline_tests(
            search_patterns => ["*.t"],
            search_dirs     => ["t/inline"],
        ),
        variant_providers => ["PU::TestVariants"],
        output_dir        => $output_dir,
    );
}

package PU::TestVariants::Backend;

use strict;
use warnings;

sub provider
{
    my ($self, $path, $context, $tests, $variants) = @_;
    my $strict   = $context->new_module_use(strict   => [qw(subs vars refs)]);
    my $warnings = $context->new_module_use(warnings => ['all']);

    $variants->{pp} = $context->new(
        $context->new_env_var(
            PERL_PARAMS_UTIL_PP => 1,
        ),
        $warnings,
        $strict,
    );
    $variants->{xs} = $context->new(
        $context->new_env_var(
            PERL_PARAMS_UTIL_PP => 0,
        ),
        $warnings,
        $strict,
    );
}

1;
