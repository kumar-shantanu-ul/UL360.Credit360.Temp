CREATE OR REPLACE PACKAGE csr.test_schema_pkg AS

-- Called once before starting a test fixture
PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE GetIssueLogsFilteredWhenNoIssueLogFiles;
PROCEDURE GetIssueLogsFilteredWhenIssueLogFiles;

-- Called once after all tests have PASSED
PROCEDURE TearDownFixture;

END;
/
