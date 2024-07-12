-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.customer_options ADD (
	show_extra_details_in_graph				NUMBER(1) DEFAULT 0 NOT NULL
);
ALTER TABLE chain.customer_options ADD CONSTRAINT chk_show_ext_det_in_grph CHECK (show_extra_details_in_graph IN (0,1));

ALTER TABLE csrimp.chain_customer_options ADD (
	show_extra_details_in_graph				NUMBER(1) DEFAULT 0 NOT NULL
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
@../chain/helper_body
@../csrimp/imp_body
@../schema_body

@update_tail
