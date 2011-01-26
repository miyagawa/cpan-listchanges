use inc::Module::Install;
name 'cpan-listchanges';
all_from 'lib/App/cpanlistchanges.pm';
readme_from('lib/App/cpanlistchanges.pm');
install_script 'bin/cpan-listchanges';
requires 'Algorithm::Diff';
requires 'LWP';
requires 'CPAN::DistnameInfo';
requires 'Module::Metadata';
requires 'YAML';
requires 'Try::Tiny';

build_requires 'Test::More', 0.88;
test_requires 'Test::Requires';
auto_set_repository();
WriteAll;
