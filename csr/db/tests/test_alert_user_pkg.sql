CREATE OR REPLACE PACKAGE csr.test_alert_user_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE TestGetUserInactiveSysAlerts;
PROCEDURE TestGetUserInactiveReminderAlerts;



PROCEDURE TearDownFixture;
END test_alert_user_pkg;
/
