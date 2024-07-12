CREATE OR REPLACE PACKAGE chain.test_dedupe_multisource_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE SetSite(in_site_name VARCHAR2);

PROCEDURE SetUp;

PROCEDURE TearDown;

PROCEDURE TearDownFixture;

PROCEDURE Test_Merge;

PROCEDURE TestMultiSrcAltCompNameMerge;

PROCEDURE Test_Relationship_Merge;

END;
/
