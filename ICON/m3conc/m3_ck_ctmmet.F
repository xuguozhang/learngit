
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
C $Header: /project/yoj/arc/ICON/src/m3conc/m3_ck_ctmmet.F,v 1.2 2011/10/21 16:41:53 yoj Exp $ 

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%


      SUBROUTINE CK_CTMMET_FL( LOGUNIT, SDATE, STIME, CTM_FL_NAME )

C***********************************************************************
 
C  Function: To check input MET_CRO_3D_CRS file for consistency with
C            the CTM_CONC file
              
C  Preconditions: None
  
C  Key Subroutines/Functions Called: None
 
C  Revision History: Prototype created by Jerry Gipson, May, 1999
C    08 Jun 11 J.Young: Replaced I/O API include files with UTILIO_DEFN
C    21 May 12 J.Young: Replaced IC_PARMS include file with an F90 module
 
C***********************************************************************

      USE UTILIO_DEFN
      USE IC_PARMS     ! ICON parameters

      IMPLICIT NONE     

C Include Files:

C Arguments:
      CHARACTER( 16 ) :: CTM_FL_NAME( * )              ! Names of CTM files

      INTEGER LOGUNIT                 ! Unit number for output log
      INTEGER SDATE                   ! Start date
      INTEGER STIME                   ! Start time

C Parameters: None

C External Functions: None

C Local Variables:
      CHARACTER( 80 ) :: MSG          ! Log message
      CHARACTER( 16 ) :: PNAME = 'CK_CTMMET_FL'  ! Procedure Name
      CHARACTER( 15 ) :: VAL1         ! Character value of real
      CHARACTER( 15 ) :: VAL2         ! Character value of real

      INTEGER L           ! Loop index
      INTEGER FTYPE1      ! File 1 file type
      INTEGER NCOLS1      ! File 1 number of columns
      INTEGER NROWS1      ! File 1 number of rows
      INTEGER NLAYS1      ! File 1 number of levels
      INTEGER NTHIK1      ! File 1 boundary thickness
      INTEGER GDTYP1      ! File 1 horizontal grid type
      INTEGER VGTYP1      ! File 1 Vertical coordinate type

      LOGICAL LERROR      ! Error Flag
 
      REAL    P_ALP1      ! File 1 map projection parameter      
      REAL    P_BET1      ! File 1 map projection parameter   
      REAL    P_GAM1      ! File 1 map projection parameter
      REAL    XORIG1      ! File 1 X-origin
      REAL    YORIG1      ! File 1 Y-origin
      REAL    XCELL1      ! File 1 X-dimension of cells
      REAL    YCELL1      ! File 1 Y-dimension of cells
      REAL    XCENT1      ! File 1 X-center of coordinate system
      REAL    YCENT1      ! File 1 Y-center of coordinate system
      REAL    VGTOP1      ! File 1 model top

      REAL   ::  VGLVS1( MXLAYS3+1 ) ! File vertical layer heights
   
