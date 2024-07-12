define version=1998
@update_header

insert into csr.batch_job_type (batch_job_type_id, description, plugin_name)
values (8, 'Templated Report', 'templated-report');

CREATE TABLE csr.batch_job_templated_report(
	APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	BATCH_JOB_ID					NUMBER(10, 0)	NOT NULL,
	TEMPLATED_REPORT_REQUEST_XML	XMLTYPE			NOT NULL,
	USER_SID						NUMBER(10, 0)	NOT NULL,
	REPORT_DATA						BLOB			NULL,
	CONSTRAINT pk_batch_job_tpl_report PRIMARY KEY (app_sid, batch_job_id)
);

ALTER TABLE CSR.BATCH_JOB_TEMPLATED_REPORT ADD CONSTRAINT fk_bj_tpl_report_bj
FOREIGN KEY (app_sid, batch_job_id)
REFERENCES csr.batch_job(app_sid, batch_job_id) ON DELETE CASCADE;

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	BEGIN
		dbms_rls.add_policy(
			object_schema   => 'CSR',
			object_name     => 'BATCH_JOB_TEMPLATED_REPORT',
			policy_name     => 'BATCH_JOB_TPL_REPORT_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive 
		);
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			NULL;
		WHEN FEATURE_NOT_ENABLED THEN
			dbms_output.put_line('RLS policies not applied for "CSR.BATCH_JOB_TEMPLATED_REPORT" as feature not enabled');
	END;
END;
/

@..\batch_job_pkg
@..\batch_job_body
@..\templated_report_pkg
@..\templated_report_body

@update_tail