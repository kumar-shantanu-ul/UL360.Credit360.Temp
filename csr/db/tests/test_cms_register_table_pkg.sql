CREATE OR REPLACE PACKAGE cms.test_cms_register_table_pkg AS

PROCEDURE With_ManagedV1;

PROCEDURE With_ManagedV2;

PROCEDURE With_ManagedV1_NoV2Created;

PROCEDURE With_ManagedV1_UpgradeToV2;

PROCEDURE With_Unmanaged;

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE SetUp;

PROCEDURE TearDown;

END;
/