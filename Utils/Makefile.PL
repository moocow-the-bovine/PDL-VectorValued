use PDL::Core::Dev;
use ExtUtils::MakeMaker;
require "../pdlmaker.plm";
PDL::Core::Dev->import();

$package = ['utils.pd','Utils','PDL::VectorValued::Utils'];
%hash = pdlmaker_init($package);

$hash{AUTHOR}         = 'Bryan Jurish';
$hash{VERSION_FROM}   = '../VectorValued/Version.pm',
$hash{PREREQ_PM}{PDL} = '2.4.2'; ##-- ensure PDL-ability
#push(@{$hash{LIBS}}, '-lm');     ##-- ?
#$hash{INC} .= '';
#$hash{OBJECT} .= '';
$hash{DIR} = [];
$hash{realclean}{FILES} .= '*~ *.tmp README.txt';

WriteMakefile(%hash);
