-- Please update version.sql too -- this keeps clean builds in sync
define version=3156
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE surveys.import_map_item
MODIFY other_option NUMBER(10);


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

--@../surveys/import_map_pkg
--@../surveys/import_map_body

@update_tail
