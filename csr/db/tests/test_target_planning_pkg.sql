CREATE OR REPLACE PACKAGE CSR.test_target_planning_pkg AS

-- Called before each test
PROCEDURE SetUp;

-- Called after each PASSED test
PROCEDURE TearDown;

-- Called once before starting a test fixture
PROCEDURE SetUpFixture(in_site_name VARCHAR2);

-- Called once after all tests have PASSED
PROCEDURE TearDownFixture;

-- The tests
PROCEDURE TestCanary;

END;
/