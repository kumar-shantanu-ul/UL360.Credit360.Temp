CREATE OR REPLACE PACKAGE csr.test_customer_pkg AS

-- Start/end of tests
PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE TearDownFixture;

-- Start/end of each test
PROCEDURE SetUp;
PROCEDURE TearDown;

-- Tests
PROCEDURE Test01SetSysTranslation;
PROCEDURE Test02UpdSysTranslation;
PROCEDURE Test03CreSysTranslation;
PROCEDURE Test04DelSysTranslation;

END test_customer_pkg;
/
