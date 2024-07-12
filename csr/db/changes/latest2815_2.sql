-- Please update version.sql too -- this keeps clean builds in sync
define version=2815
define minor_version=2
@update_header

ALTER TABLE csr.import_protocol
RENAME TO file_io_protocol;
ALTER TABLE csr.file_io_protocol
RENAME COLUMN import_protocol_id TO file_io_protocol_id;

ALTER TABLE csr.cms_imp_class_step
RENAME COLUMN cms_imp_protocol_id TO file_io_protocol_id;
ALTER TABLE csr.cms_imp_class_step
RENAME CONSTRAINT fk_cms_imp_prt_imp_cls_stp TO fk_cms_imp_file_io_proto_id;


-- Move over to plugin pattern used in Export
ALTER TABLE csr.cms_imp_class
RENAME TO automated_import_class;
ALTER TABLE csr.automated_import_class
RENAME COLUMN cms_imp_class_sid to automated_import_class_sid;

ALTER TABLE csr.cms_imp_class_step
RENAME TO automated_import_class_step;
ALTER TABLE csr.automated_import_class_step
RENAME COLUMN cms_imp_class_sid to automated_import_class_sid;

ALTER TABLE csr.cms_imp_instance
RENAME TO automated_import_instance;
ALTER TABLE csr.automated_import_instance
RENAME COLUMN cms_imp_instance_id TO automated_import_instance_id;
ALTER TABLE csr.automated_import_instance
RENAME COLUMN cms_imp_class_sid to automated_import_class_sid;

ALTER TABLE csr.cms_imp_file_type
RENAME COLUMN cms_imp_file_type_id to automated_import_file_type_id;
ALTER TABLE csr.cms_imp_file_type
RENAME TO automated_import_file_type;
ALTER TABLE csr.cms_imp_instance_step
RENAME COLUMN cms_imp_instance_step_id TO auto_import_instance_step_id;
ALTER TABLE csr.cms_imp_instance_step
RENAME COLUMN cms_imp_instance_id TO automated_import_instance_id;
ALTER TABLE csr.cms_imp_instance_step
RENAME COLUMN cms_imp_class_sid TO automated_import_class_sid;
ALTER TABLE csr.cms_imp_instance_step
RENAME TO automated_import_instance_step;
ALTER TABLE csr.cms_imp_manual_file
RENAME COLUMN cms_imp_instance_id to automated_import_instance_id;
ALTER TABLE csr.cms_imp_manual_file
RENAME TO automated_import_manual_file;
ALTER TABLE csr.cms_imp_result
RENAME COLUMN cms_imp_result_id TO automated_import_result_id;
ALTER TABLE csr.cms_imp_result
RENAME TO automated_import_result;

-- Rename the sequences. Unfortunately, that means dropping and creating
DECLARE
		v_seq_start INTEGER;
BEGIN
	SELECT csr.cms_imp_instance_id_seq.nextval
	  INTO v_seq_start
	  FROM dual;

	EXECUTE IMMEDIATE 'Create sequence csr.auto_imp_instance_id_seq
						start with ' || v_seq_start || ' increment by 1 NOMINVALUE NOMAXVALUE CACHE 20 NOORDER';

	SELECT csr.cms_imp_instance_step_id_seq.nextval
	  INTO v_seq_start
	  FROM dual;

	EXECUTE IMMEDIATE 'Create sequence csr.auto_imp_instance_step_id_seq
						start with ' || v_seq_start || ' increment by 1 NOMINVALUE NOMAXVALUE CACHE 20 NOORDER';
END;
/
DROP SEQUENCE csr.cms_imp_instance_id_seq;
DROP SEQUENCE csr.cms_imp_instance_step_id_seq;

