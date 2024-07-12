CREATE OR REPLACE PACKAGE BODY csr.test_util_script_pkg AS

-- Fixture scope
v_site_name					VARCHAR(50) := 'dbtest-utilscript.credit360.com';
v_app_sid					security.security_pkg.T_SID_ID;

v_region_sid				security.security_pkg.T_SID_ID;
v_ind_sid_1					security.security_pkg.T_SID_ID;
v_ind_sid_1a				security.security_pkg.T_SID_ID;

v_ind_sid_2					security.security_pkg.T_SID_ID;
v_ind_sid_3					security.security_pkg.T_SID_ID;
v_ind_sid_4					security.security_pkg.T_SID_ID;
v_ind_sid_5					security.security_pkg.T_SID_ID;
v_ind_sid_6					security.security_pkg.T_SID_ID;
v_ind_sid_7					security.security_pkg.T_SID_ID;
v_ind_sid_8					security.security_pkg.T_SID_ID;
v_ind_sid_9					security.security_pkg.T_SID_ID;
v_ind_sid_10				security.security_pkg.T_SID_ID;
v_ind_sid_11				security.security_pkg.T_SID_ID;
v_ind_sid_12				security.security_pkg.T_SID_ID;

PROCEDURE CreateSite
AS
BEGIN
	security.user_pkg.LogonAdmin;

	BEGIN
		v_app_sid := security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY','ACT'), 0, '//Aspen/Applications/' || v_site_name);
		security.user_pkg.LogonAdmin(v_site_name);
		csr.csr_app_pkg.DeleteApp(in_reduce_contention => 1);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;

	csr.csr_app_pkg.CreateApp(v_site_name, '/standardbranding/styles', 1, v_app_sid);
END;


PROCEDURE Trace(in_msg IN VARCHAR2)
AS
BEGIN
	--NULL;
	dbms_output.put_line(in_msg);
END;


------------------------------------
-- SETUP and TEARDOWN
------------------------------------
PROCEDURE SetUp
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
END;

-- Called after each PASSED test
PROCEDURE TearDown
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
END;

