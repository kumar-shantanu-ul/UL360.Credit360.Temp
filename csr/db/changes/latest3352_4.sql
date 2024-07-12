-- Please update version.sql too -- this keeps clean builds in sync
define version=3352
define minor_version=4
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
UPDATE csr.util_script
   SET wiki_article = 'W3737'
 WHERE util_script_id = 66;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
