
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
C $Header: /project/yoj/arc/CCTM/src/gas/ros3/rbinit.F,v 1.4 2011/10/21 16:11:10 yoj Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

      SUBROUTINE RBINIT
C***********************************************************************
C
C  Function: To initialize species tolerances, allocate arrays, and 
C            define grid structure
C
C  Preconditions: None
C
C  Return Values: None
C
C  Key Subroutines/Functions CALLED: None
C
C  Revision History: Prototype created by Jerry Gipson, August, 2004
C                    31 Jan 05 J.Young: dyn alloc - establish both horizontal
C                    & vertical domain specifications in one module (GRID_CONF)
C                    Get BLKSIZE from module GRID_CONF
C                    29 Jul 05 WTH: allocate variables used by degrade routines.
C                    28 Jun 10 J.Young: convert for Namelist redesign
C                    29 Mar 11 S.Roselle: Replaced I/O API include files
C                               with UTILIO_DEFN
C                      
C***********************************************************************
      USE GRID_CONF                ! horizontal & vertical domain specifications
      USE RBDATA                   ! Rosenbrock solver data
      USE CGRID_SPCS               ! CGRID mechanism species
      USE UTILIO_DEFN

      IMPLICIT NONE

C.....Includes:
      INCLUDE SUBST_RXCMMN         ! Mechanism reaction common block

C.....Arguments: NONE

C.....Parameters:
      CHARACTER( 16 ), PARAMETER   :: PNAME = 'RBINIT'    ! Procedure name
      REAL, PARAMETER              :: DEF_ATOL = 1.0E-07  ! Default ATOL
      REAL, PARAMETER              :: DEF_RTOL = 1.0E-03  ! Default RTOL

C.....External Functions:

C.....Local Variables: 
      CHARACTER( 132 ) :: XMSG     ! Log error message
      CHARACTER(  80 ) :: VARDESC  ! Description of environment variable 

      INTEGER N                    ! Loop index

      INTEGER COL                  ! Column number index
      INTEGER IAVGSIZE             ! Average number of cells per block
      INTEGER LEV                  ! Level number index
      INTEGER OFFSET               ! Pointer for start cell number in a block
      INTEGER NBLK                 ! Block number index
      INTEGER NCOUNT               ! Counter for number of cells for grid
      INTEGER NOXYZ                ! Total number of cells for grid
      INTEGER ROW                  ! Row number index
      INTEGER STATUS               ! Status code for functions

      REAL    DEFTOL               ! Default tolerance value

