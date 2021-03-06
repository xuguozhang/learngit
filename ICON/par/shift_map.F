
!------------------------------------------------------------------------!
!  The Community Multiscale Air Quality (CMAQ) system software is in     !
!  continuous development by various groups and is based on information  !
!  from these groups: Federal Government employees, contractors working  !
!  within a United States Government contract, and non-Federal sources   !
!  including research institutions.  These groups give the Government    !
!  permission to use, prepare derivative works of, and distribute copies !
!  of their work in the CMAQ system to the public and to permit others   !
!  to do so.  The United States Environmental Protection Agency          !
!  therefore grants similar permission to use the CMAQ system software,  !
!  but users are requested to provide copies of derivative works or      !
!  products designed to operate in the CMAQ system to the United States  !
!  Government without restrictions as to use by others.  Software        !
!  that is used with the CMAQ system but distributed under the GNU       !
!  General Public License or the GNU Lesser General Public License is    !
!  subject to their copyright restrictions.                              !
!------------------------------------------------------------------------!

C RCS file, release, date & time of last delta, author, state, [and locker]
C $Header: /project/yoj/arc/ICON/src/par/shift_map.F,v 1.1 2011/11/02 13:17:25 yoj Exp $

      SUBROUTINE SHIFT_MAP ( NCOLS, NROWS, MY_NCOLS, MY_NROWS,
     &                       GL_NCOLS_IN, GL_NROWS_IN, NCOLS_IN, NROWS_IN,
     &                       NLAYS_IN, NSPCS_IN, COL_LOC, ROW_LOC, CONC )

C ----------------------------------------------------------------------
C Purpose:
 
C To re-decompose the coarse grid domain with respect to the position of the
C fine grid domain by shifting CONC and re-calculating COL_LOC and ROW_LOC 
C accordingly.
 
C Revision history:
 
C   02/15/00 by David Wong, LM
C   -- Orginal version
 
C   10/10/00 by David Wong, LM
C   -- replaced SUBST_CSG_INDEX with SUBST_SUBGRID_INDEX 
C      after unification of subroutines SUBST_CSF_INDEX and 
C      SUBST_FSG_INDX in the STENEX library and removed one
C      argument in the SUBST_DATA_COPY routine with respect
C      to the unification.
 
C   04/10/02 by David Wong, LM
C   -- Fixed the incorrect arguments order in the 
C      SUBST_SUBGRID_INDEX call statement.
 
C   12/21/04 J.Young
C   -- Changed the argument list
 
C Argument list:
 
C In:
C        NCOLS       -- number of fine domain columns in this processor
C        NROWS       -- number of fine domain rows    in this processor
C        MY_NCOLS    -- number of fine domain data columns in this processor
C        MY_NROWS    -- number of fine domain data    rows in this processor
C        GL_NCOLS_IN -- number of coarse domain columns
C        GL_NROWS_IN -- number of coarse domain rows
C        NCOLS_IN    -- number of coarse domain columns in this processor
C        NROWS_IN    -- number of coarse domain rows    in this processor
C        NLAYS_IN    -- number of coarse domain layers
C        NSPCS_IN    -- number of coarse domain species
 
C InOut:
C        COL_LOC     -- column position of a grid point of the fine domain 
C                       relative to the coarse domain in a processor 
C        ROW_LOC     -- row position of a grid point of the fine domain 
C                       relative to the coarse domain in a processor 
C        CONC        -- concentration field
 
C ----------------------------------------------------------------------------

      USE SUBST_MODULES

      IMPLICIT NONE

C Includes:
      INCLUDE SUBST_MPI          ! MPI definitions and parameters.

