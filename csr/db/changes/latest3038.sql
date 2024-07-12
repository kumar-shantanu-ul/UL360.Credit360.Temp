-- Please update version.sql too -- this keeps clean builds in sync
define version=3038
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
CREATE INDEX CSR.IX_METRDNG_RGNDTM ON CSR.METER_READING_DATA(APP_SID, REGION_SID, READING_DTM)
;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data


BEGIN
	DBMS_SCHEDULER.DROP_JOB (
		job_name		=> 'csr.MeterRawDataJob'
	);
	DBMS_SCHEDULER.CREATE_JOB (
		job_name		=> 'csr.MeterRawDataJob',
		job_type		=> 'PLSQL_BLOCK',
		job_action		=> 'BEGIN security.user_pkg.logonadmin(); csr.meter_monitor_pkg.CreateRawDataJobsForApps; commit; END;',
		job_class		=> 'low_priority_job',
		start_date		=> to_timestamp_tz('2016/10/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval	=> 'FREQ=DAILY',
		enabled			=> TRUE,
		auto_drop		=> FALSE,
		comments		=> 'Schedule creating meter raw data jobs'
	);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../meter_aggr_pkg

@../meter_aggr_body
@../meter_monitor_body

@update_tail
