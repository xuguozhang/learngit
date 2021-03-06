
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
C $Header: /project/yoj/arc/BCON/src/m3conc/m3_bcout.F,v 1.2 2011/10/21 16:52:34 yoj Exp $ 

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%


      SUBROUTINE BCOUT( LOGUNIT, N_CTM_FLS, SDATE, STIME, NSTEPS,
     &                  NCOLS_IN, NROWS_IN, NLAYS_IN, NSPCS_IN, NSPCS_OUT,
     &                  SPMAP, CTM_FL_NAME, INFL_SP_NAME, SPNAME_OUT )

C*************************************************************************
 
C  Function: Reads the input models-3 concentration file(s) and opens and
C            writes the output BC file
              
C  Preconditions: None
  
C  Key Subroutines/Functions Called:   
 
C  Revision History:
C    Prototype created by Jerry Gipson, January, 1998
C    Modified by JG May, 1999 to treat PinG concs
C    02/25/02 Steve Howard (Jeff Young) - dynamic allocation
C    01/05/05 J.Young: vert dyn alloc - Use VGRD_DEFN eliminate malloc calls
C    13 Jul 11 J.Young: Replaced I/O API include files with M3UTILIO and
C                       Namelist for species definitions
C    23 May 12 J.Young: Replaced BC_PARMS include file with an F90 module
 
C*************************************************************************

      USE HGRD_DEFN   ! Module to store and load the horizontal grid variables
      USE VGRD_DEFN   ! vertical layer specifications
      USE M3UTILIO    ! IOAPI module
      USE CGRID_SPCS
      USE BC_PARMS    ! BCON parameters

      IMPLICIT NONE     

C Include Files: None

C Arguments: 
      INTEGER LOGUNIT           ! Unit number for output log
      INTEGER N_CTM_FLS         ! Number of input CTM files
      INTEGER SDATE             ! Date for BC Output
      INTEGER STIME             ! Time for BC output
      INTEGER NSTEPS            ! Run duration, as number of output time steps
      INTEGER NCOLS_IN          ! No. of columns in input conc file
      INTEGER NLAYS_IN          ! No. of layers in input conc file
      INTEGER NROWS_IN          ! No. of rows in input conc file
      INTEGER NSPCS_IN          ! Total No. of species in input conc file(s)
      INTEGER NSPCS_OUT         ! Number of BC species on output file(s)
      INTEGER :: SPMAP( * )     ! Map to CTM species from BC species
      CHARACTER( 16 ) :: CTM_FL_NAME( * )   ! Name of CTM_CONC file
      CHARACTER( 16 ) :: INFL_SP_NAME( * )  ! Name of input CTM species
      CHARACTER( 16 ) :: SPNAME_OUT( * )    ! Output file species names

C Parameters:
      REAL, PARAMETER :: CMIN = 1.0E-30  ! Minimum output concentration

C External Functions: 
 
C Local Variables:
      CHARACTER( 16 ) :: PNAME = 'BCOUT'  ! Procedure Name
      CHARACTER( 80 ) :: MSG              ! Log message
      CHARACTER( 16 ) :: VNAME            ! Species name on CTM conc file
      CHARACTER( 16 ) :: BC_FNAME( MXCTMS )  ! Logical names of BC Output file(s) 

      INTEGER C             ! Column loop indices
      INTEGER ERRCODE       ! Error code for Cray HPALLOC
      INTEGER FLN           ! BC output file number
      INTEGER INDX, ISP, V  ! Array indices for species
      INTEGER JDATE         ! Current date
      INTEGER JTIME         ! Current time
      INTEGER SPC           ! Species loop index 
      INTEGER L             ! Layer loop index
      INTEGER N             ! Loop indices for species
      INTEGER NBND          ! Bndry cell loop index
      INTEGER NCELL         ! Boundary cell index
      INTEGER R             ! Row loop indices
      INTEGER STEP          ! Time step loop index
      INTEGER TSTEP         ! Time step on CTM file, hhmmss

      INTEGER :: COL_LOC( NBNDY )  ! Output BC col corresponding to
                                   ! a cell in the input CTM file
      INTEGER :: ROW_LOC( NBNDY )  ! Output BC row corresponding to
                                   ! a cell in the input CTM file

      LOGICAL LNEG                 ! Flag for negative concentratuin

      REAL    DMIN   ! Smallest distance between cell centers
      REAL    LAT    ! Latitude of center of cell for the BC output file
      REAL    LON    ! Longitude of center of cell for the BC output file
      REAL    X1     ! longitudenal distance between cell centers
      REAL    Y1     ! latitudinal distance between cell centers

      REAL    :: LAT_OUT( NBNDY )              ! Lat of cells in BC output file
      REAL    :: LON_OUT( NBNDY )              ! Lon of cells in BC output file

      REAL    :: LAT_IN( NCOLS_IN,NROWS_IN )   ! Lat of cells in CTM conc file
      REAL    :: LON_IN( NCOLS_IN,NROWS_IN )   ! Lon of cells in CTM conc file

      REAL    :: COUT( NBNDY,NLAYS )             ! Substituted output BC conc
      REAL    :: CONCIN( NCOLS_IN,NROWS_IN,NLAYS_IN ) ! Input concs
      REAL    :: BCIN( NBNDY,NLAYS_IN,NSPCS_IN ) ! Horizontally set BCs
      REAL    :: BCVI( NBNDY,NLAYS,NSPCS_IN )    ! Vertically interpolated BCs

