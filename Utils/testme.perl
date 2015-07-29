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
#test_cmpvec;

##---------------------------------------------------------------------
## test: sequences

sub test_seq {
  ##-- test: rldseq (-offsets)
  my $lens = pdl(indx,[qw(3 0 1 4 2)]);
  my $offs = $lens->zeroes->long;
  my $seqs = $lens->rldseq($offs);
  my $want = null;
  $want = $want->append(sequence($_)) foreach ($lens->list);
  isok("rldseq(-offs): ", $want->nelem==$seqs->nelem && all($seqs==$want));

  ##-- test: rldseq (+offsets)
  my $lens2 = $lens;
  my $offs2 = ($lens2->xvals->double+1)*100;
  my $seqs2 = $lens2->rldseq($offs2);
  my $want2 = null;
  $want2  = $want2->append(sequence($_)) foreach ($lens2->list);
  $want2 += $lens2->rld($offs2);
  my $seqs2 = $lens2->rldseq($offs2);
  isok("rldseq(+offs): ", $want2->nelem==$seqs2->nelem && all($seqs2==$want2));

  ##-- test: rleseq (-offsets)
  my ($elen,$eoff) = $want->rleseq();
  isok("rleseq(-offs):len", all($elen->where($elen)==$lens->where($lens)));
  isok("rleseq(-offs):off", all($eoff->where($elen)==$offs->where($lens)));

  ##-- test: rleseq (+offsets)
  my ($elen2,$eoff2) = $want2->rleseq();
  isok("rleseq(+offs):len", all($elen2->where($elen2)==$lens2->where($lens2)));
  isok("rleseq(+offs):off", all($eoff2->where($elen2)==$offs2->where($lens2)));
}
test_seq();


##---------------------------------------------------------------------
## DUMMY
##---------------------------------------------------------------------
foreach $i (0..3) {
  print "--dummy($i)--\n";
}

