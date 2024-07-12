-- Please update version.sql too -- this keeps clean builds in sync
define version=2904
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.automated_export_instance
ADD is_preview number(1) default 0 NOT NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can run additional automated import instances', 0);
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

BEGIN
	INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can run additional automated export instances', 0);
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

BEGIN
	INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can preview automated exports', 0);
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

-- Add the new capabilities to any site with exports or imports
BEGIN

	FOR r IN (
		SELECT host
		  FROM csr.customer
		 WHERE app_sid IN (
			SELECT app_sid
			  FROM csr.automated_export_class
			UNION
			SELECT app_sid 
			  FROM csr.automated_import_class
		)
	)
	LOOP
		security.user_pkg.logonAdmin(r.host);
		csr.csr_data_pkg.enablecapability('Manually import automated import instances');
		csr.csr_data_pkg.enablecapability('Can run additional automated import instances');
		csr.csr_data_pkg.enablecapability('Can run additional automated export instances');
		csr.csr_data_pkg.enablecapability('Can preview automated exports');
	END LOOP;
	
	IF SYS_CONTEXT('SECURITY', 'ACT') IS NOT NULL THEN
		security.user_pkg.logoff(SYS_CONTEXT('SECURITY', 'ACT'));
	END IF;
END;
/

INSERT INTO csr.auto_exp_exporter_plugin
(plugin_id, label, exporter_assembly, outputter_assembly)
VALUES
(16, 'Barloworld Hyperion Excel', 'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.BarloworldExcelOutputter');

INSERT INTO csr.auto_exp_exporter_plugin
(plugin_id, label, exporter_assembly, outputter_assembly)
VALUES
(17, 'Barloworld Hyperion DSV', 'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.BarloworldDsvOutputter');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_export_pkg
@../automated_export_body
@../automated_import_pkg
@../automated_import_body
@../enable_body

@update_tail
