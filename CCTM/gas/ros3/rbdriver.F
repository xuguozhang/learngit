
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
C $Header: /project/yoj/arc/CCTM/src/gas/ros3/rbdriver.F,v 1.7 2011/10/21 16:11:10 yoj Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%


       SUBROUTINE CHEM( CONC, JDATE, JTIME, TSTEP )

C**********************************************************************
C
C  Function: To control gas phase chemistry calculations performed by
C            the vectorized Rosenbrock solver
C
C  Preconditions: None
C
C  Key Subroutines/Functions Called: RBINIT
C                                    RBSPARSE
C                                    PHOT
C                                    CALCKS
C                                    RBSOLVER
C                                    FIND_DEGRADED
C                                    INIT_DEGRADE
C                                    FINAL_DEGRADE
C
C  Revision History: Prototype created by Jerry Gipson, August, 2004
C                    Based on the solver described by Sandu et al
C                    ( Atm. Env., Vol. 31, No. 20, 1997 ) and included
C                    in the Kinetic PreProcessor ( see for example 
C                    Sandu et al., At, Env., Vol. 37, 5097-5114, 
C                    2003). This code also incorporates efficiency
C                    concepts originally developed by M. Jacobson
C                    for SMVGEAR (Atm. Env., Vol 28, No 2, 1994).
C                    Adapted from Subroutine CHEM in CMAQ SMVGEAR
C
C                    31 Jan 05 J.Young: dyn alloc - establish both horizontal
C                    & vertical domain specifications in one module (GRID_CONF)
C                    29 Jul 05     WTH: Added IF blocks that call degrade 
C                                       routines if MECHNAME contains 'TX' 
C                                       substring.
C                    28 Jun 10 J.Young: convert for Namelist redesign
C                    29 Mar 11 S.Roselle: Replaced I/O API include files
C                               with UTILIO_DEFN
C                    31 Aug 11 B.Hutzell revised method that determines calling
C                              degrade routine
C                    29 Sep 11 D.Wong: incorporated twoway model implementation
C**********************************************************************

      USE SUBST_MODULES
      USE GRID_CONF             ! horizontal & vertical domain specifications
      USE RBDATA                ! ROS3 solver data
      USE CGRID_SPCS            ! CGRID mechanism species
      USE UTILIO_DEFN

      IMPLICIT NONE 

C..Includes:

      INCLUDE SUBST_FILES_ID    ! CMAQ files
      INCLUDE SUBST_CONST       ! CMAQ constants
      INCLUDE SUBST_RXCMMN      ! Mechanism reaction common block
      INCLUDE SUBST_PACTL_ID    ! Process analysis control parameters
 
C..Arguments:

      REAL, POINTER :: CONC( :,:,:,: )  ! Concentrations

      INTEGER JDATE                     ! Current date (YYYYDDD)
      INTEGER JTIME                     ! Current time (HHMMSS)
      INTEGER TSTEP( 3 )                ! Time step vector (HHMMSS)

C..Parameters:

      INTEGER, PARAMETER :: IZERO = 0                ! Integer zero

      REAL,    PARAMETER :: CONCMIN = 1.0E-30        ! Minimum conc
      REAL,    PARAMETER :: CONCOFM = 1.0E+06        ! conc. of M = 1E+06 ppm
      REAL,    PARAMETER :: PA2ATM  = 1.0 / STDATMPA ! Pascal to atm conv fac

C..External Functions:

C..Local Variables:

      LOGICAL, SAVE :: LFIRST = .TRUE. ! Flag for first call to this subroutine
      LOGICAL, SAVE :: LIRRBLK         ! Flag for IRR to be done for block

      INTEGER, SAVE :: LOGDEV          ! Unit number of output log
      INTEGER, SAVE :: NOXYZ           ! Total number of grid cells

      REAL,    SAVE :: AIRFC           ! Factor to convert gms air to ppm
      REAL,    SAVE :: MAOMV           ! Mol Wt of air over Mol Wt of water
