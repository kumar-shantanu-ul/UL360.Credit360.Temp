CREATE OR REPLACE PACKAGE csr.test_automated_import_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE SetUp;

PROCEDURE TearDown;
PROCEDURE TearDownFixture;

-- Tests
PROCEDURE TestCreateClassWithNullParent;
PROCEDURE TestCreateClassWithNullParentWhenNoSubFolder;
PROCEDURE TestCreateClassWithExplicitParent;

END test_automated_import_pkg;
/
