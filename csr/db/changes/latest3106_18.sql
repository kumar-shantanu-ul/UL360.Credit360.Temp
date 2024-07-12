-- Please update version.sql too -- this keeps clean builds in sync
define version=3106
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

UPDATE csr.meter_source_type SET description = 'Urjanet meter' WHERE name ='period-null-start-dtm'

DELETE FROM csr.module where module_id = 96;


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

@../enable_pkg
@../enable_body

@update_tail
