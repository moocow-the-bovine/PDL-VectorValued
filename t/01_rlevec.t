# -*- Mode: CPerl -*-
# t/01_rlevec.t: test rlevec/rldvec

$TEST_DIR = './t';
#use lib qw(../blib/lib ../blib/arch); $TEST_DIR = '.'; # for debugging

# load common subs
use Test;
do "$TEST_DIR/common.plt";
use PDL;
use PDL::VectorValued;

BEGIN { plan tests=>17, todo=>[]; }
my ($tmp);

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

## 5..5: test enumvecg
$pk = enumvecg($p);
isok("enumvecg()", all($pk==pdl([0,0,0,1,1,2])));


##--------------------------------------------------------------
## rleND, rldND: 2d

## 6..7: test rleND(): 2d
($pf,$pv) = rleND($p);
isok("rleND():2d:counts", all($pf==$pf_expect));
isok("rleND():2d:elts",   all($pv==$pv_expect));

## 8..8: test rldND(): 2d
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
($tmp=$pv_expect_nd->slice(",,0:3")) .= $p_nd->dice_axis(-1,[0,3,5,6]);

## 9..10: test rleND(): Nd
($pf_nd,$pv_nd) = rleND($p_nd);
isok("rleND():Nd:counts", all($pf_nd==$pf_expect_nd));
isok("rleND():Nd:elts",   all($pv_nd==$pv_expect_nd));

## 11..11: test rldND(): Nd
$pd_nd = rldND($pf_nd,$pv_nd);
isok("rldND():Nd", all($pd_nd==$p_nd));

##--------------------------------------------------------------
## 12..12: test enumvec(): nd
our $v_nd = $p_nd->clump(2);
our $k_nd = $v_nd->enumvec();
isok("enumvec():Nd", all($k_nd==pdl([0,1,2,0,1,0,0])));

##--------------------------------------------------------------
## 13..17: test rldseq(), rleseq()
my $lens = pdl(long,[qw(3 0 1 4 2)]);
my $offs = (($lens->xvals+1)*100)->short;
my $seqs = null->short;
$seqs  = $seqs->append(sequence($_)) foreach ($lens->list);
$seqs += $lens->rld($offs);

my $seqs_got = $lens->rldseq($offs);
isok("rldseq():type", $seqs_got->type==$seqs->type);
isok("rldseq():data", all($seqs_got==$seqs));

my ($len_got,$off_got) = $seqs->rleseq();
isok("rleseq():type", $off_got->type==$seqs->type);
isok("rleseq():lens",  all($len_got->where($len_got)==$lens->where($lens)));
isok("rleseq():offs",  all($off_got->where($len_got)==$offs->where($lens)));

print "\n";
# end of t/01_rlevec.t

