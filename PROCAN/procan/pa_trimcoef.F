
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
C $Header: /project/yoj/arc/PROCAN/src/driver/pa/pa_trimcoef.F,v 1.5 2011/11/02 14:34:00 yoj Exp $

      FUNCTION TRIMCOEF( COEFF ) RESULT( CHRCOEF )

C***********************************************************************
 
C Function: Convert a real number to character representation using
C           the fewest number of characters  
 
C Preconditions: None
  
C Key Subroutines/functions Called: None
 
C Revision History:
C  Prototype created by Jerry Gipson, August, 1996
C  Modified May, 1997 by Jerry Gipson to be consistent with beta CTM
C  Modified Sept, 1997 by Jerry Gipson to be consistent with targeted CTM
C  Modified Aug, 2011 by Jeff Young to Fortran 90
 
C***********************************************************************
      IMPLICIT NONE
      
C Includes: None
      
C Arguments:
      REAL   COEFF                ! Real number to convert
      CHARACTER( 10 ) :: CHRCOEF  ! Character coefficient holder

C Parameters: None

C External Functions: NONE 
 
C Local Variables:
      INTEGER COEFLEN    ! Max number of characters in coefficient
      INTEGER ENDPOS     ! Position of last significant haracter
      INTEGER SPOS       ! Position of first significant character
      INTEGER OFFSET     ! Justification offset
      INTEGER POS        ! Loop index for string position

C***********************************************************************
      WRITE( CHRCOEF, '( F10.5 )' ) COEFF
      COEFLEN = 10

c..Strip Trailing zeroes
      DO POS = COEFLEN, 6, -1
          IF ( CHRCOEF( POS:POS ) .EQ. '0' ) THEN
             ENDPOS = POS
             CHRCOEF( POS:POS ) = ' '
          ELSE
             GO TO 40
          END IF
      END DO
40    CONTINUE

c..Strip decimal point if not needed
      IF ( ENDPOS .EQ. 6 ) THEN 
         CHRCOEF( 5:5 ) = ' '
         ENDPOS = ENDPOS - 1
      END IF

c..Strip leading any leading signs
      DO POS = 1, 3
         IF ( CHRCOEF( POS:POS ) .EQ. '+' .OR. 
     &        CHRCOEF( POS:POS ) .EQ. '-' ) THEN
           CHRCOEF( POS:POS ) = ' '
           GO TO 80
         END IF
      END DO

80    CONTINUE
            
c..Strip any leading zeros       
      IF ( ABS( COEFF ) .GT. 0.0 .AND. COEFF .LT. 1.0 ) THEN
         DO POS = 4, 1, -1
            IF ( CHRCOEF( POS:POS ) .EQ. '0' )
     &           CHRCOEF( POS:POS ) = ' '
         END DO
      END IF

c..Left justify character string and return
      DO POS = 1, COEFLEN
         IF ( CHRCOEF( POS:POS ) .NE. ' ' ) THEN
            SPOS = POS
            GO TO 120
         END IF
      END DO

120   CONTINUE

      OFFSET = SPOS - 1

      DO POS = 1, COEFLEN
         IF ( POS + OFFSET .LE. ENDPOS ) THEN
            CHRCOEF( POS:POS ) = CHRCOEF( POS+OFFSET:POS+OFFSET )
         ELSE
            CHRCOEF( POS:POS ) = ' '
         END IF
      END DO

      RETURN
      END  

