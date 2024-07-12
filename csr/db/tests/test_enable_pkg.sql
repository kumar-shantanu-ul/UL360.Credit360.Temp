CREATE OR REPLACE PACKAGE csr.test_enable_pkg AS

PROCEDURE SetUpFixture;
PROCEDURE SetUp;

PROCEDURE EnableAmfori;
PROCEDURE EnableAmforiSurvivesAuditClosureTypeWithDuplicateLabelAndNullLookup;
PROCEDURE EnableAmforiSurvivesReusesAuditClosureTypeWithRequestedLookup;
PROCEDURE EnableAmforiFailsWhenAuditWithLookupKeyExists;

PROCEDURE RBA01_EnableRBAFailsWhenChainNotEnabled;
PROCEDURE RBA02_EnableRBA;
PROCEDURE RBA03_DisableRBA;
PROCEDURE RBA04_DeleteRBA;

PROCEDURE QuestionLibraryMenuStructure;

PROCEDURE EnableCarbonEmissions;
PROCEDURE EnableLandingPages;
PROCEDURE DisableLandingPages;

PROCEDURE EnableGresb;
PROCEDURE EnableDelegationPlan;

PROCEDURE EnableConsentSettings;
PROCEDURE DisableConsentSettings;

PROCEDURE EnableTargetPlanning;
PROCEDURE DisableTargetPlanning;

PROCEDURE TearDown;
PROCEDURE TearDownFixture;


END test_enable_pkg;
/
