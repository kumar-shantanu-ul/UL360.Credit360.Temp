-- Please update version.sql too -- this keeps clean builds in sync
define version=297
@update_header

begin
	for r in (select constraint_name from user_constraints where table_name='ISSUE_LOG_ALERT_BATCH_RUN' and r_constraint_name='PK_CUSTOMER') loop
		execute immediate 'alter table issue_log_alert_batch_run drop constraint '||r.constraint_name;
	end loop;
end;
/

alter table issue_log_Alert_batch add
    CONSTRAINT PK_ISSUE_LOG_ALERT_BATCH PRIMARY KEY (APP_SID)
using index tablespace indx;

delete from issue_log_alert_batch_run where app_sid not in (select app_sid from issue_log_alert_batch);

ALTER TABLE ISSUE_LOG_ALERT_BATCH_RUN ADD CONSTRAINT RefISSUE_LOG_ALERT_BATCH1105 
    FOREIGN KEY (APP_SID)
    REFERENCES ISSUE_LOG_ALERT_BATCH(APP_SID) ;

@update_tail
