CREATE OR REPLACE PACKAGE chain.test_dedupe_partial_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE SetSite(in_site_name VARCHAR2);

PROCEDURE SetUp;

PROCEDURE TearDown;

PROCEDURE TearDownFixture;

PROCEDURE TestMatch_PartialNameCntryPost;

PROCEDURE TestProcess_AutoRuleSet;

PROCEDURE TestProcess_ManualRuleSet;

PROCEDURE TestNoMatchAutoCreate;

PROCEDURE TestNoMatchPark;

PROCEDURE TestNoMatchManualReview;

PROCEDURE TestNormalisedValsMatching;

PROCEDURE TestNormalisedValsNOMatching;

PROCEDURE TestRuleTypeContains;

PROCEDURE TestMultFldMatchUsingPreproc;

PROCEDURE TestMultipleMatchAutoRuleSet;

PROCEDURE TestMatchAddressMultiColumns;

PROCEDURE TestMatchAddressSingleColumn;

PROCEDURE TestPotentialAddressNoMatch;

PROCEDURE TestPartAddNameExactPCCntry;

PROCEDURE TestAutoAddrNamePCCntryMatch;

PROCEDURE TestMergeAltCompNameAddress;

END;
/
