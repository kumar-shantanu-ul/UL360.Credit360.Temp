-- Please update version.sql too -- this keeps clean builds in sync
define version=3274
define minor_version=3
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
	SYS.DBMS_SCHEDULER.DROP_JOB (job_name  => 'CSR.EXPIRE_REMOTE_JOBS');
	/*
	-- If we need to reinstate this at a later point, this is what it should have been.
	dbms_scheduler.create_job (
		job_name		=> 'CSR.EXPIRE_REMOTE_JOBS',
		job_type		=> 'PLSQL_BLOCK',
		job_action		=> 'csr.meter_processing_job_pkg.ExpireJobs;',
		job_class		=> 'low_priority_job',
		start_date		=> to_timestamp_tz('2020/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval	=> 'FREQ=MINUTELY;INTERVAL=10',
		enabled			=> TRUE,
		auto_drop		=> FALSE,
		comments		=> 'Roll-back or expire meter processing jobs that are no longer locked but in a status that means they were processing'
	);
	*/
END;
/



-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../meter_processing_job_pkg
@../meter_processing_job_body

@update_tail
