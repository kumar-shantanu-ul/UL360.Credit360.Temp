define version=2787
define minor_version=13
@update_header

-- New table for the specific FTP protocols
CREATE TABLE csr.ftp_protocol (
	PROTOCOL_ID				NUMBER(10) NOT NULL,
	LABEL					VARCHAR(128),
	CONSTRAINT pk_ftp_protocol PRIMARY KEY (protocol_id)
);
INSERT INTO csr.ftp_protocol (protocol_id, label) VALUES (0, 'FTP');
INSERT INTO csr.ftp_protocol (protocol_id, label) VALUES (1, 'FTPS');
INSERT INTO csr.ftp_protocol (protocol_id, label) VALUES (2, 'SFTP');

-- Make FTP profiles specify an FTP protocol, rather than a cms_imp_protocol
ALTER TABLE csr.ftp_profile
ADD ftp_protocol_id NUMBER(10);

ALTER TABLE csr.ftp_profile
ADD CONSTRAINT fk_ftp_protocol_id FOREIGN KEY (ftp_protocol_id) REFERENCES csr.ftp_protocol(protocol_id);

-- Move across existing settings
UPDATE csr.ftp_profile fp
   SET fp.ftp_protocol_id = (
			SELECT fp2.cms_imp_protocol_id
			  FROM csr.ftp_profile fp2
			 WHERE fp.ftp_profile_id = fp2.ftp_profile_id);

ALTER TABLE csr.ftp_profile MODIFY ftp_protocol_id NOT NULL;

-- Drop the old column
ALTER TABLE csr.ftp_profile
DROP COLUMN cms_imp_protocol_id;

-- Move the payload path to the class so the profile can be used for multiple jobs on the site
ALTER TABLE csr.automated_export_class
ADD payload_path VARCHAR2(1024);

UPDATE csr.automated_export_class aec
   SET aec.payload_path = (
		SELECT payload_path 
		  FROM csr.ftp_profile fp 
		 WHERE fp.ftp_profile_id = aec.ftp_profile_id);

ALTER TABLE csr.ftp_profile
DROP COLUMN payload_path;

-- Create FTP profiles from cms_imp jobs so that we can move it across to using profiles
ALTER TABLE csr.cms_imp_class_step
ADD ftp_profile_id NUMBER(10);

ALTER TABLE csr.cms_imp_class_step
ADD CONSTRAINT FK_cms_imp_step_ftp_prof FOREIGN KEY (app_sid, ftp_profile_id) REFERENCES csr.ftp_profile(app_sid, ftp_profile_id);

DECLARE
		v_seq_start INTEGER;
BEGIN
	SELECT NVL(MAX(ftp_profile_id) + 1, 1)
	  INTO v_seq_start
	  FROM csr.ftp_profile;

	EXECUTE IMMEDIATE 'Create sequence csr.ftp_profile_id_seq
						start with ' || v_seq_start || ' increment by 1 NOMINVALUE NOMAXVALUE CACHE 20 NOORDER';
END;
/

DECLARE
	v_ftp_profile_id	NUMBER;
BEGIN
	FOR r IN (
		SELECT cic.app_sid, cics.cms_imp_class_sid, step_number, cms_imp_protocol_id, ftp_url, ftp_secure_creds, ftp_fingerprint, ftp_username, ftp_password, ftp_port_number,
			   CASE step_number WHEN 1 THEN cic.label ELSE cic.label||' ('||step_number||')' END profile_name
		  FROM csr.cms_imp_class_step cics
		  JOIN csr.cms_imp_class cic ON cics.cms_imp_class_sid = cic.cms_imp_class_sid
		 WHERE cms_imp_protocol_id IN (0, 1, 2)
		   AND cics.ftp_profile_id IS NULL
		   AND cics.ftp_url IS NOT NULL
	)
	LOOP
		SELECT csr.ftp_profile_id_seq.NEXTVAL
		  INTO v_ftp_profile_id
		  FROM dual;
			
		-- Create the new profile
		INSERT INTO csr.ftp_profile
			(app_sid, ftp_profile_id, label, host_name, secure_credentials, fingerprint, username, password, port_number, ftp_protocol_id)
		VALUES
			(r.app_sid, v_ftp_profile_id, r.profile_name, r.ftp_url, r.ftp_secure_creds, r.ftp_fingerprint, r.ftp_username, r.ftp_password, r.ftp_port_number, r.cms_imp_protocol_id);
		
		-- Update the record
		UPDATE csr.cms_imp_class_step
		   SET ftp_profile_id 		= v_ftp_profile_id
		 WHERE cms_imp_class_sid 	= r.cms_imp_class_sid
		   AND step_number			= r.step_number;
		
	END LOOP;
