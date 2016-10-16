C RCS file, release, date & time of last delta, author, state, [and locker]
C $Header: /project/work/rep/STENEX/src/noop_f90/noop_slice_module.f,v 1.2 2000/12/22 18:37:12 yoj Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

C --------------------------------------------------------------------------
C Purpose:
C
C   use F90 interface feature to achieve "faked" polymorphism for data
C   slicing routine
C
C Revision history:
C
C   Orginal version: 11/05/99 by David Wong
C   Add integer data 12/20/00 by Jeff Young
C --------------------------------------------------------------------------

	module noop_slice_module

        implicit none

        interface noop_slice
          module procedure noop_slice1i, noop_slice1r,
     &                     noop_slice2i, noop_slice2r,
     &                     noop_slice3i, noop_slice3r,
     &                     noop_slice4i, noop_slice4r
        end interface

        contains

C --------------------------------------------------------------------------
C Purpose:
C
C   to provide a no-op noop_slice1i.f counter part for serial code
C
C Revision history:
C
C   Orginal version: 5/26/98 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C --------------------------------------------------------------------------

        subroutine noop_slice1i (data, sourcepe, destpe, dim, from, to)

        implicit none

        integer, intent(in) :: sourcepe, destpe, dim, from, to
        integer, intent(in) :: data(:)

	end subroutine noop_slice1i 

C --------------------------------------------------------------------------
C Purpose:
C
C   to provide a no-op noop_slice1r.f counter part for serial code
C
C Revision history:
C
C   Orginal version: 5/26/98 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C --------------------------------------------------------------------------

        subroutine noop_slice1r (data, sourcepe, destpe, dim, from, to)

        implicit none

        integer, intent(in) :: sourcepe, destpe, dim, from, to
        real, intent(in) :: data(:)

	end subroutine noop_slice1r 

C --------------------------------------------------------------------------
C Purpose:
C
C   to provide a no-op noop_slice2i.f counter part for serial code
C
C Revision history:
C
C   Orginal version: 5/26/98 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C --------------------------------------------------------------------------

        subroutine noop_slice2i (data, sourcepe, destpe, dim, from, to)

        implicit none

        integer, intent(in) :: sourcepe, destpe, dim, from, to
        integer, intent(in) :: data(:, :)

        end subroutine noop_slice2i 

C --------------------------------------------------------------------------
C Purpose:
C
C   to provide a no-op noop_slice2r.f counter part for serial code
C
C Revision history:
C
C   Orginal version: 5/26/98 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C --------------------------------------------------------------------------

        subroutine noop_slice2r (data, sourcepe, destpe, dim, from, to)

        implicit none

        integer, intent(in) :: sourcepe, destpe, dim, from, to
        real, intent(in) :: data(:, :)

        end subroutine noop_slice2r 

C --------------------------------------------------------------------------
C Purpose:
C
C   to provide a no-op noop_slice3i.f counter part for serial code
C
C Revision history:
C
C   Orginal version: 5/26/98 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C --------------------------------------------------------------------------

        subroutine noop_slice3i (data, sourcepe, destpe, dim, from, to)

        implicit none

        integer, intent(in) :: sourcepe, destpe, dim, from, to
        integer, intent(in) :: data(:, :, :)

	end subroutine noop_slice3i 

C --------------------------------------------------------------------------
C Purpose:
C
C   to provide a no-op noop_slice3r.f counter part for serial code
C
C Revision history:
C
C   Orginal version: 5/26/98 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C --------------------------------------------------------------------------

        subroutine noop_slice3r (data, sourcepe, destpe, dim, from, to)

        implicit none

        integer, intent(in) :: sourcepe, destpe, dim, from, to
        real, intent(in) :: data(:, :, :)

	end subroutine noop_slice3r 

C --------------------------------------------------------------------------
C Purpose:
C
C   to provide a no-op noop_slice4i.f counter part for serial code
C
C Revision history:
C
C   Orginal version: 5/26/98 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C --------------------------------------------------------------------------

        subroutine noop_slice4i (data, sourcepe, destpe, dim, from, to)

        implicit none

        integer, intent(in) :: sourcepe, destpe, dim, from, to
        integer, intent(in) :: data(:, :, :, :)

        end subroutine noop_slice4i 

C --------------------------------------------------------------------------
C Purpose:
C
C   to provide a no-op noop_slice4r.f counter part for serial code
C
C Revision history:
C
C   Orginal version: 5/26/98 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C --------------------------------------------------------------------------

        subroutine noop_slice4r (data, sourcepe, destpe, dim, from, to)

        implicit none

        integer, intent(in) :: sourcepe, destpe, dim, from, to
        real, intent(in) :: data(:, :, :, :)

        end subroutine noop_slice4r 

        end module noop_slice_module
