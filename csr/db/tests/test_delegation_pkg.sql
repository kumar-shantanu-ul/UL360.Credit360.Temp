CREATE OR REPLACE PACKAGE csr.test_delegation_pkg AS

-- The tests

PROCEDURE ChkDelegAccessAndPermsAsAdmin;

PROCEDURE ChkDelegAccessPermsAsAuditor;

PROCEDURE ChkDelegAccessPermsAsNormUser;

PROCEDURE CopyDelegAsAdminReadWrite;

PROCEDURE CopyDelegAsAuditorRead;

PROCEDURE InsertStepBeforeAllowsApprovalOfChild;

PROCEDURE UpdateDelegTranslationsAsAdmin;

PROCEDURE UpdateDelegTranslationsAsAudit;

PROCEDURE TerminateDelegAsAdmin;

PROCEDURE TerminateDelegAsAuditor;

PROCEDURE SaveValueInEditDateLockPreventsSave;

PROCEDURE SaveValueInMergeDateLockAllowsSave;

PROCEDURE SaveValueInEditDateLockWithCapAllowsSave;

PROCEDURE SetSheetResendAlerts;

PROCEDURE TestGetDelegations;
PROCEDURE TestGetMyDelegations;
PROCEDURE TestGetReportSubmissionPromptness;
PROCEDURE TestExFindOverlaps;

PROCEDURE GetNewAlerts;
PROCEDURE TestSynchChildWithParent;

PROCEDURE TestGetAllTranslations;

PROCEDURE CreateSheetsForDelegationAlerts;
PROCEDURE CreateSheetsForDelegationAlertsInactive;

-- Called before each test
PROCEDURE SetUp;

-- Called after each PASSED test
PROCEDURE TearDown;

-- Called once before starting a test fixture
PROCEDURE SetUpFixture(in_site_name VARCHAR2);

-- Called once after all tests have PASSED
PROCEDURE TearDownFixture;

END;
/
