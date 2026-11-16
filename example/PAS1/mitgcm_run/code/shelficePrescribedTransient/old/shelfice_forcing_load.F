     SUBROUTINE SHELFICE_FORCING_LOAD(
     I                         myTime, myIter, myThid )

#include "SHELFICE_OPTIONS.h"

      IMPLICIT NONE

#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "SHELFICE.h"

      _RL myTime
      INTEGER myIter, myThid

      INTEGER myDate(4)
      INTEGER fieldDate(4)
      INTEGER nextDate(4)
      INTEGER dateDiff(4)
      _RL fieldTime
      _RL nextTime
      _RL fac
      INTEGER rec0, rec1
      INTEGER i,j,bi,bj

#ifdef ALLOW_CAL
      CALL CAL_GETDATE(myIter,myTime,myDate,myThid)
#endif

      need to make it read in files here and interpolate between months
correctly
