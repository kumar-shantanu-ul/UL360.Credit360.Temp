CREATE OR REPLACE PACKAGE BODY csr.unit_test_pkg AS

v_test_name				VARCHAR(255) := NULL;

PROC_NOT_FOUND				EXCEPTION;
PRAGMA EXCEPTION_INIT(PROC_NOT_FOUND, -06550);

PROCEDURE TestFail (
	in_message			IN	VARCHAR2
)
AS
BEGIN
	TestFail(NULL, in_message);
END;

PROCEDURE TestFail (
	in_assertion		IN	VARCHAR2,
	in_message			IN	VARCHAR2
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_UNIT_TEST_FAILED, v_test_name||': '||in_assertion||' message: '||in_message);
END;

PROCEDURE StartTest(
	in_test_name		IN	VARCHAR2
)
AS
BEGIN
	v_test_name := in_test_name;
END;

PROCEDURE EndTest
AS
BEGIN
	-- do something for those that pass (those that fail raise an error)
	dbms_output.put_line(v_test_name||': passed...');
	v_test_name := NULL;
END;

PROCEDURE AssertIsNull(
	in_actual			IN	VARCHAR2,
	in_message			IN	VARCHAR2
)
AS
BEGIN
	IF in_actual IS NOT NULL THEN
		TestFail('AssertIsNull: ' || in_message || ' not null');
	END IF;
END;

PROCEDURE AssertIsNull(
	in_actual			IN	NUMBER,
	in_message			IN	VARCHAR2
)
AS
BEGIN
	IF in_actual IS NOT NULL THEN
		TestFail('AssertIsNull: ' || in_message || ' not null');
	END IF;
END;

PROCEDURE AssertIsNotNull(
	in_actual			IN	VARCHAR2,
	in_message			IN	VARCHAR2
)
AS
BEGIN
	IF in_actual IS NULL THEN
		TestFail('AssertIsNotNull: ' || in_message || ' is null');
	END IF;
END;

PROCEDURE AssertIsNotNull(
	in_actual			IN	NUMBER,
	in_message			IN	VARCHAR2
)
AS
BEGIN
	IF in_actual IS NULL THEN
		TestFail('AssertIsNotNull: ' || in_message || ' is null');
	END IF;
END;

PROCEDURE AssertIsTrue(
	in_actual			IN	BOOLEAN,
	in_message			IN	VARCHAR2
)
AS
BEGIN
	IF NOT in_actual THEN
		TestFail('AssertIsTrue: Got: False', in_message);
	END IF;
END;

PROCEDURE AssertIsFalse(
	in_actual			IN	BOOLEAN,
	in_message			IN	VARCHAR2
)
AS
BEGIN
	IF in_actual THEN
		TestFail('AssertIsFalse: Got: True', in_message);
	END IF;
END;

PROCEDURE AssertAreEqual(
	in_expected			IN	VARCHAR2,
	in_actual			IN	VARCHAR2,
	in_message			IN	VARCHAR2
)
AS
BEGIN
	IF null_pkg.ne(in_expected, in_actual) THEN
		TestFail('AssertAreEqual: Expected: '||in_expected||', Got: '||in_actual, in_message);
	END IF;
END;

PROCEDURE AssertAreEqual(
	in_expected			IN	NUMBER,
	in_actual			IN	NUMBER,
	in_message			IN	VARCHAR2
)
AS
BEGIN
	IF null_pkg.ne(in_expected, in_actual) THEN
		TestFail('AssertAreEqual: Expected: '||in_expected||', Got: '||in_actual, in_message);
	END IF;
END;

PROCEDURE AssertAreEqual(
	in_expected			IN	DATE,
	in_actual			IN	DATE,
	in_message			IN	VARCHAR2
)
AS
BEGIN
	IF null_pkg.ne(in_expected, in_actual) THEN
		TestFail('AssertAreEqual: Expected: '||in_expected||', Got: '||in_actual, in_message);
	END IF;
END;

PROCEDURE AssertAreEqual(
	in_expected			IN	CLOB,
	in_actual			IN	CLOB,
	in_message			IN	VARCHAR2
)
AS
BEGIN
	IF null_pkg.ne(in_expected, in_actual) THEN
		TestFail('AssertAreEqual: Expected: '||in_expected||', Got: '||in_actual, in_message);
	END IF;
END;

PROCEDURE AssertNotEqual(
	in_expected			IN	VARCHAR2,
	in_actual			IN	VARCHAR2,
	in_message			IN	VARCHAR2
)
AS
BEGIN
	IF null_pkg.eq(in_expected, in_actual) THEN
		TestFail('AssertNotEqual: Expected: '||in_expected||', to not equal: '||in_actual, in_message);
	END IF;
END;

PROCEDURE AssertNotEqual(
	in_expected			IN	NUMBER,
	in_actual			IN	NUMBER,
	in_message			IN	VARCHAR2
)
AS
BEGIN
	IF null_pkg.eq(in_expected, in_actual) THEN
		TestFail('AssertNotEqual: Expected: '||in_expected||', to not equal: '||in_actual, in_message);
	END IF;
END;

PROCEDURE AssertNotEqual(
	in_expected			IN	DATE,
	in_actual			IN	DATE,
	in_message			IN	VARCHAR2
)
AS
BEGIN
	IF null_pkg.eq(in_expected, in_actual) THEN
		TestFail('AssertNotEqual: Expected: '||in_expected||', to not equal: '||in_actual, in_message);
	END IF;
END;

PROCEDURE AssertNotEqual(
	in_expected			IN	CLOB,
	in_actual			IN	CLOB,
	in_message			IN	VARCHAR2
)
AS
BEGIN
	IF null_pkg.eq(in_expected, in_actual) THEN
		TestFail('AssertNotEqual: Expected: '||in_expected||', to not equal: '||in_actual, in_message);
	END IF;
END;

/** 
 * Runs unit tests against all procedures in a test fixture. Any procedures
 * ending in an underscore are ignored.
 * @param in_pkg			Package name of test fixture.
 */
PROCEDURE RunTests(
	in_pkg				IN VARCHAR2,
	in_site_name		IN VARCHAR2 DEFAULT 'rag.credit360.com'
)
AS
	v_tests				T_TESTS;
	v_owner				VARCHAR2(30);
	v_package_name		VARCHAR2(255);
BEGIN
	BEGIN
		SELECT owner, object_name
		  INTO v_owner, v_package_name
		  FROM all_objects
		 WHERE object_type='PACKAGE'
		   AND ((in_pkg NOT LIKE '%.%' AND owner = 'CSR') OR owner = UPPER(SUBSTR(in_pkg, 0, INSTR(in_pkg, '.')-1)))
		   AND ((in_pkg NOT LIKE '%.%' AND object_name = UPPER(in_pkg)) OR object_name = UPPER(SUBSTR(in_pkg, INSTR(in_pkg, '.')+1)));
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Package: '||in_pkg||' not found');
	END;
	
	-- Automatically find all procedures that aren't startup or teardown.
	-- Internal / non-test procs should be underscore suffixed to avoid being ran
	SELECT procedure_name
	  BULK COLLECT INTO v_tests
	  FROM all_procedures
	 WHERE procedure_name NOT LIKE '%\_' ESCAPE '\' --'
	   AND procedure_name NOT IN ('SETUP', 'TEARDOWN', 'SETUPFIXTURE', 'TEARDOWNFIXTURE')
	   AND owner = v_owner
	   AND object_name = v_package_name
	 ORDER BY procedure_name;
	
	RunTests(in_pkg, v_tests, in_site_name);
END;

/** 
 * Runs unit tests against specified procedures within a test fixture.
 * This will run [in_pkg].SetUpFixture / TearDownFixture (if they exist) once each.
 * This will run [in_pkg].SetUp / TearDown (if they exist) once per test.
 * Tests will stop on the first error (either assertion failure or raised application error).
 * @param in_pkg			Package name of test fixture.
 * @param in_tests			An array of tests (procedures with no arguments) to run in the fixture.
 */
PROCEDURE RunTests(
	in_pkg				IN VARCHAR2,
	in_tests			IN T_TESTS,
	in_site_name		IN VARCHAR2 DEFAULT 'rag.credit360.com'
)
AS
	v_test_proc		VARCHAR2(255);
