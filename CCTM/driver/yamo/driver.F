
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
C $Header: /project/yoj/arc/CCTM/src/driver/yamo/driver.F,v 1.10 2012/01/19 14:32:57 yoj Exp $ 

C what(1) key, module and SID; SCCS file; date and time of last delta:
C @(#)driver.F  1.2 /project/mod3/CMAQ/src/driver/ctm/SCCS/s.driver.F 07 Jul 1997 09:20:18

C:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#ifdef twoway
      SUBROUTINE CMAQ_DRIVER ( WRF_SDATE, WRF_STIME, WRF_TSTEP, WRF_NSTEP,
     &                         TWOWAY_JDATE, TWOWAY_JTIME )
#else
      PROGRAM  DRIVER
#endif

C-----------------------------------------------------------------------
C Function:
C    CMAQ CTM driver
 
C Preconditions:
C    Initialized file CONCFILE for output; completed
C    files HISTORY containing initial conditions, SPCCONST for
C    conversion of concentration field from computational units
C    to output units.
 
C Subroutines and functions called:
C    INITSCEN, ADVSTEP, M3EXIT, WRITE3
C    science processes SCIPROC, PA_OUTPUT
 
C Revision History:
C    prototype 6/92 by CJC for proof-of-concept
C    Revised   2/93 by CJC for initial LCM Prototype Alpha
 
C    31 August, 1995 by M. Talat Odman at NCSC: special version for one 
C    single grid
 
C    16 April 1995 by M. Talat Odman at NCSC: write (or rewrite if restart)
C    initial conditions to the output file

C    Jeff
C    18 June 98 - put load of mechanism common here because of ping/ping_noop,
C    chem/chem_noop options

C    2 October, 1998 by Al Bourgeois at LM: parallel implementation
C    Jeff - Dec 00 - move CGRID_MAP into f90 module, re-order cols/rows in
C    call to PAR_INIT
C    Jeff - Jul 01 - enable integral average conc data
C    Sep 01  J. Young        Dyn Alloc - Use HGRD_DEFN

C    3 Sep 01 David wong
C      -- removed M3IO SHUT3 call which is done in PAR_TERM
C      -- removed SET_CTMFILE call

C   23 Jun 03 J.Young: for layer dependent advection tstep
C   18 Aug 03 J. Pleim - move vdiff before advection
C   07 Dec 04 J.Young: for layer dyn alloc - Use VGRD_DEFN
C   30 May 05 J.Young: mass-conserving advection (yamo)
C   20 Jan 06 J.Young: add circular buffer CGRID state file
C   24 May 06 J.Young: par_init/pio_init col/row order check
C    6 Sep 06 J.Young: one-write cgrid file; SGRID in module
C   27 May 09 J.Young: re-do parallel processing initialization
C   21 Jun 10 J.Young: convert for Namelist redesign
C   20 Jul 10 J.Young: re-do serial processing termination (eliminate par_noop)
C   16 Feb 11 S.Roselle: replaced I/O API include files with UTILIO_DEFN
C   11 May 11 D.Wong: incorporated twoway model implementation
C   24 Aug 11 D.Wong: eliminated data and geo orientation in se_init call
C    8 Jan 13 C.Nolte: fixed load AGRID bug if TSTEP(1) .ne. 010000 hhmmss
C   24 Sep 13 D.Wong:  Computed AGRID at the output mark of the model
C                      indicated in TSTEP(1) for twoway model
C-----------------------------------------------------------------------

      USE PCGRID_DEFN           ! inherits GRID_CONF
      USE CGRID_SPCS, ONLY: CGRID_SPCS_INIT  ! CGRID mechanism species
      USE STD_CONC              ! standard CONC
      USE AVG_CONC              ! integral average CONC
      USE WVEL_DEFN             ! derived vertical velocity component
      USE PAGRD_DEFN            ! Process Anaylsis horiz domain specs
      USE UTILIO_DEFN

#ifdef twoway
      USE SD_TIME_SERIES_MODULE
#endif

#ifdef parallel
      USE SUBST_MODULES         ! stenex (using SUBST_INIT_MODULE)
      USE SWAP_SANDIA
#endif

      IMPLICIT NONE

#ifdef twoway
      INTEGER, INTENT( IN )  :: WRF_SDATE, WRF_STIME, WRF_TSTEP, WRF_NSTEP
      INTEGER, INTENT( OUT ) :: TWOWAY_JDATE, TWOWAY_JTIME
#endif

C Include Files:
      INCLUDE SUBST_FILES_ID    ! I/O definitions and declarations
      INCLUDE SUBST_PACTL_ID    ! PA control parameters

#ifdef parallel
      INCLUDE SUBST_MPI         ! MPI definitions and parameters
#endif

C Load the mechanism COMMON ... (next two INCLUDE files)
      INCLUDE SUBST_RXCMMN      ! chemical mechamism reactions COMMON
!     INCLUDE SUBST_RXDATA      ! chemical mechamism reactions DATA

C External Functions:
      INTEGER, EXTERNAL :: SETUP_LOGDEV


C Local variables:

      INTEGER      LOGDEV       ! FORTRAN unit number for log file
      INTEGER      STDATE       ! starting date,    format YYYYDDD
      INTEGER      STTIME       ! starting time,    format HHMMSS
      INTEGER      TSTEP( 3 )   ! time step vector (HHMMSS)
                                ! TSTEP(1) = local output step
                                ! TSTEP(2) = sciproc sync. step (chem)
                                ! TSTEP(3) = twoway model time step w.r.t. wrf time
                                !            step and wrf/cmaq call frequency

      INTEGER, ALLOCATABLE, SAVE :: ASTEP( : )
      INTEGER      NSTEPS       ! run duration: number of output time steps
      INTEGER, SAVE :: NREPS    ! number of model time steps per output step
      INTEGER      ISTEP        ! current output time step number
      INTEGER      IREP         ! model step number within this output step
      INTEGER, SAVE :: JDATE    ! current model date, coded YYYYDDD
      INTEGER, SAVE :: JTIME    ! current model time, coded HHMMSS
      INTEGER      C, R, L, K, S, V     ! loop induction variables
      INTEGER      ALLOCSTAT

      CHARACTER(  2 ) :: COLROW = 'CR'  ! col/row arg list order
      CHARACTER( 16 ) :: PNAME = 'DRIVER'
      CHARACTER( 96 ) :: XMSG = ' '

      REAL, SAVE, POINTER     :: CGRID( :,:,:,: )
      REAL, ALLOCATABLE, SAVE :: AGRID( :,:,:,: )
      REAL    DIVFAC      ! trapezoidal average factor
      INTEGER A_NLYS

      INTEGER NPROCS      ! number of processors
#ifdef parallel
!     INTEGER, PARAMETER :: GEO_ORI = 0   ! stenex array order: 0 (Cartesian), 1 (Matrix)
      INTEGER PAR_ERR     ! Error code from parallel initialization. 
      REAL    CLOCK       ! Wall-clock time (sec) at initialization.
#endif

      LOGICAL, SAVE :: FIRST_RUN = .TRUE.  ! used for twoway model

#ifdef twoway
      LOGICAL, SAVE :: SD_TIME_SERIES
      LOGICAL       :: CMAQ_WRF_FEEDBACK
      INTEGER, SAVE :: myNREPS = 0
#endif

      INTEGER, SAVE :: STEP_COUNT = 0, TOTAL_STEPS = 0
      INTEGER       :: STATUS, RUNLEN

      INTERFACE
         SUBROUTINE INITSCEN ( CGRID, STDATE, STTIME, TSTEP, NSTEPS )
            IMPLICIT NONE
            REAL, POINTER            :: CGRID( :,:,:,: )
            INTEGER, INTENT( OUT )   :: STDATE, STTIME, TSTEP( 3 )
            INTEGER, INTENT( OUT )   :: NSTEPS
         END SUBROUTINE INITSCEN
         SUBROUTINE ADVSTEP ( JDATE, JTIME, TSTEP, ASTEP, NREPS )
            IMPLICIT NONE
            INTEGER, INTENT( IN )    :: JDATE, JTIME
            INTEGER, INTENT( INOUT ) :: TSTEP( 3 )
            INTEGER, INTENT( OUT )   :: ASTEP( : )
            INTEGER, INTENT( OUT )   :: NREPS
         END SUBROUTINE ADVSTEP
         SUBROUTINE CKSUMMER ( PRNAME, CGRID, JDATE, JTIME )
            IMPLICIT NONE
            CHARACTER( * ), INTENT( IN ) :: PRNAME
            REAL, POINTER            :: CGRID( :,:,:,: )
            INTEGER, INTENT( IN )    :: JDATE, JTIME
         END SUBROUTINE CKSUMMER
         SUBROUTINE PA_INIT ( CGRID, JDATE, JTIME, TSTEP )
            IMPLICIT NONE
            REAL, POINTER            :: CGRID( :,:,:,: )
            INTEGER, INTENT( IN )    :: JDATE, JTIME, TSTEP( 3 )
         END SUBROUTINE PA_INIT
         SUBROUTINE SCIPROC ( CGRID, JDATE, JTIME, TSTEP, ASTEP )
            IMPLICIT NONE
            REAL, POINTER            :: CGRID( :,:,:,: )
            INTEGER, INTENT( INOUT ) :: JDATE, JTIME
            INTEGER, INTENT( IN )    :: TSTEP( 3 ), ASTEP( : )
         END SUBROUTINE SCIPROC
         SUBROUTINE WR_ACONC ( AGRID, JDATE, JTIME, TSTEP )
            IMPLICIT NONE
            REAL,    INTENT( IN )    :: AGRID( :,:,:,: )
            INTEGER, INTENT( IN )    :: JDATE, JTIME, TSTEP
         END SUBROUTINE WR_ACONC
         SUBROUTINE WR_CGRID ( CGRID, JDATE, JTIME, TSTEP )
            IMPLICIT NONE
            REAL, POINTER            :: CGRID( :,:,:,: )
            INTEGER, INTENT( IN )    :: JDATE, JTIME, TSTEP
         END SUBROUTINE WR_CGRID
         SUBROUTINE PA_OUTPUT ( CGRID, JDATE, JTIME )
            IMPLICIT NONE
            REAL, POINTER            :: CGRID( :,:,:,: )
            INTEGER, INTENT( IN )    :: JDATE, JTIME
         END SUBROUTINE PA_OUTPUT
      END INTERFACE

C-----------------------------------------------------------------------

      STEP_COUNT = STEP_COUNT + 1

      IF ( FIRST_RUN ) THEN

#ifdef twoway
         STDATE     = WRF_SDATE
         STTIME     = WRF_STIME
         TSTEP( 3 ) = SEC2TIME( WRF_TSTEP )
         NSTEPS     = WRF_NSTEP

         RUNLEN = ENVINT( 'CTM_RUNLEN', ' ', RUNLEN, STATUS )
         TOTAL_STEPS = TIME2SEC( RUNLEN ) / WRF_TSTEP
#endif

#ifdef parallel
C Start up processor communication
         CALL MPCOMM_INIT( NPROCS, MYPE, CLOCK, PAR_ERR )
#else
         NPROCS = 1
         MYPE = 0
#endif

         JDATE = 0
         JTIME = 0

C Start I/O-API and set up log file(s)
!        LOGDEV = INIT3()
         LOGDEV = SETUP_LOGDEV()

C Set up horizontal domain, calculate processor-to-subdomain maps
C and define vertical layer structure (in module GRID_CONF)
         IF ( .NOT. GRID_INIT ( NPROCS, MYPE ) ) THEN
            XMSG = '*** Failure defining domain configuration'
            CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
         END IF

#ifdef Verbose
         write( logdev,* ) ' MYPE -> NPROCS:   ', mype, nprocs
         write( logdev,* ) ' MYPE -> NPCOL:    ', mype, npcol
         write( logdev,* ) ' MYPE -> NPROW:    ', mype, nprow
         write( logdev,* ) ' MYPE -> GL_NCOLS: ', mype, gl_ncols
         write( logdev,* ) ' MYPE -> GL_NROWS: ', mype, gl_nrows
         write( logdev,* ) ' MYPE -> NLAYS:    ', mype, nlays
#endif

C Set CGRID mechanism
         IF ( .NOT. CGRID_SPCS_INIT() ) THEN
            XMSG = 'Error in CGRID_SPCS:CGRID_SPCS_INIT'
            CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, 1 )
         END IF