-- IMPORT PLUGINS
CREATE TABLE csr.auto_imp_importer_plugin (
	plugin_id					NUMBER NOT NULL,
	label						VARCHAR2(128) NOT NULL,
	importer_assembly			VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_auto_imp_importer_plugin_id PRIMARY KEY (plugin_id),
	CONSTRAINT uk_auto_imp_imprtr_plgn_label UNIQUE (label),
	CONSTRAINT uk_auto_imp_imprtr_plgn_assmb UNIQUE (importer_assembly)	
);


INSERT INTO csr.auto_imp_importer_plugin (plugin_id, label, importer_assembly)
VALUES (1, 'CMS importer',   'Credit360.AutomatedExportImport.Import.Importers.CmsExcelImpImporter');

ALTER TABLE csr.automated_import_class_step
ADD importer_plugin_id NUMBER DEFAULT 1 NOT NULL;

ALTER TABLE csr.automated_import_class_step
ADD CONSTRAINT fk_auto_imp_cls_stp_imp_plgn FOREIGN KEY (importer_plugin_id) REFERENCES csr.auto_imp_importer_plugin(plugin_id);

-- CMS IMPORTER
CREATE TABLE csr.auto_imp_importer_cms (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	auto_imp_importer_cms_id		NUMBER(10) NOT NULL,
	tab_sid							NUMBER(10) NOT NULL,
	mapping_xml						SYS.XMLTYPE NOT NULL,
	cms_imp_file_type_id			NUMBER(10) NOT NULL,
	dsv_separator					VARCHAR2(32),
	dsv_quotes_as_literals			NUMBER(1),
	excel_worksheet_index			NUMBER(10),
	all_or_nothing					NUMBER(1),
	CONSTRAINT pk_auto_imp_importer_cms PRIMARY KEY (app_sid, auto_imp_importer_cms_id),
	CONSTRAINT ck_auto_imp_importer_sep CHECK (dsv_separator IN ('PIPE','TAB','COMMA') OR dsv_separator IS NULL),
	CONSTRAINT ck_auto_imp_importer_quo CHECK (dsv_quotes_as_literals IN (0,1) OR dsv_quotes_as_literals IS NULL),
	CONSTRAINT ck_auto_imp_importer_allorno CHECK (all_or_nothing IN (0,1) OR all_or_nothing IS NULL),
	CONSTRAINT fk_auto_imp_imprtr_filetype FOREIGN KEY (cms_imp_file_type_id) REFERENCES csr.automated_import_file_type(automated_import_file_type_id)
);

CREATE SEQUENCE csr.auto_imp_importer_cms_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;
	
ALTER TABLE csr.automated_import_class_step
ADD auto_imp_importer_cms_id NUMBER(10);

DECLARE
	v_cms_id	NUMBER;
BEGIN
	FOR r IN (
		SELECT aics.app_sid, aic.automated_import_class_sid, aics.step_number, tab_sid, mapping_xml, cms_imp_file_type_id, dsv_separator, dsv_quotes_as_literals, 
			   excel_worksheet_index, all_or_nothing
		  FROM csr.automated_import_class_step aics
		  JOIN csr.automated_import_class aic ON aics.automated_import_class_sid = aic.automated_import_class_sid
	)
	LOOP
		SELECT csr.auto_imp_importer_cms_id_seq.nextval
		  INTO v_cms_id
		  FROM dual;
			
		-- Create the new profile
		INSERT INTO csr.auto_imp_importer_cms 
			(app_sid, auto_imp_importer_cms_id, tab_sid, mapping_xml, cms_imp_file_type_id, dsv_separator, dsv_quotes_as_literals, excel_worksheet_index, all_or_nothing)
		VALUES
			(r.app_sid, v_cms_id, r.tab_sid, r.mapping_xml, r.cms_imp_file_type_id, r.dsv_separator, r.dsv_quotes_as_literals, r.excel_worksheet_index, r.all_or_nothing);

		-- Update the record
		UPDATE csr.automated_import_class_step
		   SET auto_imp_importer_cms_id		= v_cms_id
		 WHERE automated_import_class_sid	= r.automated_import_class_sid
		   AND step_number					= r.step_number;
	END LOOP;
