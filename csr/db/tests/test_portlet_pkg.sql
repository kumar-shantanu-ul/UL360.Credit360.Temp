CREATE OR REPLACE PACKAGE csr.test_portlet_pkg AS

PROCEDURE SetUp;
PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE TearDown;
PROCEDURE TearDownFixture;

PROCEDURE TestAuditPortletState;

END test_portlet_pkg;
/
