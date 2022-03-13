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

BEGIN {
  use Test::More;
  use File::Basename;
  use Cwd;
  our ($TEST_DIR);
  $TEST_DIR = Cwd::abs_path dirname( __FILE__ ).'/t';
  eval qq{use lib ("$TEST_DIR/$_/blib/lib","$TEST_DIR/$_/blib/arch");} foreach (qw(..));
  do "$TEST_DIR/common.plt" or die("$0: failed to load $TEST_DIR/common.plt: $@");
}

##---------------------------------------------------------------------
## test: set ops

sub test_setops_data {
  our $universe = pdl(long,[ [0,0],[0,1],[1,0],[1,1] ]);
  our $v1 = $universe->dice_axis(1,pdl([0,1,2]));
  our $v2 = $universe->dice_axis(1,pdl([1,2,3]));
}

sub test_setops {
  test_setops_data();
  our ($c,$nc,$cc);

  ($c,$nc) = $v1->vv_union($v2);
  isok("vv_union:list:c",  all($c==pdl([ [0,0],[0,1],[1,0],[1,1],[0,0],[0,0] ])));
  isok("vv_union:list:nc", $nc==$universe->dim(1));
  $cc = $v1->vv_union($v2);
  isok("vv_union:scalar", all($cc==$universe));

  ($c,$nc) = $v1->vv_intersect($v2);
  isok("vv_intersect:list:c", all($c==pdl([ [0,1],[1,0],[0,0] ])));
  isok("vv_intersect:list:nc", $nc==$v1->dim(1));
  $cc = $v1->vv_intersect($v2);
  isok("vv_intersect:scalar", all($cc==$universe->slice(",1:2")));

  ($c,$nc) = $v1->vv_setdiff($v2);
  isok("vv_setdiff:list:c", all($c==pdl([ [0,0], [0,0],[0,0] ])));
  isok("vv_setdiff:list:nc", $nc==1);
  $cc = $v1->vv_setdiff($v2);
  isok("vv_setdiff:scalar", all($cc==pdl([[0,0]])));
}
#test_setops;


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
#test_vsearchvec();

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
#test_cmpvec;


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
#test_rlevec;

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
#test_rle_nd();

##---------------------------------------------------------------------
## github issue #1
## + https://github.com/moocow-the-bovine/PDL-VectorValued/issues/4
#  + see https://stackoverflow.com/questions/54905561/perl-pdl-search-if-a-vector-is-in-an-array-or-in-a-matrix/71446817#71446817

sub vv_in {
  require PDL::VectorValued::Utils;
  my ($needle, $haystack) = @_;
  die "needle must have 1 dim less than haystack"
    if $needle->ndims != $haystack->ndims - 1;
  my $ign = $needle->dummy(1)->zeroes;
  PDL::_vv_intersect_int($needle->dummy(1), $haystack, $ign, my $nc=PDL->null);
  return $nc;
}

