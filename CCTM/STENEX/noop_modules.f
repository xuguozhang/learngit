C RCS file, release, date & time of last delta, author, state, [and locker]
C $Header: /project/work/rep/STENEX/src/noop_f90/noop_modules.f,v 1.3 2002/02/28 15:20:36 yoj Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

C --------------------------------------------------------------------------
C Purpose:
C
C   to provide an interface between the noop stencil exchange library and the
C application code
C
C Revision history:
C
C   Orginal version: 11/05/99 by David Wong
C                    02/27/01 by David Wong
C                      -- to include a new statement: use noop_term_module
C                    11/27/01 by David Wong
C                      -- include a new module: noop_bndy_copy_module
C --------------------------------------------------------------------------

	module noop_modules

          use noop_init_module
          use noop_term_module

          use noop_util_module

          use noop_comm_module
          use noop_slice_module
          use noop_data_copy_module
          use noop_gather_module

          use noop_global_max_module
          use noop_global_min_module
          use noop_global_sum_module

        end module noop_modules
