##
## File: PDL::VectorValued::Version.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Vector utilities for PDL: version
##  + this lives in a separate file so that both compile-time and
##    runtime subsystems can use it
##======================================================================

package PDL::VectorValued::Version;
our $VERSION = '0.08002';
$PDL::VectorValued::VERSION = $VERSION;

1; ##-- make perl happy
