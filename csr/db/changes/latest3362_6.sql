-- Please update version.sql too -- this keeps clean builds in sync
define version=3362
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	FOR r IN (
		SELECT app_sid, host, alert_batch_run_time current_interval, 
			-- If the current interval is less than :30 then push it back to the hour. Eg
			-- 10:15 becomes 10:00
			CASE WHEN EXTRACT(MINUTE FROM alert_batch_run_time) < 30 THEN 
				alert_batch_run_time - to_dsinterval('+00 00:'|| EXTRACT(MINUTE FROM ALERT_BATCH_RUN_TIME) ||':00.000000') 
			ELSE
			-- It's after 30, so push back to :30. Eg 10:45 becomes 10:30
				ALERT_BATCH_RUN_TIME - to_dsinterval('+00 00:'|| (EXTRACT(MINUTE FROM ALERT_BATCH_RUN_TIME) - 30) ||':00.000000')
			END new_interval
		  FROM csr.customer
		 WHERE EXTRACT(MINUTE FROM ALERT_BATCH_RUN_TIME) NOT IN (0, 30)
	)
	LOOP
		UPDATE csr.customer
		   SET alert_batch_run_time = r.new_interval
		 WHERE app_sid = r.app_sid;
	END LOOP;
end;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
