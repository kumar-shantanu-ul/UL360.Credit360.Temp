CREATE OR REPLACE PACKAGE csr.test_scenario_pkg AS

-- Called once before starting a test fixture
PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE GetRuleIndTreeWithSelect;
PROCEDURE GetRuleIndListTextFiltered;
PROCEDURE GetRuleIndTreeTagFiltered;
PROCEDURE GetRuleIndListTagFiltered;
PROCEDURE GetRuleIndTreeWithDepth;
PROCEDURE GetRuleIndTreeTextFiltered;

-- Called once after all tests have PASSED
PROCEDURE TearDownFixture;

END;
/
