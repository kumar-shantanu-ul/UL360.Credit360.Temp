CREATE OR REPLACE PACKAGE csr.test_property_pkg AS

-- Start/end of tests
PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE TearDownFixture;

-- Start/end of each test
PROCEDURE SetUp;
PROCEDURE TearDown;

-- Tests
PROCEDURE TestGresbAssetId1Set;
PROCEDURE TestGresbAssetId2Update;
PROCEDURE TestGresbAssetId3Clear;
PROCEDURE TestGetMyPropertiesDoesNotError19c;
PROCEDURE TestSetPropertyFlowStateDoesNotFailIn19c;

END test_property_pkg;
/
