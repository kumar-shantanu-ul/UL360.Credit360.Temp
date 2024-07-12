-- Please update version.sql too -- this keeps clean builds in sync
define version=3462
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DROP TABLE CMS.TEMP_REGION_PATH;
DROP TABLE CMS.TEMP_IND_PATH;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
