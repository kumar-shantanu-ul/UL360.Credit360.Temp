-- Please update version.sql too -- this keeps clean builds in sync
define version=2886
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DROP SEQUENCE csr.property_tab_mobile_id_seq;
DROP TABLE csr.property_tab_mobile;
DROP TABLE csrimp.property_tab_mobile;
DROP TABLE csrimp.map_property_tab_mobile;

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
@../property_pkg
@../schema_pkg

@../csr_app_body
@../property_body
@../schema_body
@../csrimp/imp_body

@update_tail
