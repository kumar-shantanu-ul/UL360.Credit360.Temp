-- Please update version.sql too -- this keeps clean builds in sync
define version=3225
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE chain.saved_filter ADD (
	map_colour_by					VARCHAR2(255)
);

ALTER TABLE csrimp.chain_saved_filter ADD (
	map_colour_by					VARCHAR2(255)
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
@../schema_body
@../csrimp/imp_body

@../chain/filter_pkg
@../chain/filter_body

@update_tail