C***********************************************************************

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c..Initialize vars & allocate arrays used in sparse matrix treatment
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      LREORDER = .TRUE.

      N_SPEC = N_GC_SPC
      N_RXNS = NRXNS   ! loads RBDATA from RXCM.EXT

      MXRR = 3 * MXRCT
      MXRP = 3 * MXPRD

      MXCOUNT1 = N_GC_SPC * MAXGL3 * 3
      MXCOUNT2 = N_GC_SPC * MAXGL3 * 3

      ALLOCATE( NKUSERAT( NRXNS,NCS2 ),
     &          NDERIVL ( NRXNS,NCS2 ),
     &          NDERIVP ( NRXNS,NCS2 ), STAT = STATUS )
      IF ( STATUS .NE. 0 ) THEN
         XMSG = 'ERROR allocating NKUSERAT, NDERIVL or NDERIVP'
         CALL M3EXIT( PNAME, 0, 0, XMSG, XSTAT2 )
      END IF

      ALLOCATE( IRM2( NRXNS,MXRCT+MXPRD,NCS2 ),
     &          ICOEFF( NRXNS,MXRP,NCS2 ), STAT = STATUS )
      IF ( STATUS .NE. 0 ) THEN
         XMSG = 'ERROR allocating IRM2 or ICOEFF'
         CALL M3EXIT( PNAME, 0, 0, XMSG, XSTAT2 )
      END IF

      ALLOCATE( JARRAYPT( N_GC_SPC,N_GC_SPC,NCS2 ), STAT = STATUS )
      IF ( STATUS .NE. 0 ) THEN
         XMSG = 'ERROR allocating JARRAYPT'
         CALL M3EXIT( PNAME, 0, 0, XMSG, XSTAT2 )
      END IF

      ALLOCATE( JARRL( NRXNS,MXRR,NCS2 ),
     &          JARRP( NRXNS,MXRP,NCS2 ),
     &          JLIAL( NRXNS,MXRR,NCS2 ),
     &          JPIAL( NRXNS,MXRP,NCS2 ), STAT = STATUS )
      IF ( STATUS .NE. 0 ) THEN
         XMSG = 'ERROR allocating JARRL, JARRP, JLIAL, or JPIAL'
         CALL M3EXIT( PNAME, 0, 0, XMSG, XSTAT2 )
      END IF

      ALLOCATE( INEW2OLD( N_GC_SPC,NCS ),
     &          IOLD2NEW( N_GC_SPC,NCS ), STAT = STATUS )
      IF ( STATUS .NE. 0 ) THEN
         XMSG = 'ERROR allocating INEW2OLD or IOLD2NEW'
         CALL M3EXIT( PNAME, 0, 0, XMSG, XSTAT2 )
      END IF

      ALLOCATE( JZEROA( MXARRAY ),
     &          JZEROB( MXARRAY ), STAT = STATUS )
      IF ( STATUS .NE. 0 ) THEN
         XMSG = 'ERROR allocating JZEROA or JZEROB'
         CALL M3EXIT( PNAME, 0, 0, XMSG, XSTAT2 )
      END IF

      ALLOCATE( JZLO( NCS2 ),
     &          IDEC1LO( N_GC_SPC,NCS2 ),
     &          IDEC1HI( N_GC_SPC,NCS2 ), STAT = STATUS )
      IF ( STATUS .NE. 0 ) THEN
         XMSG = 'ERROR allocating JZLO, IDEC1LO or IDEC1HI'
         CALL M3EXIT( PNAME, 0, 0, XMSG, XSTAT2 )
      END IF

      ALLOCATE( IJDECA( MXCOUNT2 ),
     &          IJDECB( MXCOUNT2 ),
     &          IKDECA( MXCOUNT2 ),
     &          IKDECB( MXCOUNT2 ),
     &          KJDECA( MXCOUNT2 ),
     &          KJDECB( MXCOUNT2 ), STAT = STATUS )
      IF ( STATUS .NE. 0 ) THEN
         XMSG = 'ERROR allocating IJDECA, IJDECB, IKDECA, IKDECB, KJDECA, or KJDECB'
         CALL M3EXIT( PNAME, 0, 0, XMSG, XSTAT2 )
      END IF

      ALLOCATE( JHIZ1( N_GC_SPC,NCS2 ),
     &          JHIZ2( N_GC_SPC,NCS2 ),
     &          KZLO1( N_GC_SPC,NCS2 ),
     &          KZLO2( N_GC_SPC,NCS2 ),
     &          KZHI0( N_GC_SPC,NCS2 ),
     &          KZHI1( N_GC_SPC,NCS2 ), STAT = STATUS )
      IF ( STATUS .NE. 0 ) THEN
         XMSG = 'ERROR allocating JHIZ1, JHIZ2, KZLO1, KZLO2, KZHI0, or KZHI1'
         CALL M3EXIT( PNAME, 0, 0, XMSG, XSTAT2 )
      END IF

      ALLOCATE( KZERO( MXARRAY,NCS2 ), STAT = STATUS )
      IF ( STATUS .NE. 0 ) THEN
         XMSG = 'ERROR allocating KZERO'
         CALL M3EXIT( PNAME, 0, 0, XMSG, XSTAT2 )
      END IF

      ALLOCATE( KZILCH( N_GC_SPC,NCS2 ),
     &          MZHI0 ( N_GC_SPC,NCS2 ),
     &          MZHI1 ( N_GC_SPC,NCS2 ),
     &          MZILCH( N_GC_SPC,NCS2 ),
     &          MZLO1 ( N_GC_SPC,NCS2 ),
     &          MZLO2 ( N_GC_SPC,NCS2 ), STAT = STATUS )
      IF ( STATUS .NE. 0 ) THEN
         XMSG = 'ERROR allocating KZILCH, MZHI0, MZHI1, MZILCH, MZLO1, or MZLO2'
         CALL M3EXIT( PNAME, 0, 0, XMSG, XSTAT2 )
      END IF

      ALLOCATE( VDIAG( BLKSIZE,N_GC_SPC ), STAT = STATUS )
      IF ( STATUS .NE. 0 ) THEN
         XMSG = 'ERROR allocating VDIAG'
         CALL M3EXIT( PNAME, 0, 0, XMSG, XSTAT2 )
      END IF

      ALLOCATE( CC2( BLKSIZE,0:MXARRAY ), STAT = STATUS )
      IF ( STATUS .NE. 0 ) THEN
         XMSG = 'ERROR allocating CC2'
         CALL M3EXIT( PNAME, 0, 0, XMSG, XSTAT2 )
      END IF

