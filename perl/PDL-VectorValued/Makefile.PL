use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME         => 'PDL::VectorValued',
	      VERSION_FROM => 'VectorValued/Version.pm',
	      ABSTRACT     => 'Assorted utilities for vector-valued PDLs',
	      AUTHOR       => 'Bryan Jurish <moocow@ling.uni-potsdam.de>',
	      PREREQ_PM => {
			    PDL => '2.4.2', ##-- ensure PDL-ability
			   },
	      realclean => {
			    FILES => '*~ *.tmp README.txt',
			   },
	     );

sub MY::depend {
  package MY;
  my $inherited = shift->SUPER::depend(@_);
  if (1) {
    $inherited .= (
		   "\n\n"
		   ."dist: README.txt\n"
		   ."\n"
		   ."create_distdir: README.txt\n"
		   ."\n"
		   ."distcheck: README.txt\n"
		   ."\n"
		   ."manicheck: README.txt\n"
		   ."\n"
		  );
  }
  $inherited;
}

sub MY::special_targets {
  package MY;
  my $inherited = shift->SUPER::special_targets(@_);
  $inherited .=
"
.SUFFIXES: .pm .pod .rpod .man .txt .html

.pm.html:
\tpod2html --outfile \$@ \$<

.pm.txt:
\tpod2text \$< \$@

.rpod.html:
\tpod2html --outfile \$@ \$<

.rpod.txt:
\tpod2text \$< \$@
";
  $inherited;
}


sub MY::top_targets {
  package MY;
  my $inherited = shift->SUPER::top_targets(@_);
  $inherited;
}
