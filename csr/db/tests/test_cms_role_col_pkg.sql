CREATE OR REPLACE PACKAGE cms.test_cms_role_col_pkg AS

PROCEDURE With_UserInRole_GetAccess;

PROCEDURE With_UserNotInRole_TestFail;

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE SetUp;

PROCEDURE TearDown;

END;
/