#ifdef Verbose
         write( logdev,* ) ' MYPE -> NSPCS:    ', mype, nspcsd
#endif

#ifdef parallel
C Initialize parallel I/O
         IF ( .NOT. PIO_RE_INIT( COLROW, GL_NCOLS, GL_NROWS, NLAYS, NTHIK,
     &                           NCOLS, NROWS, NPCOL, NPROW, NPROCS,
     &                           MYPE, .TRUE. ) ) THEN
            XMSG = 'Failed to initialize parallel I/O library.'
            CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
         END IF

C Initialize stencil exchange
         CALL SE_INIT( NPROCS, NPCOL, NPROW, GL_NCOLS, GL_NROWS, NLAYS,
     &                 NSPCSD, MYPE, MNDIS, MEDIS, MSDIS, MWDIS)
         CALL SWAP_INIT_SNL( NPCOL, NPROW )
#ifdef Verbose
         write( logdev,* ) ' MYPE -> MNDIS:    ', mype, mndis
         write( logdev,* ) ' MYPE -> MEDIS:    ', mype, medis
         write( logdev,* ) ' MYPE -> MSDIS:    ', mype, msdis
         write( logdev,* ) ' MYPE -> MWDIS:    ', mype, mwdis
#endif
#endif

C Set up horizontal domain and calculate processor-to-subdomain maps for
C process analysis, if required
         IF ( LIPR .OR. LIRR ) THEN
            IF ( .NOT. PAGRD_INIT( NPROCS, MYPE ) ) THEN
               XMSG = '*** Failure defining PA domain configuration'
               CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
            END IF
         END IF

         IF ( NSPCSD .GT. MXVARS3 ) THEN
            WRITE( XMSG,'(5X, A, I5, A)' ) 'The number of variables,', NSPCSD,
     &      ' to be written to the State CGRID File'
            WRITE( LOGDEV, '( A )' ) XMSG
            WRITE( XMSG,'(5X, A, I5)' ) 'exceeds the I/O-API limit:', MXVARS3
            WRITE( LOGDEV, '( A )' ) XMSG
            XMSG = 'Recompile with an I/O-API lib having a larger MXVARS3'
            WRITE( LOGDEV, '( 5X, A )' ) XMSG
            CALL M3EXIT( PNAME, JDATE, JTIME, ' ', XSTAT1 )
         END IF

