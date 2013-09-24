## -*- Mode: CPerl -*-
##  + CPerl pukes on '/esg'-modifiers.... bummer
##
## $Id$
##
## File: PDL::VectorValued::Dev.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Vector utilities for PDL: development
##======================================================================

package PDL::VectorValued::Dev;
use strict;

##======================================================================
## Export hacks
#use PDL::PP; ##-- do NOT do this!
use Exporter;
our $VERSION = 0.01;

our @ISA = qw(Exporter);
our @EXPORT_OK =
  (
   ##
   ##-- High-level macro expansion
   qw(vvpp_def vvpp_expand),
   ##
   ##-- Type utilities
   qw(vv_indx_sig vv_indx_typedef),
   ##
   ##-- Macro expansion subs
   qw(vvpp_pdlvar_basename),
   qw(vvpp_expand_cmpvec vvpp_cmpvec_code),
  );
our %EXPORT_TAGS =
  (
   all     => [@EXPORT_OK],
   default => [@EXPORT_OK],
  );
our @EXPORT    = @{$EXPORT_TAGS{default}};

##======================================================================
## pod: header
=pod

=head1 NAME

PDL::VectorValued::Dev - development utilities for vector-valued PDLs

=head1 SYNOPSIS

 use PDL;
 use PDL::VectorValued::Dev;

 ##---------------------------------------------------------------------
 ## ... stuff happens

=cut

##======================================================================
## Description
=pod

=head1 DESCRIPTION

PDL::VectorValued::Dev provides some developer utilities for
vector-valued PDLs.  It produces code for processing with PDL::PP.

=cut

##======================================================================
## PP Utiltiies
=pod

=head1 PDL::PP Utilities

=cut

##--------------------------------------------------------------
## undef = vvpp_def($name,%args)
=pod

=head2 vvpp_def($funcName,%args)

Wrapper for pp_def() which calls vvpp_expand() on 'Code' and 'BadCode'
values in %args.

=cut

sub vvpp_def {
  my ($name,%args) = @_;
  foreach (qw(Code BadCode)) {
    $args{$_} = vvpp_expand($args{$_}) if (defined($args{$_}));
  }
  PDL::PP::pp_def($name,%args);
}



##--------------------------------------------------------------
## $pp_code = vvpp_expand($vvpp_code)
=pod

=head2 $pp_code = vvpp_expand($vvpp_code)

Expand PDL::VectorValued macros in $vvpp_code.
Currently known PDL::VectorValued macros include:

  MACRO_NAME            EXPANSION_SUBROUTINE
  ----------------------------------------------------------------------
  $CMPVEC(...)          vvpp_expand_cmpvec(...)

See the documentation of the individual expansion subroutines
for details on calling conventions.

You can add your own expansion macros by pushing an expansion
manipulating the array

 @PDL::VectorValued::Dev::MACROS

which is just a list of expansion subroutines which take a single
argument (string for Code or BadCode) and should return the expanded
string.

=cut

our @MACROS =
    (
     \&vvpp_expand_cmpvec,
     ##
     ## ... more macros here
     );
sub vvpp_expand {
  my $str = shift;
  my ($macro_sub);
  foreach $macro_sub (@MACROS) {
      $str = $macro_sub->($str);
  }
  $str;
}


##--------------------------------------------------------------
## $pp_code = vvpp_expand_cmpvec($vvpp_code)
sub vvpp_expand_cmpvec {
  my $str = shift;
  #$str =~ s{\$CMPVEC\s*\(([^\)]*)\)}{vvpp_cmpvec_code(eval($1))}esg; ##-- nope
  $str =~ s{\$CMPVEC\s*\((.*)\)}{vvpp_cmpvec_code(eval($1))}emg; ##-- single-line macros ONLY
  return $str;
}

##======================================================================
## PP Utilities: Types
=pod

=head1 Type Utilities

=cut

##--------------------------------------------------------------
## $sigtype = vv_indx_sig()
=pod

=head2 vv_indx_sig()

Returns a signature type for representing PDL indices.
For PDL E<gt>= v2.007 this should be C<PDL_Index>, otherwise it will be C<int>.

=cut

sub vv_indx_sig {
  require PDL::Core;
  return defined(&PDL::indx) ? 'indx' : 'int';
}

##--------------------------------------------------------------
## $sigtype = vv_indx_typedef()
=pod

=head2 vv_indx_typedef()

Returns a C typedef for the C<PDL_Indx> type if running under
PDL E<lt>= v2.007, otherwise just a comment.  You can call this
from client PDL::PP modules as

 pp_addhdr(PDL::VectorValued::Dev::vv_indx_typedef);

=cut

