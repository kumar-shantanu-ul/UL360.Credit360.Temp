-- Please update version.sql too -- this keeps clean builds in sync
define version=2957
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.batched_export_type (
	batch_export_type_id	NUMBER(10) NOT NULL,
	label					VARCHAR2(255) NOT NULL,
	assembly				VARCHAR2(1024) NOT NULL,
	CONSTRAINT pk_batched_export_type PRIMARY KEY (batch_export_type_id)
);

CREATE TABLE csr.batch_job_batched_export (
	app_sid                 NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL ,
	batch_job_id            NUMBER(10) NOT NULL,
	batch_export_type_id	NUMBER(10) NOT NULL,
	settings_xml			XMLTYPE NOT NULL,
	file_blob				BLOB,
	file_name				VARCHAR2(1024),
	CONSTRAINT pk_bj_batched_export PRIMARY KEY (app_sid, batch_job_id),
	CONSTRAINT fk_bj_batched_export_bj_id FOREIGN KEY (app_sid, batch_job_id) REFERENCES csr.batch_job(app_sid, batch_job_id),
	CONSTRAINT fk_bj_batched_export_type FOREIGN KEY (batch_export_type_id) REFERENCES csr.batched_export_type (batch_export_type_id)  
);

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (0, 'Full user export', 'Credit360.ExportImport.Export.Batched.Exporters.FullUserListExporter');
INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (1, 'Filtered user export', 'Credit360.ExportImport.Export.Batched.Exporters.FilteredUserListExporter');
INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (2, 'Region list export', 'Credit360.ExportImport.Export.Batched.Exporters.RegionListExporter');
INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (3, 'Indicator list export', 'Credit360.ExportImport.Export.Batched.Exporters.IndicatorListExporter');
INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (4, 'Data export', 'Credit360.ExportImport.Export.Batched.Exporters.DataExportExporter');
INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (5, 'Region role membership export', 'Credit360.ExportImport.Export.Batched.Exporters.RegionRoleExporter');
INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (6, 'Region and meter export', 'Credit360.ExportImport.Export.Batched.Exporters.RegionAndMeterExporter');
INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (7, 'Measure list export', 'Credit360.ExportImport.Export.Batched.Exporters.MeasureListExporter');

UPDATE csr.auto_exp_exporter_plugin
   SET exporter_assembly = REPLACE(exporter_assembly, '.AutomatedExportImport.', '.ExportImport.Automated.'),
       outputter_assembly = REPLACE(outputter_assembly, '.AutomatedExportImport.', '.ExportImport.Automated.');
UPDATE csr.AUTO_EXP_FILE_WRITER_PLUGIN
   SET assembly = REPLACE(assembly, '.AutomatedExportImport.', '.ExportImport.Automated.');
UPDATE csr.AUTO_IMP_FILEREAD_PLUGIN
   SET fileread_assembly = REPLACE(fileread_assembly, '.AutomatedExportImport.', '.ExportImport.Automated.');
UPDATE csr.AUTO_IMP_IMPORTER_PLUGIN
   SET importer_assembly = REPLACE(importer_assembly, '.AutomatedExportImport.', '.ExportImport.Automated.');

INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
VALUES (27, 'Batched exporter', null, 'batch-exporter', 0, null);

--Create web resource and batch container on ALL sites for the download link
DECLARE
	v_act_id 					security.security_pkg.T_ACT_ID;
	v_reg_users_sid				security.security_pkg.T_SID_ID;
	v_www_root					security.security_pkg.T_SID_ID;
	v_www_csr_site				security.security_pkg.T_SID_ID;
	v_www_csr_site_batchExports	security.security_pkg.T_SID_ID;
	v_sid						security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin();
	v_act_id := security.security_pkg.GetAct();
	
	FOR r IN (
		SELECT app_sid FROM csr.customer
	)
	LOOP
	
	-- Web resource
		v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot');
		BEGIN
			v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_root, 'csr/site');
		
			BEGIN
				v_www_csr_site_batchExports := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_www_csr_site, 'batchExports');
			EXCEPTION 
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_csr_site, 'batchExports', v_www_csr_site_batchExports);	
					
					-- give the RegisteredUsers group READ permission on the resource
					security.acl_pkg.AddACE(
						v_act_id, 
						security.acl_pkg.GetDACLIDForSID(v_www_csr_site_batchExports), 
						security.security_pkg.ACL_INDEX_LAST, 
						security.security_pkg.ACE_TYPE_ALLOW,
						security.security_pkg.ACE_FLAG_DEFAULT, 
						security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'Groups/RegisteredUsers'), 
						security.security_pkg.PERMISSION_STANDARD_READ
					);	
			END;
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
		
		-- Container for batch export dataviews
		BEGIN
			security.Securableobject_Pkg.CreateSO(v_act_id, r.app_sid, security.security_pkg.SO_CONTAINER, 'BatchExportDataviews', v_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, r.app_sid, 'BatchExportDataviews');
		END;
		-- give the RegisteredUsers group READ/WRITE permission on the resource
		security.acl_pkg.AddACE(
			v_act_id, 
			security.acl_pkg.GetDACLIDForSID(v_sid), 
			security.security_pkg.ACL_INDEX_LAST, 
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, 
			security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'Groups/RegisteredUsers'), 
			security.security_pkg.PERMISSION_STANDARD_READ + security.security_pkg.PERMISSION_WRITE + security.security_pkg.PERMISSION_DELETE + security.security_pkg.PERMISSION_ADD_CONTENTS
		);
	END LOOP;
END;
/

BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'csr.BATCHEDEXPORTSCLEARUP',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN security.user_pkg.logonadmin(); csr.batch_exporter_pkg.ScheduledFileClearUp; commit; END;',
	job_class		=> 'low_priority_job',
	start_date		=> to_timestamp_tz('2016/09/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	repeat_interval	=> 'FREQ=DAILY',
	enabled			=> TRUE,
	auto_drop		=> FALSE,
	comments		=> 'Schedule for removing batched exports file data from the database, so we do not use endless space');
END;
/

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.batch_exporter_pkg as end;
/
GRANT EXECUTE ON csr.batch_exporter_pkg TO WEB_USER;

-- *** Conditional Packages ***

-- *** Packages ***
@../batch_job_pkg
@../batch_exporter_pkg
@../batch_exporter_body

@update_tail
