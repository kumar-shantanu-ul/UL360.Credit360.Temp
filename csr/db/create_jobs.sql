-- Queue a job for deleting old 'extra session' data
BEGIN
    -- now and every day afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.SessionExtraCleanUp',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'session_extra_pkg.CleanOldData;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 04:12 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=DAILY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Raise delegation reminders');
       COMMIT;
END;
/

-- Queue a job for rolling forward value data for marked indicators
BEGIN
    -- now and every day afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.RollForward',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'indicator_pkg.RollForward;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MONTHLY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Roll forward data for marked indicators');
       COMMIT;
END;
/

-- Queue a job for rolling forward value data for marked indicators
BEGIN
    -- now and every day afterwards (could possibly be monthly?)
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.CreateNewSheets',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'delegation_pkg.CreateNewSheets;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=DAILY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Create new sheets for delegations');
       COMMIT;
END;
/

-- Queue a job for processing audit module's mapped indicators at the start of each day
BEGIN
    -- now and every day afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.TriggerAuditJobs',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'audit_pkg.TriggerAuditJobs;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=DAILY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Trigger jobs to map audit module data to indicators');
       COMMIT;
END;
/

-- Jobs for SAML integration bits
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.CleanSAMLAssertionCache',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'csr.saml_pkg.CleanAssertionCache;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 03:47 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=DAILY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Clean the SAML assertion cache');

    -- now and every day afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.CleanSAMLRequestLog',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'csr.saml_pkg.CleanRequestLog;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 05:12 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MONTHLY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Clean old SAML request log entries');
       COMMIT;
END;
/

-- job to populate the queue
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.QueueCalcJobs',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'csr.stored_calc_datasource_pkg.QueueCalcJobs;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=SECONDLY;INTERVAL=15',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Scan value change logs and produce jobs for the calculation engine');
END;
/

-- job to mark calc jobs as failed
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.MarkFailedCalcJobs',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'csr.stored_calc_datasource_pkg.MarkFailedJobs;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY;INTERVAL=3',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Mark calc jobs as failed (if they have failed)');
END;
/

-- job to mark batch jobs as failed
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.MarkFailedBatchJobs',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'csr.batch_job_pkg.MarkFailedJobs;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY;INTERVAL=3',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Mark batch jobs as failed (if they have failed)');
END;
/

-- job for adding batch job stats
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.BatchJobStats',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'csr.batch_job_pkg.ComputeJobStats;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 01:43 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=DAILY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Compute aggregate batch job stats');
       COMMIT;
END;
/

BEGIN
	DBMS_SCHEDULER.CREATE_JOB (
		  job_name            => 'csr.EnqueueAutoApprove',
		  job_type            => 'PLSQL_BLOCK',
		  job_action          => 'BEGIN csr.auto_approve_pkg.EnqueueAutoApproveSheets; END;',
		  job_class           => 'low_priority_job',
		  repeat_interval     => 'FREQ=HOURLY',
		  enabled             => FALSE,
		  auto_drop           => FALSE,
		  start_date          => TO_DATE('2000-01-01 01:30:00','yyyy-mm-dd hh24:mi:ss'),
		  comments            => 'Find sheets that can be auto approved and enqueue them for batch job');  
END;
/

-- Queue a job for lazy devs who want an easy way to refresh aggregate ind groups daily
DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every day afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.RefreshDailyGroups',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'csr.aggregate_ind_pkg.RefreshDailyGroups;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 02:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=DAILY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Refresh aggregate ind groups');
       COMMIT;
END;
/

-- job to populate the energy star job queue
DECLARE
    job BINARY_INTEGER;
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.QueueEstJobs',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'csr.energy_star_job_pkg.QueueJobs;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=SECONDLY;INTERVAL=30',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Poll peridically and scan energy star change logs to produce jobs for exchanging data');
END;
/

BEGIN

  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'csr.AutomatedExportImport',
    job_type        => 'PLSQL_BLOCK',
    job_action      => '   
          BEGIN
          csr.automated_export_import_pkg.ScheduleRun();
          commit;
          END;
    ',
	job_class       => 'low_priority_job',
	start_date      => to_timestamp_tz('2015/02/24 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	repeat_interval => 'FREQ=HOURLY',
	enabled         => TRUE,
	auto_drop       => FALSE,
	comments        => 'Schedule for automated export import framework. Check for new imports & exports to queue in batch jobs.');
END;
/

BEGIN
	DBMS_SCHEDULER.CREATE_JOB (
		job_name            => 'csr.RunClientSPs',
		job_type            => 'PLSQL_BLOCK',
		job_action          => 'BEGIN csr.ssp_pkg.RunScheduledStoredProcs(); END;',
		job_class           => 'low_priority_job',
		repeat_interval     => 'FREQ=MINUTELY;INTERVAL=15;',
		enabled             => TRUE,
		auto_drop           => FALSE,
		start_date          => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		comments            => 'Run client store procedures');
END;
/

BEGIN

  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'csr.RaiseUserInactiveRemAlerts',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'csr.csr_user_pkg.RaiseUserInactiveRemAlerts();',
	job_class       => 'LOW_PRIORITY_JOB',
	start_date      => to_timestamp_tz('2015/07/01 03:15 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	repeat_interval => 'FREQ=DAILY',
	enabled         => TRUE,
	auto_drop       => FALSE,
	comments        => 'Generates reminder alerts for inactive user account which are about to be disabled automatically becuase of account policy');

END;
/

-- job to create sheet completeness jobs
DECLARE
    job BINARY_INTEGER;
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.QueueSheetCompletenessJobs',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'csr.sheet_pkg.QueueCompletenessJobs;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=SECONDLY;INTERVAL=120',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Scan sheet change logs and produce sheet completeness batch jobs');
END;
/

