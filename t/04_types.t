# -*- Mode: CPerl -*-
# t/03_setops.t: test cmpvec, vv_qsortvec, vsearchvec

$TEST_DIR = './t';
#use lib qw(../blib/lib ../blib/arch); $TEST_DIR = '.'; # for debugging

# load common subs
use Test;
do "$TEST_DIR/common.plt";
use PDL;
use PDL::VectorValued;
#use PDL::VectorValued::Dev;

BEGIN { plan tests=>2, todo=>[]; }

##--------------------------------------------------------------
## data

## 1..2: types
isok("isa(vv_indx,PDL::Type)", UNIVERSAL::isa(vv_indx,'PDL::Type'));
if (defined(&PDL::indx)) {
  isok("vv_indx == PDL::indx (PDL >= v2.007)", vv_indx() == PDL::indx);
} else {
  isok("vv_indx == PDL::long (PDL < v2.007)", vv_indx() == PDL::long);
}

print "\n";
# end of t/04_types.t

