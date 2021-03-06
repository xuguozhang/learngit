
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
C $Header: /project/yoj/arc/ICON/src/m3conc/m3_vinterp.F,v 1.2 2011/10/21 16:41:54 yoj Exp $ 

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%


      SUBROUTINE VINTERP( CTM_FL_NAME, LOGUNIT, SDATE, STIME,
     &                    NCOLS_IN, NROWS_IN, NLAYS_IN, NSPCS_IN,
     &                    COL_LOC, ROW_LOC, PRE_COL_LOC, PRE_ROW_LOC,
     &                    CONCIN, CONCVI )

C***********************************************************************
 
C  Function: Interpolates/Extrapolates concentrations in vertical.
C            The number of layers in CONCIN is collapsed or expanded
C            according to the number of layers in env var LAYER_FILE.
C            Interpolation is done using rational function interpolation
C            ( Numerical Recipes, Press et al.) or linear 
C            interpolation.  When extrapolation is required, the 
C            concentration of the outside layer is used. If the input 
C            file has only one layer, the concentrations in that layer
C            are used for all output layers.
              
C  Preconditions: None
  
C  Key Subroutines/Functions Called: LR_INTERP  
 
C  Revision History:
C     Prototype created by Jerry Gipson, January, 1998          
C     Modified by JG 5/26/99 to treat PinG plumes
C     02/09/00 David Wong, LM
C        -- replaced NROWS and NCOLS with MY_NROWS and MY_NCOLS,
C           respectively, in loops
C        -- blocked all HPALLOC or HPDALLOC calls by using a CPP flag F90
C     01/24/02 Steve Howard (Jeff Young) - dynamic allocation
C     12/13/04 J.Young: vert dyn alloc - Use VGRD_DEFN
C     08 Jun 11 J.Young: Replaced I/O API include files with UTILIO_DEFN
C     05 Jul 11 David Wong: - added PRE_COL_LOC and PRE_ROW_LOC to hold
C                             pre normalized value of COL_LOC and ROW_LOC,
C                             respectively
C                           - used COLSX_PE and ROWSX_PE to determine the
C                             beginning and ending column and row number for
C                             calling INTERPX with MET_CRO_3D_FIN file
C                           - used PRE_COL_LOC and PRE_ROW_LOC to determine the
C                             beginning and ending column and row number for
C                             calling INTERPX with MET_CRO_3D_CRS file
C     21 May 12 J.Young: Replaced IC_PARMS include file with an F90 module
                    
C***********************************************************************

      USE HGRD_DEFN   ! Module to store and load the horizontal grid variables
      USE VGRD_DEFN   ! vertical layer specifications
      USE UTILIO_DEFN
      USE IC_PARMS    ! ICON parameters

      IMPLICIT NONE     

C Include Files:

C Arguments:
      CHARACTER( 16 ) :: CTM_FL_NAME( * )  ! Name of input conc file
      INTEGER    LOGUNIT                 ! Unit number for output log
      INTEGER    SDATE                   ! Date for IC Output
      INTEGER    STIME                   ! Time for IC output
      INTEGER    NCOLS_IN                ! No. of columns in input conc file
      INTEGER    NROWS_IN                ! No. of rows in input conc file
      INTEGER    NLAYS_IN                ! No. of layers in input conc file
      INTEGER    NSPCS_IN                ! No. of species in input conc file
      INTEGER :: COL_LOC( NCOLS,NROWS )  ! Output IC col corresponding to &
      INTEGER :: ROW_LOC( NCOLS,NROWS )  ! Output IC row corresponding to
                                         ! a cell in the input conc file
      INTEGER :: PRE_COL_LOC( NCOLS,NROWS )  ! pre normalized COL_LOC
      INTEGER :: PRE_ROW_LOC( NCOLS,NROWS )  ! pre normalized ROW_LOC
      REAL    :: CONCIN( NCOLS_IN,NROWS_IN,NLAYS_IN,* )  ! Input conc array
      REAL    :: CONCVI( NCOLS,NROWS,NLAYS,* )           ! Output IC array

C Parameters: None

C External Functions: None

