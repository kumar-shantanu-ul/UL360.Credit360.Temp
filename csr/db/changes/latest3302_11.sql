-- Please update version.sql too -- this keeps clean builds in sync
define version=3302
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.auto_exp_class_qc_settings (
    app_sid                         NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    automated_export_class_sid      NUMBER(10, 0)   NOT NULL,
	saved_filter_sid				NUMBER(10, 0)   NOT NULL,
    CONSTRAINT pk_auto_exp_class_qc_settings PRIMARY KEY (app_sid, automated_export_class_sid)
);

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO csr.auto_exp_exporter_plugin_type (plugin_type_id, label)
VALUES (5, 'Quick Chart Exporter');

INSERT INTO csr.auto_exp_exporter_plugin (
	plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter, plugin_type_id
) VALUES (
	23,
	'Quick Chart Export',
	'Credit360.ExportImport.Automated.Export.Exporters.QuickChart.QuickChartExporter',
	'Credit360.ExportImport.Automated.Export.Exporters.QuickChart.QuickChartOutputter',
	0,
	5
);

INSERT INTO csr.schema_table (owner, table_name) VALUES ('CSR', 'AUTO_EXP_CLASS_QC_SETTINGS');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_export_pkg
@../automated_export_body

@update_tail
