CREATE OR REPLACE PACKAGE csr.test_landing_page_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE TestGetDefaultHomePage;
PROCEDURE TestGetLandingPages;
PROCEDURE TestInsertLandingPage;
PROCEDURE TestUpsertLandingPage;
PROCEDURE TestUpsertLandingPageFromDifferentHost;
PROCEDURE TestDeleteLandingPage;

PROCEDURE TearDownFixture;
END test_landing_page_pkg;
/
