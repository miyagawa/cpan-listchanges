
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "list changes for CPAN modules",
  "dist_author" => [
    "Tatsuhiko Miyagawa <miyagawa\@bulknews.net>"
  ],
  "dist_name" => "cpan-listchanges",
  "dist_version" => "0.06",
  "license" => "perl",
  "module_name" => "cpan::listchanges",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Algorithm::Diff" => 0,
    "CPAN::DistnameInfo" => 0,
    "LWP" => 0,
    "Module::Metadata" => 0,
    "Pod::Usage" => 0,
    "Try::Tiny" => 0,
    "YAML" => 0,
    "perl" => "5.008001"
  },
  "script_files" => [
    "script/cpan-listchanges"
  ],
  "test_requires" => {
    "Test::More" => "0.88",
    "Test::Requires" => 0
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
