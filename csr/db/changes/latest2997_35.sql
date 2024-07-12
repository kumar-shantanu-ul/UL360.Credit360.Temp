-- Please update version.sql too -- this keeps clean builds in sync
define version=2997
define minor_version=35
@update_header

-- *** DDL ***
-- Create tables
CREATE OR REPLACE TYPE CSR.T_REGION_METRIC_AUDIT_ROW AS 
  OBJECT ( 
	REGION_METRIC_VAL_ID	NUMBER(10),
	IND_SID					NUMBER(10),
	CONVERSION_ID			NUMBER(10),
	VAL						NUMBER(24, 10),
	EFFECTIVE_DTM			DATE
);
/
CREATE OR REPLACE TYPE CSR.T_REGION_METRIC_AUDIT_TABLE AS 
  TABLE OF CSR.T_REGION_METRIC_AUDIT_ROW;
/

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.audit_type_group (audit_type_group_id, description)
VALUES (5, 'Metric object');

INSERT INTO csr.audit_type (audit_type_id, label, audit_type_group_id)
VALUES (500, 'Region metric change', 5);

INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
VALUES (85, 1, 'Property audit log', '/csr/site/property/properties/controls/AuditLogPanel.js', 'Controls.AuditLogPanel', 'Credit360.Plugins.PluginDto', 'This tab shows an audit log of this property and all associated spaces, meters and metrics', '', '');

BEGIN
	INSERT INTO csr.user_setting (category, setting, description, data_type)
	VALUES ('CREDIT360.PROPERTY', 'activeTab', 'stores the last active plugin tab', 'STRING');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../region_metric_pkg
@../csr_data_pkg
@../property_pkg
@../region_metric_body
@../property_body

@update_tail
