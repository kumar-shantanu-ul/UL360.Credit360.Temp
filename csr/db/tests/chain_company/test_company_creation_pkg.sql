CREATE OR REPLACE PACKAGE chain.test_company_creation_pkg AS

PROCEDURE SetUpFixture;

PROCEDURE TearDownFixture;

PROCEDURE SetUp;

PROCEDURE TearDown;

-- Tests
PROCEDURE TestCreateCompany;

PROCEDURE TestCreateSubsidiary;

PROCEDURE TestCompanyUpdate;

PROCEDURE TestCityCountryRegionLayout;

PROCEDURE TestAllRegionLayouts;

PROCEDURE TestMultipleCTLayouts;

PROCEDURE TestParentLayout;

END;
/