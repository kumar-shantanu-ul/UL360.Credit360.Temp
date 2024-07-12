-- Please update version.sql too -- this keeps clean builds in sync
define version=2899
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN

  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'csr.APPROVALDASHINSTANCECREATOR',
    job_type        => 'PLSQL_BLOCK',
    job_action      => '   
          BEGIN
          security.user_pkg.logonadmin();
          csr.approval_dashboard_pkg.ScheduledInstanceCreator();
          commit;
          END;
    ',
	job_class       => 'low_priority_job',
	start_date      => to_timestamp_tz('2016/03/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	repeat_interval => 'FREQ=DAILY',
	enabled         => TRUE,
	auto_drop       => FALSE,
	comments        => 'Schedule for automated export import framework. Check for new imports and exports to queue in batch jobs.');
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\approval_dashboard_pkg
@..\approval_dashboard_body
@..\scenario_body

@update_tail
