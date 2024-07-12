CREATE OR REPLACE PACKAGE BODY csr.test_schema_pkg AS

v_site_name		VARCHAR2(200);

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	dbms_output.put_line(s);
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);
END;

PROCEDURE TearDownFixture
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
END;

PROCEDURE GetIssueLogsFilteredWhenNoIssueLogFiles
AS
	v_issue_action_log_cur				SYS_REFCURSOR;
	v_issue_log_cur						SYS_REFCURSOR;
	v_issue_log_file_cur				SYS_REFCURSOR;
	v_issue_log_read_cur				SYS_REFCURSOR;
	-- the cursor contents...
	v_issue_log_file_id					issue_log_file.issue_log_file_id%TYPE;
	v_issue_log_id						issue_log_file.issue_log_id%TYPE;
	v_filename							issue_log_file.filename%TYPE;
	v_mime_type							issue_log_file.mime_type%TYPE;
	v_data								issue_log_file.data%TYPE;
	v_sha1								issue_log_file.sha1%TYPE;
	v_uploaded_dtm						issue_log_file.uploaded_dtm%TYPE;
	v_archive_file_id					issue_log_file.archive_file_id%TYPE;
	v_archive_file_size					issue_log_file.archive_file_size%TYPE;

	v_count								NUMBER;
BEGIN
	unit_test_pkg.StartTest('csr.schema_pkg.GetIssueLogsFilteredWhenNoIssueLogFiles');
	
	schema_pkg.GetIssueLogsFiltered(
		in_issue_log_file_filter => 0,
		in_issue_log_file_data => 0,
		out_issue_action_log_cur => v_issue_action_log_cur,
		out_issue_log_cur => v_issue_log_cur,
		out_issue_log_file_cur => v_issue_log_file_cur,
		out_issue_log_read_cur => v_issue_log_read_cur
	);

	v_count := 0;
	LOOP
		FETCH v_issue_log_file_cur INTO 
			v_issue_log_file_id,
			v_issue_log_id,
			v_filename,
			v_mime_type,
			v_data,
			v_sha1,
			v_uploaded_dtm,
			v_archive_file_id,
			v_archive_file_size
		;
		EXIT WHEN v_issue_log_file_cur%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;

	--If no exception test is successful
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 results');


	schema_pkg.GetIssueLogsFiltered(
		in_issue_log_file_filter => 1,
		in_issue_log_file_data => 0,
		out_issue_action_log_cur => v_issue_action_log_cur,
		out_issue_log_cur => v_issue_log_cur,
		out_issue_log_file_cur => v_issue_log_file_cur,
		out_issue_log_read_cur => v_issue_log_read_cur
	);

	v_count := 0;
	LOOP
		FETCH v_issue_log_file_cur INTO 
			v_issue_log_file_id,
			v_issue_log_id,
			v_filename,
			v_mime_type,
			v_data,
			v_sha1,
			v_uploaded_dtm,
			v_archive_file_id,
			v_archive_file_size
		;
		EXIT WHEN v_issue_log_file_cur%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;

	--If no exception test is successful
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 results');

	schema_pkg.GetIssueLogsFiltered(
		in_issue_log_file_filter => 0,
		in_issue_log_file_data => 1,
		out_issue_action_log_cur => v_issue_action_log_cur,
		out_issue_log_cur => v_issue_log_cur,
		out_issue_log_file_cur => v_issue_log_file_cur,
		out_issue_log_read_cur => v_issue_log_read_cur
	);

	v_count := 0;
	LOOP
		FETCH v_issue_log_file_cur INTO 
			v_issue_log_file_id,
			v_issue_log_id,
			v_filename,
			v_mime_type,
			v_data,
			v_sha1,
			v_uploaded_dtm,
			v_archive_file_id,
			v_archive_file_size
		;
		EXIT WHEN v_issue_log_file_cur%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;

	--If no exception test is successful
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 results');
	schema_pkg.GetIssueLogsFiltered(
		in_issue_log_file_filter => 1,
		in_issue_log_file_data => 1,
		out_issue_action_log_cur => v_issue_action_log_cur,
		out_issue_log_cur => v_issue_log_cur,
		out_issue_log_file_cur => v_issue_log_file_cur,
		out_issue_log_read_cur => v_issue_log_read_cur
	);

	v_count := 0;
	LOOP
		FETCH v_issue_log_file_cur INTO 
			v_issue_log_file_id,
			v_issue_log_id,
			v_filename,
			v_mime_type,
			v_data,
			v_sha1,
			v_uploaded_dtm,
			v_archive_file_id,
			v_archive_file_size
		;
		EXIT WHEN v_issue_log_file_cur%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;

	--If no exception test is successful
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 results');
END;

