
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
C $Header: /project/yoj/arc/CCTM/src/vdiff/acm2/rdmet.F,v 1.5 2011/10/21 16:11:46 yoj Exp $
 
C what( 1 ) key, module and SID; SCCS file; date and time of last delta:
C %W% %P% %G% %U%
 
C:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
      SUBROUTINE RDMET ( MDATE, MTIME, RDEPVHT, RJACM, RVJACMF, RRHOJ, DENS1 )

C-----------------------------------------------------------------------
C   30 Mar 01 J.Young: dyn alloc - Use HGRD_DEFN; replace INTERP3 with INTERPX;
C                      allocatable RDEPVHT, RJACM, RRHOJ
C   14 Nov 03 J.Young: add reciprocal vertical Jacobian product for full and
C                      mid-layer
C   Tanya took JACOBF out of METCRO3D! Improvise
C   31 Jan 05 J.Young: dyn alloc - establish both horizontal & vertical
C                      domain specifications in one module
C   16 Feb 11 S.Roselle: replaced I/O API include files with UTILIO_DEFN
C-----------------------------------------------------------------------

      USE GRID_CONF           ! horizontal & vertical domain specifications
      USE UTILIO_DEFN

      IMPLICIT NONE
 
!     INCLUDE SUBST_HGRD_ID   ! horizontal dimensioning parameters
!     INCLUDE SUBST_VGRD_ID   ! vertical dimensioning parameters
      INCLUDE SUBST_FILES_ID  ! file name parameters

C Arguments:

      INTEGER, INTENT( IN )  :: MDATE, MTIME      ! internal simulation date&time
!     REAL         RDEPVHT( NCOLS,NROWS )       ! reciprocal dep vel ht
!     REAL         RJACM  ( NCOLS,NROWS,NLAYS ) ! reciprocal mid-layer Jacobian
!     REAL         RRHOJ  ( NCOLS,NROWS,NLAYS ) ! reciprocal density X Jacobian
      REAL,    INTENT( OUT ) :: RDEPVHT( :,: )    ! air dens / dep vel ht
      REAL,    INTENT( OUT ) :: RJACM  ( :,:,: )  ! reciprocal mid-layer Jacobian
      REAL,    INTENT( OUT ) :: RVJACMF( :,:,: )  ! 1/ mid-full layer vert Jac
      REAL,    INTENT( OUT ) :: RRHOJ  ( :,:,: )  ! reciprocal density X Jacobian
      REAL,    INTENT( OUT ) :: DENS1  ( :,: )    ! layer 1 air density

C File variables:

!     REAL         ZF     ( NCOLS,NROWS,NLAYS ) ! layer surface ht above ground
      REAL, ALLOCATABLE, SAVE :: ZF  ( :,:,: ) ! layer surface ht above ground
      REAL, ALLOCATABLE, SAVE :: DENS( :,:,: ) ! air density
      REAL, ALLOCATABLE, SAVE :: JACF( :,:,: ) ! full-layer Jacobian
      REAL, ALLOCATABLE, SAVE :: RMSFX4( :,: ) ! inverse map scale factor ** 4

C Local variables:

      CHARACTER( 16 ) :: PNAME = 'RDMET'
      CHARACTER( 16 ) :: VNAME
      CHARACTER( 96 ) :: XMSG = ' '

      LOGICAL, SAVE :: FIRSTIME = .TRUE.
      INTEGER, SAVE :: LOGDEV

      INTEGER      GXOFF, GYOFF              ! global origin offset from file
C for INTERPX
      INTEGER, SAVE :: STRTCOLMC3, ENDCOLMC3, STRTROWMC3, ENDROWMC3
      INTEGER       :: STRTCOLGC2, ENDCOLGC2, STRTROWGC2, ENDROWGC2

      INTEGER      C, R, L                   ! loop induction variables
      INTEGER      ALLOCSTAT

C-----------------------------------------------------------------------

      IF ( FIRSTIME ) THEN
         FIRSTIME = .FALSE.
         LOGDEV = INIT3()

         CALL SUBHFILE ( MET_CRO_3D, GXOFF, GYOFF,
     &                   STRTCOLMC3, ENDCOLMC3, STRTROWMC3, ENDROWMC3 )

         ALLOCATE ( ZF( NCOLS,NROWS,NLAYS ), STAT = ALLOCSTAT )
         IF ( ALLOCSTAT .NE. 0 ) THEN
            XMSG = 'Failure allocating ZF'
            CALL M3EXIT( PNAME, MDATE, MTIME, XMSG, XSTAT1 )
            END IF

         ALLOCATE ( DENS( NCOLS,NROWS,NLAYS ), STAT = ALLOCSTAT )
         IF ( ALLOCSTAT .NE. 0 ) THEN
            XMSG = 'Failure allocating DENS'
            CALL M3EXIT( PNAME, MDATE, MTIME, XMSG, XSTAT1 )
            END IF

         ALLOCATE ( JACF( NCOLS,NROWS,NLAYS ), STAT = ALLOCSTAT )
         IF ( ALLOCSTAT .NE. 0 ) THEN
            XMSG = 'Failure allocating JACF'
            CALL M3EXIT( PNAME, MDATE, MTIME, XMSG, XSTAT1 )
            END IF

         CALL SUBHFILE ( GRID_CRO_2D, GXOFF, GYOFF,
     &                   STRTCOLGC2, ENDCOLGC2, STRTROWGC2, ENDROWGC2 )

