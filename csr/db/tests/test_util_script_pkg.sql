CREATE OR REPLACE PACKAGE csr.test_util_script_pkg AS

-- Called before each test
PROCEDURE SetUp;

-- Called after each PASSED test
PROCEDURE TearDown;

-- Called once before starting a test fixture
PROCEDURE SetUpFixture;

-- Called once after all tests have PASSED
PROCEDURE TearDownFixture;



-- Feature: ClearTrashedIndCalcXml should behave as expected when given a single sid.
PROCEDURE TestClearTrashedIndCalcXmlWhenIndIsNotTrashedExpectError;
PROCEDURE TestClearTrashedIndCalcXmlWhenIndIsTrashedExpectSuccess;

PROCEDURE TestClearTrashedIndCalcXmlWhenTrashedIndContainsUnknownSidExpectSuccess;
PROCEDURE TestClearTrashedIndCalcXmlWhenTrashedIndContainsKnownUntrashedSidExpectError;
PROCEDURE TestClearTrashedIndCalcXmlWhenTrashedIndContainsKnownTrashedSidExpectSuccess;
PROCEDURE TestClearTrashedIndCalcXmlWhenTrashedIndContainsKnownUntrashedAndTrashedSidExpectError;
PROCEDURE TestClearTrashedIndCalcXmlWhenTrashedIndIsReferencedByAnUntrashedSidExpectError;

PROCEDURE TestClearTrashedIndCalcXmlWhenIndIsNotValidExpectError;

PROCEDURE TestCTICXWhenIndIsChildOfTrashedParentAndContainsKnownTrashedSidExpectSuccess;
PROCEDURE TestCTICXWhenIndIsChildOfTrashedParentAndContainsKnownUntrashedAndTrashedSidExpectError;

-- Feature: ClearTrashedIndCalcXml should clear only when all calc sids are trashed when processing a whole site (input sid = -1).
PROCEDURE TestCTICXAllWhenTrashedIndCalcsContainUntrashedIndsExpectError;

-- Feature: ClearTrashedIndCalcXml should clear all calcs regardless when processing a whole site (input sid = -2).
PROCEDURE ZFINAL_TestCTICXWhenRemoveAllTrashedCalcsExpectSuccess;

END;
/
