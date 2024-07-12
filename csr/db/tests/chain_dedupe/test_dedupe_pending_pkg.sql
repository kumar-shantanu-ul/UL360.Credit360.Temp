CREATE OR REPLACE PACKAGE CHAIN.test_dedupe_pending_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE SetUp;

PROCEDURE TearDown;

PROCEDURE TearDownFixture;

PROCEDURE TestMatchesDefaultSet;

PROCEDURE TestDedupeNewCompanyMatches;

PROCEDURE TestMultipleMatchTypeNameCntr;

PROCEDURE TestRequestExactMatchRef;

PROCEDURE TestRequestExactMatchNameCnt;

PROCEDURE TestRequestSuggMatchNameAddr;

PROCEDURE TestLevenshteinEmailMatch;

PROCEDURE TestExactMatchEmail;

PROCEDURE TestJarowinklerMatchEmail;

PROCEDURE TestContainsMatchEmail;

PROCEDURE TestBlackListedEmail;

PROCEDURE TestRequestExactMatchWebsite;

PROCEDURE TestRequestHttpWebsite;

PROCEDURE TestRequestRestriDomainSite;

PROCEDURE TestRequestPartMatchWebsite;

PROCEDURE TestRequestExactMatchPhone;

PROCEDURE TestRequestPartMatchPhone;

PROCEDURE TestRequestNonNumericPhone;

PROCEDURE TestRequestContainsPhone;

END test_dedupe_pending_pkg;
/
