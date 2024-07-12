-- Please update version.sql too -- this keeps clean builds in sync
define version=3013
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables
DROP TYPE CHAIN.T_BUS_REL_COMP_TABLE;

CREATE OR REPLACE TYPE CHAIN.T_BUS_REL_COMP_ROW AS
	OBJECT (
		BUSINESS_RELATIONSHIP_ID	NUMBER(10),
		BUSINESS_RELATIONSHIP_TIER_ID	NUMBER(10),
		POS							NUMBER(10),
		COMPANY_SID					NUMBER(10),
		MAP MEMBER FUNCTION MAP
			RETURN VARCHAR2
	);
/

CREATE OR REPLACE TYPE BODY CHAIN.T_BUS_REL_COMP_ROW AS
	MAP MEMBER FUNCTION MAP
		RETURN VARCHAR2
	IS
	BEGIN
		RETURN BUSINESS_RELATIONSHIP_ID||'/'||BUSINESS_RELATIONSHIP_TIER_ID||'/'||POS;
	END;
END;
/

CREATE OR REPLACE TYPE CHAIN.T_BUS_REL_COMP_TABLE AS
	TABLE OF CHAIN.T_BUS_REL_COMP_ROW;
/

-- Alter tables
ALTER TABLE chain.business_relationship_tier ADD (
	allow_multiple_companies			NUMBER(1, 0) DEFAULT 0 NOT NULL
);

ALTER TABLE csrimp.chain_busine_relati_tier ADD (
	allow_multiple_companies			NUMBER(1, 0) NOT NULL
);

ALTER TABLE chain.business_relationship_company DROP PRIMARY KEY;
ALTER TABLE chain.business_relationship_company ADD (
	pos									NUMBER(10, 0) DEFAULT 0 NOT NULL
);
ALTER TABLE chain.business_relationship_company ADD CONSTRAINT pk_bus_rel_company PRIMARY KEY (app_sid, business_relationship_id, business_relationship_tier_id, pos);

ALTER TABLE csrimp.chain_busin_relat_compan DROP PRIMARY KEY;
ALTER TABLE csrimp.chain_busin_relat_compan ADD (
	pos									NUMBER(10, 0) NOT NULL
);
ALTER TABLE csrimp.chain_busin_relat_compan ADD CONSTRAINT pk_chain_busin_relat_compan PRIMARY KEY (csrimp_session_id, business_relationship_id, business_relationship_tier_id, pos);

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