C Initialize PCGRID
         IF ( .NOT. PCGRID_INIT () ) THEN
            XMSG = 'Failure defining horizontal domain'
            CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT2  )
         END IF
      
         CGRID => PCGRID( 1:MY_NCOLS,1:MY_NROWS,:,: )   ! required for PinG

C Initalize CONC definitions (in STD_CONC F90 module)
         CALL CONC_DEFN ()

C Get avg CONC definitions, species and layer pointers (in AVG_CONC F90 module)
         CALL A_CONC_DEFN ()
         A_NLYS = ACONC_ELEV - ACONC_BLEV + 1

C Initialize optional derived vertical velocity writes to conc file
         IF ( .NOT. WVEL_INIT () ) THEN
            XMSG = 'Failure initializing derived vertical velocity writes'
            CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT2  )
         END IF

C Initialize conc field: Copy IC's to CONC file as step 0
C Convention: the input file concentration units are always ppmV.
         CALL INITSCEN ( CGRID, STDATE, STTIME, TSTEP, NSTEPS )
         JDATE = STDATE; JTIME = STTIME
         CALL CKSUMMER ( 'INITSCEN', CGRID, JDATE, JTIME )

         IF ( LIPR .OR. LIRR ) CALL PA_INIT ( CGRID, JDATE, JTIME, TSTEP )

