CREATE OR REPLACE PACKAGE chain.test_company_user_pkg AS

PROCEDURE SetUpFixture;

PROCEDURE TearDownFixture;

PROCEDURE SetUp;

PROCEDURE TearDown;

-- Tests
PROCEDURE TestUserWithPromoteUserCanAddRoles;
PROCEDURE TestUserWithPromoteUserCanRemoveRoles;
PROCEDURE TestUserWithoutPromoteUserCannotAddRoles;
PROCEDURE TestUserWithoutPromoteUserCannotRemoveRoles;
PROCEDURE TestAdminCanAddRoles;
PROCEDURE TestAdminCanRemoveRoles;

END;
/
