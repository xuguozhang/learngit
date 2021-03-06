
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

       SUBROUTINE HRG4( DTC )

C**********************************************************************
C
C  FUNCTION:  To solve for the concentration of NO3 and N2O5
C
C  PRECONDITIONS: For the RACM2 family of mechanisms
C
C  KEY SUBROUTINES/FUNCTIONS CALLED: None
C
C  REVISION HISTORY: Created by EBI solver program, March 4, 2013
C
C**********************************************************************
      USE HRDATA

      IMPLICIT NONE


C..INCLUDES: NONE


C..ARGUMENTS:
      REAL DTC             ! Time step


C..PARAMETERS: NONE


C..EXTERNAL FUNCTIONS: NONE


C..SAVED LOCAL VARIABLES:
      CHARACTER( 16 ), SAVE   ::  PNAME = 'HRG4'    ! Program name


C..SCRATCH LOCAL VARIABLES:
      REAL   A, B, C, Q   ! Quadratic equation terms
      REAL   CMN          ! Temp scalar
      REAL   L15          ! Loss of NO3
      REAL   L16          ! Loss of N2O5
      REAL   P15          ! Production of NO3
      REAL   K15_15       ! Kno3+no3 * delta t
      REAL   R15_16       ! Kn2o5-->no3 * delta t
      REAL   R16_15       ! Kno3+no2-->n2o5[NO2] * delta t


C**********************************************************************


c..Production of NO3 (except from N2O5 )
      P15 =   0.200 * RXRAT(   9 )      ! HNO4=0.2*NO3+0.8*HO2+...
     &     +          RXRAT(  33 )      ! PAN=NO3+MO2
     &     +          RXRAT(  37 )      ! O3+NO2=NO3
     &     +          RXRAT(  55 )      ! NO2+O3P=NO3
     &     +          RXRAT(  57 )      ! HNO3+HO=NO3
     &     +          RXRAT( 120 )      ! PAN+HO=NO3+XO2+HCHO
     &     +          RXRAT( 121 )      ! PPN+HO=NO3+XO2+HCHO

