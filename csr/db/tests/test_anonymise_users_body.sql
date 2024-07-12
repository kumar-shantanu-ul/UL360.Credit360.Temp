CREATE OR REPLACE PACKAGE BODY csr.test_anonymise_users_pkg AS

/* private Setup, TearDown and helpers */

PROCEDURE SetAutoAnonymisation(
	in_enabled				IN	NUMBER,
	in_days_before_anon		IN	NUMBER
)
AS
BEGIN
	UPDATE csr.customer
	   SET auto_anonymisation_enabled = in_enabled, inactive_days_before_anonymisation = in_days_before_anon
	 WHERE app_sid = security.security_pkg.GetApp;
END;

PROCEDURE DeleteDataCreatedDuringTests
AS
	v_act_id					security.security_pkg.T_ACT_ID;
	v_user_sid					NUMBER;
BEGIN
	v_act_id := sys_context('security','act');
	-- delete and reset data that could have been created during tests, in case of previously aborted/failed runs.

	FOR r IN (
		SELECT u.csr_user_sid
		  FROM csr_user u
		  JOIN security.user_table s ON u.csr_user_sid = s.sid_id
		 WHERE app_sid = security.security_pkg.GetApp
		   AND (u.anonymised = 1 OR s.account_disabled_dtm IS NOT NULL)
	)
	LOOP
		csr.csr_user_pkg.DeleteObject(
			in_act => v_act_id,
			in_sid_id=> r.csr_user_sid
		);
	END LOOP;
END;

PROCEDURE SetInactivatedDate (
	in_user_sid		IN			NUMBER,
	in_date			IN			DATE
)
AS
BEGIN
	UPDATE security.user_table
	   SET account_disabled_dtm = in_date
	 WHERE sid_id = in_user_sid;				
END;

FUNCTION CursorRowCount (
	in_cur	IN	SYS_REFCURSOR
) RETURN NUMBER
AS
	v_cur_sid		NUMBER;
	v_count			NUMBER;
BEGIN
	v_count := 0;

	LOOP 
		FETCH in_cur INTO v_cur_sid;
		EXIT WHEN in_cur%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;
	CLOSE in_cur;
	
	RETURN v_count;
END;

FUNCTION CreateUser (
	v_filler			VARCHAR2,
	v_create_profile	BOOLEAN
) RETURN security_pkg.T_SID_ID
AS
	v_user_sid					security_pkg.T_SID_ID;
BEGIN

	IF (v_create_profile = TRUE) THEN
		v_user_sid := csr.unit_test_pkg.GetOrCreateUserAndProfile(v_filler, v_filler, v_filler, v_filler||'@credit360.com', NULL, NULL, NULL, v_filler, NULL, NULL);
	ELSE
		v_user_sid := csr.unit_test_pkg.GetOrCreateUser(v_filler, NULL, NULL);
	END IF;
	
	UPDATE csr.csr_user	 
	   SET full_name = v_filler,
		   phone_number = v_filler
	 WHERE app_sid = security.security_pkg.GetApp
	   AND csr_user_sid = v_user_sid;
	 
	RETURN v_user_sid;
END;

FUNCTION CreateMultipleUserAndProfile (
	in_filler			IN		VARCHAR2,
	in_count			IN		NUMBER,
	in_deactivated_on	IN		DATE
) RETURN csr.test_user_sids
AS
	v_users					csr.test_user_sids := csr.test_user_sids();
	v_user_sid				security_pkg.T_SID_ID;
	v_user_filler			VARCHAR2(32);
BEGIN

	FOR i IN 1..in_count
	LOOP
		v_user_filler := in_filler || '_' || i;
		v_user_sid := CreateUser(v_user_filler, TRUE);
		v_users.extend;
		v_users(i) := v_user_sid;
		
		IF in_deactivated_on IS NOT NULL THEN
			csr.unit_test_pkg.DeactivateUser(v_user_sid);
			SetInactivatedDate(v_user_sid, in_deactivated_on);
		END IF;
	END LOOP;
 
	RETURN v_users;
END;

FUNCTION IsValidlyAnonymised (
	in_user_sid		IN			NUMBER,
	in_filler		IN			VARCHAR2
) RETURN BOOLEAN
AS
	v_count						NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.csr_user
	 WHERE app_sid = security.security_pkg.GetApp
	   AND csr_user_sid = in_user_sid
	   AND email != CONCAT(in_filler, '@credit360.com')
	   AND user_name != in_filler
	   AND full_name != in_filler
	   AND friendly_name != in_filler
	   AND job_title != in_filler
	   AND phone_number != in_filler
	   AND anonymised = 1;
	 
	RETURN v_count = 1;
END;

FUNCTION UserIsAnonymised (
	in_user_sid		IN			NUMBER
) RETURN BOOLEAN
AS
	v_count						NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.csr_user
	 WHERE app_sid = security.security_pkg.GetApp
	   AND csr_user_sid = in_user_sid
	   AND anonymised = 1;
	
	RETURN v_count = 1;
