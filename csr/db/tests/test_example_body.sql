CREATE OR REPLACE PACKAGE BODY CSR.test_example_pkg AS

v_site_name				VARCHAR2(200);
v_region_1_sid			security_pkg.T_SID_ID;
v_ind_1_sid				security_pkg.T_SID_ID;
v_user_1_sid			security_pkg.T_SID_ID;
v_deleg_1_sid			security_pkg.T_SID_ID;

PROCEDURE CreateDelegChkUserPerms
AS
	v_regs		security_pkg.T_SID_IDS;
	v_inds		security_pkg.T_SID_IDS;
	v_count				NUMBER(10);
	v_act				security_pkg.T_ACT_ID;
BEGIN
	-- Optionally can set a more meaningful name than the procedure name
	unit_test_pkg.StartTest('csr.test_user_cover_pkg.AuditCoverTwoUsersCoveringSameUser');
	
	-- Create delegation
	v_regs(1) := v_region_1_sid;
	v_inds(1) := v_ind_1_sid;
	v_deleg_1_sid := unit_test_pkg.GetOrCreateDeleg('USER_COVER_DELEG_1', v_regs, v_inds);
	
	-- Create a user and create an ACT as that user
	v_user_1_sid := unit_test_pkg.GetOrCreateUser('USER_1');
	v_act := security.user_pkg.GenerateACT(); 
	security.act_pkg.Issue(v_user_1_sid, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	
	IF delegation_pkg.CheckDelegationPermission(v_act, v_deleg_1_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		unit_test_pkg.TestFail('User has access to delegation before user was added to delegation');
	END IF;
	
	-- Add user to delegation
	delegation_pkg.UNSEC_AddUser(security_pkg.GetAct, v_deleg_1_sid, v_user_1_sid);
	
	-- Check that the user is now in the delegation_user table
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_user
	 WHERE delegation_sid = v_deleg_1_sid
	   AND user_sid = v_user_1_sid;
	
	unit_test_pkg.AssertAreEqual(1, v_count, 'User was not added to delegation_user table');
	
	-- re-issue ACT for user their group membership has changed
	security.act_pkg.ReIssue(v_act, SYS_CONTEXT('SECURITY','APP'));
	
	IF NOT delegation_pkg.CheckDelegationPermission(v_act, v_deleg_1_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		unit_test_pkg.TestFail('User does not have access to delegation');
	END IF;
	
END;

PROCEDURE SetUp
AS
BEGIN
	-- It's safest to log in once per test as well
	security.user_pkg.logonadmin(v_site_name);
	
	-- Un-set the Built-in admin's user sid from the session,
	-- otherwise all permissions tests against any ACT will return true
	-- because of the internal workings of security pkgs
	security_pkg.SetContext('SID', NULL);
END;

PROCEDURE TearDown
AS
BEGIN
	-- Check for and remove any objects that get created in a test
	IF v_deleg_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_deleg_1_sid);
		v_deleg_1_sid := NULL;
	END IF;
	
	IF v_user_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_user_1_sid);
		v_user_1_sid := NULL;
	END IF;
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
	-- Log on to test site
	security.user_pkg.logonadmin(v_site_name);
	
	-- Set up regions + inds once per fixture. Uses helper functions
	-- on unit_test_pkg to get or create objects with minimal lines of code
	v_region_1_sid := unit_test_pkg.GetOrCreateRegion('USER_COVER_REGION_1');
	v_ind_1_sid := unit_test_pkg.GetOrCreateInd('USER_COVER_IND_1');
END;

PROCEDURE TearDownFixture
AS
BEGIN
	-- Clear down data after all tests have ran
	IF v_region_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_region_1_sid);
		v_region_1_sid := NULL;
	END IF;
	
	IF v_ind_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_ind_1_sid);
		v_ind_1_sid := NULL;
	END IF;
END;

END;
/