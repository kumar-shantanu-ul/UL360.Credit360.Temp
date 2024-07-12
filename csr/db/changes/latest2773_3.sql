-- Please update version.sql too -- this keeps clean builds in sync
define version=2773
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables
CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_FILTER_DATE_RANGE (
	FILTER_VALUE_ID NUMBER(10) NOT NULL,
	GROUP_BY_INDEX NUMBER(10),
	START_DTM DATE,
	END_DTM DATE
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CMS.TT_ID_NO_INDEX
( 
	ID							NUMBER(10) NOT NULL
) 
ON COMMIT DELETE ROWS; 

-- Alter tables
CREATE INDEX csr.ix_flow_item_item_current_stat on csr.flow_item(app_sid, flow_item_id, current_state_id);

-- *** Grants ***
GRANT SELECT ON chain.tt_filter_date_range TO csr;
GRANT SELECT ON chain.tt_filter_date_range TO cms;

grant execute on aspen2.ordered_stragg to cms;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@..\chain\filter_pkg

@..\non_compliance_report_body
@..\audit_report_body
@..\issue_report_body
@..\issue_body
@..\quick_survey_body
@..\supplier_body
@..\property_report_body
@..\chain\company_filter_body
@..\chain\filter_body
@..\chain\business_relationship_body
@..\chain\company_body
@..\chain\product_body
@..\chain\report_body
@..\..\..\aspen2\cms\db\filter_body

@update_tail
