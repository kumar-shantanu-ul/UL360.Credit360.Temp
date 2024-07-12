-- Please update version.sql too -- this keeps clean builds in sync
define version=3381
define minor_version=1
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
INSERT INTO csr.plugin 
(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
VALUES 
(csr.plugin_id_seq.nextval, 1, 'Certifications', '/csr/site/property/properties/controls/CertificationsTab.js',
 'Controls.CertificationsTab', 'Credit360.Plugins.PluginDto', 'Certifications Tab', null);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
