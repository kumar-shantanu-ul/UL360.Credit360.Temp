CREATE OR REPLACE PACKAGE BODY csr.test_landing_page_pkg AS

v_site_name		VARCHAR2(200);
v_user_sid	security.security_pkg.T_SID_ID;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);

	SELECT MIN(csr_user_sid)
	  INTO v_user_sid
	  FROM csr_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND full_name = 'Administrator';

	TearDownFixture;
END;


PROCEDURE TestGetDefaultHomePage AS
	v_out_cur		SYS_REFCURSOR;

	v_default_url	VARCHAR2(255);
	v_app_url		VARCHAR2(255);

	v_count			NUMBER;

	v_sid_1			NUMBER;

	v_original_default_url VARCHAR2(255);
BEGIN
	SELECT default_url
	  INTO v_original_default_url
	  FROM aspen2.application
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT sid_id
	  INTO v_sid_1
	  FROM SECURITY.SECURABLE_OBJECT
	 WHERE application_sid_id = SYS_CONTEXT('SECURITY', 'APP')
	   AND class_id = (
			SELECT class_id
			  FROM security.securable_object_class
			 WHERE class_name = 'Group'
			)
		AND name = 'Everyone';

	landing_page_pkg.GetDefaultHomePage(
		out_cur => v_out_cur
	);
	LOOP
		FETCH v_out_cur INTO v_default_url, v_app_url;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count +1;
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'There can be only one.');
	unit_test_pkg.AssertIsTrue(v_default_url = '', 'Unexpected default url '||v_default_url);
	unit_test_pkg.AssertIsTrue(v_app_url = v_original_default_url, 'Unexpected app url '||v_app_url);

	UPDATE aspen2.application
	   SET default_url = '/GetDefaultHomePage/app1'
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	landing_page_pkg.GetDefaultHomePage(
		out_cur => v_out_cur
	);
	LOOP
		FETCH v_out_cur INTO v_default_url, v_app_url;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count +1;
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'There can be only one.');
	unit_test_pkg.AssertIsTrue(v_default_url = '', 'Unexpected default url '||v_default_url);
	unit_test_pkg.AssertIsTrue(v_app_url = '/GetDefaultHomePage/app1', 'Unexpected app url '||v_app_url);


	landing_page_pkg.UpsertLandingPage(
		in_sid_id => v_sid_1,
		in_path => '/GetDefaultHomePage/home1',
		in_priority => 1
	);

	landing_page_pkg.GetDefaultHomePage(
		out_cur => v_out_cur
	);
	LOOP
		FETCH v_out_cur INTO v_default_url, v_app_url;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count +1;
	END LOOP;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'There can be only one.');
	unit_test_pkg.AssertIsTrue(v_default_url = '/GetDefaultHomePage/home1', 'Unexpected default url '||v_default_url);
	unit_test_pkg.AssertIsTrue(v_app_url = '/GetDefaultHomePage/app1', 'Unexpected app url '||v_app_url);

	-- tidy up
	landing_page_pkg.DeleteLandingPage(
		in_sid_id => v_sid_1
	);

	UPDATE aspen2.application
	   SET default_url = v_original_default_url
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;


PROCEDURE TestGetLandingPages AS
	v_ref					VARCHAR2(255) := 'TestLandingPage_GetLandingPages';
	v_count					NUMBER := 0;
	v_out_cur				SYS_REFCURSOR;
	v_index_1				NUMBER;
	v_index_2				NUMBER;

	v_sid					security.security_pkg.T_SID_ID;
	v_path					VARCHAR2(900);
	v_name					VARCHAR2(255);
	v_priority				NUMBER;

	v_sid_1					NUMBER;
	v_sid_2					NUMBER;
