-- Please update version.sql too -- this keeps clean builds in sync
define version=2941
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.like_for_like_scenario_alert (
	app_sid						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	like_for_like_sid			NUMBER(10, 0) NOT NULL,
	csr_user_sid				NUMBER(10, 0) NOT NULL,
	calc_job_id					NUMBER(10, 0) NOT NULL,
	calc_job_completion_dtm		DATE NOT NULL,
	CONSTRAINT PK_L4L_SCEN_ALERT		 	PRIMARY KEY	(APP_SID, LIKE_FOR_LIKE_SID, CSR_USER_SID, CALC_JOB_ID),
	CONSTRAINT FK_L4L_SCEN_ALERT_L4L_SID 	FOREIGN KEY	(APP_SID, LIKE_FOR_LIKE_SID) REFERENCES CSR.LIKE_FOR_LIKE_SLOT(APP_SID, LIKE_FOR_LIKE_SID),
	CONSTRAINT FK_L4L_SCEN_ALERT_USER_SID	FOREIGN KEY	(APP_SID, CSR_USER_SID) REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
);

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, OVERRIDE_USER_SEND_SETTING, STD_ALERT_TYPE_GROUP_ID) VALUES (76, 'Like for like dataset calculation complete',
	 'The underlying dataset for a like for like slot has completing calculating.',
	 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).', 1, 14
);
 
-- Like for like scenario completed
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'SLOT_NAME', 'Slot name', 'The name of the like for like slot', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'SCENARIO_RUN_NAME', 'Scenario name', 'The name of the underlying scenario', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'COMPLETION_DTM', 'Completion time', 'The date and time that the dataset completed calculating', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'START_DTM', 'Start date', 'The start date of the like for like slot', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'END_DTM', 'End date', 'The end date of the like for like slot', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (76, 0, 'LINK_URL', 'Link to slot', 'A link to the like for like page for the slot', 11);
 
DECLARE
   v_daf_id NUMBER(2);
BEGIN
	SELECT MAX(default_alert_frame_id) INTO v_daf_id FROM csr.default_alert_frame;

	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type)
	VALUES (76, v_daf_id, 'inactive');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../like_for_like_pkg
@../like_for_like_body
@../scenario_body
@../scenario_run_body

@update_tail
