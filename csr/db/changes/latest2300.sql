-- Please update version.sql too -- this keeps clean builds in sync
define version=2300
@update_header

CREATE TABLE CSR.TPL_REPORT_SCHEDULE (
	app_sid						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	schedule_sid				NUMBER(10) NOT NULL,
	tpl_report_sid				NUMBER(10) NOT NULL,
	owner_user_sid				NUMBER(10) NOT NULL,
	name						VARCHAR2(1023) NOT NULL,
	region_selection_type_id	NUMBER(10) NOT NULL,
	region_selection_tag_id		NUMBER(10) DEFAULT NULL,
	include_inactive_regions	NUMBER(1) DEFAULT 0 NOT NULL,
	one_report_per_region		NUMBER(1) DEFAULT 0 NOT NULL,
	schedule_xml				CLOB DEFAULT EMPTY_CLOB() NOT NULL,
	offset						NUMBER(10) DEFAULT 0,
	use_unmerged				NUMBER (1) DEFAULT 0 NOT NULL,
	output_as_pdf				NUMBER(1) DEFAULT 0 NOT NULL,
	role_sid					NUMBER(10),
	email_owner_on_complete		NUMBER(1) DEFAULT 0 NOT NULL,
	doc_folder_sid				NUMBER(10),
	overwrite_existing			NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT pk_tpl_report_sched PRIMARY KEY (app_sid, schedule_sid)
	USING INDEX,
	CONSTRAINT fk_tpl_report_sched_tpl_rep FOREIGN KEY (app_sid, tpl_report_sid)
	REFERENCES CSR.TPL_REPORT(app_sid, tpl_report_sid),
	CONSTRAINT fk_tpl_report_sched_owner FOREIGN KEY (app_sid, owner_user_sid)
	REFERENCES CSR.CSR_USER(app_sid, csr_user_sid),
	CONSTRAINT fk_tpl_rep_sched_reg_sel_type FOREIGN KEY (region_selection_type_id)
	REFERENCES CSR.REGION_SELECTION_TYPE(region_selection_type_id),
	CONSTRAINT fk_tpl_rep_sched_region_tag FOREIGN KEY (app_sid, region_selection_tag_id)
	REFERENCES CSR.TAG(app_sid, tag_id),
	CONSTRAINT chk_tpl_rep_incl_inact_reg CHECK (include_inactive_regions IN (0,1)),
	CONSTRAINT chk_tpl_rep_one_report_per CHECK (one_report_per_region IN (0,1)),
	CONSTRAINT chk_tpl_rep_use_unmerged CHECK (use_unmerged IN (0,1)),
	CONSTRAINT chk_tpl_rep_output_as_pdf CHECK (output_as_pdf IN (0,1)),
	CONSTRAINT fk_tpl_report_sched_role FOREIGN KEY (app_sid, role_sid)
	REFERENCES CSR.ROLE(app_sid, role_sid),
	CONSTRAINT chk_tpl_rep_email_owner CHECK (email_owner_on_complete IN (0,1)),
	CONSTRAINT fk_tpl_report_sched_doc_lib FOREIGN KEY (app_sid, doc_folder_sid)
	REFERENCES CSR.DOC_FOLDER(app_sid, doc_folder_sid),
	CONSTRAINT chk_tpl_rep_overwrite_doc CHECK (overwrite_existing IN (0,1))
);

CREATE TABLE CSR.TPL_REPORT_SCHEDULE_REGION (
	app_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	schedule_sid		NUMBER(10) NOT NULL,
	region_sid			NUMBER(10) NOT NULL,
	pos					NUMBER(10) NOT NULL,
	CONSTRAINT fk_tpl_report_sched_region FOREIGN KEY (app_sid, region_sid)
	REFERENCES CSR.REGION(app_sid, region_sid),
	CONSTRAINT fk_tpl_rep_sched_region_sched FOREIGN KEY (app_sid, schedule_sid)
	REFERENCES CSR.TPL_REPORT_SCHEDULE(app_sid, schedule_sid)
);

CREATE TABLE CSR.TPL_REPORT_SCHED_BATCH_RUN (
	app_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	schedule_sid		NUMBER(10) NOT NULL,
	next_fire_time		TIMESTAMP(6) DEFAULT NULL,
	CONSTRAINT pk_tpl_rep_sched_batch_sched PRIMARY KEY (app_sid, schedule_sid)
	USING INDEX
);

