
C RCS file, release, date & time of last delta, author, state, [and locker]
C $Header: /project/work/rep/PARIO/src/pm3err.f,v 1.3 2011/03/30 18:13:03 sjr Exp $

C what(1) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%

        SUBROUTINE PM3ERR( CALLER, JDATE, JTIME, ERRTXT, FATAL )
C.....................................................................
C
C  PURPOSE:   Provides M3ERR functionality in a parallel environment.
C             The processor-id suffix is appended to the name of the
C             caller. Generate simple error messages for Models-3, and
C             terminate program execution via MPI_ABORT iff FATAL.
C
C
C  PRECONDITIONS REQUIRED:  Same as for M3EXIT.
C
C
C  REVISION  HISTORY:
C       Original version 07/1999 by Al Bourgeois to provide proper
C           program exiting in parallel environment.
C       Modified 02/23/2011 by Shawn Roselle
C          -- Replaced I/O API include files with M3UTILIO; removed
C             deprecated TRIMLEN
C
C
C  ARGUMENT LIST DESCRIPTION:
C  IN:
C     CHARACTER*(*)   CALLER       ! Name of the caller.
C     INTEGER         JDATE        ! Model date for the error.
C     INTEGER         JTIME        ! Model time for the error.
C     CHARACTER*(*)   ERRTXT       ! Error message.
C     LOGICAL         FATAL        ! Terminate program iff TRUE.
C
C     COMMON BLOCK PIOVARS:
C     INTEGER  MY_PE               !  Local processor id.
C
C  OUT: none
C
C  SUBROUTINES AND FUNCTIONS CALLS:  INIT3, SHUT3, MPI_ABORT, INQUIRE.
C
C***********************************************************************

      USE M3UTILIO              ! i/o api

      IMPLICIT NONE

C...........   INCLUDES:

      INCLUDE 'mpif.h'           ! MPI definitions and parameters.
      INCLUDE 'PIOVARS.EXT'      ! Parameters for parallel implementation.


C...........   ARGUMENTS and their descriptions:

      CHARACTER*(*)   CALLER       ! Name of the caller.
      INTEGER         JDATE        ! Model date for the error.
      INTEGER         JTIME        ! Model time for the error.
      CHARACTER*(*)   ERRTXT       ! Error message.
      LOGICAL         FATAL        ! Terminate program iff TRUE.


C...........   LOCAL VARIABLES

      INTEGER      LENSTR       ! String length of CALLER.
      INTEGER      LOGDEV       ! FORTRAN unit number for log file.
      INTEGER      IDEV         ! Loop counter over FORTRAN unit numbers.
      INTEGER      ERRCODE      ! Error code from abort attempt.
      INTEGER      IERROR       ! Error from MPI_ABORT routine.
      LOGICAL      OFLAG        ! Flag for indicating file open.
      CHARACTER*24 DTBUF        ! Scratch area for date string.
      CHARACTER*3  CMYPE        ! Processor ID string.
      CHARACTER*7  PE_STR       ! String suffix to go with processor ID.
      CHARACTER*16 CALL16       ! First 16 characters of CALLER.
      CHARACTER*26 PCALLER      ! New caller string with PE information.

C.............................................................................
C   begin subroutine PM3ERR


C.......  Construct new CALLER string.
      WRITE (PE_STR,'(A7)') ' on PE '
      WRITE(CMYPE,'(I3.3)') MY_PE


C.......  Construct new CALLER string.
      LENSTR = MIN( 16, LEN_TRIM( CALLER ) )
      CALL16 = CALLER( 1: LENSTR )
      PCALLER = CALL16(1:LENSTR)//PE_STR//CMYPE


C.......  Do M3ERR tasks.

        LOGDEV = INIT3()

        IF ( FATAL ) THEN     ! Print error messages and exit.

            WRITE( LOGDEV,91010 ) PCALLER, TRIM( ERRTXT )

            IF ( JDATE .GT. 0  .OR.  JTIME .GT. 0 ) THEN
                DTBUF = DT2STR( JDATE, JTIME )
                WRITE( LOGDEV,* ) 'PM3ERR:  DTBUF ', DTBUF
                WRITE( LOGDEV,91011 ) DTBUF, JDATE, JTIME
            ELSE
                WRITE( LOGDEV,* )  'PM3ERR:  date&time specified as 0'
                WRITE( LOGDEV,91012 ) 'Date&time specified as 0'
            END IF

            IF ( .NOT. SHUT3() ) THEN
                WRITE( LOGDEV,91000 )
     &              'Could not shut down I/ O API files correctly',
     &              ' ', ' '
            END IF

            DO  11  IDEV = 10, 99
                INQUIRE( UNIT = IDEV, OPENED = OFLAG )
                IF ( OFLAG ) CLOSE( IDEV )
11          CONTINUE


C.......  Abort all parallel tasks.
          CALL MPI_ABORT( MPI_COMM_WORLD, ERRCODE, IERROR )



        ELSE    !  Print error message but do not exit.


            WRITE( LOGDEV,91020 ) PCALLER, TRIM( ERRTXT )

            IF ( JDATE .GT. 0  .OR.  JTIME .GT. 0 )  THEN
                WRITE( LOGDEV,91011 )
     &             DT2STR( JDATE, JTIME ), JDATE, JTIME
            END IF

            RETURN


        END IF

C******************  FORMAT  STATEMENTS   ******************************

C...........   Error and warning message formats..... 91xxx

91000   FORMAT ( //5X , '*** ERROR ABORT in subroutine PM3ERR ***',
     &            /5X , A , // )

91010   FORMAT ( //5X , '*** ERROR ABORT in subroutine ', A,
     &            /5X , A )

91011   FORMAT ( 5X , 'Date and time ', A, :,
     &                  ' (', I7, ':', I6.6, ')' )

91012   FORMAT ( 5X , A )

91020   FORMAT (  /5X , '>>--->> WARNING in subroutine ', A,
     &            /5X , A )

        END


