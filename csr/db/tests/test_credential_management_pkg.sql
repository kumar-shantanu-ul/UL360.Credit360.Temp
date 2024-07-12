CREATE OR REPLACE PACKAGE csr.test_credential_management_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE TestAddCredential;
PROCEDURE TestUpdateCredential;
PROCEDURE TestDeleteCredential;
PROCEDURE TestGetSelectedCredential;
PROCEDURE TestGetCredentials;
PROCEDURE TestGetActiveCredentials;
PROCEDURE TestUpdateCredentialCacheKey;

-- Authentication Types/Scopes
PROCEDURE TestGetAuthenticationTypes;
PROCEDURE TestGetAuthenticationScopes;

PROCEDURE TearDownFixture;
END test_credential_management_pkg;
/