!     REAL,    SAVE :: CONV( NLAYS )   ! Volumetric emis conv facs

      CHARACTER(  16 ) :: PNAME = 'RBDRIVER' ! Procedure name
      CHARACTER(  16 ) :: VNAME              ! Name of I/O API data variable
      CHARACTER( 144 ) :: MSG                ! Message text
     
      INTEGER C, R, L, S      ! Loop indices
      INTEGER ALLOCSTAT       ! Allocate status code
      INTEGER OFFSET          ! Starting cell number of a block
      INTEGER NCSP            ! Mech no: 1=gas/day 2=gas/night
      INTEGER BLK             ! Loop index for block of cells
      INTEGER CELLNUM         ! Cell number 
      INTEGER COL             ! Column index
      INTEGER IPAR            ! Pointer for cell sort routine
      INTEGER IRVAL           ! Pointer for cell sort routine
      INTEGER IRXN            ! Reaction number
      INTEGER ISP             ! Species index
      INTEGER ISPOLD          ! Species number in original order
      INTEGER ISPNEW          ! Species number in new sorted order 
      INTEGER ITMSTEP         ! Chemistry integration interval (sec)   
      INTEGER JPAR            ! Pointer for cell sort routine
      INTEGER JREORD          ! Index holder for sort routine
      INTEGER LEV             ! Layer index
      INTEGER LVAL            ! Pointer for cell sort routine
      INTEGER MIDDATE         ! Date at time step midpoint
      INTEGER MIDTIME         ! Time at time step midpoint
      INTEGER NCELL           ! Index for number of cells
      INTEGER NDARK           ! Number of layer 1 cells in darkness
      INTEGER NIRRCLS         ! No. of cells in block for IRR
      INTEGER NPH             ! Index for number of phot. rxns in PHOT
      INTEGER NRX             ! Index for number of reactions
      INTEGER ROW             ! Row index
      INTEGER SPC             ! Species loop index
      INTEGER VAR             ! Variable number on I/O API file

      INTEGER :: IRRCELL( BLKSIZE )   ! Cell No. of an IRR cell

C for INTERPX
      INTEGER     GXOFF, GYOFF                 ! global origin offset from file
      INTEGER, SAVE :: STRTCOLMC3, ENDCOLMC3, STRTROWMC3, ENDROWMC3
      INTEGER, SAVE :: STRTCOLEM1, ENDCOLEM1, STRTROWEM1, ENDROWEM1
 
      REAL CHEMSTEP                            ! Chem integration interval (min)
      REAL VALLOW                              ! Value holder for sort routine
      
      REAL :: DENSA_J( NCOLS,NROWS,NLAYS )      ! Cell density (Kg/m**3)
      REAL :: DENS   ( NCOLS,NROWS,NLAYS )      ! Cell density (Kg/m**3)
      REAL :: PRES   ( NCOLS,NROWS,NLAYS )      ! Cell pressure (Pa)
      REAL :: QV     ( NCOLS,NROWS,NLAYS )      ! Cell water vapor (Kg/Kg air)
      REAL :: TA     ( NCOLS,NROWS,NLAYS )      ! Cell temperature (K)

!     REAL :: RJBLK( BLKSIZE,NPHOTAB )           ! J-values for each cell in 
                                               ! a block

      REAL :: RJ( NCOLS,NROWS,NLAYS,NPHOTAB )  ! J-values for each cell      
!     REAL, ALLOCATABLE, SAVE :: RJ( :,:,:,: )  ! J-values for each cell      

#ifdef rbstats

      CHARACTER( 16 ), SAVE              :: CTM_RBSTATS_1 = 'CTM_RBSTATS_1' 
      CHARACTER( 16 ), ALLOCATABLE, SAVE :: VSTATS( : )        !

      INTEGER, SAVE                      :: WSTEP = 0     
      INTEGER, ALLOCATABLE, SAVE         :: STAT_SUM( :,:,:,: )
      INTEGER  EDATE, ETIME

      REAL                               :: STATOUT( NCOLS,NROWS,NLAYS )

#endif

      INTERFACE

