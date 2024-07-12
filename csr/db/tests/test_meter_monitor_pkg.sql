CREATE OR REPLACE PACKAGE csr.test_meter_monitor_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE SetUp;

-- Tests
PROCEDURE SetupAutoCreateMeters;
PROCEDURE TestUpsertMeterLiveData;

PROCEDURE TearDown;
PROCEDURE TearDownFixture;


END test_meter_monitor_pkg;
/