c..Loss frequency of NO3 ( except NO3 + NO3 if present )
      L15 =           RKI(   5 )                   ! NO3=NO
     &     +          RKI(   6 )                   ! NO3=O3P+NO2
     &     +          RKI(  58 ) * YC( HO      )   ! NO3+HO=HO2+NO2
     &     +          RKI(  59 ) * YC( HO2     )   ! NO3+HO2=0.7*HO+...
     &     +          RKI(  60 ) * YC( NO      )   ! NO3+NO=2*NO2
     &     +          RKI(  61 ) * YC( NO2     )   ! NO3+NO2=NO+NO2
     &     +          RKI(  63 ) * YC( NO2     )   ! NO3+NO2=N2O5
     &     +          RKI( 141 ) * YC( ETE     )   ! NO3+ETE=0.8*OLNN+...
     &     +          RKI( 142 ) * YC( OLT     )   ! NO3+OLT=...
     &     +          RKI( 143 ) * YC( OLI     )   ! NO3+OLI=...
     &     +          RKI( 144 ) * YC( DIEN    )   ! NO3+DIEN=...
     &     +          RKI( 145 ) * YC( ISO     )   ! NO3+ISO=ISON
     &     +          RKI( 146 ) * YC( API     )   ! NO3+API=0.1*OLNN+...
     &     +          RKI( 147 ) * YC( LIM     )   ! NO3+LIM=...
     &     +          RKI( 148 ) * YC( HCHO    )   ! NO3+HCHO=HO2+CO+HNO3
     &     +          RKI( 149 ) * YC( ACD     )   ! NO3+ACD=ACO3+HNO3
     &     +          RKI( 150 ) * YC( ALD     )   ! NO3+ALD=RCO3+HNO3
     &     +          RKI( 151 ) * YC( MACR    )   ! NO3+MACR=...
     &     +          RKI( 152 ) * YC( UALD    )   ! NO3+UALD=HO2+XO2+...
     &     +          RKI( 153 ) * YC( GLY     )   ! NO3+GLY=HO2+2*CO+...
     &     +          RKI( 154 ) * YC( MGLY    )   ! NO3+MGLY=ACO3+CO+...
     &     +          RKI( 155 ) * YC( PHEN    )   ! NO3+PHEN=0.4*CHO+...
     &     +          RKI( 156 ) * YC( CSL     )   ! NO3+CSL=0.4*CHO+...
     &     +          RKI( 157 ) * YC( EPX     )   ! NO3+EPX=0.5*HO+...
     &     +          RKI( 158 ) * YC( MCT     )   ! NO3+MCT=MCTO+HNO3
     &     +          RKI( 159 ) * YC( MPAN    )   ! NO3+MPAN=MACP+NO2
     &     +          RKI( 322 ) * YC( MO2     )   ! NO3+MO2=HO2+HCHO+NO2
     &     +          RKI( 323 ) * YC( ETHP    )   ! NO3+ETHP=HO2+NO2+ACD
     &     +          RKI( 324 ) * YC( HC3P    )   ! NO3+HC3P=...
     &     +          RKI( 325 ) * YC( HC5P    )   ! NO3+HC5P=...
     &     +          RKI( 326 ) * YC( HC8P    )   ! NO3+HC8P=...
     &     +          RKI( 327 ) * YC( ETEP    )   ! NO3+ETEP=HO2+NO2+...
     &     +          RKI( 328 ) * YC( OLTP    )   ! NO3+OLTP=...
     &     +          RKI( 329 ) * YC( OLIP    )   ! NO3+OLIP=...
     &     +          RKI( 330 ) * YC( BENP    )   ! NO3+BENP=HO2+NO2+...
     &     +          RKI( 331 ) * YC( TLP1    )   ! NO3+TLP1=NO2+BALD
     &     +          RKI( 332 ) * YC( TOLP    )   ! NO3+TOLP=HO2+NO2+...
     &     +          RKI( 333 ) * YC( PER1    )   ! NO3+PER1=0.5*HO2+...
     &     +          RKI( 334 ) * YC( XYL1    )   ! NO3+XYL1=NO2+BALD
     &     +          RKI( 335 ) * YC( XYLP    )   ! NO3+XYLP=HO2+NO2+...
     &     +          RKI( 336 ) * YC( PER2    )   ! NO3+PER2=HO2+NO2+...
     &     +          RKI( 337 ) * YC( XYOP    )   ! NO3+XYOP=HO2+NO2+...
     &     +          RKI( 338 ) * YC( ISOP    )   ! NO3+ISOP=HO2+NO2+...
     &     +          RKI( 339 ) * YC( APIP    )   ! NO3+APIP=HO2+NO2+...
     &     +          RKI( 340 ) * YC( LIMP    )   ! NO3+LIMP=HO2+NO2+...
     &     +          RKI( 341 ) * YC( ACO3    )   ! NO3+ACO3=MO2+NO2
     &     +          RKI( 342 ) * YC( RCO3    )   ! NO3+RCO3=ETHP+NO2
     &     +          RKI( 343 ) * YC( ACTP    )   ! NO3+ACTP=ACO3+...
     &     +          RKI( 344 ) * YC( MEKP    )   ! NO3+MEKP=...
     &     +          RKI( 345 ) * YC( KETP    )   ! NO3+KETP=HO2+NO2+...
     &     +          RKI( 346 ) * YC( MACP    )   ! NO3+MACP=HCHO+...
     &     +          RKI( 347 ) * YC( MCP     )   ! NO3+MCP=NO2+HO2+...
     &     +          RKI( 348 ) * YC( MVKP    )   ! NO3+MVKP=0.3*HO2+...
     &     +          RKI( 349 ) * YC( UALP    )   ! NO3+UALP=HO2+NO2+...
     &     +          RKI( 350 ) * YC( BALP    )   ! NO3+BALP=BAL1+NO2
     &     +          RKI( 351 ) * YC( BAL1    )   ! NO3+BAL1=BAL2+NO2
     &     +          RKI( 352 ) * YC( ADDC    )   ! NO3+ADDC=HO2+NO2+...
     &     +          RKI( 353 ) * YC( MCTP    )   ! NO3+MCTP=NO2+MCTO
     &     +          RKI( 354 ) * YC( ORAP    )   ! NO3+ORAP=NO2+GLY+HO2
     &     +          RKI( 355 ) * YC( OLNN    )   ! NO3+OLNN=HO2+NO2+...
     &     +          RKI( 356 ) * YC( OLND    )   ! NO3+OLND=2*NO2+...
     &     +          RKI( 357 ) * YC( ADCN    )   ! NO3+ADCN=2*NO2+...
     &     +          RKI( 361 ) * YC( XO2     )   ! NO3+XO2=NO2

c..Loss frequency of N2O5
      L16 =           RKI(  64 )                   ! N2O5=NO2+NO3
     &     +          RKI(  65 )                   ! N2O5=2*HNO3

c..K15_15, R15_16, and R16_15 terms
      K15_15  = RKI(  62 ) * DTC

      R15_16  = ( RKI(  64 ) ) * DTC 


      R16_15  = RKI(  63 ) * YC( NO2 ) * DTC

c..Solution of quadratic equation to get NO3 & N2O5
      CMN = 1.0 + L16 * DTC
      A = 2.0 * K15_15 * CMN
      B = CMN * ( 1.0 + L15 * DTC ) - R15_16 * R16_15
      C = CMN * ( YC0( NO3 ) + P15 * DTC ) +  R15_16 * YC0( N2O5 )

      Q = -0.5 * ( B + SIGN( 1.0, B ) * SQRT( B * B + 4.0 * A * C ) )
      YCP( NO3 ) = MAX( Q / A , -C / Q  )
      YCP( N2O5 ) = ( YC0( N2O5 ) + R16_15 * YCP( NO3 ) ) / CMN

      RETURN

      END
