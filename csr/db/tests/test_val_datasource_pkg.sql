CREATE OR REPLACE PACKAGE csr.test_val_datasource_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE SetUp;

PROCEDURE TestGetRegionTreeForSheets;
PROCEDURE TestGetRegionTree;
PROCEDURE TestGetRegions;
PROCEDURE TestGetAllIndDetailsNoInds;
PROCEDURE TestGetAllIndDetailsInds;
PROCEDURE TestGetIndAndReportCalcDetailsInds;
PROCEDURE TestGetAllGasFactors;
PROCEDURE TestGetIndDependencies;
PROCEDURE TestGetAggregateIndDependencies;
PROCEDURE TestGetAggregateChildren;
PROCEDURE TestFetchResult;
PROCEDURE TestGetStoredRecalcValues;
PROCEDURE TestGetAllSheetValues;

PROCEDURE TearDown;
PROCEDURE TearDownFixture;


END test_val_datasource_pkg;
/
