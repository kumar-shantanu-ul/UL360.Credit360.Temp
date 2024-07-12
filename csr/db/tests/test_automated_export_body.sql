CREATE OR REPLACE PACKAGE BODY csr.test_automated_export_pkg AS

-- Fixture scope
v_site_name					VARCHAR(200);

------------------------------------
-- SETUP and TEARDOWN
------------------------------------
PROCEDURE DeleteData
AS
BEGIN
	DELETE FROM AUTO_EXP_FILECREATE_DSV
	 WHERE app_sid = security.security_pkg.GetAPP;
	 
	FOR r IN (
		SELECT automated_export_class_sid FROM automated_export_class
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lookup_key like 'TestAutoExp%'
	)
	LOOP
		DELETE FROM automated_export_instance WHERE automated_export_class_sid = r.automated_export_class_sid;
		DELETE FROM automated_export_class WHERE automated_export_class_sid = r.automated_export_class_sid;
		security.securableObject_pkg.DeleteSO(security.security_pkg.GetACT, r.automated_export_class_sid);
	END LOOP;
END;

PROCEDURE SetUp
AS
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);
	DeleteData;
END;

-- Called after each PASSED test
PROCEDURE TearDown
AS
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);
	DeleteData;
END;

-- Called once before all tests
PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.LogonAdmin(v_site_name);
END;

-- Called once after all tests have PASSED
PROCEDURE TearDownFixture
AS
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);
END;

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	--dbms_output.put_line(s);
	NULL;
END;


PROCEDURE TestCreateClassWithNullParent
AS
	v_automated_export_class_sid	NUMBER;

	v_out_cur 					SYS_REFCURSOR;
	v_delimiter_id				NUMBER;
	v_secondary_delimiter_id	NUMBER;
	v_encoding_name				VARCHAR(200);
	v_encode_newline			NUMBER;

	v_count						NUMBER;
	v_parent					security.security_pkg.T_SID_ID;
	v_export_container_sid		security.security_pkg.T_SID_ID;
BEGIN
	Trace('TestCreateClassWithNullParent');

	-- Parent not supplied
	automated_export_pkg.CreateClass(
		in_label					=>	'TestAutoExp-CreateClass',
		in_schedule_xml				=>	null,
		in_file_mask				=>	'test.csv',
		in_file_mask_date_format	=>	null,
		in_email_on_error			=>	0,
		in_email_on_success			=>	0,
		in_exporter_plugin_id		=>	1, -- dataview dsv
		in_file_writer_plugin_id	=>	5, -- manual download
		in_include_headings			=>	0,
		in_output_empty_as			=>	null,
		in_lookup_key				=>	'TestAutoExp-CreateClass',
		out_class_sid				=>	v_automated_export_class_sid
	);

	SELECT parent_sid_id
	  INTO v_parent
	  FROM security.securable_object
	 WHERE sid_id = v_automated_export_class_sid;

	v_export_container_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'AutomatedExportImport/AutomatedExports');

	csr.unit_test_pkg.AssertAreEqual(v_parent, v_export_container_sid, 'Unexpected parent.');
END;

PROCEDURE TestCreateClassWithExplicitParent
AS
	v_automated_export_class_sid	NUMBER;

	v_parent					security.security_pkg.T_SID_ID;
	v_export_container_sid		security.security_pkg.T_SID_ID;
BEGIN
	Trace('TestCreateClassWithExplicitParent');

	-- choose import one as a test
	v_export_container_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'AutomatedExportImport/AutomatedImports');

	-- Parent supplied
	automated_export_pkg.CreateClass(
		in_parent					=>	v_export_container_sid,
		in_label					=>	'TestAutoExp-CreateClass',
		in_schedule_xml				=>	null,
		in_file_mask				=>	'test.csv',
		in_file_mask_date_format	=>	null,
		in_email_on_error			=>	0,
		in_email_on_success			=>	0,
		in_exporter_plugin_id		=>	1, -- dataview dsv
		in_file_writer_plugin_id	=>	5, -- manual download
		in_include_headings			=>	0,
		in_output_empty_as			=>	null,
		in_lookup_key				=>	'TestAutoExp-CreateClass',
		out_class_sid				=>	v_automated_export_class_sid
	);

	SELECT parent_sid_id
	  INTO v_parent
	  FROM security.securable_object
	 WHERE sid_id = v_automated_export_class_sid;

	v_export_container_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'AutomatedExportImport/AutomatedImports');

	csr.unit_test_pkg.AssertAreEqual(v_parent, v_export_container_sid, 'Unexpected parent.');
END;

PROCEDURE TestCreateClassWithNullParentWhenNoSubFolder
AS
	v_automated_export_class_sid	NUMBER;

	v_parent						security.security_pkg.T_SID_ID;
	v_exportimport_container_sid	security.security_pkg.T_SID_ID;
	v_export_container_sid			security.security_pkg.T_SID_ID;
