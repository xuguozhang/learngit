
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
C $Header$

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

      MODULE  HRDATA

C*************************************************************************
C
C  FUNCTION:  Mechanism & solver data for EBI solver
C
C  PRECONDITIONS: For the SAPRC07TB family of mechanisms
C
C  KEY SUBROUTINES/FUNCTIONS CALLED: None
C
C  REVISION HISTORY: Created by EBI solver program, June 1, 2012
C
C*************************************************************************

c..EBI solver fixed parameters
      INTEGER, PARAMETER ::  NEBITER = 1000  ! No. of iterations for EBI

      REAL, PARAMETER    ::  DELTAT = 2.5D+00     ! EBI time step

c..Mechanism specific variables
      INTEGER   N_SPEC       ! No. of species in mechanism
      INTEGER   N_RXNS       ! No. of reactions in mechanism
      INTEGER   N_EBISP      ! No. of species solved by EBI
      INTEGER   NING1        ! No. of species in group 1
      INTEGER   NING2        ! No. of species in group 2
      INTEGER   N_SPCL_RKS   ! No. of special rate constants
      INTEGER   N_ACTSP      ! No. of species in mechanism (non-ss spec)

c..Control flags
      LOGICAL   L_AE_VRSN    ! Flag for aerosol version of mech
      LOGICAL   L_AQ_VRSN    ! Flag for aqueous chemistry version of mech


c..Miscellaneous variables
      INTEGER   LOGDEV        ! Unit number of output log
      INTEGER   N_EBI_IT      ! No. of iterations for EBI
      INTEGER   N_EBI_STEPS   ! No. of time steps for EBI
      INTEGER   N_INR_STEPS   ! No. of inner time steps for EBI

      REAL    EBI_TMSTEP   ! Time step for EBI loops (min)

c...Allocatable arrays
      INTEGER, ALLOCATABLE :: EBISP( : )         ! Index of EBI species
      INTEGER, ALLOCATABLE :: SSASP( : )         ! Index of ss species
      INTEGER, ALLOCATABLE :: ACTSP( : )         ! Index of active species

      REAL( 8 ), ALLOCATABLE ::  RKI(   : )   ! Rate constants
      REAL( 8 ), ALLOCATABLE :: RKI_SAV( : )  ! Saved values of RKI for SS species calcs
      REAL, ALLOCATABLE ::  RXRAT( : )     ! Reaction rates
      REAL, ALLOCATABLE ::  RTOL(  : )     ! Species tolerances
      REAL, ALLOCATABLE ::  YC(    : )     ! Species concentrations
      REAL, ALLOCATABLE ::  YC0(   : )     ! Species concentrations
      REAL, ALLOCATABLE ::  YCP(   : )     ! Species concentrations
      REAL, ALLOCATABLE ::  PROD(  : )     ! Prod of species
      REAL, ALLOCATABLE ::  LOSS(  : )     ! Loss of species


c..Species indices
      INTEGER   NO2
      INTEGER   NO
      INTEGER   O3P
      INTEGER   O3
      INTEGER   NO3
      INTEGER   N2O5
      INTEGER   HNO3
      INTEGER   O1D
      INTEGER   OH
      INTEGER   HONO
      INTEGER   HO2
      INTEGER   CO
      INTEGER   CO2
      INTEGER   HNO4
      INTEGER   HO2H
      INTEGER   SO2
      INTEGER   SULF
      INTEGER   SULRXN
      INTEGER   NO2EX
      INTEGER   MEO2
      INTEGER   HCHO
      INTEGER   COOH
      INTEGER   MEOH
      INTEGER   RO2C
      INTEGER   RO2XC
      INTEGER   MECO3
      INTEGER   PAN
      INTEGER   CCOOOH
      INTEGER   CCOOH
      INTEGER   RCO3
      INTEGER   PAN2
      INTEGER   xHO2
      INTEGER   yROOH
      INTEGER   xCCHO
      INTEGER   RCOOOH
      INTEGER   RCOOH
      INTEGER   BZCO3
      INTEGER   PBZN
      INTEGER   BZO
      INTEGER   MACO3
      INTEGER   MAPAN
      INTEGER   TBUO
      INTEGER   RNO3
      INTEGER   ACETONE
      INTEGER   NPHE
      INTEGER   CRES
      INTEGER   xOH
      INTEGER   xNO2
      INTEGER   xMEO2
      INTEGER   xMECO3
      INTEGER   xRCO3
      INTEGER   xMACO3
      INTEGER   xTBUO
      INTEGER   xCO
      INTEGER   CCHO
      INTEGER   RCHO
      INTEGER   xHCHO
      INTEGER   MEK
      INTEGER   zRNO3
      INTEGER   xRCHO
      INTEGER   HCOOH
      INTEGER   xMGLY
      INTEGER   xBACL
      INTEGER   ROOH
      INTEGER   xPROD2
      INTEGER   R6OOH
      INTEGER   PRD2
      INTEGER   yR6OOH
      INTEGER   RAOOH
      INTEGER   MGLY
      INTEGER   IPRD
      INTEGER   xGLY
      INTEGER   xMEK
      INTEGER   xAFG1
      INTEGER   xAFG2
      INTEGER   GLY
      INTEGER   AFG1
      INTEGER   AFG2
      INTEGER   BACL
      INTEGER   BALD
      INTEGER   AFG3
      INTEGER   xIPRD
      INTEGER   MACR
      INTEGER   MVK
      INTEGER   xHOCCHO
      INTEGER   xRNO3
      INTEGER   HOCCHO
      INTEGER   xACETONE
      INTEGER   ACROLEIN
      INTEGER   xBALD
      INTEGER   xAFG3
      INTEGER   xMACR
      INTEGER   xMVK
      INTEGER   yRAOOH
      INTEGER   xACROLEIN
      INTEGER   ETHENE
      INTEGER   PROPENE
      INTEGER   BUTADIENE13
      INTEGER   ISOPRENE
      INTEGER   ISOPRXN
      INTEGER   APIN
      INTEGER   TRPRXN
      INTEGER   ACETYLENE
      INTEGER   BENZENE
      INTEGER   BENZRO2
      INTEGER   TOLUENE
      INTEGER   TOLRO2
      INTEGER   MXYL
      INTEGER   XYLRO2
      INTEGER   OXYL
      INTEGER   PXYL
      INTEGER   TRIMETH_BENZ124
      INTEGER   ETOH
      INTEGER   ALK1
      INTEGER   ALK2
      INTEGER   ALK3
      INTEGER   ALK4
      INTEGER   ALK5
      INTEGER   ALK5RXN
      INTEGER   OLE1
      INTEGER   OLE2
      INTEGER   ARO1
      INTEGER   ARO2
      INTEGER   TERP
      INTEGER   SESQ
      INTEGER   SESQRXN
      INTEGER   CL2
      INTEGER   CL
      INTEGER   CLNO
      INTEGER   CLONO
      INTEGER   CLNO2
      INTEGER   HCL
      INTEGER   CLO
      INTEGER   CLONO2
      INTEGER   HOCL
      INTEGER   xCL
      INTEGER   xCLCCHO
      INTEGER   xCLACET
      INTEGER   CLCCHO
      INTEGER   CLACET
      INTEGER   CLCHO
      INTEGER   BNZNRXN
      INTEGER   BNZHRXN
      INTEGER   XYLNRXN
      INTEGER   XYLHRXN
      INTEGER   TOLNRXN
      INTEGER   TOLHRXN
      INTEGER   HCHO_PRIMARY
      INTEGER   CCHO_PRIMARY
      INTEGER   ACROLEIN_PRIMARY

      END MODULE HRDATA