END;
/

--Add a constraint so that any step using FTP must have an FTP profile
ALTER TABLE csr.cms_imp_class_step
ADD CONSTRAINT ck_cms_imp_step_ftp_prof CHECK (cms_imp_protocol_id != 0 OR ftp_profile_id IS NOT NULL);

-- Update cms_imp_protocols to have a single FTP entry, with the FTP type defined by the ftp_protocol on the ftp_profile
-- This requires altering data;
--	 CURRENT ->	 NEW
-- 0 FTP		 ->	 FTP
-- 1 FTPS		->	 DB_BLOB
-- 2 SFTP		->	 LOCAL
-- 3 DB_BLOB ->	 not used
-- 4 LOCAL	 ->	 not used

-- So, 0 stays the same, 1 & 2 become 0. Then we can make 3s into 1s and 4s into 2s
UPDATE csr.cms_imp_class_step
   SET cms_imp_protocol_id = 0
 WHERE cms_imp_protocol_id IN (0, 1, 2);

UPDATE csr.cms_imp_class_step
   SET cms_imp_protocol_id = 1
 WHERE cms_imp_protocol_id = 3;
 
UPDATE csr.cms_imp_class_step
   SET cms_imp_protocol_id = 2
 WHERE cms_imp_protocol_id = 4;

-- Now update the protocol table
UPDATE csr.cms_imp_protocol
   SET label = 'DB_BLOB'
 WHERE cms_imp_protocol_id = 1;

UPDATE csr.cms_imp_protocol
   SET label = 'LOCAL'
 WHERE cms_imp_protocol_id = 2;
 
-- Rename cms_imp_protocol; crap name
ALTER TABLE csr.cms_imp_protocol RENAME TO import_protocol;
ALTER TABLE csr.import_protocol RENAME COLUMN cms_imp_protocol_id to import_protocol_id;


/* EXPORT PLUGINS */
CREATE TABLE csr.auto_exp_exporter_plugin (
	plugin_id			NUMBER NOT NULL,
	label				VARCHAR2(128) NOT NULL,
	exporter_assembly			  VARCHAR2(255) NOT NULL,
  outputter_assembly			VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_auto_exp_exporter_plugin_id PRIMARY KEY (plugin_id),
	CONSTRAINT uk_auto_exp_exporter_label UNIQUE (label),
	CONSTRAINT uk_auto_exp_exporter_assembly UNIQUE (exporter_assembly, outputter_assembly)	
);

INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (1, 'Dataview - Dsv',   'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.CsvOutputter');
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (2, 'Dataview - Excel', 'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.ExcelOutputter');
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (3, 'Dataview - XML',   'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.XmlOutputter');
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
VALUES (4, 'Nestle - Dsv',   'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.NestleDsvOutputter');


ALTER TABLE csr.automated_export_class
ADD exporter_plugin_id NUMBER NOT NULL;

ALTER TABLE csr.automated_export_class
ADD CONSTRAINT fk_auto_exp_cls_exp_plugin FOREIGN KEY (exporter_plugin_id) REFERENCES csr.auto_exp_exporter_plugin(plugin_id);

/* FILE WRITER PLUGINS */
CREATE TABLE csr.auto_exp_file_writer_plugin (
	plugin_id				NUMBER NOT NULL,
	label					VARCHAR2(128) NOT NULL,
	assembly				VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_auto_exp_file_wri_plugin_id PRIMARY KEY (plugin_id),
	CONSTRAINT uk_auto_exp_file_wri_label UNIQUE (label),
	CONSTRAINT uk_auto_exp_file_wri_assembly UNIQUE (assembly)	
);

INSERT INTO csr.auto_exp_file_writer_plugin (plugin_id, label, assembly)
VALUES (1, 'FTP', 'Credit360.AutomatedExportImport.Export.FileWrite.FtpWriter');
INSERT INTO csr.auto_exp_file_writer_plugin (plugin_id, label, assembly)
VALUES (2, 'Document library', 'Credit360.AutomatedExportImport.Export.FileWrite.DocLibWriter');
INSERT INTO csr.auto_exp_file_writer_plugin (plugin_id, label, assembly)
VALUES (3, 'Email document', 'Credit360.AutomatedExportImport.Export.FileWrite.EmailDocWriter');
INSERT INTO csr.auto_exp_file_writer_plugin (plugin_id, label, assembly)
VALUES (4, 'Email (link)', 'Credit360.AutomatedExportImport.Export.FileWrite.EmailLinkWriter');
INSERT INTO csr.auto_exp_file_writer_plugin (plugin_id, label, assembly)
VALUES (5, 'Manual download', 'Credit360.AutomatedExportImport.Export.FileWrite.ManualDownloadWriter');
INSERT INTO csr.auto_exp_file_writer_plugin (plugin_id, label, assembly)
VALUES (6, 'Save to DB', 'Credit360.AutomatedExportImport.Export.FileWrite.DbWriter');

