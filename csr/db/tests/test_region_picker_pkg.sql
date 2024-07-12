CREATE OR REPLACE PACKAGE csr.test_region_picker_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE Test_GetRegionsByType;
PROCEDURE Test_GetLeafRegions;
PROCEDURE Test_GetCountryRegions;
PROCEDURE Test_GetChildRegions;
PROCEDURE Test_GetRegionsForTags;

PROCEDURE TearDownFixture;


END test_region_picker_pkg;
/
