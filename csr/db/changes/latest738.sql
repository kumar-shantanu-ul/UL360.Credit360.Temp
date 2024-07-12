-- Please update version.sql too -- this keeps clean builds in sync
define version=738
@update_header

CREATE TABLE csr.saml_assertion_cache
(
	app_sid							number(10) default sys_context('security', 'app') not null,
	assertion_id					varchar2(4000) not null,
	expires							date,
	constraint pk_saml_assertion_cache primary key (app_sid, assertion_id)
);

CREATE TABLE csr.saml_assertion_log
(
	app_sid							number(10) default sys_context('security', 'app') not null,
	saml_request_id					number(10) not null,
	received_dtm					date default sysdate not null,
	saml_assertion					clob,
	constraint pk_saml_assertion_log primary key (app_sid, saml_request_id)
);

CREATE TABLE csr.saml_log
(
	app_sid							number(10) default sys_context('security', 'app') not null,
	saml_request_id					number(10) not null,
	message_sequence				number(10) not null,
	message							varchar2(4000),
	log_dtm							date default sysdate not null,
	constraint pk_saml_log primary key (app_sid, saml_request_id, message_sequence)
);

CREATE SEQUENCE csr.saml_request_id_seq;

DECLARE
    job BINARY_INTEGER;
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


DECLARE
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
BEGIN	
	v_list := t_tabs(
		'SAML_ASSERTION_CACHE',
		'SAML_ASSERTION_LOG',
		'SAML_LOG'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
					if v_i = 1 then
						v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
					else
						v_name := SUBSTR(v_list(i), 1, 21)||'_POLICY_'||v_i;
					end if;
					dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => 'CSR',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'CSR',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive );
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
				end;
			end loop;
		end;
	end loop;
END;
/

@..\saml_pkg
@..\saml_body
grant execute on csr.saml_pkg to web_user;

@update_tail
