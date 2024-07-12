CREATE OR REPLACE PACKAGE BODY csr.test_property_fund_pkg AS

TYPE OwnershipTable					IS TABLE OF v$property_fund_ownership%ROWTYPE;

m_company_sid						security.security_pkg.T_SID_ID;
m_region_sid						security.security_pkg.T_SID_ID;
m_fund_a							security.security_pkg.T_SID_ID;
m_fund_b							security.security_pkg.T_SID_ID;
m_property_type_id					security.security_pkg.T_SID_ID;
m_prop_flow_sid						security.security_pkg.T_SID_ID;

/* private Setup, TearDown helpers */

PROCEDURE DeleteDataCreatedDuringTests
AS
BEGIN
	test_common_pkg.TearDownChainProperty;
	DELETE FROM property_options WHERE app_sid = security.security_pkg.GetApp;

	-- delete data that could have been created during tests, in case of previously aborted/failed runs.
	DELETE FROM property_fund_ownership
	 WHERE app_sid = security.security_pkg.getApp;
END;


/* Fixture Setup, TearDown */

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	security.user_pkg.logonadmin(in_site_name);
	DeleteDataCreatedDuringTests;
	test_common_pkg.SetupChainProperty;

	INSERT INTO property_options (app_sid, enable_multi_fund_ownership) 
	VALUES (security.security_pkg.GetApp, 1);
END;

PROCEDURE TearDownFixture AS
BEGIN 
	DeleteDataCreatedDuringTests;
	test_common_pkg.TearDownChainProperty;

	DELETE FROM property_options WHERE app_sid = security.security_pkg.GetApp;
END;


/* Per test Setup, TearDown */

PROCEDURE SetUp AS
BEGIN
	DECLARE 
		TYPE fund_rec IS RECORD (
			fund_id					fund.fund_id%TYPE,
			name					fund.name%TYPE,
			fund_type_id			fund.fund_type_id%TYPE, 
			mgr_contact_name		fund.mgr_contact_name%TYPE,
			mgr_contact_email		fund.mgr_contact_email%TYPE, 
			mgr_contact_phone		fund.mgr_contact_phone%TYPE, 
			default_mgmt_company_id	fund.default_mgmt_company_id%TYPE
		);
		v_fund_cursor				security_pkg.T_OUTPUT_CUR;
		v_fund_rec					fund_rec;
	BEGIN
		property_pkg.SaveFund(
			in_fund_id					=> NULL,
			in_company_sid				=> test_common_pkg.ChainCompanySid,
			in_fund_name				=> 'Test fund A',
			in_year_of_incep			=> NULL,
			in_fund_type_id				=> NULL,
			in_mgr_contact_name			=> NULL,
			in_mgr_contact_email		=> NULL,
			in_mgr_contact_phone		=> NULL,
			in_default_mgmt_company_id	=> NULL,
			out_cur						=> v_fund_cursor
		);

		FETCH v_fund_cursor INTO v_fund_rec;
		m_fund_a := v_fund_rec.fund_id;
		CLOSE v_fund_cursor;

		property_pkg.SaveFund(
			in_fund_id					=> NULL,
			in_company_sid				=> test_common_pkg.ChainCompanySid,
			in_fund_name				=> 'Test fund B',
			in_year_of_incep			=> NULL,
			in_fund_type_id				=> NULL,
			in_mgr_contact_name			=> NULL,
			in_mgr_contact_email		=> NULL,
			in_mgr_contact_phone		=> NULL,
			in_default_mgmt_company_id	=> NULL,
			out_cur						=> v_fund_cursor
		);

		FETCH v_fund_cursor INTO v_fund_rec;
		m_fund_b := v_fund_rec.fund_id;
		CLOSE v_fund_cursor;
	END;

END;

PROCEDURE TearDown AS
BEGIN

	IF m_fund_a IS NOT NULL THEN
		property_pkg.DeleteFund(m_fund_a);
		m_fund_a := NULL;
	END IF;

	IF m_fund_b IS NOT NULL THEN
		property_pkg.DeleteFund(m_fund_b);
		m_fund_b := NULL;
	END IF;

END;

/* Test helpers */

FUNCTION GetOwnershipAsTable RETURN OwnershipTable
AS
	v_ownership						OwnershipTable;
	v_ownership_cursor				SYS_REFCURSOR;
BEGIN
	property_pkg.GetPropertyFundOwnership(test_common_pkg.ChainPropertyRegionSid, NULL, v_ownership_cursor);

	FETCH v_ownership_cursor BULK COLLECT INTO v_ownership;
	CLOSE v_ownership_cursor;

	RETURN v_ownership;
END;

/* Tests */

PROCEDURE TestSetOwnership AS
	v_ownership						OwnershipTable;
BEGIN
	property_pkg.SetFundOwnership(test_common_pkg.ChainPropertyRegionSid, m_fund_a, 1, DATE'2000-01-01');

	v_ownership := GetOwnershipAsTable();
	unit_test_pkg.AssertAreEqual(1, v_ownership.COUNT, 'Failed to retrieve ownership');
	unit_test_pkg.AssertAreEqual(DATE'2000-01-01', v_ownership(1).start_dtm, 'Wrong start date');
	unit_test_pkg.AssertIsTrue(v_ownership(1).end_dtm IS NULL, 'Wrong end date');
	unit_test_pkg.AssertIsFalse(v_ownership(1).container_sid IS NULL, 'Container node missing');
