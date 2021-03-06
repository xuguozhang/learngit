
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
C $Header: /project/yoj/arc/ICON/src/profile/prof_vinterp.F,v 1.2 2011/10/21 16:41:57 yoj Exp $ 

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%


      SUBROUTINE PROF_VINTERP( LOGUNIT, NSPCS_IN, NLAYS_IN, VGLVS_IN,
     &                         CONCIN, CONCOUT )    
C*************************************************************************
 
C  Function: Interpolates/Extrapolates concentrations in vertical.
C            The number of layers in CONCIN is collapsed or expanded
C            according to the number of layers in COORD.EXT.
C            Interpolation is done using rational function interpolation
C            ( Numerical Recipes, Press et al.) or linear 
C            interpolation.  When extapolation is required, the 
C            concentration of the outside layer is used. If the input 
C            file has only one layer, the concentrations in that layer
C            are used for all output layers.
              
C  Preconditions: None
  
C  Key Subroutines/Functions Called: LR_INTERP  
 
C  Revision History: Prototype created by Jerry Gipson, January, 1998          
C    01/24/02 Steve Howard (Jeff Young) - dynamic allocation
C    12/13/04 J.Young: vert dyn alloc - Use VGRD_DEFN
C    06 Jun 11 J.Young: Replaced I/O API include files with UTILIO_DEFN
C    21 May 12 J.Young: Replaced IC_PARMS include file with an F90 module
                   
C*************************************************************************

      USE HGRD_DEFN   ! Module to store and load the horizontal grid variables
      USE VGRD_DEFN   ! vertical layer specifications
      USE UTILIO_DEFN
      USE IC_PARMS    ! ICON parameters

      IMPLICIT NONE     

C Include Files:

C Arguments: 
      INTEGER LOGUNIT                ! Unit number for output log
      INTEGER NSPCS_IN               ! No. of species in input profile file
      INTEGER NLAYS_IN               ! No. of layers in input profile file

      REAL :: VGLVS_IN( * )          ! Input vertical levels
      REAL :: CONCIN( MXLAYS3,* )    ! Input conc array
      REAL :: CONCOUT( NLAYS,* )     ! Output IC array

C Parameters: None

C External Functions: None

C Local Variables:
      CHARACTER( 20 ) :: CHR1     ! Value of variable 1 in character data
      CHARACTER( 20 ) :: CHR2     ! Value of variable 1 in character data
      CHARACTER( 80 ) :: MSG      ! Log message
      CHARACTER( 16 ) :: PNAME = 'PROF_VINTERP'   ! Procedure Name

      INTEGER L              ! Loop index for vertical layers
      INTEGER MXLEV          ! Max no. of levels
      INTEGER N              ! Loop index
      INTEGER STATUS         ! Status code

      LOGICAL LDEC           ! Flag for monotonic decreasing layer levels
      LOGICAL LINC           ! Flag for monotonic increasing layer levels
      LOGICAL L_IDENTICAL    ! Flag for identical vert coord systems      
      LOGICAL L_RATINT       ! Flag to use rational function interpolation 
      logical wr             ! Flag for debug write

      REAL DELY  ! Error estimate for conc interpolated by rational func
      REAL X3    ! Vertical coordinate used in interpolation
      REAL Y     ! Interpolated concentration

      REAL :: WORKA(  MXLAYS3 )   ! Work array for conc input
      REAL :: X3_OLD( MXLAYS3 )   ! Old Vertical coordinate values
      
C**********************************************************************

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Write log info
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      WRITE( LOGUNIT,92000 )

      WRITE( LOGUNIT,92020 ) VGDESC( VGTYP_GD )

      WRITE( LOGUNIT,92040 ) 

      MXLEV = MAX( NLAYS + 1, NLAYS_IN + 1 )

      DO L = 1, MXLEV 

         IF ( L .LE. NLAYS + 1 .AND. L .LE. NLAYS_IN + 1 ) THEN
            WRITE( LOGUNIT,92080 ) L, VGLVS_GD( L ), VGLVS_IN( L )
         ELSE IF ( L .LE. NLAYS + 1 .AND. L .GT. NLAYS_IN + 1 ) THEN
            WRITE( LOGUNIT,92080 ) L, VGLVS_GD( L )
         ELSE IF ( L .GT. NLAYS + 1 .AND. L .LE. NLAYS_IN + 1 ) THEN
            WRITE( LOGUNIT,92100 ) L, VGLVS_IN( L )
         END IF

      END DO        
     
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Check for consistent vertical coordinates
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      L_IDENTICAL  = .TRUE.

      IF ( NLAYS .EQ. NLAYS_IN ) THEN
         DO L = 1, NLAYS + 1
            WRITE( CHR1,94060 ) VGLVS_GD( L )
            WRITE( CHR2,94060 ) VGLVS_IN( L )
            IF ( CHR1 .NE. CHR2 ) L_IDENTICAL  = .FALSE.
         END DO
      ELSE
         L_IDENTICAL  = .FALSE. 
      END IF
            
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  For identical vertical coordinates, copy the input profile
C  to the interpolated profile and return
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IF ( L_IDENTICAL ) THEN

         WRITE( LOGUNIT,92120 ) 

         DO L = 1, NLAYS
            DO N = 1, NSPCS_IN
               CONCOUT( L,N ) = CONCIN( L,N )
            END DO
         END DO
         RETURN
      END IF

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Determine type of interpolation to use: linear or rational function
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      L_RATINT = .FALSE.
      MSG = 'Flag for interpolation by rational function'
