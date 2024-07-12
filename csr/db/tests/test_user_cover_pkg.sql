CREATE OR REPLACE PACKAGE csr.test_user_cover_pkg AS

PROCEDURE CreateAuditWorkflow_;

PROCEDURE SimpleDelegationCover;

PROCEDURE GroupCoverNewGroup;

PROCEDURE GroupCoverExistingGroup;

PROCEDURE GroupCoverExistingCover;

PROCEDURE GroupCoverSameGroupFrom2Users;

PROCEDURE GroupCoverGroupRemovedAfter;

PROCEDURE RoleCoverNewRole;

PROCEDURE RoleCoverExistingRole;

PROCEDURE RoleCoverExistingParentRole;

PROCEDURE RoleCoverExistingChildRole;

PROCEDURE RoleCoverExistingCover;

PROCEDURE IssueCoverNewIssue;

PROCEDURE IssueCoverExistingIssue;

PROCEDURE IssueCoverExistingCover;

PROCEDURE IssueCoverUserRemovedAfter;

PROCEDURE FlowInvCoverNew;

PROCEDURE FlowInvCoverExistingCover;

PROCEDURE FlowInvCoverAlreadyInvolved;

PROCEDURE FlowInvCoverManuallyRemove;

PROCEDURE FlowInvCoverSurvivesHistoricCover;

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE TearDownFixture;

PROCEDURE SetUp;

PROCEDURE TearDown;

END;
/