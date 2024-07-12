CREATE OR REPLACE PACKAGE CSR.test_issue_test_pkg AS
PROCEDURE TestAutoCloseIssue;
PROCEDURE TestCreateIssue;
PROCEDURE TestCreateScheduledTask;
PROCEDURE TestCreateTaskIssue;
PROCEDURE TestCreateSheetValue;
PROCEDURE TestGetIssueAlertSummary;
PROCEDURE TestViewPriorityOveridden;
PROCEDURE TestViewPriorityOveriddenSub00;
PROCEDURE TestViewPriorityOveriddenSub10;
PROCEDURE TestViewPriorityOveriddenSub01;
PROCEDURE TestViewPriorityOveriddenSub11;
PROCEDURE TestDeleteIssue;
PROCEDURE TestUpdateIssues;

PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE TearDownFixture;

END;
/