END;

/* Fixture Setup, TearDown */

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	--dbms_output.put_line('SetUpFixture');
	security.user_pkg.logonadmin(in_site_name);
	DeleteDataCreatedDuringTests;
END;

PROCEDURE TearDownFixture AS
BEGIN 
	--dbms_output.put_line('TearDownFixture');
	DeleteDataCreatedDuringTests;
END;

/* Per test Setup, TearDown */

PROCEDURE SetUp AS
BEGIN
	--dbms_output.put_line('SetUp');
	NULL;
END;

PROCEDURE TearDown AS
BEGIN
	--dbms_output.put_line('TearDown');
	NULL;
END;

/* Tests */

PROCEDURE Test01AnonymiseUserNotAnonymised AS
	v_user_sid					NUMBER;
	v_filler					VARCHAR2(128)	:= 'abc9876';
	v_is_anonymised				BOOLEAN;
BEGIN
	-- create user with user profile	
	v_user_sid := CreateUser(v_filler, TRUE);

	-- assert that user is not anonymised when still active
	csr.unit_test_pkg.AnonymiseUser(v_user_sid);
	v_is_anonymised := UserIsAnonymised(v_user_sid);
	csr.unit_test_pkg.AssertIsFalse(v_is_anonymised, 'User anonymised when user is still active.');
END;

PROCEDURE Test02AnonymiseUserWithoutProfile AS
	v_user_sid					NUMBER;
	v_filler					VARCHAR2(128)	:= 'abc9876';
	v_columns_anonymised		BOOLEAN;
BEGIN
	-- create user without user profile	
	v_user_sid := CreateUser(v_filler, FALSE);
	
	-- assert that user has been validly anonymised and profile has been deleted when user is deactivated and anonymised
	csr.unit_test_pkg.DeactivateUser(v_user_sid);
	csr.unit_test_pkg.AnonymiseUser(v_user_sid);

	v_columns_anonymised := IsValidlyAnonymised(v_user_sid, v_filler);
	csr.unit_test_pkg.AssertIsTrue(v_columns_anonymised, 'User columns not validly anonymised.');
END;

PROCEDURE Test03AnonymiseUserWithProfile AS
	v_user_sid					NUMBER;
	v_filler					VARCHAR2(128)	:= 'abc9876';
	v_columns_anonymised		BOOLEAN;
	v_profile_count				NUMBER;
BEGIN
	-- create user with user profile	
	v_user_sid := CreateUser(v_filler, TRUE);
	
	-- assert that user has been validly anonymised and profile has been deleted when user is deactivated and anonymised
	csr.unit_test_pkg.DeactivateUser(v_user_sid);
	csr.unit_test_pkg.AnonymiseUser(v_user_sid);

	v_columns_anonymised := IsValidlyAnonymised(v_user_sid, v_filler);
	csr.unit_test_pkg.AssertIsTrue(v_columns_anonymised, 'User columns not validly anonymised.');

	SELECT COUNT(*)
	  INTO v_profile_count
	  FROM csr.user_profile
	 WHERE app_sid = security.security_pkg.GetApp
	   AND csr_user_sid = v_user_sid;
		
	csr.unit_test_pkg.AssertAreEqual(0, v_profile_count, 'User profile not deleted after user anonymisation.');
END;

PROCEDURE Test04AnonymiseTrashedUser AS
	v_act_id					security.security_pkg.T_ACT_ID;
	v_user_sid					NUMBER;
	v_filler					VARCHAR2(128)	:= 'abc9876';
	v_is_anonymised				BOOLEAN;
BEGIN
	v_act_id := sys_context('security','act');

	-- create user with user profile	
	v_user_sid := CreateUser(v_filler, TRUE);
		
	-- trash the user
	csr.csr_user_pkg.DeleteUser(
		in_act						=> v_act_id,
		in_user_sid					=> v_user_sid
	);

	-- anonymise the trashed user
	csr.unit_test_pkg.AnonymiseUser(v_user_sid);

	-- confirm that trashed user has been anonymised
	v_is_anonymised := UserIsAnonymised(v_user_sid);
	csr.unit_test_pkg.AssertIsTrue(v_is_anonymised, 'Trashed user not anonymised.');
END;

PROCEDURE Test05NotEligibleForAnonymisation AS
	v_disabled_days_ago			NUMBER			:= 20;
	v_auto_anon_after_days		NUMBER			:= 10;
	v_eligible_users_count		NUMBER;
	v_eligible_users_cur		SYS_REFCURSOR;
	v_users_eligible			csr.test_user_sids;
	v_users_not_eligible		csr.test_user_sids;