C reciprical of msfx2**2

         ALLOCATE ( RMSFX4( NCOLS,NROWS ), STAT = ALLOCSTAT )
         IF ( ALLOCSTAT .NE. 0 ) THEN
            XMSG = 'Failure allocating RMSFX4'
            CALL M3EXIT( PNAME, MDATE, MTIME, XMSG, XSTAT1 )
            END IF

         VNAME = 'MSFX2'
         IF ( .NOT. INTERPX( GRID_CRO_2D, VNAME, PNAME,
     &                       STRTCOLGC2,ENDCOLGC2, STRTROWGC2,ENDROWGC2, 1,1,
     &                       MDATE, MTIME, RMSFX4 ) ) THEN
            XMSG = 'Could not interpolate MSFX2 from ' // GRID_CRO_2D
            CALL M3EXIT( PNAME, MDATE, MTIME, XMSG, XSTAT1 )
            END IF

         RMSFX4 = 1.0 / ( RMSFX4 * RMSFX4 )

         END IF   ! FIRSTIME

C Interpolate file input variables and format for output

      VNAME = 'ZF'
      IF ( .NOT. INTERPX( MET_CRO_3D, VNAME, PNAME,
     &                    STRTCOLMC3,ENDCOLMC3, STRTROWMC3,ENDROWMC3, 1,NLAYS,
     &                    MDATE, MTIME, ZF ) ) THEN
         XMSG = 'Could not interpolate ZF from '// MET_CRO_3D
         CALL M3EXIT( PNAME, MDATE, MTIME, XMSG, XSTAT1 )
         END IF

      DO R = 1, MY_NROWS
         DO C = 1, MY_NCOLS
            RDEPVHT( C,R ) = 1.0 / ZF( C,R,1 )
            END DO
         END DO

      VNAME = 'DENS'
      IF ( .NOT. INTERPX( MET_CRO_3D, VNAME, PNAME,
     &                    STRTCOLMC3,ENDCOLMC3, STRTROWMC3,ENDROWMC3, 1,NLAYS,
     &                    MDATE, MTIME, DENS ) ) THEN
         XMSG = 'Could not interpolate DENS from ' // MET_CRO_3D
         CALL M3EXIT( PNAME, MDATE, MTIME, XMSG, XSTAT 1 )
         END IF

      DO R = 1, MY_NROWS
         DO C = 1, MY_NCOLS
            DENS1( C,R ) = DENS( C,R,1 )
            END DO
         END DO

      VNAME = 'JACOBM'
      IF ( .NOT. INTERPX( MET_CRO_3D, VNAME, PNAME,
     &                    STRTCOLMC3,ENDCOLMC3, STRTROWMC3,ENDROWMC3, 1,NLAYS,
     &                    MDATE, MTIME, RJACM ) ) THEN
         XMSG = 'Could not interpolate JACOBM from ' // MET_CRO_3D
         CALL M3EXIT( PNAME, MDATE, MTIME, XMSG, XSTAT1 )
         END IF

      VNAME = 'JACOBF'
      IF ( .NOT. INTERPX( MET_CRO_3D, VNAME, PNAME,
     &                    STRTCOLMC3,ENDCOLMC3, STRTROWMC3,ENDROWMC3, 1,NLAYS,
     &                    MDATE, MTIME, JACF ) ) THEN
         XMSG = 'Could not interpolate JACOBF from ' // MET_CRO_3D
         CALL M3EXIT( PNAME, MDATE, MTIME, XMSG, XSTAT1 )
         END IF

      DO L = 1, NLAYS
         DO R = 1, MY_NROWS
            DO C = 1, MY_NCOLS
               RJACM( C,R,L ) = 1.0 / RJACM( C,R,L )
               RVJACMF( C,R,L ) = RJACM( C,R,L ) * RMSFX4( C,R ) / JACF( C,R,L )
               END DO
            END DO
         END DO

      VNAME = 'DENSA_J'
      IF ( .NOT. INTERPX( MET_CRO_3D, VNAME, PNAME,
     &                    STRTCOLMC3,ENDCOLMC3, STRTROWMC3,ENDROWMC3, 1,NLAYS,
     &                    MDATE, MTIME, RRHOJ ) ) THEN
         XMSG = 'Could not interpolate DENSA_J from ' // MET_CRO_3D
         CALL M3EXIT( PNAME, MDATE, MTIME, XMSG, XSTAT1 )
         END IF

      DO L = 1, NLAYS
         DO R = 1, MY_NROWS
            DO C = 1, MY_NCOLS
               RRHOJ( C,R,L ) = 1.0 / RRHOJ( C,R,L )
               END DO
            END DO
         END DO

      RETURN
      END
