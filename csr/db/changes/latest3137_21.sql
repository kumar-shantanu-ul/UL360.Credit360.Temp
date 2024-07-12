-- Please update version.sql too -- this keeps clean builds in sync
define version=3137
define minor_version=21
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
	insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	values (csr.plugin_id_seq.nextval, 10, 'BSCI supplier details', '/csr/site/chain/manageCompany/controls/BsciSupplierDetailsTab.js', 'Chain.ManageCompany.BsciSupplierDetailsTab', 'Credit360.Chain.Plugins.BsciSupplierDetailsDto', 'This tab shows the BSCI details for a supplier.');
	
	insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	values (csr.plugin_id_seq.nextval, 13, 'BSCI supplier details', '/csr/site/audit/controls/BsciSupplierDetailsTab.js', 'Audit.Controls.BsciSupplierDetailsTab', 'Credit360.Audit.Plugins.BsciSupplierDetailsDto', 'This tab shows the current BSCI details for the company being audited.');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/bsci_pkg
@../chain/bsci_body

@update_tail