ALTER TABLE csr.automated_export_class
ADD file_writer_plugin_id NUMBER NOT NULL;
ALTER TABLE csr.automated_export_class
ADD CONSTRAINT fk_auto_exp_cls_filewri_plugin FOREIGN KEY (file_writer_plugin_id) REFERENCES CSR.auto_exp_file_writer_plugin(plugin_id);

ALTER TABLE csr.automated_export_class 
DROP COLUMN export_file_format;
ALTER TABLE csr.automated_export_class 
DROP COLUMN export_type;
ALTER TABLE csr.automated_export_class 
DROP COLUMN db_data_exporter_function;
ALTER TABLE csr.automated_export_class 
DROP COLUMN data_exporter_class;
ALTER TABLE csr.automated_export_class
DROP CONSTRAINT fk_automated_export_class;
ALTER TABLE csr.automated_export_class
DROP COLUMN ftp_profile_id;

ALTER TABLE csr.automated_export_class
ADD include_headings NUMBER(1) DEFAULT 1 NOT NULL;
ALTER TABLE csr.automated_export_class
ADD CONSTRAINT ck_include_headings CHECK (include_headings IN (0, 1));
ALTER TABLE csr.automated_export_class
ADD output_empty_as VARCHAR2(16);
ALTER TABLE csr.automated_export_class
ADD file_mask_date_format VARCHAR2(128);

---------------
-- MESSAGING
---------------
-- Unify the messaging framework between imports and exports. The basic idea here is to share the messaging framework between the two as the messaging is the same

-- Convert the current imports framework into a generic one, by renaming and removing the import instance id, etc

CREATE TABLE csr.auto_import_message_map (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	import_instance_id				NUMBER(10) NOT NULL,
	import_instance_step_id			NUMBER(10), -- Can be nullable so you can write messages against the instance itself
	message_id						NUMBER(10) NOT NULL,
	CONSTRAINT pk_auto_import_mes_map PRIMARY KEY (app_sid, message_id)
);

CREATE TABLE csr.auto_export_message_map (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	export_instance_id				NUMBER(10) NOT NULL,
	message_id						NUMBER(10) NOT NULL,
	CONSTRAINT pk_auto_export_mes_map PRIMARY KEY (app_sid, message_id)
);

-- We now need to migrate both sets of existing messages into a single table, containg msg_id, message, severity. The import table is most appropriate
-- for this so we'll move that table in this direction and then push the export messages across afterwards and then drop it.
-- Create map entries for import messages
INSERT INTO csr.auto_import_message_map (app_sid, import_instance_id, import_instance_step_id, message_id)
	SELECT s.app_sid, s.cms_imp_instance_id, m.cms_imp_instance_step_id, m.cms_imp_instance_step_msg_id
	  FROM csr.cms_imp_instance_step_msg m
	  JOIN csr.cms_imp_instance_step s ON m.cms_imp_instance_step_id = s.cms_imp_instance_step_id;

-- Tidy up the table
ALTER TABLE csr.cms_imp_instance_step_msg
RENAME TO auto_impexp_instance_msg;

ALTER TABLE csr.auto_impexp_instance_msg
RENAME COLUMN cms_imp_instance_step_msg_id TO message_id;

ALTER TABLE csr.auto_impexp_instance_msg
DROP CONSTRAINT fk_cms_imp_inst_stp_msg;

ALTER TABLE csr.auto_impexp_instance_msg
DROP COLUMN cms_imp_instance_step_id;

DECLARE
		v_seq_start INTEGER;
BEGIN
	SELECT csr.cms_imp_instance_step_msg_seq.NEXTVAL
	  INTO v_seq_start
	  FROM dual;

	EXECUTE IMMEDIATE 'Create sequence csr.auto_impexp_instance_msg_seq
						start with ' || v_seq_start || ' increment by 1 NOMINVALUE NOMAXVALUE CACHE 20 NOORDER';
END;
/

DROP SEQUENCE csr.cms_imp_instance_step_msg_SEQ;