BEGIN
	-- add two homepages...
	SELECT sid_id
	  INTO v_sid_1
	  FROM SECURITY.SECURABLE_OBJECT
	 WHERE application_sid_id = SYS_CONTEXT('SECURITY', 'APP')
	   AND class_id = (
			SELECT class_id
			  FROM security.securable_object_class
			 WHERE class_name = 'Group'
			)
		AND name = 'Everyone';

	SELECT sid_id
	  INTO v_sid_2
	  FROM SECURITY.SECURABLE_OBJECT
	 WHERE application_sid_id = SYS_CONTEXT('SECURITY', 'APP')
	   AND class_id = (
			SELECT class_id
			  FROM security.securable_object_class
			 WHERE class_name = 'CSRUserGroup'
			)
		AND name = 'RegisteredUsers';

	landing_page_pkg.UpsertLandingPage(
		in_sid_id => v_sid_1,
		in_path => v_ref || '/home1',
		in_priority => 1
	);

	landing_page_pkg.UpsertLandingPage(
		in_sid_id => v_sid_2,
		in_path => v_ref || '/home2',
		in_priority => 2
	);

	landing_page_pkg.GetLandingPages(
		out_cur 		 => v_out_cur
	);

	LOOP
		FETCH v_out_cur INTO v_sid, v_path, v_name, v_priority;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count +1;

		IF v_sid = v_sid_1 THEN
			v_index_1 := v_count;
		END IF;
		IF v_sid = v_sid_2 THEN
			v_index_2 := v_count;
		END IF;
	END LOOP;

	unit_test_pkg.AssertIsTrue(v_index_2 > v_index_1, 'Sort order should be correct.');
	unit_test_pkg.AssertIsTrue(v_count > 1, 'Number of returned records should be more than one');
END;


PROCEDURE TestInsertLandingPage AS
	v_ref					VARCHAR2(255) := 'TestLandingPage_InsertLandingPage';
	v_sid_1					NUMBER;

	v_pre_count				NUMBER;
	v_post_count			NUMBER;
	v_act_id				security.security_pkg.T_ACT_ID;

	v_host					security.home_page.created_by_host%TYPE;
	v_url					security.home_page.url%TYPE;
	v_priority				security.home_page.priority%TYPE;
BEGIN
	SELECT sid_id
	  INTO v_sid_1
	  FROM SECURITY.SECURABLE_OBJECT
	 WHERE application_sid_id = SYS_CONTEXT('SECURITY', 'APP')
	   AND class_id = (
			SELECT class_id
			  FROM security.securable_object_class
			 WHERE class_name = 'Group'
			)
		AND name = 'Everyone';

	landing_page_pkg.DeleteLandingPage(
		in_sid_id => v_sid_1
	);

	-- logon as non-SA, insert should fail
	security.user_pkg.LogonAuthenticated(v_user_sid, 172800, v_act_id);
	BEGIN
		landing_page_pkg.InsertLandingPage(
			in_sid_id => v_sid_1,
			in_path => v_ref,
			in_priority => 1
		);
		unit_test_pkg.TestFail('Unexpected success');
	EXCEPTION
		WHEN OTHERS THEN
			unit_test_pkg.AssertAreEqual(SQLCODE, security.security_pkg.ERR_ACCESS_DENIED, 'Exception should have been Access Denied!');
	END;
	
	-- Logon as SA, Delete existing record, audit should be present
	security.user_pkg.logonadmin(v_site_name);
	SELECT COUNT(*)
	  INTO v_pre_count
	  FROM audit_log
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND audit_type_id = csr_data_pkg.AUDIT_TYPE_LANDING_PAGE
	   AND param_1 = v_ref;


	landing_page_pkg.InsertLandingPage(
		in_sid_id => v_sid_1,
		in_path => v_ref,
		in_priority => 2
	);

	-- test that the homepage record is present and correct
	SELECT created_by_host, url, priority
	  INTO v_host, v_url, v_priority
	  FROM security.home_page hp
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND sid_id = v_sid_1;

	unit_test_pkg.AssertAreEqual(v_site_name, v_host, 'Unexpected host');
	unit_test_pkg.AssertAreEqual(v_ref, v_url, 'Unexpected url');
	unit_test_pkg.AssertAreEqual(2, v_priority, 'Unexpected priority');

	SELECT COUNT(*)
	  INTO v_post_count
	  FROM audit_log
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND audit_type_id = csr_data_pkg.AUDIT_TYPE_LANDING_PAGE
	   AND param_1 = v_ref;

	unit_test_pkg.AssertIsTrue((v_pre_count + 1) = v_post_count, 'Unexpected audit log count');

	BEGIN
		landing_page_pkg.InsertLandingPage(
			in_sid_id => v_sid_1,
			in_path => v_ref,
			in_priority => 2
		);
		unit_test_pkg.TestFail('Unexpected success');
	EXCEPTION
		WHEN OTHERS THEN
			unit_test_pkg.AssertAreEqual(SQLCODE, security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'Exception should have been Dup Obj!');
	END;
