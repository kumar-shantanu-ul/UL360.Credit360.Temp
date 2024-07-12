CREATE OR REPLACE PACKAGE csr.test_aggregate_ind_pkg AS

-- The tests
PROCEDURE DataFetchDoesntThrowWithNoInstance;
PROCEDURE DataFetchThrowsWhenNoBucket;
PROCEDURE AggIndGroupWithDataBucketTriggersBatchJob;
PROCEDURE AggIndGroupWithDataBucketTriggersCalcJob;
PROCEDURE SetGroupOnDuplicateDoesUpdate;
PROCEDURE TestRemoveAggIndGroup;

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