c..cell & solver data
      ALLOCATE( BLKTEMP( BLKSIZE ),
     &          BLKPRES( BLKSIZE ),
     &          BLKCH2O( BLKSIZE ),
     &          BLKDENS( BLKSIZE ), STAT = STATUS )
      IF ( STATUS .NE. 0 ) THEN
         XMSG = 'ERROR allocating BLKTEMP, BLKPRES, BLKCH2O, or BLKDENS'
         CALL M3EXIT( PNAME, 0, 0, XMSG, XSTAT2 )
      END IF

      NJPHOT  = NPHOTAB
      ALLOCATE( RJBLK( BLKSIZE,NJPHOT ), STAT = STATUS )    
      IF ( STATUS .NE. 0 ) THEN
         XMSG = 'ERROR allocating RJBLK'
         CALL M3EXIT( PNAME, 0, 0, XMSG, XSTAT2 )
      END IF

      ALLOCATE( RKI( BLKSIZE,NRXNS ),
     &          ATOL( N_SPEC ),
     &          RTOL( N_SPEC ),
     &          Y( BLKSIZE,N_SPEC ), STAT = STATUS )
      IF ( STATUS .NE. 0 ) THEN
         XMSG = 'ERROR allocating RKI, ATOL, RTOL, or Y'
         CALL M3EXIT( PNAME, 0, 0, XMSG, XSTAT2 )
      END IF

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Set convergence tolerances for each species; currently uses
c  one set of tolerances for all species
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      VARDESC = 'Relative tolerance for Rosenbrock Solver'
      DEFTOL = DEF_RTOL
      GLBL_RTOL = ENVREAL( 'RB_RTOL', VARDESC, DEFTOL, STATUS )
      IF ( STATUS .EQ. 1 ) THEN
         XMSG = 'Environment variable RB_RTOL improperly formatted'
         CALL M3EXIT( PNAME, 0, 0, XMSG, XSTAT2 )
      ELSE IF ( STATUS .LT. 0 ) THEN
         GLBL_RTOL = DEF_RTOL
      END IF

      VARDESC = 'Absolute tolerance for Rosenbrock Solver'
      DEFTOL = DEF_ATOL
      GLBL_ATOL = ENVREAL( 'RB_ATOL', VARDESC, DEFTOL, STATUS )
      IF ( STATUS .EQ. 1 ) THEN
         XMSG = 'Environment variable RB_ATOL improperly formatted'
         CALL M3EXIT( PNAME, 0, 0, XMSG, XSTAT2 )
      ELSE IF ( STATUS .LT. 0 ) THEN
         GLBL_ATOL = DEF_ATOL
      END IF

      DO N = 1, N_GC_SPC
         ATOL( N ) = GLBL_ATOL
         RTOL( N ) = GLBL_RTOL
      END DO

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Get number of cells in grid and store i,j,k indices of cells in
c  sequential order
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      NCOUNT = 0
      DO LEV = 1, NLAYS
         DO COL = 1, MY_NCOLS
            DO ROW = 1, MY_NROWS
!        DO ROW = 1, MY_NROWS
!           DO COL = 1, MY_NCOLS
               NCOUNT = NCOUNT + 1
               CCOL( NCOUNT ) = COL
               CROW( NCOUNT ) = ROW
               CLEV( NCOUNT ) = LEV
            END DO
         END DO
      END DO

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Define block structure for grid; stop if maxblks exceeded
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      NOXYZ = NCOUNT
      NBLKS = 1 + ( NOXYZ - 1 ) / BLKSIZE
      IF ( NBLKS .GT. MXBLKS ) THEN
         WRITE( XMSG, 92020 ) NBLKS, MXBLKS
         CALL M3EXIT( PNAME, 0, 0, XMSG, XSTAT1 )
      END IF

      IAVGSIZE = 1 + ( NOXYZ - 1 ) / NBLKS
      IAVGSIZE = MIN( IAVGSIZE, BLKSIZE )
      OFFSET = 0

      DO NBLK = 1, NBLKS - 1
         BLKCNO( NBLK ) = OFFSET
         BLKLEN( NBLK ) = IAVGSIZE
         OFFSET = OFFSET + IAVGSIZE
      END DO
      BLKCNO( NBLKS ) = OFFSET
      BLKLEN( NBLKS ) = NOXYZ - ( ( NBLK-1 ) * IAVGSIZE )

      RETURN
      
C********************** FORMAT Statements ******************************      
92020 FORMAT( 1X, 'ERROR: Maximum Number of Blocks Exceeded',
     &            ' for Grid', 'NBLKS=', I3, 1X, ' MAXBLKS=',
     &            I3, '  Change GRPARMS.EXT' )

      END
