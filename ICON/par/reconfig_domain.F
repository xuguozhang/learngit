
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
C $Header: /project/yoj/arc/ICON/src/par/reconfig_domain.F,v 1.1 2011/11/02 13:17:25 yoj Exp $

      SUBROUTINE RECONFIG_DOMAIN( COLROW, GL_NCOLS, GL_NROWS, NLAYS, NSPCS,
     &                            NTHIK, NCOLS, NROWS, NPCOL, NPROW,
     &                            MNDIS, MEDIS, MSDIS, MWDIS,
     &                            COLSX_PE, ROWSX_PE, MY_NCOLS, MY_NROWS,
     &                            MY_NBNDY, IERROR )

C ----------------------------------------------------------------------------
C Purpose:
               
C Re-initialize appropriate variables for PAR_IO and Stencil Exchange 
C libraries when switching to another domain (basically this is a subset of
C par_init.F)
 
C Revision history:
 
C   Orginal version: 02/15/00 by David Wong
C   10/10/00 by David Wong - reorder column/row in se_init
C   03/29/02 Jeff and David - MYPE now starts at 0, so add one
C   25 May 06 J.Young: reorder args to cols/rows; ck cols/rows arg list order
C                      in pio_init
C   09 Jun 11 J.Young: replace I/O API include files with UTILIO_DEFN module
 
C Argument list:
C In:
C     COLROW    -- columns/rows arg list check
C     GL_NCOLS  -- Number of columns in entire grid
C     GL_NROWS  -- Number of rows in entire grid
C     NLAYS     -- Number of layers in entire grid
C     NSPCS     -- Number of species in CGRID
C     NTHIK     -- Boundary thickness (cells)
C     NCOLS     -- Column dimension of local-processor arrays
C     NROWS     -- Row dimension of local-processor arrays
C     NPCOL     -- Number of processors across grid columns
C     NPROW     -- Number of processors across grid rows
C     MNDIS     -- Maximum stencil displacement in the north direction
C     MEDIS     -- Maximum stencil displacement in the east direction
C     MSDIS     -- Maximum stencil displacement in the south direction
C     MWDIS     -- Maximum stencil displacement in the west direction
C Out
C     COLSX_PE  -- Column range for each PE, COLSX_PE(1,*) is the starting 
C                  column index and COLSX_PE(2,*) is the ending column index
C     ROWSX_PE  -- Row range for each PE, ROWSX_PE(1,*) is the starting row 
C                  index and ROWSX_PE(2,*) is the ending row index
C     MY_NCOLS  -- Local number of grid columns actually used
C     MY_NROWS  -- Local number of grid rows actually used
C     MY_NBNDY  -- Local number of boundary cells actually used
C     IERROR    -- Error code: 0 for ok, 1 for fail
C
C Calls: SUBDMAP, PIO_INIT, M3WARN, SE_INIT, MPI_COMM_RANK, MPI_COMM_SIZE
C
C NOTES: Error flag IERROR is set to 1 if an error occurs in any of
C        the initialization routines called fails
C ----------------------------------------------------------------------------

      USE SUBST_MODULES
      USE UTILIO_DEFN

      IMPLICIT  NONE

C Include Files:
      INCLUDE SUBST_MPI          ! MPI definitions and parameters.

C Arguments:
      CHARACTER( 2 ), INTENT( IN ) :: COLROW
      INTEGER, INTENT( IN )        :: GL_NCOLS
      INTEGER, INTENT( IN )        :: GL_NROWS
      INTEGER, INTENT( IN )        :: NLAYS
      INTEGER, INTENT( IN )        :: NSPCS
      INTEGER, INTENT( IN )        :: NTHIK
      INTEGER, INTENT( IN )        :: NCOLS
      INTEGER, INTENT( IN )        :: NROWS
      INTEGER, INTENT( IN )        :: NPCOL
      INTEGER, INTENT( IN )        :: NPROW
      INTEGER, INTENT( IN )        :: MNDIS
      INTEGER, INTENT( IN )        :: MEDIS
      INTEGER, INTENT( IN )        :: MSDIS
      INTEGER, INTENT( IN )        :: MWDIS
      INTEGER, INTENT( OUT )       :: COLSX_PE( 2,NPCOL*NPROW )
      INTEGER, INTENT( OUT )       :: ROWSX_PE( 2,NPCOL*NPROW )
      INTEGER, INTENT( OUT )       :: MY_NCOLS
      INTEGER, INTENT( OUT )       :: MY_NROWS
      INTEGER, INTENT( OUT )       :: MY_NBNDY
      INTEGER, INTENT( OUT )       :: IERROR

