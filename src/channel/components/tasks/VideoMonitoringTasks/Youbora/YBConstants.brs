' ********** Copyright 2023 Nice People At Work.  All Rights Reserved. **********

'YBConstants.brs

Function YouboraConstants()
  if m.ybconstants = invalid then
    m.ybconstants = {
      QUEUE_LIMIT_SIZE: 100
    }
  end if

  return m.ybconstants
End Function