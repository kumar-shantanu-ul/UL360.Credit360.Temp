CREATE OR REPLACE PACKAGE csr.test_period_set_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

--PERIOD_SET
PROCEDURE TestAddPeriodSet;
PROCEDURE TestUpdatePeriodSet;
PROCEDURE TestDeletePeriodSet;

--PERIOD
PROCEDURE TestAddPeriod;
PROCEDURE TestUpdatePeriod;
PROCEDURE TestDeletePeriod;

--PERIOD_DATES
PROCEDURE TestAddPeriodDates;
PROCEDURE TestUpdatePeriodDates;
PROCEDURE TestDeletePeriodDates;

-- PERIOD_INTERVAL
PROCEDURE TestAddPeriodInterval;
PROCEDURE TestUpdatePeriodInterval;
PROCEDURE TestDeletePeriodInterval;

--PERIOD_INTERVAL_MEMBER
PROCEDURE TestAddPeriodIntervalMember;
PROCEDURE TestDeletePeriodIntervalMember;

PROCEDURE TearDownFixture;

END;
/
