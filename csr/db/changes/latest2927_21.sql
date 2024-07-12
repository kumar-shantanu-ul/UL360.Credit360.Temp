-- Please update version.sql too -- this keeps clean builds in sync
define version=2927
define minor_version=21
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
INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
VALUES (NULL, csr.plugin_id_seq.nextval, 16, 'Meter data quick chart', '/csr/site/meter/controls/meterListTab.js', 'Credit360.Metering.MeterQuickChartTab', 'Credit360.Metering.Plugins.MeterQuickChartTab', 'Display data for the meter in a calendar view, chart, list, or pivot table.', '/csr/shared/plugins/screenshots/property_tab_meter_list.png');

INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
VALUES (NULL, csr.plugin_id_seq.nextval, 16, 'Meter audit log', '/csr/site/meter/controls/AuditLogTab.js', 'Credit360.Metering.AuditLogTab', 'Credit360.Metering.Plugins.AuditLogTab', 'Log changes to the meter region and any patches made to the meter data.', '/csr/shared/plugins/screenshots/meter_audit_log_tab.png');

INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
VALUES (NULL, csr.plugin_id_seq.nextval, 16, 'Actions tab', '/csr/site/meter/controls/IssuesTab.js', 'Credit360.Metering.IssuesTab', 'Credit360.Plugins.PluginDto', 'Show all actions associated with the meter, and raise new actions.', '/csr/shared/plugins/screenshots/meter_issue_list_tab.png');

-- Update meter list tab description for quick charts.
UPDATE csr.plugin
   SET description = 'Meter data quick chart'
 WHERE js_class = 'Credit360.Metering.MeterListTab'
   AND app_sid IS NULL
   AND js_include = '/csr/site/meter/controls/meterListTab.js'
   AND description = 'Meter data list';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\meter_pkg
@..\csr_data_pkg

@..\meter_body
@..\issue_body
@..\enable_body
@..\util_script_body

@update_tail
