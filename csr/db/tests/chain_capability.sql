SET SERVEROUTPUT ON
SET ECHO OFF

@chain_capability\test_chain_capability_pkg
@chain_capability\test_chain_capability_body

BEGIN
	--we need to tear down everything in case the previous execution failed
	chain.test_chain_capability_pkg.SetSite(:bv_site_name);
	chain.test_chain_capability_pkg.TearDown;
	chain.test_chain_capability_pkg.TearDownFixture;
END;
/

GRANT EXECUTE ON chain.test_chain_capability_pkg TO CSR;

BEGIN
	-- Run tests in package
	csr.unit_test_pkg.RunTests('chain.test_chain_capability_pkg', csr.unit_test_pkg.T_TESTS(
		'Test_PurchaserInvolvement','Test_PrimPurchaserInvolvement','Test_OwnerInvolvement','Test_RoleInvolvement',
		'Test_RoleWithPrimaryInv','Test_RoleWithOwnerInv','Test_SpecificPurchaser','Test_SpecificSupplier','Test_SpecificPurAndSupp',
		'Test_DeletedRelationship','Test_CapabilityGroups'), :bv_site_name
	);
END;
/


DROP PACKAGE chain.test_chain_capability_pkg;

SET ECHO ON