BEGIN
	
	dbms_output.enable(null);
	
	-- Run fixture's startup (if it exists)
	dbms_output.put_line('in_site_name='||in_site_name);
	BEGIN
		EXECUTE IMMEDIATE ('BEGIN '||in_pkg||'.SetUpFixture(in_site_name => '''||in_site_name||'''); END;');
	EXCEPTION
		WHEN PROC_NOT_FOUND THEN
			-- if is not supported, try the parameterless form
			BEGIN
				EXECUTE IMMEDIATE ('BEGIN '||in_pkg||'.SetUpFixture; END;');
			EXCEPTION
				WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
			END;
	END;
	
	-- Run each test
	FOR i IN 1 .. in_tests.count
	LOOP
		-- Run test startup (if one exits)
		BEGIN
			EXECUTE IMMEDIATE ('BEGIN '||in_pkg||'.SetUp; END;');
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
		
		v_test_proc := in_pkg||'.'||in_tests(i);
		
		StartTest(v_test_proc);
		
		-- TODO: Could store success / fail per test in a temp table (preserve rows)
		-- rather than bomb out on first failure
		EXECUTE IMMEDIATE ('BEGIN '||v_test_proc||'; END;');
		
		-- Run test teardown (if one exits)
		BEGIN
			EXECUTE IMMEDIATE ('BEGIN '||in_pkg||'.TearDown; END;');
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
		
		EndTest;
		
	END LOOP;
	
	-- Run fixture's teardown (if it exists)
	BEGIN
		EXECUTE IMMEDIATE ('BEGIN '||in_pkg||'.TearDownFixture; END;');
	EXCEPTION
		WHEN PROC_NOT_FOUND THEN
			NULL; -- it is acceptable that it is not supported
	END;
END;





/*******************************************************************************************************************/
/* Helper procs to get some basedata for tests (otherwise tests get v long) - could be moved to a separate package */
/*******************************************************************************************************************/





FUNCTION GetOrCreateMeasure (
	in_name							IN	VARCHAR2,	
	in_std_measure_conversion_id	IN	measure.std_measure_conversion_id%TYPE DEFAULT NULL,
	in_custom_field					IN	measure.custom_field%TYPE DEFAULT NULL
) RETURN security_pkg.T_SID_ID
AS
	v_measure_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT MIN(measure_sid)
	  INTO v_measure_sid
	  FROM measure
	 WHERE name = in_name
	   AND app_sid = security_pkg.GetApp;
	
	IF v_measure_sid IS NOT NULL THEN
		RETURN v_measure_sid;
	END IF;
	
	measure_pkg.CreateMeasure(
		in_name => in_name,
		in_description => in_name,
		in_std_measure_conversion_id => in_std_measure_conversion_id,
		in_custom_field => in_custom_field,
		out_measure_sid => v_measure_sid
	);
	
	return v_measure_sid;
END;

FUNCTION AddMeasureConversion (
	in_measure_sid					IN	measure.measure_sid%TYPE,	
	in_description					IN	measure_conversion.description%TYPE,
	in_std_measure_conversion_id	IN	std_measure_conversion.std_measure_conversion_id%TYPE

) RETURN measure.std_measure_conversion_id%TYPE
AS
	v_cnv_id					measure.std_measure_conversion_id%TYPE;
BEGIN
	measure_pkg.SetConversion(
		in_act_id				=> security.security_pkg.GetAct,
		in_conversion_id		=> NULL,
		in_measure_sid			=> in_measure_sid,
		in_description			=> in_description,
		in_std_measure_conversion_id =>	in_std_measure_conversion_id,
		out_conversion_id		=> v_cnv_id
	);
	RETURN v_cnv_id;
END;

FUNCTION GetOrCreateInd (
	in_lookup_key		IN	VARCHAR2,
	in_measure_name		IN	VARCHAR2 DEFAULT 'MEASURE_1',
	in_parent_sid		IN	security_pkg.T_SID_ID DEFAULT NULL
) RETURN security_pkg.T_SID_ID
AS
	v_measure_sid			security_pkg.T_SID_ID := GetOrCreateMeasure(in_measure_name);
	v_ind_sid				security_pkg.T_SID_ID;
	v_ind_root_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT MIN(ind_sid)
	  INTO v_ind_sid
	  FROM ind
	 WHERE lookup_key = in_lookup_key
	   AND app_sid = security_pkg.GetApp;
	
	IF v_ind_sid IS NOT NULL THEN
		RETURN v_ind_sid;
	END IF;
	
	IF in_parent_sid IS NULL THEN
		SELECT ind_root_sid
		  INTO v_ind_root_sid
		  FROM customer;
	ELSE
		v_ind_root_sid := in_parent_sid;
	END IF;

	indicator_pkg.CreateIndicator(
		in_parent_sid_id => v_ind_root_sid,
		in_name => in_lookup_key,
		in_description => in_lookup_key,
		in_lookup_key => in_lookup_key,
		in_measure_sid => v_measure_sid,
		in_aggregate => 'SUM',
		out_sid_id => v_ind_sid
	);
	
	return v_ind_sid;
END;

FUNCTION SetIndicatorValue(
	in_ind_sid					IN security.security_pkg.T_SID_ID,
	in_region_sid				IN security.security_pkg.T_SID_ID,
	in_period_start				IN val.period_start_dtm%TYPE,
	in_period_end				IN val.period_end_dtm%TYPE,
	in_val_number				IN val.val_number%TYPE
) RETURN val.val_id%TYPE
AS
	v_val_id					val.val_id%TYPE;
BEGIN
	indicator_pkg.SetValue(
		in_act_id				=> security.security_pkg.GetAct,
		in_ind_sid				=> in_ind_sid,
		in_region_sid			=> in_region_sid,
		in_period_start			=> in_period_start,
		in_period_end			=> in_period_end,
		in_val_number			=> in_val_number,
		in_flags				=> 0,
		in_note					=> 'Test data setup',
		out_val_id				=> v_val_id
	);
	RETURN v_val_id;
END;

FUNCTION SetIndicatorText(
	in_ind_sid					IN security.security_pkg.T_SID_ID,
	in_region_sid				IN security.security_pkg.T_SID_ID,
	in_period_start				IN val.period_start_dtm%TYPE,
	in_period_end				IN val.period_end_dtm%TYPE,
	in_text						IN val.note%TYPE
) RETURN val.val_id%TYPE
AS
	v_val_id					val.val_id%TYPE;
BEGIN
	indicator_pkg.SetValue(
		in_act_id				=> security.security_pkg.GetAct,
		in_ind_sid				=> in_ind_sid,
		in_region_sid			=> in_region_sid,
		in_period_start			=> in_period_start,
		in_period_end			=> in_period_end,
		in_val_number			=> NULL,
		in_flags				=> 0,
		in_note					=> in_text,
		out_val_id				=> v_val_id
	);
	RETURN v_val_id;
END;

FUNCTION GetOrCreateRole (
	in_lookup_key		IN	VARCHAR2
) RETURN security_pkg.T_SID_ID
AS
	v_role_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT MIN(role_sid)
	  INTO v_role_sid
	  FROM role
	 WHERE lookup_key = in_lookup_key
	   AND app_sid = security_pkg.GetApp;
	
	IF v_role_sid IS NOT NULL THEN
		RETURN v_role_sid;
	END IF;
	
	role_pkg.SetRole(
		in_role_name 	=> in_lookup_key,
		in_lookup_key 	=> in_lookup_key,
		out_role_sid 	=> v_role_sid
	);
	
	return v_role_sid;
END;

FUNCTION GetOrCreateRegion (
	in_lookup_key			IN	VARCHAR2,
	in_parent_region_sid	IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_region_type			IN	region.region_type%TYPE	DEFAULT csr_data_pkg.REGION_TYPE_NORMAL
) RETURN security_pkg.T_SID_ID
AS
	v_region_root_sid		security_pkg.T_SID_ID;
	v_region_sid			security_pkg.T_SID_ID;
BEGIN
	
	SELECT MIN(region_sid)
	  INTO v_region_sid
	  FROM region
	 WHERE lookup_key = in_lookup_key
	   AND app_sid = security_pkg.GetApp;
	
	IF v_region_sid IS NOT NULL THEN
		RETURN v_region_sid;
	END IF;
	
	SELECT NVL(in_parent_region_sid, region_tree_root_sid)
	  INTO v_region_root_sid
	  FROM region_tree
	 WHERE is_primary=1;

	region_pkg.CreateRegion(
		in_parent_sid 	=> v_region_root_sid,
		in_name 		=> in_lookup_key,
		in_description 	=> in_lookup_key,
		in_region_ref	=> in_lookup_key,
		in_region_type	=> in_region_type, 
		out_region_sid	=> v_region_sid
	);
	
	UPDATE region SET lookup_Key = in_lookup_key WHERE region_sid = v_region_sid;
	
	return v_region_sid;
	
END;

FUNCTION GetOrCreateUser (
	in_name				IN	VARCHAR2,
	in_group_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_password			IN  VARCHAR2 DEFAULT NULL
) RETURN security_pkg.T_SID_ID
AS
	v_user_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT MIN(csr_user_sid)
	  INTO v_user_sid
	  FROM csr_user
	 WHERE user_name = LOWER(in_name)
	   AND app_sid = security_pkg.GetApp;
	
	IF v_user_sid IS NOT NULL THEN
		RETURN v_user_sid;
	END IF;
	
	csr_user_pkg.CreateUser(
		in_act => security_pkg.GetAct,
		in_app_sid => security_pkg.GetApp,
		in_user_name => in_name,
		in_password => in_password,
		in_full_name => in_name,
		in_friendly_name => in_name,
		in_email => in_name||'@credit360.com',
		in_job_title => 'Test user',
		in_phone_number => NULL,
		in_info_xml => NULL,
		in_send_alerts => 1,
		out_user_sid => v_user_sid
	);

	IF in_group_sid IS NOT NULL THEN
		csr_user_pkg.AddUserToGroupLogged(v_user_sid, in_group_sid, in_group_sid);
	END IF;
	
	RETURN v_user_sid;
END;

FUNCTION GetOrCreateUserAndProfile (
	in_primary_key					IN csr.user_profile.primary_key%TYPE,
	in_first_name					IN csr.user_profile.first_name%TYPE,
	in_last_name					IN csr.user_profile.last_name%TYPE,
	in_email_address				IN csr.user_profile.email_address%TYPE,
	in_work_phone_number			IN csr.user_profile.work_phone_number%TYPE,
	in_date_of_birth				IN csr.user_profile.date_of_birth%TYPE,
	in_gender						IN csr.user_profile.gender%TYPE,
	in_job_title					IN csr.user_profile.job_title%TYPE,
	in_employment_type				IN csr.user_profile.employment_type%TYPE,
	in_manager_primary_key			IN csr.user_profile.manager_primary_key%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_user_sid				security.security_pkg.T_SID_ID;
	v_user_profile_row		csr.T_USER_PROFILE_STAGED_ROW;
BEGIN
	SELECT csr_user_sid
	  INTO v_user_sid
	  FROM csr.user_profile
	 WHERE UPPER(primary_key) = UPPER(in_primary_key);

	RETURN v_user_sid;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		SELECT csr.T_USER_PROFILE_STAGED_ROW(
				in_primary_key, NULL, NULL, in_first_name, in_last_name,
				NULL, NULL, in_email_address, in_primary_key, in_work_phone_number,
				NULL, NULL, NULL, NULL, NULL,
				in_manager_primary_key, NULL, NULL, NULL, in_date_of_birth,
				in_gender, in_job_title, NULL, in_employment_type, NULL,
				NULL, NULL, NULL, NULL, NULL,
				NULL, NULL, NULL, NULL, NULL,
				NULL, NULL, NULL, NULL, NULL,
				NULL, NULL, NULL, NULL, NULL,
				NULL, NULL, NULL, NULL, NULL,
				NULL, NULL, NULL, NULL, NULL,
				NULL, SYSDATE, SYS_CONTEXT('SECURITY', 'SID'), 'Manual', NULL
				)
		INTO v_user_profile_row
		FROM DUAL;

		csr.user_profile_pkg.CreateUserAndProfile(
			in_row							=> v_user_profile_row,
			in_use_loc_region_as_start_pt	=> 0,
			out_csr_user_sid				=> v_user_sid
		);

		RETURN v_user_sid;
END;

FUNCTION GetUserGuidFromSid (
	in_user_sid			IN	csr.csr_user.csr_user_sid%TYPE
) RETURN csr.csr_user.guid%TYPE
AS
	v_guid	csr.csr_user.guid%TYPE;
BEGIN
	SELECT guid INTO v_guid FROM csr.csr_user WHERE csr_user_sid = in_user_sid;

	return v_guid;
END;

FUNCTION GetOrCreateDeleg (
	in_name				IN	VARCHAR2,
	in_regions			IN	security_pkg.T_SID_IDS,
	in_inds				IN	security_pkg.T_SID_IDS
) RETURN security_pkg.T_SID_ID
AS
	v_deleg_sid			security_pkg.T_SID_ID;
	v_i					NUMBER;
	v_inds				security.T_SID_TABLE := security_pkg.SidArrayToTable(in_inds);
	v_regions			security.T_SID_TABLE := security_pkg.SidArrayToTable(in_regions);
BEGIN
	SELECT MIN(delegation_sid)
	  INTO v_deleg_sid
	  FROM delegation
	 WHERE parent_sid = security_pkg.GetApp
	   AND name = in_name;
	
	IF v_deleg_sid IS NOT NULL THEN
		RETURN v_deleg_sid;
	END IF;
	
	delegation_pkg.CreateTopLevelDelegation(
		in_act_id				=> security_pkg.GetAct,
		in_name					=> in_name,
		in_date_from			=> date '2010-01-01',
		in_date_to				=> date '2011-01-01',
		in_period_set_id		=> 1,
		in_period_interval_id	=> 1,
		in_allocate_users_to	=> 'region',
		in_app_sid 				=> security_pkg.getApp,
		in_note 				=> 'Test delegation',
		in_group_by 			=> 'region,indicator',
		in_schedule_xml 		=> '<recurrences><yearly every-n="1"><day number="1" month="jan"/></yearly></recurrences>',
		in_reminder_offset 		=> 5,
		in_submission_offset	=> 0,
		in_note_mandatory 		=> 0,
		in_flag_mandatory 		=> 0,
		in_policy 				=> NULL,
		out_delegation_sid 		=> v_deleg_sid
	);
	
	v_i := 1;
	FOR r IN (
		SELECT i.ind_sid, i.description
		  FROM v$ind i
		  JOIN TABLE(v_inds) t ON i.ind_sid = t.column_value
	) LOOP
		delegation_pkg.AddIndicatorToTLD(
			in_act_id => security_pkg.getact,
			in_delegation_sid => v_deleg_sid,
			in_sid_id => r.ind_sid,
			in_description =>r.description,
			in_pos => v_i
		);
		v_i := v_i + 1;
	END LOOP;
	
	v_i := 1;
	FOR r IN (
		SELECT r.region_sid, r.description
		  FROM v$region r
		  JOIN TABLE(v_regions) t ON r.region_sid = t.column_value
	) LOOP
		delegation_pkg.AddRegionToTLD(
			in_act_id => security_pkg.getact,
			in_delegation_sid => v_deleg_sid,
			in_sid_id => r.region_sid,
			in_description =>r.description,
			in_pos => v_i
		);
		v_i := v_i + 1;
	END LOOP;
	
	RETURN v_deleg_sid;
	
END;

FUNCTION GetOrCreateAudit (
	in_name				IN	VARCHAR2,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_user_sid			IN	security_pkg.T_SID_ID,	
	in_survey_sid 		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_audit_dtm		IN	DATE DEFAULT DATE '2010-01-01'
) RETURN security_pkg.T_SID_ID
AS
	v_audit_sid			security_pkg.T_SID_ID;
	v_audit_type_id		NUMBER(10);
BEGIN
	SELECT MIN(internal_audit_sid)
	  INTO v_audit_sid
	  FROM internal_audit
	 WHERE app_sid = security_pkg.GetApp
	   AND label = in_name;
	
	IF v_audit_sid IS NOT NULL THEN
		RETURN v_audit_sid;
	END IF;
	
	BEGIN
		SELECT internal_audit_type_id
		  INTO v_audit_type_id
		  FROM internal_audit_type
		 WHERE label='AUDIT_TYPE';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO internal_audit_type (internal_audit_type_id, label, internal_audit_type_source_id)
			VALUES (internal_audit_type_id_seq.nextval, 'AUDIT_TYPE', 1)
			RETURNING internal_audit_type_id INTO v_audit_type_id;
	END;
	
	SELECT MIN(internal_audit_type_id)
	  INTO v_audit_type_id
	  FROM internal_audit_type;
	
	audit_pkg.Save(
		in_sid_id => NULL,
		in_audit_ref => NULL,
		in_survey_sid => in_survey_sid,
		in_region_sid => in_region_sid,
		in_label => in_name,
		in_audit_dtm => in_audit_dtm,
		in_auditor_user_sid => in_user_sid,
		in_notes => NULL,
		in_internal_audit_type => v_audit_type_id,
		in_auditor_name => NULL,
		in_auditor_org => NULL,
		out_sid_id => v_audit_sid
	);
	
	RETURN v_audit_sid;
END;

FUNCTION GetOrCreateAuditWithFlow (
	in_name				IN	VARCHAR2,
	in_flow_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_user_sid			IN	security_pkg.T_SID_ID,
	in_survey_sid 		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_audit_type_name	IN	VARCHAR2 DEFAULT 'AUDIT_TYPE_WITH_FLOW',
	in_audit_dtm		IN	DATE DEFAULT DATE '2010-01-01'
) RETURN security_pkg.T_SID_ID
AS
	v_audit_sid			security_pkg.T_SID_ID;
	v_audit_type_id		NUMBER(10);
BEGIN
	SELECT MIN(internal_audit_sid)
	  INTO v_audit_sid
	  FROM internal_audit
	 WHERE app_sid = security_pkg.GetApp
	   AND label = in_name;
	
	IF v_audit_sid IS NOT NULL THEN
		RETURN v_audit_sid;
	END IF;
	
	BEGIN
		SELECT internal_audit_type_id
		  INTO v_audit_type_id
		  FROM internal_audit_type
		 WHERE label=in_audit_type_name;
		
		UPDATE internal_audit_type
		   SET flow_sid = in_flow_sid
		 WHERE internal_audit_type_id = v_audit_type_id;
		
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO internal_audit_type (internal_audit_type_id, label, flow_sid, internal_audit_type_source_id)
			VALUES (internal_audit_type_id_seq.nextval, in_audit_type_name, in_flow_sid, 1)
			RETURNING internal_audit_type_id INTO v_audit_type_id;
	END;
	
	audit_pkg.Save(
		in_sid_id => NULL,
		in_audit_ref => NULL,
		in_survey_sid => in_survey_sid,
		in_region_sid => in_region_sid,
		in_label => in_name,
		in_audit_dtm => in_audit_dtm,
		in_auditor_user_sid => in_user_sid,
		in_notes => NULL,
		in_internal_audit_type => v_audit_type_id,
		in_auditor_name => NULL,
		in_auditor_org => NULL,
		out_sid_id => v_audit_sid
	);
	
	RETURN v_audit_sid;
END;

FUNCTION GetOrCreateAuditWithInvType (
	in_name					IN	VARCHAR2,
	in_flow_sid				IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_aud_coord_sid		IN	security_pkg.T_SID_ID,
	in_inv_user_sid			IN	security_pkg.T_SID_ID,
	out_flow_item_id		OUT	NUMBER,
	out_flow_inv_type_id	OUT NUMBER
)
RETURN security_pkg.T_SID_ID
AS
	v_audit_sid						security.security_pkg.T_SID_ID;
	v_flow_inv_type					NUMBER(10);
	v_audit_type_id					NUMBER(10);
	v_flow_item_id					NUMBER(10);
BEGIN
	-- N.B. Doesn't need to be an audit workflow, we just need the involvement type's flow alert class
	-- to be something
	v_audit_sid := GetOrCreateAuditWithFlow(in_name, in_flow_sid, in_region_sid, in_aud_coord_sid, NULL, 'AUDIT_TYPE_WITH_INV_TYPE');
	SELECT internal_audit_type_id, flow_item_id
	  INTO v_audit_type_id, v_flow_item_id
	  FROM internal_audit ia
	 WHERE ia.internal_audit_sid = v_audit_sid;
	 
	flow_pkg.SetInvolvementType(in_flow_sid, 'AUDIT_INV_TYPE', NULL, v_flow_inv_type);
	INSERT INTO flow_item_involvement(flow_involvement_type_id, flow_item_id, user_sid)
	VALUES (v_flow_inv_type, v_flow_item_id, in_inv_user_sid);
	
	out_flow_item_id := v_flow_item_id;
	out_flow_inv_type_id := v_flow_inv_type;
	RETURN v_audit_sid;
END;

FUNCTION GetOrCreateNonComplianceTypeId (
	in_name				IN	VARCHAR2,
	in_is_flow_capability_enabled	NUMBER	DEFAULT 1
) RETURN NUMBER
AS
	v_nct_id						NUMBER(10);
	v_dummy_repeat_audit_type_ids	security_pkg.T_SID_IDS;
BEGIN
	SELECT MIN(nct.non_compliance_type_id)
	  INTO v_nct_id
	  FROM non_compliance_type nct
	 WHERE label = in_name;
	
	IF v_nct_id IS NOT NULL THEN
		RETURN v_nct_id;
	END IF;
	
	audit_pkg.SetNonComplianceType(
		in_non_compliance_type_id		=> NULL,
		in_label						=> in_name,
		in_lookup_key					=> in_name || '_KEY',
		in_position						=> 0,
		in_colour_when_open				=> 0,
		in_colour_when_closed			=> 0, 
		in_can_have_actions				=> 0,
		in_closure_behaviour_id			=> 1,
		in_score						=> NULL,
		in_repeat_score					=> NULL,
		in_root_cause_enabled			=> 0,
		in_match_repeats_by_carry_fwd	=> 0,
		in_match_repeats_by_dflt_ncs	=> 0,
		in_match_repeats_by_surveys		=> 0,
		in_find_repeats_in_unit			=> 'none',
		in_find_repeats_in_qty			=> NULL,
		in_carry_fwd_repeat_type		=> 'normal',
		in_is_default_survey_finding	=> 0,
		in_is_flow_capability_enabled	=> in_is_flow_capability_enabled,
		in_repeat_audit_type_ids		=> v_dummy_repeat_audit_type_ids,
		out_non_compliance_type_id		=> v_nct_id
	);
	
	SELECT MIN(nct.non_compliance_type_id)
	  INTO v_nct_id
	  FROM non_compliance_type nct
	 WHERE label = in_name;
	
	IF v_nct_id IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Error creating non-compliance type');
	END IF;
	
	RETURN v_nct_id;
END;

FUNCTION GetOrCreateNonComplianceId (
	in_audit_sid				IN	security_pkg.T_SID_ID,
	in_name						IN	VARCHAR2,
	in_non_compliance_type_id	IN  NUMBER DEFAULT NULL
) RETURN NUMBER
AS
	v_dummy_1			security_pkg.T_SID_IDS;
BEGIN
	RETURN GetOrCreateNonComplianceId(in_audit_sid, in_name, in_non_compliance_type_id, v_dummy_1);
END;

FUNCTION GetOrCreateNonComplianceId (
	in_audit_sid				IN	security_pkg.T_SID_ID,
	in_name						IN	VARCHAR2,
	in_non_compliance_type_id	IN  NUMBER DEFAULT NULL,
	in_tag_ids					IN	security_pkg.T_SID_IDS
) RETURN NUMBER
AS
	v_nc_id				NUMBER(10);
	v_cur				security_pkg.T_OUTPUT_CUR;
	v_dummy_1			security_pkg.T_SID_IDS;
	v_dummy_2			audit_pkg.T_CACHE_KEYS;
BEGIN
	SELECT MIN(anc.non_compliance_id)
	  INTO v_nc_id
	  FROM audit_non_compliance anc
	  JOIN non_compliance nc ON anc.non_compliance_id = nc.non_compliance_id
	 WHERE anc.internal_audit_sid = in_audit_sid
	   AND label = in_name;
	
	IF v_nc_id IS NOT NULL THEN
		RETURN v_nc_id;
	END IF;
	
	audit_pkg.SaveNonCompliance(
		in_non_compliance_id => NULL,
		in_internal_audit_sid => in_audit_sid,
		in_from_non_comp_default_id => NULL,
		in_label => in_name,
		in_detail => 'Detail for '||in_name,
		in_non_compliance_type_id => in_non_compliance_type_id,
		in_is_closed => NULL,
		in_current_file_uploads => v_dummy_1,
		in_new_file_uploads => v_dummy_2,
		in_tag_ids => in_tag_ids,
		in_question_id => NULL,
		in_question_option_id => NULL,
		out_nc_cur => v_cur,
		out_nc_upload_cur => v_cur,
		out_nc_tag_cur => v_cur
	);
	
	SELECT MIN(anc.non_compliance_id)
	  INTO v_nc_id
	  FROM audit_non_compliance anc
	  JOIN non_compliance nc ON anc.non_compliance_id = nc.non_compliance_id
	 WHERE anc.internal_audit_sid = in_audit_sid
	   AND label = in_name;
	
	IF v_nc_id IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Error creating non-compliance');
	END IF;
	
	RETURN v_nc_id;
END;

FUNCTION GetOrCreateGroup (
	in_group_name		IN	Security_Pkg.T_SO_NAME
) RETURN NUMBER
AS
	v_groups_sid		security_pkg.T_SID_ID;
	v_group_sid			security_pkg.T_SID_ID;
BEGIN
	v_groups_sid := security.securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Groups');

	BEGIN
		v_group_sid := security.securableobject_pkg.GetSidFromPath(security_pkg.GetAct, v_groups_sid, in_group_name);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			security.group_pkg.CreateGroupWithClass(security_pkg.GetAct,v_groups_sid, security_pkg.GROUP_TYPE_SECURITY,
				in_group_name, security.class_pkg.GetClassId('CSRUserGroup'), v_group_sid);
	END;

	RETURN v_group_sid;
END;

FUNCTION GetOrCreateDelegPlan (
	in_name					IN	VARCHAR2,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_root_regions			IN	security_pkg.T_SID_IDS,
	in_roles				IN	security_pkg.T_SID_IDS,
	in_start_date			IN	DATE,
	in_end_date				IN	DATE,
	in_schedule_xml			IN	CLOB,
	in_dynamic				IN	NUMBER DEFAULT 1,
	in_period_set_id		IN	NUMBER DEFAULT 1,
	in_period_interval_id	IN	NUMBER DEFAULT 1,
	in_reminder_offset		IN	NUMBER DEFAULT 5,
	in_region_selection		IN	VARCHAR2 DEFAULT CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION,
	in_tag_id				IN	NUMBER DEFAULT NULL,
	in_region_type			IN	NUMBER DEFAULT NULL,
	in_selected_regions		IN	security_pkg.T_SID_IDS DEFAULT security_pkg.T_SID_IDS()
) RETURN security_pkg.T_SID_ID
AS
	v_deleg_plan_sid		security_pkg.T_SID_ID;
	v_regions				security.T_SID_TABLE;
	v_deleg_template_cur	SYS_REFCURSOR;
	v_deleg_plan_col_id		deleg_plan_col.deleg_plan_col_id%TYPE;
BEGIN
	v_regions := security_pkg.SidArrayToTable(CASE WHEN in_selected_regions.COUNT = 0 THEN in_root_regions ELSE in_selected_regions END);
	
	SELECT MIN(deleg_plan_sid)
	  INTO v_deleg_plan_sid
	  FROM deleg_plan
	 WHERE app_sid = security_pkg.GetApp
	   AND name = in_name;

	IF v_deleg_plan_sid IS NOT NULL THEN
		RETURN v_deleg_plan_sid;
	END IF;

	v_deleg_plan_sid := deleg_plan_pkg.NewDelegPlan(
		in_name					=> in_name,
		in_start_date			=> in_start_date,
		in_end_date				=> in_end_date,
		in_reminder_offset 		=> in_reminder_offset,
		in_period_set_id		=> in_period_set_id,
		in_period_interval_id	=> in_period_interval_id,
		in_schedule_xml 		=> in_schedule_xml,
		in_dynamic				=> in_dynamic
	);

	--Add regions
	deleg_plan_pkg.SetPlanRegions(v_deleg_plan_sid, in_root_regions);

	--Add roles
	deleg_plan_pkg.SetPlanRoles(v_deleg_plan_sid, in_roles);

	--Add template
	deleg_plan_pkg.AddDelegToPlan(v_deleg_plan_sid, in_delegation_sid, v_deleg_template_cur);

	--Select regions 
	SELECT deleg_plan_col_id
	  INTO v_deleg_plan_col_id
	  FROM deleg_plan_col
	 WHERE deleg_plan_sid = v_deleg_plan_sid;

	FOR r IN (
		SELECT column_value FROM TABLE(v_regions)
	) LOOP
		deleg_plan_pkg.UpdateDelegPlanColRegion(
			in_deleg_plan_col_id => v_deleg_plan_col_id,
			in_region_sid => r.column_value,
			in_region_selection => in_region_selection,
			in_tag_id => in_tag_id,
			in_region_type => in_region_type
		);
	END LOOP;

	RETURN v_deleg_plan_sid;
END;

PROCEDURE SetSelectionForDelegPlan(
	in_name					IN	VARCHAR2,
	in_root_regions			IN	security_pkg.T_SID_IDS,
	in_region_selection		IN	VARCHAR2 DEFAULT CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION,
	in_tag_id				IN	NUMBER DEFAULT NULL,
	in_region_type			IN	NUMBER DEFAULT NULL
)
AS
	v_deleg_plan_sid		security_pkg.T_SID_ID;
	v_regions				security.T_SID_TABLE := security_pkg.SidArrayToTable(in_root_regions);
	v_deleg_plan_col_id		deleg_plan_col.deleg_plan_col_id%TYPE;
BEGIN
	SELECT MIN(deleg_plan_sid)
	  INTO v_deleg_plan_sid
	  FROM deleg_plan
	 WHERE app_sid = security_pkg.GetApp
	   AND name = in_name;
	   
	--Select regions 
	SELECT deleg_plan_col_id
	  INTO v_deleg_plan_col_id
	  FROM deleg_plan_col
	 WHERE deleg_plan_sid = v_deleg_plan_sid;

	FOR r IN (
		SELECT column_value FROM TABLE(v_regions)
	) LOOP
		deleg_plan_pkg.UpdateDelegPlanColRegion(
			in_deleg_plan_col_id => v_deleg_plan_col_id,
			in_region_sid => r.column_value,
			in_region_selection => in_region_selection,
			in_tag_id => in_tag_id,
			in_region_type => in_region_type
		);
	END LOOP;
END;

--If in_schedule_xml is null, then it's fixed dates
--TODO : Allow passing of scheduled and reminder offset for all combinations
PROCEDURE SetScheduleForDelegPlan (
	in_deleg_plan_sid	IN	security_pkg.T_SID_ID,
	in_deleg_templates	IN	security_pkg.T_SID_IDS,
	in_roles			IN	security_pkg.T_SID_IDS,
	in_schedule_xml		IN	deleg_plan_date_schedule.schedule_xml%type DEFAULT NULL,
	in_reminder_offset	IN 	deleg_plan_date_schedule.reminder_offset%type DEFAULT NULL
)
AS
	v_roles					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_roles);
	v_templates				security.T_SID_TABLE := security_pkg.SidArrayToTable(in_deleg_templates);
	v_entries				SYS_REFCURSOR;
	TYPE entry_type 		IS RECORD (
		role_sid			NUMBER(10),
		deleg_plan_col_id	NUMBER(10),
		start_dtm			DATE,
		creation_dtm		DATE,
		submission_dtm		DATE,
		reminder_dtm		DATE
	);
	v_entries_row			entry_type;
BEGIN
	IF in_deleg_templates.COUNT > 0 AND in_roles.COUNT > 0 THEN
		FOR t IN (
			SELECT column_value FROM TABLE(v_templates)
		) LOOP
			FOR r IN (
				SELECT column_value FROM TABLE(v_roles)
			) LOOP			
				deleg_plan_pkg.AddDelegPlanDateSchedule(
					in_deleg_plan_sid		=>	in_deleg_plan_sid,
					in_role_sid				=>	r.column_value,
					in_deleg_plan_col_id	=>	t.column_value,
					in_schedule_xml			=>	in_schedule_xml,
					in_reminder_offset		=>	in_reminder_offset
				);				
			END LOOP;
		END LOOP;

	ELSIF in_deleg_templates.COUNT > 0 AND in_roles.COUNT = 0 THEN
		FOR r IN (
			SELECT column_value FROM TABLE(v_templates)
		) LOOP
			deleg_plan_pkg.AddDelegPlanDateSchedule(
				in_deleg_plan_sid		=>	in_deleg_plan_sid,
				in_role_sid				=>	NULL,
				in_deleg_plan_col_id	=>	r.column_value,
				in_schedule_xml			=>	in_schedule_xml,
				in_reminder_offset		=>	in_reminder_offset
			);
		END LOOP;

	ELSIF in_roles.COUNT > 0 AND in_deleg_templates.COUNT = 0 THEN	
		FOR r IN (
			SELECT column_value FROM TABLE(v_roles)
		) LOOP
			deleg_plan_pkg.AddDelegPlanDateSchedule(
				in_deleg_plan_sid		=>	in_deleg_plan_sid,
				in_role_sid				=>	r.column_value,
				in_deleg_plan_col_id	=>	NULL,
				in_schedule_xml			=>	in_schedule_xml,
				in_reminder_offset		=>	in_reminder_offset
			);
		END LOOP;

	ELSE
		deleg_plan_pkg.AddDelegPlanDateSchedule(
			in_deleg_plan_sid		=>	in_deleg_plan_sid,
			in_role_sid				=>	NULL,
			in_deleg_plan_col_id	=>	NULL,
			in_schedule_xml			=>	in_schedule_xml,
			in_reminder_offset		=>	in_reminder_offset
		);
	END IF;

	OPEN v_entries FOR 'SELECT role_sid, deleg_plan_col_id, start_dtm, creation_dtm, submission_dtm, reminder_dtm 
						  FROM csr.temp_deleg_test_schedule_entry';
		LOOP
			FETCH v_entries INTO v_entries_row;
			EXIT WHEN v_entries%NOTFOUND;
			deleg_plan_pkg.AddDelegPlanDateScheduleEntry(
					in_deleg_plan_sid		=>	in_deleg_plan_sid,
					in_role_sid				=>	v_entries_row.role_sid,
					in_deleg_plan_col_id	=>	v_entries_row.deleg_plan_col_id,
					in_start_dtm 			=>	v_entries_row.start_dtm,
					in_creation_dtm			=>	v_entries_row.creation_dtm,
					in_submission_dtm		=>	v_entries_row.submission_dtm,
					in_reminder_dtm			=>	v_entries_row.reminder_dtm
				);
		END LOOP;
	CLOSE v_entries;
END;

FUNCTION GetOrCreateTagGroup (
	in_lookup_key			IN	VARCHAR2,
	in_multi_select			IN	NUMBER,
	in_applies_to_inds		IN	NUMBER,
	in_applies_to_regions	IN	NUMBER,
	in_tag_members			IN	VARCHAR2,
	in_mandatory			IN	NUMBER DEFAULT 0,
	in_applies_to_suppliers	IN	NUMBER DEFAULT 0
) RETURN NUMBER
AS
	v_tag_group_id				NUMBER;
	v_tag_id					NUMBER;
BEGIN
	SELECT MIN(tag_group_id)
	  INTO v_tag_group_id
	  FROM tag_group
	 WHERE lookup_key = in_lookup_key
	   AND app_sid = security_pkg.GetApp;
	
	IF v_tag_group_id IS NOT NULL THEN
		RETURN v_tag_group_id;
	END IF;
	
	tag_pkg.SetTagGroup(
		in_name					=>	in_lookup_key,
		in_multi_select			=>	in_multi_select,
		in_mandatory			=>	in_mandatory,
		in_applies_to_inds		=>	in_applies_to_inds,
		in_applies_to_regions	=>	in_applies_to_regions,
		in_applies_to_suppliers	=>  in_applies_to_suppliers,
		in_lookup_key			=>	in_lookup_key,
		out_tag_group_id		=>	v_tag_group_id
	);
	
	FOR r IN (
		SELECT REGEXP_SUBSTR(in_tag_members, '[^,]+', 1, ROWNUM) tag 
		  FROM dual
	   CONNECT BY LEVEL <= regexp_count(in_tag_members, '[^,]+')
	)
	LOOP
		tag_pkg.SetTag(
			in_tag_group_id			=>	v_tag_group_id,
			in_tag					=>	r.tag,
			in_explanation			=>	r.tag,
			in_lookup_key			=>	r.tag,
			out_tag_id				=>	v_tag_id
		);
	END LOOP;
	
	RETURN v_tag_group_id;
END;

FUNCTION GetOrCreateTag (
	in_lookup_key			IN	VARCHAR2,
	in_tag_group_id			IN	NUMBER
) RETURN NUMBER
AS
	v_tag_id				NUMBER;
BEGIN
	SELECT MIN(tag_id)
	  INTO v_tag_id
	  FROM tag
	 WHERE lookup_key = in_lookup_key
	   AND app_sid = security_pkg.GetApp;
	
	IF v_tag_id IS NOT NULL THEN
		RETURN v_tag_id;
	END IF;
	 
	tag_pkg.SetTag(
		in_tag_group_id			=>	in_tag_group_id,
		in_tag					=>	in_lookup_key,
		in_explanation			=>	in_lookup_key,
		in_lookup_key			=>	in_lookup_key,
		out_tag_id				=>	v_tag_id
	);
	
	RETURN v_tag_id;
END;

FUNCTION GetOrCreatePeriodSet
RETURN NUMBER
AS
	v_period_set_id					NUMBER;
BEGIN
	SELECT MAX(period_set_id)
	  INTO v_period_set_id
	  FROM period_set;
	  
	IF v_period_set_id > 1 THEN
		RETURN v_period_set_id;
	END IF;
	
	v_period_set_id := 2;
	
	INSERT INTO period_set (period_set_id,annual_periods,label) VALUES (v_period_set_id, 0, 'Thirteen Periods');

	INSERT INTO period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (v_period_set_id,1,'P01',null,null);
	INSERT INTO period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (v_period_set_id,2,'P02',null,null);
	INSERT INTO period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (v_period_set_id,3,'P03',null,null);
	INSERT INTO period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (v_period_set_id,4,'P04',null,null);
	INSERT INTO period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (v_period_set_id,5,'P05',null,null);
	INSERT INTO period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (v_period_set_id,6,'P06',null,null);
	INSERT INTO period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (v_period_set_id,7,'P07',null,null);
	INSERT INTO period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (v_period_set_id,8,'P08',null,null);
	INSERT INTO period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (v_period_set_id,9,'P09',null,null);
	INSERT INTO period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (v_period_set_id,10,'P10',null,null);
	INSERT INTO period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (v_period_set_id,11,'P11',null,null);
	INSERT INTO period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (v_period_set_id,12,'P12',null,null);
	INSERT INTO period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (v_period_set_id,13,'P13',null,null);

	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,1,2009, DATE'2009-04-01',DATE'2009-05-03');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,2,2009, DATE'2009-05-03',DATE'2009-05-31');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,3,2009, DATE'2009-05-31',DATE'2009-06-28');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,4,2009, DATE'2009-06-28',DATE'2009-07-26');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,5,2009, DATE'2009-07-26',DATE'2009-08-23');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,6,2009, DATE'2009-08-23',DATE'2009-09-20');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,7,2009, DATE'2009-09-20',DATE'2009-10-18');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,8,2009, DATE'2009-10-18',DATE'2009-11-15');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,9,2009, DATE'2009-11-15',DATE'2009-12-13');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,10,2009,DATE'2009-12-13',DATE'2010-01-10');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,11,2009,DATE'2010-01-10',DATE'2010-02-07');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,12,2009,DATE'2010-02-07',DATE'2010-03-07');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,13,2009,DATE'2010-03-07',DATE'2010-04-01');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,1,2010, DATE'2010-04-01',DATE'2010-05-02');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,2,2010, DATE'2010-05-02',DATE'2010-05-30');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,3,2010, DATE'2010-05-30',DATE'2010-06-27');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,4,2010, DATE'2010-06-27',DATE'2010-07-25');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,5,2010, DATE'2010-07-25',DATE'2010-08-22');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,6,2010, DATE'2010-08-22',DATE'2010-09-19');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,7,2010, DATE'2010-09-19',DATE'2010-10-17');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,8,2010, DATE'2010-10-17',DATE'2010-11-14');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,9,2010, DATE'2010-11-14',DATE'2010-12-12');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,10,2010,DATE'2010-12-12',DATE'2011-01-09');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,11,2010,DATE'2011-01-09',DATE'2011-02-06');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,12,2010,DATE'2011-02-06',DATE'2011-03-06');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,13,2010,DATE'2011-03-06',DATE'2011-04-01');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,1,2011, DATE'2011-04-01',DATE'2011-05-01');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,2,2011, DATE'2011-05-01',DATE'2011-05-29');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,3,2011, DATE'2011-05-29',DATE'2011-06-26');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,4,2011, DATE'2011-06-26',DATE'2011-07-24');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,5,2011, DATE'2011-07-24',DATE'2011-08-21');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,6,2011, DATE'2011-08-21',DATE'2011-09-18');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,7,2011, DATE'2011-09-18',DATE'2011-10-16');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,8,2011, DATE'2011-10-16',DATE'2011-11-13');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,9,2011, DATE'2011-11-13',DATE'2011-12-11');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,10,2011,DATE'2011-12-11',DATE'2012-01-08');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,11,2011,DATE'2012-01-08',DATE'2012-02-05');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,12,2011,DATE'2012-02-05',DATE'2012-03-04');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,13,2011,DATE'2012-03-04',DATE'2012-04-01');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,1,2012, DATE'2012-04-01',DATE'2012-04-29');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,2,2012, DATE'2012-04-29',DATE'2012-05-27');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,3,2012, DATE'2012-05-27',DATE'2012-06-24');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,4,2012, DATE'2012-06-24',DATE'2012-07-22');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,5,2012, DATE'2012-07-22',DATE'2012-08-19');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,6,2012, DATE'2012-08-19',DATE'2012-09-16');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,7,2012, DATE'2012-09-16',DATE'2012-10-14');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,8,2012, DATE'2012-10-14',DATE'2012-11-11');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,9,2012, DATE'2012-11-11',DATE'2012-12-09');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,10,2012,DATE'2012-12-09',DATE'2013-01-06');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,11,2012,DATE'2013-01-06',DATE'2013-02-03');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,12,2012,DATE'2013-02-03',DATE'2013-03-03');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,13,2012,DATE'2013-03-03',DATE'2013-04-01');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,1,2013, DATE'2013-04-01',DATE'2013-04-28');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,2,2013, DATE'2013-04-28',DATE'2013-05-26');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,3,2013, DATE'2013-05-26',DATE'2013-06-23');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,4,2013, DATE'2013-06-23',DATE'2013-07-21');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,5,2013, DATE'2013-07-21',DATE'2013-08-18');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,6,2013, DATE'2013-08-18',DATE'2013-09-15');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,7,2013, DATE'2013-09-15',DATE'2013-10-13');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,8,2013, DATE'2013-10-13',DATE'2013-11-10');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,9,2013, DATE'2013-11-10',DATE'2013-12-08');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,10,2013,DATE'2013-12-08',DATE'2014-01-05');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,11,2013,DATE'2014-01-05',DATE'2014-02-02');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,12,2013,DATE'2014-02-02',DATE'2014-03-02');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,13,2013,DATE'2014-03-02',DATE'2014-04-01');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,1,2014, DATE'2014-04-01',DATE'2014-04-27');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,2,2014, DATE'2014-04-27',DATE'2014-05-25');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,3,2014, DATE'2014-05-25',DATE'2014-06-22');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,4,2014, DATE'2014-06-22',DATE'2014-07-20');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,5,2014, DATE'2014-07-20',DATE'2014-08-17');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,6,2014, DATE'2014-08-17',DATE'2014-09-14');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,7,2014, DATE'2014-09-14',DATE'2014-10-12');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,8,2014, DATE'2014-10-12',DATE'2014-11-09');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,9,2014, DATE'2014-11-09',DATE'2014-12-07');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,10,2014,DATE'2014-12-07',DATE'2015-01-04');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,11,2014,DATE'2015-01-04',DATE'2015-02-01');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,12,2014,DATE'2015-02-01',DATE'2015-03-01');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,13,2014,DATE'2015-03-01',DATE'2015-04-01');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,1,2015, DATE'2015-04-01',DATE'2015-05-03');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,2,2015, DATE'2015-05-03',DATE'2015-05-31');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,3,2015, DATE'2015-05-31',DATE'2015-06-28');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,4,2015, DATE'2015-06-28',DATE'2015-07-26');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,5,2015, DATE'2015-07-26',DATE'2015-08-23');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,6,2015, DATE'2015-08-23',DATE'2015-09-20');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,7,2015, DATE'2015-09-20',DATE'2015-10-18');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,8,2015, DATE'2015-10-18',DATE'2015-11-15');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,9,2015, DATE'2015-11-15',DATE'2015-12-13');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,10,2015,DATE'2015-12-13',DATE'2016-01-10');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,11,2015,DATE'2016-01-10',DATE'2016-02-07');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,12,2015,DATE'2016-02-07',DATE'2016-03-06');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,13,2015,DATE'2016-03-06',DATE'2016-04-01');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,1,2016, DATE'2016-04-01',DATE'2016-05-01');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,2,2016, DATE'2016-05-01',DATE'2016-05-29');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,3,2016, DATE'2016-05-29',DATE'2016-06-26');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,4,2016, DATE'2016-06-26',DATE'2016-07-24');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,5,2016, DATE'2016-07-24',DATE'2016-08-21');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,6,2016, DATE'2016-08-21',DATE'2016-09-18');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,7,2016, DATE'2016-09-18',DATE'2016-10-16');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,8,2016, DATE'2016-10-16',DATE'2016-11-13');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,9,2016, DATE'2016-11-13',DATE'2016-12-11');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,10,2016,DATE'2016-12-11',DATE'2017-01-08');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,11,2016,DATE'2017-01-08',DATE'2017-02-05');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,12,2016,DATE'2017-02-05',DATE'2017-03-05');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,13,2016,DATE'2017-03-05',DATE'2017-03-31');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,1,2017, DATE'2017-03-31',DATE'2017-04-29');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,2,2017, DATE'2017-04-29',DATE'2017-05-27');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,3,2017, DATE'2017-05-27',DATE'2017-06-24');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,4,2017, DATE'2017-06-24',DATE'2017-07-22');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,5,2017, DATE'2017-07-22',DATE'2017-08-19');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,6,2017, DATE'2017-08-19',DATE'2017-09-16');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,7,2017, DATE'2017-09-16',DATE'2017-10-14');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,8,2017, DATE'2017-10-14',DATE'2017-11-11');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,9,2017, DATE'2017-11-11',DATE'2017-12-09');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,10,2017,DATE'2017-12-09',DATE'2018-01-06');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,11,2017,DATE'2018-01-06',DATE'2018-02-03');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,12,2017,DATE'2018-02-03',DATE'2018-03-03');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,13,2017,DATE'2018-03-03',DATE'2018-03-31');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,1,2018, DATE'2018-03-31',DATE'2018-04-28');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,2,2018, DATE'2018-04-28',DATE'2018-05-26');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,3,2018, DATE'2018-05-26',DATE'2018-06-23');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,4,2018, DATE'2018-06-23',DATE'2018-07-21');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,5,2018, DATE'2018-07-21',DATE'2018-08-18');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,6,2018, DATE'2018-08-18',DATE'2018-09-15');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,7,2018, DATE'2018-09-15',DATE'2018-10-13');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,8,2018, DATE'2018-10-13',DATE'2018-11-10');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,9,2018, DATE'2018-11-10',DATE'2018-12-08');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,10,2018,DATE'2018-12-08',DATE'2019-01-05');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,11,2018,DATE'2019-01-05',DATE'2019-02-02');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,12,2018,DATE'2019-02-02',DATE'2019-03-02');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,13,2018,DATE'2019-03-02',DATE'2019-03-31');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,1,2019, DATE'2019-03-31',DATE'2019-04-27');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,2,2019, DATE'2019-04-27',DATE'2019-05-25');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,3,2019, DATE'2019-05-25',DATE'2019-06-22');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,4,2019, DATE'2019-06-22',DATE'2019-07-20');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,5,2019, DATE'2019-07-20',DATE'2019-08-17');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,6,2019, DATE'2019-08-17',DATE'2019-09-14');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,7,2019, DATE'2019-09-14',DATE'2019-10-12');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,8,2019, DATE'2019-10-12',DATE'2019-11-09');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,9,2019, DATE'2019-11-09',DATE'2019-12-07');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,10,2019,DATE'2019-12-07',DATE'2020-01-04');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,11,2019,DATE'2020-01-04',DATE'2020-02-01');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,12,2019,DATE'2020-02-01',DATE'2020-02-29');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,13,2019,DATE'2020-02-29',DATE'2020-03-31');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,1,2020, DATE'2020-03-31',DATE'2020-04-29');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,2,2020, DATE'2020-04-29',DATE'2020-05-27');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,3,2020, DATE'2020-05-27',DATE'2020-06-24');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,4,2020, DATE'2020-06-24',DATE'2020-07-22');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,5,2020, DATE'2020-07-22',DATE'2020-08-19');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,6,2020, DATE'2020-08-19',DATE'2020-09-16');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,7,2020, DATE'2020-09-16',DATE'2020-10-14');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,8,2020, DATE'2020-10-14',DATE'2020-11-11');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,9,2020, DATE'2020-11-11',DATE'2020-12-09');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,10,2020,DATE'2020-12-09',DATE'2021-01-06');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,11,2020,DATE'2021-01-06',DATE'2021-02-03');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,12,2020,DATE'2021-02-03',DATE'2021-03-03');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,13,2020,DATE'2021-03-03',DATE'2021-03-31');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,1,2021, DATE'2021-03-31',DATE'2021-04-29');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,2,2021, DATE'2021-04-29',DATE'2021-05-27');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,3,2021, DATE'2021-05-27',DATE'2021-06-24');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,4,2021, DATE'2021-06-24',DATE'2021-07-22');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,5,2021, DATE'2021-07-22',DATE'2021-08-19');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,6,2021, DATE'2021-08-19',DATE'2021-09-16');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,7,2021, DATE'2021-09-16',DATE'2021-10-14');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,8,2021, DATE'2021-10-14',DATE'2021-11-11');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,9,2021, DATE'2021-11-11',DATE'2021-12-09');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,10,2021,DATE'2021-12-09',DATE'2022-01-06');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,11,2021,DATE'2022-01-06',DATE'2022-02-03');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,12,2021,DATE'2022-02-03',DATE'2022-03-03');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,13,2021,DATE'2022-03-03',DATE'2022-03-31');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,1,2022, DATE'2022-03-31',DATE'2022-04-29');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,2,2022, DATE'2022-04-29',DATE'2022-05-27');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,3,2022, DATE'2022-05-27',DATE'2022-06-24');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,4,2022, DATE'2022-06-24',DATE'2022-07-22');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,5,2022, DATE'2022-07-22',DATE'2022-08-19');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,6,2022, DATE'2022-08-19',DATE'2022-09-16');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,7,2022, DATE'2022-09-16',DATE'2022-10-14');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,8,2022, DATE'2022-10-14',DATE'2022-11-11');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,9,2022, DATE'2022-11-11',DATE'2022-12-09');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,10,2022,DATE'2022-12-09',DATE'2023-01-06');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,11,2022,DATE'2023-01-06',DATE'2023-02-03');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,12,2022,DATE'2023-02-03',DATE'2023-03-03');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,13,2022,DATE'2023-03-03',DATE'2023-03-31');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,1,2023, DATE'2023-03-31',DATE'2023-04-29');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,2,2023, DATE'2023-04-29',DATE'2023-05-27');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,3,2023, DATE'2023-05-27',DATE'2023-06-24');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,4,2023, DATE'2023-06-24',DATE'2023-07-22');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,5,2023, DATE'2023-07-22',DATE'2023-08-19');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,6,2023, DATE'2023-08-19',DATE'2023-09-16');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,7,2023, DATE'2023-09-16',DATE'2023-10-14');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,8,2023, DATE'2023-10-14',DATE'2023-11-11');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,9,2023, DATE'2023-11-11',DATE'2023-12-09');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,10,2023,DATE'2023-12-09',DATE'2024-01-06');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,11,2023,DATE'2024-01-06',DATE'2024-02-03');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,12,2023,DATE'2024-02-03',DATE'2024-03-03');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,13,2023,DATE'2024-03-03',DATE'2024-03-31');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,1,2024, DATE'2024-03-31',DATE'2024-04-29');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,2,2024, DATE'2024-04-29',DATE'2024-05-27');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,3,2024, DATE'2024-05-27',DATE'2024-06-24');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,4,2024, DATE'2024-06-24',DATE'2024-07-22');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,5,2024, DATE'2024-07-22',DATE'2024-08-19');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,6,2024, DATE'2024-08-19',DATE'2024-09-16');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,7,2024, DATE'2024-09-16',DATE'2024-10-14');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,8,2024, DATE'2024-10-14',DATE'2024-11-11');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,9,2024, DATE'2024-11-11',DATE'2024-12-09');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,10,2024,DATE'2024-12-09',DATE'2025-01-06');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,11,2024,DATE'2025-01-06',DATE'2025-02-03');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,12,2024,DATE'2025-02-03',DATE'2025-03-03');
	INSERT INTO period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (v_period_set_id,13,2024,DATE'2025-03-03',DATE'2025-03-31');

	INSERT INTO period_interval (period_set_id,period_interval_id,single_interval_label,multiple_interval_label,label,single_interval_no_year_label) 
		VALUES (v_period_set_id,1,'{0:PL} {0:YYYY/ZZ}','{0:PL} {0:YYYY} - {1:PL} {1:YYYY}','Period','{0:PL}');
	INSERT INTO period_interval (period_set_id,period_interval_id,single_interval_label,multiple_interval_label,label,single_interval_no_year_label)
		VALUES (v_period_set_id,2,'Q{0:I} {0:YYYY/ZZ}','Q{0:I} {0:YYYY} - Q{1:I} {1:YYYY}','Quarter','Q{0:I}');
	INSERT INTO period_interval (period_set_id,period_interval_id,single_interval_label,multiple_interval_label,label,single_interval_no_year_label)
		VALUES (v_period_set_id,3,'H{0:I} {0:YYYY/ZZ}','H{0:I} {0:YYYY} - H{1:I} {1:YYYY}','Half','H{0:I}');
	INSERT INTO period_interval (period_set_id,period_interval_id,single_interval_label,multiple_interval_label,label,single_interval_no_year_label)
		VALUES (v_period_set_id,4,'{0:YYYY/ZZ}','{0:YYYY} - {1:YYYY}','Year','Whole year');

	INSERT INTO period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (v_period_set_id,1,1,1);
	INSERT INTO period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (v_period_set_id,2,1,3);
	INSERT INTO period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (v_period_set_id,4,1,13);
	INSERT INTO period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (v_period_set_id,1,2,2);
	INSERT INTO period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (v_period_set_id,1,3,3);
	INSERT INTO period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (v_period_set_id,1,4,4);
	INSERT INTO period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (v_period_set_id,2,4,6);
	INSERT INTO period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (v_period_set_id,1,5,5);
	INSERT INTO period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (v_period_set_id,1,6,6);
	INSERT INTO period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (v_period_set_id,1,7,7);
	INSERT INTO period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (v_period_set_id,2,7,9);
	INSERT INTO period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (v_period_set_id,1,8,8);
	INSERT INTO period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (v_period_set_id,1,9,9);
	INSERT INTO period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (v_period_set_id,1,10,10);
	INSERT INTO period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (v_period_set_id,2,10,13);
	INSERT INTO period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (v_period_set_id,1,11,11);
	INSERT INTO period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (v_period_set_id,1,12,12);
	INSERT INTO period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (v_period_set_id,1,13,13);
	INSERT INTO period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (v_period_set_id,3,1,6);
	INSERT INTO period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (v_period_set_id,3,7,13);
	  
	RETURN v_period_set_id;
END;

FUNCTION GetOrCreateMenu(
	in_so_name					IN	VARCHAR2,
	in_name						IN	VARCHAR2,
	in_action					IN	VARCHAR2,
	in_pos						IN	NUMBER,
	in_parent_sid				IN	security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'menu'),
	in_parent_path				IN	VARCHAR2 DEFAULT 'menu',
	in_admin_group_sid			IN	security.security_pkg.T_SID_ID DEFAULT GetOrCreateGroup('Administrators')
) RETURN security.security_pkg.T_SID_ID
AS
	v_sid						security.security_pkg.T_SID_ID;
BEGIN
	security.menu_pkg.CreateMenu(SYS_CONTEXT('SECURITY','ACT'), in_parent_sid,
		in_so_name, in_name, in_action, in_pos, null, v_sid);
	
	security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), security.acl_pkg.GetDACLIDForSID(v_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 0,
		in_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	
	RETURN v_sid;
EXCEPTION
	WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
		RETURN security.securableobject_pkg.getSidFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), in_parent_path || '/' || in_so_name);
END;

FUNCTION GetOrCreateWebResource(
	in_parent_sid			IN	security.security_pkg.T_SID_ID,
	in_name					IN	VARCHAR2
) RETURN security.security_pkg.T_SID_ID
AS
	v_sid							security.security_pkg.T_SID_ID;
	v_www_sid						security.security_pkg.T_SID_ID := security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'wwwroot');
BEGIN
	RETURN security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY','ACT'), in_parent_sid, in_name);
EXCEPTION
	WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
		security.web_pkg.CreateResource(SYS_CONTEXT('SECURITY','ACT'), v_www_sid, in_parent_sid, in_name, v_sid);
		RETURN v_sid;
END;

PROCEDURE GetOrCreateWorkflow (
	in_label						IN	flow.label%TYPE,
	in_flow_alert_class				IN	flow.flow_alert_class%TYPE,
	out_sid							OUT	security.security_pkg.T_SID_ID
)
AS
	v_audit_type_count		NUMBER;
	v_flow_item_id			flow_item.flow_item_id%TYPE;
	v_workflows_sid			security.security_pkg.T_SID_ID;
BEGIN
	v_workflows_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Workflows');
	BEGIN
		out_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), v_workflows_sid, in_label);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND	THEN
			flow_pkg.CreateFlow(
				in_label			=> in_label,
				in_parent_sid		=> v_workflows_sid,
				in_flow_alert_class	=> in_flow_alert_class,
				out_flow_sid		=> out_sid
			);
	END;
END;

PROCEDURE GetOrCreateWorkflowState (
	in_flow_sid						IN	flow.flow_sid%TYPE,
	in_state_label					IN	flow_state.label%TYPE,
	in_state_lookup_key				IN	flow_state.lookup_key%TYPE,
	out_flow_state_id				OUT	flow_state.flow_state_id%TYPE
)
AS
BEGIN
	out_flow_state_id := flow_pkg.GetStateId(
		in_flow_sid				=> in_flow_sid,
		in_lookup_key			=> in_state_lookup_key
	);
	
	IF out_flow_state_id IS NULL OR out_flow_state_id = 0 THEN
		flow_pkg.CreateState(
			in_flow_sid				=> in_flow_sid,
			in_label				=> in_state_label,
			in_lookup_key			=> in_state_lookup_key,
			in_flow_state_nature_id	=> NULL,
			out_flow_state_id		=> out_flow_state_id
		);
	END IF;
END;

/* Test site creation. First run csr.csr_app_pkg.CreateApp */

PROCEDURE CreateCommonMenu
AS
	v_menu_sid						security.security_pkg.T_SID_ID;
BEGIN
	v_menu_sid := GetOrCreateMenu(
		in_name => 'Data entry',
		in_so_name => 'data',
		in_pos => 1,
		in_action => '#'
	);
	v_menu_sid := GetOrCreateMenu(
		in_name => 'Admin',
		in_so_name => 'admin',
		in_pos => 2,
		in_action => '#'
	);
	v_menu_sid := GetOrCreateMenu(
		in_name => 'Setup',
		in_so_name => 'setup',
		in_pos => 3,
		in_action => '#'
	);
END;

-- Bare minimum to get a test site up and running.
PROCEDURE CreateCommonWebResources
AS
	v_www_sid 						security.security_pkg.T_SID_ID := security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'wwwroot');
	v_wwwapp_sid					security.security_pkg.T_SID_ID;
	v_csr_sid						security.security_pkg.T_SID_ID;
	v_site_sid						security.security_pkg.T_SID_ID;
	v_site_admin_sid				security.security_pkg.T_SID_ID;
	v_login_sid						security.security_pkg.T_SID_ID;
	v_logout_sid					security.security_pkg.T_SID_ID;
	v_styles_sid					security.security_pkg.T_SID_ID;
	v_shared_sid					security.security_pkg.T_SID_ID;
	v_public_sid					security.security_pkg.T_SID_ID;
	
	v_everyone_group_sid			security.security_pkg.T_SID_ID := GetOrCreateGroup('Everyone');
BEGIN
	v_csr_sid := GetOrCreateWebResource(v_www_sid, 'csr');
	v_wwwapp_sid := GetOrCreateWebResource(v_www_sid, 'app');
	v_site_sid := GetOrCreateWebResource(v_csr_sid, 'site');
	v_site_admin_sid := GetOrCreateWebResource(v_site_sid, 'admin');
	
	v_login_sid := GetOrCreateWebResource(v_site_sid, 'login.acds');
	security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), security.acl_pkg.GetDACLIDForSID(v_login_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_everyone_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	
	v_logout_sid := GetOrCreateWebResource(v_site_sid, 'blankLogout.acds');
	security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), security.acl_pkg.GetDACLIDForSID(v_logout_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_everyone_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	
	v_styles_sid := GetOrCreateWebResource(v_csr_sid, 'styles');
	security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), security.acl_pkg.GetDACLIDForSID(v_styles_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_everyone_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	v_shared_sid := GetOrCreateWebResource(v_csr_sid, 'shared');
	security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), security.acl_pkg.GetDACLIDForSID(v_shared_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_everyone_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	v_public_sid := GetOrCreateWebResource(v_csr_sid, 'public');
	security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), security.acl_pkg.GetDACLIDForSID(v_public_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_everyone_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);
END;

/* Audits */
PROCEDURE EnableAudits
AS
	v_admin_group_sid				security.security_pkg.T_SID_ID := GetOrCreateGroup('Administrators');
	v_everyone_group_sid			security.security_pkg.T_SID_ID := GetOrCreateGroup('Everyone');
	v_registered_users_sid			security.security_pkg.T_SID_ID := GetOrCreateGroup('RegisteredUsers');
	v_www_sid 						security.security_pkg.T_SID_ID := security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'wwwroot');
	
	v_csr_sid						security.security_pkg.T_SID_ID := GetOrCreateWebResource(v_www_sid, 'csr');
	v_site_sid						security.security_pkg.T_SID_ID := GetOrCreateWebResource(v_csr_sid, 'site');
	v_issues_sid					security.security_pkg.T_SID_ID;
	v_issues2_sid					security.security_pkg.T_SID_ID;
BEGIN
	/* Create required menu items */
	CreateCommonMenu;

	/* Web resources */
	CreateCommonWebResources;
	
	-- Required specifically for audits
	v_issues_sid := GetOrCreateWebResource(v_site_sid, 'issues');
	security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), security.acl_pkg.GetDACLIDForSID(v_issues_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	v_issues2_sid := GetOrCreateWebResource(v_site_sid, 'issues2');
	security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), security.acl_pkg.GetDACLIDForSID(v_issues2_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	enable_pkg.EnableAudit;
END;

PROCEDURE CreateAuditType(
	in_label						IN internal_audit_type.label%TYPE,
	in_flow_sid						IN internal_audit_type.flow_sid%TYPE DEFAULT NULL,
	in_audit_contact_role_sid		IN internal_audit_type.audit_contact_role_sid%TYPE DEFAULT NULL,
	in_auditor_role_sid				IN internal_audit_type.auditor_role_sid%TYPE DEFAULT NULL,
	out_audit_type_id				OUT internal_audit_type.internal_audit_type_id%TYPE
)
AS
BEGIN
	INSERT INTO internal_audit_type (internal_audit_type_id, label, internal_audit_type_source_id,
		flow_sid, audit_contact_role_sid, auditor_role_sid)
	VALUES (internal_audit_type_id_seq.NEXTVAL, in_label, 1 /* Internal */, in_flow_sid,
		in_audit_contact_role_sid, in_auditor_role_sid)
	RETURNING internal_audit_type_id INTO out_audit_type_id;
END;

PROCEDURE CreateAudit(
	in_label						IN	VARCHAR2,
	in_audit_type_id				IN	internal_audit_type.internal_audit_type_id%TYPE,
	out_sid							OUT	security.security_pkg.T_SID_ID
)
AS
	v_sid							security.security_pkg.T_SID_ID;
	v_auditor_user_sid				security.security_pkg.T_SID_ID := GetOrCreateUser('audit_coordinator');
	v_audit_so_sid					security.security_pkg.T_SID_ID := security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
	v_audit_region_sid				security.security_pkg.T_SID_ID := GetOrCreateRegion('AUDIT_REGION_1');
BEGIN
	security.securableobject_pkg.CreateSO(
		SYS_CONTEXT('SECURITY', 'ACT'),
		v_audit_so_sid,
		security.class_pkg.GetClassId('CSRAudit'),
		NULL, -- Don't make the name unique
		v_sid);
	
	INSERT INTO internal_audit (
		internal_audit_sid, region_sid, label, audit_dtm,
		auditor_user_sid, internal_audit_type_id, created_by_user_sid)
	VALUES (
		v_sid, v_audit_region_sid, in_label, SYSDATE,
		v_auditor_user_sid, in_audit_type_id, v_auditor_user_sid
	);
	
	out_sid := v_sid;
END;

PROCEDURE CreateAuditsNoWf(
	in_no_of_audits					IN	NUMBER DEFAULT 10
)
AS
	v_non_flow_at_id				csr.internal_audit_type.internal_audit_type_id%TYPE;
	v_sid_id						security.security_pkg.T_SID_ID;
BEGIN
	INSERT INTO csr.internal_audit_type (internal_audit_type_id, label, internal_audit_type_source_id)
	VALUES (csr.internal_audit_type_id_seq.NEXTVAL, 'Non WF audit', 1 /* Internal */)
	RETURNING internal_audit_type_id INTO v_non_flow_at_id;
	
	FOR i IN 1 .. 10
	LOOP
		CreateAudit('Non WF audit ' || i, v_non_flow_at_id, v_sid_id);
	END LOOP;
END;

/* Chain */
PROCEDURE EnableChain
AS
	v_admin_group_sid				security.security_pkg.T_SID_ID := GetOrCreateGroup('Administrators');
	v_everyone_group_sid			security.security_pkg.T_SID_ID := GetOrCreateGroup('Everyone');
	v_registered_users_sid			security.security_pkg.T_SID_ID := GetOrCreateGroup('RegisteredUsers');
	
	v_www_sid 						security.security_pkg.T_SID_ID := security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'wwwroot');
	v_csr_sid						security.security_pkg.T_SID_ID := GetOrCreateWebResource(v_www_sid, 'csr');
	v_site_sid						security.security_pkg.T_SID_ID := GetOrCreateWebResource(v_csr_sid, 'site');
	
	v_user_sid						security.security_pkg.T_SID_ID;
	v_menu_sid						security.security_pkg.T_SID_ID;
	v_alerts_sid					security.security_pkg.T_SID_ID;
BEGIN
	v_user_sid := unit_test_pkg.GetOrCreateUser('admin');

	CreateCommonMenu;
	
	v_menu_sid := GetOrCreateMenu(
		in_name => 'Login',
		in_so_name => 'login',
		in_pos => 100,
		in_action => '/csr/site/login.acds'
	);
	security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1, security.security_pkg.ACE_TYPE_DENY, 2,
		v_registered_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 2,
		v_everyone_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	
	v_menu_sid := GetOrCreateMenu(
		in_name => 'Logout',
		in_so_name => 'logout',
		in_pos => 101,
		in_action => '/fp/aspen/public/logout.aspx?page=%2fcsr%2fsite%2flogin.acds%3floggedoff%3d1'
	);
	security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 2,
		v_registered_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	
	CreateCommonWebResources;
	v_alerts_sid := GetOrCreateWebResource(v_site_sid, 'alerts');
	security.acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), security.acl_pkg.GetDACLIDForSID(v_alerts_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 3,
		v_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	
	enable_pkg.EnablePortal;
	chain.test_chain_utils_pkg.SetupTwoTier;
END;

PROCEDURE SetFlowCapability(
	in_flow_capability	NUMBER,
	in_flow_state_id 	NUMBER,
	in_permission_set	NUMBER,
	in_role_sid			NUMBER DEFAULT NULL,
	in_group_sid		NUMBER DEFAULT NULL
)
AS
BEGIN
	BEGIN
		INSERT INTO csr.flow_state_role(flow_state_id, group_sid, is_editable, role_sid)
			VALUES (in_flow_state_id, in_group_sid, 1, in_role_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO flow_state_role_capability(flow_state_rl_cap_id, flow_state_id, group_sid, role_sid,
			flow_capability_id, permission_set)
			VALUES (flow_state_rl_cap_id_seq.NEXTVAL, in_flow_state_id, in_group_sid, in_role_sid, in_flow_capability, in_permission_set);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE flow_state_role_capability
			   SET permission_set = in_permission_set
			 WHERE flow_state_id = in_flow_state_id
			   AND flow_capability_id = in_flow_capability
			   AND (group_sid = in_group_sid OR in_group_sid IS NULL)
			   AND (role_sid = in_role_sid OR in_role_sid IS NULL);
	END;
END;

PROCEDURE GetELCIncidentData (
	in_instance_id			IN 	NUMBER,
	out_cur					OUT	security.security_pkg.T_OUTPUT_CUR
)AS
	v_last_run_dtm			DATE;
	v_exp_class_sid			NUMBER;
BEGIN
--get the last run date
	SELECT automated_export_class_sid 
	  INTO v_exp_class_sid
	  FROM csr.automated_export_instance 
	 WHERE automated_export_instance_id = in_instance_id;
	 
	SELECT MAX(bj.completed_dtm)
	  INTO v_last_run_dtm
	  FROM csr.automated_export_instance aei
	  JOIN csr.batch_job bj ON bj.batch_job_id = aei.batch_job_id
	 WHERE aei.automated_export_class_sid = v_exp_class_sid 
	   AND (aei.is_preview = 0 AND bj.result LIKE 'The export completed successfully')
	   AND automated_export_instance_id <> in_instance_id;

	OPEN out_cur FOR
		SELECT '02' "Area", 
				123 "Abstract", 
				'i.region_city' "AccidentCity",
				'i.region_state' "AccidentState",  
				'r.description' "Account", 
				124 "AgentofLoss",
				'2024/04/26 12:34' "CommitTime",
				'New York' "CustomerCity",
				'New York' "CustomerState",
				'2024/04/26 12:35' "DateReported",
				'i.injury_how_did_the_incident' "Description", 
				125 "DetailLossLocation", 
				'0000' "SiteCode", 
				NULL "Source",
				'0000000378' "SSCGID", 
				'i.lastname' "LastName", 
				'a.label' "ClaimSubtype",
				'cp.zlabel' "CustomerPremises",
				'i.region_employer' "Employer", 
				'New York' "EmployerCity",
				'New York' "EmployerState",
				'lt.zlabel' "LostTime", 
				'rtw.zlabel' "RTWIndicator", 
				'i.natureofinjury_id' "NatureofInjury", 
				'i.bodypart_id' "BodyPart",
				'i.injurydescription' "InjuryDescription",
				'i.regularoccupation' "InjuryOccupation",
				'i.regularoccupation' "RegularOccupation",
				'p.name' "AccidentCountry",
				'i.region_address1' "AccidentStreetAddress",
				'i.region_zip' "AccidentZip",
				NULL "AuthoritiesContacted",
				'i.state' "BenefitState",
				NULL "CATCode",
				'New York' "City",
				'United States' "Country",
				NULL "CustomerAtFault",
				NULL "CustomerRefNumber",
				'7 Corporate Center Drive' "CustomerAddr1",
				'Attn: Cori Dayton' "CustomerAddr2",
				'United States' "CustomerCountry",
				'The Estee Lauder Companies' "CustomerName",
				'11747' "CustomerZip",
				'i.region_policynum' "CustPrvdPolNbr",
				'disabilitymanagement@estee.com' "EmailAddress", 
				NULL "EnvironmentalIndicator",
				NULL "ExposureType",
				NULL "FEIN", 
				NULL "FileId",
				'io.zlabel' "IncidentReportOnly",
				NULL "INSRequestedBy",
				'i.insuredcontactfaxnumber' "InsuredContactFaxNumber",
				'i.insuredcontactname' "InsuredContactName",
				'i.insuredcontactphonenumber' "InsuredContactPhoneNumber", 
				NULL "Lawsuit",
				NULL "OSHANumber",
				'The Estee Lauder Companies' "ParentAccountName",
				NULL "PhoneNumber",
				'i.region_zip' "PostalCode",
				'i.screening_your_name' "ReportedByName",
				NULL "ReportedByPhoneNumber",
				NULL "RowStatus",
				NULL "SRNumber",
				'i.region_state' "State",
				NULL "Status",
				'i.region_address1' "StreetAddress",-- Pending with client
				NULL "SubStatus",
				NULL "ViolationsIssued",
				'i.firstname' "FirstName",
				'01/02/2023' "BirthDate",
				NULL "ContactId",
				NULL "DependentCount",
				NULL "ClaimantEmailAddress",
				NULL "ClaimantFaxPhone", 
				'i.recordability_emp_phone' "ClaimantHomePhone",
				'i.recordability_gender' "M-F", 
				NULL "ClaimantMaritalStatus", 
				NULL "ClaimantMiddleName", 
				NULL "ClaimantNamePrefix", 
				NULL "ClaimantNameSuffix", 
				NULL "ClaimantParticipantAge", 
				'i.socialsecuritynumber' "SocialSecurityNumber",
				NULL "ClaimantWorkPhone",  
				'i.city' "ClaimantCity",
				'i.country' "ClaimantCountry",
				'i.postalcode' "ClaimantPostalCode",
				'i.state' "ClaimantState", 
				'i.personalstreetaddress' "ClaimantStreetAddress",
				NULL "PersonId",
				'Injured Employee' "Role",
				NULL "GLCategory",
				NULL "Actual-Estimated",
				NULL "Days-Week",
				NULL "DeptNumber",
				NULL "DisabilityDate",
				NULL "DrugScreenProgramId",
				'i.employeeid' "EmployeeId",
				'United States' "EmployerCountry",
				NULL "EmployerisCustomer",
				'01/02/2023' "EmployerNotifiedDate",
				NULL "EmployerPhoneNumber",
				NULL "EmployerStreetAddress",
				NULL "EmployerTaxId",
				'11747' "EmployerZip",
				'es.zlabel' "EmploymentStatus",
				NULL "EstReturntoWorkDate", 
				'01/02/2024' "HireDate",
				NULL "Hourly-Weekly", 
				NULL "Hours-Day", 
				'01/02/2025' "LastDayWorked",
				NULL "LastDrugResultIndicator",
				NULL "LastExpoDate",
				NULL "OtherRemuneration",
				NULL "PaidThruDate",
				NULL "ReleasedtoWorkDate",
				NULL "RemunerationAmount",
				'01/03/2023' "ReturnedtoWork",
				127 "RTWQualifier",
				NULL "SafeguardsProvided",
				NULL "SafeguardsUsed",
				NULL "SalaryContinued",
				NULL "SupervisorName",
				NULL "SupervisorPhoneNumber",
				'i.recordability_avg_wage' "WageAmountDisplayed",
				NULL "WagesfromOtherEmployment",
				NULL "WeeksWorkedLast12months",
				NULL "HospitalCity",
				NULL "HospitalCountry",
				NULL "HospitalEmailAddress",
				NULL "HospitalFaxNumber",
				NULL "HospitalName",
				NULL "HospitalPhoneNumber",
				NULL "HospitalState",
				NULL "HospitalStreetAddress",
				NULL "HospitalZip",
				NULL "PhysicianCity",
				NULL "PhysicianLastName",
				NULL "PhysicianPhoneNumber",
				NULL "PhysicianState",
				NULL "PhysicianStreetAddress",
				NULL "PhysicianZip", 
				'i.region_sic' "SICCode",
				NULL "AccidentCauseDeath",
				NULL "CauseofInjury",
				NULL "DateofDeath",
				NULL "ICD9Indicator",
				126 "InitialTreatment",
				NULL "InjuryLocation", 
				NULL "LifeFlight-MedEvac",
				NULL "Pre-ExistingCondition",
				NULL "SevereInjury",
				NULL "SurgeryIndicator"
		  FROM DUAL;

END;

PROCEDURE AnonymiseUser(
	in_user_sid				IN	csr.csr_user.csr_user_sid%TYPE
)
AS
BEGIN
	csr.csr_user_pkg.anonymiseUser(security.security_pkg.GetAct, in_user_sid);
END;

PROCEDURE DeactivateUser(
	in_user_sid				IN	csr.csr_user.csr_user_sid%TYPE
)
AS
BEGIN
	csr.csr_user_pkg.deactivateUser(security.security_pkg.GetAct, in_user_sid);
END;

END;
/