C Local Variables:
      INTEGER NROWS_PE( 1:NPCOL*NPROW )  ! Row range for each processor
      INTEGER NCOLS_PE( 1:NPCOL*NPROW )  ! Column range for each processor
      INTEGER        NPROCS              ! Total number of processors
      INTEGER        MYPE         ! Local processor id (range is 0 to NPROCS-1)
      INTEGER        MAXCELLS     ! Returned argument from SUBDMAP, not used
      CHARACTER( 80 ) :: MSG             ! Message issued from M3WARN routine
      CHARACTER( 16 ) :: PNAME = 'RECONFIG_DOMAIN'
      CHARACTER(  2 ) :: DATA_ORI
      INTEGER     GEO_ORI                ! 0 (Cartesian), 1 (Matrix)

C External functions:
#ifndef parallel
      LOGICAL, EXTERNAL :: PIO_RE_INIT
#endif

C........................................................................

C Initialize error code
      IERROR = 0

C Set orientation
!     CALL UPCASE ( COLROW )
      IF ( COLROW .NE. 'CR' ) THEN
         MSG = 'Argument list must have cols/rows orientation.'
         CALL M3WARN ( PNAME, 0, 0, MSG )
         IERROR = 1; RETURN
      END IF
      DATA_ORI = COLROW
      GEO_ORI  = 0

C Get number of processors
      CALL MPI_COMM_SIZE( MPI_COMM_WORLD, NPROCS, IERROR )
      IF ( IERROR .NE. 0 ) THEN
        MSG = 'Error in MPI_COMM_SIZE.'
        CALL M3WARN( PNAME, 0, 0, MSG )
        IERROR = 1; RETURN
      END IF

C Get my processor rank (i.e., get ID of this processor)
      CALL MPI_COMM_RANK( MPI_COMM_WORLD, MYPE, IERROR )
      IF ( IERROR .NE. 0 ) THEN
        MSG = 'Error in MPI_COMM_WORLD.'
        CALL M3WARN( PNAME, 0, 0, MSG )
        IERROR = 1; RETURN
      END IF

C Initialize parallel I/O
        IF ( .NOT. PIO_RE_INIT( DATA_ORI, GL_NCOLS, GL_NROWS, NLAYS, NTHIK,
     &                          NCOLS, NROWS, NPCOL, NPROW, NPROCS,
     &                          MYPE, .TRUE. ) ) THEN
          MSG = 'Failed to initialize parallel I/O library.'
          CALL M3WARN( PNAME, 0, 0, MSG )
          IERROR = 1; RETURN
        END IF

C Initialize stencil exchange
      CALL SUBST_INIT( NPROCS, NPCOL, NPROW, GL_NCOLS, GL_NROWS, NLAYS,
     &                 NSPCS, MYPE, MNDIS, MEDIS, MSDIS, MWDIS,
     &                 DATA_ORI, GEO_ORI )

C Calculate processor-to-subdomain maps. This is done here to allow ROWSX_PE,
C COLSX_PE, MY_NROWS, MY_NCOLS, and MY_NBNDY to be passed to ICON

      CALL SUBDMAP( NPROCS, GL_NCOLS, GL_NROWS, NLAYS, NPCOL, NPROW,
     &              NCOLS_PE, NROWS_PE, COLSX_PE, ROWSX_PE,
     &              MAXCELLS, IERROR )

      MY_NCOLS = NCOLS_PE( MYPE + 1 )
      MY_NROWS = NROWS_PE( MYPE + 1 )
      MY_NBNDY = 2*NTHIK * ( MY_NCOLS + MY_NROWS + 2*NTHIK )

      RETURN
      END SUBROUTINE RECONFIG_DOMAIN
