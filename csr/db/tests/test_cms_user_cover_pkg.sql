CREATE OR REPLACE PACKAGE cms.test_cms_user_cover_pkg AS

PROCEDURE CmsCoverCoverableColGetsCvr;

PROCEDURE CmsCoverNonCoverableNoCvr;

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE SetUp;

PROCEDURE TearDown;

END;
/