-- Please update version.sql too -- this keeps clean builds in sync
define version=3170
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.schema_table SET csrimp_table_name = 'COMPLIANCE_ALERT' WHERE table_name = 'COMPLIANCE_ALERT';
UPDATE csr.schema_table SET csrimp_table_name = 'COMPLIANCE_ENHESA_MAP' WHERE table_name = 'COMPLIANCE_ENHESA_MAP';
UPDATE csr.schema_table SET csrimp_table_name = 'COMPLIANCE_ENHESA_MAP_ITEM' WHERE table_name = 'COMPLIANCE_ENHESA_MAP_ITEM';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