CREATE TABLE CSR.TPL_REPORT_SCHED_SAVED_DOC (
	app_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	schedule_sid		NUMBER(10) NOT NULL,
	doc_id				NUMBER(10) NOT NULL,
	region_sid			NUMBER(10) DEFAULT NULL,
	CONSTRAINT fk_tpl_rep_sched_sched_sid FOREIGN KEY (app_sid, schedule_sid)
	REFERENCES CSR.TPL_REPORT_SCHEDULE(app_sid, schedule_sid),
	CONSTRAINT fk_tpl_rep_sched_doc_sid FOREIGN KEY (app_sid, doc_id)
	REFERENCES CSR.DOC(app_sid, doc_id),
	CONSTRAINT fk_tpl_rep_sched_region FOREIGN KEY (app_sid, region_sid)
	REFERENCES CSR.REGION(app_sid, region_sid)
);

ALTER TABLE CSR.BATCH_JOB_TEMPLATED_REPORT
  ADD schedule_sid NUMBER(10);

ALTER TABLE CSR.BATCH_JOB_TEMPLATED_REPORT
  ADD CONSTRAINT fk_batch_tpl_report_schedule 
         FOREIGN KEY (app_sid, schedule_sid)
      REFERENCES CSR.TPL_REPORT_SCHEDULE(app_sid, schedule_sid);

@../templated_report_schedule_pkg
@../templated_report_schedule_body

DECLARE
    v_id    NUMBER(10);
BEGIN   
    security.user_pkg.logonadmin;
    security.class_pkg.CreateClass(SYS_CONTEXT('SECURITY','ACT'), null, 'CSRTemplatedReportsSchedule', 'csr.templated_report_schedule_pkg', null, v_Id);
EXCEPTION
    WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
        NULL;
END;
/
	  
DECLARE
	v_default_alert_frame_id	NUMBER;
	v_success_alert_type_id		NUMBER := 64;
	v_failed_alert_type_id		NUMBER := 65;