BEGIN
	-- disable auto-anonymisation
	SetAutoAnonymisation(0, 0);

	-- create 5 users with account deactivated before cutoff date
	v_users_eligible := CreateMultipleUserAndProfile('_to_anonymise', 5, SYSDATE - v_disabled_days_ago);
		
	-- create 7 users with account deactivated after cutoff date
	v_users_not_eligible := CreateMultipleUserAndProfile('_not_anonymise', 7, SYSDATE - v_auto_anon_after_days + 1);

	-- confirm that no users are eligible
	csr_user_pkg.UsersEligibleForAnonymisation(v_eligible_users_cur); 
	v_eligible_users_count := CursorRowCount(v_eligible_users_cur);
	csr.unit_test_pkg.AssertAreEqual(0, v_eligible_users_count, 'Incorrect count of users eligible for anonymisation.');
END;

PROCEDURE Test06EligibleCutoffDate AS
	v_disabled_days_ago			NUMBER			:= 20;
	v_auto_anon_after_days		NUMBER			:= 10;
	v_eligible_users_count		NUMBER;
	v_eligible_users_cur		SYS_REFCURSOR;
	v_users_eligible			csr.test_user_sids;
	v_users_not_eligible		csr.test_user_sids;
BEGIN
	-- create 5 users with account deactivated before cutoff date
	v_users_eligible := CreateMultipleUserAndProfile('_to_anonymise', 5, SYSDATE - v_disabled_days_ago);
		
	-- create 7 users with account deactivated after cutoff date
	v_users_not_eligible := CreateMultipleUserAndProfile('_not_anonymise', 7, SYSDATE - v_auto_anon_after_days + 1);

	-- enable auto-anonymisation
	SetAutoAnonymisation(1, v_auto_anon_after_days);

	-- confirm that 0 users would be anonymised if cutoff date is 100 days ago 
	csr_user_pkg.CountOfUsersEligibleForAnonymisation(100, v_eligible_users_count);
	csr.unit_test_pkg.AssertAreEqual(0, v_eligible_users_count, 'Incorrect count of users eligible for anonymisation.');
	
	-- confirm that 5 users would be anonymised if the cutoff date was v_auto_anon_after_days days ago 
	csr_user_pkg.CountOfUsersEligibleForAnonymisation(v_auto_anon_after_days, v_eligible_users_count);
	csr.unit_test_pkg.AssertAreEqual(5, v_eligible_users_count, 'Incorrect count of users eligible for anonymisation.');
END;

PROCEDURE Test07EligibleUsersMatchExpectedUsers AS
	v_disabled_days_ago			NUMBER			:= 20;
	v_auto_anon_after_days		NUMBER			:= 10;
	v_eligible_users_count		NUMBER;
	v_eligible_users_cur		SYS_REFCURSOR;
	v_users_eligible			csr.test_user_sids;
	v_users_not_eligible		csr.test_user_sids;
	v_cur_sid					NUMBER;
	v_count_valid 				NUMBER;
BEGIN
	-- create 5 users with account deactivated before cutoff date
	v_users_eligible := CreateMultipleUserAndProfile('_to_anonymise', 5, SYSDATE - v_disabled_days_ago);
		
	-- create 7 users with account deactivated after cutoff date
	v_users_not_eligible := CreateMultipleUserAndProfile('_not_anonymise', 7, SYSDATE - v_auto_anon_after_days + 1);

	-- enable auto-anonymisation
	SetAutoAnonymisation(1, v_auto_anon_after_days);

	-- check users eligible for anonymisation are expected users	
	csr_user_pkg.UsersEligibleForAnonymisation(v_eligible_users_cur); 
	v_eligible_users_count := CursorRowCount(v_eligible_users_cur);
	 
	-- confirm the expected number of users are eligible
	csr.unit_test_pkg.AssertAreEqual(5, v_eligible_users_count, 'Incorrect count of users eligible for anonymisation.');

	-- we also need to check the user sids are the expected user sids	
	csr_user_pkg.UsersEligibleForAnonymisation(v_eligible_users_cur); 
	v_count_valid := 0;
	
	BEGIN
		LOOP 
			FETCH v_eligible_users_cur INTO v_cur_sid;
			EXIT WHEN v_eligible_users_cur%NOTFOUND;

			-- check that the user sid is expectd	
			FOR i in 1..v_users_eligible.COUNT LOOP
				IF v_users_eligible(i) = v_cur_sid THEN
					v_count_valid := v_count_valid + 1;
					-- we NULL the element from the array so that we do not count it
					-- a second time which could happen
					-- if v_eligible_users_cur incorrectly contains duplicate rows
					v_users_eligible(i) := NULL;
				END IF;
			END LOOP;

		END LOOP;
		CLOSE v_eligible_users_cur;
	END;

	csr.unit_test_pkg.AssertAreEqual(v_users_eligible.COUNT, v_count_valid, 'User sids eligible for anonymisation do not match expected user sids.');	
END;

END test_anonymise_users_pkg;
/