sub vv_indx_typedef {
  require PDL::Core;
  if (defined(&PDL::indx)) {
    return "/*-- PDL_Indx built-in for PDL >= v2.007 --*/\n";
  }
  return "typedef int PDL_Indx; /*-- PDL_Indx typedef for PDL <= v2.007 --*/\n";
}


##======================================================================
## PP Utilities: Macro Expansion
=pod

=head1 Macro Expansion Utilities

=cut

##--------------------------------------------------------------
## vvpp_pdlvar_basename()
=pod

=head2 vvpp_pdlvar_basename($pdlVarString)

Gets basename of a PDL::PP variable by removing leading '$'
and anything at or following the first open parenthesis:

 $base = vvpp_pdlvar_basename('$a(n=>0)'); ##-- $base is now 'a'

=cut

sub vvpp_pdlvar_basename {
  my $varname = shift;
  $varname =~ s/^\s*\$\s*//;
  $varname =~ s/\s*\(.*//;
  return $varname;
}

##--------------------------------------------------------------
## vvpp_cmpvec_code()
=pod

=head2 vvpp_cmpvec_code($vec1,$vec2,$dimName,$retvar,%options)

Returns PDL::PP code for lexicographically comparing two vectors
C<$vec1> and C<$vec2> along the dimension named C<$dim>, storing the
comparsion result in the C variable C<$retvar>,
similar to what:

 $retvar = ($vec1 <=> $vec2);

"ought to" do.

Parameters:

=over 4

=item $vec1

=item $vec2

PDL::PP string forms of vector PDLs to be compared.
Need not be physical.

=item $dimName

Name of the dimension along which vectors should be compared.

=item $retvar

Name of a C variable to store the comparison result.

=item $options{cvar1}

=item $options{cvar2}

If specified, temporary values for C<$vec1> (rsp. C<$vec2>)
will be stored in the C variable $options{cvar1} (rsp. C<$options{cvar2}>).
If unspecified, a new locally scoped C variable
C<_vvpp_cmpvec_val1> (rsp. C<_vvpp_cmpvec_val2>) will be declared and used.

=back

=for example

The PDL::PP code for cmpvec() looks something like this:

 use PDL::VectorValued::Dev;
 pp_def('cmpvec',
        Pars => 'a(n); b(n); int [o]cmp()',
        Code => (
                 'int cmpval;'
                 .vvpp_cmpvec_code( '$a()', '$b()', 'n', 'cmpval' )
                 .$cmp() = cmpval'
                );
        );

=cut

sub vvpp_cmpvec_code {
  my ($vec1,$vec2,$dimName,$retvar,%opts) = @_;
  ##
  ##-- sanity checks
  my $USAGE = 'vvpp_cmpvec_code($vec1,$vec2,$dimName,$retvar,%opts)';
  die ("Usage: $USAGE") if (grep {!defined($_)} @_[0,1,2,3]);
  ##
  ##-- get PDL variable basenames
  my $vec1Name = vvpp_pdlvar_basename($vec1);
  my $vec2Name = vvpp_pdlvar_basename($vec2);
  my $ppcode = "\n{ /*-- BEGIN vvpp_cmpvec_code --*/\n";
  ##
  ##-- get C variables
  my ($cvar1,$cvar2);
  if (!defined($cvar1=$opts{var1})) {
      $cvar1   = '_vvpp_cmpvec_val1';
      $ppcode .= " \$GENERIC(${vec1Name}) ${cvar1};\n";
  }
  if (!defined($cvar2=$opts{var2})) {
      $cvar2   = '_vvpp_cmpvec_val2';
      $ppcode .= " \$GENERIC(${vec2Name}) ${cvar2};\n";
  }
  ##
  ##-- generate comparison code
  $ppcode .= (''
	      ." ${retvar}=0;\n"
	      ." loop (${dimName}) %{\n"
	      ."  ${cvar1}=$vec1;\n"
	      ."  ${cvar2}=$vec2;\n"
	      ."  if      (${cvar1} < ${cvar2}) { ${retvar}=-1; break; }\n"
	      ."  else if (${cvar1} > ${cvar2}) { ${retvar}= 1; break; }\n"
	      ." %}\n"
	      ."} /*-- END vvpp_cmpvec_code --*/\n"
	     );
  ##
  ##-- ... and return
  return $ppcode;
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
## pod: Bugs
=pod

=head1 KNOWN BUGS

=head2 Why not PDL::PP macros?

All of these functions would be more intuitive if implemented directly
as PDL::PP macros, and thus expanded directly by pp_def() rather
than requiring vvpp_def().

Unfortunately, I don't currently have the time to figure out how to
use the (undocumented) PDL::PP macro expansion mechanism.
Feel free to add real macro support.

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

Copyright (c) 2007, Bryan Jurish.  All rights reserved.

This package is free software.  You may redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), PDL::PP(3perl).

=cut
