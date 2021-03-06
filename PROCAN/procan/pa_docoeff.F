
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
C $Header: /project/yoj/arc/PROCAN/src/driver/pa/pa_docoeff.F,v 1.5 2011/11/02 14:33:55 yoj Exp $

      SUBROUTINE DOCOEFF( COEF, COUT )

C***********************************************************************
 
C Function: Transform a coefficient from numerical to character form for
C           output reports   
 
C Preconditions: None
  
C Key Subroutines/functions Called: None
 
C Revision History:
C  Prototype created by Jerry Gipson, August, 1996
C  Modified May, 1997 by Jerry Gipson to be consistent with beta CTM
 
C***********************************************************************
      IMPLICIT NONE
      
C Includes: None
      
C Arguments:
      REAL    COEF              ! Coefficient for output term 
      CHARACTER( * ) :: COUT    ! Output coefficient
                                        
C Parameters: None

C External Functions: None

C Local Variables
      INTEGER N   ! Loop index
         
C***********************************************************************

      DO N = 1, LEN( COUT )
         COUT( N:N ) = ' '
      END DO

      IF ( ABS( COEF ) .NE. 1.0 ) THEN
         WRITE( COUT, '( 2X, F7.4 )' ) ABS( COEF )
         COUT( 11:11 ) = '*'
      END IF   

      IF ( COEF .GE. 0.0 ) THEN
         COUT( 1:1 ) = '+'
      ELSE
         COUT( 1:1 ) = '-'
      END IF

      RETURN 
      END