!?       SUBROUTINE PA_IRR_SETUP( NBLKS, LIRRBLK, LCELL, BLKLEN,
!?   &                            CCOL, CROW, CLEV )
!?          USE GRID_CONF
!?          USE CGRID_SPCS
!?          USE PAGRD_DEFN
!?          IMPLICIT NONE
!?          INTEGER NBLKS
!?          LOGICAL :: LIRRBLK( : )
!?          INTEGER :: LCELL( : ), BLKLEN( : )
!?          INTEGER :: CCOL( : ), CROW( : ), CLEV( : )
!?       END SUBROUTINE PA_IRR_SETUP

         SUBROUTINE PA_IRR_CKBLK ( NUMCELLS, LIRRFLAG, OFFSET,
     &                             CCOL, CROW, CLEV, NORDCELL,
     &                             NIRRCLS, IRRCELL )
            IMPLICIT NONE
            INTEGER, INTENT( IN )  :: NUMCELLS, OFFSET
            LOGICAL, INTENT( OUT ) :: LIRRFLAG
            INTEGER, INTENT( IN )  :: CCOL( : ), CROW( : ), CLEV( : )
            INTEGER, INTENT( IN )  :: NORDCELL( : )
            INTEGER, INTENT( INOUT ) :: NIRRCLS
            INTEGER, INTENT( INOUT ) :: IRRCELL( : )
         END SUBROUTINE PA_IRR_CKBLK
         SUBROUTINE PA_IRR_BLKENDC ( OFFSET, 
     &                               CCOL, CROW, CLEV, NORDCELL,
     &                               NIRRCLS, IRRCELL )
            IMPLICIT NONE
            INTEGER, INTENT( IN ) :: OFFSET
            INTEGER, INTENT( IN ) :: CCOL( : ), CROW( : ), CLEV( : )
            INTEGER, INTENT( IN ) :: NORDCELL( : )
            INTEGER, INTENT( INOUT ) :: NIRRCLS
            INTEGER, INTENT( INOUT ) :: IRRCELL( : )
         END SUBROUTINE PA_IRR_BLKENDC
         SUBROUTINE RBSOLVER ( LOGDEV, JDATE, JTIME, CHEMSTEP, NCSP,
     &                         LIRRFLAG, NIRRCLS, IRRCELL )
            USE GRID_CONF
            USE RBDATA
            USE CGRID_SPCS
            USE UTILIO_DEFN
            IMPLICIT NONE
            INTEGER, INTENT( IN ) :: LOGDEV, JDATE, JTIME
            REAL,    INTENT( IN ) :: CHEMSTEP
            INTEGER, INTENT( IN ) :: NCSP
            LOGICAL, INTENT( IN ) :: LIRRFLAG
            INTEGER, INTENT( INOUT ) :: NIRRCLS
            INTEGER, INTENT( IN ) :: IRRCELL( : )
         END SUBROUTINE RBSOLVER
