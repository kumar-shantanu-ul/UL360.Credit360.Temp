-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=46
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csrimp.cms_tab
ADD policy_view VARCHAR(1024);

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
@@..\csrimp\imp_body
@@..\..\..\aspen2\cms\db\tab_body

@update_tail
