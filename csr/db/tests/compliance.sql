SET SERVEROUTPUT ON
SET ECHO OFF

@@test_compliance_pkg
@@test_compliance_body

BEGIN
	security.user_pkg.logonadmin(:bv_site_name);
	csr.unit_test_pkg.RunTests('csr.test_compliance_pkg', csr.unit_test_pkg.T_TESTS(
		'TestTempCompLevelsNone',
		'TestTempCompLevelsOneManyOverflow',
		'TestCreateRolloutInfo',
		'TestUpdateRegulationFailsWhenDuplicateVers',
		'TestClearingVersionHistoryWorksForReg',
		'TestUpdateRequirementFailsWhenDuplicateVers',
		'TestClearingVersionHistoryWorksForReq',
		'TestSingleTagWithSingleExclusion',
		'TestSingleTagWithNoExclusion',
		'TestMultipleTagsWithSomeExclusion',
		'TestMultipleTagsWithAllExclusion',
		'TestRequirementWithSingleExclusion'
	), :bv_site_name);
END;
/

DROP PACKAGE csr.test_compliance_pkg;

SET ECHO ON
