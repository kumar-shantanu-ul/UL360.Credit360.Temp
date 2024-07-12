-- Please update version.sql too -- this keeps clean builds in sync
define version=2972
define minor_version=25
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.MODULE ADD (
	WARNING_MSG	VARCHAR2(1023)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.audit_type ( audit_type_group_id, audit_type_id, label ) 
VALUES (1, 120, 'Module enabled');

INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning, warning_msg)
VALUES (84, 'Properties - base', 'EnableProperties', 'Enables the Properties module. Cannot be undone. To manage a property, add a user to Property Manager role after enabling.', 1, 'This enables parts of the supply chain system and cannot be undone.');

INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (84, 'in_company_name', 0, 'Provide name of top level company if chain is not already enabled');

INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (84, 'in_property_type', 1, 'Enter default property type (existing properties will be assigned this type)');

INSERT INTO csr.util_script (util_script_id,util_script_name,description,util_script_sp,wiki_article) 
VALUES (24, 'Add Missing Properties', 'Add properties from the region tree which are missing in the Properties module list. (Needed if Properties was enabled prior to October 2016.)', 'AddMissingProperties', NULL);

INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint, pos) 
VALUES (24, 'Property type','Enter default property type (if type does not exist, it will be created)',0);

UPDATE csr.module SET Module_name = 'Properties - dashboards' WHERE module_id = 64;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../csr_data_pkg
@../enable_pkg
@../benchmarking_dashboard_pkg
@../metric_dashboard_pkg
@../util_script_pkg
@../csr_data_pkg

@../csr_app_body
@../region_body
@../enable_body
@../benchmarking_dashboard_body
@../metric_dashboard_body
@../util_script_body
@../property_report_body

@update_tail
