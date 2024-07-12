-- Please update version.sql too -- this keeps clean builds in sync
define version=3147
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables
-- No FK to filter_value, not required as extra rows do no harm and get cleaned up anyway
CREATE TABLE chain.filter_field_top_n_cache (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	filter_field_id					NUMBER(10) NOT NULL,
	group_by_index					NUMBER(1) NOT NULL,
	filter_value_id					NUMBER(10) NOT NULL,
	CONSTRAINT pk_filter_field_top_n_cache PRIMARY KEY (app_sid, filter_field_id, group_by_index, filter_value_id),
	CONSTRAINT fk_flt_fld_top_n_cache_flt_fld FOREIGN KEY (app_sid, filter_field_id)
		REFERENCES chain.filter_field (app_sid, filter_field_id)
		ON DELETE CASCADE
);

-- Alter tables

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
@..\chain\filter_pkg

@..\..\..\aspen2\cms\db\filter_body
@..\audit_report_body
@..\chain\activity_report_body
@..\chain\bsci_2009_audit_report_body
@..\chain\bsci_2014_audit_report_body
@..\chain\bsci_ext_audit_report_body
@..\chain\bsci_supplier_report_body
@..\chain\business_rel_report_body
@..\chain\certification_report_body
@..\chain\company_filter_body
@..\chain\company_request_report_body
@..\chain\dedupe_proc_record_report_body
@..\chain\filter_body
@..\chain\prdct_supp_mtrc_report_body
@..\chain\product_metric_report_body
@..\chain\product_report_body
@..\chain\product_supplier_report_body
@..\compliance_library_report_body
@..\compliance_register_report_body
@..\initiative_report_body
@..\issue_report_body
@..\meter_list_body
@..\meter_report_body
@..\non_compliance_report_body
@..\permit_report_body
@..\property_report_body
@..\question_library_report_body
@..\quick_survey_report_body
@..\region_report_body
@..\user_report_body
@..\chain\chain_body

@update_tail
