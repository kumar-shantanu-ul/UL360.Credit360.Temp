CREATE OR REPLACE PACKAGE chain.test_chain_capability_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE SetSite(in_site_name VARCHAR2);

PROCEDURE SetUp;

PROCEDURE TearDown;

PROCEDURE TearDownFixture;

PROCEDURE Test_PurchaserInvolvement;

PROCEDURE Test_PrimPurchaserInvolvement;

PROCEDURE Test_OwnerInvolvement;

PROCEDURE Test_RoleInvolvement;

PROCEDURE Test_RoleWithPrimaryInv;

PROCEDURE Test_RoleWithOwnerInv;

PROCEDURE Test_SpecificPurchaser;

PROCEDURE Test_SpecificSupplier;

PROCEDURE Test_SpecificPurAndSupp;

PROCEDURE Test_DeletedRelationship;

PROCEDURE Test_CapabilityGroups;

END;
/