END;


PROCEDURE TestUpsertLandingPage AS
	v_ref					VARCHAR2(255) := 'TestLandingPage_UpsertLandingPage';
	v_sid_1					NUMBER;

	v_pre_count				NUMBER;
	v_post_count			NUMBER;
	v_act_id				security.security_pkg.T_ACT_ID;

	v_host					security.home_page.created_by_host%TYPE;
	v_url					security.home_page.url%TYPE;
	v_priority				security.home_page.priority%TYPE;
BEGIN
	SELECT sid_id
	  INTO v_sid_1
	  FROM SECURITY.SECURABLE_OBJECT
	 WHERE application_sid_id = SYS_CONTEXT('SECURITY', 'APP')
	   AND class_id = (
			SELECT class_id
			  FROM security.securable_object_class
			 WHERE class_name = 'Group'
			)
		AND name = 'Everyone';

	landing_page_pkg.DeleteLandingPage(
		in_sid_id => v_sid_1
	);

	-- logon as non-SA, upsert should fail
	security.user_pkg.LogonAuthenticated(v_user_sid, 172800, v_act_id);
	BEGIN
		landing_page_pkg.UpsertLandingPage(
			in_sid_id => v_sid_1,
			in_path => v_ref,
			in_priority => 1
		);
		unit_test_pkg.TestFail('Unexpected success');
	EXCEPTION
		WHEN OTHERS THEN
			unit_test_pkg.AssertAreEqual(SQLCODE, security.security_pkg.ERR_ACCESS_DENIED, 'Exception should have been Access Denied!');
	END;
	
	-- Logon as SA, Delete existing record, audit should be present
	security.user_pkg.logonadmin(v_site_name);
	SELECT COUNT(*)
	  INTO v_pre_count
	  FROM audit_log
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND audit_type_id = csr_data_pkg.AUDIT_TYPE_LANDING_PAGE
	   AND param_1 = v_ref;

	-- insert
	landing_page_pkg.UpsertLandingPage(
		in_sid_id => v_sid_1,
		in_path => v_ref,
		in_priority => 2
	);

	-- update
	landing_page_pkg.UpsertLandingPage(
		in_sid_id => v_sid_1,
		in_path => v_ref,
		in_priority => 2
	);

	-- test that the homepage record is present and correct
	SELECT created_by_host, url, priority
	  INTO v_host, v_url, v_priority
	  FROM security.home_page hp
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND sid_id = v_sid_1;

	unit_test_pkg.AssertAreEqual(v_site_name, v_host, 'Unexpected host');
	unit_test_pkg.AssertAreEqual(v_ref, v_url, 'Unexpected url');
	unit_test_pkg.AssertAreEqual(2, v_priority, 'Unexpected priority');

	SELECT COUNT(*)
	  INTO v_post_count
	  FROM audit_log
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND audit_type_id = csr_data_pkg.AUDIT_TYPE_LANDING_PAGE
	   AND param_1 = v_ref;

	unit_test_pkg.AssertIsTrue((v_pre_count + 2) = v_post_count, 'Unexpected audit log count');
END;

PROCEDURE TestUpsertLandingPageFromDifferentHost AS
	v_ref					VARCHAR2(255) := 'TestLandingPage_UpsertLandingPageFromDifferentHost';
	v_sid_1					NUMBER;

	v_pre_count				NUMBER;
	v_post_count			NUMBER;
	v_act_id				security.security_pkg.T_ACT_ID;

	v_host					security.home_page.created_by_host%TYPE;
	v_url					security.home_page.url%TYPE;
	v_priority				security.home_page.priority%TYPE;