!        SUBROUTINE PHOT ( MDATE, MTIME, JDATE, JTIME, NDARK, RJ )
!           USE CGRID_SPCS           ! CGRID species number and offsets
!           USE PCGRID_DEFN          ! get cgrid
!           USE UTILIO_DEFN          ! IOAPI infoe
!           USE SUBST_MODULES        ! stenex
!           USE AERO_DATA            ! describes aerosol distribution
!!          USE PHOT_MOD             ! photolysis in-line module
!           IMPLICIT NONE
!           INTEGER, INTENT( IN )  :: MDATE, MTIME, JDATE, JTIME
!           INTEGER, INTENT( OUT ) :: NDARK
!           REAL,    INTENT( OUT ) :: RJ( :,:,:,: )
!        END SUBROUTINE PHOT
         SUBROUTINE FIND_DEGRADED( JDATE, JTIME, LOGDEV, CALL_DEGRADE )
           USE DEGRADE_SETUP_TOX
           IMPLICIT NONE
           INTEGER, INTENT( IN )  :: JDATE        ! current model date , coded YYYYDDD
           INTEGER, INTENT( IN )  :: JTIME        ! current model time , coded HHMMSS
           INTEGER, INTENT( IN )  :: LOGDEV       ! unit number for the log file
           LOGICAL, INTENT( OUT ) :: CALL_DEGRADE ! whether to call degradation routines
         END SUBROUTINE FIND_DEGRADED
         SUBROUTINE INIT_DEGRADE( CBLK, TCELL, DCELL, PHOTO_CELL, NUMCELLS,
     &                         JDATE, JTIME, LOGDEV, BLKID )
           USE DEGRADE_SETUP_TOX
           IMPLICIT NONE
           INCLUDE SUBST_RXCMMN   
           REAL( 8 ), INTENT( IN ) :: CBLK ( BLKSIZE, NSPCSD )           !  species concentration in cell
           REAL( 8 ), INTENT( IN ) :: TCELL( BLKSIZE )                    !  cell temperature  [ k ]
           REAL( 8 ), INTENT( IN ) :: DCELL( BLKSIZE )                   !  cell air density  [ kg/m^3 ]
           REAL,      INTENT( IN ) :: PHOTO_CELL( BLKSIZE, N_PHOTO_TAB ) !  Photolysis table for cell [1/s]
           INTEGER,   INTENT( IN ) :: NUMCELLS  ! number of grid cells in block
           INTEGER,   INTENT( IN ) :: JDATE     ! current model date , coded YYYYDDD
           INTEGER,   INTENT( IN ) :: JTIME     ! current model time , coded HHMMSS
           INTEGER,   INTENT( IN ) :: LOGDEV    ! unit number for the log
           INTEGER,   INTENT( IN ) :: BLKID     ! number for the block
         END SUBROUTINE INIT_DEGRADE      
         SUBROUTINE FINAL_DEGRADE( CBLK )
           USE DEGRADE_SETUP_TOX
           IMPLICIT NONE
           REAL( 8 ), INTENT( INOUT ) :: CBLK( BLKSIZE, NSPCSD ) ! species conc in cell
         END SUBROUTINE FINAL_DEGRADE
      END INTERFACE

C**********************************************************************

      IF ( N_GC_SPC .EQ. 0 ) THEN
         CALL M3MESG( '*** WARNING: Gas-Chemistry processing bypassed!' )
         RETURN
      END IF

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  On first call, call routines to set-up for Gear solver and 
c  set-up to do emissions here if that option is invoked
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IF ( LFIRST ) THEN
         LFIRST = .FALSE.
         LOGDEV = INIT3( )

         IF ( .NOT. CELLVAR_ALLOC() ) THEN
            MSG = 'Failure allocating variables dependent on horizontal extents'
            CALL M3EXIT( PNAME, JDATE, JTIME, MSG, XSTAT1 )
         END IF

         CALL RBINIT
         CALL RBSPARSE( LOGDEV )
         NOXYZ = MY_NCOLS * MY_NROWS * NLAYS
         MAOMV =  MWAIR / MWWAT

C...Initialize and report data

         WRITE( LOGDEV, 92020 ) NOXYZ, BLKSIZE, NBLKS, BLKLEN( 1 ), BLKLEN( NBLKS )

         WRITE( LOGDEV, 92040 ) GLBL_RTOL, GLBL_ATOL

         CALL SUBHFILE ( MET_CRO_3D, GXOFF, GYOFF,
     &                   STRTCOLMC3, ENDCOLMC3, STRTROWMC3, ENDROWMC3 )

         STARTCOLCO = COLSX_PE( 1, MYPE + 1 )
         ENDCOLCO   = COLSX_PE( 2, MYPE + 1 )
         STARTROWCO = ROWSX_PE( 1, MYPE + 1 )
         ENDROWCO   = ROWSX_PE( 2, MYPE + 1 )

