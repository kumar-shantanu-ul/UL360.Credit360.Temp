-- Please update version.sql too -- this keeps clean builds in sync
define version=3359
define minor_version=2
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
  dbms_scheduler.run_job(
    job_name  => 'CSR.UPDATE_METRIC_VALS',
    use_current_session	=> false
  );
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