PROCEDURE GetIssueLogsFilteredWhenIssueLogFiles
AS
	-- Test data
	v_issue_type_id						issue_type.issue_type_id%TYPE;
	v_new_issue_id						issue.issue_id%TYPE;
	v_new_issue_log_id					issue_log.issue_log_id%TYPE;

	v_issue_action_log_cur				SYS_REFCURSOR;
	v_issue_log_cur						SYS_REFCURSOR;
	v_issue_log_file_cur				SYS_REFCURSOR;
	v_issue_log_read_cur				SYS_REFCURSOR;
	-- the cursor contents...
	v_issue_log_file_id					issue_log_file.issue_log_file_id%TYPE;
	v_issue_log_id						issue_log_file.issue_log_id%TYPE;
	v_filename							issue_log_file.filename%TYPE;
	v_mime_type							issue_log_file.mime_type%TYPE;
	v_data								issue_log_file.data%TYPE;
	v_sha1								issue_log_file.sha1%TYPE;
	v_uploaded_dtm						issue_log_file.uploaded_dtm%TYPE;
	v_archive_file_id					issue_log_file.archive_file_id%TYPE;
	v_archive_file_size					issue_log_file.archive_file_size%TYPE;

	v_count								NUMBER;
BEGIN
	unit_test_pkg.StartTest('csr.schema_pkg.GetIssueLogsFilteredWhenIssueLogFiles');

	SELECT MIN(issue_type_id)
	  INTO v_issue_type_id
	  FROM issue_type;


	INSERT INTO csr.issue (issue_id, label, description, raised_dtm, raised_by_user_sid, issue_type_id, owner_user_sid, assigned_to_user_sid)
	VALUES (csr.issue_id_seq.NEXTVAL, 'in_label', 'in_description', SYSDATE, 3, v_issue_type_id, 3, 3)
	RETURNING issue_id INTO v_new_issue_id;

	INSERT INTO issue_log (issue_log_id, issue_id, message, logged_by_user_sid, logged_dtm, is_system_generated, param_1, param_2, param_3)
		VALUES (issue_log_id_seq.nextval, v_new_issue_id, 'in_message', 3, SYSDATE, 0, NULL, NULL, NULL)
	RETURNING issue_log_id
	     INTO v_new_issue_log_id;

	INSERT INTO issue_log_file (issue_log_file_id, issue_log_id, filename, mime_type, data, sha1, uploaded_dtm)
	VALUES (issue_log_file_id_seq.nextval, v_new_issue_log_id, 'filename', 'mime_type', 'ABCD', dbms_crypto.hash('ABCD', dbms_crypto.hash_sh1), DATE '2023-07-01');

	-- filter out all files
	schema_pkg.GetIssueLogsFiltered(
		in_issue_log_file_filter => 0,
		in_issue_log_file_data => 0,
		out_issue_action_log_cur => v_issue_action_log_cur,
		out_issue_log_cur => v_issue_log_cur,
		out_issue_log_file_cur => v_issue_log_file_cur,
		out_issue_log_read_cur => v_issue_log_read_cur
	);

	v_count := 0;
	LOOP
		FETCH v_issue_log_file_cur INTO 
			v_issue_log_file_id,
			v_issue_log_id,
			v_filename,
			v_mime_type,
			v_data,
			v_sha1,
			v_uploaded_dtm,
			v_archive_file_id,
			v_archive_file_size
		;
		EXIT WHEN v_issue_log_file_cur%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;

	--If no exception test is successful
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 results');


	-- filter out no files
	schema_pkg.GetIssueLogsFiltered(
		in_issue_log_file_filter => 1,
		in_issue_log_file_data => 1,
		out_issue_action_log_cur => v_issue_action_log_cur,
		out_issue_log_cur => v_issue_log_cur,
		out_issue_log_file_cur => v_issue_log_file_cur,
		out_issue_log_read_cur => v_issue_log_read_cur
	);

	v_count := 0;
	LOOP
		FETCH v_issue_log_file_cur INTO 
			v_issue_log_file_id,
			v_issue_log_id,
			v_filename,
			v_mime_type,
			v_data,
			v_sha1,
			v_uploaded_dtm,
			v_archive_file_id,
			v_archive_file_size
		;
		EXIT WHEN v_issue_log_file_cur%NOTFOUND;
		v_count := v_count + 1;

		unit_test_pkg.AssertIsNotNull(UTL_RAW.CAST_TO_VARCHAR2(v_data), 'Expected data');
		unit_test_pkg.AssertIsNotNull(UTL_RAW.CAST_TO_VARCHAR2(v_sha1), 'Expected data');
		unit_test_pkg.AssertIsNotNull(v_archive_file_id, 'Expected data');
		unit_test_pkg.AssertIsNotNull(v_archive_file_size, 'Expected data');
	END LOOP;

	--If no exception test is successful
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 results');


	-- filter out files before date
	schema_pkg.GetIssueLogsFiltered(
		in_issue_log_file_filter => 20230801,
		in_issue_log_file_data => 1,
		out_issue_action_log_cur => v_issue_action_log_cur,
		out_issue_log_cur => v_issue_log_cur,
		out_issue_log_file_cur => v_issue_log_file_cur,
		out_issue_log_read_cur => v_issue_log_read_cur
	);

	v_count := 0;
	LOOP
		FETCH v_issue_log_file_cur INTO 
			v_issue_log_file_id,
			v_issue_log_id,
			v_filename,
			v_mime_type,
			v_data,
			v_sha1,
			v_uploaded_dtm,
			v_archive_file_id,
			v_archive_file_size
		;
		EXIT WHEN v_issue_log_file_cur%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;

	--If no exception test is successful
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 results');

	-- filter out files after date
	schema_pkg.GetIssueLogsFiltered(
		in_issue_log_file_filter => 20221201,
		in_issue_log_file_data => 1,
		out_issue_action_log_cur => v_issue_action_log_cur,
		out_issue_log_cur => v_issue_log_cur,
		out_issue_log_file_cur => v_issue_log_file_cur,
		out_issue_log_read_cur => v_issue_log_read_cur
	);

	v_count := 0;
	LOOP
		FETCH v_issue_log_file_cur INTO 
			v_issue_log_file_id,
			v_issue_log_id,
			v_filename,
			v_mime_type,
			v_data,
			v_sha1,
			v_uploaded_dtm,
			v_archive_file_id,
			v_archive_file_size
		;
		EXIT WHEN v_issue_log_file_cur%NOTFOUND;
		v_count := v_count + 1;

		unit_test_pkg.AssertIsNotNull(UTL_RAW.CAST_TO_VARCHAR2(v_data), 'Expected data');
		unit_test_pkg.AssertIsNotNull(UTL_RAW.CAST_TO_VARCHAR2(v_sha1), 'Expected data');
		unit_test_pkg.AssertIsNotNull(v_archive_file_id, 'Expected data');
		unit_test_pkg.AssertIsNotNull(v_archive_file_size, 'Expected data');
	END LOOP;

	--If no exception test is successful
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 results');


	-- filter out no files, but filter data out.
	schema_pkg.GetIssueLogsFiltered(
		in_issue_log_file_filter => 1,
		in_issue_log_file_data => 0,
		out_issue_action_log_cur => v_issue_action_log_cur,
		out_issue_log_cur => v_issue_log_cur,
		out_issue_log_file_cur => v_issue_log_file_cur,
		out_issue_log_read_cur => v_issue_log_read_cur
	);

	v_count := 0;
	LOOP
		FETCH v_issue_log_file_cur INTO 
			v_issue_log_file_id,
			v_issue_log_id,
			v_filename,
			v_mime_type,
			v_data,
			v_sha1,
			v_uploaded_dtm,
			v_archive_file_id,
			v_archive_file_size
		;
		EXIT WHEN v_issue_log_file_cur%NOTFOUND;
		v_count := v_count + 1;

		unit_test_pkg.AssertIsNull(UTL_RAW.CAST_TO_VARCHAR2(v_data), 'Expected empty blob');
		unit_test_pkg.AssertIsNull(UTL_RAW.CAST_TO_VARCHAR2(v_sha1), 'Expected no data');
		unit_test_pkg.AssertIsNotNull(v_archive_file_id, 'Expected data');
		unit_test_pkg.AssertIsNotNull(v_archive_file_size, 'Expected data');
	END LOOP;

	--If no exception test is successful
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 results');



	DELETE FROM issue_log_file;
	DELETE FROM issue_log;
END;

END;
/