sub test_intersect_mowhawk() {
  *vv_intersect = \&PDL::vv_intersect;
  my $toto = pdl([1,2,3], [4,5,6]);
  my $titi = pdl(1,2,3);
  my $notin = pdl(7,8,9);
  my $titi1 = $titi->dummy(1);
  my $notin1 = $notin->dummy(1);

  pdlok("titi&toto", $c=vv_intersect($titi, $toto), pdl([[1,2,3]]));
  #Empty[3x0] [0] # wrong - the built-in broadcasting engine would insert a dim of 1, you need to mimic that

  pdlok('notin&toto', $c=vv_intersect($notin, $toto), zeroes(3,0));
  # Empty[3x0] [0] # right

  pdlok("titi1&toto", $c=vv_intersect($titi->dummy(1), $toto), pdl([[1,2,3]]));
  # right

  pdlok("notin1&toto", $c=vv_intersect($notin->dummy(1), $toto), zeroes(3,0));
  # [[0 0 0]] # this should be empty

  ##----

  # now we want to know whether each needle is "in" one by one, not really
  # a normal intersect, so we insert a dummy in haystack in order to broadcast
  # the "nc" needs to come back as a 4x2
  #my $needles8 = pdl([[1,2,3],[9,9,9]])->slice(",*4,"); # 3x4x2 : fake
  my $needles8 = pdl( [[[1,2,3],[4,5,6],[8,8,8],[8,8,8]],
		       [[4,5,6],[9,9,9],[1,2,3],[9,9,9]]]); # 3x4x2

  # need to manipulate above into suitable inputs for intersect to get right output
  # + dummy dim here also ensures singleton query-vector-sets are (trivially) sorted
  my $needles8x = $needles8->slice(",*1,,"); # 3x*x4x2 # dummy of size 1 inserted in dim 1

  # haystack: no changes needed; don't need same number of dims, broadcast engine will add dummy/1s at top
  my $haystack = pdl([[1,2,3],[4,5,6]]); # 3x2
  my $haystack8 = $haystack;
  my $c_want8 = [
		 [[[1,2,3]],[[4,5,6]],[[0,0,0]],[[0,0,0]]],
		 [[[4,5,6]],[[0,0,0]],[[1,2,3]],[[0,0,0]]],
		];
  my $nc_want8 = [[1,1,0,0],
		  [1,0,1,0]];

  my ($c, $nc) = vv_intersect($needles8x, $haystack8);
  pdlok('needles8x&haystack - result', $c, $c_want8);
  pdlok('needles8x&haystack - counts', $nc, $nc_want8);


  print "what now?\n";
}
test_intersect_mowhawk();

##----------------------------------------------
## dimcheck: vv_union

sub test_union_dimcheck {
  $, = ' ';
  my $wx   = sequence(3,2)+1;
  my $wxyz = sequence(3,4)+1;
  print scalar($wx->vv_union($wxyz)), "\n";

  my $tu = -$wx;
  print scalar($tu->vv_union($wxyz)), "\n";

  my $tuwx = $tu->glue(1,$wx);
  print scalar($tuwx->vv_union($wxyz)), "\n";

  my $empty = zeroes(3,0);
  print scalar($empty->vv_union($wxyz)), "\n";
  print scalar($wxyz->vv_union($empty)), "\n";
  print scalar($empty->vv_union($empty)), "\n";

  my $k = 2;
  my $wx_k = $wx->slice(",,*$k");
  print scalar($wx_k->vv_union($wxyz)), "\n";

  my $tu_k = $tu->slice(",,*$k");
  print scalar($tu_k->vv_union($wxyz)), "\n";

  my $tuwx_k = $tuwx->slice(",,*$k");
  print scalar($tuwx_k->vv_union($wxyz)), "\n";
}
test_union_dimcheck();


##----------------------------------------------
## dimcheck: vv_intersect

sub test_intersect_dimcheck1 {
  $, = ' ';
  my $needle = sequence(3)+1;
  my $haystack = sequence(3,4)+1;
  print scalar($needle->slice(",*1")->vv_intersect($haystack)), "\n";

  my $noneedle = -$needle;
  print scalar($noneedle->slice(",*1")->vv_intersect($haystack)), "\n";

  my $needles = $haystack->dice_axis(1,[0,3]);
  print scalar($needles->vv_intersect($haystack)), "\n";

  my $noneedles = -$needles;
  print scalar($noneedles->vv_intersect($haystack)), "\n";

  my $nontriv = $needle->cat($noneedle);
  print scalar($nontriv->vv_intersect($haystack)), "\n";

  my $k = 2;
  my $needlek = $needle->slice(",*1,*$k");
  print scalar($needlek->vv_intersect($haystack)), "\n";

  my $needlesk = $needles->slice(",,*$k");
  print scalar($needlesk->vv_intersect($haystack)), "\n";

  my $nontrivk = $needles->glue(2,$nontriv);
  print scalar($nontrivk->vv_intersect($haystack)), "\n";

}
test_intersect_dimcheck1();


##----------------------------------------------
## dimcheck: vv_setdiff

