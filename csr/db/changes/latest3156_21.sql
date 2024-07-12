-- Please update version.sql too -- this keeps clean builds in sync
define version=3156
define minor_version=21
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
UPDATE csr.ind 
   SET target_direction = -1 
 WHERE gas_type_id is not null
   AND target_direction != -1;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../indicator_body

@update_tail
