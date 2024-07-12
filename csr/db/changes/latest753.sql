-- Please update version.sql too -- this keeps clean builds in sync
define version=753
@update_header

@requiredvers SECURITY 39 ""
-- 
-- TABLE: CORRESPONDENT 
--
CREATE TABLE csr.CORRESPONDENT(
    APP_SID             NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CORRESPONDENT_ID    NUMBER(10, 0)    NOT NULL,
    FULL_NAME           VARCHAR2(255)    NOT NULL,
    EMAIL               VARCHAR2(255),
    PHONE               VARCHAR2(255),
    GUID                RAW(16)          NOT NULL,
    CONSTRAINT PK_CORRESPONDENT PRIMARY KEY (APP_SID, CORRESPONDENT_ID)
)
;

-- 
-- TABLE: ISSUE_ACTION_LOG 
--
CREATE TABLE csr.ISSUE_ACTION_LOG(
    APP_SID                 		NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ISSUE_ACTION_LOG_ID     		NUMBER(10, 0)    NOT NULL,
    ISSUE_ACTION_TYPE_ID    		NUMBER(10, 0)    NOT NULL,
    ISSUE_ID                		NUMBER(10, 0),
    ISSUE_LOG_ID            		NUMBER(10, 0),
    LOGGED_BY_USER_SID      		NUMBER(10, 0),
    LOGGED_BY_CORRESPONDENT_ID    	NUMBER(10, 0),
    LOGGED_DTM              		DATE             DEFAULT SYSDATE NOT NULL,
    ASSIGNED_TO_ROLE_SID    		NUMBER(10, 0),
    ASSIGNED_TO_USER_SID    		NUMBER(10, 0),
    CONSTRAINT CHK_IAL_XOR_ASSIGNED CHECK (
    	ISSUE_ACTION_TYPE_ID NOT IN (1) -- IAT_ASSIGNED
		OR
		(
			(ASSIGNED_TO_USER_SID IS NOT NULL OR ASSIGNED_TO_ROLE_SID IS NOT NULL)
			AND
			(ASSIGNED_TO_USER_SID IS NULL OR ASSIGNED_TO_ROLE_SID IS NULL)
		)
	),
	CONSTRAINT CHK_IAL_XOR_LOGGED_BY CHECK (
		(LOGGED_BY_USER_SID IS NOT NULL OR LOGGED_BY_CORRESPONDENT_ID IS NOT NULL)
		AND
		(LOGGED_BY_USER_SID IS NULL OR LOGGED_BY_CORRESPONDENT_ID IS NULL)
	),
    CONSTRAINT PK_ISSUE_ACTION_LOG PRIMARY KEY (APP_SID, ISSUE_ACTION_LOG_ID)
)
;

-- 
-- TABLE: ISSUE_ACTION_TYPE 
--
CREATE TABLE csr.ISSUE_ACTION_TYPE(
    ISSUE_ACTION_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION             VARCHAR2(100)    NOT NULL,
    CONSTRAINT ISSUE_ACTION_TYPE PRIMARY KEY (ISSUE_ACTION_TYPE_ID)
)
;


-- 
-- TABLE: ISSUE
--
ALTER TABLE csr.ISSUE MODIFY ASSIGNED_TO_USER_SID NULL;

ALTER TABLE csr.ISSUE ADD (
	CORRESPONDENT_NOTIFIED     NUMBER(1, 0)      DEFAULT 0 NOT NULL,
	CORRESPONDENT_ID           NUMBER(10, 0),
	ASSIGNED_TO_ROLE_SID       NUMBER(10, 0),
    REGION_SID                 NUMBER(10, 0),
    GUID                       RAW(16),
	CONSTRAINT CHK_ISSUE_XOR_IS_ASSIGNED CHECK (
		(ASSIGNED_TO_USER_SID IS NOT NULL OR ASSIGNED_TO_ROLE_SID IS NOT NULL)
		AND
		(ASSIGNED_TO_USER_SID IS NULL OR ASSIGNED_TO_ROLE_SID IS NULL)
	)
)
;

ALTER TABLE csr.ISSUE_LOG MODIFY LOGGED_BY_USER_SID NULL;

ALTER TABLE csr.ISSUE_LOG ADD (
	LOGGED_BY_CORRESPONDENT_ID    NUMBER(10, 0),
	CONSTRAINT CHK_IL_XOR_LOGGED_BY CHECK (
		(LOGGED_BY_USER_SID IS NOT NULL OR LOGGED_BY_CORRESPONDENT_ID IS NOT NULL)
		AND
		(LOGGED_BY_USER_SID IS NULL OR LOGGED_BY_CORRESPONDENT_ID IS NULL)
	)
);

-- 
-- TABLE: ISSUE_TYPE
--
ALTER TABLE csr.ISSUE_TYPE ADD (
    DEFAULT_REGION_SID    NUMBER(10, 0)
)
;

