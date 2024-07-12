CREATE OR REPLACE PACKAGE csr.test_core_access_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE SetUp;

PROCEDURE TestGetUserRecordByUserName;
PROCEDURE TestGetRegionRecord;
PROCEDURE TestGetChildRegionRecords;
PROCEDURE TestUpdateAuditRegion;
PROCEDURE TestUpdateAuditRegionNoIssue;
PROCEDURE TestUpdateAuditRegionNoFinding;
PROCEDURE TestSetCmsTableHelperPackage;
PROCEDURE TestSetCmsTableFlowSid;
--PROCEDURE TestSetCmsTableColumnNullable;

PROCEDURE TearDown;
PROCEDURE TearDownFixture;

END test_core_access_pkg;
/
