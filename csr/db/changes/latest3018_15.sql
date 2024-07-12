-- Please update version.sql too -- this keeps clean builds in sync
define version=3018
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables
DROP TYPE CHAIN.T_BUS_REL_PATH_TABLE;
DROP TYPE CHAIN.T_BUS_REL_PATH_ROW;

DROP TYPE CHAIN.T_BUS_REL_COMP_TABLE;

CREATE OR REPLACE TYPE CHAIN.T_BUS_REL_COMP_ROW AS
	OBJECT (
		STARTING_COMPANY_SID		NUMBER(10),
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
		RETURN STARTING_COMPANY_SID||':'||BUSINESS_RELATIONSHIP_ID||'/'||BUSINESS_RELATIONSHIP_TIER_ID||'.'||POS;
	END;
END;
/

CREATE OR REPLACE TYPE CHAIN.T_BUS_REL_COMP_TABLE AS
	TABLE OF CHAIN.T_BUS_REL_COMP_ROW;
/

-- Alter tables
ALTER TABLE chain.company_tab ADD (
	business_relationship_type_id		NUMBER(10, 0),
	CONSTRAINT fk_company_tab_bus_rel_type FOREIGN KEY (app_sid, business_relationship_type_id) REFERENCES chain.business_relationship_type (app_sid, business_relationship_type_id)
);

CREATE INDEX chain.ix_company_tab_bus_rel_type ON chain.company_tab (app_sid, business_relationship_type_id);

ALTER TABLE csrimp.chain_company_tab ADD (
	business_relationship_type_id		NUMBER(10, 0)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
values (csr.plugin_id_seq.nextval, 10, 'Business Relationship Graph', '/csr/site/chain/manageCompany/controls/BusinessRelationshipGraph.js', 'Chain.ManageCompany.BusinessRelationshipGraph', 'Credit360.Chain.Plugins.BusinessRelationshipGraphDto', 'This tab shows a graph of business relationships for a company.');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/business_relationship_pkg
@../chain/plugin_pkg

@../schema_body
@../chain/business_relationship_body
@../chain/company_body
@../chain/company_filter_body
@../chain/plugin_body
@../csrimp/imp_body

@update_tail
