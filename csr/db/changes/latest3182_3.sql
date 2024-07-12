-- Please update version.sql too -- this keeps clean builds in sync
define version=3182
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
	DBMS_SCHEDULER.SET_ATTRIBUTE (
		name		=> 'csr.AutomatedExportImport',
		attribute	=> 'job_action',
		/**/value		=> 'BEGIN csr.automated_export_import_pkg.ScheduleRun(); commit; END;'
	);

	DBMS_SCHEDULER.SET_ATTRIBUTE (
		name		=> 'csr.BATCHEDEXPORTSCLEARUP',
		attribute	=> 'job_action',
		value		=> 'BEGIN security.user_pkg.logonadmin(); csr.batch_exporter_pkg.ScheduledFileClearup(); security.user_pkg.logoff(security.security_pkg.GetAct); commit; END;'
	);

	DBMS_SCHEDULER.SET_ATTRIBUTE (
		name		=> 'csr.BATCHEDIMPORTSCLEARUP',
		attribute	=> 'job_action',
		value		=> 'BEGIN security.user_pkg.logonadmin(); csr.batch_importer_pkg.ScheduledFileClearUp; security.user_pkg.LogOff(security.security_pkg.GetAct); commit; END;'
	);


	DBMS_SCHEDULER.SET_ATTRIBUTE (
		name		=> 'csr.MeterRawDataJob',
		attribute	=> 'job_action',
		value		=> 'BEGIN security.user_pkg.logonadmin(); csr.meter_monitor_pkg.CreateRawDataJobsForApps; security.user_pkg.LogOff(security.security_pkg.GetAct); commit; END;'
	);

	DBMS_SCHEDULER.SET_ATTRIBUTE (
		name		=> 'csr.MeterMatchJob',
		attribute	=> 'job_action',
		value		=> 'BEGIN security.user_pkg.logonadmin(); csr.meter_monitor_pkg.CreateMatchJobsForApps; security.user_pkg.LogOff(security.security_pkg.GetAct); commit; END;'
	);

	DBMS_SCHEDULER.SET_ATTRIBUTE (
		name		=> 'csr.MeterMatchJob',
		attribute	=> 'job_action',
		value		=> 'BEGIN security.user_pkg.logonadmin(); csr.customer_pkg.RefreshCalcWindows; security.user_pkg.LogOff(security.security_pkg.GetAct); END;'
	);

END;
/

-- expire timeouts mistakenly set to an app_sid to time out in the time they were meant to
UPDATE security.act_timeout
   SET timeout = 86400
 WHERE timeout IN (
	SELECT application_sid_id
	  FROM security.website
 );

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\chain\scheduled_alert_body
@..\chain\bsci_body
@..\chain\questionnaire_body
@..\chain\dedupe_preprocess_body
@..\energy_star_job_body
@..\stored_calc_datasource_body
@..\region_tree_body
@..\sheet_body
@..\indicator_body
@..\delegation_body
@..\aggregate_ind_body
@..\audit_body
@..\automated_import_body

@update_tail