DECLARE
    job BINARY_INTEGER;
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.PurgeInactiveEnergyStarErrors',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'csr.energy_star_pkg.PurgeInactiveErrors;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 05:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=DAILY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Deletes inactive energy star errors that are older than a month');
END;
/

BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'csr.BATCHEDEXPORTSCLEARUP',
    job_type        => 'PLSQL_BLOCK',
    job_action      => '   
          BEGIN
          security.user_pkg.logonadmin();
          csr.batch_exporter_pkg.ScheduledFileClearup();
          security.user_pkg.logoff(security.security_pkg.GetAct);
          commit;
          END;
    ',
	job_class       => 'low_priority_job',
	start_date      => to_timestamp_tz('2016/09/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	repeat_interval => 'FREQ=DAILY',
	enabled         => TRUE,
	auto_drop       => FALSE,
	comments        => 'Schedule for removing batched exports file data from the database, so we do not use endless space');
END;
/

BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'csr.BATCHEDIMPORTSCLEARUP',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN
							security.user_pkg.logonadmin();
							csr.batch_importer_pkg.ScheduledFileClearUp;
							security.user_pkg.LogOff(security.security_pkg.GetAct);
							commit;
							END;',
	job_class		=> 'low_priority_job',
	start_date		=> to_timestamp_tz('2016/09/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	repeat_interval	=> 'FREQ=DAILY',
	enabled			=> TRUE,
	auto_drop		=> FALSE,
	comments		=> 'Schedule for removing batched imports file data from the database, so we do not use endless space');
END;
/

BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
	job_name		=> 'csr.MeterRawDataJob',
	job_type		=> 'PLSQL_BLOCK',
	job_action		=> 'BEGIN
							security.user_pkg.logonadmin();
							csr.meter_monitor_pkg.CreateRawDataJobsForApps;
							security.user_pkg.LogOff(security.security_pkg.GetAct);
							commit;
							END;',
	job_class		=> 'low_priority_job',
	start_date		=> to_timestamp_tz('2016/10/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	repeat_interval	=> 'FREQ=DAILY',
	enabled			=> TRUE,
	auto_drop		=> FALSE,
	comments		=> 'Schedule creating meter raw data jobs');
END;
/

BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
	job_name		=> 'csr.MeterMatchJob',
	job_type		=> 'PLSQL_BLOCK',
	job_action		=> 'BEGIN
							security.user_pkg.logonadmin();
							csr.meter_monitor_pkg.CreateMatchJobsForApps;
							security.user_pkg.LogOff(security.security_pkg.GetAct);
							commit;
							END;',
	job_class		=> 'low_priority_job',
	start_date		=> to_timestamp_tz('2016/10/01 03:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	repeat_interval	=> 'FREQ=DAILY',
	enabled			=> TRUE,
	auto_drop		=> FALSE,
	comments		=> 'Schedule creating meter match jobs');
END;
/

BEGIN
	DBMS_SCHEDULER.CREATE_JOB (
		job_name => '"CSR"."ProcessExpiredAuditReports"',
		job_type => 'PLSQL_BLOCK',
		job_action => 'begin security.user_pkg.LogonAdmin; audit_pkg.ProcessExpiredPublicReports; security.user_pkg.Logoff(SYS_CONTEXT(''SECURITY'',''ACT'')); end;',
		number_of_arguments => 0,
		start_date => to_timestamp_tz('2008/01/01 04:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval => 'FREQ=DAILY',
		enabled => TRUE,
		auto_drop => FALSE,
		comments => 'Clear out expired public audit reports');
END;
/

BEGIN
	dbms_scheduler.create_job (
		job_name		=> 'CSR.REFRESH_CALC_WINDOWS',
		job_type		=> 'PLSQL_BLOCK',
		job_action		=> 'BEGIN security.user_pkg.logonadmin(); csr.customer_pkg.RefreshCalcWindows; security.user_pkg.LogOff(security.security_pkg.GetAct); END;',
		job_class		=> 'low_priority_job',
		start_date		=> to_timestamp_tz(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE, 'MONTH'), 1), 'YYYY/MM/DD') || ' 02:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval	=> 'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=1;BYHOUR=02;BYMINUTE=00;BYSECOND=00',
		enabled			=> TRUE,
		auto_drop		=> FALSE,
		comments		=> 'Refresh calculation start/end time window for all customers'
	);
END;
/

BEGIN
	dbms_scheduler.create_job (
		job_name		=> 'CSR.EXPIRE_REMOTE_JOBS',
		job_type		=> 'PLSQL_BLOCK',
		job_action		=> 'csr.meter_processing_job_pkg.ExpireJobs;',
		job_class		=> 'low_priority_job',
		start_date		=> to_timestamp_tz('2018/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval	=> 'FREQ=MINUTELY;INTERVAL=10',
		enabled			=> TRUE,
		auto_drop		=> FALSE,
		comments		=> 'Roll-back or expire meter processing jobs that are no longer locked but in a processing status'
	);
END;
/

BEGIN
	dbms_scheduler.create_job (
		job_name		=> 'CSR.ARCHIVE_OLD_FL_IT_GEN_ALER',
		job_type		=> 'PLSQL_BLOCK',
		job_action		=> 'csr.flow_pkg.ArchiveOldFlowItemGenEntries;',
		job_class		=> 'low_priority_job',
		start_date		=> to_timestamp_tz('2019/03/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval	=>  'FREQ=DAILY;INTERVAL=1;BYDAY=SAT;', -- every Saturday midnight
		enabled			=> TRUE,
		auto_drop		=> FALSE,
		comments		=> 'Archive processed flow item alert entries'
	);
END;
/

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
END;
/
