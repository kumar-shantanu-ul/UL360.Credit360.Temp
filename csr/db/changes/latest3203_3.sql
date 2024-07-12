-- Please update version.sql too -- this keeps clean builds in sync
define version=3203
define minor_version=3
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
UPDATE chain.card
   SET class_type = 'Credit360.Schema.Cards.RegionFilter'
 WHERE class_type = 'Credit360.Region.Cards.RegionFilter';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
