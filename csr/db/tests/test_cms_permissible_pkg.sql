CREATE OR REPLACE PACKAGE cms.test_cms_permissible_pkg AS

PROCEDURE A_With_UserInCol_GetAccess;
PROCEDURE B_With_CoverUserInCol_GetAccess;
PROCEDURE C_With_CoverMultiUserInCol_GetAccess;
PROCEDURE D_With_MultiState_UserInCol_GetAccess;

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE SetUp;

PROCEDURE TearDownFixture;

END;
/