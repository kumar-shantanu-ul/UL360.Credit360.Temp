CREATE OR REPLACE PACKAGE csr.test_finding_permission_pkg AS

-- Feature: Ensures that a common security model for finding types is available to developers
		 -- so that checking access permissions to a finding is based on a consistent behaviour.


-- ---------------------------
-- STANDARD CAPABILITY TESTS:
-- ---------------------------

	PROCEDURE UserCannotAccessNonExistingFinding;
	-- Scenario: User trying to access a finding which does not exist
		-- Given a non existing finding
		-- When the user tries to access the finding
		-- Then the user cannot access the finding
		
	PROCEDURE UserCannotAccessFinding;
	-- Scenario: User trying to access a finding for an audit which does not have a workflow
		-- Given a finding related to an audit with no workflow
		-- When a normal user tries to access the finding 
		-- Then the user cannot access the finding

	PROCEDURE AdminCanAccessFinding;
	-- Scenario: Built-in administrator trying to access a finding for an audit which does not have a workflow
		-- Given a finding related to an audit with no workflow
		-- When the built-in administrator tries to access the finding 
		-- Then the buit-in administrator can access the finding

	PROCEDURE UserCannotAccessFindingWithWorkflow;
	-- Scenario: User trying to access a finding for an audit which has a workflow
		-- Given a finding related to an audit with a workflow
		-- When a normal user tries to access the finding 
		-- Then the user cannot access the finding

	PROCEDURE AdminCanAccessFindingWithWorkFlow;
	-- Scenario: Built-in administrator trying to access a finding for an audit which has a workflow
		-- Given a finding related to an audit with a workflow
		-- When the built-in administrator tries to access the finding 
		-- Then the buit-in administrator can access the finding

	PROCEDURE UserCannotAccessFindingWithoutCapability;
	-- Scenario: User trying to access a finding without any capability for an audit which has a workflow
		-- Given a finding related to an audit with a workflow
		-- And no capability has been set
		-- When a normal user tries to access the finding 
		-- Then the user cannot access the finding

	PROCEDURE UserCantAccessFindingWithWrongCapability;
	-- Scenario: User trying to access a finding with the wrong capability for an audit which has a workflow
		-- Given a finding related to an audit with a workflow
		-- And the wrong capability has been set
		-- When a normal user tries to access the finding
		-- Then the user cannot access the finding

	PROCEDURE UserCanAccessFindingWithRightCapability;
	-- Scenario: User trying to access a finding with the right capability for an audit which has a workflow
		-- Given a finding related to an audit with a workflow
		-- And the right capability has been set
		-- When a normal user tries to access the finding 
		-- Then the user can access the finding


-- ------------------------
-- CUSTOM CAPABILITY TESTS:
-- ------------------------

	-- [1] Checking access permission to a single finding:

		PROCEDURE UsrCantAccessFindingWithCustomCapability;
		-- Scenario: User denied access to a finding with an associated custom capability due to no permissions set against it
			-- Given a finding related to an audit with a workflow
			-- And linked to a finding type with associated custom capability
			-- And a standard user belonging to a role which has not been assigned permissions through the custom capability
			-- When the user tries to access the finding
			-- Then the user cannot access the finding

		PROCEDURE UserCantAccessFindingWithoutPermission;
		-- Scenario: User denied access to a finding with an associated custom capability due to no read permissions set against it
			-- Given a finding related to an audit with a workflow
			-- And linked to a finding type with associated custom capability
			-- And a standard user belonging to a role which has not been given read access through the custom capability
			-- When the user tries to access the finding 
			-- Then the user cannot access the finding

		PROCEDURE UserCantAccessFindingWithWrongPermission;
		-- Scenario: User denied access to a finding with an associated custom capability due to a wrong permission set against it
			-- Given a finding related to an audit with a workflow
			-- And linked to a finding type with associated custom capability
			-- And a standard user belonging to a role which has been given read access through a different custom capability
			-- When the user tries to access the finding 
			-- Then the user cannot access the finding

		PROCEDURE UserCanAccessFindingWithCustomCapability;
		-- Scenario: User allowed access to a finding with an associated custom capability
			-- Given a finding related to an audit with a workflow
			-- And linked to a finding type with associated custom capability
			-- And a standard user belonging to a role which has been given read access through the custom capability
			-- When the user tries to access the finding 
			-- Then the user can access the finding


	-- [2] Checking access permission to a all findings related to a given audit:

		PROCEDURE UserCanAccessPermittedFindingsForAudit;
		-- Scenario: User allowed access to findings with associated custom capabilities and related to a given audit
			-- Given an audit with associated workflow and with some related findings
			-- some of which linked to a custom capability with read access 
			-- some of which linked to a custom capability without readaccess
			-- some of which linked to a standard capability with read access
			-- And a standard user belonging to a role which has been given read access through some of the capabilities above
			-- When the user tries to access the findings in the audit 
			-- Then the user can only access the findings which have been given read accesss through a standard or custom capability


	-- [3] Checking access permission to a all findings:

		PROCEDURE UserCannotAccessOtherUsersFindingTypes;
		-- Scenario: User denied access to a finding type which belongs to another user and for which the first user has not been given read permission
			-- Given two users, each with their own distinct role, audit, finding type and custom capability
			-- When a developer wants to determine which finding types a user has access to for any audit linked to the workflow
			-- Then each user can only access finding types which related to them 

		PROCEDURE UserCanOnlyAccessPermittedFindings;
			-- Scenario: User is only allowed access to findings for which a read permission has been granted
			-- Given a user having access to some findings with related custom or standard capabilities
			-- And other findings which the user has not access to related to other users, roles, audits, workflows, finding types, custom and standard capabilities
			-- When one user tries to access all existing findings
			-- Then the user can only access findings where read permissions has been granted through standard or custom capabilities

