-- Please update version.sql too -- this keeps clean builds in sync
define version=1457
@update_header

CREATE SEQUENCE CSR.BATCH_JOB_ID_SEQ;
CREATE SEQUENCE CSR.DELEG_PLAN_SYNC_JOB_ID_SEQ;

CREATE TABLE CSR.DELEG_PLAN_SYNC_JOB
(
    APP_SID             			NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
 	DELEG_PLAN_SYNC_JOB_ID   		NUMBER(10) NOT NULL,
 	DELEGATION_SID					NUMBER(10) NOT NULL,
 	CONSTRAINT PK_DELEG_PLAN_SYNC_JOB PRIMARY KEY (APP_SID, DELEG_PLAN_SYNC_JOB_ID),
 	CONSTRAINT FK_DLG_PLAN_SYNC_JOB_MAST_DLG FOREIGN KEY (APP_SID, DELEGATION_SID)
 	REFERENCES CSR.MASTER_DELEG (APP_SID, DELEGATION_SID)
);
CREATE INDEX CSR.IX_DELEG_PLAN_SYNC_JOB_DELEG ON CSR.DELEG_PLAN_SYNC_JOB (APP_SID, DELEGation_sid);

CREATE TABLE CSR.BATCH_JOB_TYPE(
	BATCH_JOB_TYPE_ID				NUMBER(10) NOT NULL,
	DESCRIPTION						VARCHAR2(500) NOT NULL,
	SP								VARCHAR2(100),
	PLUGIN_NAME						VARCHAR2(500),
	CONSTRAINT PK_BATCH_JOB_TYPE PRIMARY KEY (BATCH_JOB_TYPE_ID),
	CONSTRAINT CK_BATCH_JOB_TYPE_CODE_TYPE CHECK ( (SP IS NULL AND PLUGIN_NAME IS NOT NULL) OR (SP IS NOT NULL AND PLUGIN_NAME IS NULL) )
);

begin
	insert into csr.batch_job_type (batch_job_type_id, description, sp)
	values (1, 'Delegation plan synchronisation', 'csr.deleg_plan_pkg.ProcessSyncDelegWithMasterJob');
end;
/

CREATE TABLE CSR.BATCH_JOB(
    APP_SID             			NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    BATCH_JOB_ID        			NUMBER(10, 0)    NOT NULL,
    BATCH_JOB_TYPE_ID				NUMBER(10, 0)	 NOT NULL,
    DESCRIPTION						VARCHAR2(500),
    REQUESTED_BY_USER_SID			NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','SID') NOT NULL,
    REQUESTED_DTM					DATE             DEFAULT SYSDATE NOT NULL,
    EMAIL_ON_COMPLETION				NUMBER(1)		 DEFAULT 0 NOT NULL,
    STARTED_DTM						DATE,
    COMPLETED_DTM					DATE,    
    UPDATED_DTM         			DATE             DEFAULT SYSDATE NOT NULL,
    RETRY_DTM						DATE,
    WORK_DONE           			NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    TOTAL_WORK          			NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    RUNNING_ON          			VARCHAR2(256),
 	DELEG_PLAN_SYNC_JOB_ID   		NUMBER(10),
    CONSTRAINT PK_BATCH_JOB PRIMARY KEY (APP_SID, BATCH_JOB_ID),
    CONSTRAINT FK_BATCH_JOB_BATCH_JOB_TYPE FOREIGN KEY (BATCH_JOB_TYPE_ID)
    REFERENCES CSR.BATCH_JOB_TYPE (BATCH_JOB_TYPE_ID),
    CONSTRAINT FK_BATCH_JOB_DLG_PLN_SYNC_JOB FOREIGN KEY (APP_SID, DELEG_PLAN_SYNC_JOB_ID)
    REFERENCES CSR.DELEG_PLAN_SYNC_JOB(APP_SID, DELEG_PLAN_SYNC_JOB_ID),
    CONSTRAINT FK_BATCH_JOB_CSR_USER FOREIGN KEY (APP_SID, REQUESTED_BY_USER_SID)
    REFERENCES CSR.CSR_USER (APP_SID, CSR_USER_SID),
    CONSTRAINT CK_BATCH_JOB_DLG_PLAN_EMAIL CHECK (EMAIL_ON_COMPLETION IN (0,1)),
    -- similar to the issues one where one and only one of the type fields is set
    CONSTRAINT CK_BATCH_JOB_TYPE CHECK (
    	( BATCH_JOB_TYPE_ID = 1 AND DELEG_PLAN_SYNC_JOB_ID IS NOT NULL )
    	-- adding a job type makes this:
    	-- or ( BATCH_JOB_TYPE_ID = 1 AND DELEG_PLAN_SYNC_JOB_ID IS NOT NULL AND NEW_JOB_SPECIFIC_ID IS NULL )
    	-- or ( BATCH_JOB_TYPE_ID = 2 AND DELEG_PLAN_SYNC_JOB_ID IS NULL AND NEW_JOB_SPECIFIC_ID IS NOT NULL )
    	-- etc
    )
);
CREATE INDEX CSR.IX_BATCH_JOB_BATCH_JOB_TYPE ON CSR.BATCH_JOB(BATCH_JOB_TYPE_ID);
CREATE INDEX CSR.IX_BATCH_JOB_REQ_USER_SID ON CSR.BATCH_JOB(APP_SID, REQUESTED_BY_USER_SID);
CREATE INDEX CSR.IX_BATCH_JOB_DLG_PLAN_JOB ON CSR.BATCH_JOB(APP_SID, DELEG_PLAN_SYNC_JOB_ID);