BEGIN
	Trace('TestCreateClassWithNullParentWhenNoSubFolder');

	-- rename subcontainer
	v_export_container_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'AutomatedExportImport/AutomatedExports');
	security.securableobject_pkg.RenameSO(security.security_pkg.getact, v_export_container_sid, 'AutomatedExportsRenamed');

	-- Parent not supplied
	automated_export_pkg.CreateClass(
		in_label					=>	'TestAutoExp-CreateClass',
		in_schedule_xml				=>	null,
		in_file_mask				=>	'test.csv',
		in_file_mask_date_format	=>	null,
		in_email_on_error			=>	0,
		in_email_on_success			=>	0,
		in_exporter_plugin_id		=>	1, -- dataview dsv
		in_file_writer_plugin_id	=>	5, -- manual download
		in_include_headings			=>	0,
		in_output_empty_as			=>	null,
		in_lookup_key				=>	'TestAutoExp-CreateClass',
		out_class_sid				=>	v_automated_export_class_sid
	);

	SELECT parent_sid_id
	  INTO v_parent
	  FROM security.securable_object
	 WHERE sid_id = v_automated_export_class_sid;

	v_exportimport_container_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'AutomatedExportImport');
	csr.unit_test_pkg.AssertAreEqual(v_parent, v_exportimport_container_sid, 'Unexpected parent.');

	-- Rename back
	security.securableobject_pkg.RenameSO(security.security_pkg.getact, v_export_container_sid, 'AutomatedExports');
END;


PROCEDURE TestGetDsvSettingsByClass
AS
	v_automated_export_class_sid	NUMBER;

	v_out_cur 					SYS_REFCURSOR;
	v_delimiter_id				NUMBER;
	v_secondary_delimiter_id	NUMBER;
	v_encoding_name				VARCHAR(200);
	v_encode_newline			NUMBER;

	v_count						NUMBER;
	v_parent					security.security_pkg.T_SID_ID;
BEGIN
	Trace('TestGetDsvSettingsByClass');

	v_parent := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'AutomatedExportImport');
	automated_export_pkg.CreateClass(
		in_parent					=>	v_parent,
		in_label					=>	'TestAutoExp-GetDsvSettingsByClass',
		in_schedule_xml				=>	null,
		in_file_mask				=>	'test.csv',
		in_file_mask_date_format	=>	null,
		in_email_on_error			=>	0,
		in_email_on_success			=>	0,
		in_exporter_plugin_id		=>	1, -- dataview dsv
		in_file_writer_plugin_id	=>	5, -- manual download
		in_include_headings			=>	0,
		in_output_empty_as			=>	null,
		in_lookup_key				=>	'TestAutoExp-GetDsvSettingsByClass',
		out_class_sid				=>	v_automated_export_class_sid
	);


	automated_export_pkg.GetDsvSettingsByClass(
		in_automated_export_class_sid => v_automated_export_class_sid,
		out_cur => v_out_cur
	);

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO v_delimiter_id, v_secondary_delimiter_id, v_encoding_name, v_encode_newline;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count +1;
	END LOOP;

	csr.unit_test_pkg.AssertAreEqual(v_count, 1, 'Unexpected count.');
	csr.unit_test_pkg.AssertAreEqual(v_encode_newline, 0, 'unexpected value for encode_newline.');

	automated_export_pkg.UpdateDsvSettings(
		in_automated_export_class_sid		=>	v_automated_export_class_sid,
		in_delimiter_id						=>	0,
		in_secondary_delimiter_id			=>	null,
		in_encoding_name					=>	null,
		in_encode_newline					=>	1
	);

	automated_export_pkg.GetDsvSettingsByClass(
		in_automated_export_class_sid => v_automated_export_class_sid,
		out_cur => v_out_cur
	);

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO v_delimiter_id, v_secondary_delimiter_id, v_encoding_name, v_encode_newline;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count +1;
	END LOOP;

	csr.unit_test_pkg.AssertAreEqual(v_count, 1, 'Unexpected count.');
	csr.unit_test_pkg.AssertAreEqual(v_encode_newline, 1, 'Unexpected value for encode_newline.');



	automated_export_pkg.UpdateDsvSettings(
		in_automated_export_class_sid		=>	v_automated_export_class_sid,
		in_delimiter_id						=>	0,
		in_secondary_delimiter_id			=>	null,
		in_encoding_name					=>	null,
		in_encode_newline					=>	2
	);

	automated_export_pkg.GetDsvSettingsByClass(
		in_automated_export_class_sid => v_automated_export_class_sid,
		out_cur => v_out_cur
	);

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO v_delimiter_id, v_secondary_delimiter_id, v_encoding_name, v_encode_newline;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count +1;
	END LOOP;

	csr.unit_test_pkg.AssertAreEqual(v_count, 1, 'Unexpected count.');
	csr.unit_test_pkg.AssertAreEqual(v_encode_newline, 2, 'Unexpected value for encode_newline.');
