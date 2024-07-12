-- Please update version.sql too -- this keeps clean builds in sync
define version=2927
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) 
VALUES (1, 25, 'Portlet');

INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) 
VALUES (1, 26, 'Dashboard');

INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (71, 'Audit log reports: Dashboards', 'EnableDashboardAuditLogReports', 'Enables the audit log reports page in the admin menu and adds dashboard report. NOTE - not related to the audits module. This is audit LOGS', 0);



-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../csr_data_pkg
@../enable_pkg
@../portlet_pkg

@../csr_data_body
@../portlet_body
@../enable_body

@update_tail
