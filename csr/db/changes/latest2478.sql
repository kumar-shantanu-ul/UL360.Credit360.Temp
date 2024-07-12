-- Please update version.sql too -- this keeps clean builds in sync
define version=2478
@update_header

--Drop the old job against UPD

declare
   job_doesnt_exist EXCEPTION;
   PRAGMA EXCEPTION_INIT( job_doesnt_exist, -27475 );
begin
   dbms_scheduler.drop_job(job_name => 'CmsDataImport');
exception when job_doesnt_exist then
   null;
end;
/

/*----------------------------------------------------------------------------------
-- Setup the schedule to create import jobs - Against CSR
----------------------------------------------------------------------------------*/

BEGIN

  DBMS_SCHEDULER.create_job (
    job_name        => 'csr.CmsDataImport',
    job_type        => 'PLSQL_BLOCK',
    job_action      => '   
          BEGIN
          csr.user_pkg.logonadmin();
          csr.cms_data_imp_pkg.ScheduleRun();
          commit;
          END;
    ',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'freq=daily; byhour=2; byminute=0; bysecond=0;',
    end_date        => NULL,
    enabled         => TRUE,
    comments        => 'Cms data import schedule');

END;
/

@update_tail