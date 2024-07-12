-- Please update version.sql too -- this keeps clean builds in sync
define version=1168
@update_header

-- Ensure region body is recompiled 
-- when the release freeze is lifted
@../region_body;
	
@update_tail

