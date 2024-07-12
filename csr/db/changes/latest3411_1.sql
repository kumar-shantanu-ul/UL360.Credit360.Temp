-- Please update version.sql too -- this keeps clean builds in sync
define version=3411
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csrimp.compliance_item_description MODIFY title VARCHAR2(2048);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../compliance_body

@update_tail
