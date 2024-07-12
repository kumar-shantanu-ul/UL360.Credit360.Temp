-- Please update version.sql too -- this keeps clean builds in sync
define version=2755
define minor_version=23
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.std_alert_type_group (
	std_alert_type_group_id						NUMBER(10)		NOT NULL,
	description									VARCHAR(255)	NOT NULL,
	CONSTRAINT pk_std_alert_type_group 			PRIMARY KEY (std_alert_type_group_id)
);

CREATE TABLE csr.user_inactive_sys_alert (
	app_sid										NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	user_inactive_sys_alert_id					NUMBER(10)		NOT NULL,
	notify_user_sid								NUMBER(10)		NOT NULL,
	sent_dtm									DATE,
	CONSTRAINT pk_user_inactive_sys_alert 		PRIMARY KEY (app_sid, user_inactive_sys_alert_id)
);

CREATE TABLE csr.user_inactive_man_alert (
	app_sid										NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	user_inactive_man_alert_id					NUMBER(10)		NOT NULL,
	notify_user_sid								NUMBER(10)		NOT NULL,
	sent_dtm									DATE,
	CONSTRAINT pk_user_inactive_man_alert 		PRIMARY KEY (app_sid, user_inactive_man_alert_id)
);

CREATE TABLE csr.user_inactive_rem_alert (
	app_sid										NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	user_inactive_rem_alert_id					NUMBER(10)		NOT NULL,
	notify_user_sid								NUMBER(10)		NOT NULL,
	sent_dtm									DATE,
	CONSTRAINT pk_user_inactive_rem_alert 		PRIMARY KEY (app_sid, user_inactive_rem_alert_id)
);

-- Alter tables
ALTER TABLE csr.user_inactive_sys_alert
  ADD CONSTRAINT fk_inactive_sys_alert_csr_user FOREIGN KEY (app_sid, notify_user_sid)
	  REFERENCES csr.csr_user (app_sid, csr_user_sid);

ALTER TABLE csr.user_inactive_man_alert
  ADD CONSTRAINT fk_inactive_man_alert_csr_user FOREIGN KEY (app_sid, notify_user_sid)
	  REFERENCES csr.csr_user (app_sid, csr_user_sid);

ALTER TABLE csr.user_inactive_rem_alert
  ADD CONSTRAINT fk_inactive_rem_alert_csr_user FOREIGN KEY (app_sid, notify_user_sid)
	  REFERENCES csr.csr_user (app_sid, csr_user_sid);

ALTER TABLE csr.alert_template
 DROP CONSTRAINT CK_ALERT_TEMPLATE_SEND_TYPE;

ALTER TABLE csr.alert_template
  ADD CONSTRAINT CK_ALERT_TEMPLATE_SEND_TYPE
	  CHECK (SEND_TYPE IN ('manual', 'automatic', 'inactive'));

ALTER TABLE csr.customer
  ADD ntfy_days_before_user_inactive NUMBER(10) DEFAULT 15 NOT NULL;

ALTER TABLE csrimp.customer
  ADD ntfy_days_before_user_inactive NUMBER(10) NULL;

ALTER TABLE csr.std_alert_type
  ADD std_alert_type_group_id NUMBER(10) NULL;

ALTER TABLE csr.std_alert_type
  ADD override_template_send_type NUMBER(1) DEFAULT 0 NOT NULL;
  
ALTER TABLE csr.std_alert_type
  ADD CONSTRAINT fk_std_alert_type_alert_group FOREIGN KEY (std_alert_type_group_id)
	  REFERENCES csr.std_alert_type_group (std_alert_type_group_id);

ALTER TABLE csr.default_alert_template
  DROP CONSTRAINT CK_DEF_ALRT_TEMPLATE_SEND_TYPE;

ALTER TABLE csr.default_alert_template
  ADD CONSTRAINT CK_DEF_ALRT_TEMPLATE_SEND_TYPE
	  CHECK (SEND_TYPE IN ('manual', 'automatic', 'inactive'));

	  
-- Sequences
CREATE SEQUENCE csr.user_inactive_sys_alert_id_seq MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 NOCACHE  NOORDER  NOCYCLE;
CREATE SEQUENCE csr.user_inactive_man_alert_id_seq MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 NOCACHE  NOORDER  NOCYCLE;
CREATE SEQUENCE csr.user_inactive_rem_alert_id_seq MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 NOCACHE  NOORDER  NOCYCLE;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'USER_INACTIVE_SYS_ALERT',
		policy_name     => 'USER_INACTIVE_SYS_ALERT_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive
	);

	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'USER_INACTIVE_MAN_ALERT',
		policy_name     => 'USER_INACTIVE_MAN_ALERT_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive
	);

	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'USER_INACTIVE_REM_ALERT',
		policy_name     => 'USER_INACTIVE_REM_ALERT_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive
	);
END;
/	
-- Data
BEGIN  
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (1, 'Users');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (2, 'Delegations');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (3, 'Actions');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (4, 'Templated reports');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (5, 'Document Library');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (6, 'Corporate Reporter');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (7, 'Audits');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (8, 'Supply Chain');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (9, 'SRM');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (10, 'Teamroom');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (11, 'Initiatives');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (12, 'Ethics');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (13, 'CMS');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (14, 'Other');
END;
/

