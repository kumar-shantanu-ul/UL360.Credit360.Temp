CREATE OR REPLACE PACKAGE csr.test_scheduled_import_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE SetUp;

-- Write message tests
PROCEDURE WriteMsg_AcceptsLongMessages;

PROCEDURE TearDown;


END test_scheduled_import_pkg;
/
