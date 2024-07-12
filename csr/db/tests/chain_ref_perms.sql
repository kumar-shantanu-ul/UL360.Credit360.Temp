SET SERVEROUTPUT ON
SET ECHO OFF

@@chain_ref_perms\build

DECLARE
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	security.user_pkg.logonadmin(:bv_site_name);

	chain.test_ref_perms_pkg.TearDown;
	chain.test_ref_perms_pkg.TearDownFixture;
	COMMIT;
END;
/

BEGIN
 	-- Run tests in package
 	csr.unit_test_pkg.RunTests(
		in_pkg					=> 'chain.test_ref_perms_pkg',
		in_tests				=> csr.unit_test_pkg.T_TESTS(
			'TestCannotSetRefsWithNoPerms',
			'TestCanSetRefsWithGroupPerms',
			'TestCanSetRefsWithRolePerms',
			'TestCannotSetRefsWithROPerms',
			'TestRefPermsApplyByRef',
			'TestCannotSetRefForBadCompType',
			'TestChainAdminsGetBestPerms'
		),
		in_site_name			=> :bv_site_name
 	);
END;
/

--No need to keep the test fixture package after tests have ran
DROP PACKAGE chain.test_ref_perms_pkg;

SET ECHO ON