C***********************************************************************

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Write out report data
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      MSG = 'MET_CRO_3D_CRS File being checked for ' //
     &      'consistent header data' 
      CALL M3MESG( MSG )

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Get header data for CTM file 1 and create a list of species in the
c  CTM files
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IF ( .NOT. DESC3 ( CTM_FL_NAME( 1 ) ) ) THEN
         MSG = 'Could not read DESC of  ' // CTM_FL_NAME( 1 ) 
     &         // ' file'
         CALL M3EXIT( PNAME, 0, 0, MSG, XSTAT2 )
      END IF

      FTYPE1 = FTYPE3D
      NCOLS1 = NCOLS3D
      NROWS1 = NROWS3D
      NLAYS1 = NLAYS3D
      NTHIK1 = NTHIK3D
      GDTYP1 = GDTYP3D
      P_ALP1 = P_ALP3D
      P_BET1 = P_BET3D
      P_GAM1 = P_GAM3D
      XORIG1 = XORIG3D
      YORIG1 = YORIG3D
      XCELL1 = XCELL3D
      YCELL1 = YCELL3D
      XCENT1 = XCENT3D
      YCENT1 = YCENT3D
      VGTYP1 = VGTYP3D
      VGTOP1 = VGTOP3D
      DO L = 1 , NLAYS3D + 1
         VGLVS1( L ) = VGLVS3D( L )
      END DO
     
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Open the MET_CRO_3D_CRS file
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IF ( .NOT. OPEN3( MET_CRO_3D_CRS, FSREAD3, PNAME ) ) THEN
         MSG = 'Could not open ' // MET_CRO_3D_CRS // ' file'
         CALL M3EXIT( PNAME, 0, 0, MSG, XSTAT1 )
      END IF

      IF ( .NOT. DESC3( MET_CRO_3D_CRS ) ) THEN
         MSG = 'Could not read DESC of  ' // MET_CRO_3D_CRS 
     &            // ' file'
         CALL M3EXIT( PNAME, 0, 0, MSG, XSTAT2 )
      END IF

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Check MET_CRO_3D_CRS file
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      WRITE( MSG, '( ''     Differences found between files '', A, 
     &               '' and '', A, '':'' )' ) CTM_FL_NAME( 1 ), 
     &         MET_CRO_3D_CRS

      CALL M3MESG( MSG )

      LERROR = .FALSE.
         
      IF ( FTYPE1 .NE. FTYPE3D ) THEN
         WRITE( LOGUNIT, 94020 ) FTYPE1, FTYPE3D
         LERROR = .TRUE.
      END IF

      IF ( GDTYP1 .NE. GDTYP3D ) THEN
         WRITE( LOGUNIT, 94200 ) GDTYP1, GDTYP3D
         LERROR = .TRUE.
      END IF

      WRITE( VAL1, 94000 ) P_ALP1
      WRITE( VAL2, 94000 ) P_ALP3D
      IF ( VAL1 .NE. VAL2 ) THEN
         WRITE( LOGUNIT, 94220 ) P_ALP1, P_ALP3D
         LERROR = .TRUE.
      END IF

      WRITE( VAL1, 94000 ) P_BET1
      WRITE( VAL2, 94000 ) P_BET3D
      IF ( VAL1 .NE. VAL2 ) THEN
         WRITE( LOGUNIT, 94240 ) P_BET1, P_BET3D
         LERROR = .TRUE.
      END IF

      WRITE( VAL1, 94000 ) P_GAM1
      WRITE( VAL2, 94000 ) P_GAM3D
      IF ( VAL1 .NE. VAL2 ) THEN
         WRITE( LOGUNIT, 94260 ) P_GAM1, P_GAM3D
         LERROR = .TRUE.
      END IF

      WRITE( VAL1, 94000 ) XORIG1
      WRITE( VAL2, 94000 ) XORIG3D
      IF ( VAL1 .NE. VAL2 ) THEN
         WRITE( LOGUNIT, 94280 ) XORIG1, XORIG3D
         LERROR = .TRUE.
      END IF

      WRITE( VAL1, 94000 ) YORIG1
      WRITE( VAL2, 94000 ) YORIG3D
      IF ( VAL1 .NE. VAL2 ) THEN
         WRITE( LOGUNIT, 94300 ) YORIG1, YORIG3D
         LERROR = .TRUE.
      END IF

      WRITE( VAL1, 94000 ) XCELL1
      WRITE( VAL2, 94000 ) XCELL3D
      IF ( VAL1 .NE. VAL2 ) THEN
         WRITE( LOGUNIT, 94320 ) XCELL1, XCELL3D
         LERROR = .TRUE.
      END IF

      WRITE( VAL1, 94000 ) YCELL1
      WRITE( VAL2, 94000 ) YCELL3D
      IF ( VAL1 .NE. VAL2 ) THEN
         WRITE( LOGUNIT, 94340 ) YCELL1, YCELL3D
         LERROR = .TRUE.
      END IF

      WRITE( VAL1, 94000 ) XCENT1
      WRITE( VAL2, 94000 ) XCENT3D
      IF ( VAL1 .NE. VAL2 ) THEN
         WRITE( LOGUNIT, 94360 ) XCENT1, XCENT3D
         LERROR = .TRUE.
      END IF

      WRITE( VAL1, 94000 ) YCENT1
      WRITE( VAL2, 94000 ) YCENT3D
      IF ( VAL1 .NE. VAL2 ) THEN
         WRITE( LOGUNIT, 94380 ) YCENT1, YCENT3D
         LERROR = .TRUE.
      END IF

      WRITE( VAL1, 94000 ) VGTOP1
      WRITE( VAL2, 94000 ) VGTOP3D
      IF ( VAL1 .NE. VAL2 ) THEN
         WRITE( LOGUNIT, 94420 ) VGTOP1, VGTOP3D
         LERROR = .TRUE.
      END IF

      DO L = 1 , NLAYS1 + 1
            WRITE( VAL1, 94000 ) VGLVS1(  L )
            WRITE( VAL2, 94000 ) VGLVS3D( L )
            IF ( VAL1 .NE. VAL2 ) THEN
            WRITE( LOGUNIT, 94440 ) L, VGLVS1( L ), L,
     &                              VGLVS3D( L )      
            LERROR = .TRUE.
         END IF
      END DO
 
      IF ( .NOT. CHECK3(  MET_CRO_3D_CRS, 'ALL', SDATE, STIME ) ) THEN
         MSG = 'Requested time is not on the ' // MET_CRO_3D_CRS
     &            // ' file'
         WRITE( LOGUNIT, 94480 ) MSG
         LERROR = .TRUE.
      END IF
             
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  If inconsistency found, then stop, else return
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IF ( .NOT. LERROR ) THEN
         WRITE( LOGUNIT, 94460 )
      ELSE
         MSG = 'MET_CRO_3D_CRS file inconsistent: stopping' 
         CALL M3EXIT( PNAME, 0, 0, MSG, XSTAT2 )
      END IF

      RETURN

