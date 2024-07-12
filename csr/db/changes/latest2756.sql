-- Please update version.sql too -- this keeps clean builds in sync
define version=2756
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (52, 'Audit log reports', 'EnableAuditLogReports', 'Enables the audit log reports page in the admin menu. NOTE - not related to the audits module. This is audit LOGS.', 0);

-- ** New package grants **

-- *** Packages ***
@../csr_user_pkg
@../csr_user_body

@update_tail
