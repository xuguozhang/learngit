
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

      SUBROUTINE HRINIT
C***********************************************************************
C
C  FUNCTION: To initialize species tolerances, arrays, and indices
C
C  PRECONDITIONS: For the SAPRC07TC family of mechanisms
C
C  RETURN VALUES: None
C
C  KEY SUBROUTINES/FUNCTIONS CALLED: None
C
C  REVISION HISTORY: Created by EBI solver program, June 1, 2012
C   21 Jun 10 J.Young: convert for Namelist redesign
C***********************************************************************

      USE CGRID_SPCS, ONLY: N_GC_SPC   ! CGRID mechanism species
      USE UTILIO_DEFN
      USE HRDATA

      IMPLICIT NONE

C.....INCLUDES:
      INCLUDE SUBST_RXCMMN    ! Mechanism reaction common block

C.....ARGUMENTS: NONE

C.....PARAMETERS: NONE


C.....EXTERNAL FUNCTIONS:
      INTEGER  FINDEX         ! Finds location of a number in a list

C.....SAVED VARIABLES:
      CHARACTER( 16 ), SAVE  ::  PNAME = 'HRINIT'   ! Program name


C.....LOCAL VARIABLES:
      CHARACTER( 132 ) ::  MSG       ! Log message

      INTEGER IND             ! Species index
      INTEGER N               ! Loop index
      INTEGER IOS             ! Allocate error status

C***********************************************************************

      N_SPEC = N_GC_SPC
      N_RXNS = NRXNS
      N_SPCL_RKS =   0
      ALLOCATE( RKI( NRXNS ),
     &          RXRAT( NRXNS ),
     &          RTOL( N_SPEC),
     &          YC(   N_SPEC),
     &          YC0(  N_SPEC),
     &          YCP(  N_SPEC),
     &          PROD( N_SPEC),
     &          LOSS( N_SPEC),
     &          STAT = IOS )

       IF ( IOS .NE. 0 ) THEN
          MSG = 'Error allocating RKI, RXRAT, RTOL, YC, YC0, YCP, PROD, LOSS, or PNEG'
          CALL M3EXIT( PNAME, 0, 0, MSG, XSTAT1 )
       END IF

      NING1 = 4
      NING2 = 4


cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Set species indices and pointers
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      NO2               =   1
      NO                =   2
      O3P               =   3
      O3                =   4
      NO3               =   5
      N2O5              =   6
      HNO3              =   7
      O1D               =   8
      OH                =   9
      HONO              =  10
      HO2               =  11
      CO                =  12
      CO2               =  13
      HNO4              =  14
      HO2H              =  15
      SO2               =  16
      SULF              =  17
      SULRXN            =  18
      NO2EX             =  19
      MEO2              =  20
      HCHO              =  21
      COOH              =  22
      MEOH              =  23
      RO2C              =  24
      RO2XC             =  25
      MECO3             =  26
      PAN               =  27
      CCOOOH            =  28
      CCOOH             =  29
      RCO3              =  30
      PAN2              =  31
      xHO2              =  32
      yROOH             =  33
      xCCHO             =  34
      RCOOOH            =  35
      RCOOH             =  36
      BZCO3             =  37
      PBZN              =  38
      BZO               =  39
      MACO3             =  40
      MAPAN             =  41
      TBUO              =  42
      RNO3              =  43
      ACETONE           =  44
      NPHE              =  45
      CRES              =  46
      xOH               =  47
      xNO2              =  48
      xMEO2             =  49
      xMECO3            =  50
      xRCO3             =  51
      xMACO3            =  52
      xTBUO             =  53
      xCO               =  54
      CCHO              =  55
      RCHO              =  56
      xHCHO             =  57
      MEK               =  58
      zRNO3             =  59
      xRCHO             =  60
      HCOOH             =  61
      xMGLY             =  62
      xBACL             =  63
      ROOH              =  64
      xPROD2            =  65
      R6OOH             =  66
      PRD2              =  67
      yR6OOH            =  68
      RAOOH             =  69
      MGLY              =  70
      IPRD              =  71
      xGLY              =  72
      xMEK              =  73
      xAFG1             =  74
      xAFG2             =  75
      GLY               =  76
      AFG1              =  77
      AFG2              =  78
      BACL              =  79
      BALD              =  80
      AFG3              =  81
      xIPRD             =  82
      MACR              =  83
      MVK               =  84
      xHOCCHO           =  85
      xRNO3             =  86
      HOCCHO            =  87
      xACETONE          =  88
      ACROLEIN          =  89
      xBALD             =  90
      xAFG3             =  91
      xMACR             =  92
      xMVK              =  93
      yRAOOH            =  94
      xACROLEIN         =  95
      ETHENE            =  96
      PROPENE           =  97
      BUTADIENE13       =  98
      ISOPRENE          =  99
      ISOPRXN           = 100
      APIN              = 101
      TRPRXN            = 102
      ACETYLENE         = 103
      BENZENE           = 104
      BENZRO2           = 105
      TOLUENE           = 106
      TOLRO2            = 107
      MXYL              = 108
      XYLRO2            = 109
      OXYL              = 110
      PXYL              = 111
      TRIMETH_BENZ124   = 112
      ETOH              = 113
      ALK1              = 114
      ALK2              = 115
      ALK3              = 116
      ALK4              = 117
      ALK5              = 118
      ALK5RXN           = 119
      OLE1              = 120
      OLE2              = 121
      ARO1              = 122
      ARO2              = 123
      TERP              = 124
      SESQ              = 125
      SESQRXN           = 126
      CL2               = 127
      CL                = 128
      CLNO              = 129
      CLONO             = 130
      CLNO2             = 131
      HCL               = 132
      CLO               = 133
      CLONO2            = 134
      HOCL              = 135
      xCL               = 136
      xCLCCHO           = 137
      xCLACET           = 138
      CLCCHO            = 139
      CLACET            = 140
      CLCHO             = 141
      BNZNRXN           = 142
      BNZHRXN           = 143
      XYLNRXN           = 144
      XYLHRXN           = 145
      TOLNRXN           = 146
      TOLHRXN           = 147
      HCHO_PRIMARY      = 148
      CCHO_PRIMARY      = 149
      ACROLEIN_PRIMARY  = 150

