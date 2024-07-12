-- Please update version.sql too -- this keeps clean builds in sync
define version=2776
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
@..\audit_pkg
@..\audit_body
@..\chain\chain_link_pkg
@..\chain\chain_link_body
@..\chain\supplier_audit_body

@update_tail
