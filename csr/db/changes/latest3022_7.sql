-- Please update version.sql too -- this keeps clean builds in sync
define version=3022
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.business_relationship_tier ADD (
	create_sup_rels_w_lower_tiers			NUMBER(1, 0) DEFAULT 0 NOT NULL,
	CONSTRAINT ck_bus_rel_tier_ctsrwlt CHECK (create_sup_rels_w_lower_tiers IN (0, 1))
);

ALTER TABLE csrimp.chain_busine_relati_tier ADD (
	create_sup_rels_w_lower_tiers			NUMBER(1, 0) NOT NULL
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
@../chain/business_relationship_pkg

@../chain/business_relationship_body
@../schema_body
@../csrimp/imp_body

@update_tail
