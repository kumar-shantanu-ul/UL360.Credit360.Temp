CREATE OR REPLACE PACKAGE csr.test_anonymise_users_pkg AS

-- Start/end of tests
PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE TearDownFixture;

-- Start/end of each test
PROCEDURE SetUp;
PROCEDURE TearDown;

-- Tests
PROCEDURE Test01AnonymiseUserNotAnonymised;
PROCEDURE Test02AnonymiseUserWithoutProfile;
PROCEDURE Test03AnonymiseUserWithProfile;
PROCEDURE Test04AnonymiseTrashedUser;
PROCEDURE Test05NotEligibleForAnonymisation;
PROCEDURE Test06EligibleCutoffDate;
PROCEDURE Test07EligibleUsersMatchExpectedUsers;

END test_anonymise_users_pkg;
/
