CREATE OR REPLACE PACKAGE csr.test_baseline_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE SetUp;

PROCEDURE TearDown;
PROCEDURE TearDownFixture;

-- Tests
PROCEDURE TestCreateBaselineConfig;
PROCEDURE TestUpdateBaselineConfig;
PROCEDURE TestCreateBaselineConfigPeriod;
PROCEDURE TestUpdateBaselineConfigPeriod;
PROCEDURE TestGetBaselineConfigs;
PROCEDURE TestGetBaselineConfig;
PROCEDURE TestGetBaselineConfigList;
PROCEDURE TestGetBaselineConfigPeriod;
PROCEDURE TestDeleteBaselineConfig;
PROCEDURE TestDeleteBaselineConfigPeriod;

END test_baseline_pkg;
/
