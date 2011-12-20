use ExtUtils::MakeMaker;

#@MY::pdpm = qw(Utils/Utils.pm);
require "pdlmaker.plm";
pdlmaker_init();

WriteMakefile(
	      NAME         => 'PDL::VectorValued',
	      VERSION_FROM => 'VectorValued/Version.pm',
	      ABSTRACT     => 'Assorted utilities for vector-valued PDLs',
	      AUTHOR       => 'Bryan Jurish',
	      PREREQ_PM => {
			    PDL => '2.4.2', ##-- ensure PDL-ability
			   },
	      realclean => {
			    FILES => '*~ *.tmp README.txt',
			   },
	     );