-- Called once before all tests
PROCEDURE SetUpFixture
AS
BEGIN
	CreateSite;

	security.user_pkg.LogonAdmin(v_site_name);

	v_region_sid := unit_test_pkg.GetOrCreateRegion('Region1');
	v_ind_sid_1 := unit_test_pkg.GetOrCreateInd('Ind1 Not In Trash');
	v_ind_sid_1a := unit_test_pkg.GetOrCreateInd('Ind1a Not In Trash');
	UPDATE ind
	   SET calc_xml = '<path sid="'||v_ind_sid_1||'" description="Valid Sid" node-id="1" />'
	 WHERE ind_sid = v_ind_sid_1a;

	v_ind_sid_2 := unit_test_pkg.GetOrCreateInd('Ind2 In Trash, no sids in calc xml');
	UPDATE ind
	   SET calc_xml = '<path node-id="1" />'
	 WHERE ind_sid = v_ind_sid_2;
	indicator_pkg.TrashObject(security_pkg.GetAct, v_ind_sid_2);

	v_ind_sid_3 := unit_test_pkg.GetOrCreateInd('Ind3 In trash, Unknown sid in calc xml');
	UPDATE ind
	   SET calc_xml = '<path sid="123456" description="Trashed Sid" node-id="1" />'
	 WHERE ind_sid = v_ind_sid_3;
	indicator_pkg.TrashObject(security_pkg.GetAct, v_ind_sid_3);

	v_ind_sid_4 := unit_test_pkg.GetOrCreateInd('Ind4 In trash, Known untrashed sid in calc xml');
	UPDATE ind
	   SET calc_xml = '<path sid="'||v_ind_sid_1||'" description="Trashed Sid" node-id="1" />'
	 WHERE ind_sid = v_ind_sid_4;
	indicator_pkg.TrashObject(security_pkg.GetAct, v_ind_sid_4);

	v_ind_sid_5 := unit_test_pkg.GetOrCreateInd('Ind5 In trash, Known trashed sid in calc xml');
	UPDATE ind
	   SET calc_xml = '<path sid="'||v_ind_sid_2||'" description="Trashed Sid" node-id="1" />'
	 WHERE ind_sid = v_ind_sid_5;
	indicator_pkg.TrashObject(security_pkg.GetAct, v_ind_sid_5);

	v_ind_sid_6 := unit_test_pkg.GetOrCreateInd('Ind6 In trash, Known trashed sid and untrashed sid in calc xml');
	UPDATE ind
	   SET calc_xml = '<add node-id="1"><left><path sid="'||v_ind_sid_2||'" description="A" node-id="2" /></left><right><path sid="'||v_ind_sid_1||'" description="B" node-id="3" /></right></add>'
	 WHERE ind_sid = v_ind_sid_6;
	indicator_pkg.TrashObject(security_pkg.GetAct, v_ind_sid_6);


	v_ind_sid_7 := unit_test_pkg.GetOrCreateInd('Ind7 In trash, has children');
	v_ind_sid_8 := unit_test_pkg.GetOrCreateInd(
		in_lookup_key => 'Ind8 In trash, Is child, Known trashed sid in calc xml',
		in_parent_sid => v_ind_sid_7);
	UPDATE ind
	   SET calc_xml = '<add node-id="1"><left><path sid="'||v_ind_sid_2||'" description="A" node-id="2" /></left><right><path sid="'||v_ind_sid_2||'" description="B" node-id="3" /></right></add>'
	 WHERE ind_sid = v_ind_sid_8;
	indicator_pkg.TrashObject(security_pkg.GetAct, v_ind_sid_7);

	v_ind_sid_9 := unit_test_pkg.GetOrCreateInd('Ind9 In trash, has children');
	v_ind_sid_10 := unit_test_pkg.GetOrCreateInd(
		in_lookup_key => 'Ind10 In trash, Is child, Known trashed sid and untrashed sid in calc xml',
		in_parent_sid => v_ind_sid_9);
	UPDATE ind
	   SET calc_xml = '<add node-id="1"><left><path sid="'||v_ind_sid_2||'" description="A" node-id="2" /></left><right><path sid="'||v_ind_sid_1||'" description="B" node-id="3" /></right></add>'
	 WHERE ind_sid = v_ind_sid_10;
	indicator_pkg.TrashObject(security_pkg.GetAct, v_ind_sid_9);

	v_ind_sid_11 := unit_test_pkg.GetOrCreateInd('Ind In trash, referenced by untrashed sid in calc xml');
	indicator_pkg.TrashObject(security_pkg.GetAct, v_ind_sid_11);
	v_ind_sid_12 := unit_test_pkg.GetOrCreateInd('Ind Not In trash, references trashed sid in calc xml');
	UPDATE ind
	   SET calc_xml = '<path sid="'||v_ind_sid_11||'" description="Trashed Sid" node-id="1" />'
	 WHERE ind_sid = v_ind_sid_12;

	Trace('v_ind_sid_1='||v_ind_sid_1);
	Trace('v_ind_sid_2='||v_ind_sid_2);
	Trace('v_ind_sid_3='||v_ind_sid_3);
	Trace('v_ind_sid_4='||v_ind_sid_4);
	Trace('v_ind_sid_5='||v_ind_sid_5);
	Trace('v_ind_sid_6='||v_ind_sid_6);
	Trace('v_ind_sid_7='||v_ind_sid_7);
	Trace('v_ind_sid_8='||v_ind_sid_8);
	Trace('v_ind_sid_9='||v_ind_sid_9);
	Trace('v_ind_sid_10='||v_ind_sid_10);
	Trace('v_ind_sid_11='||v_ind_sid_11);
	Trace('v_ind_sid_12='||v_ind_sid_12);
END;

-- Called once after all tests have PASSED
PROCEDURE TearDownFixture
AS
BEGIN
	security.user_pkg.LogonAdmin(v_site_name);
	csr_app_pkg.DeleteApp(in_reduce_contention => 1);
END;

-----------------------------------------
-- TESTS
-----------------------------------------
-- Scenario: 
PROCEDURE TestClearTrashedIndCalcXmlWhenIndIsNotTrashedExpectError
AS
	v_testname		VARCHAR(100) := 'TestClearTrashedIndCalcXmlWhenIndIsNotTrashedExpectError';
