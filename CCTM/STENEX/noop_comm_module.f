C RCS file, release, date & time of last delta, author, state, [and locker]
C $Header: /project/work/rep/STENEX/src/noop_f90/noop_comm_module.f,v 1.1 2000/12/14 16:19:14 yoj Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

C --------------------------------------------------------------------------
C Purpose:
C
C   use F90 interface feature to achieve "faked" polymorphism for noop pe 
C communication routine 
C
C Revision history:
C
C   Orginal version: 11/05/99 by David Wong
C --------------------------------------------------------------------------

	module noop_comm_module

        implicit none

        interface noop_comm
          module procedure noop_pe_comm1, 
     &                     noop_pe_comm2, noop_pe_comm2e, 
     &                     noop_pe_comm3, noop_pe_comm3e, 
     &                     noop_pe_comm4
        end interface

        contains

C --------------------------------------------------------------------------
C Purpose:
C
C   to provide a no-op noop_comm1.f counter part for serial code
C
C Revision history:
C
C   Orginal version: 10/6/98 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C --------------------------------------------------------------------------

	subroutine noop_pe_comm1 (data, dispstr, dirstr, str)

	implicit none

	real, intent(in) :: data(:)
        character (len = 16), intent(in) :: dirstr
        character (len = 12), intent(in) :: dispstr
        character (len = *), optional, intent(in) :: str

        end subroutine noop_pe_comm1 

C --------------------------------------------------------------------------
C Purpose:
C
C   to provide a no-op noop_comm2.f counter part for serial code
C
C Revision history:
C
C   Orginal version: 10/6/98 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C --------------------------------------------------------------------------

	subroutine noop_pe_comm2 (data, dispstr, dirstr, str)

	implicit none

        real, intent(in) :: data(:, :)
        character (len = 16), intent(in) :: dirstr
        character (len = 12), intent(in) :: dispstr
        character (len = *), optional, intent(in) :: str

        end subroutine noop_pe_comm2 

C --------------------------------------------------------------------------
C Purpose:
C
C   to provide a no-op noop_comm2e.f counter part for serial code
C
C Revision history:
C
C   Orginal version: 10/6/98 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C --------------------------------------------------------------------------

	subroutine noop_pe_comm2e (data, dispstr, dirstr, flag, str)

	implicit none

        real, intent(in) :: data(:, :)
        character (len = 16), intent(in) :: dirstr
        character (len = 12), intent(in) :: dispstr
        integer, intent(in) :: flag
        character (len = *), optional, intent(in) :: str

        end subroutine noop_pe_comm2e 

C --------------------------------------------------------------------------
C Purpose:
C
C   to provide a no-op noop_comm3.f counter part for serial code
C
C Revision history:
C
C   Orginal version: 10/6/98 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C --------------------------------------------------------------------------

	subroutine noop_pe_comm3 (data, dispstr, dirstr, str)

	implicit none

        real, intent(in) :: data(:, :, :)
        character (len = 16), intent(in) :: dirstr
        character (len = 12), intent(in) :: dispstr
        character (len = *), optional, intent(in) :: str

	end subroutine noop_pe_comm3 

C --------------------------------------------------------------------------
C Purpose:
C
C   to provide a no-op noop_comm3e.f counter part for serial code
C
C Revision history:
C
C   Orginal version: 10/6/98 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C --------------------------------------------------------------------------

	subroutine noop_pe_comm3e (data, dispstr, dirstr, flag, str)

	implicit none

        real, intent(in) :: data(:, :, :)
        character (len = 16), intent(in) :: dirstr
        character (len = 12), intent(in) :: dispstr
        integer, intent(in) :: flag
        character (len = *), optional, intent(in) :: str

	end subroutine noop_pe_comm3e 

C --------------------------------------------------------------------------
C Purpose:
C
C   to provide a no-op noop_comm4.f counter part for serial code
C
C Revision history:
C
C   Orginal version: 10/6/98 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C --------------------------------------------------------------------------

	subroutine noop_pe_comm4 (data, dispstr, dirstr, str)

	implicit none

        real, intent(in) :: data(:, :, :, :)
        character (len = 16), intent(in) :: dirstr
        character (len = 12), intent(in) :: dispstr
        character (len = *), optional, intent(in) :: str

	end subroutine noop_pe_comm4 

        end module noop_comm_module
