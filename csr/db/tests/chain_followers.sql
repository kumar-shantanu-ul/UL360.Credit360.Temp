SET SERVEROUTPUT ON
SET ECHO OFF

@@chain_followers\build

BEGIN
	chain.test_followers_role_pkg.TearDown;
	chain.test_followers_role_pkg.TearDownFixture;
	COMMIT;
END;
/

BEGIN
 	-- Run tests in package
 	csr.unit_test_pkg.RunTests(
		in_pkg					=> 'chain.test_followers_role_pkg',
		in_tests				=> csr.unit_test_pkg.T_TESTS(
									'TestRoleGetsDeletedWhenRelaDel'
								),
		in_site_name			=> :bv_site_name
 	);

END;
/

--No need to keep the test fixture package after tests have ran
DROP PACKAGE chain.test_followers_role_pkg;

SET ECHO ON