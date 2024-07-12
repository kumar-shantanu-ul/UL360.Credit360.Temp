-- Please update version.sql too -- this keeps clean builds in sync
define version=2935
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.property_options ADD (auto_assign_manager NUMBER(1, 0) DEFAULT 0 NOT NULL);

ALTER TABLE csrimp.property_options ADD (auto_assign_manager NUMBER(1, 0));
UPDATE csrimp.property_options SET auto_assign_manager = 0;
ALTER TABLE csrimp.property_options MODIFY auto_assign_manager NUMBER(1, 0) NOT NULL;

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
@../property_body
@../schema_body.sql
@../csrimp/imp_body.sql

@update_tail
