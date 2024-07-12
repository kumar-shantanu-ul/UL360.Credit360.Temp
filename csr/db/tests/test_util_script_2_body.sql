CREATE OR REPLACE PACKAGE BODY csr.test_util_script_2_pkg AS

-- Fixture scope
v_site_name					VARCHAR(50) := 'dbtest-utilscript-2.credit360.com';
v_app_sid					security.security_pkg.T_SID_ID;

v_region_sid				security.security_pkg.T_SID_ID;
v_ind_sid_10				security.security_pkg.T_SID_ID;
v_ind_sid_11				security.security_pkg.T_SID_ID;
v_ind_sid_12				security.security_pkg.T_SID_ID;
v_ind_sid_13				security.security_pkg.T_SID_ID;
v_ind_sid_14				security.security_pkg.T_SID_ID;
v_ind_sid_15				security.security_pkg.T_SID_ID;


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
	v_ind_sid_11 := unit_test_pkg.GetOrCreateInd('Ind11 Not In Trash');

	v_ind_sid_10 := unit_test_pkg.GetOrCreateInd('Ind10 not In Trash, sids in calc xml');
	UPDATE ind
	   SET calc_xml = '<path sid="'||v_ind_sid_11||'" description="untrashed Sid" node-id="1" />'
	 WHERE ind_sid = v_ind_sid_10;


	v_ind_sid_12 := unit_test_pkg.GetOrCreateInd('Ind2 In Trash, no sids in calc xml');
	UPDATE ind
	   SET calc_xml = '<path node-id="1" />'
	 WHERE ind_sid = v_ind_sid_12;
	indicator_pkg.TrashObject(security_pkg.GetAct, v_ind_sid_12);

	v_ind_sid_13 := unit_test_pkg.GetOrCreateInd('Ind3 In trash, trashed sid in calc xml');
	UPDATE ind
	   SET calc_xml = '<path sid="'||v_ind_sid_12||'" description="Trashed Sid" node-id="1" />'
	 WHERE ind_sid = v_ind_sid_13;
	indicator_pkg.TrashObject(security_pkg.GetAct, v_ind_sid_13);

	v_ind_sid_14 := unit_test_pkg.GetOrCreateInd('Ind15 In trash, has children');
	v_ind_sid_15 := unit_test_pkg.GetOrCreateInd(
		in_lookup_key => 'Ind5 In trash, Is child, Known trashed sid in calc xml',
		in_parent_sid => v_ind_sid_14);
	UPDATE ind
	   SET calc_xml = '<add node-id="1"><left><path sid="'||v_ind_sid_12||'" description="A" node-id="2" /></left><right><path sid="'||v_ind_sid_13||'" description="B" node-id="3" /></right></add>'
	 WHERE ind_sid = v_ind_sid_15;
	indicator_pkg.TrashObject(security_pkg.GetAct, v_ind_sid_14);



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

PROCEDURE TestCTICXAllWhenTrashedIndCalcsContainTrashedIndsExpectSuccess
AS
	v_testname		VARCHAR(100) := 'TestCTICXAllWhenTrashedIndCalcsContainTrashedIndsExpectSuccess';

	v_calc_xml		VARCHAR2(100);
BEGIN
	TRACE(v_testname);

	BEGIN
		util_script_pkg.ClearTrashedIndCalcXml(-1);
	EXCEPTION
		WHEN OTHERS THEN 
			unit_test_pkg.TestFail('Unexpected error '||SQLERRM);
	END;

	SELECT calc_xml
	  INTO v_calc_xml
	  FROM ind
	 WHERE ind_sid = v_ind_sid_13;

	IF v_calc_xml IS NOT NULL THEN
		unit_test_pkg.TestFail('Calc XML has not been reset.');
	END IF;

END;


END;
/
