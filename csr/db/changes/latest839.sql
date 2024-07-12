-- Please update version.sql too -- this keeps clean builds in sync
define version=839
@update_header

ALTER TABLE ACTIONS.IND_TEMPLATE ADD(
	INFO_TEXT           	VARCHAR2(4000)
);

ALTER TABLE ACTIONS.TASK_STATUS ADD(
	IS_DRAFT            	NUMBER(1, 0)      DEFAULT 0 NOT NULL,
	MEANS_BACK          	NUMBER(1, 0)      DEFAULT 0 NOT NULL,
	CHECK (IS_DRAFT IN(0,1)),
	CHECK (MEANS_BACK IN(0,1))
);

ALTER TABLE ACTIONS.PROJECT_IND_TEMPLATE MODIFY (
	POS_GROUP				NUMBER(10,0)
);

CREATE TABLE ACTIONS.IND_TEMPLATE_GROUP(
    APP_SID               	NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    PROJECT_SID           	NUMBER(10, 0)     NOT NULL,
    POS_GROUP             	NUMBER(10, 0)     NOT NULL,
    IS_GROUP_MANDATORY    	NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    LABEL                 	VARCHAR2(1024),
    INFO_TEXT           	VARCHAR2(4000),
    CHECK (IS_GROUP_MANDATORY IN(0,1)),
    CONSTRAINT PK159 PRIMARY KEY (APP_SID, PROJECT_SID, POS_GROUP)
)
;

ALTER TABLE ACTIONS.IND_TEMPLATE_GROUP ADD CONSTRAINT RefPROJECT317 
    FOREIGN KEY (APP_SID, PROJECT_SID)
    REFERENCES ACTIONS.PROJECT(APP_SID, PROJECT_SID)
;

CREATE INDEX ACTIONS.IX_PROJECT_IND_TEMPLATE_GROUP ON ACTIONS.IND_TEMPLATE_GROUP (APP_SID, PROJECT_SID);

BEGIN
	INSERT INTO actions.ind_template_group
	  (app_sid, project_sid, pos_group)
		SELECT DISTINCT app_sid, project_sid, pos_group
		  FROM actions.project_ind_template;
END;
/

ALTER TABLE ACTIONS.PROJECT_IND_TEMPLATE ADD CONSTRAINT RefIND_TEMPLATE_GROUP318 
    FOREIGN KEY (APP_SID, PROJECT_SID, POS_GROUP)
    REFERENCES ACTIONS.IND_TEMPLATE_GROUP(APP_SID, PROJECT_SID, POS_GROUP)
;

CREATE INDEX ACTIONS.IX_PRJ_IND_TPL_IND_TPL_GROUP ON ACTIONS.PROJECT_IND_TEMPLATE (APP_SID, PROJECT_SID, POS_GROUP);

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'ACTIONS',
		object_name     => 'IND_TEMPLATE_GROUP',
		policy_name     => 'IND_TEMPLATE_GROUP_POLICY',
		function_schema => 'ACTIONS',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

BEGIN
	-- Generic status change alert
	INSERT INTO csr.alert_type (ALERT_TYPE_ID, PARENT_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) 
		VALUES (2019, NULL, 'Initiative status changed', 'The initiative status has changed.', 'The user who changed the status.');
	
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'SUBMITTED_BY_FULL_NAME', 'Submitted by full name', 'The full name of the submitting user', 0, 1);
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'SUBMITTED_BY_FRIENDLY_NAME', 'Submitted by friendly name', 'The friendly name of the submitting user', 0, 2);
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'SUBMITTED_BY_USER_NAME', 'Submitted user name', 'The user name of the submitting user', 0, 3);
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'SUBMITTED_BY_EMAIL', 'Submitted e-Mmail', 'The e-mail address of the submitting user', 0, 4);
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'TO_FULL_NAME', 'Recipient full name', 'The full name of the user who is responsible for the next action on the initiative', 0, 5);
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'TO_FRIENDLY_NAME', 'Recipient friendly name', 'The friendly name of the user who is responsible for the next action on the initiative', 0, 6);
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'TO_USER_NAME', 'Recipient user name', 'The user name of the user who is responsible for the next action on the initiative', 0, 7);
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'TO_EMAIL', 'Recipient e-mail', 'The e-mail address of the user who is responsible for the next action on the initiative', 0, 8);
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'NAME', 'Name', 'The initiative name', 0, 9);
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'REFERENCE', 'Reference', 'The initiative reference', 0, 10);
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'INITIATIVE_SUB_TYPE', 'Type', 'The initiative type', 0, 11);
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'START_DTM', 'Start date', 'The initiative start date', 0, 12);
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'END_DTM', 'End date', 'The initiative end date', 0, 13);
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'VIEW_URL', 'View link', 'A link to the initiative', 0, 14);
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'REGION_DESC', 'Property', 'The property the initiative relates to', 0, 15);
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'COMMENT', 'Comment', 'The comment entered by the reviewing user', 0, 16);
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'TRANSITION_NAME', 'Action', 'The action performed that caused the transition', 0, 17);
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'FROM_STATUS_NAME', 'From status', 'The status the initiative was in before the action was taken', 0, 18);
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2019, 'TO_STATUS_NAME', 'To status', 'The status the initiative is in due to the action taken', 0, 19);
END;
/

@../actions/initiative_pkg
@../actions/initiative_body
@../actions/project_body

@update_tail