C Local Variables:
      CHARACTER( 20 ) :: CHR1     ! Value of variable 1 in character data
      CHARACTER( 20 ) :: CHR2     ! Value of variable 1 in character data
      CHARACTER( 80 ) :: MSG      ! Log message
      CHARACTER( 16 ) :: PNAME = 'VINTERP'  ! Procedure Name
      CHARACTER( 16 ) :: VNAME    ! Variable Name

      INTEGER ABORT          ! Abort code for Cray HPALLOC
      INTEGER C, CIN         ! Loop indices for columns
      INTEGER ERRCODE        ! Error code for Cray HPALLOC
      INTEGER L              ! Loop index for vertical layers
      INTEGER MXLEV          ! Largest no. of levels
      INTEGER R, RIN         ! Loop indices for rows
      INTEGER STATUS         ! Staus code
      INTEGER V              ! Loop index for variables

      LOGICAL LDEC           ! Flag for monotonic decreasing layer levels
      LOGICAL LINC           ! Flag for monotonic increasing layer levels
      LOGICAL L_IDENTICAL    ! Flag for identical vert coord systems      
      LOGICAL L_RATINT       ! Flag to use rational function interpolation 
      LOGICAL L_SAME_SCALE   ! Flag for same vert coord systems but 
                             ! different resolutions  

      REAL    DELY  ! Error estimate for conc interpolated by rational func
      REAL    X3    ! Vertical coordinate used in interpolation
      REAL    Y     ! Interpolated concentration

      REAL   :: WORKA(  MXLAYS3 )   ! Work array for conc input
      REAL   :: X3_OLD( MXLAYS3 )   ! Old Vertical coordinate values

      REAL   :: HT_IC( NCOLS,NROWS,NLAYS )            ! New mid-layer heights
      REAL   :: HT_CTM( NCOLS_IN,NROWS_IN,NLAYS_IN )  ! Old mid-layer heights
     
      INTEGER :: BEG_COL, END_COL, BEG_ROW, END_ROW          ! Fine file indices
      INTEGER :: BEG_COL_C, END_COL_C, BEG_ROW_C, END_ROW_C  ! Coarse file indices
 
C***********************************************************************

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Determine type of interpolation to use: linear or rational function
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IF ( .NOT. DESC3( CTM_FL_NAME( 1 ) ) ) THEN
         MSG = 'Could not read DESC of  ' // CTM_FL_NAME( 1 ) 
     &         // ' file'
         CALL M3EXIT( PNAME, SDATE, STIME, MSG, XSTAT2 )
      END IF

      WRITE( LOGUNIT, 92000 )

      L_RATINT = .FALSE.
      MSG = 'Flag for interpolation by rational function'
!     L_RATINT = ENVYN( 'RATIONAL_FUNC', MSG, L_RATINT, STATUS )  
      IF ( .NOT. L_RATINT ) THEN
         MSG = 'Linear Vertical interpolation method'
      ELSE
         MSG = 'Rational Function Vertical interpolation method'
      END IF

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Check for consistent vertical coordinates
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      L_IDENTICAL  = .TRUE.
      L_SAME_SCALE = .TRUE.

