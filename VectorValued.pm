## $Id$
##
## File: PDL::VectorValued.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Vector utilities for PDL: perl side only
##======================================================================

package PDL::VectorValued;
use strict;

##======================================================================
## Export hacks
use PDL;
use PDL::Exporter;
use PDL::VectorValued::Utils;
our @ISA = qw(PDL::Exporter);
our @EXPORT_OK =
  (
   (@PDL::VectorValued::Utils::EXPORT_OK), ##-- inherited
   qw(vv_uniqvec),
   qw(rleND rldND),
   qw(vv_indx),
  );
our %EXPORT_TAGS =
  (
   Func => [@EXPORT_OK],               ##-- respect PDL conventions (hopefully)
  );

## VERSION was formerly set by PDL::VectorValued::Version, now use perl-reversion from Perl::Version instead
our $VERSION = '1.0.12';

##======================================================================
## pod: header
=pod

=head1 NAME

PDL::VectorValued - Utilities for vector-valued PDLs

=head1 SYNOPSIS

 use PDL;
 use PDL::VectorValued;

 ##---------------------------------------------------------------------
 ## ... stuff happens

=cut

##======================================================================
## Description
=pod

=head1 DESCRIPTION

PDL::VectorValued provides generalizations of some elementary PDL
functions to higher-order PDLs which treat vectors as "data values".

=cut

##======================================================================
## pod: Functions
=pod

=head1 FUNCTIONS

=cut

##----------------------------------------------------------------------
## vv_uniqvec

=pod

=head2 vv_uniqvec

=for sig

  Signature: (v(N,M); [o]vu(N,MU))

=for ref

Drop-in replacement for broken uniqvec() which uses vv_qsortvec().
Otherwise copied from PDL::Primitive::primitive.pd.

See also: PDL::VectorValued::Utils::vv_qsortvec, PDL::Primitive::uniqvec.

=cut

*PDL::vv_uniqvec = \&vv_uniqvec;
sub vv_uniqvec {
  my($pdl) = shift;

  # slice is not cheap but uniqvec isn't either -- shouldn't cost too much.
  return $pdl if($pdl->nelem == 0 || $pdl->ndims <2 || $pdl->slice("(0)")->nelem < 2); 

  my $srt = $pdl->mv(0,-1)->
    clump($pdl->ndims - 1)->
      mv(-1,0)->vv_qsortvec-> ##-- moo: Tue, 24 Apr 2007 17:17:39 +0200: use vv_qsortvec
	mv(0,-1);

  $srt=$srt->dice($srt->mv(0,-1)->ngoodover->which) if ($PDL::Bad::Status && $srt->badflag);
  ##use dice instead of nslice since qsortvec might be packing the badvals to the front of
  #the array instead of the end like the docs say. If that is the case and it gets fixed,
  #it won't bust uniqvec. DAL 14-March 2006
  my $uniq = ($srt != $srt->rotate(-1)) -> mv(0,-1) -> orover->which;

  return $uniq->nelem==0 ? 
	$srt->slice("0,:")->mv(0,-1) :
	$srt->dice($uniq)->mv(0,-1);
}


##======================================================================
## Run-Length Encoding/Decoding: n-dimensionl
=pod

=head1 Higher-Order Run-Length Encoding and Decoding

The following functions generalize the builtin PDL functions rle() and rld()
for higher-order "values".

See also:
PDL::VectorValued::Utils::rlevec(), PDL::VectorValued::Utils::rldvec().

=cut

##----------------------------------------------------------------------
## rleND()
=pod

=head2 rleND

=for sig

  Signature: (data(@vdims,N); int [o]counts(N); [o]elts(@vdims,N))

=for ref

Run-length encode a set of (sorted) n-dimensional values.

Generalization of rle() and rlevec():
given set of values $data, generate a vector $counts with the number of occurrences of each element
(where an "element" is a matrix of dimensions @vdims ocurring as a sequential run over the
final dimension in $data), and a set of vectors $elts containing the elements which begin a run.
Really just a wrapper for clump() and rlevec().

See also: PDL::Slices::rle, PDL::Ngrams::VectorValued::Utils::rlevec.

=cut

*PDL::rleND = \&rleND;
sub rleND {
  my $data   = shift;
  my @vdimsN = $data->dims;

  ##-- construct output pdls
  my $counts = $#_ >= 0 ? $_[0] : zeroes(long, $vdimsN[$#vdimsN]);
  my $elts   = $#_ >= 1 ? $_[1] : zeroes($data->type, @vdimsN);

  ##-- guts: call rlevec()
  rlevec($data->clump($#vdimsN), $counts, $elts->clump($#vdimsN));

  return ($counts,$elts);
}

##----------------------------------------------------------------------
## rldND()
=pod

=head2 rldND

=for sig

  Signature: (int counts(N); elts(@vdims,N); [o]data(@vdims,N);)

=for ref

Run-length decode a set of (sorted) n-dimensional values.

Generalization of rld() and rldvec():
given a vector $counts() of the number of occurrences of each @vdims-dimensioned element,
and a set $elts() of @vdims-dimensioned elements, run-length decode to $data().

Really just a wrapper for clump() and rldvec().

See also: PDL::Slices::rld, PDL::VectorValued::Utils::rldvec

=cut

*PDL::rldND = \&rldND;
sub rldND {
  my ($counts,$elts) = (shift,shift);
  my @vdimsN        = $elts->dims;

  ##-- construct output pdl
  my ($data);
  if ($#_ >= 0) { $data = $_[0]; }
  else {
    my $size      = $counts->sumover->max; ##-- get maximum size for Nth-dimension for small encodings
    my @countdims = $counts->dims;
    shift(@countdims);
    $data         = zeroes($elts->type, @vdimsN, @countdims);
  }

  ##-- guts: call rldvec()
  rldvec($counts, $elts->clump($#vdimsN), $data->clump($#vdimsN));

  return $data;
}

##======================================================================
## pod: Functions: datatype utilities
=pod

=head1 Datatype Utilities

=cut

##----------------------------------------------------------------------
## vv_indx()
=pod

=head2 vv_indx

=for sig

  Signature: vv_indx()

=for ref

Returns PDL::Type subclass used for indices.
If built with PDL E<lt> v2.007, this should return C<PDL::long>, otherwise C<PDL::indx>.

=cut

sub vv_indx {
  return defined(&PDL::indx) ? PDL::indx(@_) : PDL::long(@_);
}

1; ##-- make perl happy


##======================================================================
## pod: Functions: low-level
=pod

=head2 Low-Level Functions

Some additional low-level functions are provided in the
PDL::VectorValued::Utils
package.
See L<PDL::VectorValued::Utils> for details.

=cut



##======================================================================
## pod: Footer
=pod

=head1 ACKNOWLEDGEMENTS

perl by Larry Wall.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

PDL by Karl Glazebrook, Tuomas J. Lukka, Christian Soeller, and others.

=head1 COPYRIGHT

Copyright (c) 2007-2021, Bryan Jurish.  All rights reserved.

This package is free software.  You may redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), PDL(3perl), PDL::VectorValued::Utils(3perl)

=cut
