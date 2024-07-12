CREATE OR REPLACE PACKAGE csr.test_supplier_pkg AS

PROCEDURE TestGetSupplierFlowAggregatesNoData;
PROCEDURE TestGetSupplierFlowAggregatesWithDates;

PROCEDURE SetUpFixture;
PROCEDURE SetUp;
PROCEDURE TearDown;
PROCEDURE TearDownFixture;

END;
/