BEGIN
	TRACE(v_testname);
	
	BEGIN
		util_script_pkg.ClearTrashedIndCalcXml(v_ind_sid_1);
		unit_test_pkg.TestFail('Unexpected success');
	EXCEPTION
		WHEN OTHERS THEN 
			IF SQLCODE <> -20001 THEN
				unit_test_pkg.TestFail('Unexpected error');
			END IF;
			IF SQLCODE = -20001 THEN
				unit_test_pkg.AssertAreEqual('ORA-20001: Indicator ' || v_ind_sid_1 || ' is not trashed.', SQLERRM, 'Unexpected exception');
			END IF;		
	END;
END;

PROCEDURE TestClearTrashedIndCalcXmlWhenIndIsTrashedExpectSuccess
AS
	v_testname		VARCHAR(100) := 'TestClearTrashedIndCalcXmlWhenIndIsTrashedExpectSuccess';

	v_calc_xml		VARCHAR2(100);
BEGIN
	TRACE(v_testname);
	
	BEGIN
		util_script_pkg.ClearTrashedIndCalcXml(v_ind_sid_2);
	EXCEPTION
		WHEN OTHERS THEN 
			unit_test_pkg.TestFail('Unexpected error '||SQLERRM);
	END;

	SELECT calc_xml
	  INTO v_calc_xml
	  FROM ind
	 WHERE ind_sid = v_ind_sid_2;

	IF v_calc_xml IS NOT NULL THEN
		unit_test_pkg.TestFail('Calc XML has not been reset.');
	END IF;
END;

PROCEDURE TestClearTrashedIndCalcXmlWhenTrashedIndContainsUnknownSidExpectSuccess
AS
	v_testname		VARCHAR(100) := 'TestClearTrashedIndCalcXmlWhenTrashedIndContainsUnknownSidExpectSuccess';

	v_calc_xml		VARCHAR2(100);
BEGIN
	TRACE(v_testname);
	
	BEGIN
		util_script_pkg.ClearTrashedIndCalcXml(v_ind_sid_3);
	EXCEPTION
		WHEN OTHERS THEN 
			unit_test_pkg.TestFail('Unexpected error '||SQLERRM);
	END;

	SELECT calc_xml
	  INTO v_calc_xml
	  FROM ind
	 WHERE ind_sid = v_ind_sid_3;

	IF v_calc_xml IS NOT NULL THEN
		unit_test_pkg.TestFail('Calc XML has not been reset.');
	END IF;
END;

PROCEDURE TestClearTrashedIndCalcXmlWhenTrashedIndContainsKnownUntrashedSidExpectError
AS
	v_testname		VARCHAR(100) := 'TestClearTrashedIndCalcXmlWhenTrashedIndContainsKnownUntrashedSidExpectError';
BEGIN
	TRACE(v_testname);
	
	BEGIN
		util_script_pkg.ClearTrashedIndCalcXml(v_ind_sid_4);
		unit_test_pkg.TestFail('Unexpected success');
	EXCEPTION
		WHEN OTHERS THEN 
			IF SQLCODE <> -20001 THEN
				unit_test_pkg.TestFail('Unexpected error');
			END IF;
			IF SQLCODE = -20001 THEN
				unit_test_pkg.AssertAreEqual('ORA-20001: Indicator ' || v_ind_sid_4 || ' - not all the indicators referenced in its calc_xml have been trashed.', SQLERRM, 'Unexpected exception');
			END IF;		
	END;
END;

PROCEDURE TestClearTrashedIndCalcXmlWhenTrashedIndContainsKnownTrashedSidExpectSuccess
AS
	v_testname		VARCHAR(100) := 'TestClearTrashedIndCalcXmlWhenTrashedIndContainsKnownTrashedSidExpectSuccess';

	v_calc_xml		VARCHAR2(100);
BEGIN
	TRACE(v_testname);
	
	BEGIN
		util_script_pkg.ClearTrashedIndCalcXml(v_ind_sid_5);
	EXCEPTION
		WHEN OTHERS THEN 
			unit_test_pkg.TestFail('Unexpected error '||SQLERRM);
	END;

	SELECT calc_xml
	  INTO v_calc_xml
	  FROM ind
	 WHERE ind_sid = v_ind_sid_5;

	IF v_calc_xml IS NOT NULL THEN
		unit_test_pkg.TestFail('Calc XML has not been reset.');
	END IF;
END;

PROCEDURE TestClearTrashedIndCalcXmlWhenTrashedIndContainsKnownUntrashedAndTrashedSidExpectError
AS
	v_testname		VARCHAR(100) := 'TestClearTrashedIndCalcXmlWhenTrashedIndContainsKnownUntrashedAndTrashedSidExpectError';
