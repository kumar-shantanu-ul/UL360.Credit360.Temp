CREATE OR REPLACE PACKAGE csr.test_util_script_2_pkg AS

-- Called before each test
PROCEDURE SetUp;

-- Called after each PASSED test
PROCEDURE TearDown;

-- Called once before starting a test fixture
PROCEDURE SetUpFixture;

-- Called once after all tests have PASSED
PROCEDURE TearDownFixture;


-- Feature: ClearTrashedIndCalcXml should behave as expected when processing a whole site (input sid = -1).
PROCEDURE TestCTICXAllWhenTrashedIndCalcsContainTrashedIndsExpectSuccess;



END;
/