C************************* FORMAT STATEMENTS ***************************

94000 FORMAT( E15.5 )
94020 FORMAT( 10X, 'CTM_CONC_1 FTYPE = ', I3, 3X, 'MET_CRO_3D_CRS FTYPE = ', I3 )
94200 FORMAT( 10X, 'CTM_CONC_1 GDTYP = ', I3, 3X, 'MET_CRO_3D_CRS GDTYP = ', I3 )
94220 FORMAT( 10X, 'CTM_CONC_1 P_ALP = ', 1PE12.5, 3X, 'MET_CRO_3D_CRS P_ALP = ', 1PE12.5 )
94240 FORMAT( 10X, 'CTM_CONC_1 P_BET = ', 1PE12.5, 3X, 'MET_CRO_3D_CRS P_BET = ', 1PE12.5 )
94260 FORMAT( 10X, 'CTM_CONC_1 P_GAM = ', 1PE12.5, 3X, 'MET_CRO_3D_CRS P_GAM = ', 1PE12.5 )
94280 FORMAT( 10X, 'CTM_CONC_1 XORIG = ', 1PE12.5, 3X, 'MET_CRO_3D_CRS XORIG = ', 1PE12.5 )
94300 FORMAT( 10X, 'CTM_CONC_1 YORIG = ', 1PE12.5, 3X, 'MET_CRO_3D_CRS YORIG = ', 1PE12.5 )
94320 FORMAT( 10X, 'CTM_CONC_1 XCELL = ', 1PE12.5, 3X, 'MET_CRO_3D_CRS XCELL = ', 1PE12.5 )
94340 FORMAT( 10X, 'CTM_CONC_1 YCELL = ', 1PE12.5, 3X, 'MET_CRO_3D_CRS YCELL = ', 1PE12.5 )
94360 FORMAT( 10X, 'CTM_CONC_1 XCENT = ', 1PE12.5, 3X, 'MET_CRO_3D_CRS XCENT = ', 1PE12.5 )
94380 FORMAT( 10X, 'CTM_CONC_1 YCENT = ', 1PE12.5, 3X, 'MET_CRO_3D_CRS YCENT = ', 1PE12.5 )
94420 FORMAT( 10X, 'CTM_CONC_1 VGTOP = ', 1PE12.5, 3X, 'MET_CRO_3D_CRS VGTOP = ', 1PE12.5 )
94440 FORMAT( 10X, 'CTM_CONC_1 VGLVS(', I2, ' ) = ', 1PE12.5,
     &         'MET_CRO_3D_CRS VGLVS(', I2, ' ) = ', 1PE12.5 )
94460 FORMAT( 10X, 'NONE' )
94480 FORMAT( A )

      END
