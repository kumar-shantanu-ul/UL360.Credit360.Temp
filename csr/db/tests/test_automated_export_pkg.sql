CREATE OR REPLACE PACKAGE csr.test_automated_export_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE SetUp;

PROCEDURE TearDown;
PROCEDURE TearDownFixture;

-- Tests
PROCEDURE TestCreateClassWithNullParent;
PROCEDURE TestCreateClassWithNullParentWhenNoSubFolder;
PROCEDURE TestCreateClassWithExplicitParent;
PROCEDURE TestGetDsvSettingsByClass;
PROCEDURE TestAppendAndResetPayload;

END test_automated_export_pkg;
/
