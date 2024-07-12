-- Please update version.sql too -- this keeps clean builds in sync
define version=2935
define minor_version=20
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
EXEC security.user_pkg.logonadmin;
  
UPDATE csr.automated_import_class_step 
   SET plugin = 'Credit360.AutomatedExportImport.Import.Plugins.UrjanetImporterStepPlugin'
 WHERE importer_plugin_id = 2;
 
BEGIN  
  FOR x IN (
	SELECT map.app_sid app_sid, map.message_id message_id, message, severity, msg_dtm message_dtm
	  FROM csr.auto_import_message_map map
	  JOIN csr.auto_impexp_instance_msg msg ON msg.message_id = map.message_id AND msg.app_sid = map.app_sid
	 WHERE UPPER(message)='CRITICAL ERROR IN STEP'
	   AND (map.app_sid, import_instance_id) IN (
		SELECT app_sid, automated_import_instance_id 
		  FROM csr.automated_import_instance_step  
		 WHERE result=3 
		   AND payload_filename IS NULL 
		   AND (app_sid, automated_import_class_sid, step_number) IN (
			SELECT app_sid, automated_import_class_sid, step_number 
			  FROM csr.automated_import_class_step 
			 WHERE importer_plugin_id=2)))

LOOP
	DELETE FROM csr.auto_import_message_map WHERE message_id=x.message_id AND app_sid = x.app_sid;
	DELETE FROM csr.auto_impexp_instance_msg WHERE message_id=x.message_id AND app_sid = x.app_sid;
END LOOP;
END;
/ 

UPDATE csr.batch_job
   SET result='The import completed successfully'
 WHERE UPPER(result)='THE IMPORT FAILED' 
   AND (app_sid, batch_job_id) IN (
	SELECT ii.app_sid, batch_job_id 
      FROM csr.automated_import_instance ii
      JOIN csr.automated_import_instance_step  iis ON iis.automated_import_instance_id = ii.automated_import_instance_id AND ii.app_sid = iis.app_sid
     WHERE iis.result=3 
       AND iis.payload_filename IS NULL 
       AND (iis.app_sid, iis.automated_import_class_sid, step_number) IN (
		SELECT app_sid, automated_import_class_sid, step_number 
		  FROM csr.automated_import_class_step 
		 WHERE importer_plugin_id=2));
		 
UPDATE csr.automated_import_instance_step
   SET result=5
 WHERE result=3 
   AND payload_filename IS NULL 
   AND (app_sid, automated_import_class_sid,step_number) IN (
	SELECT app_sid, automated_import_class_sid,step_number 
	  FROM csr.automated_import_class_step 
	 WHERE importer_plugin_id=2);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail
