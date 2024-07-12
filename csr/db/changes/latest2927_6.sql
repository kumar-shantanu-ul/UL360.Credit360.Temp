-- Please update version.sql too -- this keeps clean builds in sync
define version=2927
define minor_version=6
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

UPDATE chain.aggregate_type
   SET description = 'Total'
 WHERE card_group_id = 46 
   AND description = 'Total consumption';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
