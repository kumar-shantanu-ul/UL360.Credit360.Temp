CREATE OR REPLACE PACKAGE BODY CSR.test_target_planning_pkg AS

v_site_name				VARCHAR2(200);

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
	NULL;
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
	-- Log on to test site
	security.user_pkg.logonadmin(v_site_name);
	
	-- Set up regions + inds once per fixture. Uses helper functions
	-- on unit_test_pkg to get or create objects with minimal lines of code
END;

PROCEDURE TearDownFixture
AS
BEGIN
	-- Clear down data after all tests have ran
	NULL;
END;

PROCEDURE TestCanary
AS
	v_act				security_pkg.T_ACT_ID;
BEGIN
	-- Optionally can set a more meaningful name than the procedure name
	unit_test_pkg.StartTest('csr.test_target_planning_pkg.TestCanary');
	
	target_planning_pkg.Canary;

	unit_test_pkg.AssertAreEqual(1, 1, 'test');
	
END;



END;
/