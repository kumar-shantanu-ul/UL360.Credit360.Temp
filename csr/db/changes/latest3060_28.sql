-- Please update version.sql too -- this keeps clean builds in sync
define version=3060
define minor_version=28
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.batch_job_type
ADD timeout_mins NUMBER(4);

ALTER TABLE CSR.BATCH_JOB_TYPE_APP_CFG
ADD timeout_mins NUMBER(4);

ALTER TABLE csr.batch_job_type
RENAME COLUMN notify_after_attempts TO max_retries;

ALTER TABLE csr.batch_job
ADD timed_out NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE csr.batch_job
ADD CONSTRAINT ck_batch_job_timed_out CHECK (timed_out IN (0, 1));

ALTER TABLE csr.batch_job
ADD ignore_timeout NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE csr.batch_job
ADD CONSTRAINT ck_batch_job_ignore_timeout CHECK (ignore_timeout IN (0, 1));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	UPDATE csr.batch_job_type
	   SET timeout_mins = 120; -- 2 hours
	
	-- Metering and automated imports
	UPDATE csr.batch_job_type
	   SET timeout_mins = 360 -- 6 hours	
	 WHERE batch_job_type_id IN (10, 13, 19, 23, 24, 50, 53, 55, 56, 57);
END;
/

BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) 
	VALUES (31, 'Modify batch job timeout', 'Changes the timeout for a batchjob type for the current app.','SetBatchJobTimeoutOverride',NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) 
	VALUES (31, 'Batch job type id', 'Batch job type id', 0, NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) 
	VALUES (31, 'Timeout mins', 'Minutes the job can run for before it times out.', 1, NULL);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../batch_job_pkg
@../util_script_pkg


@../batch_job_body
@../util_script_body
@../templated_report_schedule_body


@update_tail