-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=24
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
INSERT INTO csr.plugin
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES
	(csr.plugin_id_seq.nextval, 10, 'Supplier list expandable', '/csr/site/chain/managecompany/controls/SupplierListExpandableTab.js',
		'Chain.ManageCompany.SupplierListExpandableTab', 'Credit360.Chain.Plugins.SupplierListExpandable',
		'Same as supplier list plus extra column with expandable row with companies related to a particular company.');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../chain/company_filter_pkg
@../chain/company_filter_body

@update_tail
