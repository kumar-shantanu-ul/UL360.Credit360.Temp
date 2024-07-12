-- Please update version.sql too -- this keeps clean builds in sync
define version=3065
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.saved_filter_column ADD (
	label							VARCHAR2(1024)
);

ALTER TABLE csrimp.chain_saved_filter_column ADD (
	label							VARCHAR2(1024)
);

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
@../chain/filter_pkg

@../chain/filter_body
@../csrimp/imp_body
@../schema_body

@update_tail
