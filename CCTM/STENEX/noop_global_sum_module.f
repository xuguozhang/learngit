C RCS file, release, date & time of last delta, author, state, [and locker]
C $Header: /project/work/rep/STENEX/src/noop_f90/noop_global_sum_module.f,v 1.1.1.1 2000/04/12 17:40:55 yoj Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

C --------------------------------------------------------------------------
C Purpose:
C
C   use F90 interface feature to achieve "faked" polymorphism for noop global 
C sum routine
C
C Revision history:
C
C   Orginal version: 11/05/99 by David Wong
C -----------------------------------------------------------------------------

        module noop_global_sum_module

        implicit none

        interface noop_global_sum
          module procedure noop_global_isum, noop_global_rsum
        end interface

        contains

C -----------------------------------------------------------------------------
C Purpose: a noop counter part of se_global_isum which determine the global 
C          integer sum
C
C Revision history:
C
C   Orginal version: 11/16/98 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C
C Parameter List:
C
C   In: var -- sum variable
C -----------------------------------------------------------------------------

        function noop_global_isum (var) result (noop_global_isum_result)

	implicit none

	integer, intent(in) :: var
	integer :: noop_global_isum_result

        noop_global_isum_result = var

	end function noop_global_isum 

C -----------------------------------------------------------------------------
C Purpose: a noop counter part of se_global_rsum which determine the global 
C          real sum
C
C Revision history:
C
C   Orginal version: 11/16/98 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C
C Parameter List:
C
C   In: var -- sum variable
C -----------------------------------------------------------------------------

        function noop_global_rsum (var) result (noop_global_rsum_result)

	implicit none

	real, intent(in) :: var
        real :: noop_global_rsum_result

        noop_global_rsum_result = var

	end function noop_global_rsum

        end module noop_global_sum_module
