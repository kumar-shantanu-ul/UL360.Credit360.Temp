CREATE OR REPLACE PACKAGE csr.test_region_metric_pkg AS

CHECK_CONSTRAINT_VIOLATED EXCEPTION;
PRAGMA EXCEPTION_INIT(CHECK_CONSTRAINT_VIOLATED, -2290);

PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE SetUp;

PROCEDURE TestSetMetricOnMonthBoundary;
PROCEDURE TestSetMetricOnMiddleOfMonthJan;
PROCEDURE TestSetMetricOnMiddleOfMonthDec;

PROCEDURE TestSetDualMetricOnMonthBoundary;
PROCEDURE TestSetDualMetricOnMiddleOfMonthJan;
PROCEDURE TestSetDualMetricOnMiddleOfMonthDec;

PROCEDURE TestSetDoubleMonthMetric;
PROCEDURE TestSetTripleMonthMetric;

PROCEDURE TestSetMetricBeforeCalcStart;
PROCEDURE TestSetMetricAfterCalcEnd;


PROCEDURE TearDown;
PROCEDURE TearDownFixture;


END test_region_metric_pkg;
/
