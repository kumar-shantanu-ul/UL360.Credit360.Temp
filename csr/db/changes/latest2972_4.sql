-- Please update version.sql too -- this keeps clean builds in sync
define version=2972
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE csr.auto_imp_core_data_val_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;

CREATE TABLE csr.auto_imp_core_data_val (
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL ,
	val_id					NUMBER(10) NOT NULL,
	instance_id				NUMBER(10) NOT NULL,
	instance_step_id		NUMBER(10) NOT NULL,
	ind_sid					NUMBER(10) NOT NULL,
	region_sid				NUMBER(10) NOT NULL,
	start_dtm				DATE NOT NULL,
	end_dtm					DATE NOT NULL,
	val_number				NUMBER(24, 10),
	measure_conversion_id	NUMBER(10),
	entry_val_number		NUMBER(24, 10),
	note					CLOB,
	source_file_ref			VARCHAR2(1024),
	CONSTRAINT pk_auto_imp_core_data_val PRIMARY KEY (app_sid, val_id),
	CONSTRAINT uk_auto_imp_core_data_val UNIQUE (app_sid, ind_sid, region_sid, start_dtm, end_dtm, instance_step_id)
);

CREATE TABLE csr.auto_imp_mapping_type (
	mapping_type_id			NUMBER(2) NOT NULL,
	name					VARCHAR(255),
	CONSTRAINT pk_auto_imp_map_type PRIMARY KEY (mapping_type_id)
);

CREATE TABLE csr.auto_imp_date_type (
	date_type_id			NUMBER(2) NOT NULL,
	name					VARCHAR(255),
	CONSTRAINT pk_auto_imp_date_type PRIMARY KEY (date_type_id)
);

CREATE TABLE csr.auto_imp_date_col_type (
	date_col_type_id		NUMBER(2) NOT NULL,
	name					VARCHAR(255),
	CONSTRAINT pk_auto_imp_date_col_type PRIMARY KEY (date_col_type_id)
);

CREATE SEQUENCE csr.auto_imp_coredta_setngs_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;

CREATE TABLE csr.auto_imp_core_data_settings (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	auto_imp_core_data_settings_id	NUMBER(10) NOT NULL,
	automated_import_class_sid		NUMBER(10) NOT NULL,
	step_number						NUMBER(10) NOT NULL,
	mapping_xml						SYS.XMLTYPE NOT NULL,
	automated_import_file_type_id	NUMBER(10) NOT NULL,
	dsv_separator					CHAR(1),
	dsv_quotes_as_literals			NUMBER(1),
	excel_worksheet_index			NUMBER(10),
	all_or_nothing					NUMBER(1),
	has_headings					NUMBER(1) DEFAULT 1 NOT NULL,
	ind_mapping_type_id				NUMBER(2) NOT NULL,
	region_mapping_type_id			NUMBER(2) NOT NULL,
	unit_mapping_type_id			NUMBER(2) NOT NULL,
	requires_validation_step		NUMBER(1) DEFAULT 0 NOT NULL,
	date_format_type_id				NUMBER(2) NOT NULL,
	first_col_date_format_id		NUMBER(2),
	second_col_date_format_id		NUMBER(2),
	zero_indexed_month_indices		NUMBER(1) DEFAULT 1 NOT NULL,
	CONSTRAINT pk_auto_imp_core_data_settings PRIMARY KEY (app_sid, auto_imp_core_data_settings_id),
	CONSTRAINT ck_auto_imp_core_set_quo CHECK (dsv_quotes_as_literals IN (0,1) OR dsv_quotes_as_literals IS NULL),
	CONSTRAINT ck_auto_imp_core_set_allorno CHECK (all_or_nothing IN (0,1) OR all_or_nothing IS NULL),
	CONSTRAINT ck_auto_imp_core_set_hasheads CHECK (has_headings IN (0,1)),
	CONSTRAINT ck_auto_imp_core_set_reqvalid CHECK (requires_validation_step IN (0,1)),
	CONSTRAINT ck_auto_imp_core_set_zeroind CHECK (zero_indexed_month_indices IN (0,1)),
	CONSTRAINT fk_auto_imp_core_set_step FOREIGN KEY (app_sid, automated_import_class_sid, step_number) REFERENCES csr.automated_import_class_step(app_sid, automated_import_class_sid, step_number),
	CONSTRAINT uk_auto_imp_core_set_step UNIQUE (app_sid, automated_import_class_sid, step_number),
	CONSTRAINT fk_auto_imp_core_set_filetype FOREIGN KEY (automated_import_file_type_id) REFERENCES csr.automated_import_file_type(automated_import_file_type_id),
	CONSTRAINT fk_auto_imp_core_set_indmap FOREIGN KEY (ind_mapping_type_id) REFERENCES csr.auto_imp_mapping_type(mapping_type_id),
	CONSTRAINT fk_auto_imp_core_set_regmap FOREIGN KEY (region_mapping_type_id) REFERENCES csr.auto_imp_mapping_type(mapping_type_id),
	CONSTRAINT fk_auto_imp_core_set_unitmap FOREIGN KEY (unit_mapping_type_id) REFERENCES csr.auto_imp_mapping_type(mapping_type_id),
	CONSTRAINT fk_auto_imp_core_set_datetype FOREIGN KEY (date_format_type_id) REFERENCES csr.auto_imp_date_type(date_type_id), 
	CONSTRAINT fk_auto_imp_core_set_datecol1 FOREIGN KEY (first_col_date_format_id) REFERENCES csr.auto_imp_date_col_type(date_col_type_id),
	CONSTRAINT fk_auto_imp_core_set_datecol2 FOREIGN KEY (second_col_date_format_id) REFERENCES csr.auto_imp_date_col_type(date_col_type_id)
);

