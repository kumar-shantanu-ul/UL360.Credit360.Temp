-- Please update version.sql too -- this keeps clean builds in sync
define version=3344
define minor_version=1
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
	dbms_scheduler.create_job (
		job_name		=> 'CSR.UPDATE_METRIC_VALS',
		job_type		=> 'PLSQL_BLOCK',
		job_action		=> 'BEGIN security.user_pkg.logonadmin(); csr.region_metric_pkg.RefreshSystemValues; security.user_pkg.LogOff(security.security_pkg.GetAct); END;',
		job_class		=> 'low_priority_job',
		start_date		=> to_timestamp_tz(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE, 'MONTH'), 1), 'YYYY/MM/DD') || ' 02:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval	=> 'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=2;BYHOUR=02;BYMINUTE=00;BYSECOND=00',
		enabled			=> TRUE,
		auto_drop		=> FALSE,
		comments		=> 'Update end date of region metrics values'
	);
	
	dbms_scheduler.run_job(
		job_name			=> 'CSR.UPDATE_METRIC_VALS',
		use_current_session	=> false
	);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../region_metric_pkg

@../indicator_body
@../region_metric_body

@update_tail