BEGIN

	/* RLS */
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'TPL_REPORT_SCHEDULE',
		policy_name     => 'TPL_REP_SCHED_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
	
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'TPL_REPORT_SCHEDULE_REGION',
		policy_name     => 'TPL_REP_SCHED_REGION_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
	
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'TPL_REPORT_SCHED_BATCH_RUN',
		policy_name     => 'TPL_REP_SCHED_BATCH_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
	
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'TPL_REPORT_SCHED_SAVED_DOC',
		policy_name     => 'TPL_REP_SCHED_DOC_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
		
	--ALERTS
	--Success
	INSERT INTO CSR.STD_ALERT_TYPE (std_alert_type_id, description, send_trigger, sent_from) 
			VALUES(v_success_alert_type_id, 'Schedule report completed', 
				'Sent when a scheduled report successfully completes.',
				'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
			);

	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_success_alert_type_id, 0, 'FROM_NAME', 'From name', 'The name of the schedule owner', 1);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_success_alert_type_id, 0, 'FROM_EMAIL', 'From email', 'The email of the schedule owner', 2);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_success_alert_type_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 3);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_success_alert_type_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 4);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_success_alert_type_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 5);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_success_alert_type_id, 0, 'TEMPLATE_NAME', 'Template name', 'The name of the template useed for the report', 6);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_success_alert_type_id, 0, 'SCHEDULE_NAME', 'Schedule name', 'The name of the schedule which caused the report to be generated', 7);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_success_alert_type_id, 0, 'REPORT_URL', 'Report URL', 'Link to the generated report', 8);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_success_alert_type_id, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);
	
	SELECT MAX (default_alert_frame_id) INTO v_default_alert_frame_id FROM CSR.DEFAULT_ALERT_FRAME;
	INSERT INTO CSR.DEFAULT_ALERT_TEMPLATE
		(std_alert_type_id, default_alert_frame_id, send_type) 
	VALUES 
		(v_success_alert_type_id, v_default_alert_frame_id, 'manual');		

	INSERT INTO CSR.DEFAULT_ALERT_TEMPLATE_BODY (STD_ALERT_TYPE_ID,LANG,SUBJECT,BODY_HTML,ITEM_HTML) VALUES (v_success_alert_type_id,'en',
		'<template>A scheduled report has been generated for you in CRedit360</template>',
		'<template>
		<p>Hello,</p>
		<p>You are receiving this email because a schedule report has been generated for you.</p>
		<p>The schedule named <mergefield name="SCHEDULE_NAME" /> successfully ran and generated a report for you to view.</p>
		<p>To view the report, please go to this web page:</p>
		<p><mergefield name="REPORT_URL" /></p>
		<p>(If you think you should not be receiving this email, or you have any questions about it, then please forward it to <a href="mailto:support@credit360.com">support@credit360.com</a>).</p>
		</template>',
		'<template/>'
		);
    
    
    --Failure
  INSERT INTO CSR.STD_ALERT_TYPE (std_alert_type_id, description, send_trigger, sent_from) 
			VALUES(v_failed_alert_type_id, 'Schedule report failed', 
				'Sent when a scheduled report fails to run.',
				'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
			);

	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_failed_alert_type_id, 0, 'FROM_NAME', 'From name', 'The name of the schedule owner', 1);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_failed_alert_type_id, 0, 'FROM_EMAIL', 'From email', 'The email of the schedule owner', 2);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_failed_alert_type_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 3);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_failed_alert_type_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 4);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_failed_alert_type_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 5);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_failed_alert_type_id, 0, 'TEMPLATE_NAME', 'Template name', 'The name of the template useed for the report', 6);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_failed_alert_type_id, 0, 'SCHEDULE_NAME', 'Schedule name', 'The name of the schedule which caused the report to be generated', 7);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_failed_alert_type_id, 0, 'ERROR_MES', 'Error message', 'A summary of why the report failed to run', 8);
	INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_failed_alert_type_id, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);
	
	SELECT MAX (default_alert_frame_id) INTO v_default_alert_frame_id FROM CSR.DEFAULT_ALERT_FRAME;
	INSERT INTO CSR.DEFAULT_ALERT_TEMPLATE
		(std_alert_type_id, default_alert_frame_id, send_type) 
	VALUES 
		(v_failed_alert_type_id, v_default_alert_frame_id, 'manual');		

	INSERT INTO CSR.DEFAULT_ALERT_TEMPLATE_BODY (STD_ALERT_TYPE_ID,LANG,SUBJECT,BODY_HTML,ITEM_HTML) VALUES (v_failed_alert_type_id,'en',
		'<template>A scheduled report has failed to run</template>',
		'<template>
		<p>Hello,</p>
		<p>You are receiving this email because a schedule report you were due to recieve has failed to run successfully..</p>
		<p>The schedule named <mergefield name="SCHEDULE_NAME" /> for templated report <mergefield name="TEMPLATE_NAME" /> failed with the following message;</p>
		<p><mergefield name="ERROR_MES" /></p>
		<p>If you are unable to resolve this issue yourself, or think you should not be recieving this email, then please forward it to <a href="mailto:support@credit360.com">support@credit360.com</a>).</p>
		</template>',
		'<template/>'
		);
    
    
    --Add template for all customers
    FOR r IN (
		SELECT c.app_sid
		  FROM csr.customer c
	) LOOP
		BEGIN
			INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
			VALUES (r.app_sid, csr.customer_alert_type_id_seq.nextval, v_success_alert_type_id);
			
			INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
			VALUES (r.app_sid, csr.customer_alert_type_id_seq.nextval, v_failed_alert_type_id);

			INSERT INTO csr.alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
			SELECT r.app_sid, cat.customer_alert_type_id, MIN(af.alert_frame_id), 'manual'
			  FROM csr.alert_frame af
			  JOIN csr.customer_alert_type cat ON af.app_sid = cat.app_sid
			 WHERE af.app_sid = r.app_sid
			   AND cat.std_alert_type_id IN (v_success_alert_type_id, v_failed_alert_type_id)
			 GROUP BY cat.customer_alert_type_id
			HAVING MIN(af.alert_frame_id) > 0;			
			
			INSERT INTO csr.alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
			SELECT r.app_sid, cat.customer_alert_type_id, t.lang, d.subject, d.body_html, d.item_html
			  FROM csr.default_alert_template_body d
			  JOIN csr.customer_alert_type cat ON d.std_alert_type_id = cat.std_alert_type_id
			  JOIN csr.alert_template at ON at.customer_alert_type_id = cat.customer_alert_type_id AND at.app_sid = cat.app_sid
			  CROSS JOIN aspen2.translation_set t
			 WHERE d.std_alert_type_id IN (v_success_alert_type_id, v_failed_alert_type_id)
			   AND d.lang='en'
			   AND t.application_sid = r.app_sid
			   AND cat.app_sid = r.app_sid;
		EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
		END;
	END LOOP;
END;

/

@../batch_job_pkg
@../batch_job_body
@../csr_data_pkg
@../csr_user_body
@../doc_body
@../doc_folder_body
@../region_pkg
@../region_body
@../templated_report_pkg
@../templated_report_body
@../templated_report_schedule_pkg
@../templated_report_schedule_body

grant execute on csr.templated_report_schedule_pkg to web_user;
grant execute on csr.templated_report_schedule_pkg to security;

@update_tail