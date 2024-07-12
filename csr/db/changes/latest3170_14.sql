-- Please update version.sql too -- this keeps clean builds in sync
define version=3170
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.tag
ADD parent_id NUMBER(10);

ALTER TABLE csr.tag
ADD CONSTRAINT FK_PARENT_TAG_ID FOREIGN KEY(app_sid, parent_id) REFERENCES csr.tag(app_sid, tag_id);

CREATE INDEX csr.ix_tag_parent_id ON csr.tag (app_sid, parent_id);

ALTER TABLE csrimp.tag
ADD parent_id NUMBER(10);

ALTER TABLE csr.tag_group
ADD is_hierarchical NUMBER(1, 0) DEFAULT 0 NOT NULL;

ALTER TABLE csr.tag_group
ADD CONSTRAINT CHK_IS_HIERARCHICAL CHECK (IS_HIERARCHICAL IN (0, 1));

ALTER TABLE csrimp.tag_group
ADD is_hierarchical NUMBER(1, 0) NOT NULL;

ALTER TABLE csrimp.tag_group
ADD CONSTRAINT CHK_IS_HIERARCHICAL CHECK (IS_HIERARCHICAL IN (0, 1));


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.
CREATE OR REPLACE VIEW CSR.V$TAG_GROUP AS
	SELECT tg.app_sid, tg.tag_group_id, NVL(tgd.name, tgden.name) name,
		tg.multi_select, tg.mandatory, tg.applies_to_inds,
		tg.applies_to_regions, tg.applies_to_non_compliances, tg.applies_to_suppliers,
		tg.applies_to_initiatives, tg.applies_to_chain, tg.applies_to_chain_activities,
		tg.applies_to_chain_product_types, tg.applies_to_chain_products, tg.applies_to_chain_product_supps,
		tg.applies_to_quick_survey, tg.applies_to_audits,
		tg.applies_to_compliances, tg.lookup_key, tg.is_hierarchical
	  FROM csr.tag_group tg
	LEFT JOIN csr.tag_group_description tgd ON tgd.app_sid = tg.app_sid AND tgd.tag_group_id = tg.tag_group_id AND tgd.lang = SYS_CONTEXT('SECURITY', 'LANGUAGE')
	LEFT JOIN csr.tag_group_description tgden ON tgden.app_sid = tg.app_sid AND tgden.tag_group_id = tg.tag_group_id AND tgden.lang = 'en';

CREATE OR REPLACE VIEW CSR.V$TAG AS
	SELECT t.app_sid, t.tag_id, NVL(td.tag, tden.tag) tag, NVL(td.explanation, tden.explanation) explanation,
		t.lookup_key, t.exclude_from_dataview_grouping, t.parent_id
	  FROM csr.tag t
	LEFT JOIN csr.tag_description td ON td.app_sid = t.app_sid AND td.tag_id = t.tag_id AND td.lang = SYS_CONTEXT('SECURITY', 'LANGUAGE')
	LEFT JOIN csr.tag_description tden ON tden.app_sid = t.app_sid AND tden.tag_id = t.tag_id AND tden.lang = 'en';

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../tag_pkg

@../tag_body
@../schema_body
@../strategy_body
@../enable_body
@../integration_api_body

@../csrimp/imp_body

@update_tail
