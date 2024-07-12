CREATE OR REPLACE PACKAGE csr.test_audit_report_pkg AS
-- Feature: Ensures that retrievel of data for the audit report works as expected

-- Scenario: Values for string type issue custom fields are returned
	-- Given a string type custom issue field
	-- And an audit that has a finding that has an issue that has a value in the custom field
	-- When I get the data for the audit report for the audit
	-- Then the value of the string type custom field is correct
PROCEDURE StringCustomFieldValuesAreReturned;

-- Scenario: Values for option type issue custom fields are returned
	-- Given an option type custom issue field
	-- And an audit that has a finding that has an issue that has a value in the custom field
	-- When I get the data for the audit report for the audit
	-- Then the value of the option type custom field is correct
PROCEDURE SingleOptionCustomFieldValuesAreReturned;

-- Scenario: Values for option type issue custom fields are returned
	-- Given an option type custom issue field
	-- And an audit that has a finding that has an issue that has a value in the custom field
	-- When I get the data for the audit report for the audit
	-- Then the value of the option type custom field is correct
PROCEDURE MultiOptionCustomFieldValuesAreReturned;

-- Scenario: Values for date type issue custom fields are returned
	-- Given a date type custom issue field
	-- And an audit that has a finding that has an issue that has a value in the custom field
	-- When I get the data for the audit report for the audit
	-- Then the value of the date type custom field is correct
PROCEDURE DateCustomFieldValuesAreReturned;

-- Scenario: Values for restricted issue custom fields are not returned for users not in the restricted group
	-- Given a custom issue field that is restricted to a group
	-- And an audit that has a finding that has an issue that has a value in the restricted custom field
	-- And I am logged on as a user that is not in the group
	-- When I get the data for the audit report for the audit
	-- Then the restricted custom field is not included
PROCEDURE SecuredCustomFieldsNotReturned;

-- Scenario: Values for restricted issue custom fields are returned for users in the restricted group
	-- Given a custom issue field that is restricted to a group
	-- And an audit that has a finding that has an issue that has a value in the restricted custom field
	-- And I am logged on as a user that is in the group
	-- When I get the data for the audit report for the audit
	-- Then the restricted custom field is included
PROCEDURE SecuredCustomFieldsAreReturned;

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