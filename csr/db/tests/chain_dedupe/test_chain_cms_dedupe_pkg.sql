CREATE OR REPLACE PACKAGE chain.test_chain_cms_dedupe_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE SetSite(in_site_name VARCHAR2);

PROCEDURE SetUp;

PROCEDURE TearDown;

PROCEDURE TearDownFixture;

PROCEDURE Test_ParseCmsData;

PROCEDURE Test_ParseEnumData;

PROCEDURE Test_ProcessRecord;

PROCEDURE Test_TwoSourcesSameDest;

PROCEDURE Test_TwoSourcesDiffDest;

PROCEDURE Test_ProcessWithMissingMand;

PROCEDURE Test_MergeCmsData;

PROCEDURE Test_ChildCmsDataCreate;

PROCEDURE Test_ChildCmsDataCreateUpdate;

PROCEDURE Test_ChildCmsDataUpdate;

PROCEDURE Test_CmsDataAnotherCmpnyCreate;

PROCEDURE Test_CmsDataAnotherCmpnyUpdate;

PROCEDURE Test_TwoCmsChildTab;

PROCEDURE Test_ChildCmsDataMultipleComp;

END;
/