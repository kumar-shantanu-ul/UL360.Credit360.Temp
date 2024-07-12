CREATE OR REPLACE PACKAGE csr.test_tag_pkg AS
-- Feature: Ensures that the tags package works as expected

-- Scenario: Trying to change a Tag Group applies to after the Tag Group has been used should throw an exception
	-- Given a tag group is created which applies to non-compliances
	-- And tags in that tag group are assigned to a finding (non-compliance)
	-- When changing tag group so that it no longer applies to non-compliances
	-- Then the package should throw an exception preventing it
PROCEDURE TagAppliesToCantBeChanged;

-- Scenario: Trying to change a Tag Group applies to before the Tag Group has been used should update the Tag Group
	-- Given a tag group is created which applies to non-compliances
	-- And tags in that tag group are not assigned to a finding (non-compliance)
	-- When changing tag group so that it no longer applies to non-compliances
	-- Then the Tag Group should be updated
PROCEDURE TagAppliesToCanBeChanged;

-- Scenario: Check tags can be created/updated
PROCEDURE TagCRUD;

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
