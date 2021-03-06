
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
C $Header: /project/yoj/arc/PROCAN/src/driver/pa/pa_wrtdatext.F,v 1.7 2011/11/02 14:34:00 yoj Exp $

      SUBROUTINE PA_WRTDATEXT

C***********************************************************************
 
C Function: To write the Models-3 Process Analysis Include file 
C           containing data statements 
 
C Preconditions: Requires mechanism to have been processed
  
C Key Subroutines/Functions Called: None
 
C Revision History:
C  Prototype created by Jerry Gipson, August, 1996
C  Modified by Jerry Gipson April, 1997 to add ADJC process and to add
C  species = all for proc outputs
C  Modified May, 1997 by Jerry Gipson to be consistent with beta CTM
C  Modified Sept, 1997 by Jerry Gipson to be consistent with targeted CTM
C  Aug 2011 Jeff Young: Replaced I/O API include files with IOAPI's M3UTILIO
C                       replaced TRIMLEN with LEN_TRIM
 
C***********************************************************************
      USE M3UTILIO      ! IOAPI module

      IMPLICIT NONE
      
C Includes:
      INCLUDE 'PA_IPRDEF.EXT'
      INCLUDE 'PA_GLOBAL.EXT'
      INCLUDE 'PA_PARSE.EXT'
      INCLUDE 'PA_VARS.EXT'
      INCLUDE 'PA_INCDATA.EXT'
      
C Arguments: None
                                        
C Parameters: None

C External Functions: None

C Local Variables:

      CHARACTER(  1 ) :: DOT = '.'  ! Dot character
      CHARACTER( 80 ) :: DELIM      ! Delimiter line output
      CHARACTER( 80 ) :: CEES
      CHARACTER( 78 ) :: LINOUT     ! Output line
      CHARACTER(  7 ) :: BUF6 ( MAXIPROUT )  ! 6-Character buffer
      CHARACTER( 13 ) :: BUF12( MAXIPROUT )  ! 12-Character buffer
      CHARACTER( 21 ) :: BUF20( MAXIPROUT )  ! 20-Character buffer

      INTEGER IEND            ! Position of last non-blank character
      INTEGER IOUT            ! Unit number for include file
      INTEGER :: LINLEN = 78  ! Length of output line
      INTEGER :: MAXCNT = 99  ! Maximum number of continuation lines
      INTEGER N               ! Loop index
      INTEGER NHI             ! Highest index of loop
      INTEGER NIRR            ! IRR loop index
      INTEGER NLO             ! Lowest index of loop
      INTEGER NPA             ! IPR species loop index
      INTEGER NS              ! Loop index for sets of data statments
      INTEGER NSETS           ! Number of sets of data statements to write

      LOGICAL LIPR            ! Flag for process monitoring
      LOGICAL LIRR            ! Flag for IRR computations
         