-- Add 'info' severity to messaging
ALTER TABLE csr.auto_impexp_instance_msg
DROP CONSTRAINT chk_cms_imp_inst_stp_sev;
ALTER TABLE csr.auto_impexp_instance_msg
ADD CONSTRAINT ck_auto_impexp_inst_msg_sev CHECK (severity IN ('W', 'X', 'I'));

-- We now need to move over the export messages.	We'll do this via a loop because we need to update the message ids and update the message
-- map. 

DECLARE
	v_new_msg_id	NUMBER;
BEGIN

	FOR r IN (
		SELECT app_sid, instance_message_id, automated_export_instance_id, message, CASE result WHEN 'Failure' THEN 'X' WHEN 'Success' THEN 'I' ELSE 'I' END severity
		  FROM csr.AUTOMATED_EXPORT_INST_MESSAGE
	)
	LOOP
	
		SELECT csr.auto_impexp_instance_msg_seq.NEXTVAL
		  INTO v_new_msg_id
		  FROM DUAl;
		  
		--Insert the message
		INSERT INTO csr.auto_impexp_instance_msg (app_sid, message_id, message, severity)
		VALUES (r.app_sid, v_new_msg_id, r.message, r.severity);
		--Insert into the message map
		INSERT INTO csr.auto_export_message_map (app_sid, export_instance_id, message_id)
		VALUES (r.app_sid, r.automated_export_instance_id, v_new_msg_id); 
		
	
	END LOOP;
END;
/

DROP TABLE csr.automated_export_inst_message;



-- Update the import plugins; THe assemblies have moved

UPDATE csr.cms_imp_class_step
   SET plugin = REPLACE(plugin, '.CmsDataImport.', '.AutomatedExportImport.Import.')
 WHERE plugin IS NOT NULL;
 
UPDATE csr.cms_imp_class
   SET import_plugin = REPLACE(import_plugin, '.CmsDataImport.', '.AutomatedExportImport.Import.')
 WHERE import_plugin IS NOT NULL;
 
 
/* Setting specific tables */
/* DATA RETRIEVAL */
/* Dataview */
CREATE TABLE csr.auto_exp_retrieval_dataview (
	app_sid								NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	auto_exp_retrieval_dataview_id		NUMBER(10) NOT NULL,
	dataview_sid						NUMBER(10) NOT NULL,
	ignore_null_values					NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT pk_auto_exp_retrieval_dataview PRIMARY KEY (app_sid, auto_exp_retrieval_dataview_id),
	CONSTRAINT fk_auto_exp_rtrvl_dview_sid FOREIGN KEY (app_sid, dataview_sid) REFERENCES csr.dataview(app_sid, dataview_sid),
	CONSTRAINT ck_auto_exp_rtrvl_ignore_na CHECK (ignore_null_values IN (0, 1))
);

CREATE SEQUENCE csr.auto_exp_rtrvl_dataview_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;
	
ALTER TABLE csr.automated_export_class
ADD auto_exp_retrieval_dataview_id NUMBER(10);

/* FILE CREATION */
/* CSV */

CREATE TABLE csr.auto_exp_imp_dsv_delimiters (
	delimiter_id				NUMBER(10) NOT NULL,
	label						VARCHAR2(32),
	CONSTRAINT pk_auto_exp_imp_dsv_delim PRIMARY KEY (delimiter_id),
	CONSTRAINT uk_auto_exp_imp_dsv_delim UNIQUE (label)
);
INSERT INTO csr.auto_exp_imp_dsv_delimiters (delimiter_id, label) VALUES (0, 'Comma');
INSERT INTO csr.auto_exp_imp_dsv_delimiters (delimiter_id, label) VALUES (1, 'Pipe');
INSERT INTO csr.auto_exp_imp_dsv_delimiters (delimiter_id, label) VALUES (2, 'Tab');

CREATE TABLE csr.auto_exp_filecreate_dsv (
	app_sid								NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	auto_exp_filecreate_dsv_id			NUMBER(10) NOT NULL,
	delimiter_id						NUMBER(10) NOT NULL,
	quotes_as_literals					NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT pk_auto_exp_filecreate_dsv PRIMARY KEY (app_sid, auto_exp_filecreate_dsv_id),
	CONSTRAINT fk_auto_exp_delimiter FOREIGN KEY (delimiter_id) REFERENCES csr.auto_exp_imp_dsv_delimiters(delimiter_id),
	CONSTRAINT ck_auto_exp_filecre_quotes CHECK (quotes_as_literals IN (0, 1))
);

CREATE SEQUENCE csr.auto_exp_filecre_dsv_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;
	
ALTER TABLE csr.automated_export_class
ADD auto_exp_filecre_dsv_id NUMBER(10);

