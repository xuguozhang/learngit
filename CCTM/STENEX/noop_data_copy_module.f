C RCS file, release, date & time of last delta, author, state, [and locker]
C $Header: /project/work/rep/STENEX/src/noop_f90/noop_data_copy_module.f,v 1.3 2002/02/28 15:25:45 yoj Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

C --------------------------------------------------------------------------
C Purpose:
C
C   use F90 interface feature to achieve "faked" polymorphism for noop data
C   copy routine
C
C Revision history:
C
C   Orginal version: 11/05/99 by David Wong
C --------------------------------------------------------------------------

	module noop_data_copy_module

        implicit none

        interface noop_data_copy
          module procedure noop_2d_data_copy, noop_2de_data_copy,
     &                     noop_3d_data_copy, noop_3de_data_copy, 
     &                     noop_4d_data_copy, noop_4de_data_copy
        end interface

        contains

C --------------------------------------------------------------------------
C Purpose:
C
C   to provide a no-op 2-D noop_data_copy.f counter part for serial code
C
C Revision history:
C
C   Orginal version: 02/15/99 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C --------------------------------------------------------------------------

        subroutine noop_2d_data_copy (data1, data2)

        implicit none

        real, intent(in) :: data1(:, :)
        real, intent(out) :: data2(:, :)

        end subroutine noop_2d_data_copy 

C --------------------------------------------------------------------------
C Purpose:
C
C   to provide a no-op 2-D noop_data_copy.f counter part for serial code
C
C Revision history:
C
C   Orginal version: 02/15/99 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C                    05/11/01 by David Wong
C                      -- fixed data1 declaration bug
C --------------------------------------------------------------------------

        subroutine noop_2de_data_copy (data1, data2, spc)

        implicit none

        real, intent(in) :: data1(:, :, :)
        real, intent(out) :: data2(:, :)
        integer, intent(in) :: spc

        end subroutine noop_2de_data_copy

C --------------------------------------------------------------------------
C Purpose:
C
C   to provide a no-op 3-D noop_data_copy.f counter part for serial code
C
C Revision history:
C
C   Orginal version: 02/15/99 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C --------------------------------------------------------------------------

        subroutine noop_3d_data_copy (data1, data2)

        implicit none

        real, intent(in) :: data1(:, :, :)
        real, intent(out) :: data2(:, :, :)

        end subroutine noop_3d_data_copy 

C --------------------------------------------------------------------------
C Purpose:
C
C   to provide a no-op 3-D noop_data_copy.f counter part for serial code
C
C Revision history:
C
C   Orginal version: 02/15/99 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C                    05/11/01 by David Wong
C                      -- fixed data1 declaration bug
C --------------------------------------------------------------------------

        subroutine noop_3de_data_copy (data1, data2, spc)

        implicit none

        real, intent(in) :: data1(:, :, :, :)
        real, intent(out) :: data2(:, :, :)
        integer, intent(in) :: spc

        end subroutine noop_3de_data_copy 

C --------------------------------------------------------------------------

        subroutine noop_4d_data_copy (data1, data2)

        implicit none

        real, intent(in) :: data1(:, :, :, :)
        real, intent(out) :: data2(:, :, :, :)

        end subroutine noop_4d_data_copy 

C --------------------------------------------------------------------------
C Purpose:
C
C   to provide a no-op 4-D noop_data_copy.f counter part for serial code
C
C Revision history:
C
C   Orginal version: 02/15/99 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C --------------------------------------------------------------------------

        subroutine noop_4de_data_copy (data1, data2, spc, des)

        implicit none

        real, intent(in) :: data1(:, :, :, :)
        real, intent(out) :: data2(:, :, :, :)
        integer, intent(in) :: spc, des

        end subroutine noop_4de_data_copy 

        end module noop_data_copy_module
