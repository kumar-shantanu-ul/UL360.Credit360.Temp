CREATE OR REPLACE PACKAGE csr.test_product_type_pkg AS

PROCEDURE SetUp;
PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE TearDownFixture;
PROCEDURE TearDown;

PROCEDURE TestAddDeleteProductType;
PROCEDURE TestRenameProductType;
PROCEDURE TestMoveProductType;
PROCEDURE TestActivateDeactivate;

END test_product_type_pkg;
/
