CREATE OR REPLACE PACKAGE chain.test_chain_preprocess_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE SetUp;

PROCEDURE TearDown;

PROCEDURE TearDownFixture;

PROCEDURE Test_Output;

END;
/