-- Please update version.sql too -- this keeps clean builds in sync
define version=3057
define minor_version=18
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
INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (csr.plugin_id_seq.nextval, 10, 'Product list (Company)', '/csr/site/chain/manageCompany/controls/ProductListTab.js', 'Chain.ManageCompany.ProductListTab', 'Credit360.Chain.Plugins.ProductListDto', 'This tab shows the product list for a company.');

INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (csr.plugin_id_seq.nextval, 10, 'Product list (Supplier)', '/csr/site/chain/manageCompany/controls/ProductListSupplierTab.js', 'Chain.ManageCompany.ProductListSupplierTab', 'Credit360.Chain.Plugins.ProductListDto', 'This tab shows the product list for a supplier.');

-- ** New package grants **
grant execute on chain.product_report_pkg to csr;
grant execute on chain.product_report_pkg to web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/company_product_pkg
@../chain/company_filter_pkg

@../enable_body
@../chain/card_body
@../chain/company_filter_body
@../chain/setup_body

@update_tail