-- 
-- INDEX: UK_CORRESPONDENT_EMAIL 
--
CREATE UNIQUE INDEX UK_CORRESPONDENT_EMAIL ON csr.CORRESPONDENT(APP_SID, NVL(UPPER(EMAIL),'CRSPDNT'||TO_CHAR(CORRESPONDENT_ID)))
;

-- 
-- TABLE: CORRESPONDENT 
--
ALTER TABLE csr.CORRESPONDENT ADD CONSTRAINT FK_CUSTOMER_CORR 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID)
;

-- 
-- TABLE: ISSUE 
--
ALTER TABLE csr.ISSUE ADD CONSTRAINT FK_CORR_ISSUE 
    FOREIGN KEY (APP_SID, CORRESPONDENT_ID)
    REFERENCES csr.CORRESPONDENT(APP_SID, CORRESPONDENT_ID)
;

ALTER TABLE csr.ISSUE ADD CONSTRAINT FK_ASS_ROLE_ISSUE 
    FOREIGN KEY (APP_SID, ASSIGNED_TO_ROLE_SID)
    REFERENCES csr.ROLE(APP_SID, ROLE_SID)
;

ALTER TABLE csr.ISSUE ADD CONSTRAINT FK_REGION_ISSUE 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES csr.REGION(APP_SID, REGION_SID)
;

-- 
-- TABLE: ISSUE_LOG 
--
ALTER TABLE csr.ISSUE_LOG ADD CONSTRAINT FK_CORR_ISSUE_LOG 
    FOREIGN KEY (APP_SID, LOGGED_BY_CORRESPONDENT_ID)
    REFERENCES csr.CORRESPONDENT(APP_SID, CORRESPONDENT_ID)
;

-- 
-- TABLE: ISSUE_ACTION_LOG 
--
ALTER TABLE csr.ISSUE_ACTION_LOG ADD CONSTRAINT FK_BY_CSRU_AIL 
    FOREIGN KEY (APP_SID, LOGGED_BY_USER_SID)
    REFERENCES csr.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE csr.ISSUE_ACTION_LOG ADD CONSTRAINT FK_ISSUE_IAL 
    FOREIGN KEY (APP_SID, ISSUE_ID)
    REFERENCES csr.ISSUE(APP_SID, ISSUE_ID)
;

ALTER TABLE csr.ISSUE_ACTION_LOG ADD CONSTRAINT FK_IA_TYPE_LOG 
    FOREIGN KEY (ISSUE_ACTION_TYPE_ID)
    REFERENCES csr.ISSUE_ACTION_TYPE(ISSUE_ACTION_TYPE_ID)
;

ALTER TABLE csr.ISSUE_ACTION_LOG ADD CONSTRAINT FK_ASS_ROLE_IAL 
    FOREIGN KEY (APP_SID, ASSIGNED_TO_ROLE_SID)
    REFERENCES csr.ROLE(APP_SID, ROLE_SID)
;

ALTER TABLE csr.ISSUE_ACTION_LOG ADD CONSTRAINT FK_ASS_CSRU_AIL 
    FOREIGN KEY (APP_SID, ASSIGNED_TO_USER_SID)
    REFERENCES csr.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE csr.ISSUE_ACTION_LOG ADD CONSTRAINT FK_CUSTOMER_IAL 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID)
;

ALTER TABLE csr.ISSUE_ACTION_LOG ADD CONSTRAINT FK_IL_IAL 
    FOREIGN KEY (APP_SID, ISSUE_LOG_ID)
    REFERENCES csr.ISSUE_LOG(APP_SID, ISSUE_LOG_ID)
;

ALTER TABLE csr.ISSUE_ACTION_LOG ADD CONSTRAINT FK_LOG_CORR_IAL 
    FOREIGN KEY (APP_SID, LOGGED_BY_CORRESPONDENT_ID)
    REFERENCES csr.CORRESPONDENT(APP_SID, CORRESPONDENT_ID)
;

-- 
-- TABLE: ISSUE_TYPE 
--
ALTER TABLE csr.ISSUE_TYPE ADD CONSTRAINT FK_REGION_ISSUE_TYPE 
    FOREIGN KEY (APP_SID, DEFAULT_REGION_SID)
    REFERENCES csr.REGION(APP_SID, REGION_SID)
;

-- 
-- SEQUENCE: ISSUE_ACTION_LOG_ID_SEQ 
--
CREATE SEQUENCE csr.ISSUE_ACTION_LOG_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

-- 
-- SEQUENCE: CORRESPONDENT_ID_SEQ 
--

CREATE SEQUENCE csr.CORRESPONDENT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

/**************************************************************************************/

BEGIN
	INSERT INTO csr.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (0, 'Opened');
	INSERT INTO csr.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (1, 'Assigned');
	INSERT INTO csr.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (2, 'Replied to correspondent');
	INSERT INTO csr.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (3, 'Resolved');
	INSERT INTO csr.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (4, 'Closed');
	INSERT INTO csr.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (5, 'Reopened');
	INSERT INTO csr.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (6, 'Due date changed');
