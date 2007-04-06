# -*- Mode: CPerl -*-
# t/02_rlevec.t: test cmpvec, vv_qsortvec, vsearchvec

$TEST_DIR = './t';
#use lib qw(../blib/lib ../blib/arch); $TEST_DIR = '.'; # for debugging

# load common subs
use Test;
do "$TEST_DIR/common.plt";
use PDL;
use PDL::VectorValued;

BEGIN { plan tests=>8, todo=>[]; }

##--------------------------------------------------------------
## cmpvec

## 1..3: test cmpvec
our $vdim = 4;
our $v1 = zeroes($vdim);
our $v2 = pdl($v1);
$v2->set(-1,1);

isok("cmpvec:1d:<",  $v1->cmpvec($v2)<0);
isok("cmpvec:1d:>",  $v2->cmpvec($v1)>0);
isok("cmpvec:1d:==", $v1->cmpvec($v1)==0);


##--------------------------------------------------------------
## qsortvec, qsortveci

##-- 4..5: qsortvec, qsortveci
our $p2d  = pdl([[1,2],[3,4],[1,3],[1,2],[3,3]]);

isok("vv_qsortvec", all($p2d->vv_qsortvec==pdl([[1,2],[1,2],[1,3],[3,3],[3,4]])));
isok("qsortveci",   all($p2d->dice_axis(1,$p2d->qsortveci)==$p2d->vv_qsortvec));

##--------------------------------------------------------------
## vsearchvec

##-- 6..8: vsearchvec
our $which = pdl(long,[[0,0],[0,0],[0,1],[0,1],[1,0],[1,0],[1,1],[1,1]]);
our $find  = $which->slice(",0:-1:2");

isok("vsearchvec():match", all($find->vsearchvec($which)==pdl([0,2,4,6])));
isok("vsearchvev():<<",    all(pdl([-1,-1])->vsearchvec($which)==0));
isok("vsearchvev():>>",    all(pdl([2,2])->vsearchvec($which)==$which->dim(1)-1));

print "\n";
# end of t/02_cmpvec.t