c..the following two lines are for testing only
!     L_IDENTICAL  = .FALSE.
!     L_SAME_SCALE = .FALSE.

      IF ( VGTYP_GD .NE. VGTYP3D .OR. VGTOP_GD .NE. VGTOP3D) THEN 
         L_IDENTICAL  = .FALSE.
         L_SAME_SCALE = .FALSE.
      END IF

      IF ( NLAYS .EQ. NLAYS_IN ) THEN
         DO L = 1, NLAYS + 1
            WRITE( CHR1, 94000 ) VGLVS_GD( L )
            WRITE( CHR2, 94000 ) VGLVS3D ( L )
            IF ( CHR1 .NE. CHR2 ) L_IDENTICAL  = .FALSE.
         END DO
      ELSE
         L_IDENTICAL  = .FALSE. 
      END IF

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  For identical vertical coordinates, copy the CTM concs to the output
c  IC array and return
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IF ( L_IDENTICAL ) THEN

         WRITE( LOGUNIT, 92020 ) 

         DO C = 1, MY_NCOLS
            DO R = 1, MY_NROWS
               CIN = COL_LOC( C, R )
               RIN = ROW_LOC( C, R )
               DO L = 1, NLAYS
                  DO V = 1, NSPCS_IN
                     CONCVI( C, R, L, V ) = CONCIN( CIN, RIN, L, V )
                  END DO
               END DO
            END DO
         END DO

         RETURN

      END IF

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Interpolate by VGLEVS for vertical coords of same type but different
c  resolution
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IF ( L_SAME_SCALE ) THEN

         WRITE( LOGUNIT, 92040 )
         WRITE( LOGUNIT, 92060 ) VGDESC( VGTYP_GD )
         WRITE( LOGUNIT, 92080 )

         MXLEV = MAX( NLAYS + 1, NLAYS_IN + 1 )

         DO L = 1, MXLEV 

            IF ( L .LE. NLAYS + 1 .AND. L .LE. NLAYS_IN + 1 ) THEN
               WRITE( LOGUNIT, 92100 ) L, VGLVS_GD( L ), VGLVS3D( L )
            ELSE IF ( L .LE. NLAYS + 1 .AND. L .GT. NLAYS_IN + 1 ) THEN
               WRITE( LOGUNIT, 92100 ) L, VGLVS_GD( L )
            ELSE IF ( L .GT. NLAYS + 1 .AND. L .LE. NLAYS_IN + 1 ) THEN
               WRITE( LOGUNIT, 92120 ) L, VGLVS3D( L )
            END IF

         END DO        

         WRITE( LOGUNIT, 92140 ) MSG 

         DO L = 1, NLAYS3D 
            X3_OLD( L ) = 0.5 * ( VGLVS3D( L ) +  VGLVS3D( L+1 ) )
         END DO

         LINC = .FALSE.
         LDEC = .FALSE.
         IF ( VGLVS3D ( NLAYS_IN ) .GT. VGLVS3D ( 1 ) ) THEN
            LINC = .TRUE.
         ELSE
            LDEC = .TRUE.
         END IF

         DO C = 1, MY_NCOLS
            DO R = 1, MY_NROWS
               CIN = COL_LOC( C,R )
               RIN = ROW_LOC( C,R )
               DO V = 1, NSPCS_IN    

                  DO L = 1, NLAYS_IN
                     WORKA( L ) = CONCIN( CIN,RIN,L,V )
                  END DO

                  DO L = 1, NLAYS

                     IF ( NLAYS_IN .EQ. 1 ) THEN
                        CONCVI( C,R,L,V ) = WORKA( 1 )

                     ELSE

                        X3 = 0.5 * ( VGLVS_GD( L ) +  VGLVS_GD( L + 1 ) )

                        IF ( LINC .AND. X3 .LE. X3_OLD( 1 ) ) THEN
                           CONCVI( C,R,L,V ) = WORKA( 1 )
                        ELSE IF ( LDEC .AND. X3 .GE. X3_OLD( 1 ) ) THEN
                           CONCVI( C,R,L,V ) = WORKA( 1 )
                        ELSE IF ( LINC .AND. X3 .GE. X3_OLD( NLAYS_IN ) ) THEN
                           CONCVI( C,R,L,V ) = WORKA( NLAYS_IN )
                        ELSE IF ( LDEC .AND. X3 .LE. X3_OLD( NLAYS_IN ) ) THEN
                           CONCVI( C,R,L,V ) = WORKA( NLAYS_IN )
                        ELSE
                           CALL LR_INTERP( L_RATINT, X3_OLD, WORKA, NLAYS_IN,
     &                                     X3, Y, DELY )
                           CONCVI( C,R,L,V ) = Y
                        END IF

                     END IF

                  END DO 
 
               END DO
            END DO
         END DO

         RETURN

      END IF

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c   Interpolate by height for all other vertical grid types; a dynamic
c   array holding heights will need to be allocated
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      WRITE( LOGUNIT, 92160 )
      WRITE( LOGUNIT, 92140 ) MSG

#ifdef parallel
      BEG_COL = COLSX_PE( 1, MYPE+1 )
      END_COL = COLSX_PE( 2, MYPE+1 )
      BEG_ROW = ROWSX_PE( 1, MYPE+1 )
      END_ROW = ROWSX_PE( 2, MYPE+1 )
#else
      BEG_COL = 1
      END_COL = NCOLS
      BEG_ROW = 1
      END_ROW = NROWS
#endif

C Get the layer mid-point heights
      VNAME = 'ZH'
      IF ( .NOT. INTERPX( MET_CRO_3D_FIN, VNAME, PNAME,
     &                    BEG_COL, END_COL, BEG_ROW, END_ROW, 
     &                    1,NLAYS, SDATE, STIME, HT_IC ) ) THEN
         MSG = 'Could not read layer heights from ' // MET_CRO_3D_FIN 
         CALL M3EXIT( PNAME, SDATE, STIME, MSG, XSTAT1 )
      END IF

      VNAME = 'ZH'
      if ( .not. desc3( met_cro_3d_crs ) ) then
         msg = 'Could not read layer heights from ' // met_cro_3d_fin 
         call m3exit( pname, sdate, stime, msg, xstat1 )
      end if
      write( logunit,* ) 'gdtyp3d: ', gdtyp3d
      write( logunit,* ) 'ftype3d: ', ftype3d
      write( logunit,* ) 'sdate3d: ', sdate3d
      write( logunit,* ) 'stime3d: ', stime3d
      write( logunit,* ) 'tstep3d: ', tstep3d
      write( logunit,* ) 'nvars3d: ', nvars3d
      write( logunit,* ) 'p_alp3d: ', p_alp3d
      write( logunit,* ) 'p_bet3d: ', p_bet3d
      write( logunit,* ) 'p_gam3d: ', p_gam3d
      write( logunit,* ) 'xorig3d: ', xorig3d
      write( logunit,* ) 'xcell3d: ', xcell3d
      write( logunit,* ) 'ncols3d: ', ncols3d
      write( logunit,* ) 'nrows3d: ', nrows3d
      write( logunit,* ) 'nlays3d: ', nlays3d
      write( logunit,* ) 'vgtyp3d: ', vgtyp3d
      write( logunit,* ) 'vgtop3d: ', vgtop3d

