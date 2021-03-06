
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
C $Header: /project/yoj/arc/PROCAN/src/driver/pa/pa_rdline.F,v 1.5 2011/11/02 14:33:59 yoj Exp $

      SUBROUTINE RDLINE

C***********************************************************************
 
C Function: RDLINE reads one line from a file and stores it in INBUF.
C           The position of the last non-blank character is stored
C           in IEOL. All blank lines and lines with a ! in the first
C           column are skipped. The line count is stored in LINNUM.
 
C Preconditions: None
  
C Key Subroutines/Functions Called: None
 
C Revision History:
C  Prototype created by Jerry Gipson, August, 1996
C  Modified May, 1997 by Jerry Gipson to be consistent with beta CTM
C  Modified Sept, 1997 by Jerry Gipson to be consistent with targeted CTM
C  Aug 2011 Jeff Young: Replaced I/O API include files with IOAPI's M3UTILIO
 
C***********************************************************************
      USE M3UTILIO      ! IOAPI module

      IMPLICIT NONE
      
C Includes:
      INCLUDE 'PA_PARSE.EXT' 
      
C Arguments: None
                                        
C Parameters: None

C External Functions: None

C Local Variables: None
         
C***********************************************************************
         
c..Read the first non-comment line and find the last non-blank character
c..in that line
20    CONTINUE
      READ( IFILE, '( A )', END = 999 ) INBUF
      LINNUM = LINNUM + 1
      IF ( INBUF( 1:1 ) .EQ. '!' ) THEN
         GO TO 20
      ELSE
         IEOL = LEN_TRIM( INBUF )
         IF ( IEOL .EQ. 1 .AND. INBUF( 1:1 ) .EQ. ' ' ) THEN 
            GO TO 20
         ELSE
            LPOINT = 0
            RETURN
         END IF
      END IF
999   CONTINUE

c..eof file encountered -- exit program
      WRITE( MSG, 94000 ) 
      CALL M3MESG( MSG )
      WRITE( MSG, 94020 )
      CALL M3MESG( MSG )
      CALL M3EXIT( 'RDLINE', IZERO, IZERO, ' ', XSTAT2 )
      
C*********************** FORMAT Statements *****************************      
      
94000 FORMAT( 'ERROR: End of file reached on the Process Analysis',
     &               ' command file' )
94020 FORMAT( '       ENDPA must be the last command' )       

      END