C***********************************************************************

      DO N = 1, 78
         DELIM( N:N ) = DOT
         CEES( N:N ) = 'c'
      END DO     
      DELIM( 1:1 ) = 'C'

      IF ( LFULLIRR ) THEN
         LIRR    = .TRUE.
         NIRRVAR = NRXNS
      ELSE IF ( LPARTIRR ) THEN
         LIRR    = .TRUE.
         NIRRVAR = NIRROUT
      ELSE
         LIRR = .FALSE.     
      END IF

      IF ( N_IPR_SPC .GT. 0 ) THEN
         LIPR = .TRUE.
      ELSE
         LIPR = .FALSE.
      END IF

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Open DAT Include file and write the header data
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IOUT = JUNIT( )
      OPEN( UNIT = IOUT,  FILE = 'PA_DAT.EXT' )
      WRITE( IOUT, 94000 ) DELIM( 1:72 )
      LINOUT = 'C    INCLUDE FILE   PA_DAT.EXT'
      WRITE( IOUT, 94000 ) LINOUT
      WRITE( IOUT, 94000 ) LINOUT( 1:1 )
      LINOUT = 'C    CONTAINS: Data statements for Process Analysis'
      WRITE( IOUT, 94000 ) LINOUT
      WRITE( IOUT, 94000 ) LINOUT( 1:1 )
      LINOUT = 'C    DEPENDENT UPON: Process Analysis COMMON Include '
      IEND = LEN_TRIM( LINOUT )
      LINOUT = LINOUT( 1:IEND ) // 'File'
      WRITE( IOUT, 94000 ) LINOUT
      WRITE( IOUT, 94000 ) LINOUT( 1:1 )
      LINOUT = 'C    CREATED BY: Process Analysis Control Program'
      WRITE( IOUT, 94000 ) LINOUT
      LINOUT = 'C                ' // TDATOUT
      WRITE( IOUT, 94000 ) LINOUT
      WRITE( IOUT, 94000 ) LINOUT( 1:1 )
      WRITE( IOUT, 94000 ) DELIM( 1:72 )
      LINOUT = ''
      WRITE( IOUT, 94000 ) LINOUT

      IF ( .NOT. LIPR .AND. .NOT. LIRR ) THEN
         WRITE( IOUT,  94110 )
         GO TO 999
      END IF         

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Write data statements for output file variables
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      WRITE( IOUT, 94000 ) CEES( 1:72 )
      WRITE( IOUT, 94120 ) 
      WRITE( IOUT, 94000 ) CEES( 1:72 )
      WRITE( IOUT, 94200 ) 
 
      IF ( NIPRVAR .GT. 0 ) THEN
         NSETS = ( ( NIPRVAR - 1 ) / ( 3 * MAXCNT ) ) + 1
         DO NS = 1, NSETS
            NLO = ( NS - 1 ) * ( 3 * MAXCNT ) + 1
            NHI = MIN( ( NS * 3 * MAXCNT ), NIPRVAR )
            WRITE( IOUT, 94220 ) NLO,  NHI
            DO NPA = NLO, NHI
               BUF20( NPA ) = ' ''' // IPRNAME( NPA ) // ''','
            END DO
            BUF20( NHI )( 20:21 ) = ' /'
            WRITE( IOUT, 94020 ) ( BUF20( NPA ), NPA = NLO, NHI )
         END DO

         NSETS = ( ( NIPRVAR - 1 ) / MAXCNT ) + 1
         DO NS = 1, NSETS
            NLO = ( NS - 1 ) * ( MAXCNT ) + 1
            NHI = MIN( ( NS * MAXCNT ), NIPRVAR )         
            WRITE( IOUT, 94240 ) NLO,  NHI
            DO NPA = NLO, NHI
               LINOUT = '     &  ''' // IPRDESC( NPA ) // ''','
               IF ( NPA .EQ. NHI ) LINOUT( 71:71 ) = '/'
               WRITE( IOUT, 94000 ) LINOUT            
            END DO
         END DO
      END IF

      IF ( NIRRVAR .GT. 0 ) THEN
         NSETS = ( ( NIRRVAR - 1 ) / ( 3 * MAXCNT ) ) + 1
         DO NS = 1, NSETS
            NLO = ( NS - 1 ) * ( 3 * MAXCNT ) + 1
            NHI = MIN( ( NS * 3 * MAXCNT ),  NIRRVAR )
            WRITE( IOUT, 94260 ) NLO, NHI
            DO NIRR = NLO,  NHI
               BUF20( NIRR ) = ' ''' // IRRNAME( NIRR ) // ''','
            END DO
            BUF20( NHI )( 20:21 ) = ' /'
            WRITE( IOUT, 94020 ) ( BUF20( NIRR ), NIRR = NLO, NHI )
         END DO

         NSETS = ( ( NIRRVAR - 1 ) / MAXCNT ) + 1
         DO NS = 1, NSETS
            NLO = ( NS - 1 ) * ( MAXCNT ) + 1
            NHI = MIN( ( NS * MAXCNT ), NIRRVAR )         
            WRITE( IOUT, 94280 ) NLO,  NHI
            DO NIRR = NLO, NHI
               LINOUT = '     &  ''' // IRRDESC( NIRR ) // ''','
               IF ( NIRR .EQ. NHI ) LINOUT( 71:71 ) = '/'
               WRITE( IOUT, 94000 ) LINOUT            
            END DO
         END DO
      END IF

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Write data statements for integrated Process rate variables
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IF ( LIPR ) THEN
         WRITE( IOUT, 94000 )
         WRITE( IOUT, 94000 )
         WRITE( IOUT, 94000 ) CEES( 1:72 )
         WRITE( IOUT, 94140 ) 
         WRITE( IOUT, 94000 ) CEES( 1:72 )

         NSETS = ( ( NPROCS - 1 ) / ( 3 * MAXCNT ) ) + 1
         DO NS = 1,  NSETS
            NLO = ( NS - 1 ) * ( 3 * MAXCNT ) + 1
            NHI = MIN( ( NS * 3 * MAXCNT ),  NPROCS )         
            WRITE( IOUT, 94290 ) NLO, NHI
            DO NPA = NLO, NHI
               BUF20( NPA ) = ' ''' // PROCNAME( NPA ) // ''',' 
            END DO
            BUF20( NHI )( 20:21 ) = ' /'
            WRITE( IOUT, 94020 ) ( BUF20( NPA ), NPA = NLO, NHI )
         END DO
      END IF

      IF ( N_IPR_SPC .GT. 0 ) THEN
         NSETS = ( ( N_IPR_SPC - 1 ) / ( 10 * MAXCNT ) ) + 1
         DO NS = 1, NSETS
            NLO = ( NS - 1 ) * ( 10 * MAXCNT ) + 1
            NHI = MIN( ( NS * 10 * MAXCNT ), N_IPR_SPC )         
            WRITE( IOUT, 94300 ) NLO, NHI
            DO NPA = NLO,  NHI
               WRITE( BUF6( NPA ), '( I5, '','' )' ) NCGRID( NPA )
            END DO
            BUF6( NHI )( 6:7 ) = ' /'
            WRITE( IOUT, 94040 ) ( BUF6( NPA ), NPA = NLO, NHI )
         END DO
      END IF

      IF ( NCSAVE .GT. 0 ) THEN
         NSETS = ( ( NCSAVE - 1 ) / ( 10 * MAXCNT ) ) + 1
         DO NS = 1, NSETS
            NLO = ( NS - 1 ) * ( 10 * MAXCNT ) + 1
            NHI = MIN( ( NS * 10 * MAXCNT ), NCSAVE )         
            WRITE( IOUT, 94320 ) NLO, NHI
            DO NPA = NLO,  NHI
               WRITE( BUF6( NPA ), 94080 ) SV2GRD( NPA )
            END DO
            BUF6( NHI )( 6:7 ) = ' /'
            WRITE( IOUT, 94040 ) ( BUF6( NPA ), NPA = NLO, NHI )
         END DO
      END IF

      IF ( N_IPR_SPC .GT. 0 ) THEN
         DO NPA = 1, N_IPR_SPC
            NSETS = ( ( NPROCS - 1 ) / ( 10 * MAXCNT ) ) + 1
            DO NS = 1, NSETS
               NLO = ( NS - 1 ) * ( 10 * MAXCNT ) + 1
               NHI = MIN( ( NS * 10 * MAXCNT ), NPROCS )         
               WRITE( IOUT, 94340 ) NPA, NLO, NHI
               DO N = NLO,  NHI
                  WRITE( BUF6( N ), 94080 ) IPROUT( NPA, N )
               END DO
               BUF6( NHI )( 6:7 ) = ' /'
               WRITE( IOUT, 94040 ) ( BUF6( N ), N = NLO, NHI )
            END DO 
         END DO
      END IF 

      IF ( N_IPR_SPC .GT. 0 ) THEN
         DO NPA = 1, N_IPR_SPC
            NSETS = ( ( NCGRID( NPA ) - 1 ) / ( 10 * MAXCNT ) ) + 1
            DO NS = 1, NSETS
               NLO = ( NS - 1 ) * ( 10 * MAXCNT ) + 1
               NHI = MIN( ( NS * 10 * MAXCNT ),  NCGRID( NPA ) )         
               WRITE( IOUT, 94360 ) NPA, NLO, NHI
               DO N = NLO, NHI
                  WRITE( BUF6( N ), 94080 ) IPR2GRD( NPA, N )
               END DO
               BUF6( NHI )( 6:7 ) = ' /'
               WRITE( IOUT, 94040 ) ( BUF6( N ), N = NLO, NHI )
            END DO 
         END DO
      END IF

      IF ( N_IPR_SPC .GT. 0 ) THEN
         DO NPA = 1, N_IPR_SPC
            NSETS = ( ( NCGRID( NPA ) - 1 ) / ( 10 * MAXCNT ) ) + 1
            DO NS = 1, NSETS
               NLO = ( NS - 1 ) * ( 10 * MAXCNT ) + 1
               NHI = MIN( ( NS * 10 * MAXCNT ), NCGRID( NPA ) )         
               WRITE( IOUT, 94380 ) NPA,  NLO,  NHI
               DO N = NLO, NHI
                  WRITE( BUF6( N ), 94080 ) IPR2SAV( NPA, N )
               END DO
               BUF6( NHI )( 6:7 ) = ' /'
               WRITE( IOUT, 94040 ) ( BUF6( N ), N = NLO, NHI )
            END DO 
         END DO
      END IF

      IF ( LIPR ) THEN
         NSETS = ( ( NPROCS - 1 ) / ( 5 * MAXCNT ) ) + 1
         DO NS = 1,  NSETS
            NLO = ( NS - 1 ) * ( 5 * MAXCNT ) + 1
            NHI = MIN( ( NS * 5 * MAXCNT ), NPROCS )         
            WRITE( IOUT, 94400 ) NLO,  NHI
            DO N = NLO, NHI
               IF ( LPROCOUT( N ) ) THEN
                  BUF12( N ) = '     .TRUE., '
               ELSE
                  BUF12( N ) = '    .FALSE., '
               END IF
            END DO
            BUF12( NHI )( 12:13 ) = ' /'  
            WRITE( IOUT, 94060 ) ( BUF12( N ), N = NLO, NHI )
         END DO
      END IF

      IF ( N_IPR_SPC .GT. 0 ) THEN
         DO NPA = 1, N_IPR_SPC
            NSETS = ( ( NCGRID( NPA ) - 1 ) / ( 5 * MAXCNT ) ) + 1
            DO NS = 1, NSETS
               NLO = ( NS - 1 ) * ( 5 * MAXCNT ) + 1
               NHI = MIN( ( NS * 5 * MAXCNT ), NCGRID( NPA ) )         
               WRITE( IOUT, 94420 ) NPA, NLO, NHI
               DO N = 1,  NCGRID( NPA )
                  WRITE( BUF12( N ), 94100 ) SPCOEF( NPA,  N )
               END DO
               BUF12( NHI )( 12:13 ) = ' /'
               WRITE( IOUT, 94060 ) ( BUF12( N ), N = NLO, NHI )
            END DO 
         END DO
      END IF

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Write data statements for IRR variables
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IF ( LPARTIRR ) THEN
         WRITE( IOUT, 94000 )
         WRITE( IOUT, 94000 )
         WRITE( IOUT, 94000 ) CEES( 1:72 )
         WRITE( IOUT, 94160 ) 
         WRITE( IOUT, 94000 ) CEES( 1:72 )

         IF ( NIRRVAR .GT. 0 ) THEN
            NSETS = ( ( NIRRVAR - 1 ) / ( 10 * MAXCNT ) ) + 1
            DO NS = 1, NSETS
               NLO = ( NS - 1 ) * ( 10 * MAXCNT ) + 1
               NHI = MIN( ( NS * 10 * MAXCNT ), NIRRVAR )         
               WRITE( IOUT, 94440 ) NLO, NHI
               DO NIRR = NLO, NHI
                  WRITE( BUF6( NIRR ), '( I5, '','' )' ) 
     &                                 NIRRRXNS( NIRR )
               END DO
               BUF6( NHI )( 6:7 ) = ' /'
               WRITE( IOUT, 94040 ) ( BUF6( NIRR ), NIRR = NLO, NHI )
            END DO
         END IF     

         IF ( NUMTEMPS .GT. 0 ) THEN
            NSETS = ( ( NUMTEMPS - 1 ) / ( 10 * MAXCNT ) ) + 1
            DO NS = 1, NSETS
               NLO = ( NS - 1 ) * ( 10 * MAXCNT ) + 1
               NHI = MIN( ( NS * 10 * MAXCNT ),  NUMTEMPS )         
               WRITE( IOUT, 94460 ) NLO, NHI
               DO NIRR = NLO, NHI
                  WRITE( BUF6( NIRR ), '( I5, '','' )' )
     &                                 TEMPTERMS( NIRR )
               END DO
               BUF6( NHI )( 6:7 ) = ' /'
               WRITE( IOUT, 94040 ) ( BUF6( NIRR ), NIRR = NLO, NHI )
            END DO
         END IF     
 
         IF ( NUMOUTPOS .GT. 0 ) THEN
            NSETS = ( ( NUMOUTPOS - 1 ) / ( 10 * MAXCNT ) ) + 1
            DO NS = 1, NSETS
               NLO = ( NS - 1 ) * ( 10 * MAXCNT ) + 1
               NHI = MIN(  ( NS * 10 * MAXCNT ),  NUMOUTPOS )         
               WRITE( IOUT, 94480 ) NLO, NHI
               DO NIRR = NLO, NHI
                  WRITE( BUF6( NIRR ), '( I5, '','' )' )
     &                                 TEMPOUTPOS( NIRR )
               END DO
               BUF6( NHI )( 6:7 ) = ' /'
               WRITE( IOUT, 94040 ) ( BUF6( NIRR ), NIRR = NLO, NHI )
            END DO
         END IF 
             
         IF ( NUMOUTNEG .GT. 0 ) THEN
            NSETS = ( ( NUMOUTNEG - 1 ) / ( 10 * MAXCNT ) ) + 1
            DO NS = 1, NSETS
               NLO = ( NS - 1 ) * ( 10 * MAXCNT ) + 1
               NHI = MIN( ( NS * 10 * MAXCNT ),  NUMOUTNEG )         
               WRITE( IOUT, 94500 ) NLO,  NHI
               DO NIRR = NLO, NHI
                  WRITE( BUF6( NIRR ), '( I5, '','' )' ) 
     &                                 TEMPOUTNEG( NIRR )
               END DO
               BUF6( NHI )( 6:7 ) = ' /'
               WRITE( IOUT, 94040 ) ( BUF6( NIRR ), NIRR = NLO, NHI )
            END DO
         END IF 

         IF ( NUMOUTIND .GT. 0 ) THEN
            NSETS = ( ( NUMOUTIND - 1 ) / ( 10 * MAXCNT ) ) + 1
            DO NS = 1, NSETS
               NLO = ( NS - 1 ) * ( 10 * MAXCNT ) + 1
               NHI = MIN( ( NS * 10 * MAXCNT ), NUMOUTIND )         
               WRITE( IOUT, 94520 ) NLO, NHI
               DO NIRR = NLO, NHI
                  WRITE( BUF6( NIRR ), '( I5, '','' )' ) 
     &                                 TEMPOUTIND( NIRR )
              END DO
               BUF6( NHI )( 6:7 ) = ' /'
               WRITE( IOUT, 94040 ) ( BUF6( NIRR ), NIRR = NLO, NHI )
            END DO
         END IF 

         IF ( NUMOUTPOS .GT. 0 ) THEN
            NSETS = ( ( NUMOUTPOS - 1 ) / ( 10 * MAXCNT ) ) + 1
            DO NS = 1, NSETS
               NLO = ( NS - 1 ) * ( 10 * MAXCNT ) + 1
               NHI = MIN( ( NS * 10 * MAXCNT ), NUMOUTPOS )         
               WRITE( IOUT, 94540 ) NLO, NHI
               DO NIRR = NLO, NHI
                  WRITE( BUF6( NIRR ), '( I5, '','' )' )
     &                                 INDXOUTPOS( NIRR )
               END DO
               BUF6( NHI )( 6:7 ) = ' /'
               WRITE( IOUT, 94040 ) ( BUF6( NIRR ), NIRR = NLO, NHI )
            END DO
         END IF 

         IF ( NUMOUTNEG .GT. 0 ) THEN
            NSETS = ( ( NUMOUTNEG - 1 ) / ( 10 * MAXCNT ) ) + 1
            DO NS = 1, NSETS
               NLO = ( NS - 1 ) * ( 10 * MAXCNT ) + 1
               NHI = MIN( ( NS * 10 * MAXCNT ), NUMOUTNEG )       
               WRITE( IOUT, 94560 ) NLO, NHI
               DO NIRR = NLO, NHI
                  WRITE( BUF6( NIRR ), '( I5, '','' )' ) 
     &                                 INDXOUTNEG( NIRR )
              END DO
               BUF6( NHI )( 6:7 ) = ' /'
               WRITE( IOUT, 94040 ) ( BUF6( NIRR ), NIRR = NLO, NHI )
            END DO
         END IF 

         IF ( NUMOUTIND .GT. 0 ) THEN
            NSETS = ( ( NUMOUTIND - 1 ) / ( 10 * MAXCNT ) ) + 1
            DO NS = 1, NSETS
               NLO = ( NS - 1 ) * ( 10 * MAXCNT ) + 1
               NHI = MIN( ( NS * 10 * MAXCNT ), NUMOUTIND )       
               WRITE( IOUT, 94580 ) NLO, NHI
               DO NIRR = NLO, NHI
                  WRITE( BUF6( NIRR ), '( I5, '','' )' )
     &                                 INDXOUTIND( NIRR )
               END DO
               BUF6( NHI )( 6:7 ) = ' /'
               WRITE( IOUT, 94040 ) ( BUF6( NIRR ), NIRR = NLO, NHI )
            END DO
         END IF

         IF ( NIRRVAR .GT. 0 ) THEN
            DO NIRR = 1, NIRRVAR
               IF ( NIRRRXNS( NIRR ) .GT. 0 ) THEN
                  NSETS = ( ( NIRRRXNS( NIRR ) - 1 ) / ( 10 * MAXCNT ) ) + 1
                  DO NS = 1,  NSETS
                     NLO = ( NS - 1 ) * ( 10 * MAXCNT ) + 1
                     NHI = MIN( ( NS * 10 * MAXCNT ), NIRRRXNS( NIRR ) )         
                     WRITE( IOUT, 94600 ) NIRR, NLO, NHI
                     DO N = NLO, NHI
                        WRITE( BUF6( N ), 94080 ) IRRRXN( NIRR, N )
                     END DO
                     BUF6( NHI )( 6:7 ) = ' /'
                     WRITE( IOUT, 94040 ) ( BUF6( N ), N = NLO, NHI )
                  END DO
               END IF 
            END DO
         END IF

         IF ( NUMTEMPS .GT. 0 ) THEN
            DO NIRR= 1, NUMTEMPS
               IF ( TEMPTERMS( NIRR ) .GT. 0 ) THEN
                  NSETS = ( ( TEMPTERMS( NIRR ) - 1 ) / ( 10 * MAXCNT ) ) + 1
                  DO NS = 1, NSETS
                     NLO = ( NS - 1 ) * ( 10 * MAXCNT ) + 1
                     NHI = MIN( ( NS * 10 * MAXCNT ), TEMPTERMS( NIRR ) )         
                     WRITE( IOUT, 94620 ) NIRR,  NLO,  NHI
                     DO N = NLO, NHI
                        WRITE( BUF6( N ), 94080 ) TEMPRXN( NIRR, N )
                     END DO
                     BUF6( NHI )( 6:7 ) = ' /'
                     WRITE( IOUT, 94040 ) ( BUF6( N ), N = NLO,  NHI ) 
                  END DO
               END IF
            END DO
         END IF

         IF ( NUMOUTPOS .GT. 0 ) THEN
            NSETS = ( ( NUMOUTPOS - 1 ) / ( 5 * MAXCNT ) ) + 1
            DO NS = 1, NSETS
               NLO = ( NS - 1 ) * ( 5 * MAXCNT ) + 1
               NHI = MIN( ( NS * 5 * MAXCNT ), NUMOUTPOS )         
               WRITE( IOUT, 94640 ) NLO, NHI
               DO NIRR = NLO, NHI
                  WRITE( BUF12( NIRR ), 94100 ) COEFOUTPOS( NIRR )
               END DO
               BUF12( NHI )( 12:13 ) = ' /'
               WRITE( IOUT, 94060 ) ( BUF12( NIRR ), NIRR = NLO, NHI )
            END DO
         END IF

         IF ( NUMOUTNEG .GT. 0 ) THEN
            NSETS = ( ( NUMOUTNEG - 1 ) / ( 5 * MAXCNT ) ) + 1
            DO NS = 1, NSETS
               NLO = ( NS - 1 ) * ( 5 * MAXCNT ) + 1
               NHI = MIN( ( NS * 5 * MAXCNT ), NUMOUTNEG )         
               WRITE( IOUT, 94660 ) NLO,  NHI
               DO NIRR = NLO, NHI
                  WRITE( BUF12( NIRR ), 94100 ) COEFOUTNEG( NIRR )
               END DO
               BUF12( NHI )( 12:13 ) = ' /'
               WRITE( IOUT, 94060 ) ( BUF12( NIRR ), NIRR = NLO, NHI )
            END DO
         END IF

         IF ( NUMOUTIND .GT. 0 ) THEN
            NSETS = ( ( NUMOUTIND - 1 ) / ( 5 * MAXCNT ) ) + 1
            DO NS = 1, NSETS
               NLO = ( NS - 1 ) * ( 5 * MAXCNT ) + 1
               NHI = MIN( ( NS * 5 * MAXCNT ), NUMOUTIND )         
               WRITE( IOUT, 94680 ) NLO,  NHI
               DO NIRR = NLO, NHI
                 WRITE( BUF12( NIRR ), 94100 ) COEFOUTIND( NIRR )
               END DO
               BUF12( NHI )( 12:13 ) = ' /'
               WRITE( IOUT, 94060 ) ( BUF12( NIRR ), NIRR = NLO, NHI )
            END DO
         END IF

         IF ( NUMTEMPS .GT. 0 ) THEN
            DO NIRR= 1, NUMTEMPS
               IF ( TEMPTERMS( NIRR ) .GT. 0 ) THEN
                  NSETS = ( ( TEMPTERMS( NIRR ) - 1 ) / ( 5 * MAXCNT ) ) + 1
                  DO NS = 1, NSETS
                     NLO = ( NS - 1 ) * ( 5 * MAXCNT ) + 1
                     NHI = MIN(  ( NS * 5 * MAXCNT ), TEMPTERMS( NIRR ) )         
                     WRITE( IOUT, 94700 ) NIRR, NLO, NHI
                     DO N = NLO, NHI
                        WRITE( BUF12( N ), 94100 ) TEMPCOEF( NIRR, N )
                     END DO
                     BUF12( NHI )( 12:13 ) = ' /'
                     WRITE( IOUT, 94060 ) ( BUF12( N ), N = NLO, NHI )
                 END DO
               END IF 
            END DO
         END IF

         IF ( NIRRVAR .GT. 0 ) THEN
            DO NIRR = 1, NIRRVAR
               IF ( NIRRRXNS( NIRR ) .GT. 0 ) THEN
                  NSETS = ( ( NIRRRXNS( NIRR ) - 1 ) / ( 5 * MAXCNT ) ) + 1
                  DO NS = 1, NSETS
                     NLO = ( NS - 1 ) * ( 5 * MAXCNT ) + 1
                     NHI = MIN( ( NS * 5 * MAXCNT ), NIRRRXNS( NIRR ) )         
                     WRITE( IOUT, 94720 ) NIRR,  NLO,  NHI
                     DO N = NLO, NHI
                        WRITE( BUF12( N ), 94100 ) IRRCOEF( NIRR, N )
                     END DO
                     BUF12( NHI )( 12:13 ) = ' /'
                     WRITE( IOUT, 94060 ) ( BUF12( N ), N = NLO, NHI )
                  END DO
               END IF 
            END DO
         END IF
      END IF

  999 CONTINUE

      WRITE( IOUT, 94000 )
      WRITE( IOUT, 94000 )
      WRITE( IOUT, 94000 )
      LINOUT = DELIM
      LINOUT( 14:58 ) = ' End of Process Analysis DATA Include File '
      WRITE( IOUT, 94000 ) LINOUT
      CLOSE( IOUT )

      RETURN 
     