c..Allocate and define ebi species

      N_EBISP  = 137
      ALLOCATE( EBISP( N_EBISP ), STAT = IOS ) 
      IF ( IOS .NE. 0 ) THEN
         MSG = 'Error allocating EBISP' 
         CALL M3EXIT( PNAME, 0, 0, MSG, XSTAT1 )
      END IF

      EBISP(   1 ) = HNO3
      EBISP(   2 ) = CO
      EBISP(   3 ) = CO2
      EBISP(   4 ) = HO2H
      EBISP(   5 ) = SO2
      EBISP(   6 ) = SULF
      EBISP(   7 ) = SULRXN
      EBISP(   8 ) = NO2EX
      EBISP(   9 ) = MEO2
      EBISP(  10 ) = HCHO
      EBISP(  11 ) = COOH
      EBISP(  12 ) = MEOH
      EBISP(  13 ) = RO2C
      EBISP(  14 ) = RO2XC
      EBISP(  15 ) = CCOOOH
      EBISP(  16 ) = CCOOH
      EBISP(  17 ) = RCO3
      EBISP(  18 ) = PAN2
      EBISP(  19 ) = xHO2
      EBISP(  20 ) = yROOH
      EBISP(  21 ) = xCCHO
      EBISP(  22 ) = RCOOOH
      EBISP(  23 ) = RCOOH
      EBISP(  24 ) = BZCO3
      EBISP(  25 ) = PBZN
      EBISP(  26 ) = BZO
      EBISP(  27 ) = MACO3
      EBISP(  28 ) = MAPAN
      EBISP(  29 ) = TBUO
      EBISP(  30 ) = RNO3
      EBISP(  31 ) = ACETONE
      EBISP(  32 ) = NPHE
      EBISP(  33 ) = CRES
      EBISP(  34 ) = xOH
      EBISP(  35 ) = xNO2
      EBISP(  36 ) = xMEO2
      EBISP(  37 ) = xMECO3
      EBISP(  38 ) = xRCO3
      EBISP(  39 ) = xMACO3
      EBISP(  40 ) = xTBUO
      EBISP(  41 ) = xCO
      EBISP(  42 ) = CCHO
      EBISP(  43 ) = RCHO
      EBISP(  44 ) = xHCHO
      EBISP(  45 ) = MEK
      EBISP(  46 ) = zRNO3
      EBISP(  47 ) = xRCHO
      EBISP(  48 ) = HCOOH
      EBISP(  49 ) = xMGLY
      EBISP(  50 ) = xBACL
      EBISP(  51 ) = ROOH
      EBISP(  52 ) = xPROD2
      EBISP(  53 ) = R6OOH
      EBISP(  54 ) = PRD2
      EBISP(  55 ) = yR6OOH
      EBISP(  56 ) = RAOOH
      EBISP(  57 ) = MGLY
      EBISP(  58 ) = IPRD
      EBISP(  59 ) = xGLY
      EBISP(  60 ) = xMEK
      EBISP(  61 ) = xAFG1
      EBISP(  62 ) = xAFG2
      EBISP(  63 ) = GLY
      EBISP(  64 ) = AFG1
      EBISP(  65 ) = AFG2
      EBISP(  66 ) = BACL
      EBISP(  67 ) = BALD
      EBISP(  68 ) = AFG3
      EBISP(  69 ) = xIPRD
      EBISP(  70 ) = MACR
      EBISP(  71 ) = MVK
      EBISP(  72 ) = xHOCCHO
      EBISP(  73 ) = xRNO3
      EBISP(  74 ) = HOCCHO
      EBISP(  75 ) = xACETONE
      EBISP(  76 ) = ACROLEIN
      EBISP(  77 ) = xBALD
      EBISP(  78 ) = xAFG3
      EBISP(  79 ) = xMACR
      EBISP(  80 ) = xMVK
      EBISP(  81 ) = yRAOOH
      EBISP(  82 ) = xACROLEIN
      EBISP(  83 ) = ETHENE
      EBISP(  84 ) = PROPENE
      EBISP(  85 ) = BUTADIENE13
      EBISP(  86 ) = ISOPRENE
      EBISP(  87 ) = ISOPRXN
      EBISP(  88 ) = APIN
      EBISP(  89 ) = TRPRXN
      EBISP(  90 ) = ACETYLENE
      EBISP(  91 ) = BENZENE
      EBISP(  92 ) = BENZRO2
      EBISP(  93 ) = TOLUENE
      EBISP(  94 ) = TOLRO2
      EBISP(  95 ) = MXYL
      EBISP(  96 ) = XYLRO2
      EBISP(  97 ) = OXYL
      EBISP(  98 ) = PXYL
      EBISP(  99 ) = TRIMETH_BENZ124
      EBISP( 100 ) = ETOH
      EBISP( 101 ) = ALK1
      EBISP( 102 ) = ALK2
      EBISP( 103 ) = ALK3
      EBISP( 104 ) = ALK4
      EBISP( 105 ) = ALK5
      EBISP( 106 ) = ALK5RXN
      EBISP( 107 ) = OLE1
      EBISP( 108 ) = OLE2
      EBISP( 109 ) = ARO1
      EBISP( 110 ) = ARO2
      EBISP( 111 ) = TERP
      EBISP( 112 ) = SESQ
      EBISP( 113 ) = SESQRXN
      EBISP( 114 ) = CL2
      EBISP( 115 ) = CL
      EBISP( 116 ) = CLNO
      EBISP( 117 ) = CLONO
      EBISP( 118 ) = CLNO2
      EBISP( 119 ) = HCL
      EBISP( 120 ) = CLO
      EBISP( 121 ) = CLONO2
      EBISP( 122 ) = HOCL
      EBISP( 123 ) = xCL
      EBISP( 124 ) = xCLCCHO
      EBISP( 125 ) = xCLACET
      EBISP( 126 ) = CLCCHO
      EBISP( 127 ) = CLACET
      EBISP( 128 ) = CLCHO
      EBISP( 129 ) = BNZNRXN
      EBISP( 130 ) = BNZHRXN
      EBISP( 131 ) = XYLNRXN
      EBISP( 132 ) = XYLHRXN
      EBISP( 133 ) = TOLNRXN
      EBISP( 134 ) = TOLHRXN
      EBISP( 135 ) = HCHO_PRIMARY
      EBISP( 136 ) = CCHO_PRIMARY
      EBISP( 137 ) = ACROLEIN_PRIMARY


cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Set species tolerances
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      RTOL( NO2              ) = 1.0E-03
      RTOL( NO               ) = 1.0E-03
      RTOL( O3P              ) = 1.0E+00
      RTOL( O3               ) = 1.0E-03
      RTOL( NO3              ) = 1.0E-03
      RTOL( N2O5             ) = 1.0E-03
      RTOL( HNO3             ) = 1.0E-03
      RTOL( O1D              ) = 1.0E+00
      RTOL( OH               ) = 1.0E-03
      RTOL( HONO             ) = 1.0E-03
      RTOL( HO2              ) = 1.0E-03
      RTOL( CO               ) = 1.0E-03
      RTOL( CO2              ) = 1.0E-03
      RTOL( HNO4             ) = 1.0E-03
      RTOL( HO2H             ) = 1.0E-03
      RTOL( SO2              ) = 1.0E-03
      RTOL( SULF             ) = 1.0E+00
      RTOL( SULRXN           ) = 1.0E+00
      RTOL( NO2EX            ) = 1.0E-03
      RTOL( MEO2             ) = 1.0E-03
      RTOL( HCHO             ) = 1.0E-03
      RTOL( COOH             ) = 1.0E-03
      RTOL( MEOH             ) = 1.0E-03
      RTOL( RO2C             ) = 1.0E-03
      RTOL( RO2XC            ) = 1.0E-03
      RTOL( MECO3            ) = 1.0E-03
      RTOL( PAN              ) = 1.0E-03
      RTOL( CCOOOH           ) = 1.0E-03
      RTOL( CCOOH            ) = 1.0E-03
      RTOL( RCO3             ) = 1.0E-03
      RTOL( PAN2             ) = 1.0E-03
      RTOL( xHO2             ) = 1.0E-03
      RTOL( yROOH            ) = 1.0E-03
      RTOL( xCCHO            ) = 1.0E-03
      RTOL( RCOOOH           ) = 1.0E-03
      RTOL( RCOOH            ) = 1.0E-03
      RTOL( BZCO3            ) = 1.0E-03
      RTOL( PBZN             ) = 1.0E-03
      RTOL( BZO              ) = 1.0E-03
      RTOL( MACO3            ) = 1.0E-03
      RTOL( MAPAN            ) = 1.0E-03
      RTOL( TBUO             ) = 1.0E-03
      RTOL( RNO3             ) = 1.0E-03
      RTOL( ACETONE          ) = 1.0E-03
      RTOL( NPHE             ) = 1.0E-03
      RTOL( CRES             ) = 1.0E-03
      RTOL( xOH              ) = 1.0E-03
      RTOL( xNO2             ) = 1.0E-03
      RTOL( xMEO2            ) = 1.0E-03
      RTOL( xMECO3           ) = 1.0E-03
      RTOL( xRCO3            ) = 1.0E-03
      RTOL( xMACO3           ) = 1.0E-03
      RTOL( xTBUO            ) = 1.0E-03
      RTOL( xCO              ) = 1.0E-03
      RTOL( CCHO             ) = 1.0E-03
      RTOL( RCHO             ) = 1.0E-03
      RTOL( xHCHO            ) = 1.0E-03
      RTOL( MEK              ) = 1.0E-03
      RTOL( zRNO3            ) = 1.0E-03
      RTOL( xRCHO            ) = 1.0E-03
      RTOL( HCOOH            ) = 1.0E-03
      RTOL( xMGLY            ) = 1.0E-03
      RTOL( xBACL            ) = 1.0E-03
      RTOL( ROOH             ) = 1.0E-03
      RTOL( xPROD2           ) = 1.0E-03
      RTOL( R6OOH            ) = 1.0E-03
      RTOL( PRD2             ) = 1.0E-03
      RTOL( yR6OOH           ) = 1.0E-03
      RTOL( RAOOH            ) = 1.0E-03
      RTOL( MGLY             ) = 1.0E-03
      RTOL( IPRD             ) = 1.0E-03
      RTOL( xGLY             ) = 1.0E-03
      RTOL( xMEK             ) = 1.0E-03
      RTOL( xAFG1            ) = 1.0E-03
      RTOL( xAFG2            ) = 1.0E-03
      RTOL( GLY              ) = 1.0E-03
      RTOL( AFG1             ) = 1.0E-03
      RTOL( AFG2             ) = 1.0E-03
      RTOL( BACL             ) = 1.0E-03
      RTOL( BALD             ) = 1.0E-03
      RTOL( AFG3             ) = 1.0E-03
      RTOL( xIPRD            ) = 1.0E-03
      RTOL( MACR             ) = 1.0E-03
      RTOL( MVK              ) = 1.0E-03
      RTOL( xHOCCHO          ) = 1.0E-03
      RTOL( xRNO3            ) = 1.0E-03
      RTOL( HOCCHO           ) = 1.0E-03
      RTOL( xACETONE         ) = 1.0E-03
      RTOL( ACROLEIN         ) = 1.0E-03
      RTOL( xBALD            ) = 1.0E-03
      RTOL( xAFG3            ) = 1.0E-03
      RTOL( xMACR            ) = 1.0E-03
      RTOL( xMVK             ) = 1.0E-03
      RTOL( yRAOOH           ) = 1.0E-03
      RTOL( xACROLEIN        ) = 1.0E-03
      RTOL( ETHENE           ) = 1.0E-03
      RTOL( PROPENE          ) = 1.0E-03
      RTOL( BUTADIENE13      ) = 1.0E-03
      RTOL( ISOPRENE         ) = 1.0E-03
      RTOL( ISOPRXN          ) = 1.0E+00
      RTOL( APIN             ) = 1.0E-03
      RTOL( TRPRXN           ) = 1.0E+00
      RTOL( ACETYLENE        ) = 1.0E-03
      RTOL( BENZENE          ) = 1.0E-03
      RTOL( BENZRO2          ) = 1.0E-03
      RTOL( TOLUENE          ) = 1.0E-03
      RTOL( TOLRO2           ) = 1.0E-03
      RTOL( MXYL             ) = 1.0E-03
      RTOL( XYLRO2           ) = 1.0E-03
      RTOL( OXYL             ) = 1.0E-03
      RTOL( PXYL             ) = 1.0E-03
      RTOL( TRIMETH_BENZ124  ) = 1.0E-03
      RTOL( ETOH             ) = 1.0E-03
      RTOL( ALK1             ) = 1.0E-03
      RTOL( ALK2             ) = 1.0E-03
      RTOL( ALK3             ) = 1.0E-03
      RTOL( ALK4             ) = 1.0E-03
      RTOL( ALK5             ) = 1.0E-03
      RTOL( ALK5RXN          ) = 1.0E+00
      RTOL( OLE1             ) = 1.0E-03
      RTOL( OLE2             ) = 1.0E-03
      RTOL( ARO1             ) = 1.0E-03
      RTOL( ARO2             ) = 1.0E-03
      RTOL( TERP             ) = 1.0E-03
      RTOL( SESQ             ) = 1.0E-03
      RTOL( SESQRXN          ) = 1.0E+00
      RTOL( CL2              ) = 1.0E-03
      RTOL( CL               ) = 1.0E-03
      RTOL( CLNO             ) = 1.0E-03
      RTOL( CLONO            ) = 1.0E-03
      RTOL( CLNO2            ) = 1.0E-03
      RTOL( HCL              ) = 1.0E-03
      RTOL( CLO              ) = 1.0E-03
      RTOL( CLONO2           ) = 1.0E-03
      RTOL( HOCL             ) = 1.0E-03
      RTOL( xCL              ) = 1.0E-03
      RTOL( xCLCCHO          ) = 1.0E-03
      RTOL( xCLACET          ) = 1.0E-03
      RTOL( CLCCHO           ) = 1.0E-03
      RTOL( CLACET           ) = 1.0E-03
      RTOL( CLCHO            ) = 1.0E-03
      RTOL( BNZNRXN          ) = 1.0E+00
      RTOL( BNZHRXN          ) = 1.0E+00
      RTOL( XYLNRXN          ) = 1.0E+00
      RTOL( XYLHRXN          ) = 1.0E+00
      RTOL( TOLNRXN          ) = 1.0E+00
      RTOL( TOLHRXN          ) = 1.0E+00
      RTOL( HCHO_PRIMARY     ) = 1.0E-03
      RTOL( CCHO_PRIMARY     ) = 1.0E-03
      RTOL( ACROLEIN_PRIMARY ) = 1.0E-03


      RETURN

      END
