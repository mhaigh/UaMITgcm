#include "SHELFICE_OPTIONS.h"

      SUBROUTINE SHELFICE_GET_FORCING(myTime,myThid)

      IMPLICIT NONE

#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "SHELFICE.h"

C edits to make:
C make OPEN unit using mdsfindunit
C need to close the opened file?
C generalise so takes input start and end years
C any way to use exf architecture?

      _RL myTime
      INTEGER myThid

      INTEGER i,j,bi,bj
      INTEGER iG,jG
      INTEGER year,month
      INTEGER dayOfYear
      INTEGER rec0,rec1
      INTEGER nDay(12)

      _RL tYear
      _RL tMonth0,tMonth1
      _RL frac

      REAL*4 fieldT(600,384)
      REAL*4 fieldS(600,384)

      DATA nDay / 0,31,59,90,120,151,181,212,243,273,304,334 /

      INTEGER, SAVE :: oldRec = 0
      INTEGER, SAVE :: tUnit = 0
      INTEGER, SAVE :: sUnit = 0

C-----------------------------------------------------------------------
C     Time since 1 Jan 1920.
C-----------------------------------------------------------------------

      tYear = myTime-startTime

      year = INT(tYear/(365.D0*86400.D0))
      tYear = tYear-year*365.D0*86400.D0

      dayOfYear = INT(tYear/86400.D0)

      month = 1
      DO WHILE (month.LT.12 .AND.
     &          dayOfYear.GE.nDay(month+1))
         month = month+1
      ENDDO

C-----------------------------------------------------------------------
C     Record numbers:
C       1 = Jan 1920
C       2172 = Dec 2100
C-----------------------------------------------------------------------

      rec0 = year*12 + month
      rec1 = MIN(rec0+1,2172)

C-----------------------------------------------------------------------
C     Fraction between the two monthly records.
C-----------------------------------------------------------------------

      tMonth0 = nDay(month)*86400.D0

      IF (month.LT.12) THEN
         tMonth1 = nDay(month+1)*86400.D0
      ELSE
         tMonth1 = 365.D0*86400.D0
      ENDIF

      frac = (tYear-tMonth0)/(tMonth1-tMonth0)

C     Hold December 2100 after the end of the forcing.
      IF (rec0.EQ.2172) frac = 0.D0

C-----------------------------------------------------------------------
C     Open files and read new records only when the month changes.
C-----------------------------------------------------------------------

      IF (tUnit.EQ.0) THEN

         OPEN(UNIT=90,FILE=SHELFICEforcingTFile,
     &        ACCESS='DIRECT',FORM='UNFORMATTED',
     &        RECL=600*384,STATUS='OLD')

         OPEN(UNIT=91,FILE=SHELFICEforcingSFile,
     &        ACCESS='DIRECT',FORM='UNFORMATTED',
     &        RECL=600*384,STATUS='OLD')

         tUnit = 90
         sUnit = 91

      ENDIF

      IF (rec0.NE.oldRec) THEN

C        First month
         READ(tUnit,REC=rec0) fieldT
         READ(sUnit,REC=rec0) fieldS

         DO bj=myByLo(myThid),myByHi(myThid)
            DO bi=myBxLo(myThid),myBxHi(myThid)

               DO j=1,sNy
                  jG=myYGlobalLo+(bj-myByLo(myThid))*sNy+j-1

                  DO i=1,sNx
                     iG=myXGlobalLo+(bi-myBxLo(myThid))*sNx+i-1

                     shelficeForcingT0(i,j,bi,bj)=fieldT(iG,jG)
                     shelficeForcingS0(i,j,bi,bj)=fieldS(iG,jG)

                  ENDDO
               ENDDO

            ENDDO
         ENDDO

C        Second month
         IF (rec1.EQ.rec0) THEN

            shelficeForcingT1=shelficeForcingT0
            shelficeForcingS1=shelficeForcingS0

         ELSE

            READ(tUnit,REC=rec1) fieldT
            READ(sUnit,REC=rec1) fieldS

            DO bj=myByLo(myThid),myByHi(myThid)
               DO bi=myBxLo(myThid),myBxHi(myThid)

                  DO j=1,sNy
                     jG=myYGlobalLo+
     &                  (bj-myByLo(myThid))*sNy+j-1

                     DO i=1,sNx
                        iG=myXGlobalLo+
     &                     (bi-myBxLo(myThid))*sNx+i-1

                        shelficeForcingT1(i,j,bi,bj)=fieldT(iG,jG)
                        shelficeForcingS1(i,j,bi,bj)=fieldS(iG,jG)

                     ENDDO
                  ENDDO

               ENDDO
            ENDDO

         ENDIF

         oldRec=rec0

      ENDIF

C-----------------------------------------------------------------------
C     Linear interpolation.
C-----------------------------------------------------------------------

      DO bj=myByLo(myThid),myByHi(myThid)
         DO bi=myBxLo(myThid),myBxHi(myThid)

            DO j=1,sNy
               DO i=1,sNx

                  shelficeForcingT(i,j,bi,bj) =
     &             (1.D0-frac)*shelficeForcingT0(i,j,bi,bj)
     &             + frac*shelficeForcingT1(i,j,bi,bj)

                  shelficeForcingS(i,j,bi,bj) =
     &             (1.D0-frac)*shelficeForcingS0(i,j,bi,bj)
     &             + frac*shelficeForcingS1(i,j,bi,bj)

               ENDDO
            ENDDO

         ENDDO
      ENDDO

      RETURN
      END
