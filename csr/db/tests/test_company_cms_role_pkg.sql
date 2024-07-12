CREATE OR REPLACE PACKAGE csr.test_company_cms_role_pkg AS

PROCEDURE TestCompanyUserRoleAccess;

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE SetUp;

PROCEDURE TearDown;

END;
/