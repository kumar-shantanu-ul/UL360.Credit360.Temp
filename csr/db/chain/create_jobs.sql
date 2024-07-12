-- Queue a job for processing questionnaires expiring running hourly
DECLARE
    job BINARY_INTEGER;
BEGIN
    -- every hour
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'chain.ExpireQuestionnaires',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'questionnaire_pkg.ExpireQuestionnaires;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=HOURLY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Trigger jobs to expire questionnaires');
       COMMIT;
END;
/

-- Queue a job for RunChainJobs (UpdateExpirations, CheckForOverdueQuestionnaires, UpdateTasksForReview) running hourly
DECLARE
    job BINARY_INTEGER;
BEGIN
    -- every hour
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'chain.RunChainJobs',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'scheduled_alert_pkg.RunChainJobs;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=HOURLY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Triggers job for running chain jobs');
       COMMIT;
END;
/

-- Queue a job for filter caching, removing expired caches, running every 10 minutes
DECLARE
    job BINARY_INTEGER;
BEGIN
    -- every 10 minutes
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'chain.RunFilterExpiry',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'filter_pkg.RemoveExpiredCaches;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY;INTERVAL=10',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Triggers job for running chain jobs');
       COMMIT;
END;
/


-- Queue a job for preprocessing chain company fields before dedupe
DECLARE
    job BINARY_INTEGER;
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
        job_name        => 'chain.DedupePreprocessing',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'chain.dedupe_preprocess_pkg.RunPreprocessJob;',
        job_class       => 'low_priority_job',
        start_date      => to_timestamp_tz('2008/01/01 05:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
        repeat_interval => 'FREQ=HOURLY;',
        enabled         => TRUE,
        auto_drop       => FALSE,
        comments        => 'Create Dedupe preprocessing batch job');
END;
/
