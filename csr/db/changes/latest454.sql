-- Please update version.sql too -- this keeps clean builds in sync
define version=454
@update_header

declare
	v_exists number;
begin
	select count(*)
	  into v_exists
	  from user_constraints
	 where constraint_name='PK_ISSUE_LOG_ALERT_BATCH_RUN';
	if v_exists = 0 then
		execute immediate 'alter table ISSUE_LOG_ALERT_BATCH_RUN add CONSTRAINT PK_ISSUE_LOG_ALERT_BATCH_RUN PRIMARY KEY (APP_SID)';
	end if;
end;
/

@update_tail
