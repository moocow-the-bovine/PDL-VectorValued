#!/usr/bin/perl -wd

use lib qw(./blib/lib ./blib/arch);
use PDL;
use PDL::VectorValued;

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
## test: vsearchvec

sub vsvec_data {
  our $which = pdl(long,[[0,0],[0,0],[0,1],[0,1],[1,0],[1,0],[1,1],[1,1]]);
  our $find  = $which->slice(",0:-1:2");
}

sub test_vsearchvec {
  vsvec_data();

  isok("vsearchvec():match", all($find->vsearchvec($which)==pdl([0,2,4,6])));
  isok("vsearchvev():<<",    pdl([-1,-1])->vsearchvec($which)==0);
  isok("vsearchvev():>>",    pdl([2,2])->vsearchvec($which)==$which->dim(1)-1);
}
test_vsearchvec();

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
## test: rlevec, rldvec

sub rlevec_data {
  our $p2d  = pdl([[1,2],[3,4],[1,3],[1,2],[3,3]]) if (!defined($p2d));
  #our $p2ds = $p2d->qsortvec;  ##-- broken in default PDL-2.4.3 (and debian <= 2.4.3-3)
  #our $p2duv = $p2d->uniqvec; ##-- also broken
  ##--
  our $p2ds = vv_qsortvec($p2d); ##-- workaround

  our $p  = $p2d;
  our $ps = $p2ds;
}
#rlevec_data();

sub test_rlevec {
  rlevec_data;
  our ($puf,$pur) = rlevec($ps);
  our $ps2        = rldvec($puf,$pur);
  isok("rlevec+rldvec", all($ps==$ps2));
}
test_rlevec;

##---------------------------------------------------------------------
## test: rlend, rldnd: perl wrappers for clump() + rlevec(), rldvec()

sub rlevec_data_nd {
  our $pnd1 = (1  *(sequence(long, 2,3  )+1))->slice(",,*3");
  our $pnd2 = (10 *(sequence(long, 2,3  )+1))->slice(",,*2");
  our $pnd3 = (100*(sequence(long, 2,3,2)+1));
  our $pnd  = $pnd1->mv(-1,0)->append($pnd2->mv(-1,0))->append($pnd3->mv(-1,0))->mv(0,-1);
  our $pnds = $pnd; ##-- pre-sorted
  our $p    = $pnd; ##-- alias
  our $ps   = $pnd; ##-- alias
}

sub test_rle_nd {
  ##-- base case   : ND methods should handle 2d data correctly: ok
  rlevec_data;
  our ($puf,$pur) = rleND($ps);
  our $ps2        = rldND($puf,$pur);
  isok("rleND+rldND/2d", all($ps==$ps2));

  ##-- general case: ND data
  rlevec_data_nd();
  ($puf,$pur) = rleND($ps);
  $ps2        = rldND($puf,$pur);
  isok("rleND+rldND/nd", all($ps==$ps2));
}
test_rle_nd();


##---------------------------------------------------------------------
## DUMMY
##---------------------------------------------------------------------
foreach $i (0..3) {
  print "--dummy($i)--\n";
}

