      SUBROUTINE SHELFICE_GET_FLUXES(
     &     myTime, myIter, myThid )

C     ==================================================================
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
C     ==================================================================

      IMPLICIT NONE

#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "SHELFICE.h"

C     === Arguments ====================================================

      INTEGER myIter, myThid
      _RL myTime

C     === CAL_GETMONTHSREC variables ===================================

      INTEGER count0, count1
      INTEGER year0, year1

      _RL fac

      LOGICAL first
      LOGICAL changed

C     === Monthly fields ===============================================

      _RL heatFlux0(1:sNx,1:sNy)
      _RL heatFlux1(1:sNx,1:sNy)

      INTEGER i, j

C     ==================================================================
C     Ask the MITgcm calendar package which two monthly records
C     surround the current model time.
C     ==================================================================

      CALL cal_GetMonthsRec(
     &     fac, first, changed,
     &     count0, count1, year0, year1,
     &     myTime, myIter, myThid )

C     ==================================================================
C     Load new records whenever the required month pair changes.
C
C     The FIRST flag handles the initial read.
C     CHANGED becomes true when CAL_GETMONTHSREC moves to a new pair.
C     ==================================================================


      IF ( first .OR. changed ) THEN

       CALL READ_HEAT_FLUX(
     &        year0, count0,
     &        heatFlux0, nX, nY,
     &        myThid )

       CALL READ_HEAT_FLUX(
     &        year1, count1,
     &        heatFlux1, nX, nY,
     &        myThid )

      ENDIF

C     ==================================================================
C     Interpolate between the two monthly records.
C
C        fac = 0   -> first record
C        fac = 1   -> second record
C     ==================================================================


      DO j = 1, nY
        DO i = 1, nX

           heatFlux(i,j) =
     &     (1.0 _d 0 - fac)*heatFlux0(i,j)
     &     + fac*heatFlux1(i,j)

        ENDDO
      ENDDO

      RETURN
      END


C***********************************************************************
C
C     C76S_READ_HEAT_FLUX
C
C     Read one monthly heat-flux record from:
C
C        is_heat_flux_YEAR
C
C     The file contains 12 sequential binary records, with each record
C     containing an nX by nY array.
C
C***********************************************************************

      SUBROUTINE READ_HEAT_FLUX(
     &     year, month, field,
     &     nX, nY, myThid )

      IMPLICIT NONE

C     === Arguments ====================================================

      INTEGER year
      INTEGER month
      INTEGER nX
      INTEGER nY
      INTEGER myThid

      _RL field(nX,nY)

C     === Local variables ==============================================

     INTEGER unit
     INTEGER rec
     INTEGER ios

     CHARACTER*256 fileName

C     ==================================================================
C     Construct filename.
C
C        e.g.
C
C        is_heat_flux_1990
C        is_heat_flux_1991
C        ...
C     ==================================================================

      WRITE(fileName,'(A,I4.4)') 'is_heat_flux_', year

C     ==================================================================
C     Open the yearly binary file.
C
C     Sequential unformatted is assumed.
C     ==================================================================
 
      unit = 77

      OPEN(
     &     UNIT=unit,
     &     FILE=fileName,
     &     FORM='UNFORMATTED',
     &     ACCESS='SEQUENTIAL',
     &     STATUS='OLD',
     &     IOSTAT=ios )

      IF ( ios .NE. 0 ) THEN

         WRITE(*,*) 'C76S_GET_HEAT_FLUX: ERROR opening file: ',
     &              fileName

         STOP 'C76S_GET_HEAT_FLUX: file open error'

      ENDIF

C     ==================================================================
C     Skip forward to the requested monthly record.
C
C        January   = record 1
C        February  = record 2
C        ...
C        December  = record 12
C     ==================================================================

      DO rec = 1, month

         READ(unit,IOSTAT=ios) field

         IF ( ios .NE. 0 ) THEN

            WRITE(*,*) 'C76S_GET_HEAT_FLUX: ERROR reading file: ',
     &                 fileName

            WRITE(*,*) 'Requested month = ', month
            WRITE(*,*) 'Record          = ', rec

            CLOSE(unit)

            STOP 'C76S_GET_HEAT_FLUX: read error'

         ENDIF

      ENDDO

C     ==================================================================
C     Close file.
C     ==================================================================

      CLOSE(unit)

      RETURN
      END

