-- Please update version.sql too -- this keeps clean builds in sync
define version=3060
define minor_version=39
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
UPDATE csr.plugin
   SET js_class = 'Controls.IssuesPanel'
 WHERE js_class = 'Credit360.Property.Plugins.IssuesPanel';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