BEGIN
	SELECT sid_id
	  INTO v_sid_1
	  FROM SECURITY.SECURABLE_OBJECT
	 WHERE application_sid_id = SYS_CONTEXT('SECURITY', 'APP')
	   AND class_id = (
			SELECT class_id
			  FROM security.securable_object_class
			 WHERE class_name = 'Group'
			)
		AND name = 'Everyone';

	landing_page_pkg.DeleteLandingPage(
		in_sid_id => v_sid_1
	);
	
	-- artificially rename site
	UPDATE customer
	   SET host = REPLACE(host, '.com', '.fake')
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
		
	-- insert
	landing_page_pkg.UpsertLandingPage(
		in_sid_id => v_sid_1,
		in_path => v_ref || '/home1',
		in_priority => 1
	);
	
	UPDATE customer
	   SET host = REPLACE(host, '.fake', '.com')
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	
	-- update
	landing_page_pkg.UpsertLandingPage(
		in_sid_id => v_sid_1,
		in_path => v_ref || '/home2',
		in_priority => 2
	);
	
	-- test that the homepage record is present and correct
	SELECT created_by_host, url, priority
	  INTO v_host, v_url, v_priority
	  FROM security.home_page hp
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND sid_id = v_sid_1;

	unit_test_pkg.AssertAreEqual(v_site_name, v_host, 'Unexpected host');
	unit_test_pkg.AssertAreEqual(v_ref || '/home2', v_url, 'Unexpected url');
	unit_test_pkg.AssertAreEqual(2, v_priority, 'Unexpected priority');
END;


PROCEDURE TestDeleteLandingPage AS
	v_ref					VARCHAR2(255) := 'TestLandingPage_DeleteLandingPage';
	v_sid_1					NUMBER;

	v_pre_count				NUMBER;
	v_post_count			NUMBER;
	v_act_id				security.security_pkg.T_ACT_ID;
BEGIN
	-- insert a test record
	SELECT sid_id
	  INTO v_sid_1
	  FROM SECURITY.SECURABLE_OBJECT
	 WHERE application_sid_id = SYS_CONTEXT('SECURITY', 'APP')
	   AND class_id = (
			SELECT class_id
			  FROM security.securable_object_class
			 WHERE class_name = 'Group'
			)
		AND name = 'Everyone';

	landing_page_pkg.UpsertLandingPage(
		in_sid_id => v_sid_1,
		in_path => v_ref,
		in_priority => 1
	);


	-- logon as non-SA, delete should fail
	security.user_pkg.LogonAuthenticated(v_user_sid, 172800, v_act_id);
	BEGIN
		landing_page_pkg.DeleteLandingPage(
			in_sid_id => v_sid_1
		);
		unit_test_pkg.TestFail('Unexpected success');
	EXCEPTION
		WHEN OTHERS THEN
			unit_test_pkg.AssertAreEqual(security.security_pkg.ERR_ACCESS_DENIED, SQLCODE, 'Exception should have been Access Denied!');
	END;
	

	-- Logon as SA, Delete existing record, audit should be present
	security.user_pkg.logonadmin(v_site_name);
	SELECT COUNT(*)
	  INTO v_pre_count
	  FROM audit_log
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND audit_type_id = csr_data_pkg.AUDIT_TYPE_LANDING_PAGE
	   AND param_1 = v_ref;


	landing_page_pkg.DeleteLandingPage(
		in_sid_id => v_sid_1
	);

	SELECT COUNT(*)
	  INTO v_post_count
	  FROM audit_log
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND audit_type_id = csr_data_pkg.AUDIT_TYPE_LANDING_PAGE
	   AND param_1 = v_ref;

	unit_test_pkg.AssertIsTrue((v_pre_count + 1) = v_post_count, 'Unexpected audit log count');

	SELECT COUNT(*)
	  INTO v_post_count
	  FROM security.home_page
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND sid_id = v_sid_1;

	unit_test_pkg.AssertIsTrue(v_post_count = 0, 'Unexpected home page count');

END;


PROCEDURE TearDownFixture 
AS
BEGIN
	FOR r in (
		SELECT sid_id FROM security.home_page
		 WHERE url like 'TestLandingPage_%'
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	)
	LOOP
		security.web_pkg.DeleteHomePage(
			in_act_id => SYS_CONTEXT('SECURITY', 'ACT'),
			in_app_sid => SYS_CONTEXT('SECURITY', 'APP'),
			in_sid_id => r.sid_id
		);
	END LOOP;
END;

END test_landing_page_pkg;
/
