CREATE OR REPLACE PACKAGE csr.test_meter_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE SetUp;

-- Tests
PROCEDURE ImportPreventsRowsThatOverlapDataLockPeriodARB;
PROCEDURE ImportAllowsRowsThatAreOutsideDataLockPeriodARB;
PROCEDURE ImportPreventsRowsThatOverlapDataLockPeriodPIT;
PROCEDURE ImportAllowsRowsThatAreOutsideDataLockPeriodPIT;
PROCEDURE ImportPreventsRowsThatOverlapDataLockPeriodRT;
PROCEDURE ImportAllowsRowsThatAreOutsideDataLockPeriodRT;
PROCEDURE TestSetArbitraryPeriodAfter;
PROCEDURE TestSetArbitraryPeriodOn;
PROCEDURE TestUpdatingLockedInPeriod; --Non Happy Path
PROCEDURE TestDeleteMeterReading;
PROCEDURE TestDeleteLockedInPeriod; --Non Happy Path
PROCEDURE TestSetMeterReadingAfter;
PROCEDURE TestSetMeterReadingOn;
PROCEDURE TestSetMeterLockedInPeriod; --Non Happy Path;

--Clean-up
PROCEDURE TearDown;
PROCEDURE TearDownFixture;

END test_meter_pkg;
/