c..Open file for solver stats if requested
#ifdef rbstats
         ALLOCATE( VSTATS( 3 ) )
         VSTATS( 1 ) = 'N_STRT_FAILS'
         VSTATS( 2 ) = 'N_FAILS'
         VSTATS( 3 ) = 'N_STEPS'

         IF ( MYPE .EQ. 0 ) THEN

            IF ( .NOT. OPEN3( CTM_CONC_1, FSREAD3, PNAME ) ) THEN
               MSG = 'Could not open ' // CTM_CONC_1 // ' file for readonly'
               CALL M3EXIT( PNAME, JDATE, JTIME, MSG, XSTAT2 )
            END IF

            IF ( .NOT. DESC3( CTM_CONC_1 ) ) THEN
               MSG = 'Could not get description of concentration file '
     &             // CTM_CONC_1
               CALL M3EXIT( PNAME, JDATE, JTIME, MSG, XSTAT2 )
            END IF

            EDATE = JDATE
            ETIME = JTIME
            CALL NEXTIME( EDATE, ETIME, TSTEP( 1 ) )

            SDATE3D = EDATE
            STIME3D = ETIME
            NVARS3D = 3
            NCOLS3D = GL_NCOLS
            NROWS3D = GL_NROWS
            NLAYS3D = NLAYS
            VNAME3D( 1 ) = 'N_STRT_FAILS'
            VNAME3D( 2 ) = 'N_FAILS'
            VNAME3D( 3 ) = 'N_STEPS'
            VDESC3D( 1 ) = 'Number of fails at start'
            VDESC3D( 2 ) = 'Number of step fails'
            VDESC3D( 3 ) = 'Number of steps'
            UNITS3D( 1 ) = 'None'
            UNITS3D( 2 ) = 'None'
            UNITS3D( 3 ) = 'None'
            VTYPE3D( 1 ) = M3REAL
            VTYPE3D( 2 ) = M3REAL
            VTYPE3D( 3 ) = M3REAL
            IF ( .NOT. OPEN3( CTM_RBSTATS_1, FSNEW3, PNAME ) ) THEN
               MSG = 'Could not create '// TRIM( CTM_RBSTATS_1 ) // ' file'
               CALL M3EXIT( PNAME, SDATE3D, STIME3D, MSG, XSTAT2 )
            END IF

         END IF

         ALLOCATE( STAT_SUM( MY_NCOLS, MY_NROWS, NLAYS, 3 ) )

!        ALLOCATE( RJ( NCOLS, NROWS, NLAYS, NPHOTAB ) )

         STAT_SUM = 0

#endif

C Determine whether DEGRADE rountines are needed.

         CALL FIND_DEGRADED( JDATE, JTIME, LOGDEV, CALL_DEG )
         IF( CALL_DEG ) THEN
            WRITE( LOGDEV, * ) 'DEGRADE ROUTINES USED'
            WRITE( LOGDEV, * ) 'Mechanism contains degraded species'
#ifdef verbose_gas         
         ELSE
            WRITE( LOGDEV, * ) 'DEGRADE ROUTINES not USED'
            WRITE( LOGDEV, * ) 'Mechanism contains NO degraded species'
#endif            
         ENDIF

C set up degradation array


         ALLOCATE( Y_DEGRADE( BLKSIZE, NSPCSD ) )

      END IF      ! First call

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
C  Start of integration driver after first call
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      NIRRCLS = 0

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
C  Set date and time to center of time step, get necessary physical 
C  data, and get photolysis rates
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      MIDDATE = JDATE
      MIDTIME = JTIME
      ITMSTEP = TIME2SEC( TSTEP( 2 ) )
      CHEMSTEP = FLOAT( ITMSTEP ) / 60.0
      CALL NEXTIME( MIDDATE, MIDTIME, SEC2TIME( ITMSTEP / 2 ) )
 
C.. Get ambient temperature in K

      VNAME = 'TA' 
      IF ( .NOT. INTERPX( MET_CRO_3D, VNAME, PNAME,
     &                    STRTCOLMC3,ENDCOLMC3, STRTROWMC3,ENDROWMC3, 1,NLAYS,
     &                    MIDDATE, MIDTIME, TA ) ) THEN
         MSG = 'Could not read TA from MET_CRO_3D'
         CALL M3EXIT( PNAME, MIDDATE, MIDTIME, MSG, XSTAT1 )
      END IF
      
C.. Get specific humidity in Kg H2O / Kg air

      VNAME = 'QV'
      IF ( .NOT. INTERPX( MET_CRO_3D, VNAME, PNAME,
     &                    STRTCOLMC3,ENDCOLMC3, STRTROWMC3,ENDROWMC3, 1,NLAYS,
     &                    MIDDATE, MIDTIME, QV ) ) THEN
         MSG = 'Could not read QV from MET_CRO_3D'
         CALL M3EXIT( PNAME, MIDDATE, MIDTIME, MSG, XSTAT1 )
      END IF 
      
