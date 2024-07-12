CREATE OR REPLACE PACKAGE csr.test_excel_export_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE TestSaveOptions;
PROCEDURE TestUpdateOptions;
PROCEDURE TestGetOptions;

PROCEDURE TearDownFixture;
END test_excel_export_pkg;
/
