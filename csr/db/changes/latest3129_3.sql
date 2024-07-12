-- Please update version.sql too -- this keeps clean builds in sync
define version=3129
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.customer ADD lazy_load_role_membership NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csr.customer ADD CONSTRAINT chk_lazy_load_role_membership CHECK (lazy_load_role_membership IN (0,1));
ALTER TABLE csrimp.customer ADD lazy_load_role_membership NUMBER(1) NOT NULL;
ALTER TABLE csrimp.customer ADD CONSTRAINT chk_lazy_load_role_membership CHECK (lazy_load_role_membership IN (0,1));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP, WIKI_ARTICLE) VALUES (37, 'Enable/Disable lazy load of region role membership on user edit', 'Enable or disables automatic loading of region role membership for users on editing a user', 'SetUserRegionRoleLazyLoad', NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS, PARAM_VALUE, PARAM_HIDDEN) VALUES (37, 'Lazy load', '1 to enable, 0 to disable lazy load', 0, NULL, 0);
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\util_script_pkg
@..\util_script_body
@..\customer_body
@..\schema_body
@..\csrimp\imp_body

@update_tail
