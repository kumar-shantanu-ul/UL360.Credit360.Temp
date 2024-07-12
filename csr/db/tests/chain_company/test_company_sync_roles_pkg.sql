CREATE OR REPLACE PACKAGE chain.test_company_sync_roles_pkg AS

PROCEDURE SetUpFixture;

PROCEDURE TearDownFixture;

PROCEDURE SetUp;

PROCEDURE TearDown;

-- Tests
PROCEDURE TestCascadeRole;

END;
/