!     L_RATINT = ENVYN( 'RATIONAL_FUNC', MSG, L_RATINT, STATUS )  
      IF ( .NOT. L_RATINT ) THEN
         MSG = 'Linear vertical interpolation used'
      ELSE
         MSG = 'Vertical interpolation by rational function'
      END IF
      CALL M3MESG( MSG )
         
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Interpolate by VGLEVS for vertical coords of same type but different
c  resolution
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      DO L = 1, NLAYS_IN 
         X3_OLD( L ) = 0.5 * ( VGLVS_IN ( L ) +  VGLVS_IN ( L+1 ) )
      END DO

      LINC = .FALSE.
      LDEC = .FALSE.
      IF ( VGLVS_IN ( NLAYS_IN ) .GT. VGLVS_IN ( 1 ) ) THEN
         LINC = .TRUE.
      ELSE
         LDEC = .TRUE.
      END IF

      DO N = 1, NSPCS_IN    

         DO L = 1, NLAYS_IN
            WORKA( L ) = CONCIN( L,N )
         END DO

         DO L = 1, NLAYS

            IF ( NLAYS_IN .EQ. 1 ) THEN
               CONCOUT( L,N ) = WORKA( 1 )
            ELSE
               X3 = 0.5 * ( VGLVS_GD ( L ) +  VGLVS_GD ( L + 1 ) )
               IF ( LINC .AND. X3 .LE. X3_OLD( 1 ) ) THEN
                  CONCOUT( L,N ) = WORKA( 1 )
               ELSE IF ( LDEC .AND. X3 .GE. X3_OLD( 1 ) ) THEN
                  CONCOUT( L,N ) = WORKA( 1 )
               ELSE IF ( LINC .AND. X3 .GE. X3_OLD( NLAYS_IN ) ) THEN
                  CONCOUT( L,N ) = WORKA( NLAYS_IN )
               ELSE IF ( LDEC .AND. X3 .LE. X3_OLD( NLAYS_IN ) ) THEN
                  CONCOUT( L,N ) = WORKA( NLAYS_IN )
               ELSE
                  CALL LR_INTERP( L_RATINT, X3_OLD, WORKA, NLAYS_IN,
     &                            X3, Y, DELY )
!                 CALL LR_INTERP( wr, logunit, L_RATINT, X3_OLD, WORKA,
!    &                            NLAYS_IN, X3, Y, DELY )
                  CONCOUT( L,N ) = Y
               END IF
            END IF

         END DO 
 
      END DO

      RETURN

C************************* FORMAT Statements ***************************

92000 FORMAT( // 1X, 79( '#' ) 
     &         / 1X, '#  Vertical Interpolation Section '
     &         / 1X, 79( '#' ) 
     &        // 5X, 'WARNING: The vertical grid type used for the ',
     &               'profile data is assumed to'
     &         / 5X, 'be the same as the type specified in the MET_CRO_3D ',
     &               'file header. The'
     &         / 5X, 'resolution of each is listed below. ' )

92020 FORMAT(  / 5X, 'MET_CRO_3D Vertical grid type: ', A )
92040 FORMAT(  / 5X, 'Vertical layer surface values: '
     &         /10X, ' K     MET_CRO_3D      Input Profile data' )
92060 FORMAT( A )
92080 FORMAT(   10X, I2, 1X, F12.3, 10X, F12.3 )
92100 FORMAT(   10X, I2,       13X, 10X, F12.3 )
92120 FORMAT( // 5X, 'The vertical structure in MET_CRO_3D is identical'
     &               ' to that of the input profile data. '
     &        /  5X, 'No vertical interpolation necessary.' )

94060 FORMAT( 1PE20.4 )

      END