END;

PROCEDURE TestClearOwnership AS
	v_ownership						OwnershipTable;
BEGIN
	property_pkg.SetFundOwnership(test_common_pkg.ChainPropertyRegionSid, m_fund_a, 1, DATE'2000-01-01');
	property_pkg.SetFundOwnership(test_common_pkg.ChainPropertyRegionSid, m_fund_a, 1, DATE'2001-01-01');
	property_pkg.SetFundOwnership(test_common_pkg.ChainPropertyRegionSid, m_fund_a, 1, DATE'2002-01-01');
	property_pkg.ClearFundOwnership(test_common_pkg.ChainPropertyRegionSid);

	v_ownership := GetOwnershipAsTable();
	unit_test_pkg.AssertAreEqual(0, v_ownership.COUNT, 'Failed to clear ownership');
END;

PROCEDURE TestEndDateCalculation AS
	v_ownership						OwnershipTable;
BEGIN
	property_pkg.SetFundOwnership(test_common_pkg.ChainPropertyRegionSid, m_fund_a, 1, DATE'2000-01-01');
	property_pkg.SetFundOwnership(test_common_pkg.ChainPropertyRegionSid, m_fund_a, 1, DATE'2001-01-01');
	property_pkg.SetFundOwnership(test_common_pkg.ChainPropertyRegionSid, m_fund_a, 1, DATE'2002-01-01');

	v_ownership := GetOwnershipAsTable();
	unit_test_pkg.AssertAreEqual(DATE'2000-01-01', v_ownership(1).start_dtm, 'Wrong start date');
	unit_test_pkg.AssertAreEqual(DATE'2001-01-01', v_ownership(1).end_dtm, 'Wrong end date');
	unit_test_pkg.AssertAreEqual(DATE'2001-01-01', v_ownership(2).start_dtm, 'Wrong start date');
	unit_test_pkg.AssertAreEqual(DATE'2002-01-01', v_ownership(2).end_dtm, 'Wrong end date');
	unit_test_pkg.AssertAreEqual(DATE'2002-01-01', v_ownership(3).start_dtm, 'Wrong start date');
	unit_test_pkg.AssertIsTrue(v_ownership(3).end_dtm IS NULL, 'Wrong end date');
END;

PROCEDURE TestSetInvalidOwnership AS
BEGIN
	BEGIN
		property_pkg.SetFundOwnership(m_region_sid, m_fund_a, 1.5, DATE'2000-01-01');
	EXCEPTION
		WHEN OTHERS THEN RETURN;
	END;

	unit_test_pkg.TestFail('Invalid ownership did not throw');
END;

PROCEDURE TestSetInvalidTotalOwnership AS
	v_error							BOOLEAN := FALSE;
BEGIN
	property_pkg.SetFundOwnership(test_common_pkg.ChainPropertyRegionSid, m_fund_a, 0.5, DATE'2000-01-01');
	property_pkg.SetFundOwnership(test_common_pkg.ChainPropertyRegionSid, m_fund_b, 0.5, DATE'2001-01-01');

	-- Succeeds: Fund a ownership is 0.5
	property_pkg.SetFundOwnership(test_common_pkg.ChainPropertyRegionSid, m_fund_b, 0.1, DATE'2003-01-01');

	-- Succeeds: Fund b ownership is 0.1
	property_pkg.SetFundOwnership(test_common_pkg.ChainPropertyRegionSid, m_fund_a, 0.9, DATE'2005-01-01');

	-- Fails: Fund a ownership is 0.5 
	v_error := FALSE;
	BEGIN
		property_pkg.SetFundOwnership(test_common_pkg.ChainPropertyRegionSid, m_fund_b, 0.6, DATE'2000-01-01');
	EXCEPTION
		WHEN OTHERS THEN v_error := TRUE;
	END;
	/*dbms_output.put_line('fund a='||m_fund_a);
	dbms_output.put_line('fund b='||m_fund_b);
	FOR r IN (
		SELECT start_dtm, SUM(ownership) sumown
		  FROM property_fund_ownership
		 WHERE region_sid = test_common_pkg.ChainPropertyRegionSid
	  GROUP BY start_dtm
	  ORDER BY start_dtm)
	LOOP
		dbms_output.put_line(' from' ||r.start_dtm || ' has %'|| r.sumown);
	END LOOP;*/
	unit_test_pkg.AssertIsTrue(v_error, 'Expected error');


	-- Fails: Fund a ownership is 0.5, but becomes 0.9 in 2005
	v_error := FALSE;
	BEGIN
		property_pkg.SetFundOwnership(test_common_pkg.ChainPropertyRegionSid, m_fund_b, 0.2, DATE'2005-01-01');
	EXCEPTION
		WHEN OTHERS THEN v_error := TRUE;
	END;
	unit_test_pkg.AssertIsTrue(v_error, 'Expected error');
END;

END test_property_fund_pkg;
/
