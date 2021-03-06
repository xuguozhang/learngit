
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
C $Header: /project/yoj/arc/PROCAN/src/driver/pa/pa_getlabel.F,v 1.5 2011/11/02 14:33:57 yoj Exp $

      SUBROUTINE GETLABEL

C***********************************************************************
 
C Function: GETLABEL gets all characters except blanks between the
C           delimiters <> or []. Line wrap is allowed. The maximum
C           label length is sixteen characters.
             
C Preconditions: None
  
C Key Subroutines/Functions Called: EATCOM
C                                   GETCHR
 
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

C Local Variables:
      CHARACTER( 1 ) :: BEGCHR   ! Starting delimiter for label
      CHARACTER( 1 ) :: ENDCHR   ! Ending delimiter for label

      INTEGER LENGTH    ! Length of label
         
C***********************************************************************

c..Set beginning and and ending characters delineating the label
      LABEL  = ''
      LENGTH = 0
      IF ( CHR .EQ. '<' ) THEN
         BEGCHR = '<'
         ENDCHR = '>'
      ELSE
         BEGCHR = '['
         ENDCHR = ']'
      END IF
 
c..top of loop for getting next character
20    CONTINUE
      CALL GETCHR

c..if the end of the label has not been reached, store the character
      IF ( CHR .NE. ENDCHR ) THEN
         IF ( CHR .EQ. '(' .OR. CHR .EQ. '{' ) CALL EATCOM
         LENGTH = LENGTH + 1 
         IF ( LENGTH .GT. 16 ) THEN
            WRITE( MSG, 94000 ) 
            CALL M3MESG( MSG )
            WRITE( MSG, 94020 ) LINNUM, INBUF
            CALL M3MESG( MSG )
            WRITE( MSG, 94040 ) BEGCHR, LABEL
            CALL M3MESG( MSG )
            CALL M3EXIT( 'PA_GETLABEL', IZERO, IZERO, ' ', XSTAT2 )
         END IF
         LABEL( LENGTH : LENGTH ) = CHR
         GO TO 20
      END IF

      CALL GETCHR

      RETURN
      
C*********************** FORMAT Statements *****************************

94000 FORMAT( 'ERROR: A Reaction label or operator option exceeds 16',
     &              ' characters' )
94020 FORMAT( '       Line No. ', I4, ': ', A )
94040 FORMAT( '       Label found : ', A, A )
      END