END;
/

ALTER TABLE csr.ISSUE ADD (
	OWNER_USER_SID             NUMBER(10, 0),
    OWNER_ROLE_SID             NUMBER(10, 0)
);

UPDATE csr.ISSUE SET OWNER_USER_SID = RAISED_BY_USER_SID; 

ALTER TABLE csr.ISSUE ADD CONSTRAINT FK_OWNER_CSRU_ISSUE 
    FOREIGN KEY (APP_SID, OWNER_USER_SID)
    REFERENCES csr.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE csr.ISSUE ADD CONSTRAINT FK_OWNER_ROLE_ISSUE 
    FOREIGN KEY (APP_SID, OWNER_ROLE_SID)
    REFERENCES csr.ROLE(APP_SID, ROLE_SID)
;

ALTER TABLE csr.ISSUE ADD (
    CONSTRAINT CHK_ISSUE_XOR_OWNER CHECK (
    	(OWNER_USER_SID IS NOT NULL OR OWNER_ROLE_SID IS NOT NULL)
		AND
		(OWNER_USER_SID IS NULL OR OWNER_ROLE_SID IS NULL)
	)
);



CREATE OR REPLACE TYPE csr.T_USER_FILTER_ROW AS
	OBJECT (
		CSR_USER_SID		NUMBER(10),
		ACCOUNT_ENABLED		NUMBER(1),	
		IS_SA				NUMBER(10)
	);
/

CREATE OR REPLACE TYPE csr.T_USER_FILTER_TABLE AS
  TABLE OF T_USER_FILTER_ROW;
/

CREATE OR REPLACE VIEW csr.v$issue AS
	SELECT i.app_sid, i.issue_id, i.label, note, i.source_label,
		   raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
		   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
		   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
		   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
		   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone,
		   sysdate now_dtm, due_dtm, ist.issue_type_Id, ist.label issue_type_label,
		   issue_pending_val_id, issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id,
		   CASE 
			WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND SYSDATE > due_dtm THEN 1
			ELSE 0 
		   END is_overdue
	  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user cuass, role r, correspondent c
	 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
	   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
	   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+) 
	   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
	   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+)
	   AND i.app_sid = r.app_sid(+) AND i.assigned_to_role_sid = r.role_sid(+)
	   AND i.app_sid = c.app_sid(+) AND i.correspondent_id = c.correspondent_id(+);
	   
-- fixup data
BEGIN
	INSERT INTO csr.issue_type (app_sid, issue_type_id, label)
	SELECT app_sid, 9, label
	  FROM csr.issue_type
	 WHERE issue_type_id = 1000;

	UPDATE csr.issue SET issue_type_id = 9 where issue_type_id = 1000;

	DELETE FROM csr.issue_type WHERE issue_type_id = 1000;

	INSERT INTO csr.portlet (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) 
	VALUES (portlet_id_seq.nextval, 'New Issues', 'Credit360.Portlets.Issue2', '/csr/site/portal/portlets/issue2.js');
END;
/

-- create alerts
BEGIN
	INSERT INTO csr.ALERT_TYPE (ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (32, 'Correspondent issue submission confirmation',
		'A issue is created and a correspondent (non-system user) is attached.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
	);  

	INSERT INTO csr.ALERT_TYPE (ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (33, 'Response to issue correspondent',
		'A system user manually triggers a response to an issue correspondent.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
	);  

	-- Correspondent issue submission confirmation
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (32, 0, 'TO_NAME', 'To full name', 'The full name of the person (correspondent) that the alert is being sent to', 1);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (32, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the person (correspondent) that the alert is being sent to', 2);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (32, 0, 'NOTE', 'Log entry note', 'The note that was submitted to open the issue', 3);
	
	-- Response to issue correspondent
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (33, 0, 'TO_NAME', 'To full name', 'The full name of the person (correspondent) that the alert is being sent to', 1);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (33, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the person (correspondent) that the alert is being sent to', 2);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (33, 0, 'FROM_NAME', 'From full name', 'The full name of the user that is triggering the alert send', 3);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (33, 0, 'NOTE', 'Log entry note', 'The note to the correspondent that is also written into the issue log', 4);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (33, 0, 'LINK', 'Public access link', 'The public link that allows the correspondent to view the issue and add further comments', 5);
	INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (33, 0, 'ATTACHMENT_COUNT', 'Attachment count', 'The number of attachments which are attached to the last log entry that can be downloaded by the correspondent.', 6);
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
		'ISSUE_ACTION_LOG',
		'CORRESPONDENT'
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

@..\csr_data_pkg
@..\issue_pkg
@..\csr_user_pkg
@..\role_pkg

@..\issue_body
@..\csr_user_body
@..\role_body

@update_tail
