-- Please update version.sql too -- this keeps clean builds in sync
define version=2932
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE security.user_table DROP COLUMN remove_roles_on_deactivation;

ALTER TABLE security.account_policy DROP COLUMN remove_roles_on_account_expir;

ALTER TABLE csr.batch_job_structure_import DROP COLUMN remove_from_roles_inactivated;
  

ALTER TABLE csrimp.user_table DROP COLUMN remove_roles_on_deactivation;

ALTER TABLE csrimp.account_policy DROP COLUMN remove_roles_on_account_expir;
  


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../role_pkg
@../role_body
@../csr_user_pkg
@../csr_user_body
@../structure_import_pkg
@../structure_import_body
@../../../security/db/oracle/accountpolicyhelper_body
@../../../security/db/oracle/user_pkg
@../../../security/db/oracle/user_body
@../../../security/db/oracle/accountpolicy_pkg
@../../../security/db/oracle/accountpolicy_body
@../csr_app_body

@../schema_body
@../csrimp/imp_body

@update_tail