C Arguments:
      INTEGER, INTENT( IN )    :: NCOLS, NROWS, MY_NCOLS, MY_NROWS
      INTEGER, INTENT( IN )    :: GL_NCOLS_IN, GL_NROWS_IN, NCOLS_IN, NROWS_IN
      INTEGER, INTENT( IN )    :: NLAYS_IN, NSPCS_IN
      INTEGER, INTENT( INOUT ) :: COL_LOC( NCOLS,NROWS ), ROW_LOC( NCOLS,NROWS )
      REAL,    INTENT( INOUT ) :: CONC( NCOLS_IN,NROWS_IN,NLAYS_IN,NSPCS_IN )

C Local Variables:
      REAL    :: TCONC( NCOLS_IN,NROWS_IN,NLAYS_IN,NSPCS_IN )
      INTEGER I, J, FIRST_ROW, FIRST_COL

      INTEGER MY_BEGCOL, MY_ENDCOL, MY_BEGROW, MY_ENDROW,
     &        MY_SUBGRID_COLS, MY_SUBGRID_ROWS

C-----------------------------------------------------------------------

C -- determine the decompostion of the coarse domain relative to the position
C    of the fine domain and determine the range of rows and columns in a processor
C    for data exchange purposes

C map a 2-D subgrid, with redistribution, with change of resolution in the subgrid,
C on a domain grid to all processors.
      CALL SUBST_SUBGRID_INDEX ( COL_LOC( 1,1 ), COL_LOC( MY_NCOLS,MY_NROWS ),
     &                           ROW_LOC( 1,1 ), ROW_LOC( MY_NCOLS,MY_NROWS ),
     &                           MY_BEGCOL, MY_ENDCOL,
     &                           MY_BEGROW, MY_ENDROW,
     &                           MY_SUBGRID_COLS, MY_SUBGRID_ROWS, 
     &                           GL_NCOLS_IN, GL_NROWS_IN )

C in:
C  COL_LOC( 1,1 ), COL_LOC( MY_NCOLS,MY_NROWS ) -
C     beginning and ending column indices of the subgrid
C  ROW_LOC( 1,1 ), ROW_LOC( MY_NCOLS,MY_NROWS ) -
C     beginning and ending row indices of the subgrid
C  GL_NCOLS_IN - No. of columns in the subgrid (fine grid)
C  GL_NROWS_IN - No. of rows in the subgrid (fine grid)

C out:
C  MY_BEGCOL, MY_ENDCOL  -
C     local beginning and ending column indices of the subgrid
C  MY_BEGROW, MY_ENDROW -
C     local beginning and ending row indices of the subgrid
C  MY_SUBGRID_COLS, MY_SUBGRID_ROWS -
C     No. of columns and rows of the subgrid in this processor

!!!!! Even tho' it looks like you should, don't do following, because having
!!!!! specified "RC" in par_init, Dave's stenex code does the swapping of
!!!!! row-col internally

!     CALL SUBST_SUBGRID_INDEX ( ROW_LOC( 1,1 ), ROW_LOC( MY_NCOLS,MY_NROWS ),
!    &                           COL_LOC( 1,1 ), COL_LOC( MY_NCOLS,MY_NROWS ),
!    &                           MY_BEGROW, MY_ENDROW,
!    &                           MY_BEGCOL, MY_ENDCOL,
!    &                           MY_SUBGRID_ROWS, MY_SUBGRID_COLS, 
!    &                           GL_NROWS_IN, GL_NCOLS_IN )

C -- exchange data according to the new decomposition of the coarse domain

      CALL SUBST_DATA_COPY ( CONC, TCONC )

      CONC = TCONC

C -- normalize the row and column positions

      FIRST_COL = COL_LOC( 1,1 ) - 1
      FIRST_ROW = ROW_LOC( 1,1 ) - 1
      DO J = 1, MY_NROWS
         DO I = 1, MY_NCOLS
            COL_LOC( I,J ) = COL_LOC( I,J ) - FIRST_COL
            ROW_LOC( I,J ) = ROW_LOC( I,J ) - FIRST_ROW
         END DO
      END DO

      RETURN
      END SUBROUTINE SHIFT_MAP
