CREATE OR REPLACE PACKAGE cms.test_cms_flow_alerts_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE SetUp;

PROCEDURE TestGetOpenGeneratedAlertsWorksIn19c;

PROCEDURE TearDown;
PROCEDURE TearDownFixture;


END test_cms_flow_alerts_pkg;
/
