-- Please update version.sql too -- this keeps clean builds in sync
define version=2912
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

UPDATE csr.flow_state
   SET lookup_key = null
 WHERE is_deleted = 1;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../flow_body

@update_tail