C.. Get pressure in Pascals

      VNAME = 'PRES'
      IF ( .NOT. INTERPX( MET_CRO_3D, VNAME, PNAME,
     &                    STRTCOLMC3,ENDCOLMC3, STRTROWMC3,ENDROWMC3, 1,NLAYS,
     &                    MIDDATE, MIDTIME, PRES ) ) THEN
         MSG = 'Could not read PRES from MET_CRO_3D'
         CALL M3EXIT ( PNAME, MIDDATE, MIDTIME, MSG, XSTAT1 )
      END IF

C.. Get density in Kg/m^3

      VNAME = 'DENS'
      IF ( .NOT. INTERPX( MET_CRO_3D, VNAME, PNAME,
     &                    STRTCOLMC3,ENDCOLMC3, STRTROWMC3,ENDROWMC3, 1,NLAYS,
     &                    MIDDATE, MIDTIME, DENS ) ) THEN
         MSG = 'Could not read DENS from MET_CRO_3D'
         CALL M3EXIT( PNAME, JDATE, JTIME, MSG, XSTAT1 )
      END IF

C.. Get photolysis rates in /min

      CALL PHOT ( MIDDATE, MIDTIME, JDATE, JTIME, NDARK, RJ )                    

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Set flag for reordering of cells and put cells in sequential  
c  order initially
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      LORDERING = .TRUE.
      IF ( .NOT. LREORDER .OR. NBLKS .EQ. 1 ) LORDERING = .FALSE.
      DO NCELL = 1, NOXYZ
         NORDCELL( NCELL ) = NCELL
      END DO

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
C  Top of loop over blocks. This loop will be done once if
C  no reordering, twice if reordering is required
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
100   CONTINUE

!     write( logdev,* ) 'driver-lordering,lreorder: ', lordering, lreorder

      DO 500 BLK = 1, NBLKS
         BLKID = BLK
         NUMCELLS = BLKLEN( BLK )
         OFFSET = BLKCNO( BLK )
         IF ( .NOT. LORDERING .AND. LIRR ) THEN
             LIRRBLK = .FALSE.
             CALL PA_IRR_CKBLK ( NUMCELLS, LIRRBLK, OFFSET,
     &                           CCOL, CROW, CLEV, NORDCELL, NIRRCLS,
     &                           IRRCELL )
             CALL PA_IRR_BLKSTRT( NUMCELLS )
         END IF
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
C  Put the grid cell physical data in the block arrays, converting
C  pressure to atmospheres, water vapor to ppm, emissions to ppm/min 
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

         DO NCELL = 1, NUMCELLS
            CELLNUM = NORDCELL( OFFSET + NCELL )
            COL = CCOL( CELLNUM )
            ROW = CROW( CELLNUM )
            LEV = CLEV( CELLNUM )
            BLKTEMP( NCELL ) = TA( COL,ROW,LEV )
            BLKDENS( NCELL ) = DENS( COL,ROW,LEV )
            BLKPRES( NCELL ) = PA2ATM * PRES( COL, ROW, LEV )
            BLKCH2O( NCELL ) = MAX( QV( COL,ROW,LEV ) * MAOMV * CONCOFM, 0.0 )          
         END DO

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
C  Put the grid cell concentrations in the block arrays
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
         DO ISP = 1, ISCHANG( NCS )
            ISPNEW = IOLD2NEW( ISP,NCS )
            DO NCELL = 1, NUMCELLS
               CELLNUM = NORDCELL( OFFSET + NCELL )
               COL = CCOL( CELLNUM )
               ROW = CROW( CELLNUM )
               LEV = CLEV( CELLNUM )
               Y( NCELL,ISPNEW ) = MAX( CONC( COL,ROW,LEV,ISP ), CONCMIN )
            END DO                 
         END DO

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
C   Get photolytic and thermal rate constants & call solver
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
         LSUNLIGHT = .FALSE.

         DO NCELL = 1, NUMCELLS
            CELLNUM = NORDCELL( OFFSET + NCELL )
            COL = CCOL( CELLNUM )   ! wrong order
            ROW = CROW( CELLNUM )
            LEV = CLEV( CELLNUM )
            DO NPH = 1, NPHOTAB
               RJBLK( NCELL,NPH ) = RJ( COL,ROW,LEV,NPH )
               IF ( RJBLK( NCELL, NPH ) .GT. 0.0 ) LSUNLIGHT = .TRUE.
            END DO                         
         END DO
         
