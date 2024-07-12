CREATE OR REPLACE PACKAGE csr.test_core_api_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE SetUp;
PROCEDURE TearDown;
PROCEDURE TearDownFixture;

--PROCEDURE TestScenarios;
--PROCEDURE TestIndicators;
--PROCEDURE TestRegions; 

--PROCEDURE TestMeasures;

END test_core_api_pkg;
/
