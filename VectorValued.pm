## $Id$
##
## File: PDL::VectorValued.pm
## Author: Bryan Jurish <moocow@ling.uni-potsdam.de>
## Description: Vector utilities for PDL: perl side only
##======================================================================

package PDL::VectorValued;
use strict;

##======================================================================
## Export hacks
use PDL;
use PDL::Exporter;
use PDL::VectorValued::Version; ##-- sets $PDL::VectorValued::VERSION
use PDL::VectorValued::Utils;
our @ISA = qw(PDL::Exporter);
our @EXPORT_OK =
  (
   (@PDL::VectorValued::Utils::EXPORT_OK), ##-- inherited
   qw(rleND rldND),
  );
our %EXPORT_TAGS =
  (
   Func => [@EXPORT_OK],               ##-- respect PDL conventions (hopefully)
  );


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


1; ##-- make perl happy


##======================================================================
## pod: Functions: low-level
=pod

=head2 Low-Level Functions

Some additional low-level functions are provided in the
PDL::Ngrams::ngutils
package.
See L<PDL::Ngrams::ngutils> for details.

=cut

##======================================================================
## pod: Footer
=pod

=head1 ACKNOWLEDGEMENTS

perl by Larry Wall.

=head1 AUTHOR

Bryan Jurish E<lt>jurish@ling.uni-potsdam.deE<gt>

PDL by Karl Glazebrook, Tuomas J. Lukka, Christian Soeller, and others.

=head1 COPYRIGHT

Copyright (c) 2007, Bryan Jurish.  All rights reserved.

This package is free software.  You may redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), PDL(3perl), PDL::VectorValued::Utils(3perl)

=cut