END;
/

ALTER TABLE csr.automated_import_class_step DROP COLUMN tab_sid;
ALTER TABLE csr.automated_import_class_step DROP COLUMN mapping_xml;
ALTER TABLE csr.automated_import_class_step DROP COLUMN cms_imp_file_type_id;
ALTER TABLE csr.automated_import_class_step DROP COLUMN dsv_separator;
ALTER TABLE csr.automated_import_class_step DROP COLUMN dsv_quotes_as_literals;
ALTER TABLE csr.automated_import_class_step DROP COLUMN excel_worksheet_index;
ALTER TABLE csr.automated_import_class_step DROP COLUMN all_or_nothing;



-- READER PLUGINS
CREATE TABLE csr.auto_imp_fileread_plugin (
	plugin_id						NUMBER NOT NULL,
	label							VARCHAR2(128) NOT NULL,
	fileread_assembly				VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_auto_imp_fileread_plugin_id PRIMARY KEY (plugin_id),
	CONSTRAINT uk_auto_imp_fileread_label UNIQUE (label),
	CONSTRAINT uk_auto_imp_fileread_assembly UNIQUE (fileread_assembly)	
);

INSERT INTO csr.auto_imp_fileread_plugin (plugin_id, label, fileread_assembly)
VALUES (1, 'FTP Reader', 'Credit360.AutomatedExportImport.Import.FileReaders.FtpReader');
INSERT INTO csr.auto_imp_fileread_plugin (plugin_id, label, fileread_assembly)
VALUES (2, 'Database Reader', 'Credit360.AutomatedExportImport.Import.FileReaders.DBReader');

ALTER TABLE csr.automated_import_class_step
ADD fileread_plugin_id NUMBER;

--Update existing entries
UPDATE csr.automated_import_class_step
   SET fileread_plugin_id = 1 
 WHERE file_io_protocol_id = 0;
UPDATE csr.automated_import_class_step
   SET fileread_plugin_id = 2 
 WHERE file_io_protocol_id = 1;

ALTER TABLE csr.automated_import_class_step
ADD CONSTRAINT fk_auto_imp_cls_file_plugin FOREIGN KEY (fileread_plugin_id) REFERENCES csr.auto_imp_fileread_plugin(plugin_id);

-- FTP Reader
CREATE TABLE csr.auto_imp_fileread_ftp (
	app_sid								NUMBER(10) DEFAULT SYS_CONTEXT('security', 'app') NOT NULL,
	auto_imp_fileread_ftp_id			NUMBER(10) NOT NULL,
	ftp_profile_id						NUMBER(10) NOT NULL,
	payload_path						VARCHAR2(255) NOT NULL,
	file_mask							VARCHAR2(255),
	sort_by								VARCHAR2(10),
	sort_by_direction					VARCHAR2(10),
	move_to_path_on_success				VARCHAR2(1024),
	move_to_path_on_error				VARCHAR2(1024),
	delete_on_success					NUMBER(1) DEFAULT 0 NOT NULL,
	delete_on_error						NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT pk_auto_imp_fileread_ftp 		PRIMARY KEY (app_sid, auto_imp_fileread_ftp_id),
	CONSTRAINT fk_auto_imp_fileread_ftp_prof 	FOREIGN KEY (app_sid, ftp_profile_id) REFERENCES csr.ftp_profile(app_sid, ftp_profile_id),
	CONSTRAINT ck_auto_IMP_fileread_ftp_sort 	CHECK (SORT_BY IN ('DATE','FILENAME') OR SORT_BY IS NULL),
	CONSTRAINT ck_auto_imp_fileread_ftp_dir 	CHECK (sort_by_direction IN ('ASC','DESC') OR sort_by_direction IS NULL),
	CONSTRAINT ck_auto_imp_fileread_ftp_dlsuc 	CHECK (delete_on_success IN (0, 1)),
	CONSTRAINT ck_auto_imp_fileread_ftp_dlerr 	CHECK (delete_on_error IN (0, 1))
);

