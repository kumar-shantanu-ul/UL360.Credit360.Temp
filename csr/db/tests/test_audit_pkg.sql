CREATE OR REPLACE PACKAGE csr.test_audit_pkg AS

-- Called before each test
PROCEDURE SetUp;

-- Called after each PASSED test
PROCEDURE TearDown;

-- Called once before starting a test fixture
PROCEDURE SetUpFixture(in_site_name VARCHAR2);

-- Called once after all tests have PASSED
PROCEDURE TearDownFixture;

-- Tests
PROCEDURE DeleteAudit;
PROCEDURE TrashAudit;
PROCEDURE TestGetIndLookup;
PROCEDURE AuditorNameGetsSetWhenNull;
PROCEDURE TagsAreCreatedForNewDefaultFindingsFromReadOnlyUser;
PROCEDURE TagsAreCreatedForNewDefaultFindingsForDefaultSurveyFromReadOnlyUser;
PROCEDURE TagsAreCreatedForNewDefaultFindingsForSurveyFromReadOnlyUser;

END;
/