BEGIN
	TRACE(v_testname);
	
	BEGIN
		util_script_pkg.ClearTrashedIndCalcXml(v_ind_sid_6);
		unit_test_pkg.TestFail('Unexpected success');
	EXCEPTION
		WHEN OTHERS THEN 
			IF SQLCODE <> -20001 THEN
				unit_test_pkg.TestFail('Unexpected error');
			END IF;
			IF SQLCODE = -20001 THEN
				unit_test_pkg.AssertAreEqual('ORA-20001: Indicator ' || v_ind_sid_6 || ' - not all the indicators referenced in its calc_xml have been trashed.', SQLERRM, 'Unexpected exception');
			END IF;		
	END;
END;

PROCEDURE TestClearTrashedIndCalcXmlWhenTrashedIndIsReferencedByAnUntrashedSidExpectError
AS
	v_testname		VARCHAR(100) := 'TestClearTrashedIndCalcXmlWhenTrashedIndIsReferencedByAnUntrashedSidExpectError';
BEGIN
	TRACE(v_testname);

	BEGIN
		util_script_pkg.ClearTrashedIndCalcXml(v_ind_sid_11);
	EXCEPTION
		WHEN OTHERS THEN 
				unit_test_pkg.TestFail('Unexpected error '||SQLERRM);
	END;
END;


PROCEDURE TestClearTrashedIndCalcXmlWhenIndIsNotValidExpectError
AS
	v_testname		VARCHAR(100) := 'TestClearTrashedIndCalcXmlWhenIndIsNotValidExpectError';
BEGIN
	TRACE(v_testname);
	
	BEGIN
		util_script_pkg.ClearTrashedIndCalcXml(0);
		unit_test_pkg.TestFail('Unexpected success');
	EXCEPTION
		WHEN OTHERS THEN 
			IF SQLCODE <> -20001 THEN
				unit_test_pkg.TestFail('Unexpected error');
			END IF;
			IF SQLCODE = -20001 THEN
				unit_test_pkg.AssertAreEqual('ORA-20001: Indicator ' || 0 || ' is not valid.', SQLERRM, 'Unexpected exception');
			END IF;		
	END;

	BEGIN
		util_script_pkg.ClearTrashedIndCalcXml(-3);
		unit_test_pkg.TestFail('Unexpected success');
	EXCEPTION
		WHEN OTHERS THEN 
			IF SQLCODE <> -20001 THEN
				unit_test_pkg.TestFail('Unexpected error');
			END IF;
			IF SQLCODE = -20001 THEN
				unit_test_pkg.AssertAreEqual('ORA-20001: Indicator ' || -3 || ' is not valid.', SQLERRM, 'Unexpected exception');
			END IF;		
	END;

	BEGIN
		util_script_pkg.ClearTrashedIndCalcXml(1);
		unit_test_pkg.TestFail('Unexpected success');
	EXCEPTION
		WHEN OTHERS THEN 
			IF SQLCODE <> -20001 THEN
				unit_test_pkg.TestFail('Unexpected error');
			END IF;
			IF SQLCODE = -20001 THEN
				unit_test_pkg.AssertAreEqual('ORA-20001: Indicator ' || 1 || ' is not trashed.', SQLERRM, 'Unexpected exception');
			END IF;		
	END;
END;

PROCEDURE TestCTICXWhenIndIsChildOfTrashedParentAndContainsKnownTrashedSidExpectSuccess
AS
	v_testname		VARCHAR(100) := 'TestCTICXWhenIndIsChildOfTrashedParentAndContainsKnownTrashedSidExpectSuccess';

	v_calc_xml		VARCHAR2(100);
BEGIN
	TRACE(v_testname);
	
	BEGIN
		util_script_pkg.ClearTrashedIndCalcXml(v_ind_sid_8);
	EXCEPTION
		WHEN OTHERS THEN 
			unit_test_pkg.TestFail('Unexpected error '||SQLERRM);
	END;

	SELECT calc_xml
	  INTO v_calc_xml
	  FROM ind
	 WHERE ind_sid = v_ind_sid_8;

	IF v_calc_xml IS NOT NULL THEN
		unit_test_pkg.TestFail('Calc XML has not been reset.');
	END IF;
