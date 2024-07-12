-- Please update version.sql too -- this keeps clean builds in sync
define version=2844
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
UPDATE security.menu
   SET action = '/csr/site/admin/trash/trash.acds'
 WHERE LOWER(action) = LOWER('/csr/site/admin/trash.acds');

-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../csr_data_pkg
@../dataview_pkg
@../indicator_pkg
@../quick_survey_pkg
@../region_pkg
@../trash_pkg
@../dataview_body
@../indicator_body
@../quick_survey_body
@../region_body
@../trash_body

@update_tail
