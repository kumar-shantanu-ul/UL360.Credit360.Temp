-- Please update version.sql too -- this keeps clean builds in sync
define version=3047
define minor_version=9
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
UPDATE csr.plugin SET cs_class = 'Credit360.Plugins.EmptyDto' WHERE js_class = 'Chain.ManageProduct.ProductHeader';

BEGIN
	BEGIN
		insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
		values (96, 19, 'Chain Product Certifications Tab', '/csr/site/chain/manageProduct/controls/ProductCertificationsTab.js', 'Chain.ManageProduct.ProductCertificationsTab', 'Credit360.Chain.Plugins.ProductCertificationsDto', 'This tab shows the certifications attached to a product.');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;

	BEGIN
		insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
		values (97, 20, 'Chain Product Supplier Certifications Tab', '/csr/site/chain/manageProduct/controls/ProductSupplierCertificationsTab.js', 'Chain.ManageProduct.ProductSupplierCertificationsTab', 'Credit360.Chain.Plugins.ProductSupplierCertificationsDto', 'This tab shows the certifications attached to a product supplier.');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/company_product_pkg
@../chain/company_product_body

@update_tail
