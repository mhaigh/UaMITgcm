#include "SHELFICE_OPTIONS.h"

      SUBROUTINE SHELFICE_GET_FORCING2(
     &     myTime, myIter, myThid )

C=====================================================================
C     SHELFICE_GET_FLUXES
C
C     Read and temporally interpolate monthly heat-flux fields.
C
C     Input files:
C
C        is_heat_flux_YEAR
C
C     Each file contains 12 binary records:
C
C        record  1 = January
C        record  2 = February
C        ...
C        record 12 = December
C
C     CAL_GETMONTHSREC determines:
C
C        count0, year0 = first monthly record
C        count1, year1 = second monthly record
C        fac            = interpolation factor
C
C     This also handles the December -> January year boundary.
C=====================================================================

      IMPLICIT NONE

#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "SHELFICE.h"

C====== Arguments ====================================================

      INTEGER myIter, myThid
      _RL myTime

C====== CAL_GETMONTHSREC variables ===================================

      INTEGER count0, count1
      INTEGER year0, year1

      _RL fac

      LOGICAL first
      LOGICAL changed

C     Indices

      INTEGER i, j
      INTEGER iG, jG
      INTEGER iStart, jStart

C===================================================================
C     Use cal package to get necessary forcing years/months
C     and check if new fields need to be read.
C==================================================================

      CALL cal_GetMonthsRec(
     &     fac, first, changed,
     &     count0, count1, year0, year1,
     &     myTime, myIter, myThid )
     
C     WRITE(6,*) fac, first, changed, count0, year0, count1, year1
 
C=======================================================================
C     Read two flux fields if initialising model, or month changed.
C=======================================================================

      IF ( first .OR. changed ) THEN

        CALL READ_FLUX(SHELFICEforcingTFile,
     &        year0, count0,
     &        shelficeForcingT0, Nx, Ny,
     &        myThid )

         CALL READ_FLUX(SHELFICEforcingTFile,
     &        year1, count1,
     &        shelficeForcingT1, Nx, Ny,
     &        myThid )

      ENDIF

C=======================================================================
C     Interpolate between two fluxes
C=======================================================================

      iStart = (myPx-1)*sNx
      jStart = (myPy-1)*sNy

      DO j = 1, sNy
        DO i = 1, sNx

          iG = iStart + i
          jG = jStart + j

          shelficeForcingT(i,j,1,1) =
     &    (1.0 _d 0 - fac)*shelficeForcingT0(iG,jG)
     &    + fac*shelficeForcingT1(iG,jG)

        ENDDO
      ENDDO
       
      RETURN
      END

C=======================================================================
C     Read flux subroutine
C=======================================================================

      SUBROUTINE READ_FLUX(filePrefix,
     &     year, month, field,
     &     Nx, Ny, myThid )

      IMPLICIT NONE

C     Arguments
      INTEGER year
      INTEGER month
      INTEGER myThid
      INTEGER Nx
      INTEGER Ny
      INTEGER recl
      INTEGER j,i

C      _RS tmpVar(1:Nx,1:Ny)
      REAL*4 tmpVar(1:Nx,Ny)
      _RL field(1:Nx,1:Ny)
C      _RS tmpVarOne
      REAL*4 tmpVarOne

C     Local vars
      INTEGER unit
      INTEGER rec
      INTEGER pos
      INTEGER ios
      CHARACTER*256 fileName
      CHARACTER*256 filePrefix
      CHARACTER*256 iomsg

C================================================================

      DO j=1,Ny
        DO i=1,Nx
          tmpVar(i,j)=0
        ENDDO
      ENDDO

C     Make filename
      WRITE(fileName,'(A,"_",I4.4)') trim(filePrefix), year

C     Open file
      recl = Nx * Ny * 4
      pos = 1 + (month-1)*recl

      OPEN(
     &     NEWUNIT=unit,
     &     FILE=fileName,
     &     FORM='UNFORMATTED',
     &     ACCESS='STREAM',
C     &     RECL=recl
     &     STATUS='OLD',
     &     IOSTAT=ios )

      IF ( ios .NE. 0 ) THEN
         WRITE(*,*) 'SHELFICE_GET_FORCING: ERROR opening file: ',
     &              fileName
         STOP 'SHELFICE_GET_FORCING: file open error'
      ENDIF

C      iomsg = 'All fine'
C      WRITE(6,*) 'Doing mothly recs, unit', unit
C      FLUSH(6)
C      DO month=1,12
C       pos = 1 + (month-1)*recl
C       READ(
C     &     UNIT=unit,
C     &     POS=pos,
C     &     IOMSG=iomsg,
C     &     IOSTAT=ios ) tmpVar
C       tmpVarOne = 0
C       WRITE(6,*) month, pos, ios, iomsg, tmpVarOne
C      ENDDO

      ios = 0
      iomsg = 'All fine'
      WRITE(6,*) 'Doing bitwise recs'
      FLUSH(6)
      DO month=1,12
       pos = 1 + (month-1)*recl
C       pos = 11059200-recl-recl+month
       READ(
     &     UNIT=unit,
     &     POS=pos,
     &     IOMSG=iomsg,
     &     IOSTAT=ios ) tmpVar
       WRITE(6,*) month, pos, ios, iomsg
       tmpVarOne = 0
       DO j=1,Ny
         DO i=1,Nx
          tmpVarOne = tmpVarOne + tmpVar(i,j)
         ENDDO
       ENDDO
       WRITE(6,*) tmpVarOne

       ios=0
       iomsg = 'All fine'
       ENDDO

C     Read required record in file
C      READ(
C     &     UNIT=unit,
C     &     REC=month,
C     &     IOSTAT=ios ) tmp
       READ(
     &     UNIT=unit,
     &     POS=pos,
     &     IOMSG=iomsg,
     &     IOSTAT=ios ) tmpVarOne
       IF ( ios .NE. 0 ) THEN
         WRITE(6,*) 'SHELFICE_GET_FORCING: ERROR reading file: ',
     &              fileName
         WRITE(6,*) 'Requested month = ',month
         WRITE(6,*) 'IOSTAT          = ',ios
         WRITE(6,*) Nx, Ny, recl, pos, iomsg
         CLOSE(unit)
         STOP 'SHELFICE_GET_FORCING: read error'

      ENDIF

C     This way safely accounts for different precisions
      field = tmpVar

C      DO rec = 1, month
C         READ(unit,IOSTAT=ios) field
C         IF ( ios .NE. 0 ) THEN
C            WRITE(*,*) 'SHELFICE_GET_FORCING: ERROR reading file: ',
C     &                 fileName
C            WRITE(*,*) 'Requested month = ', month
C            WRITE(*,*) 'Record          = ', rec
C            CLOSE(unit)
C            STOP 'SHELFICE_GET_FORCING: read error'
C         ENDIF
C      ENDDO

C     Close file
      CLOSE(UNIT=unit)

      RETURN
      END

C=======================================================================
C     End read flux subroutine
C=======================================================================
