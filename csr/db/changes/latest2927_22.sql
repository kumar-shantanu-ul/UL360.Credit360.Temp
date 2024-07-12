-- Please update version.sql too -- this keeps clean builds in sync
define version=2927
define minor_version=22
@update_header

-- *** DDL ***
-- Create tables
DROP TYPE CHAIN.T_FILTER_AGG_TYPE_TABLE;
CREATE OR REPLACE TYPE CHAIN.T_FILTER_AGG_TYPE_ROW AS 
	 OBJECT ( 
		CARD_GROUP_ID				NUMBER(10),
		AGGREGATE_TYPE_ID			NUMBER(10),	
		DESCRIPTION 				VARCHAR2(1023),
		FORMAT_MASK					VARCHAR2(255),
		FILTER_PAGE_IND_INTERVAL_ID	NUMBER(10),
		ACCUMULATIVE				NUMBER(1),
		AGGREGATE_GROUP				VARCHAR2(255),
		UNIT_OF_MEASURE				VARCHAR2(255)
	 ); 
/
CREATE OR REPLACE TYPE CHAIN.T_FILTER_AGG_TYPE_TABLE AS 
	TABLE OF CHAIN.T_FILTER_AGG_TYPE_ROW;
/

-- Alter tables
ALTER TABLE chain.saved_filter ADD (
	dual_axis NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_dual_axis CHECK (dual_axis IN (0, 1))
);

ALTER TABLE csrimp.chain_saved_filter ADD (
	dual_axis NUMBER(1) NULL
);

UPDATE csrimp.chain_saved_filter SET dual_axis = 0;
ALTER TABLE csrimp.chain_saved_filter MODIFY(dual_axis NUMBER(1) NOT NULL);


-- *** Grants ***
GRANT EXECUTE ON chain.t_filter_agg_type_table TO csr;
GRANT EXECUTE ON chain.t_filter_agg_type_row TO csr;
GRANT EXECUTE ON chain.t_filter_agg_type_table TO cms;
GRANT EXECUTE ON chain.t_filter_agg_type_row TO cms;

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

@../meter_report_body
@../chain/filter_body
@../initiative_report_body
@../property_report_body
@../user_report_body
@../schema_body
@../csrimp/imp_body
@../../../aspen2/cms/db/filter_body

@update_tail
