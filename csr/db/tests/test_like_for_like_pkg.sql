CREATE OR REPLACE PACKAGE csr.test_like_for_like_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

--
PROCEDURE TestGetFinalValuesNoData;
PROCEDURE TestGetFinalValuesTempData;
PROCEDURE TestLoadExcludedValsRawTableNoDupes;

PROCEDURE TearDownFixture;

END;
/