-- Mapping tables
-- Where the sid/id is null, it means you explicitly want to ignore that value, which is different from the value
-- not being there at all; ie if the source text doesn't exist, it means it hasn't been mapped. If it's there
-- but with a null sid/id, then it will ignore the row without erroring or adding to the error file.
CREATE TABLE csr.auto_imp_indicator_map (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	automated_import_class_sid		NUMBER(10) NOT NULL,
	source_text						VARCHAR2(1024),
	ind_sid							NUMBER(10),
	CONSTRAINT pk_auto_imp_indicator_map PRIMARY KEY (app_sid, automated_import_class_sid, source_text),
	CONSTRAINT fk_auto_imp_ind_map_cls FOREIGN KEY (app_sid, automated_import_class_sid) REFERENCES csr.automated_import_class(app_sid, automated_import_class_sid),
	CONSTRAINT fk_auto_imp_ind_map_ind FOREIGN KEY (app_sid, ind_sid) REFERENCES csr.ind(app_sid, ind_sid)  
);
CREATE TABLE csr.auto_imp_region_map (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	automated_import_class_sid		NUMBER(10) NOT NULL,
	source_text						VARCHAR2(1024),
	region_sid						NUMBER(10),
	CONSTRAINT pk_auto_imp_region_map PRIMARY KEY (app_sid, automated_import_class_sid, source_text),
	CONSTRAINT fk_auto_imp_reg_map_cls FOREIGN KEY (app_sid, automated_import_class_sid) REFERENCES csr.automated_import_class(app_sid, automated_import_class_sid),
	CONSTRAINT fk_auto_imp_reg_map_reg FOREIGN KEY (app_sid, region_sid) REFERENCES csr.region(app_sid, region_sid)  
);
CREATE TABLE csr.auto_imp_unit_map (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	automated_import_class_sid		NUMBER(10) NOT NULL,
	source_text						VARCHAR2(1024),
	measure_conversion_id			NUMBER(10),
	CONSTRAINT pk_auto_imp_unit_map PRIMARY KEY (app_sid, automated_import_class_sid, source_text),
	CONSTRAINT fk_auto_imp_unit_map_cls FOREIGN KEY (app_sid, automated_import_class_sid) REFERENCES csr.automated_import_class(app_sid, automated_import_class_sid),
	CONSTRAINT fk_auto_imp_unit_map_unit FOREIGN KEY (app_sid, measure_conversion_id) REFERENCES csr.measure_conversion(app_sid, measure_conversion_id)  
);

-- Alter tables
-- Add 'Super admin' severity to messaging
ALTER TABLE csr.auto_impexp_instance_msg
 DROP CONSTRAINT ck_auto_impexp_inst_msg_sev;
ALTER TABLE csr.auto_impexp_instance_msg
 ADD CONSTRAINT ck_auto_impexp_inst_msg_sev CHECK (severity IN ('W', 'X', 'I', 'S'));


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.auto_imp_mapping_type (mapping_type_id, name) VALUES (0, 'Sid');
INSERT INTO csr.auto_imp_mapping_type (mapping_type_id, name) VALUES (1, 'Lookup key');
INSERT INTO csr.auto_imp_mapping_type (mapping_type_id, name) VALUES (2, 'Mapping table');
INSERT INTO csr.auto_imp_mapping_type (mapping_type_id, name) VALUES (3, 'Description');

INSERT INTO csr.auto_imp_date_type (date_type_id, name) VALUES (0, 'One col, one date');
INSERT INTO csr.auto_imp_date_type (date_type_id, name) VALUES (1, 'One col, two dates');
INSERT INTO csr.auto_imp_date_type (date_type_id, name) VALUES (2, 'Two cols, one date');
INSERT INTO csr.auto_imp_date_type (date_type_id, name) VALUES (3, 'Two cols, two dates');

INSERT INTO csr.auto_imp_date_col_type (date_col_type_id, name) VALUES (0, 'Year, eg 15 or 2015');
INSERT INTO csr.auto_imp_date_col_type (date_col_type_id, name) VALUES (1, 'Month name, eg Aug or August');
INSERT INTO csr.auto_imp_date_col_type (date_col_type_id, name) VALUES (2, 'Month index');
INSERT INTO csr.auto_imp_date_col_type (date_col_type_id, name) VALUES (3, 'Financial year, eg FY15 or FY2015');
INSERT INTO csr.auto_imp_date_col_type (date_col_type_id, name) VALUES (4, 'Date string, eg .net parsable');
INSERT INTO csr.auto_imp_date_col_type (date_col_type_id, name) VALUES (5, 'App year, eg 15 or 2015');
INSERT INTO csr.auto_imp_date_col_type (date_col_type_id, name) VALUES (6, 'Month and year, eg Aug 2015, August 2015 (or with 15)');

INSERT INTO csr.auto_imp_importer_plugin (plugin_id, label, importer_assembly) VALUES (4, 'Core data importer', 'Credit360.ExportImport.Automated.Import.Importers.CoreDataImporter.CoreDataImporter');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\csr_data_pkg
@..\region_pkg
@..\region_body
@..\indicator_body
@..\measure_body
@..\automated_import_pkg
@..\automated_import_body

@update_tail
