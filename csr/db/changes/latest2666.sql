--Please update version.sql too -- this keeps clean builds in sync
define version=2666
@update_header

-- Add missing CSRIMP columns.
-- Check if they already exist. I've had to run this separately for Berkeley
-- as I had built everything for a patch already...
DECLARE
	v_exists	NUMBER;
BEGIN
	-- Columns were added at the same time, so only need
	-- to check one exists.
	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_tab_cols
	 WHERE table_name = 'METER_SOURCE_TYPE'
	   AND owner = 'CSRIMP'
	   AND column_name = 'PERIOD_SET_ID';

	IF v_exists = 0 THEN
		EXECUTE IMMEDIATE('ALTER TABLE csrimp.meter_source_type ADD (period_set_id NUMBER(10), period_interval_id NUMBER(10))');

		-- For any existing sessions.
		EXECUTE IMMEDIATE('UPDATE csrimp.meter_source_type SET period_set_id = 1, period_interval_id = 1');

		EXECUTE IMMEDIATE('ALTER TABLE csrimp.meter_source_type MODIFY (period_set_id NUMBER(10) NOT NULL, period_interval_id NUMBER(10) NOT NULL)');
	END IF;
END;
/


@update_tail