C***********************************************************************

      write( logunit,* ) ' '
      write( logunit,* ) '    NCOLS_IN: ', NCOLS_IN
      write( logunit,* ) '    NROWS_IN: ', NROWS_IN
      write( logunit,* ) '    NLAYS_IN: ', NLAYS_IN
      write( logunit,* ) '    NSPCS_IN: ', NSPCS_IN
      write( logunit,* ) '    NBNDY:    ', NBNDY
      write( logunit,* ) '    NLAYS:    ', NLAYS
      write( logunit,* ) ' '

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Compute the lat and lon of the center of each input cell
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IF ( .NOT. DESC3 ( CTM_FL_NAME( 1 ) ) ) THEN
          MSG = 'Could not read DESC of  ' // CTM_FL_NAME( N ) 
     &       // ' file'
         CALL M3EXIT( PNAME, JDATE, JTIME, MSG, XSTAT2 )
      END IF

      DO C = 1, NCOLS_IN
         DO R = 1, NROWS_IN
            CALL LAT_LON( C, R, GDTYP3D, XORIG3D, YORIG3D,
     &                    XCELL3D, YCELL3D, XCENT3D, YCENT3D,
     &                    P_ALP3D, P_BET3D, P_GAM3D,
     &                    LAT_IN( C,R ), LON_IN( C,R ) )
         END DO
      END DO

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Compute the lat and lon of the center of each output BC cell
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
C South border
      NCELL = 0
      DO C = 1, NCOLS + 1
         R = 0
         NCELL = NCELL + 1
         CALL LAT_LON( C, R, GDTYP_GD, XORIG_GD, YORIG_GD, 
     &                 XCELL_GD, YCELL_GD, XCENT_GD, YCENT_GD,
     &                 P_ALP_GD, P_BET_GD, P_GAM_GD,
     &                 LAT_OUT( NCELL ), LON_OUT( NCELL ) )
      END DO

C East border
      DO R = 1, NROWS + 1
         C = NCOLS + 1
         NCELL = NCELL + 1
         CALL LAT_LON( C, R, GDTYP_GD, XORIG_GD, YORIG_GD, 
     &                 XCELL_GD, YCELL_GD, XCENT_GD, YCENT_GD,
     &                 P_ALP_GD, P_BET_GD, P_GAM_GD,
     &                 LAT_OUT( NCELL ), LON_OUT( NCELL ) )
      END DO

C North border
      DO C = 0, NCOLS
         R = NROWS + 1
         NCELL = NCELL + 1
         CALL LAT_LON( C, R, GDTYP_GD, XORIG_GD, YORIG_GD, 
     &                 XCELL_GD, YCELL_GD, XCENT_GD, YCENT_GD,
     &                 P_ALP_GD, P_BET_GD, P_GAM_GD,
     &                 LAT_OUT( NCELL ), LON_OUT( NCELL ) )
      END DO

C West border
      DO R = 0, NROWS
         C = 0
         NCELL = NCELL + 1
         CALL LAT_LON( C, R, GDTYP_GD, XORIG_GD, YORIG_GD, 
     &                 XCELL_GD, YCELL_GD, XCENT_GD, YCENT_GD,
     &                 P_ALP_GD, P_BET_GD, P_GAM_GD,
     &                 LAT_OUT( NCELL ), LON_OUT( NCELL ) )
      END DO

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Map the CTM file LAT/LONs to the BC file LAT/LONs
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      DO N = 1, NBNDY
         LAT = LAT_OUT( N )
         LON = LON_OUT( N )
         DMIN = 1.0E+30
         DO C = 1, NCOLS_IN
            DO R = 1, NROWS_IN
               Y1 = ( LAT - LAT_IN( C,R ) ) ** 2
               X1 = ( LON - LON_IN( C,R ) ) ** 2
               IF ( ( X1 + Y1 ) .LT. DMIN ) THEN           
                  DMIN = X1 + Y1
                  COL_LOC( N ) = C
                  ROW_LOC( N ) = R
               END IF
             END DO
         END DO
      END DO