!        CALL CALCKS( NPHOTAB, RJBLK )
         CALL CALCKS( )

         IF ( LSUNLIGHT ) THEN
            NCSP = NCS
         ELSE
            NCSP = NCS + 1
         END IF

C  update cell concentrations for degradation routines

         IF ( CALL_DEG ) THEN

            Y_DEGRADE = 0.0
            DO ISP = 1, NSPCSD
               DO NCELL = 1, NUMCELLS
                  CELLNUM = NORDCELL( OFFSET + NCELL )
                  COL = CCOL( CELLNUM )
                  ROW = CROW( CELLNUM )
                  LEV = CLEV( CELLNUM )
                  Y_DEGRADE( NCELL,ISP ) = MAX( CONC( COL,ROW,LEV,ISP ),
     &                                          CONCMIN )
               END DO
            END DO

C initialize degradation routines

            CALL INIT_DEGRADE( Y_DEGRADE, BLKTEMP, BLKDENS, RJBLK,
     &                         NUMCELLS, JDATE, JTIME, LOGDEV, BLKID )

         END IF

#ifdef rbstats

         NSTEPS = 0
         NFAILS = 0
         N_BAD_STARTS = 0

#endif

         CALL RBSOLVER( LOGDEV, JDATE, JTIME, CHEMSTEP, NCSP,
     &                  LIRRBLK, NIRRCLS, IRRCELL ) 

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
C  If not ordering cells, save performance statistics and
C  store updated concentrations.
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
         IF ( .NOT. LORDERING ) THEN

C..Update concentrations
            DO ISP = 1, ISCHANG( NCS )
               ISPOLD  = INEW2OLD( ISP,NCS )
               DO NCELL = 1, NUMCELLS
                  CELLNUM = NORDCELL( OFFSET + NCELL )
                  COL = CCOL( CELLNUM )
                  ROW = CROW( CELLNUM )
                  LEV = CLEV( CELLNUM )
                  CONC( COL,ROW,LEV,ISPOLD ) = Y( NCELL,ISP ) 
               END DO
            END DO

            IF ( CALL_DEG ) THEN

C  Update degradation array with species treated by Rosenbach solver

               DO ISP = 1, ISCHANG( NCS )
                  ISPOLD  = INEW2OLD( ISP, NCS )
                  DO NCELL = 1, NUMCELLS
                     Y_DEGRADE( NCELL,ISPOLD ) = Y( NCELL,ISP )
                  END DO
               END DO

C  Update CGRID based on the degradation routines

               CALL FINAL_DEGRADE( Y_DEGRADE )
               DO ISP = NR_STRT, (TR_STRT-1)
                  DO NCELL = 1, NUMCELLS
                     CELLNUM = NORDCELL( OFFSET + NCELL )
                     COL = CCOL( CELLNUM )
                     ROW = CROW( CELLNUM )
                     LEV = CLEV( CELLNUM )
                     CONC( COL,ROW,LEV,ISP ) = Y_DEGRADE( NCELL,ISP )
                 END DO
               END DO
            END IF            !WTH

#ifdef rbstats

            DO NCELL = 1, NUMCELLS
               CELLNUM = NORDCELL( OFFSET + NCELL )
               COL = CCOL( CELLNUM )
               ROW = CROW( CELLNUM )
               LEV = CLEV( CELLNUM )
               STAT_SUM( COL,ROW,LEV,1 ) = STAT_SUM( COL,ROW,LEV,1 )
     &                                   + N_BAD_STARTS
               STAT_SUM( COL,ROW,LEV,2 ) = STAT_SUM( COL,ROW,LEV,2 )
     &                                   + NFAILS
               STAT_SUM( COL,ROW,LEV,3 ) = STAT_SUM( COL,ROW,LEV,3 )
     &                                   + NSTEPS
            END DO

