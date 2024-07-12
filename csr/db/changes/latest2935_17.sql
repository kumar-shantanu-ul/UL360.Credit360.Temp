-- Please update version.sql too -- this keeps clean builds in sync
define version=2935
define minor_version=17
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
INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class)
SELECT 
	csr.plugin_id_seq.NEXTVAL, 
	16,
	'Low-res chart', 
	'/csr/site/meter/controls/meterLowResChartTab.js', 
	'Credit360.Metering.MeterLowResChartTab', 
	'Credit360.Metering.Plugins.MeterLowResChart'
FROM dual
WHERE NOT EXISTS(
	SELECT * 
	  FROM csr.plugin 
	 WHERE js_class = 'Credit360.Metering.MeterLowResChartTab' 
	   AND plugin_type_id = 16
);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
