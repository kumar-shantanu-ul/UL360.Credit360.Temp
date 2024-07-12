-- Please update version.sql too -- this keeps clean builds in sync
define version=2927
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE security.user_table
  ADD remove_roles_on_deactivation		NUMBER(1,0)	DEFAULT 0;

ALTER TABLE security.account_policy
  ADD remove_roles_on_account_expir		NUMBER(1,0)	DEFAULT 0;

ALTER TABLE csr.batch_job_structure_import 
  ADD remove_from_roles_inactivated		NUMBER(1,0) DEFAULT 0;
  

ALTER TABLE csrimp.user_table
  ADD remove_roles_on_deactivation		NUMBER(1,0);

ALTER TABLE csrimp.account_policy
  ADD remove_roles_on_account_expir		NUMBER(1,0);
  


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