#endif
                      
            IF ( LIRRBLK ) CALL PA_IRR_BLKENDC ( OFFSET, CCOL, CROW, CLEV,
     &                                           NORDCELL, NIRRCLS, IRRCELL )

         END IF

500   CONTINUE

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
C  End of block loop; reorder cells if necessary and go back do the  
C  block loop again.  Taken from Jacobson 1994.
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IF ( LORDERING ) THEN
         LORDERING = .FALSE.     
         LVAL = NOXYZ / 2 + 1
         IRVAL = NOXYZ
600      CONTINUE
         IF ( LVAL .GT. 1 ) THEN
            LVAL = LVAL - 1
            VALLOW = ERRMX2( LVAL )
            JREORD = NORDCELL( LVAL )
         ELSE
            VALLOW = ERRMX2( IRVAL )
            JREORD = NORDCELL( IRVAL )
            ERRMX2( IRVAL ) = ERRMX2( 1 )
            NORDCELL( IRVAL ) = NORDCELL( 1 )
            IRVAL = IRVAL - 1
            IF ( IRVAL.EQ.1 ) THEN
               ERRMX2( IRVAL ) = VALLOW
               NORDCELL( IRVAL ) = JREORD
               GO TO 100
            END IF
         END IF
         IPAR = LVAL
         JPAR = LVAL + LVAL
650      CONTINUE
         IF ( JPAR .LE. IRVAL ) THEN
            IF ( JPAR .LT. IRVAL ) THEN
               IF ( ERRMX2( JPAR ) .LT. ERRMX2( JPAR + 1 ) ) JPAR = JPAR + 1
            END IF
            IF ( VALLOW .LT. ERRMX2( JPAR )) THEN
               ERRMX2( IPAR ) = ERRMX2( JPAR )
               NORDCELL( IPAR ) = NORDCELL( JPAR )
               IPAR = JPAR
               JPAR = JPAR + JPAR
            ELSE
               JPAR = IRVAL + 1
            END IF
            GO TO 650
         END IF
         ERRMX2( IPAR ) = VALLOW
         NORDCELL( IPAR ) = JREORD
         GO TO 600
      END IF
       
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
C  Output performance statistics if required and return
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

#ifdef rbstats

      WSTEP = WSTEP + TIME2SEC( TSTEP( 2 ) )
      EDATE = JDATE
      ETIME = JTIME
      CALL NEXTIME( EDATE, ETIME, TSTEP( 2 ) )
      IF ( WSTEP .GE. TIME2SEC( TSTEP( 1 ) ) ) THEN

         WSTEP = 0

         DO S = 1, 3
            DO R = 1, MY_NROWS
               DO C = 1, MY_NCOLS
                  DO L = 1, NLAYS
                     STATOUT( C, R, L ) = INT( STAT_SUM( C,R,L,S )
     &                                  +  0.00001 )
                  END DO
               END DO
            END DO

            IF ( .NOT. WRITE3( CTM_RBSTATS_1, VSTATS( S ),
     &            EDATE, ETIME, STATOUT ) ) THEN
               XMSG = 'Could not write ' // CTM_RBSTATS_1 // ' file'
               CALL M3EXIT( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
            END IF  

         END DO

         STAT_SUM = 0.0

      END IF

#endif

      RETURN

C*********************** FORMAT STATEMENTS ****************************
92020 FORMAT( / 10X, 'Chemistry Solver Blocking Parameters ... ',
     &        / 10X, 'Domain Size (number of cells):             ', I10
     &        / 10X, 'Dimensioning Block Size (number of cells): ', I10
     &        / 10X, 'Number of Blocks:        ', I10
     &        / 10X, 'Size of General Blocks:  ', I10
     &        / 10X, 'Size of Last Block:      ', I10 )
92040 FORMAT( / 10X, 'Rosenbrock Chemistry Solver Error Control ',
     &               'Parameters ...',
     &        / 10X, 'RTOL : ', 1PE12.3,
     &        / 10X, 'ATOL : ', 1PE12.3, ' ppm' )

      END