-- ---------------------------
-- TAG STANDARD CAPABILITY TESTS:
-- ---------------------------

	PROCEDURE UserCannotAccessNonExistingFindingsTags;
	-- Scenario: User trying to access a finding which does not exist
		-- Given a non existing finding
		-- When the user tries to access the finding
		-- Then the user cannot access the finding
		
	PROCEDURE UserCannotAccessFindingsTags;
	-- Scenario: User trying to access a finding tags for an audit which does not have a workflow
		-- Given a finding related to an audit with no workflow
		-- When a normal user tries to access the finding 
		-- Then the user cannot access the finding

	PROCEDURE AdminCanAccessFindingsTags;
	-- Scenario: Built-in administrator trying to access a finding tags for an audit which does not have a workflow
		-- Given a finding related to an audit with no workflow
		-- When the built-in administrator tries to access the finding 
		-- Then the buit-in administrator can access the finding

	PROCEDURE UserCannotAccessFindingsTagsWithWorkflow;
	-- Scenario: User trying to access a finding tags for an audit which has a workflow
		-- Given a finding related to an audit with a workflow
		-- When a normal user tries to access the finding 
		-- Then the user cannot access the finding

	PROCEDURE AdminCanAccessFindingsTagsWithWorkFlow;
	-- Scenario: Built-in administrator trying to access a finding tags for an audit which has a workflow
		-- Given a finding related to an audit with a workflow
		-- When the built-in administrator tries to access the finding 
		-- Then the buit-in administrator can access the finding

	PROCEDURE UserCannotAccessFindingsTagsWithoutCapability;
	-- Scenario: User trying to access a finding tags without any capability for an audit which has a workflow
		-- Given a finding related to an audit with a workflow
		-- And no capability has been set
		-- When a normal user tries to access the finding 
		-- Then the user cannot access the finding

	PROCEDURE UserCantAccessFindingsTagsWithWrongCapability;
	-- Scenario: User trying to access a finding tags with the wrong capability for an audit which has a workflow
		-- Given a finding related to an audit with a workflow
		-- And the wrong capability has been set
		-- When a normal user tries to access the finding
		-- Then the user cannot access the finding

	PROCEDURE UserCanAccessFindingsTagsWithRightCapability;
	-- Scenario: User trying to access a finding tags with the right capability for an audit which has a workflow
		-- Given a finding related to an audit with a workflow
		-- And the right capability has been set
		-- When a normal user tries to access the finding 
		-- Then the user can access the finding


-- ------------------------
-- TAG CUSTOM CAPABILITY TESTS:
-- ------------------------

	-- [1] Checking access permission to a single findings tags:

		PROCEDURE UsrCantAccessFindingsTagsWithCustomCapability;
		-- Scenario: User denied access to a finding tags with an associated custom capability due to no permissions set against it
			-- Given a finding related to an audit with a workflow
			-- And linked to a finding type with associated custom capability
			-- And a standard user belonging to a role which has not been assigned permissions through the custom capability
			-- When the user tries to access the finding
			-- Then the user cannot access the finding

		PROCEDURE UserCantAccessFindingsTagsWithoutPermission;
		-- Scenario: User denied access to a finding tags with an associated custom capability due to no read permissions set against it
			-- Given a finding related to an audit with a workflow
			-- And linked to a finding type with associated custom capability
			-- And a standard user belonging to a role which has not been given read access through the custom capability
			-- When the user tries to access the finding 
			-- Then the user cannot access the finding

		PROCEDURE UserCantAccessFindingsTagsWithWrongPermission;
		-- Scenario: User denied access to a finding tags with an associated custom capability due to a wrong permission set against it
			-- Given a finding related to an audit with a workflow
			-- And linked to a finding type with associated custom capability
			-- And a standard user belonging to a role which has been given read access through a different custom capability
			-- When the user tries to access the finding 
			-- Then the user cannot access the finding

		PROCEDURE UserCanAccessFindingsTagsWithCustomCapability;
		-- Scenario: User allowed access to a finding tags with an associated custom capability
			-- Given a finding related to an audit with a workflow
			-- And linked to a finding type with associated custom capability
			-- And a standard user belonging to a role which has been given read access through the custom capability
			-- When the user tries to access the finding 
			-- Then the user can access the finding


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
