-- Please update version.sql too -- this keeps clean builds in sync
define version=23
@update_header

	--- we can restore these later but setting water_pct = 0 makes the regression testing easier 
	-- and the users are going to have to ammend / check the values copied from the average's linked to prod type anyway
	
	UPDATE gt_formulation_answers
		SET water_pct = 0;

@update_tail