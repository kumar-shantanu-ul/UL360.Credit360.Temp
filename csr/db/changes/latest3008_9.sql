-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=9
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
UPDATE csr.capability 
   SET description = 'Data Explorer: Displays checkboxes in Data Explorer allowing users to display the percentage or absolute variances between periods on charts (either between consecutive periods or between a specified baseline period and each subsequent period).'
 WHERE name = 'Enable Dataview Bar Variance Options';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
