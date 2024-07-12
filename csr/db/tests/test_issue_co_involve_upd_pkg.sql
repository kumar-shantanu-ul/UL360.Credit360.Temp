CREATE OR REPLACE PACKAGE csr.test_issue_co_involve_upd_pkg AS

-- Feature: Ensures that updating the auditor company of an audit 
--			that is of an audit type that automatically involves the auditor company
--			correctly updates the company involvement against issues attached to the audit

PROCEDURE SwitchTopToInterOneAudit;
-- Scenario: Switching the auditor company from the top company to an intermediary company for a single audit and a single issue
	-- Given an audit of an audit type that automatically involves the auditor company with issues
	-- And a finding that has an issue
	-- And the auditor company is the top company
	-- When the auditor company is switched to an intermediary company
	-- Then the intermediary company is involved with the issue

PROCEDURE SwitchInterToTopOneAudit;
-- Scenario: Switching the auditor company from an intermediary company to the top company for a single audit and a single issue
	-- Given an audit of an audit type that automatically involves the auditor company with issues
	-- And a finding that has an issue
	-- And the auditor company is an intermediary company
	-- When the auditor company is switched to the top company
	-- Then the intermediary company is no longer involved with the issue

PROCEDURE SwitchIntersOneAudit;
-- Scenario: Switching the auditor company from one intermediary company to another for a single audit and a single issue
	-- Given an audit of an audit type that automatically involves the auditor company with issues
	-- And a finding that has an issue
	-- And the auditor company is an intermediary company
	-- When the auditor company is switched to another intermediary company
	-- Then the previous intermediary company is no longer involved with the issue
	-- And the new intermediary company is involved with the issue

PROCEDURE SwitchTopToInterTwoAudits;
-- Scenario: Switching the auditor company from the top company to an intermediary company for two audits that share a single issue
	-- Given an audit type that automatically involves the auditor company with issues and also allows the carrying forward of data from itself
	-- And an audit of that type that has a finding and an issue and an auditor company of the top company
	-- And a second audit is created of the same audit type that also has an auditor company of the top company
	-- When the auditor company of the first audit is switched to an intermediary company
	-- Then the intermediary company is involved with the issue

PROCEDURE SwitchInterToTopTwoAudits;
-- Scenario: Switching the auditor company from an intermediary company to the top company for two audits that share a single issue
	-- Given an audit type that automatically involves the auditor company with issues and also allows the carrying forward of data from itself
	-- And an audit of that type that has a finding and an issue and an auditor company of an intermediary company
	-- And a second audit is created of the same audit type that also has an auditor company of the same intermediary company
	-- When the auditor company of the first audit is switched to the top company
	-- Then the intermediary company remains involved with the issue
	-- When the auditor company of the second audit is also switched to the top company
	-- Then the intermediary company is no longer involved with the issue

PROCEDURE SwitchIntersTwoAudits;
-- Scenario: Switching the auditor company from one intermediary company to another for two audits that share a single issue
	-- Given an audit type that automatically involves the auditor company with issues and also allows the carrying forward of data from itself
	-- And an audit of that type that has a finding and an issue and an auditor company of an intermediary company
	-- And a second audit is created of the same audit type that also has an auditor company of the same intermediary company
	-- When the auditor company of the first audit is switched to another intermediary company
	-- Then the first intermediary company is involved with the issue
	-- And the second intermediary company is involved with the issue
	-- When the auditor company of the second audit is also switched to the other intermediary company
	-- Then the first intermediary company is no longer involved with the issue
	-- And the second intermediary company remains involved with the issue

PROCEDURE SwitchIntersManyFindings;
-- Scenario: Switching the auditor company from one intermediary company to another for a single audit that has multiple findings and issue
	-- Given an audit type that automatically involves the auditor company with issues
	-- And an audit of that type that has two findings each with two issues
	-- And an auditor company of an intermediary company
	-- When the auditor company is switched to another intermediary company
	-- Then the previous intermediary company is no longer involved with any of the issues
	-- And the new intermediary company is involved with all of the issues

-- Called before each test
PROCEDURE SetUp;

-- Called after each PASSED test
PROCEDURE TearDown;

-- Called once before starting a test fixture
PROCEDURE SetUpFixture;

-- Called once after all tests have PASSED
PROCEDURE TearDownFixture;

END;
/