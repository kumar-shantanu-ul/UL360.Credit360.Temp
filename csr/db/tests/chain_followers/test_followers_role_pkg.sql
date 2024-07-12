CREATE OR REPLACE PACKAGE chain.test_followers_role_pkg AS

PROCEDURE SetUpFixture;

PROCEDURE TearDownFixture;

PROCEDURE SetUp;

PROCEDURE TearDown;

-- Tests
-- Given a T1 company is related with a T2 supplier
-- And 2 users of T1 company are following T2 supplier
-- When the relationship between T1 company and T2 supplier gets deleted
-- Then the follower role on T2 suppliers for the 2 T1 company users also gets removed
PROCEDURE TestRoleGetsDeletedWhenRelaDel;

END;
/