CREATE OR REPLACE TYPE CSR.T_BATCH_JOB_QUEUE_ENTRY AS OBJECT (
	BATCH_JOB_ID NUMBER(10)
);
/

CREATE OR REPLACE VIEW CSR.v$batch_job AS
	SELECT bj.app_sid, bj.batch_job_id, bj.batch_job_type_id, bj.description,
		   bjt.description batch_job_type_description, bj.requested_by_user_sid,
	 	   cu.full_name requested_by_full_name, cu.email requested_by_email, bj.requested_dtm,
	 	   bj.email_on_completion, bj.started_dtm, bj.completed_dtm, bj.updated_dtm, bj.retry_dtm,
	 	   bj.work_done, bj.total_work, bj.running_on
      FROM batch_job bj, batch_job_type bjt, csr_user cu
     WHERE bj.app_sid = cu.app_sid AND bj.requested_by_user_sid = cu.csr_user_sid
       AND bj.batch_job_type_id = bjt.batch_job_type_id;

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'BATCH_JOB',
		'DELEG_PLAN_SYNC_JOB'
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
				    -- dbms_output.put_line('done  '||v_name);
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
				end;
			end loop;
		end;
	end loop;
end;
/

-- create a queue for batch jobs
BEGIN
	DBMS_AQADM.CREATE_QUEUE_TABLE (
		queue_table        => 'csr.batch_job_queue',
		queue_payload_type => 'csr.t_batch_job_queue_entry',
		sort_list		   => 'priority,enq_time'
	);
	DBMS_AQADM.CREATE_QUEUE (
		queue_name  => 'csr.batch_job_queue',
		queue_table => 'csr.batch_job_queue'
	);
	DBMS_AQADM.START_QUEUE (
		queue_name => 'csr.batch_job_queue'
	);
END;
/

declare
	v_default_alert_frame_id csr.default_alert_frame.default_alert_frame_id%TYPE;
	v_alert_frame_id csr.alert_frame.alert_frame_id%TYPE;
	v_capabilities_sid security.security_pkg.T_SID_ID;
	v_capability_sid security.security_pkg.T_SID_ID;
	v_cat csr.customer_alert_type.customer_alert_type_id%TYPE;
	v_has_en number;
	v_has_en_gb number;
	v_lang varchar2(10);