C*********************** FORMAT Statements *****************************

94000 FORMAT( A )
94020 FORMAT( 5X, '&  ', 3A21 )
94040 FORMAT( 5X, '&  ', 10A7 )
94060 FORMAT( 5X, '&  ', 5A13 )
94080 FORMAT( I5, ',' )
94100 FORMAT( F11.4, ',' )
94110 FORMAT( 'c  Neither IPR nor IRR calculations are being done.' /
     &        'c  Additional data are not required' )
94120 FORMAT( 'c  Output file descriptor data' )
94140 FORMAT( 'c  IPR data' )
94160 FORMAT( 'c  IRR data' )
94200 FORMAT( /6X, 'INTEGER TERM' )
94220 FORMAT( /6X, 'DATA ( IPRNAME( TERM ), TERM =', I4, ', ', I4, ' ) /' )
94240 FORMAT( /6X, 'DATA ( IPRDESC( TERM ), TERM =', I4, ', ', I4, ' ) /' )
94260 FORMAT( /6X, 'DATA ( IRRNAME( TERM ), TERM =', I4, ', ', I4, ' ) /' )
94280 FORMAT( /6X, 'DATA ( IRRDESC( TERM ), TERM =', I4, ', ', I4, ' ) /' )
94290 FORMAT( /6X, 'DATA ( PROCNAME( TERM ), TERM =', I4, ', ', I4, ' ) /' )
94300 FORMAT( /6X, 'DATA ( NCGRID( TERM ), TERM =', I4, ', ', I4, ' ) /' )
94320 FORMAT( /6X, 'DATA ( SV2GRD( TERM ), TERM =', I4, ', ', I4, ' ) /' )
94340 FORMAT( /6X, 'DATA ( IPROUT( ', I3, ', TERM ), TERM =', I4, ', ', I4, ' ) /' )
94360 FORMAT( /6X, 'DATA ( IPR2GRD( ', I3, ', TERM ), TERM =', I4, ', ', I4, ' ) /' )
94380 FORMAT( /6X, 'DATA ( IPR2SAV( ', I3, ', TERM ), TERM =', I4, ', ', I4, ' ) /' )
94400 FORMAT( /6X, 'DATA ( LPROCOUT( TERM ), TERM =', I4, ', ', I4, ' ) /' )
94420 FORMAT( /6X, 'DATA ( SPCOEF( ', I3, ', TERM ), TERM =', I4, ', ', I4, ' ) /' )
94440 FORMAT( /6X, 'DATA ( NIRRRXNS( TERM ), TERM =', I4, ', ', I4, ' ) /' )
94460 FORMAT( /6X, 'DATA ( TEMPTERMS( TERM ), TERM =', I4, ', ', I4, ' ) /' )
94480 FORMAT( /6X, 'DATA ( TEMPOUTPOS( TERM ), TERM =', I4, ', ', I4, ' ) /' )
94500 FORMAT( /6X, 'DATA ( TEMPOUTNEG( TERM ), TERM =', I4, ', ', I4, ' ) /' )
94520 FORMAT( /6X, 'DATA ( TEMPOUTIND( TERM ), TERM =', I4, ', ', I4, ' ) /' )
94540 FORMAT( /6X, 'DATA ( INDXOUTPOS( TERM ), TERM =', I4, ', ', I4, ' ) /' )
94560 FORMAT( /6X, 'DATA ( INDXOUTNEG( TERM ), TERM =', I4, ', ', I4, ' ) /' )
94580 FORMAT( /6X, 'DATA ( INDXOUTIND( TERM ), TERM =', I4, ', ', I4, ' ) /' )
94600 FORMAT( /6X, 'DATA ( IRRRXN( ', I3, ', TERM ), TERM =', I4, ', ', I4, ' ) /' )
94620 FORMAT( /6X, 'DATA ( TEMPRXN( ', I3, ', TERM ), TERM =', I4, ', ', I4, ' ) /' )
94640 FORMAT( /6X, 'DATA ( COEFOUTPOS( TERM ), TERM =', I4, ', ', I4, ' ) /' )
94660 FORMAT( /6X, 'DATA ( COEFOUTNEG( TERM ), TERM =', I4, ', ', I4, ' ) /' )
94680 FORMAT( /6X, 'DATA ( COEFOUTIND( TERM ), TERM =', I4, ', ', I4, ' ) /' )
94700 FORMAT( /6X, 'DATA ( TEMPCOEF( ', I3, ', TERM ), TERM =', I4, ', ', I4, ' ) /' )
94720 FORMAT( /6X, 'DATA ( IRRCOEF( ', I3, ', TERM ), TERM =', I4, ', ', I4, ' ) /' )
      END
