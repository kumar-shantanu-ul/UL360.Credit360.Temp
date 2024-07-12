CREATE OR REPLACE PACKAGE CSR.test_example_pkg AS

-- The tests are any public procedures
PROCEDURE CreateDelegChkUserPerms;

-- Called before each test
PROCEDURE SetUp;

-- Called after each PASSED test
PROCEDURE TearDown;

-- Called once before starting a test fixture
PROCEDURE SetUpFixture(in_site_name VARCHAR2);

-- Called once after all tests have PASSED
PROCEDURE TearDownFixture;

END;
/