CREATE OR REPLACE PACKAGE csr.test_flow_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE SetUp;

PROCEDURE TestFlowItemAutoFailureCount;

PROCEDURE TearDown;
PROCEDURE TearDownFixture;


END test_flow_pkg;
/
