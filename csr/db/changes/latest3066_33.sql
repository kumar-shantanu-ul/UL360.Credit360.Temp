-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=33
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.compliance_options ADD auto_involve_managers NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE csrimp.compliance_options ADD auto_involve_managers NUMBER(1,0) NOT NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'DUE_DTM', 'Due date', 'The date the issue should be resolved by', 18);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'ISSUE_REF', 'Issue Ref', 'The issue reference', 19);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'ISSUE_TYPE_DESCRIPTION', 'Issue type', 'The description of the issue type', 20);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'ASSIGNED_TO', 'Assigned to', 'The user that the issue is currently assigned to', 21);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'CRITICAL', 'Critical', 'Indicates if the action is critical', 22);

INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 1, 'DUE_DTM', 'Due date', 'The date the issue should be resolved by', 21);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 1, 'ASSIGNED_TO', 'Assigned to', 'The user that the issue is currently assigned to', 22);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 1, 'CRITICAL', 'Critical', 'Indicates if the action is critical', 23);

INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60, 1, 'ISSUE_ID', 'Issue ID', 'The issue ID', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60, 1, 'ISSUE_LABEL', 'Issue label', 'The label of the issue', 11);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60, 1, 'ISSUE_REF', 'Issue Ref', 'The issue reference', 12);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60, 1, 'ASSIGNED_TO', 'Assigned to', 'The user that the issue is currently assigned to', 13);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60, 1, 'CRITICAL', 'Critical', 'Indicates if the action is critical', 14);

INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61, 1, 'ISSUE_ID', 'Issue ID', 'The issue ID', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61, 1, 'ISSUE_LABEL', 'Issue label', 'The label of the issue', 11);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61, 1, 'ISSUE_REF', 'Issue Ref', 'The issue reference', 12);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61, 1, 'ASSIGNED_TO', 'Assigned to', 'The user that the issue is currently assigned to', 13);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61, 1, 'CRITICAL', 'Critical', 'Indicates if the action is critical', 14);

UPDATE CSR.default_alert_template_body 
   SET item_html = 
	'<template><p><mergefield name="CRITICAL"/> <mergefield name="ISSUE_LABEL"/> ' || 
		'assigned to <mergefield name="ASSIGNED_TO"/> at <mergefield name="ISSUE_REGION"/> ' ||
		'expires on <mergefield name="DUE_DTM"/>. <mergefield name="ISSUE_LINK"/>' ||
	'</p></template>'
 WHERE std_alert_type_id IN (60, 61) AND lang = 'en';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../issue_pkg
@../compliance_pkg

@../issue_body
@../schema_body
@../csrimp/imp_body
@../compliance_body

@update_tail