#ifdef parallel
      BEG_COL = PRE_COL_LOC( 1,1 )
      END_COL = PRE_COL_LOC( SIZE( PRE_COL_LOC,1 ), 1 )
      BEG_ROW = PRE_ROW_LOC( 1,1 )
      END_ROW = PRE_ROW_LOC( 1, SIZE( PRE_ROW_LOC,2 ) )
      BEG_COL_C = 1
      END_COL_C = END_COL - BEG_COL + 1
      BEG_ROW_C = 1
      END_ROW_C = END_ROW - BEG_ROW + 1
      IF ( .NOT. INTERPX( MET_CRO_3D_CRS, VNAME, PNAME,
     &                    BEG_COL, END_COL, BEG_ROW, END_ROW,
     &                    1,NLAYS_IN, SDATE, STIME, 
     &                    HT_CTM( 1:END_COL_C,1:END_ROW_C,: ) ) ) THEN
#else
      IF ( .NOT. INTERPX( MET_CRO_3D_CRS, VNAME, PNAME,
     &                    1,NCOLS_IN, 1,NROWS_IN,
     &                    1,NLAYS_IN, SDATE, STIME, HT_CTM ) ) THEN
#endif
         MSG = 'Could not interpolate ZH from ' // MET_CRO_3D_CRS
         CALL M3EXIT ( PNAME, SDATE, STIME, MSG, XSTAT1 )
      END IF

C Interpolate
      DO C = 1, MY_NCOLS
         DO R = 1, MY_NROWS
            CIN = COL_LOC( C,R )
            RIN = ROW_LOC( C,R )
            DO V = 1, NSPCS_IN    

               DO L = 1, NLAYS_IN
                  WORKA( L ) = CONCIN( CIN,RIN,L,V )
                  X3_OLD( L ) = HT_CTM( CIN,RIN,L )
               END DO

               DO L = 1, NLAYS

                  IF ( NLAYS_IN .EQ. 1 ) THEN
                     CONCVI( C,R,L,V ) = WORKA( 1 )

                  ELSE
                     X3 = HT_IC( C,R,L )

                     IF ( X3 .LT. X3_OLD( 1 ) ) THEN
                        CONCVI( C,R,L,V ) = WORKA( 1 )
                     ELSE IF ( X3 .GT. X3_OLD( NLAYS_IN ) ) THEN
                        CONCVI( C,R,L,V ) = WORKA( NLAYS_IN )
                     ELSE
                        CALL LR_INTERP( L_RATINT, X3_OLD, WORKA, NLAYS_IN, 
     &                                  X3, Y, DELY )
                        CONCVI( C,R,L,V ) = Y
                     END IF

                  END IF

               END DO

            END DO
         END DO
      END DO

      RETURN

C************************* FORMAT Statements ***************************

92000 FORMAT( // 1X, 79( '#' ) 
     &         / 1X, '#  Vertical Interpolation Section '
     &         / 1X, 79( '#' ) ) 

92020 FORMAT( // 5X, 'The vertical structure in Layer Defn is identical'
     &               ' to that in the CTM input file. '
     &        // 5X, 'No vertical interpolation necessary' )

92040 FORMAT( // 5X, 'The Layer Defn and CTM vertical grid types are the '
     &               'same, but the resolution is different.' /
     &           5X, 'Vertical interpolation will be done using VGLVS '
     &               '(listed below). ' )

92060 FORMAT( // 5X, 'Vertical grid type: ', A )

92080 FORMAT( // 5X, 'Vertical layer surface values (VGLVS) : '
     &         /10X, ' K    Layer Defn   Input CTM' )

92100 FORMAT(   10X, I2, 1X, F12.3, 1X, F12.3 )

92120 FORMAT(   10X, I2,       13X, 1X, F12.3 )

92140 FORMAT( //5X, A )

92160 FORMAT( //5X, 'The Layer Defn and CTM vertical grid types are '
     &               'different. '
     &         / 5X, 'Vertical interpolation will be done using HEIGHT ',
     &               'from the MET_CRO_3D files. ' )

94000 FORMAT( 1PE20.4 )

      END
