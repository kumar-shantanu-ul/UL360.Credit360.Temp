CREATE OR REPLACE PACKAGE chain.test_chain_substitution_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE SetSite(in_site_name VARCHAR2);

PROCEDURE SetUp;

PROCEDURE TearDown;

PROCEDURE TearDownFixture;

PROCEDURE Test_SingleMatchNoSubNoPP;

PROCEDURE Test_SingleMatchNoSubWithPP;

PROCEDURE Test_NoMatch;

PROCEDURE Test_SingleMatchWithSubNoPP;

PROCEDURE Test_SingleMatchWithSubWithPP;

PROCEDURE Test_MultiMatchWithWithoutSub;

END;
/