-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=43
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- Need to change the data first, as there are already some nulls in there.
-- Make them all Manual DB reader
UPDATE csr.automated_import_class_step
  SET fileread_plugin_id = 3
 WHERE fileread_plugin_id IS NULL;

ALTER TABLE csr.automated_import_class_step
MODIFY fileread_plugin_id NOT NULL;

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

@update_tail
