C RCS file, release, date & time of last delta, author, state, [and locker]
C $Header: /project/work/rep/STENEX/src/noop_f90/noop_init_module.f,v 1.1.1.1 2000/04/12 17:40:55 yoj Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

C --------------------------------------------------------------------------
C Purpose:
C
C   use F90 module feature to capture noop_init routine
C
C Revision history:
C
C   Orginal version: 11/05/99 by David Wong
C --------------------------------------------------------------------------

        module noop_init_module

          implicit none

          contains

C -----------------------------------------------------------------------------
C Purpose:
C
C   to provide a no-op noop_init.f counter part for serial code
C
C Revision history:
C
C   Orginal version: 10/6/98 by David Wong
C                    11/05/99 by David Wong
C                      -- recode using F90 syntax
C -----------------------------------------------------------------------------

	subroutine noop_init (numprocs, nprow, npcol, gl_nrows, 
     $                        gl_ncols, gl_nlays, gl_nspcs, my_pe,
     $                        mndis, medis, msdis, mwdis, data_ori, geo_ori)

	implicit none

        integer, intent(in) :: numprocs, nprow, npcol
        integer, intent(in) :: gl_nrows, gl_ncols, gl_nlays, gl_nspcs
        integer, intent(in) :: my_pe
        integer, intent(in) :: mndis, medis, msdis, mwdis
        character (len = 2), intent(in) :: data_ori
        integer, intent(in) :: geo_ori

        end subroutine noop_init 

        end module noop_init_module
