-- Please update version.sql too -- this keeps clean builds in sync
define version=2989
define minor_version=29
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
INSERT INTO csr.plugin (
	plugin_id, 
	plugin_type_id, 
	description, 
	js_include, 
	js_class, 
	cs_class, 
	details
) VALUES (
	csr.plugin_id_seq.nextval, 
	10, 
	'Document library', 
	'/csr/site/chain/managecompany/controls/DocLibTab.js',
	'Chain.ManageCompany.DocLibTab', 
	'Credit360.Chain.Plugins.DocLibTabDto', 
	'This tab will show the document library for the selected company.'
);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../supplier_pkg
@../supplier_body

@update_tail
