-- Please update version.sql too -- this keeps clean builds in sync
define version=3111
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.plugin DROP CONSTRAINT ck_plugin_refs;
DROP INDEX csr.plugin_js_class;

ALTER TABLE csr.plugin ADD (
    PRE_FILTER_SID			NUMBER(10, 0),
	CONSTRAINT CK_PLUGIN_REFS CHECK(
        (TAB_SID IS NULL AND (FORM_PATH IS NULL AND FORM_SID IS NULL) AND
		 GROUP_KEY IS NULL AND
         (SAVED_FILTER_SID IS NULL AND PRE_FILTER_SID IS NULL) AND
         CONTROL_LOOKUP_KEYS IS NULL AND PORTAL_SID IS NULL)
        OR
        (APP_SID IS NOT NULL AND(
            (TAB_SID IS NOT NULL AND (FORM_PATH IS NOT NULL OR FORM_SID IS NOT NULL) AND
             GROUP_KEY IS NULL AND
             (SAVED_FILTER_SID IS NULL AND PRE_FILTER_SID IS NULL) AND
             PORTAL_SID IS NULL)
            OR
            (TAB_SID IS NULL AND (FORM_PATH IS NULL AND FORM_SID IS NULL) AND
			 GROUP_KEY IS NOT NULL AND
             (SAVED_FILTER_SID IS NULL AND PRE_FILTER_SID IS NULL) AND
             PORTAL_SID IS NULL)
            OR
            (TAB_SID IS NULL AND (FORM_PATH IS NULL AND FORM_SID IS NULL) AND
             GROUP_KEY IS NULL AND
             (SAVED_FILTER_SID IS NOT NULL OR PRE_FILTER_SID IS NOT NULL) AND
             PORTAL_SID IS NULL)
            OR
            (TAB_SID IS NULL AND (FORM_PATH IS NULL AND FORM_SID IS NULL) AND
             GROUP_KEY IS NULL AND
             (SAVED_FILTER_SID IS NULL AND PRE_FILTER_SID IS NULL) AND
             PORTAL_SID IS NOT NULL)
        ))
    )
);

CREATE UNIQUE INDEX csr.plugin_js_class ON CSR.PLUGIN(APP_SID, JS_CLASS, FORM_PATH, GROUP_KEY, SAVED_FILTER_SID, RESULT_MODE, PORTAL_SID, R_SCRIPT_PATH, FORM_SID, PRE_FILTER_SID);

CREATE INDEX csr.ix_plugin_pre_filter ON CSR.PLUGIN (APP_SID, PRE_FILTER_SID);

ALTER TABLE csrimp.plugin ADD (
    PRE_FILTER_SID			NUMBER(10, 0)
);

-- *** Grants ***

-- ** Cross schema constraints ***
ALTER TABLE csr.plugin 
ADD CONSTRAINT fk_plugin_pre_filter 
FOREIGN KEY (app_sid, pre_filter_sid) 
REFERENCES chain.saved_filter(app_sid, saved_filter_sid);

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	BEGIN
		INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
		VALUES (csr.plugin_id_seq.NEXTVAL, 10, 'Product list (Purchaser)', '/csr/site/chain/manageCompany/controls/ProductListPurchaserTab.js', 'Chain.ManageCompany.ProductListPurchaserTab', 'Credit360.Chain.Plugins.ProductListDto', 'This tab shows the product list for a purchaser.');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/

UPDATE csr.plugin 
   SET js_include = '/csr/site/chain/managecompany/controls/BusinessRelationshipListTab.js' 
 WHERE js_include = '/csr/site/chain/managecompany/controls/BusinessRelationshipList.js';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../plugin_pkg

@../chain/filter_pkg

@../audit_report_pkg
@../compliance_library_report_pkg
@../compliance_register_report_pkg
@../initiative_report_pkg
@../issue_report_pkg
@../meter_list_pkg
@../meter_report_pkg
@../non_compliance_report_pkg
@../permit_report_pkg
@../property_report_pkg
@../question_library_report_pkg
@../quick_survey_report_pkg
@../region_report_pkg
@../user_report_pkg
@../chain/activity_report_pkg
@../chain/business_rel_report_pkg
@../chain/certification_report_pkg
@../chain/company_filter_pkg
@../chain/company_request_report_pkg
@../chain/dedupe_proc_record_report_pkg
@../chain/product_report_pkg
@../chain/product_metric_report_pkg
@../chain/product_supplier_report_pkg
@../chain/prdct_supp_mtrc_report_pkg
--@../surveys/question_library_report_pkg

@../../../aspen2/cms/db/filter_pkg.sql

@../plugin_body
@../audit_body
@../meter_body
@../permit_body
@../property_body
@../chain/plugin_body

@../chain/filter_body

@../audit_report_body
@../compliance_library_report_body
@../compliance_register_report_body
@../initiative_report_body
@../issue_report_body
@../meter_list_body
@../meter_report_body
@../non_compliance_report_body
@../permit_report_body
@../property_report_body
@../question_library_report_body
@../quick_survey_report_body
@../region_report_body
@../user_report_body
@../chain/activity_report_body
@../chain/business_rel_report_body
@../chain/certification_report_body
@../chain/company_filter_body
@../chain/company_request_report_body
@../chain/dedupe_proc_record_report_body
@../chain/product_report_body
@../chain/product_metric_report_body
@../chain/product_supplier_report_body
@../chain/prdct_supp_mtrc_report_body
--@../surveys/question_library_report_body

@../../../aspen2/cms/db/filter_body.sql

@../schema_body
@../csrimp/imp_body

@update_tail
