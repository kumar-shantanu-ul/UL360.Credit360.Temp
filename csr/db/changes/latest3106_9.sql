-- Please update version.sql too -- this keeps clean builds in sync
define version=3106
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DROP INDEX CHAIN.IX_COMPANY_PRODUCT_SKU;
ALTER TABLE chain.company_product RENAME COLUMN sku TO product_ref;
ALTER TABLE chain.company_product MODIFY (product_ref NULL);
CREATE UNIQUE INDEX CHAIN.IX_COMPANY_PRODUCT_REF ON CHAIN.COMPANY_PRODUCT(APP_SID, COMPANY_SID, LOWER(NVL(PRODUCT_REF, 'NOPRODUCTREF_' || PRODUCT_ID)));

ALTER TABLE chain.product_supplier ADD (
	PRODUCT_SUPPLIER_REF				VARCHAR2(1024)
);
CREATE UNIQUE INDEX CHAIN.IX_PRODUCT_SUPPLIER_REF ON CHAIN.PRODUCT_SUPPLIER(APP_SID, PRODUCT_ID, LOWER(NVL(PRODUCT_SUPPLIER_REF, 'NOSUPPLIERREF_' || PRODUCT_SUPPLIER_ID)));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- C:\cvs\csr\db\chain\create_views.sql
CREATE OR REPLACE VIEW chain.v$company_product AS
	SELECT cp.app_sid, cp.product_id, tr.description product_name, cp.company_sid, cp.product_type_id,
		   cp.product_ref, cp.lookup_key, cp.is_active
	  FROM chain.company_product cp
	  JOIN chain.company_product_tr tr ON tr.product_id = cp.product_id AND tr.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.logonadmin;

	UPDATE chain.saved_filter_alert_param
	   SET field_name = 'PRODUCT_REF', description = 'Product Reference'
	 WHERE field_name = 'SKU';
END;
/

DECLARE
	v_plugin_id			NUMBER(10, 0);
BEGIN
	security.user_pkg.logonadmin;

	BEGIN
		SELECT plugin_id
		  INTO v_plugin_id
		  FROM csr.plugin WHERE js_class = 'Chain.ManageProduct.ProductDetailsTab';

		DELETE FROM chain.product_tab_product_type
		 WHERE product_tab_id IN (
			SELECT product_tab_id
			  FROM chain.product_tab
			 WHERE plugin_id = v_plugin_id
		 );
		
		DELETE FROM chain.product_tab
		 WHERE plugin_id = v_plugin_id;

		DELETE FROM csr.plugin
		 WHERE plugin_id = v_plugin_id;
	EXCEPTION
		WHEN no_data_found THEN
			NULL;
	END;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/company_product_pkg

@../chain/company_product_body
@../chain/product_report_body
@../chain/product_supplier_report_body

@update_tail