END;


PROCEDURE TestAppendAndResetPayload
AS
	v_automated_export_class_sid		automated_export_class.automated_export_class_sid%TYPE;
	v_automated_export_inst_id			automated_export_instance.automated_export_instance_id%TYPE;
	v_batch_job_id						batch_job.batch_job_id%TYPE;

	v_payload_1 						BLOB;
	v_payload_2 						BLOB;
	v_filename  						VARCHAR2(100);
	v_count								NUMBER;
	v_payload_size						NUMBER;
	v_total_size 						NUMBER;
	v_parent							security.security_pkg.T_SID_ID;
BEGIN
	Trace('TestAppendAndResetPayload');

	v_payload_1 := UTL_RAW.CAST_TO_RAW('First chunk');
	v_payload_2 := UTL_RAW.CAST_TO_RAW('Second chunk');
	v_filename := 'data.csv';
	
	v_parent := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'AutomatedExportImport');
	automated_export_pkg.CreateClass(
		in_parent					=>	v_parent,
		in_label					=>	'TestAutoExp-GetDsvSettingsByClass',
		in_schedule_xml				=>	null,
		in_file_mask				=>	'test.csv',
		in_file_mask_date_format	=>	null,
		in_email_on_error			=>	0,
		in_email_on_success			=>	0,
		in_exporter_plugin_id		=>	1, -- dataview dsv
		in_file_writer_plugin_id	=>	5, -- manual download
		in_include_headings			=>	0,
		in_output_empty_as			=>	null,
		in_lookup_key				=>	'TestAutoExp-GetDsvSettingsByClass',
		out_class_sid				=>	v_automated_export_class_sid
	);

	SELECT aut_export_inst_id_seq.NEXTVAL
	  INTO v_automated_export_inst_id
	  FROM DUAL;

	SELECT batch_job_id_seq.NEXTVAL
	  INTO v_batch_job_id
	  FROM DUAL;

	INSERT INTO automated_export_instance
		(automated_export_instance_id, automated_export_class_sid, batch_job_id, is_preview)
	VALUES 
		(v_automated_export_inst_id, v_automated_export_class_sid, v_batch_job_id, 0);

	SELECT COUNT(*) 
	  INTO v_count 
	  FROM automated_export_instance 
	 WHERE automated_export_instance_id = v_automated_export_inst_id;

	csr.unit_test_pkg.AssertAreEqual(v_count, 1, 'Unexpected count.');
	
	automated_export_pkg.AppendToInstancePayload(
			in_instance_id => v_automated_export_inst_id,
			in_payload_chunk => v_payload_1,
			in_payload_filename => v_filename
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM automated_export_instance
	 WHERE automated_export_instance_id = v_automated_export_inst_id;

	csr.unit_test_pkg.AssertAreEqual(v_count, 1, 'The count should remain one after first chunk update.'); 

	-- Append the second chunk
	automated_export_pkg.AppendToInstancePayload(
			in_instance_id => v_automated_export_inst_id,
			in_payload_chunk => v_payload_2,
			in_payload_filename => v_filename
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM automated_export_instance
	 WHERE automated_export_instance_id = v_automated_export_inst_id;

	csr.unit_test_pkg.AssertAreEqual(v_count, 1, 'The count should remain one after second chunk update.'); 

	SELECT DBMS_LOB.GETLENGTH(payload) 
	  INTO v_payload_size 
	  FROM automated_export_instance 
	 WHERE automated_export_instance_id = v_automated_export_inst_id;

	SELECT DBMS_LOB.GETLENGTH(v_payload_1) +  DBMS_LOB.GETLENGTH(v_payload_2) 
	  INTO v_total_size 
	  FROM DUAL;

	-- Ensure that the total size is the sum of sizes of both payloads
	csr.unit_test_pkg.AssertAreEqual(v_payload_size, v_total_size, 'Size is the sum of sizes of both payloads.');

	automated_export_pkg.ResetInstancePayload(
			in_instance_id => v_automated_export_inst_id,
			in_payload_filename => v_filename
	);

	SELECT DBMS_LOB.GETLENGTH(payload)
	  INTO v_payload_size
	  FROM  automated_export_instance
	 WHERE automated_export_instance_id = v_automated_export_inst_id;

	csr.unit_test_pkg.AssertIsNull(v_payload_size,  'Payload should be null after reset.');
END;

END test_automated_export_pkg;
/