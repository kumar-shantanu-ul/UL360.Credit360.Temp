CREATE OR REPLACE PACKAGE csr.test_permits_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE TearDownFixture;

PROCEDURE SetUp;
PROCEDURE TearDown;

PROCEDURE TestTempCompLevelsNone;
PROCEDURE TestTempCompLevelsOneManyOverflow;

END test_permits_pkg;
/
