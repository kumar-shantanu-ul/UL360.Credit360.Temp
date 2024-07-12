-- Please update version.sql too -- this keeps clean builds in sync
define version=3096
define minor_version=3
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
insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
values (CSR.PLUGIN_ID_SEQ.nextval, 1, 'Compliance Tab', '/csr/site/property/properties/controls/ComplianceTab.js', 'Controls.ComplianceTab', 'Credit360.Property.Plugins.CompliancePlugin', 'Shows Compliance Legal Register.');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body
@../compliance_register_report_pkg
@../compliance_register_report_body

@update_tail