END;

PROCEDURE TestCTICXWhenIndIsChildOfTrashedParentAndContainsKnownUntrashedAndTrashedSidExpectError
AS
	v_testname		VARCHAR(100) := 'TestCTICXWhenIndIsChildOfTrashedParentAndContainsKnownUntrashedAndTrashedSidExpectError';
BEGIN
	TRACE(v_testname);
	
	BEGIN
		util_script_pkg.ClearTrashedIndCalcXml(v_ind_sid_10);
		unit_test_pkg.TestFail('Unexpected success');
	EXCEPTION
		WHEN OTHERS THEN 
			IF SQLCODE <> -20001 THEN
				unit_test_pkg.TestFail('Unexpected error');
			END IF;
			IF SQLCODE = -20001 THEN
				unit_test_pkg.AssertAreEqual('ORA-20001: Indicator ' || v_ind_sid_10 || ' - not all the indicators referenced in its calc_xml have been trashed.', SQLERRM, 'Unexpected exception');
			END IF;		
	END;
END;



-- Feature: ClearTrashedIndCalcXml should behave as expected when processing a whole site (input sid = -1).

PROCEDURE TestCTICXAllWhenTrashedIndCalcsContainUntrashedIndsExpectError
AS
	v_testname		VARCHAR(100) := 'TestCTICXAllWhenTrashedIndCalcsContainUntrashedIndsExpectError';
BEGIN
	TRACE(v_testname);
	
	BEGIN
		util_script_pkg.ClearTrashedIndCalcXml(-1);
		unit_test_pkg.TestFail('Unexpected success');
	EXCEPTION
		WHEN OTHERS THEN 
			IF SQLCODE <> -20001 THEN
				unit_test_pkg.TestFail('Unexpected error');
			END IF;
			IF SQLCODE = -20001 THEN
				unit_test_pkg.AssertAreEqual('ORA-20001: All Indicators cannot be processed as not all the indicators referenced in the trashed indicator calc_xml''s have been trashed. Check Ind '||v_ind_sid_4||', calc sid '||v_ind_sid_1, SQLERRM, 'Unexpected exception');
			END IF;		
	END;
END;


PROCEDURE ZFINAL_TestCTICXWhenRemoveAllTrashedCalcsExpectSuccess
AS
	v_testname		VARCHAR(100) := 'ZFINAL_TestCTICXWhenRemoveAllTrashedCalcsExpectSuccess';

	v_count			NUMBER;
BEGIN
	TRACE(v_testname);

	-- reset live ind so it doesn't fail.
	UPDATE ind
	   SET calc_xml = NULL
	 WHERE ind_sid = v_ind_sid_12;

	SELECT COUNT(*)
	  INTO v_count
	  FROM ind
	 WHERE trash_pkg.IsInTrashHierarchical(SYS_CONTEXT('SECURITY', 'ACT'), ind_sid) = 0
	   AND calc_xml IS NOT NULL;

	IF v_count = 0 THEN
		unit_test_pkg.TestFail('Invalid test conditions.');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM ind
	 WHERE trash_pkg.IsInTrashHierarchical(SYS_CONTEXT('SECURITY', 'ACT'), ind_sid) = 1
	   AND calc_xml IS NOT NULL;

	IF v_count = 0 THEN
		unit_test_pkg.TestFail('Invalid test conditions.');
	END IF;
	
	BEGIN
		util_script_pkg.ClearTrashedIndCalcXml(-2);
	EXCEPTION
		WHEN OTHERS THEN 
			unit_test_pkg.TestFail('Unexpected error '||SQLERRM);
	END;

	SELECT COUNT(*)
	  INTO v_count
	  FROM ind
	 WHERE trash_pkg.IsInTrashHierarchical(SYS_CONTEXT('SECURITY', 'ACT'), ind_sid) = 0
	   AND calc_xml IS NOT NULL;

	IF v_count = 0 THEN
		unit_test_pkg.TestFail('Where did the untrashed calc go?');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM ind
	 WHERE trash_pkg.IsInTrashHierarchical(SYS_CONTEXT('SECURITY', 'ACT'), ind_sid) = 1
	   AND calc_xml IS NOT NULL;

	IF v_count != 0 THEN
		unit_test_pkg.TestFail('All trashed Calc XMLs have not been reset.');
	END IF;
END;

END;
/
