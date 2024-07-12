-- Please update version.sql too -- this keeps clean builds in sync
define version=3168
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csrimp.enhesa_options
MODIFY (
	packages_imported DEFAULT NULL,
	packages_total DEFAULT NULL,
	items_imported DEFAULT NULL,
	items_total DEFAULT NULL,
	links_created DEFAULT NULL,
	links_total DEFAULT NULL
);


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
