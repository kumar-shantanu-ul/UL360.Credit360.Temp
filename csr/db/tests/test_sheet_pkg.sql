CREATE OR REPLACE PACKAGE csr.test_sheet_pkg AS

-- The tests
PROCEDURE AutoApproveDCR;

-- Called before each test
PROCEDURE SetUp;

-- Called after each PASSED test
PROCEDURE TearDown;

-- Called once before starting a test fixture
PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE GetReminderAlerts;
PROCEDURE GetOverdueAlerts;

-- Called once after all tests have PASSED
PROCEDURE TearDownFixture;

END;
/
