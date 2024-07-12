-- Please update version.sql too -- this keeps clean builds in sync
define version=3117
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

BEGIN
	BEGIN
		INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
		VALUES (csr.plugin_id_seq.nextval, 10, 'Product supplier list (Company)', '/csr/site/chain/manageCompany/controls/ProductSupplierListTab.js', 'Chain.ManageCompany.ProductSupplierListTab', 'Credit360.Chain.Plugins.ProductSupplierListDto', 'This tab shows the product supplier list for a company.');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
		VALUES (csr.plugin_id_seq.nextval, 10, 'Product supplier list (Purchaser)', '/csr/site/chain/manageCompany/controls/ProductSupplierListPurchaserTab.js', 'Chain.ManageCompany.ProductSupplierListPurchaserTab', 'Credit360.Chain.Plugins.ProductSupplierListDto', 'This tab shows the product supplier list for a purchaser.');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
		VALUES (csr.plugin_id_seq.nextval, 10, 'Product supplier list (Supplier)', '/csr/site/chain/manageCompany/controls/ProductSupplierListSupplierTab.js', 'Chain.ManageCompany.ProductSupplierListSupplierTab', 'Credit360.Chain.Plugins.ProductSupplierListDto', 'This tab shows the product supplier list for a supplier.');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