DECLARE
	ALERT_GROUP_USERS			NUMBER(10) := 1;
	ALERT_GROUP_DELEGTIONS		NUMBER(10) := 2;
	ALERT_GROUP_ACTIONS			NUMBER(10) := 3;
	ALERT_GROUP_TPLREPORTS		NUMBER(10) := 4;
	ALERT_GROUP_DOCLIBRARY		NUMBER(10) := 5;
	ALERT_GROUP_CORPREPORTER	NUMBER(10) := 6;
	ALERT_GROUP_AUDITS			NUMBER(10) := 7;
	ALERT_GROUP_SUPPLYCHAIN		NUMBER(10) := 8;
	ALERT_GROUP_SRM				NUMBER(10) := 9;
	ALERT_GROUP_TEAMROOM		NUMBER(10) := 10;
	ALERT_GROUP_INITIATIVES		NUMBER(10) := 11;
	ALERT_GROUP_ETHICS			NUMBER(10) := 12;
	ALERT_GROUP_CMS				NUMBER(10) := 13;
	ALERT_GROUP_OTHER			NUMBER(10) := 14;
BEGIN  
	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_USERS
	 WHERE std_alert_type_id IN (1, 20, 25, 26, 38, 72, 73, 74);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_DELEGTIONS
	 WHERE std_alert_type_id IN (2, 3, 4, 5, 7, 8, 9, 10, 11, 12,
		13, 14, 15, 16, 27, 28, 29, 30, 39, 57, 58, 59, 62, 68
	);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_ACTIONS
	WHERE std_alert_type_id IN (17, 18, 32, 33, 34, 35, 36, 47, 60, 61);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_TPLREPORTS
	 WHERE std_alert_type_id IN (64, 65);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_DOCLIBRARY
	 WHERE std_alert_type_id IN (19);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_CORPREPORTER
	 WHERE std_alert_type_id IN (44, 48, 49, 52, 53, 56, 63);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_AUDITS
	 WHERE std_alert_type_id IN (45, 46, 67);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_SUPPLYCHAIN
	 WHERE std_alert_type_id IN (21, 22, 23, 24, 1000, 1001, 1002, 1003, 5000,
		5002, 5003, 5004, 5005, 5006, 5007, 5008, 5010, 5011, 5012, 5013, 5014,
		5015, 5016, 5017, 5018, 5019, 5020, 5021, 5022, 5025, 5026 
	);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_SRM
	 WHERE std_alert_type_id IN (5023, 5024);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_TEAMROOM
	 WHERE std_alert_type_id IN (54, 55);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_INITIATIVES
	 WHERE std_alert_type_id IN (2000, 2001, 2002, 2003, 2005, 2006, 2007, 2008, 2009,
		2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2050, 2051, 2052 
	);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_ETHICS
	 WHERE std_alert_type_id IN (3000, 3001);

	UPDATE csr.std_alert_type
	   SET std_alert_type_group_id = ALERT_GROUP_OTHER
	 WHERE std_alert_type_id IN (31, 37, 40, 41, 42, 43, 50, 51, 66, 69, 70, 71, 72, 2004);
END;
/

BEGIN
	UPDATE csr.std_alert_type
	   SET override_template_send_type = 1
	 WHERE std_alert_type_id = 25;
END;
/

BEGIN
	INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, override_user_send_setting, std_alert_type_group_id) VALUES (73, 'User account – pending deactivation', 
		 'A user account will soon be deactivated automatically because the user has not logged in for a specified number of days.  The alert is sent each of the 15 last days before the account is due to be deactivated.',
		 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).',
		 1, 1
	); 

	INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, override_user_send_setting, std_alert_type_group_id) VALUES (74, 'User account deactivated (system)', 
		 'A user account is deactivated automatically because the user has not logged in for a specified number of days.',
		 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).',
		 1, 1
	); 

	INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, override_user_send_setting, std_alert_type_group_id) VALUES (75, 'User account deactivated (manually)', 
		 'A user account is deactivated manually by another user.',
		 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).',
		 1, 1
	); 
END;
/

DECLARE
	v_alert_id NUMBER(10);
BEGIN
	-- User account - pending deactivation
	v_alert_id := 73;
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
  
	-- User account disabled (system)
	v_alert_id := 74;
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
  
	-- User account disabled (manually)
	v_alert_id := 75;
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_alert_id, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5); 
END;
/

DECLARE
   v_daf_id NUMBER(2);
BEGIN
	SELECT MAX(default_alert_frame_id) INTO v_daf_id FROM csr.default_alert_frame;

	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type)
	VALUES (73, v_daf_id, 'inactive');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type)
	VALUES (74, v_daf_id, 'inactive');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type)
	VALUES (75, v_daf_id, 'inactive');
END;
/

-- Scheduled job
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

-- Enable alerts for existing sites
BEGIN
	security.user_pkg.LogOnAdmin();
	FOR r IN (
		SELECT DISTINCT w.website_name host, c.app_sid 
		  FROM csr.customer c
		  JOIN security.website w
		    ON c.app_sid = w.application_sid_id
	)
	LOOP
		security.user_pkg.LogOnAdmin(r.host);
		-- Add new user alerts
		BEGIN
		  INSERT INTO csr.customer_alert_type (customer_alert_type_id, std_alert_type_id)
			SELECT csr.customer_alert_type_id_seq.NEXTVAL, std_alert_type_id
			  FROM csr.std_alert_type
			 WHERE std_alert_type_id IN (
				73,
				74,
				75
			);
		EXCEPTION
		  WHEN DUP_VAL_ON_INDEX THEN
			NULL;
		END;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Packages ***
@../csr_data_pkg
@../csr_data_body

@../alert_pkg
@../alert_body

@../csr_user_pkg
@../csr_user_body

@../csr_app_body
@../schema_body
@../delegation_body
@../sheet_body
@../issue_body
@../audit_body
@../section_body
@../csrimp/imp_body

@update_tail
