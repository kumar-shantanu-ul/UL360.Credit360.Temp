CREATE OR REPLACE PACKAGE chain.test_chain_user_dedupe_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE SetSite(in_site_name VARCHAR2);

PROCEDURE SetUp;

PROCEDURE TearDown;

PROCEDURE TearDownFixture;

PROCEDURE Test_UserImport;

PROCEDURE Test_ImportExistingUser;

PROCEDURE Test_MandatoryFields;

PROCEDURE Test_CmsAndUserImport;

PROCEDURE Test_CmsAndUserImportManual;

PROCEDURE Test_PriorityFullFriendly;

PROCEDURE Test_CTRoles;

PROCEDURE Test_CTRoles2;

PROCEDURE Test_ImportUserNowAnonymised;

END;
/