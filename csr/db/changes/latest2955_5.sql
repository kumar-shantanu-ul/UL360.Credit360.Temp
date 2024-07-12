-- Please update version.sql too -- this keeps clean builds in sync
define version=2955
define minor_version=5
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
INSERT INTO csr.plugin_type
	(plugin_type_id, description)
VALUES
	(17, 'Emission factor tab');

INSERT INTO csr.plugin
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES
	(csr.plugin_id_seq.nextval, 17, 'Emissions profiles', '/csr/site/admin/emissionFactors/controls/EmissionProfilesTab.js',
		'Controls.EmissionProfilesTab', 'Credit360.Plugins.PluginDto', 'This tab will hold the options to manage emission factor profiles.');

INSERT INTO csr.plugin
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES
	(csr.plugin_id_seq.nextval, 17, 'Map indicators', '/csr/site/admin/emissionFactors/controls/MapIndicatorsTab.js',
		'Controls.MapIndicatorsTab', 'Credit360.Plugins.PluginDto', 'This tab will hold the options to manage the emission factor indicator mappings.');
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../factor_pkg
@../factor_body

@update_tail