CREATE SEQUENCE csr.auto_imp_fileread_ftp_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;

ALTER TABLE csr.automated_import_class_step
ADD auto_imp_fileread_ftp_id NUMBER(10);

-- Move the contents of the existing steps to FTP settings table
DECLARE
	v_auto_imp_fileread_ftp_id	NUMBER;
BEGIN
	FOR r IN (
		SELECT cics.app_sid, cic.automated_import_class_sid, cics.step_number, payload_path, file_mask, sort_by, sort_by_direction, ftp_profile_id, move_to_path_on_success,
			   move_to_path_on_error, NVL(delete_on_success, 0) delete_on_success, NVL(delete_on_error, 0) delete_on_error
		  FROM csr.automated_import_class_step cics
		  JOIN csr.automated_import_class cic ON cics.automated_import_class_sid = cic.automated_import_class_sid
		 WHERE file_io_protocol_id = 0
		   AND cics.ftp_profile_id IS NOT NULL
	)
	LOOP
		SELECT csr.auto_imp_fileread_ftp_id_seq.nextval
		  INTO v_auto_imp_fileread_ftp_id
		  FROM dual;
			
		-- Create the new profile
		INSERT INTO csr.auto_imp_fileread_ftp 
			(app_sid, auto_imp_fileread_ftp_id, ftp_profile_id, payload_path, file_mask, sort_by, sort_by_direction, move_to_path_on_success, move_to_path_on_error, delete_on_success, delete_on_error)
		VALUES
			(r.app_sid, v_auto_imp_fileread_ftp_id, r.ftp_profile_id, r.payload_path, r.file_mask, r.sort_by, r.sort_by_direction, r.move_to_path_on_success, r.move_to_path_on_error, r.delete_on_success, r.delete_on_error);
		
		-- Update the record
		UPDATE csr.automated_import_class_step
		   SET auto_imp_fileread_ftp_id		= v_auto_imp_fileread_ftp_id
		 WHERE automated_import_class_sid	= r.automated_import_class_sid
		   AND step_number					= r.step_number;
		
	END LOOP;
END;
/

ALTER TABLE csr.automated_import_class_step
DROP CONSTRAINT fk_cms_imp_file_io_proto_id;
DROP TABLE csr.file_io_protocol;
ALTER TABLE CSR.automated_import_class_step
DROP COLUMN file_io_protocol_id CASCADE CONSTRAINTS;

ALTER TABLE csr.automated_import_class_step
ADD CONSTRAINT fk_auto_imp_proto_ftp_id FOREIGN KEY (app_sid, auto_imp_fileread_ftp_id) REFERENCES csr.auto_imp_fileread_ftp(app_sid, auto_imp_fileread_ftp_id);

-- DB reader
CREATE TABLE csr.auto_imp_fileread_db (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	auto_imp_fileread_db_id			NUMBER(10) NOT NULL,
	filedata_sp						VARCHAR(255),
	CONSTRAINT pk_auto_imp_fileread_db PRIMARY KEY (app_sid, auto_imp_fileread_db_id)
);

CREATE SEQUENCE csr.auto_imp_fileread_db_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;

ALTER TABLE csr.automated_import_class_step
ADD auto_imp_fileread_db_id NUMBER(10);

-- Move the contents of the existing steps to FTP settings table
DECLARE
	v_auto_imp_fileread_db_id	NUMBER;
