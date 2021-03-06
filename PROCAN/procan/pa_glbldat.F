
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
C $Header: /project/yoj/arc/PROCAN/src/driver/pa/pa_glbldat.F,v 1.6 2011/11/02 14:33:59 yoj Exp $

      SUBROUTINE PA_GLBLDAT ( 
     &           MXSPEC, MXRXNS, MXPRD_IN,
     &           N_GC_SPC_IN, N_AE_SPC_IN, N_NR_SPC_IN, N_TR_SPC_IN,
     &           GC_SPC_IN, AE_SPC_IN, NR_SPC_IN, TR_SPC_IN,
     &           NRXNS_IN,
     &           RXLABEL_IN, NREACT_IN, NPRDCT_IN,
     &           IRXBITS_IN, IRR_IN, SC_IN )

C***********************************************************************
 
C Function: To get mechanism and grid data to pass to the main
C           PACP program.  It is included to speed compile time.
                
C Preconditions: None
  
C Key Subroutines/Functions Called: None
 
C Revision History:
C  Prototype created by Jerry Gipson, May, 1997
C  Modified Sept, 1997 by Jerry Gipson to be consistent with the targeted CTM
C  Updated May 2002 by Jerry Gipson for dynamic allocation version of CCTM
C  Aug 2011 Jeff Young: Replaced I/O API include files with IOAPI's M3UTILIO
C  Aug 2011 Jeff Young: Convert for mechansim Include files to Namelist

C***********************************************************************
      USE M3UTILIO      ! IOAPI module
      USE CGRID_SPCS

      IMPLICIT NONE
      
C Includes:
!     INCLUDE SUBST_RXCMMN  available in CGRID_SPCS
!     INCLUDE SUBST_RXDATA  available in CGRID_SPCS

C Arguments:
      INTEGER MXSPEC       ! Maximum number of species in mechanism
      INTEGER MXRXNS       ! Maximum number of Reactions in mechanism
      INTEGER MXPRD_IN     ! Maximum number of Products in a reaction
      INTEGER N_GC_SPC_IN  ! No. of gas-chemistry species
      INTEGER N_AE_SPC_IN  ! No. of aerosol species
      INTEGER N_NR_SPC_IN  ! No. of non-reactive species
      INTEGER N_TR_SPC_IN  ! No. of tracer species
      CHARACTER( 16 ) :: GC_SPC_IN ( MXSPEC )  ! Gas-chemistry species names
      CHARACTER( 16 ) :: AE_SPC_IN ( MXSPEC )  ! Aerosol species names
      CHARACTER( 16 ) :: NR_SPC_IN ( MXSPEC )  ! Non-reactive species names
      CHARACTER( 16 ) :: TR_SPC_IN ( MXSPEC )  ! Tracer species names
      CHARACTER( 16 ) :: RXLABEL_IN( MXRXNS )  ! Reaction labels
      INTEGER NRXNS_IN              ! Number of mechanism reactions
      INTEGER NREACT_IN ( MXRXNS )  ! Number of reactants in each reaction
      INTEGER NPRDCT_IN ( MXRXNS )  ! Number of products in each reaction 
      INTEGER IRXBITS_IN( MXRXNS )  ! Bit test vector for selected reactions
      INTEGER IRR_IN( MXRXNS,MXPRD_IN + 3 )  ! Pointer to reactants and
                                             ! products in reactions
      REAL    SC_IN ( MXRXNS,MXPRD_IN )      ! Stoichiometric coefficients

C Parameters: None

C External FUNCTIONS: None 

C Local Variables:
      CHARACTER(  16 ) :: PNAME = 'PA_GLBLDAT'   ! Procedure name
      CHARACTER( 132 ) :: MSG     ! Error message

      LOGICAL LERROR        ! Error Flag

      INTEGER N, NP         ! Loop indices
      INTEGER MAXNSPC       ! Maximum no. of species in AE, GC, NR, TR

