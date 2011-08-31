use PDL::Core::Dev;
use ExtUtils::MakeMaker;
PDL::Core::Dev->import();

$package = ['utils.pd','Utils','PDL::VectorValued::Utils'];
%hash = pdlpp_stdargs($package);

$hash{AUTHOR}         = 'Bryan Jurish';
$hash{VERSION_FROM}   = '../VectorValued/Version.pm',
$hash{PREREQ_PM}{PDL} = '2.4.2'; ##-- ensure PDL-ability
#push(@{$hash{LIBS}}, '-lm');     ##-- ?
#$hash{INC} .= '';
#$hash{OBJECT} .= '';
$hash{DIR} = [];
$hash{realclean}{FILES} .= '*~ *.tmp README.txt';

##--
## hacks for CPAN indexer, part 1 of 2
##   + include PODs from PDL::PP-generated *.pm file to get docs on CPAN
##   + BUT unlink it here so that its presence doesn't clobber
##     the PDL::PP rules in postamble
$pkg = $package->[1]; ##-- package basename
unlink "$pkg.pm" if (-e "$pkg.pm");

WriteMakefile(%hash);

sub MY::depend {
  package MY;
  return shift->SUPER::depend(@_) .<<EOF;

dist: $::pkg.pm

distcheck: $::pkg.pm

create_distdir: $::pkg.pm

EOF
}

##--
## hacks for CPAN indexer, part 2 of 2
##   + sneak generated .pm file into the distribution
##   + keep it under the MANIFEST radar to avoid annoying warnings from ExtUtils::Manifest
##     on 'perl Makefile.PL'
sub MY::distdir {
  package MY;
  my $inherited = shift->SUPER::distdir(@_);
  $inherited =~ s/^(create_distdir\s*:.*\R(?:\t.*\R)*)/$1\t\$(CP) $::pkg.pm \$(DISTVNAME)\n/m;
  $inherited;
}

sub MY::postamble {
  pdlpp_postamble($package);
}