BEGIN
	FOR r IN (
		SELECT cics.app_sid, cic.automated_import_class_sid, cics.step_number, filedata_sp
		  FROM csr.automated_import_class_step cics
		  JOIN csr.automated_import_class cic ON cics.automated_import_class_sid = cic.automated_import_class_sid
		 WHERE filedata_sp IS NOT NULL
	)
	LOOP
		SELECT csr.auto_imp_fileread_db_id_seq.nextval
		  INTO v_auto_imp_fileread_db_id
		  FROM dual;
			
		-- Create the new profile
		INSERT INTO csr.auto_imp_fileread_db
			(app_sid, auto_imp_fileread_db_id, filedata_sp)
		VALUES
			(r.app_sid, v_auto_imp_fileread_db_id, r.filedata_sp);
		
		-- Update the record
		UPDATE csr.AUTOMATED_IMPORT_CLASS_step
		   SET auto_imp_fileread_db_id 		= v_auto_imp_fileread_db_id
		 WHERE automated_import_class_sid 	= r.automated_import_class_sid
		   AND step_number			= r.step_number;
		
	END LOOP;
END;
/

ALTER TABLE csr.automated_import_class_step
ADD CONSTRAINT fk_auto_imp_proto_db_id FOREIGN KEY (app_sid, auto_imp_fileread_db_id) REFERENCES csr.auto_imp_fileread_db(app_sid, auto_imp_fileread_db_id);


-- Drop all the old columns
ALTER TABLE csr.automated_import_class_step DROP COLUMN payload_path;
ALTER TABLE csr.automated_import_class_step DROP COLUMN ftp_url;
ALTER TABLE csr.automated_import_class_step DROP COLUMN ftp_secure_creds;
ALTER TABLE csr.automated_import_class_step DROP COLUMN ftp_fingerprint;
ALTER TABLE csr.automated_import_class_step DROP COLUMN ftp_username;
ALTER TABLE csr.automated_import_class_step DROP COLUMN ftp_password;
ALTER TABLE csr.automated_import_class_step DROP COLUMN ftp_port_number;
ALTER TABLE csr.automated_import_class_step DROP COLUMN file_mask;
ALTER TABLE csr.automated_import_class_step DROP COLUMN sort_by;
ALTER TABLE csr.automated_import_class_step DROP COLUMN sort_by_direction;
ALTER TABLE csr.automated_import_class_step DROP COLUMN ftp_profile_id CASCADE CONSTRAINTS;
ALTER TABLE csr.automated_import_class_step DROP COLUMN move_to_path_on_success CASCADE CONSTRAINTS;
ALTER TABLE csr.automated_import_class_step DROP COLUMN move_to_path_on_error CASCADE CONSTRAINTS;
ALTER TABLE csr.automated_import_class_step DROP COLUMN delete_on_success CASCADE CONSTRAINTS;
ALTER TABLE csr.automated_import_class_step DROP COLUMN delete_on_error CASCADE CONSTRAINTS;
ALTER TABLE csr.automated_import_class_step DROP COLUMN filedata_sp CASCADE CONSTRAINTS;

--Put check constraints in so that relevant settings entry exists for chosen filereader
ALTER TABLE csr.automated_import_class_step
ADD CONSTRAINT ck_auto_imp_fileread_ftp_id CHECK (fileread_plugin_id != 1 OR auto_imp_fileread_ftp_id IS NOT NULL);
ALTER TABLE csr.automated_import_class_step
ADD CONSTRAINT ck_auto_imp_fileread_db_id CHECK (fileread_plugin_id != 2 OR auto_imp_fileread_db_id IS NOT NULL);

-- Drop unused column
ALTER TABLE csr.automated_import_class
DROP COLUMN helper_pkg;

-- Update the plugin
UPDATE csr.batch_job_type
   SET description = 'Automated import',
       plugin_name = 'automated-import'
 WHERE batch_job_type_id = 13;
 
-- Time stamp log messages
ALTER TABLE csr.auto_impexp_instance_msg
ADD msg_dtm DATE;

