-- Please update version.sql too -- this keeps clean builds in sync
define version=2979
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE csr.auto_imp_zip_settings_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;

CREATE TABLE csr.auto_imp_zip_settings(
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	auto_imp_zip_settings_id		NUMBER(10) NOT NULL,
	automated_import_class_sid		NUMBER(10) NOT NULL,
	step_number						NUMBER(10) NOT NULL,
	sort_by							VARCHAR2(10),
	sort_by_direction				VARCHAR2(10),
	CONSTRAINT pk_auto_imp_zip_settings PRIMARY KEY (app_sid, auto_imp_zip_settings_id),
	CONSTRAINT fk_auto_imp_zip_set_step FOREIGN KEY (app_sid, automated_import_class_sid, step_number) REFERENCES csr.automated_import_class_step(app_sid, automated_import_class_sid, step_number),
	CONSTRAINT uk_auto_imp_zip_set_step UNIQUE (app_sid, automated_import_class_sid, step_number),
	CONSTRAINT ck_auto_imp_zip_set_sort_by CHECK (SORT_BY IN ('DATE','FILENAME') OR SORT_BY IS NULL),
	CONSTRAINT ck_auto_imp_zip_set_sort_dir CHECK (SORT_BY_DIRECTION IN ('ASC','DESC') OR SORT_BY_DIRECTION IS NULL)
);

CREATE TABLE csr.auto_imp_zip_filter(
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	auto_imp_zip_settings_id		NUMBER(10) NOT NULL,
	pos								NUMBER(10) NOT NULL,
	wildcard_match					VARCHAR2(1024),
	regex_match						VARCHAR2(1024),
	matched_import_class_sid		NUMBER(10) NOT NULL,
	CONSTRAINT pk_auto_imp_zip_filter PRIMARY KEY (app_sid, auto_imp_zip_settings_id, pos),
	CONSTRAINT fk_auto_imp_zip_filter_cls FOREIGN KEY (app_sid, matched_import_class_sid) REFERENCES csr.automated_import_class(app_sid, automated_import_class_sid)
);

-- Alter tables
ALTER TABLE CSR.AUTOMATED_IMPORT_INSTANCE
ADD parent_instance_id NUMBER(10);

ALTER TABLE CSR.AUTOMATED_IMPORT_INSTANCE
ADD CONSTRAINT auto_instance_parent_instance FOREIGN KEY (app_sid, parent_instance_id) REFERENCES CSR.AUTOMATED_IMPORT_INSTANCE(app_sid, automated_import_instance_id);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO CSR.AUTO_IMP_IMPORTER_PLUGIN
  (plugin_id, label, importer_assembly)
VALUES
  (5, 'Zip extractor', 'Credit360.ExportImport.Automated.Import.Importers.ZipExtractImporter.ZipExtractImporter');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\automated_import_pkg
@..\automated_import_body

@update_tail
