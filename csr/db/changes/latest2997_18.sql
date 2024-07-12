-- Please update version.sql too -- this keeps clean builds in sync
define version=2997
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DROP INDEX CSR.PLUGIN_JS_CLASS;
CREATE UNIQUE INDEX CSR.PLUGIN_JS_CLASS ON CSR.PLUGIN(APP_SID, JS_CLASS, FORM_PATH, GROUP_KEY, SAVED_FILTER_SID, RESULT_MODE, PORTAL_SID, R_SCRIPT_PATH, FORM_SID);

ALTER TABLE CSR.INCIDENT_TYPE RENAME COLUMN mobile_list_path TO mobile_form_path;
ALTER TABLE CSR.INCIDENT_TYPE DROP COLUMN mobile_edit_path;
ALTER TABLE CSR.INCIDENT_TYPE DROP COLUMN mobile_new_case_path;
ALTER TABLE CSR.INCIDENT_TYPE ADD ( 
	mobile_form_sid NUMBER(10, 0),
	CONSTRAINT ck_incident_mobile_form CHECK ( mobile_form_path IS NULL OR mobile_form_sid IS NULL )
);

-- incident types don't seem to be in csrimp yet

-- *** Grants ***

-- ** Cross schema constraints ***
ALTER TABLE CSR.INCIDENT_TYPE ADD CONSTRAINT FK_INC_TYPE_CMS_FORM
	FOREIGN KEY (APP_SID, MOBILE_FORM_SID) 
	REFERENCES CMS.FORM (APP_SID, FORM_SID);
	
create index csr.ix_incident_type_mobile_form_s on csr.incident_type (app_sid, mobile_form_sid);

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../incident_pkg
@../incident_body

@update_tail
