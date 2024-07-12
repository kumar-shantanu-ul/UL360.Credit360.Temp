CREATE OR REPLACE PACKAGE csr.test_context_sensitive_help_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE TestAddRedirect;
PROCEDURE TestUpdateRedirect;
PROCEDURE TestDeleteRedirect;
PROCEDURE TestGetOneRedirect;
PROCEDURE TestGetAllRedirects;

PROCEDURE TestBaseConstraints;
PROCEDURE TestGetBase;

PROCEDURE TearDownFixture;
END test_context_sensitive_help_pkg;
/
