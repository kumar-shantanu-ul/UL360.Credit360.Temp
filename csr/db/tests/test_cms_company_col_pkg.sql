CREATE OR REPLACE PACKAGE cms.test_cms_company_col_pkg AS

PROCEDURE With_UserInCompany_GetAccess;

PROCEDURE With_UserNotInCompany_TestFail;

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE SetUp;

PROCEDURE TearDown;

END;
/