CREATE OR REPLACE PACKAGE csr.test_property_fund_pkg AS

-- Start/end of tests
PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE TearDownFixture;

-- Start/end of each test
PROCEDURE SetUp;
PROCEDURE TearDown;

-- Tests
PROCEDURE TestSetOwnership;
PROCEDURE TestClearOwnership;
PROCEDURE TestEndDateCalculation;
PROCEDURE TestSetInvalidOwnership;
PROCEDURE TestSetInvalidTotalOwnership;

END test_property_fund_pkg;
/
