# -*- Mode: CPerl -*-
# t/01_rlevec.t: test rlevec/rldvec

$TEST_DIR = './t';
#use lib qw(../blib/lib ../blib/arch); $TEST_DIR = '.'; # for debugging

# load common subs
use Test;
do "$TEST_DIR/common.plt";
use PDL;
use PDL::VectorValued;

BEGIN { plan tests=>11, todo=>[]; }

##--------------------------------------------------------------
## rlevec(), rldvec(): 2d ONLY

## 1..2: test rlevec()
$p = pdl([[1,2],[1,2],[1,2],[3,4],[3,4],[5,6]]);

($pf,$pv)  = rlevec($p);
$pf_expect = pdl([3,2,1,0,0,0]);
$pv_expect = pdl([[1,2],[3,4],[5,6],[0,0],[0,0],[0,0]]);

isok("rlevec():counts",  all($pf==$pf_expect));
isok("rlevec():elts", all($pv==$pv_expect));

## 3..3: test rldvec()
$pd = rldvec($pf,$pv);
isok("rldvec()", all($pd==$p));

## 4..4: test enumvec
$pk = enumvec($p);
isok("enumvec()", all($pk==pdl([0,1,2,0,1,0])));

##--------------------------------------------------------------
## rleND, rldND: 2d

## 5..6: test rleND(): 2d
($pf,$pv) = rleND($p);
isok("rleND():2d:counts", all($pf==$pf_expect));
isok("rleND():2d:elts",   all($pv==$pv_expect));

## 7..7: test rldND(): 2d
$pd = rldND($pf,$pv);
isok("rldND():2d", all($pd==$p));

##--------------------------------------------------------------
## rleND, rldND: Nd

our $pnd1 = (1  *(sequence(long, 2,3  )+1))->slice(",,*3");
our $pnd2 = (10 *(sequence(long, 2,3  )+1))->slice(",,*2");
our $pnd3 = (100*(sequence(long, 2,3,2)+1));
our $p_nd = $pnd1->mv(-1,0)->append($pnd2->mv(-1,0))->append($pnd3->mv(-1,0))->mv(0,-1);

our $pf_expect_nd = pdl(long,[3,2,1,1,0,0,0]);
our $pv_expect_nd = zeroes($p_nd->type, $p_nd->dims);
$pv_expect_nd->slice(",,0:3") .= $p_nd->dice_axis(-1,[0,3,5,6]);

## 8..9: test rleND(): Nd
($pf_nd,$pv_nd) = rleND($p_nd);
isok("rleND():Nd:counts", all($pf_nd==$pf_expect_nd));
isok("rleND():Nd:elts",   all($pv_nd==$pv_expect_nd));

## 10..10: test rldND(): Nd
$pd_nd = rldND($pf_nd,$pv_nd);
isok("rldND():Nd", all($pd_nd==$p_nd));

##--------------------------------------------------------------
## 11..11: test enumvec(): nd
our $v_nd = $p_nd->clump(2);
our $k_nd = $v_nd->enumvec();
isok("enumvec():Nd", all($k_nd==pdl([0,1,2,0,1,0,0])));

print "\n";
# end of t/01_rlevec.t