-- Time stamp existing messages with the start dtm of the instance they apply to
UPDATE csr.auto_impexp_instance_msg msg
   SET msg_dtm = (
		SELECT bj.requested_dtm
		  FROM csr.auto_import_message_map mm
		  JOIN csr.automated_import_instance i ON mm.import_instance_id = i.automated_import_instance_id
		  JOIN csr.batch_job bj ON bj.batch_job_id = i.batch_job_id
		 WHERE mm.message_id = msg.message_id
   )
 WHERE EXISTS ( 
	SELECT 1 
	  FROM CSR.auto_import_message_map mm
	 WHERE mm.message_id = msg.message_id
);
UPDATE csr.auto_impexp_instance_msg msg
   SET msg_dtm = (
      SELECT bj.requested_dtm
        FROM csr.auto_export_message_map mm
        JOIN csr.automated_export_instance e on mm.export_instance_id = e.automated_export_instance_id
        JOIN csr.batch_job bj on bj.batch_job_id = e.batch_job_id
       WHERE mm.message_id = msg.message_id
   )
 WHERE EXISTS ( 
	SELECT 1 
	  FROM CSR.auto_export_message_map mm
	 WHERE mm.message_id = msg.message_id
);
-- Just in case; Use a random Dtm, so we can make the column nullable. Utlimately anything being updated here
-- can't have a matching instance and therefore isn't accessible anyway...
UPDATE CSR.auto_impexp_instance_msg
   SET msg_dtm = DATE '1970-01-01'
 WHERE msg_dtm IS NULL;
 
ALTER TABLE csr.auto_impexp_instance_msg
MODIFY msg_dtm NOT NULL;

-- Update the securable object classes
UPDATE security.securable_object_class
   SET class_name = 'CSRAutomatedImport',
       helper_pkg = 'crs.automated_import_pkg'
 WHERE class_name = 'CSRCmsDataImport';
 
UPDATE security.securable_object_class
   SET class_name = 'CSRAutomatedExport',
       helper_pkg = 'crs.automated_export_pkg'
 WHERE class_name = 'AutomatedExport';

-- Alter the DB scheduler

-- Drop the old jobs. Try and drop in both csr and UPD because of issues with the latest scripts. Live should both be in csr, but local, etc..
BEGIN
  DBMS_SCHEDULER.DROP_JOB (job_name => 'csr.CMSDATAIMPORT');
EXCEPTION
  when OTHERS then
    null;
END;
/
BEGIN
  DBMS_SCHEDULER.DROP_JOB (job_name => 'upd.CMSDATAIMPORT');
EXCEPTION
  when OTHERS then
    null;
END;
/
BEGIN
  DBMS_SCHEDULER.DROP_JOB (job_name => 'csr.AUTOMATEDEXPORT');
EXCEPTION
  when OTHERS then
    null;
END;
/
BEGIN
  DBMS_SCHEDULER.DROP_JOB (job_name => 'upd.AUTOMATEDEXPORT');
EXCEPTION
  when OTHERS then
    null;
END;
/

BEGIN

  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'csr.AutomatedExportImport',
    job_type        => 'PLSQL_BLOCK',
    job_action      => '   
          BEGIN
          security.user_pkg.logonadmin();
          csr.automated_export_import_pkg.ScheduleRun();
          commit;
          END;
    ',
	job_class       => 'low_priority_job',
	start_date      => to_timestamp_tz('2015/02/24 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	repeat_interval => 'FREQ=HOURLY',
	enabled         => TRUE,
	auto_drop       => FALSE,
	comments        => 'Schedule for automated export import framework. Check for new imports and exports to queue in batch jobs.');
END;
/

