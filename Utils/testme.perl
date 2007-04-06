#!/usr/bin/perl -wd

use lib qw(./blib/lib ./blib/arch);
use PDL;
use PDL::VectorValued::Utils;

BEGIN {
  $, = ' ';
  our $eps=1e-6;
}

##---------------------------------------------------------------------
## utils: as for common.plt

sub isok {
  my ($lab,$test) = @_;
  print "$lab: ", ($test ? "ok" : "NOT ok"), "\n";
}

##---------------------------------------------------------------------
## test: cmpvec

sub cmpvec_data {
  our $vdim = 4;
  our $v1 = zeroes($vdim);
  our $v2 = pdl($v1);
  $v2->set(-1,1);
}

sub test_cmpvec {
  cmpvec_data();
  isok("cmpvec:1d:<",  $v1->cmpvec($v2)<0);
  isok("cmpvec:1d:>",  $v2->cmpvec($v1)>0);
  isok("cmpvec:1d:==", $v1->cmpvec($v1)==0);
}
test_cmpvec;


##---------------------------------------------------------------------
## DUMMY
##---------------------------------------------------------------------
foreach $i (0..3) {
  print "--dummy($i)--\n";
}

