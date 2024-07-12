CREATE OR REPLACE PACKAGE csr.test_indicator_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE SetUp;

PROCEDURE TestAmendIndicator;
PROCEDURE TestCreateIndicator;
PROCEDURE TestCopyIndicator;
PROCEDURE TestGetDataOverviewIndicators;
PROCEDURE TestGetIndicator;
PROCEDURE TestGetIndicatorChildren;
PROCEDURE TestGetIndicators;
PROCEDURE TestGetIndicatorsForList;
PROCEDURE TestGetTreeSinceDate;
PROCEDURE TestGetTreeWithDepth;
PROCEDURE TestGetTreeWithSelect;
PROCEDURE TestGetTreeTextFiltered;
PROCEDURE TestGetTreeTagFiltered;

PROCEDURE TestGetListTagFiltered;
PROCEDURE TestGetListTextFiltered;

PROCEDURE TestSetActivityType;
PROCEDURE TestSetAggregateIndicator;
PROCEDURE TestSetTolerance;
PROCEDURE TestSetTranslationAndUpdateGasChildren;

PROCEDURE TearDown;
PROCEDURE TearDownFixture;


END test_indicator_pkg;
/