C Verify input file header consistency and run duration
         CALL FLCHECK ( JDATE, JTIME, TSTEP( 1 ) )

         ALLOCATE ( AGRID( MY_NCOLS,MY_NROWS,A_NLYS,N_ASPCS ), STAT = ALLOCSTAT )
         IF ( ALLOCSTAT .NE. 0 ) THEN
            XMSG = 'AGRID memory allocation failed'
            CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
         END IF

!        AGRID = 0.0

         ALLOCATE ( ASTEP( NLAYS ), STAT = ALLOCSTAT )
         IF ( ALLOCSTAT .NE. 0 ) THEN
            XMSG = 'ASTEP memory allocation failed'
            CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
         END IF

         FIRST_RUN = .FALSE.

#ifdef twoway
         CMAQ_WRF_FEEDBACK = ENVYN( 'CMAQ_WRF_FEEDBACK', ' ', .FALSE., STATUS )
         IF ( STATUS .EQ. 1 ) THEN
            PRINT *, 'Environment variable improperly formatted'
            STOP
         ELSE IF ( STATUS .EQ. -1 ) THEN
            PRINT *, 'Environment variable set, but empty ... Using default:'
         ELSE IF ( STATUS .EQ. -2 ) THEN
            PRINT *, 'Environment variable not set ... Using default:'
         END IF

         IF ( CMAQ_WRF_FEEDBACK ) THEN
            CALL FEEDBACK_SETUP ( JDATE, JTIME, TSTEP( 3 ) )
         END IF

         SD_TIME_SERIES = ENVYN( "SD_TIME_SERIES", ' ', .FALSE., STATUS )
         IF ( SD_TIME_SERIES ) THEN
            CALL SD_TIME_SERIES_INIT ( LOGDEV, TSTEP( 3 ) )
            CALL OUTPUT_SD_TIME_SERIES ( CGRID, JDATE, JTIME )
         END IF
#endif

      END IF ! first_run

C Main processing loop:

#ifdef twoway
      TWOWAY_JDATE = JDATE
      TWOWAY_JTIME = JTIME
#else
      DO 201 ISTEP = 1, NSTEPS   ! output time step loop
#endif