-- Change the menus and web resources
BEGIN
	FOR r IN (
		SELECT m.sid_id, m.description, m.action, c.host
		  FROM security.menu m
		  JOIN security.securable_object so ON m.sid_id = so.sid_id
		  JOIN csr.customer c on c.app_sid = so.application_sid_id
		 WHERE lower(action) like '/csr/site/cmsdataimp%'
	)
	LOOP
		security.user_pkg.logonadmin(r.host);
		DBMS_OUTPUT.PUT_LINE('CHANGING ACTION ON '||r.description||' on '||r.host||' sid '||r.sid_id);
		security.menu_pkg.SetMenuAction(SYS_CONTEXT('SECURITY', 'ACT'), r.sid_id, REPLACE(LOWER(r.action), '/csr/site/cmsdataimp', '/csr/site/automatedExportImport'));
		-- Change the description too, but only if the client hasn't done so already
		IF lower(r.description) = 'scheduled imports' THEN
		  security.menu_pkg.SetMenuDescription(SYS_CONTEXT('SECURITY', 'ACT'), r.sid_id, 'Scheduled exports and imports');
		  DBMS_OUTPUT.PUT_LINE('ALSO CHANGING DESC');
		END IF;
	END LOOP;
	security.user_pkg.logonadmin();
END;
/
BEGIN
	FOR r IN (
		SELECT wr.sid_id, wr.path, c.host
		  FROM security.web_resource wr
		  JOIN security.securable_object so ON wr.sid_id = so.sid_id
		  JOIN csr.customer c on c.app_sid = so.application_sid_id
		 WHERE lower(wr.path) = '/csr/site/cmsdataimp'
	)
	LOOP
		security.user_pkg.logonadmin(r.host);
		DBMS_OUTPUT.PUT_LINE('RENAMING '||r.path||' on '||r.host||' sid '||r.sid_id);
		security.securableobject_pkg.RenameSO(SYS_CONTEXT('SECURITY', 'ACT'), r.sid_id, 'automatedExportImport');
	END LOOP;
	security.user_pkg.logonadmin();
END;
/
BEGIN
	FOR r IN (
		SELECT so.sid_id, so.name, c.host
		  FROM security.securable_object so
		  JOIN csr.customer c on c.app_sid = so.application_sid_id
		 WHERE so.CLASS_ID 		= 4
		   AND LOWER(so.name) 	= 'cmsdataimports'
		   AND so.parent_sid_id	= application_sid_id --security.security_pkg.SO_CONTAINER
	)
	LOOP
		security.user_pkg.logonadmin(r.host);
		DBMS_OUTPUT.PUT_LINE('RENAMING '||r.name||' on '||r.host);
		security.securableobject_pkg.RenameSO(SYS_CONTEXT('SECURITY', 'ACT'), r.sid_id, 'AutomatedImports');
	END LOOP;
	security.user_pkg.logonadmin();
END;
/
-- Update the enables
UPDATE csr.module 
   SET 	module_name	= 'Automated export import framework',
		enable_sp 	= 'EnableAutomatedExportImport',
		description = 'Enables the automated export/import framework. Pages, menus, capabilities, etc'
 WHERE LOWER(module_name) = 'cms data import';

DELETE FROM csr.module
WHERE LOWER(module_name) = 'automated exports';

-- Old, unneeded tables
DROP TABLE CSR.automated_export_alias;
DROP TABLE CSR.automated_export_ind_columns;
DROP TABLE CSR.automated_export_ind_member;
DROP TABLE CSR.automated_export_inst_files;
DROP TABLE CSR.automated_export_region_member;
DROP TABLE CSR.automated_export_ind_conf;

-- New payload handling for exports
ALTER TABLE csr.automated_export_instance
ADD payload blob;
ALTER TABLE csr.automated_export_instance
ADD payload_filename varchar2(1024);

@../csr_data_pkg
@../batch_job_pkg
@../csr_app_body
@../automated_export_import_pkg
@../automated_export_import_body
@../automated_export_pkg
@../automated_export_body
@../automated_import_pkg
@../automated_import_body
@../enable_pkg
@../enable_body

GRANT EXECUTE ON csr.automated_import_pkg TO web_user;
GRANT EXECUTE ON csr.automated_export_pkg TO web_user;
DROP PACKAGE csr.cms_data_imp_pkg;

@update_tail