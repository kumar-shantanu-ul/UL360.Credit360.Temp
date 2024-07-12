-- Please update version.sql too -- this keeps clean builds in sync
define version=2861
define minor_version=1
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

-- ** New package grants **

-- *** Packages ***
@..\alert_pkg
@..\alert_body
@..\audit_body
@..\branding_pkg
@..\branding_body
@..\customer_body
@..\region_body
@..\supplier_body
@..\training_body
@..\chain\admin_helper_pkg
@..\chain\admin_helper_body
@..\chain\chain_link_body

@update_tail