/* FILE WRITING */
/* FTP */
CREATE TABLE csr.auto_exp_filewrite_ftp (
	app_sid								NUMBER(10) DEFAULT SYS_CONTEXT('security', 'app') NOT NULL,
	auto_exp_filewrite_ftp_id			NUMBER(10) NOT NULL,
	ftp_profile_id						NUMBER(10) NOT NULL,
	output_path							VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_auto_exp_filewrite_ftp PRIMARY KEY (app_sid, auto_exp_filewrite_ftp_id),
	CONSTRAINT fk_auto_exp_filewri_ftp_prof FOREIGN KEY (app_sid, ftp_profile_id) REFERENCES csr.ftp_profile(app_sid, ftp_profile_id)
);

CREATE SEQUENCE csr.auto_exp_filecre_ftp_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;

ALTER TABLE csr.automated_export_class
ADD auto_exp_filewri_ftp_id NUMBER(10);

ALTER TABLE csr.automated_export_class
ADD CONSTRAINT ck_auto_exp_cls_ftp_id CHECK (file_writer_plugin_id != 1 OR auto_exp_filewri_ftp_id IS NOT NULL);

ALTER TABLE csr.automated_export_class
ADD CONSTRAINT fk_auto_exp_cls_ftp_id FOREIGN KEY (app_sid, auto_exp_filewri_ftp_id) REFERENCES csr.auto_exp_filewrite_ftp(app_sid, auto_exp_filewrite_ftp_id);

/* PERIOD SPAN PATTERNS */

CREATE TABLE csr.period_span_pattern_type (
	period_span_pattern_type_id				NUMBER(10) NOT NULL,
	label									VARCHAR2(128) NOT NULL,
	CONSTRAINT pk_period_span_pattern_type PRIMARY KEY (period_span_pattern_type_id),
	CONSTRAINT uk_period_span_pattern_label UNIQUE (label)
);

INSERT INTO csr.period_span_pattern_type (period_span_pattern_type_id, label)
VALUES (0, 'Fixed');
INSERT INTO csr.period_span_pattern_type (period_span_pattern_type_id, label)
VALUES (1, 'Fixed to now');
INSERT INTO csr.period_span_pattern_type (period_span_pattern_type_id, label)
VALUES (2, 'Rolling to now');
INSERT INTO csr.period_span_pattern_type (period_span_pattern_type_id, label)
VALUES (3, 'Offset to now');

CREATE TABLE csr.period_span_pattern (
	app_sid									NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	period_span_pattern_id					NUMBER(10) NOT NULL,
	period_span_pattern_type_id				NUMBER(10) NOT NULL,
	period_set_id							NUMBER(10) NOT NULL,
	period_interval_id						NUMBER(10) NOT NULL,
	date_from								DATE,
	date_to									DATE,
	periods_offset_from_now					NUMBER(2) DEFAULT 0 NOT NULL,
	number_rolling_periods					NUMBER(2) DEFAULT 0 NOT NULL,
	period_in_year							NUMBER(2) DEFAULT 0 NOT NULL,
	year_offset								NUMBER(2) DEFAULT 0 NOT NULL,
	CONSTRAINT pk_period_span_pattern PRIMARY KEY (app_sid, period_span_pattern_id),
	CONSTRAINT fk_prd_span_ptrn_type FOREIGN KEY (period_span_pattern_type_id) REFERENCES csr.period_span_pattern_type(period_span_pattern_type_id),
	CONSTRAINT fk_prd_span_ptrn_prd_set FOREIGN KEY (app_sid, period_set_id) REFERENCES csr.period_set(app_sid, period_set_id),
	CONSTRAINT fk_prd_span_ptrn_prd_int FOREIGN KEY (app_sid, period_set_id, period_interval_id) REFERENCES csr.period_interval(app_sid, period_set_id, period_interval_id)
);

CREATE SEQUENCE csr.period_span_pattern_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;

ALTER TABLE csr.automated_export_class
ADD period_span_pattern_id NUMBER(10) NOT NULL;
ALTER TABLE csr.automated_export_class
ADD CONSTRAINT fk_auto_exp_cl_per_span_pat_id FOREIGN KEY (app_sid, period_span_pattern_id) REFERENCES csr.period_span_pattern(app_sid, period_span_pattern_id);

-- Enable script
INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (53, 'Automated exports', 'EnableAutomatedExport', 'Enables the automated export framework.', 0);

@../automated_export_import_pkg
@../automated_export_import_body
@../cms_data_imp_pkg
@../cms_data_imp_body
@../enable_pkg
@../enable_body
@../csr_app_body

@update_tail