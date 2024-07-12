SET SERVEROUTPUT ON
SET ECHO OFF

@@chain_bus_rel\build

DECLARE
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	chain.test_bus_rel_pkg.SetSite(:bv_site_name);
	chain.test_bus_rel_pkg.TearDown;
	chain.test_bus_rel_pkg.TearDownFixture;
	COMMIT;
END;
/

BEGIN
 	-- Run tests in package
 	csr.unit_test_pkg.RunTests(
		in_pkg					=> 'chain.test_bus_rel_pkg',
		in_tests				=> csr.unit_test_pkg.T_TESTS(
									'TestCreateBusRel','TestDeleteBusRel','TestDelBusRelExpctAccessDnied1','TestDelBusRelExpctAccessDnied2','TestDelBusRelExpctAccessDnied3',
									'TestDelBusRelExpctAccessDnied4','TestDelBusRelExpctAccessDnied5'
								   ),
		in_site_name			=> :bv_site_name
 	);
END;
/

--No need to keep the test fixture package after tests have ran
DROP PACKAGE chain.test_bus_rel_pkg;

SET ECHO ON
