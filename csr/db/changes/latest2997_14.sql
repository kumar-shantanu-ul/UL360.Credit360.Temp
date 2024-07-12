-- Please update version.sql too -- this keeps clean builds in sync
define version=2997
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.FORECASTING_SCENARIO_ALERT(
	APP_SID						NUMBER(10, 0) 	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	FORECASTING_SID				NUMBER(10, 0) 	NOT NULL,
	CSR_USER_SID				NUMBER(10, 0) 	NOT NULL,
	CALC_JOB_ID					NUMBER(10, 0) 	NOT NULL,
	CALC_JOB_COMPLETION_DTM		DATE 			NOT NULL,
	CONSTRAINT PK_FRCAST_SCEN_ALERT PRIMARY KEY (APP_SID, FORECASTING_SID, CSR_USER_SID, CALC_JOB_ID)
)
;


-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, OVERRIDE_USER_SEND_SETTING, STD_ALERT_TYPE_GROUP_ID) VALUES (77, 'Forecasting dataset calculation complete',
	'Calculating the dataset for a forecasting slot has completed.',
	'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).', 1, 14
);


INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'SLOT_NAME', 'Slot name', 'The name of the forecasting slot', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'SCENARIO_RUN_NAME', 'Scenario name', 'The name of the underlying scenario', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'COMPLETION_DTM', 'Completion time', 'The date and time that the dataset completed calculating', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'START_DTM', 'Start date', 'The start date of the forecasting slot', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'NUMBER_OF_YEARS', 'Number of years', 'The number of years covered by the forecasting slot', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'LINK_URL', 'Link to slot', 'A link to the forecasting page for the slot', 11);


DECLARE
	v_daf_id NUMBER(2);
BEGIN
	SELECT MAX(default_alert_frame_id) INTO v_daf_id FROM csr.default_alert_frame;

	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type)
	VALUES (77, v_daf_id, 'inactive');
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../enable_body
@../forecasting_pkg
@../forecasting_body

@update_tail
