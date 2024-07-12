CREATE OR REPLACE PACKAGE csr.test_int_api_tags_pkg AS

PROCEDURE SetUp;
PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE TearDownFixture;
PROCEDURE TearDown;

PROCEDURE TestGetTagGroupsBase;
PROCEDURE TestGetTagGroups;
PROCEDURE TestGetTagGroup;
PROCEDURE TestUpsertTagGroup;
PROCEDURE TestUpsertTag;

END test_int_api_tags_pkg;
/
