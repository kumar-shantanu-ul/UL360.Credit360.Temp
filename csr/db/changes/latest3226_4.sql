-- Please update version.sql too -- this keeps clean builds in sync
define version=3226
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.saved_filter ADD (
	map_cluster_bias				NUMBER(2)
);

ALTER TABLE csrimp.chain_saved_filter ADD (
	map_cluster_bias				NUMBER(2)
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
