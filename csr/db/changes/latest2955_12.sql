-- Please update version.sql too -- this keeps clean builds in sync
define version=2955
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.compliance_options (
    app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	quick_survey_type_id			NUMBER(10, 0) NOT NULL
);
CREATE TABLE csrimp.compliance_options (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	quick_survey_type_id			NUMBER(10, 0) NOT NULL,
    CONSTRAINT compliance_options	PRIMARY KEY (csrimp_session_id),
    CONSTRAINT fk_compliance_options_is 
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id) 
		ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE csr.compliance_options ADD CONSTRAINT fk_compliance_options_st
    FOREIGN KEY (app_sid, quick_survey_type_id)
    REFERENCES csr.quick_survey_type (app_sid, quick_survey_type_id);

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_options TO tool_user;
GRANT SELECT, INSERT, UPDATE ON csr.compliance_options TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (79, 'Compliance', 'EnableCompliance', 'Enables the Compliance module. Requires Surveys and Workflow to be enabled.', 1);

INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (80, 'Compliance - ENHESA integration', 'EnableEnhesa', 'Enables the ENHESA integration for the compliance module. Requires Compliance to be enabled.', 1);

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.compliance_pkg
AS
END;
/
GRANT EXECUTE ON csr.compliance_pkg TO web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../csrimp/imp_pkg
@../compliance_pkg
@../enable_pkg
@../schema_pkg

@../csrimp/imp_body
@../compliance_body
@../csr_app_body
@../enable_body
@../schema_body

@update_tail