C Get synchronization and advection time steps, TSTEP(2), ASTEP(L) and NREPS
         CALL ADVSTEP ( JDATE, JTIME, TSTEP, ASTEP, NREPS )

#ifdef twoway
         IF ( MOD( TIME2SEC( JTIME ), TIME2SEC( TSTEP( 1 ) ) ) .EQ. 0 ) THEN
#endif
            DO V = 1, N_ASPCS
               S = AVG_CONC_MAP( V )
               L = 0
               DO K = ACONC_BLEV, ACONC_ELEV
                  L = L + 1
                  DO R = 1, MY_NROWS
                     DO C = 1, MY_NCOLS
                        AGRID( C,R,L,V ) = CGRID( C,R,K,S )
                     END DO
                  END DO
               END DO
            END DO
#ifdef twoway
         END IF
#endif

C science process sequence:
         
#ifdef twoway
         myNREPS = myNREPS + NREPS
#else
         DIVFAC = 0.5 / FLOAT( NREPS )
#endif

         DO IREP = 1, NREPS

            CALL SCIPROC ( CGRID, JDATE, JTIME, TSTEP, ASTEP )

            DO V = 1, N_ASPCS
               S = AVG_CONC_MAP( V )
               L = 0
               DO K = ACONC_BLEV, ACONC_ELEV
                  L = L + 1
                  DO R = 1, MY_NROWS
                     DO C = 1, MY_NCOLS
                        AGRID( C,R,L,V ) = AGRID( C,R,L,V )
     &                                   + 2.0 * CGRID( C,R,K,S )
                     END DO
                  END DO
               END DO
            END DO

         END DO

#ifdef twoway
         IF ( MOD( TIME2SEC( JTIME ), TIME2SEC( TSTEP( 1 ) ) ) .EQ. 0 ) THEN
!        print *, ' ==d== NREPS d ', myNREPS
         DIVFAC = 0.5 / FLOAT( myNREPS )
         myNREPS = 0
#endif
            DO V = 1, N_ASPCS
               S = AVG_CONC_MAP( V )
               L = 0
               DO K = ACONC_BLEV, ACONC_ELEV
                  L = L + 1
                  DO R = 1, MY_NROWS
                     DO C = 1, MY_NCOLS
                        AGRID( C,R,L,V ) = DIVFAC * ( AGRID( C,R,L,V )
     &                                   -            CGRID( C,R,K,S ) )
                     END DO
                  END DO
               END DO
            END DO
#ifdef twoway
         END IF
#endif

         DO V = 1, N_CSPCS
            S = CONC_MAP( V )
            L = 0
            DO K = CONC_BLEV, CONC_ELEV
               L = L + 1
               DO R = 1, MY_NROWS
                  DO C = 1, MY_NCOLS
                     SGRID( C,R,L,V ) = CGRID( C,R,K,S )
                  END DO
               END DO
            END DO
         END DO

C write conc fields

         IF ( MOD( TIME2SEC( JTIME ), TIME2SEC( TSTEP( 1 ) ) ) .EQ. 0 ) THEN
            CALL WR_CONC ( JDATE, JTIME, TSTEP( 1 ) )
            CALL WR_ACONC ( AGRID, JDATE, JTIME, TSTEP( 1 ) )
            IF ( LIPR .OR. LIRR ) CALL PA_OUTPUT ( CGRID, JDATE, JTIME )
         END IF

#ifdef twoway
         IF ( SD_TIME_SERIES ) THEN
            CALL OUTPUT_SD_TIME_SERIES ( CGRID, JDATE, JTIME )
         END IF
#else

201      CONTINUE

#endif

      IF ( ( STEP_COUNT .EQ. TOTAL_STEPS ) .OR. ( TOTAL_STEPS .EQ. 0 ) ) THEN
C write CGRID state file for subsequent runs
         CALL WR_CGRID ( CGRID, JDATE, JTIME, TSTEP( 1 ) )
      END IF

#ifdef twoway
      END SUBROUTINE CMAQ_DRIVER
#else

C shut down
#ifdef parallel
C Clean up communications and shut down IOAPI
      CALL PAR_TERM ( PNAME, JDATE, JTIME, CLOCK )
#endif

C Shut down IOAPI
      IF ( SHUT3() ) THEN
         XMSG = '>>---->  Program completed successfully  <----<<'
         WRITE ( LOGDEV,'( //5X, A, // )' ) XMSG
      ELSE
         XMSG = ' *** FATAL ERROR shutting down Models-3 I/O *** '
         WRITE ( LOGDEV,'( //5X, A, // )' ) XMSG
         CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
      END IF

      END PROGRAM DRIVER
#endif