sub test_vvdiff_dimcheck {
  $, = ' ';
  my $needle = sequence(3)+1;
  my $haystack = sequence(3,4)+1;
  print scalar($haystack->vv_setdiff($needle->slice(",*1"))), "\n";

  my $noneedle = -$needle;
  print scalar($haystack->vv_setdiff($noneedle->slice(",*1"))), "\n";

  my $needles = $haystack->dice_axis(1,[0,3]);
  print scalar($haystack->vv_setdiff($needles)), "\n";

  my $noneedles = -$needles;
  print scalar($haystack->vv_setdiff($noneedles)), "\n";

  my $nontriv = $needle->cat($noneedle);
  print scalar($haystack->vv_setdiff($nontriv)), "\n";

  my $k = 2;
  my $kneedle = $needle->slice(",*1,*$k");
  my $khaystack = $haystack->slice(",,*$k");
  print scalar($khaystack->vv_setdiff($kneedle)), "\n";

  my $kneedles = $needles->slice(",,*$k");
  print scalar($khaystack->slice->vv_setdiff($kneedles)), "\n";

  my $knontriv = $needles->glue(2,$nontriv);
  print scalar($khaystack->vv_setdiff($knontriv)), "\n";
}
test_vvdiff_dimcheck();



##----------------------------------------------
## dimcheck: v_union

sub test_vsetops_dimcheck {
  $, = ' ';

  # data: base
  my $empty = zeroes(0);
  my $v1_2 = pdl([1,2]);
  my $v3_4 = pdl([3,4]);
  my $v1_4 = $v1_2->cat($v3_4)->flat;

  # data: threaded
  my $k = 2;
  my $kempty = $empty->slice(",*$k");
  my $kv1_2 = $v1_2->slice(",*$k");
  my $kv3_4 = $v3_4->slice(",*$k");
  my $kv1_4 = $v1_4->slice(",*$k");

  if (1) {
    # v_union
    print scalar($v1_2->v_union($v3_4)), "\n";
    print scalar($v1_2->v_union($v1_4)), "\n";
    print scalar($v3_4->v_union($v1_4)), "\n";
    print scalar($empty->v_union($v1_4)), "\n";
    print scalar($empty->v_union($empty)), "\n";

    print scalar($kv1_2->v_union($v3_4)), "\n";
    print scalar($kv1_2->v_union($v1_4)), "\n";
    print scalar($kv3_4->v_union($v1_4)), "\n";
    print scalar($kempty->v_union($v1_4)), "\n";
    print scalar($kempty->v_union($empty)), "\n";
  }

  if (1) {
    # v_intersect
    print scalar($v1_2->v_intersect($v3_4)), "\n";
    print scalar($v1_2->v_intersect($v1_4)), "\n";
    print scalar($v3_4->v_intersect($v1_4)), "\n";
    print scalar($empty->v_intersect($v1_4)), "\n";
    print scalar($empty->v_intersect($empty)), "\n";

    print scalar($kv1_2->v_intersect($v3_4)), "\n";
    print scalar($kv1_2->v_intersect($v1_4)), "\n";
    print scalar($kv3_4->v_intersect($v1_4)), "\n";
    print scalar($kempty->v_intersect($v1_4)), "\n";
    print scalar($kempty->v_intersect($empty)), "\n";
  }

  if (1) {
    # v_setdiff
    print scalar($v1_2->v_setdiff($v3_4)), "\n";
    print scalar($v1_2->v_setdiff($v1_4)), "\n";
    print scalar($v3_4->v_setdiff($v1_4)), "\n";
    print scalar($empty->v_setdiff($v1_4)), "\n";
    print scalar($empty->v_setdiff($empty)), "\n";

    print scalar($kv1_2->v_setdiff($v3_4)), "\n";
    print scalar($kv1_2->v_setdiff($v1_4)), "\n";
    print scalar($kv3_4->v_setdiff($v1_4)), "\n";
    print scalar($kempty->v_setdiff($v1_4)), "\n";
    print scalar($kempty->v_setdiff($empty)), "\n";
  }
}
test_vsetops_dimcheck;



##---------------------------------------------------------------------
## DUMMY
##---------------------------------------------------------------------
foreach $i (0..3) {
  print "--dummy($i)--\n";
}

