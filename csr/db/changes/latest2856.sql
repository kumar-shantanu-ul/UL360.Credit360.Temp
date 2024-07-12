-- Please update version.sql too -- this keeps clean builds in sync
define version=2856
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data
ALTER TABLE csr.role DROP COLUMN is_user_creator;
ALTER TABLE csrimp.role DROP COLUMN is_user_creator;


-- ** New package grants **

-- *** Packages ***
@..\csrimp\imp_body
@..\schema_body
@..\role_body
@..\csr_user_body
@..\supplier_body
@..\delegation_body

@update_tail
