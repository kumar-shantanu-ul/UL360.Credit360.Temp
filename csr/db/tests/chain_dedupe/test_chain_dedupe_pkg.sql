CREATE OR REPLACE PACKAGE chain.test_chain_dedupe_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE SetSite(in_site_name VARCHAR2);

PROCEDURE SetUp;

PROCEDURE TearDown;

PROCEDURE TearDownFixture;

PROCEDURE TestMatch_NameCountryRule;

PROCEDURE TestMatch_RefRule;

PROCEDURE TestMatch_TypePostDateRule;

PROCEDURE TestMatch_AllRules;

PROCEDURE TestMatch_SectorAddress;

PROCEDURE TestMatch_AddressTagGroup;

PROCEDURE TestNoMatch_CreateCompany;

PROCEDURE TestMatch_MergeCompanyData;

PROCEDURE Test_DataMergedFromHigherPrior;

PROCEDURE TestManualReview_Create;

PROCEDURE TestRuleManualReview_Merge;

PROCEDURE TestFlagFillNullsUnderUI;

PROCEDURE TestAuto_MultipleMatches;

PROCEDURE TestMatch_AltNameCountryRule;

END;
/