!     do n = 1, nbndy
!          write(*, '(3I4,6(1PE12.4) )') n, COL_LOC( n ),
!    &       ROW_LOC( n ),
!    &       LAT_OUT( n ), LON_OUT( n ),
!    &       LAT_IN( COL_LOC( n ), ROW_LOC( n ) ),
!    &       LON_IN( COL_LOC( n ), ROW_LOC( n ) ) 
!     enddo           
 
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Call the spatial interpolation routine to log info only 
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      CALL VINTERP( LOGUNIT, SDATE, STIME, NCOLS_IN, NROWS_IN, NLAYS_IN,
     &              NSPCS_IN, COL_LOC, ROW_LOC, BCIN, BCVI, CTM_FL_NAME )
 
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Call the routine to open the Models3 BC output file
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IF ( .NOT. DESC3 ( CTM_FL_NAME( 1 ) ) ) THEN
         MSG = 'Could not read DESC of  ' // CTM_FL_NAME( 1 ) // ' file'
         CALL M3EXIT( PNAME, 0, 0, MSG, XSTAT2 )
      END IF

      TSTEP = TSTEP3D

      CALL OPN_BC_FILE( LOGUNIT, SDATE, STIME, TSTEP, NSPCS_OUT, 
     &                  SPNAME_OUT, BC_FNAME, 1 )  

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Top of loop over output time steps 
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      JDATE = SDATE
      JTIME = STIME

      DO STEP = 1, NSTEPS

C Read the concentration file(s)
         LNEG = .FALSE.
         ISP = 0

         DO N = 1, N_CTM_FLS

            IF ( .NOT. DESC3 ( CTM_FL_NAME( N ) ) ) THEN
               MSG = 'Could not read DESC of  ' // CTM_FL_NAME( N ) 
     &              // ' file'
               CALL M3EXIT( PNAME, JDATE, JTIME, MSG, XSTAT2 )
            END IF

            DO V = 1, NVARS3D

               ISP = ISP + 1
               VNAME = INFL_SP_NAME( V )
                  
               IF ( .NOT. READ3( CTM_FL_NAME( N ), VNAME, ALLAYS3, JDATE, 
     &                          JTIME, CONCIN( 1,1,1 ) ) ) THEN
                  MSG = 'Could not read input CTM Conc file ' //
     &                   CTM_FL_NAME( N )         
                  CALL M3EXIT( PNAME, JDATE, JTIME, MSG, XSTAT2 )
               END IF


               DO NBND = 1, NBNDY
                  C = COL_LOC( NBND )
                  R = ROW_LOC( NBND )
                  DO L = 1, NLAYS_IN
                     BCIN( NBND,L,ISP ) = CONCIN( C,R,L )
                  END DO
               END DO

            END DO 

         END DO

C Do the spatial interpolation
         CALL VINTERP( LOGUNIT, JDATE, JTIME, NCOLS_IN, NROWS_IN, 
     &                 NLAYS_IN, NSPCS_IN, COL_LOC, ROW_LOC, BCIN, 
     &                 BCVI, CTM_FL_NAME )
      
C Write the output BC concentrations 
         DO N = 1, NSPCS_OUT

            FLN = ( N - 1 ) / MXVARS3 + 1
            VNAME = SPNAME_OUT( N )

            INDX = SPMAP( N )

            DO L = 1, NLAYS
               DO NBND = 1, NBNDY
                  COUT( NBND,L ) = BCVI( NBND,L,INDX )
                  IF ( COUT( NBND,L ) .LT. 0.0 ) THEN
                     LNEG = .TRUE.
                  ELSE IF ( COUT( NBND,L ) .LT. CMIN ) THEN
                     COUT( NBND,L ) = CMIN 
                  END IF
               END DO
            END DO

            IF ( .NOT. WRITE3( BC_FNAME( FLN ), VNAME, JDATE, JTIME,
     &                        COUT( 1,1 ) ) ) THEN
               MSG =  'Could not WRITE species ' //  VNAME // 
     &                'to file ' // BC_FNAME( FLN ) 
               CALL M3EXIT( PNAME, JDATE, JTIME, MSG, XSTAT2 )
            END IF

         END DO

         IF ( LNEG ) THEN
            MSG = 'Negative BCs output'
            CALL M3EXIT( PNAME, JDATE, JTIME, MSG, XSTAT2 ) 
         END IF

         WRITE( LOGUNIT, '( /5X, 3( A, :, 1X ), I8, ":", I6.6 )' )
     &         'Timestep written to', BC_FNAME( FLN ),
     &         'for date and time', JDATE, JTIME

         CALL NEXTIME( JDATE, JTIME, TSTEP )

      END DO

      RETURN

      END