C***********************************************************************

C Set CGRID mechanism
      IF ( .NOT. CGRID_SPCS_INIT() ) THEN
         MSG = 'Error in CGRID_GC_SPCS:CGRID_SPCS_INIT'
         CALL M3EXIT ( PNAME, 0, 0, MSG, XSTAT1 )
      END IF

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c Error checking
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      LERROR = .FALSE.

      MAXNSPC = 0
      MAXNSPC = MAX( MAXNSPC, N_GC_SPC )
      MAXNSPC = MAX( MAXNSPC, N_AE_SPC )
      MAXNSPC = MAX( MAXNSPC, N_NR_SPC )
      MAXNSPC = MAX( MAXNSPC, N_TR_SPC )

      IF ( MAXNSPC .GT. MXSPEC ) THEN
         WRITE( MSG,94000 ) 
         CALL M3MESG( MSG )
         WRITE( MSG, 94020 ) MXSPEC, MAXNSPC 
         CALL M3MESG( MSG )
         LERROR = .TRUE.
      END IF

      IF ( NRXNS .GT. MXRXNS ) THEN
         WRITE( MSG,94040 ) 
         CALL M3MESG( MSG )
         WRITE( MSG, 94060 ) MXRXNS, NRXNS
         CALL M3MESG( MSG )
         LERROR = .TRUE.
      END IF

      IF ( MXPRD .GT. MXPRD_IN ) THEN
         WRITE( MSG,94080 ) 
         CALL M3MESG( MSG )
         WRITE( MSG, 94100 ) MXPRD_IN, MXPRD
         CALL M3MESG( MSG )
         LERROR = .TRUE.
      END IF

      IF ( LERROR ) THEN
         WRITE( MSG, 94120 )
         CALL M3MESG( MSG )
         CALL M3EXIT( PNAME, 0, 0, ' ', XSTAT2 )
      END IF

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c Copy global include file data to PACP variables
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      
      N_GC_SPC_IN = N_GC_SPC
      N_AE_SPC_IN = N_AE_SPC
      N_NR_SPC_IN = N_NR_SPC
      N_TR_SPC_IN = N_TR_SPC
      NRXNS_IN = NRXNS
      
      DO N = 1, N_GC_SPC
         GC_SPC_IN( N ) = GC_SPC( N )
      END DO

      DO N = 1, N_AE_SPC
         AE_SPC_IN( N ) = AE_SPC( N )
      END DO

      DO N = 1, N_NR_SPC
         NR_SPC_IN( N ) = NR_SPC( N )
      END DO
      

      DO N = 1, N_TR_SPC
         TR_SPC_IN( N ) = TR_SPC( N )
      END DO
      
      DO N = 1, NRXNS
         RXLABEL_IN( N ) = RXLABEL( N )
         IRXBITS_IN( N ) = IRXBITS( N )
         NREACT_IN ( N ) = NREACT(  N )
         NPRDCT_IN ( N ) = NPRDCT(  N )
         DO NP = 1, MXPRD
            SC_IN( N,NP ) = SC( N,NP )
         END DO
         DO NP = 1, MXPRD + 3
            IRR_IN( N,NP ) = IRR( N,NP )
         END DO
      END DO
      
      RETURN 

94000 FORMAT( 'ERROR: Maximum number of species exceeded' )
94020 FORMAT( '       Increase PARAMETER ( MXSPEC =', I3,' ) to ', I3 )
94040 FORMAT( 'ERROR: Maximum number of reactions exceeded' )
94060 FORMAT( '       Increase PARAMETER ( MXRXNS =', I3,' ) to ', I3 )
94080 FORMAT( 'ERROR: Maximum number of products exceeded' )
94100 FORMAT( '       Increase PARAMETER ( MXPRD =', I3,' ) to ', I3 )
94120 FORMAT( 'STOPPING because of dimensioning error(s)' )
  
      END