begin
	security.user_pkg.logonadmin;

	INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (43, 'Batch job completed',
		'A batch job has completed successfully.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
	);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (43, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (43, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (43, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (43, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 4);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (43, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (43, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (43, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 7);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (43, 0, 'JOB_TYPE', 'Job type', 'The type of the batch job that has completed', 8);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (43, 0, 'JOB_DESCRIPTION', 'Job description', 'A description of the batch job that has completed', 9);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (43, 0, 'JOB_RESULT', 'Job result', 'The result of running the job', 10);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (43, 0, 'JOB_URL', 'Result link', 'A hyperlink to the job results, if applicable, or to the main website if not', 11);

	SELECT MIN(default_alert_frame_id)
	  INTO v_default_alert_frame_id
	  FROM csr.default_alert_frame;
	IF v_default_alert_frame_id IS NOT NULL THEN
		INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (43, v_default_alert_frame_id, 'automatic');
		INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (43, 'en',
			'<template>A batch job has completed</template>',
			'<template><p>Hello,</p>'||
			'<p>You are receiving this e-mail because a batch job type '||chr(38)||'quot;<mergefield name="JOB_TYPE"/>'||chr(38)||
			'quot; and description '||chr(38)||'quot;<mergefield name="JOB_DESCRIPTION"/>'||chr(38)||'quot; that you '||
			'submitted has completed with result '||chr(38)||'quot;<mergefield name="JOB_RESULT"/>'||chr(38)||'quot;.</p>'||
			'<p/>'||
			'<p>You can view the results of the job (if applicable) by going to this web page:</p>'||
			'<p><mergefield name="JOB_URL"/></p>'||
			'<p>(If you think you shouldn'||CHR(38)||'apos;t be receiving this e-mail, or you have any questions about it, then please forward it to support@credit360.com).</p></template>',
			'<template/>');
	END IF;
	
	INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
		SELECT app_sid, csr.customer_alert_type_id_seq.nextval, 43
		  FROM csr.customer;

	for r in (select app_sid from csr.customer) loop
		select min(alert_frame_id)
		  into v_alert_frame_id
		  from csr.alert_frame
		 where app_sid = r.app_sid
		   and lower(name)='default';
		if v_alert_frame_id is null then
			select min(alert_frame_id)
			  into v_alert_frame_id
			  from csr.alert_frame
			 where app_sid = r.app_sid;
		end if;
		v_lang := null;
		select count(*)
		  into v_has_en
		  from aspen2.translation_set
		 where application_sid = r.app_sid and lang='en';
		if v_has_en > 0 then
			v_lang := 'en';
		else
			select count(*)
			  into v_has_en_gb
			  from aspen2.translation_set
			 where application_sid = r.app_sid and lang='en-gb';
			if v_has_en_gb > 0 then
				v_lang := 'en_gb';
			end if;
		end if;
		if v_alert_frame_id is not null and v_lang is not null then
			select customer_alert_type_id
			  into v_cat
			  from csr.customer_alert_type
			 where app_sid = r.app_sid and std_alert_type_id=43;
			 
			INSERT INTO CSR.alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
			VALUES (r.app_sid, v_cat, v_alert_frame_id, 'automatic');
		
			INSERT INTO csr.alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
			VALUES (r.app_sid, v_cat, v_lang,
				'<template>A batch job has completed</template>',
				'<template><p>Hello,</p>'||
				'<p>You are receiving this e-mail because a batch job type '||chr(38)||'quot;<mergefield name="JOB_TYPE"/>'||chr(38)||
				'quot; and description '||chr(38)||'quot;<mergefield name="JOB_DESCRIPTION"/>'||chr(38)||'quot; that you '||
				'submitted has completed with result '||chr(38)||'quot;<mergefield name="JOB_RESULT"/>'||chr(38)||'quot;.</p>'||
				'<p/>'||
				'<p>You can view the results of the job (if applicable) by going to this web page:</p>'||
				'<p><mergefield name="JOB_URL"/></p>'||
				'<p>(If you think you shouldn'||CHR(38)||'apos;t be receiving this e-mail, or you have any questions about it, then please forward it to support@credit360.com).</p></template>',
				'<template/>');			
		end if;

		security.security_pkg.setapp(r.app_sid);
	    -- just create a sec obj of the right type in the right place
	    BEGIN
			v_capabilities_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
					SYS_CONTEXT('SECURITY','APP'), 
					security.security_pkg.SO_CONTAINER,
					'Capabilities',
					v_capabilities_sid
				);
		END;
		begin
			security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
				v_capabilities_sid, 
				security.class_pkg.GetClassId('CSRCapability'),
				'Manage jobs',
				v_capability_sid
			);
		exception
			when security.security_pkg.duplicate_object_name then
				null;
		end;
		security.security_pkg.setapp(null);
		
	end loop;
end;
/

create or replace package csr.batch_job_pkg as
end;
/
grant execute on csr.batch_job_pkg to web_user;

INSERT INTO csr.capability (name, allow_by_default) VALUES ('Manage jobs', 0);

@../batch_job_pkg
@../batch_job_body
@../deleg_plan_pkg
@../deleg_plan_body

@update_tail
