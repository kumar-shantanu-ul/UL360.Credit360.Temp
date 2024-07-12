CREATE OR REPLACE PACKAGE BODY csr.test_automated_import_pkg AS

-- Fixture scope
v_site_name					VARCHAR(200);

------------------------------------
-- SETUP and TEARDOWN
------------------------------------
PROCEDURE DeleteData
AS
BEGIN
	FOR r IN (
		SELECT automated_import_class_sid FROM automated_import_class
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lookup_key like 'TestAutoImp%'
	)
	LOOP
		DELETE FROM automated_import_instance WHERE automated_import_class_sid = r.automated_import_class_sid;
		DELETE FROM automated_import_class WHERE automated_import_class_sid = r.automated_import_class_sid;
		security.securableObject_pkg.DeleteSO(security.security_pkg.GetACT, r.automated_import_class_sid);
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
	v_automated_import_class_sid	NUMBER;

	v_parent					security.security_pkg.T_SID_ID;
	v_import_container_sid		security.security_pkg.T_SID_ID;
BEGIN
	Trace('TestCreateClassWithNullParent');

	-- Parent not supplied
	automated_import_pkg.CreateClass(
		in_label					=>	'TestAutoImp-CreateClass',
		in_lookup_key				=>	'TestAutoImp-CreateClass',
		in_schedule_xml				=>	null,
		in_abort_on_error			=>	0,
		in_email_on_error			=>	0,
		in_email_on_partial			=>	0,
		in_email_on_success			=>	0,
		in_on_completion_sp			=>	'',
		in_import_plugin			=>	null,
		out_class_sid				=>	v_automated_import_class_sid
	);

	SELECT parent_sid_id
	  INTO v_parent
	  FROM security.securable_object
	 WHERE sid_id = v_automated_import_class_sid;

	v_import_container_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'AutomatedExportImport/AutomatedImports');

	csr.unit_test_pkg.AssertAreEqual(v_parent, v_import_container_sid, 'Unexpected parent.');
END;

PROCEDURE TestCreateClassWithNullParentWhenNoSubFolder
AS
	v_automated_import_class_sid	NUMBER;

	v_parent						security.security_pkg.T_SID_ID;
	v_exportimport_container_sid	security.security_pkg.T_SID_ID;
	v_import_container_sid			security.security_pkg.T_SID_ID;
BEGIN
	Trace('TestCreateClassWithNullParentWhenNoSubFolder');

	-- rename subcontainer
	v_import_container_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'AutomatedExportImport/AutomatedImports');
	security.securableobject_pkg.RenameSO(security.security_pkg.getact, v_import_container_sid, 'AutomatedImportsRenamed');

	-- Parent not supplied
	automated_import_pkg.CreateClass(
		in_label					=>	'TestAutoImp-CreateClass',
		in_lookup_key				=>	'TestAutoImp-CreateClass',
		in_schedule_xml				=>	null,
		in_abort_on_error			=>	0,
		in_email_on_error			=>	0,
		in_email_on_partial			=>	0,
		in_email_on_success			=>	0,
		in_on_completion_sp			=>	'',
		in_import_plugin			=>	null,
		out_class_sid				=>	v_automated_import_class_sid
	);

	SELECT parent_sid_id
	  INTO v_parent
	  FROM security.securable_object
	 WHERE sid_id = v_automated_import_class_sid;

	v_exportimport_container_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'AutomatedExportImport');
	csr.unit_test_pkg.AssertAreEqual(v_parent, v_exportimport_container_sid, 'Unexpected parent.');

	-- Rename back
	security.securableobject_pkg.RenameSO(security.security_pkg.getact, v_import_container_sid, 'AutomatedImports');
END;


PROCEDURE TestCreateClassWithExplicitParent
AS
	v_automated_import_class_sid	NUMBER;

	v_parent					security.security_pkg.T_SID_ID;
	v_import_container_sid		security.security_pkg.T_SID_ID;
BEGIN
	Trace('TestCreateClassWithExplicitParent');

	-- choose export one as a test
	v_import_container_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'AutomatedExportImport/AutomatedExports');

	-- Parent supplied
	automated_import_pkg.CreateClass(
		in_parent					=>	v_import_container_sid,
		in_label					=>	'TestAutoImp-CreateClass',
		in_lookup_key				=>	'TestAutoImp-CreateClass',
		in_schedule_xml				=>	null,
		in_abort_on_error			=>	0,
		in_email_on_error			=>	0,
		in_email_on_partial			=>	0,
		in_email_on_success			=>	0,
		in_on_completion_sp			=>	'',
		in_import_plugin			=>	null,
		out_class_sid				=>	v_automated_import_class_sid
	);

	SELECT parent_sid_id
	  INTO v_parent
	  FROM security.securable_object
	 WHERE sid_id = v_automated_import_class_sid;

	v_import_container_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'AutomatedExportImport/AutomatedExports');

	csr.unit_test_pkg.AssertAreEqual(v_parent, v_import_container_sid, 'Unexpected parent.');
END;

END test_automated_import_pkg;
/