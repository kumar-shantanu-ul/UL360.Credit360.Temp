-- Please update version.sql too -- this keeps clean builds in sync
define version=3070
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
UPDATE csr.flow_capability
   SET description = 'Edit indicator mapping'
 WHERE flow_capability_id = 21;

UPDATE csr.flow_capability
   SET description = 'Clear indicator mapping'
 WHERE flow_capability_id = 22;
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../section_body

@update_tail