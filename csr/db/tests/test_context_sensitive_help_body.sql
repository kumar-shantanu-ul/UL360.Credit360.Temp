CREATE OR REPLACE PACKAGE BODY csr.test_context_sensitive_help_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_label					VARCHAR2(255);
	v_count					NUMBER;
BEGIN
	security.user_pkg.logonadmin(in_site_name);

	DELETE FROM context_sensitive_help_redirect
	 WHERE source_path LIKE 'TestContextSensitiveHelpRedirect_%';
END;

PROCEDURE TestAddRedirect AS
	v_old_count			NUMBER;
	v_new_count			NUMBER;
	v_source_path		VARCHAR2(255) := 'TestContextSensitiveHelpRedirect__AddRedirect';
BEGIN
	SELECT COUNT(*)
	  INTO v_old_count
	  FROM context_sensitive_help_redirect
	 WHERE source_path like 'TestContextSensitiveHelpRedirect_%';

	context_sensitive_help_pkg.UpsertContextSensitiveHelpRedirect(
		in_source_path => v_source_path,
		in_help_path => v_source_path || '_help'
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM context_sensitive_help_redirect
	 WHERE source_path like 'TestContextSensitiveHelpRedirect_%';

	unit_test_pkg.AssertAreEqual((v_old_count+ 1), v_new_count, 'Expected count');
END;

PROCEDURE TestUpdateRedirect AS
	v_source_path			VARCHAR2(255) := 'TestContextSensitiveHelpRedirect__UpdateRedirect';
	v_help_path				VARCHAR2(255) := 'TestContextSensitiveHelpRedirect__UpdateRedirect_Help';
	v_help_path_updated		VARCHAR2(255) := 'TestContextSensitiveHelpRedirect__UpdateRedirect_Help_Updated';
	v_old_count				NUMBER;
	v_new_count				NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_old_count
	  FROM context_sensitive_help_redirect
	 WHERE source_path like v_source_path;

	context_sensitive_help_pkg.UpsertContextSensitiveHelpRedirect(
		in_source_path => v_source_path,
		in_help_path => v_help_path
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM context_sensitive_help_redirect
	 WHERE source_path = v_source_path;

	unit_test_pkg.AssertAreEqual((v_old_count+ 1), v_new_count, 'Expected count');

	context_sensitive_help_pkg.UpsertContextSensitiveHelpRedirect(
		in_source_path => v_source_path,
		in_help_path => v_help_path_updated
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM context_sensitive_help_redirect
	 WHERE source_path = v_source_path;

	unit_test_pkg.AssertAreEqual((v_old_count+ 1), v_new_count, 'Expected count');


	SELECT COUNT(*)
	  INTO v_new_count
	  FROM context_sensitive_help_redirect
	 WHERE source_path = v_source_path
	   AND help_path = v_help_path_updated;

	unit_test_pkg.AssertAreEqual(1, v_new_count, 'Should be only one');
END;

PROCEDURE TestDeleteRedirect AS
	v_source_path			VARCHAR2(255) := 'TestContextSensitiveHelpRedirect_DeleteRedirect';
	v_old_count				NUMBER;
	v_new_count				NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_old_count
	  FROM context_sensitive_help_redirect
	 WHERE source_path like v_source_path;

	context_sensitive_help_pkg.UpsertContextSensitiveHelpRedirect(
		in_source_path => v_source_path,
		in_help_path => v_source_path || '_help'
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM context_sensitive_help_redirect
	 WHERE source_path = v_source_path;

	unit_test_pkg.AssertAreEqual((v_old_count+ 1), v_new_count, 'Expected count');

	context_sensitive_help_pkg.DeleteContextSensitiveHelpRedirect(
		in_source_path => v_source_path
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM context_sensitive_help_redirect
	 WHERE source_path = v_source_path;

	unit_test_pkg.AssertAreEqual(0, v_new_count, 'Expected none');
END;

PROCEDURE TestGetOneRedirect AS
	v_source_path			VARCHAR2(255) := 'TestContextSensitiveHelpRedirect_GetSelectedRecord';
	v_count					NUMBER := 0;
	v_out_cur				SYS_REFCURSOR;
	v_cur_source_path		VARCHAR2(255);
	v_cur_help_path			VARCHAR2(255);
BEGIN
	context_sensitive_help_pkg.UpsertContextSensitiveHelpRedirect(
		in_source_path => v_source_path,
		in_help_path => v_source_path || '_help'
	);

	context_sensitive_help_pkg.GetContextSensitiveHelpRedirect(
		in_source_path => v_source_path,
		out_cur 		 => v_out_cur
	);

	LOOP
		FETCH v_out_cur INTO v_cur_source_path, v_cur_help_path;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count +1;
	END LOOP;

	unit_test_pkg.AssertAreEqual(1, v_count, 'Only single record must be returned');
END;

PROCEDURE TestGetAllRedirects AS
	v_source_path			VARCHAR2(255) := 'TestContextSensitiveHelpRedirect_GetAllRecords';
	v_count					NUMBER := 0;
	v_out_cur				SYS_REFCURSOR;
	v_cur_source_path		VARCHAR2(255);
	v_cur_help_path			VARCHAR2(255);
	v_index_1				NUMBER;
	v_index_2				NUMBER;
BEGIN
	context_sensitive_help_pkg.UpsertContextSensitiveHelpRedirect(
		in_source_path => v_source_path || '_002',
		in_help_path => v_source_path || '_help002'
	);

	context_sensitive_help_pkg.UpsertContextSensitiveHelpRedirect(
		in_source_path => v_source_path || '_001',
		in_help_path => v_source_path || '_help001'
	);

	context_sensitive_help_pkg.GetContextSensitiveHelpRedirects(
		out_cur 		 => v_out_cur
	);

	LOOP
		FETCH v_out_cur INTO v_cur_source_path, v_cur_help_path;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count +1;

		IF v_cur_source_path = v_source_path||'_001' THEN
			v_index_1 := v_count;
		END IF;
		IF v_cur_source_path = v_source_path||'_002' THEN
			v_index_2 := v_count;
		END IF;
	END LOOP;

	unit_test_pkg.AssertIsTrue(v_index_1 < v_index_2, 'Sort order should be correct.');
	unit_test_pkg.AssertIsTrue(v_count >=1, 'Number of saved records should be more than one');
END;


PROCEDURE TestBaseConstraints AS
	v_old_count			NUMBER;
	v_new_count			NUMBER;
	v_source_path		VARCHAR2(255) := 'TestContextSensitiveHelpBase__Add';
BEGIN
	SELECT COUNT(*)
	  INTO v_new_count
	  FROM context_sensitive_help_base;

	unit_test_pkg.AssertAreEqual(1, v_new_count, 'Expected count');

	BEGIN
		INSERT INTO context_sensitive_help_base (client_help_root, internal_help_root) VALUES ('another', 'record');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;


	SELECT COUNT(*)
	  INTO v_new_count
	  FROM context_sensitive_help_base;

	unit_test_pkg.AssertAreEqual(1, v_new_count, 'Expected count');
END;

PROCEDURE TestGetBase AS
	v_count					NUMBER := 0;
	v_out_cur				SYS_REFCURSOR;
	v_client_help_root		VARCHAR(255);
	v_internal_help_root	VARCHAR(255);
BEGIN
	context_sensitive_help_pkg.GetContextSensitiveHelpBase(
		out_cur 		 => v_out_cur
	);

	LOOP
		FETCH v_out_cur INTO v_client_help_root, v_internal_help_root;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count +1;
	END LOOP;

	unit_test_pkg.AssertAreEqual(1, v_count, 'Only single record must be returned');
END;



PROCEDURE TearDownFixture 
AS
	v_count				NUMBER;
	v_label				VARCHAR2(255);
	v_updated_label		VARCHAR2(255);

BEGIN
	DELETE FROM context_sensitive_help_redirect
	 WHERE source_path LIKE 'TestContextSensitiveHelpRedirect_%';
END;

END test_context_sensitive_help_pkg;
/
