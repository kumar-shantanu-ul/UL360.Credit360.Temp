CREATE OR REPLACE PACKAGE csr.test_alert_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE TestActiveAlertMarkUnconfiguredCmsFieldChangeSent;
PROCEDURE TestInActiveAlertMarkUnconfiguredCmsFieldChangeSent;
PROCEDURE TestGetBatchedCmsFieldChangeAlerts;



PROCEDURE TearDownFixture;
END test_alert_pkg;
/
