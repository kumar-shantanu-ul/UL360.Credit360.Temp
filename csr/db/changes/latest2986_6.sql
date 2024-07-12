-- Please update version.sql too -- this keeps clean builds in sync
define version=2986
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE cms.cms_aggregate_type ADD (
	normalize_by_aggregate_type_id	NUMBER(10,0)
);

ALTER TABLE csrimp.cms_aggregate_type ADD (
	normalize_by_aggregate_type_id	NUMBER(10,0)
);

ALTER TABLE cms.cms_aggregate_type ADD CONSTRAINT fk_cms_agg_type_cms_agg_type
	FOREIGN KEY (app_sid, normalize_by_aggregate_type_id) REFERENCES cms.cms_aggregate_type(app_sid, cms_aggregate_type_id);

CREATE INDEX cms.ix_cms_agg_norm_by_agg_type_id ON cms.cms_aggregate_type (app_sid, normalize_by_aggregate_type_id);

DROP TYPE chain.T_FILTER_AGG_TYPE_TABLE;

CREATE OR REPLACE TYPE chain.T_FILTER_AGG_TYPE_ROW AS
	OBJECT (
		card_group_id					NUMBER(10),
		aggregate_type_id				NUMBER(10),
		description 					VARCHAR2(1023),
		format_mask						VARCHAR2(255),
		filter_page_ind_interval_id		NUMBER(10),
		accumulative					NUMBER(1),
		aggregate_group					VARCHAR2(255),
		unit_of_measure					VARCHAR2(255),
		normalize_by_aggregate_type_id	NUMBER(10)
	);
/

CREATE OR REPLACE TYPE chain.T_FILTER_AGG_TYPE_TABLE AS
	TABLE OF chain.T_FILTER_AGG_TYPE_ROW;
/

-- *** Grants ***
GRANT EXECUTE ON chain.T_FILTER_AGG_TYPE_TABLE TO csr;
GRANT EXECUTE ON chain.T_FILTER_AGG_TYPE_ROW TO csr;
GRANT EXECUTE ON chain.T_FILTER_AGG_TYPE_TABLE TO cms;
GRANT EXECUTE ON chain.T_FILTER_AGG_TYPE_ROW TO cms;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/cms/db/filter_pkg

@../audit_report_body
@../comp_regulation_report_body
@../comp_requirement_report_body
@../initiative_report_body
@../meter_list_body
@../meter_report_body
@../property_report_body
@../user_report_body

@../chain/filter_body

@../../../aspen2/cms/db/filter_body
@../../../aspen2/cms/db/tab_body

@../csrimp/imp_body

@update_tail
