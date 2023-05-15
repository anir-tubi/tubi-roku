' ********** Copyright 2023 Nice People At Work.  All Rights Reserved. **********

'YBConstants.brs

function YouboraConstants()
	if m.ybconstants = invalid then
		m.ybconstants = {
			QUEUE_LIMIT_SIZE: 100
		}
	end if

	return m.ybconstants
end function