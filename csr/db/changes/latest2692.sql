-- Please update version.sql too -- this keeps clean builds in sync
define version=2692
@update_header

-- *** DDL ***
-- Create tables
ALTER TABLE chain.business_relationship_tier ADD (
	  create_supplier_relationship			 NUMBER(1, 0)
);

UPDATE chain.business_relationship_tier
SET create_supplier_relationship = 0
WHERE create_supplier_relationship IS NULL
AND tier > 1;

ALTER TABLE chain.business_relationship_tier ADD (
	CONSTRAINT ck_bus_rel_tier_create_sup_rel CHECK (
	  			 (tier = 1 AND create_supplier_relationship IS NULL) OR
				 (tier > 1 AND create_supplier_relationship IN (0, 1))
	)
);

ALTER TABLE csrimp.chain_busine_relati_tier ADD (
	  create_supplier_relationship			 NUMBER(1, 0)
);

ALTER TABLE chain.business_relationship_tier ADD (
	  create_new_company					 NUMBER(1, 0)
);

UPDATE chain.business_relationship_tier
SET create_new_company = 0
WHERE create_new_company IS NULL;

ALTER TABLE chain.business_relationship_tier MODIFY (
	  create_new_company					 DEFAULT 0 NOT NULL
);

ALTER TABLE csrimp.chain_busine_relati_tier ADD (
	  create_new_company					NUMBER(1, 0)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../chain/business_relationship_pkg

@../chain/type_capability_body
@../chain/company_body
@../chain/business_relationship_body
@../schema_body
@../csrimp/imp_body

@update_tail
