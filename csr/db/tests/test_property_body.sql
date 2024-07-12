CREATE OR REPLACE PACKAGE BODY csr.test_property_pkg AS

m_count								NUMBER;
m_id								NUMBER;

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	dbms_output.put_line(s);
	--NULL;
END;


/* private Setup, TearDown helpers */

PROCEDURE DeleteDataCreatedDuringTests
AS
BEGIN
	test_common_pkg.TearDownChainProperty;

	-- delete data that could have been created during tests, in case of previously aborted/failed runs.
	DELETE FROM property_gresb
	 WHERE app_sid = security.security_pkg.getApp;
END;


/* Fixture Setup, TearDown */

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	--dbms_output.put_line('SetUpFixture');
	security.user_pkg.logonadmin(in_site_name);
	DeleteDataCreatedDuringTests;
	test_common_pkg.SetupChainProperty;
END;

PROCEDURE TearDownFixture AS
BEGIN 
	--dbms_output.put_line('TearDownFixture');
	DeleteDataCreatedDuringTests;
	test_common_pkg.TearDownChainProperty;
END;


/* Per test Setup, TearDown */

PROCEDURE SetUp AS
BEGIN
	--dbms_output.put_line('SetUp');
	NULL;
END;

PROCEDURE TearDown AS
BEGIN
	--dbms_output.put_line('TearDown');
	NULL;
END;


/* Tests */

PROCEDURE TestGresbAssetId1Set AS
BEGIN
	SELECT COUNT(*)
	  INTO m_count
	  FROM property_gresb
	 WHERE app_sid = security.security_pkg.getApp;

	unit_test_pkg.AssertAreEqual(0, m_count, 'Unexpected number of records');

	property_pkg.SetGresbAssetId(test_common_pkg.ChainPropertyRegionSid, 1);

	SELECT COUNT(*)
	  INTO m_count
	  FROM property_gresb
	 WHERE app_sid = security.security_pkg.getApp;

	SELECT asset_id
	  INTO m_id
	  FROM property_gresb
	 WHERE app_sid = security.security_pkg.getApp
	   AND region_sid = test_common_pkg.ChainPropertyRegionSid;

	unit_test_pkg.AssertAreEqual(1, m_count, 'Failed to set gresb asset id');
	unit_test_pkg.AssertAreEqual(1, m_id, 'Failed to set gresb asset id to expected value');
END;

PROCEDURE TestGresbAssetId2Update AS
BEGIN
	SELECT COUNT(*)
	  INTO m_count
	  FROM property_gresb
	 WHERE app_sid = security.security_pkg.getApp;

	unit_test_pkg.AssertAreEqual(1, m_count, 'Unexpected number of records');

	property_pkg.SetGresbAssetId(test_common_pkg.ChainPropertyRegionSid, 2);

	SELECT COUNT(*)
	  INTO m_count
	  FROM property_gresb
	 WHERE app_sid = security.security_pkg.getApp;

	SELECT asset_id
	  INTO m_id
	  FROM property_gresb
	 WHERE app_sid = security.security_pkg.getApp
	   AND region_sid = test_common_pkg.ChainPropertyRegionSid;

	unit_test_pkg.AssertAreEqual(1, m_count, 'Unexpected number of records');
	unit_test_pkg.AssertAreEqual(2, m_id, 'Failed to set gresb asset id to expected value');
END;

PROCEDURE TestGresbAssetId3Clear AS
BEGIN
	SELECT COUNT(*)
	  INTO m_count
	  FROM property_gresb
	 WHERE app_sid = security.security_pkg.getApp;

	unit_test_pkg.AssertAreEqual(1, m_count, 'Unexpected number of records');

	property_pkg.ClearGresbAssetId(test_common_pkg.ChainPropertyRegionSid);

	SELECT COUNT(*)
	  INTO m_count
	  FROM property_gresb
	 WHERE app_sid = security.security_pkg.getApp;

	unit_test_pkg.AssertAreEqual(0, m_count, 'Failed to clear gresb asset id');
END;

PROCEDURE TestGetMyPropertiesDoesNotError19c AS
	v_out_cur 						SYS_REFCURSOR;
	v_out_roles_cur					SYS_REFCURSOR;
	v_tag_ids						security_pkg.T_SID_IDS;
	
	v_region_sid					NUMBER;
	v_description					VARCHAR(255);
	v_region_ref					VARCHAR(255);
	v_street_addr_1					VARCHAR(255);
	v_street_addr_2					VARCHAR(255);
	v_city							VARCHAR(255);
	v_state							VARCHAR(255);
	v_postcode						VARCHAR(255);
	v_country_code					VARCHAR(255);
	v_country_name					VARCHAR(255);
	v_country_currency				VARCHAR(255);
	v_property_type_id				NUMBER;
	v_property_type_label			VARCHAR(255);
	v_property_sub_type_id			NUMBER;
	v_property_sub_type_label		VARCHAR(255);
	v_flow_item_id					NUMBER;
	v_current_state_id				NUMBER;
	v_current_state_label			VARCHAR(255);
	v_current_state_colour			VARCHAR(255);
	v_current_state_lookup_key		VARCHAR(255);
	v_active						NUMBER;
	v_acquisition_dtm				DATE;
	v_disposal_dtm					DATE;
	v_lng							NUMBER;
	v_lat							NUMBER;
	v_is_editable					NUMBER;
	v_mgmt_company_id				NUMBER;
	v_mgmt_company_name				VARCHAR(255);
	v_fund_name						VARCHAR(255);
	v_fund_id						NUMBER;
	v_member_name					VARCHAR(255);
	v_total_sheets					NUMBER;
	v_total_overdue_sheets			NUMBER;
	v_number_of_photos 				NUMBER;
	v_energy_star_sync				NUMBER;
	v_energy_star_push				NUMBER;
	v_is_energy_star				NUMBER;
	v_is_energy_star_push			NUMBER;
	v_gresb_asset_id				NUMBER;
BEGIN
	property_pkg.GetMyProperties(
		in_restrict_to_region_sid	=> NULL,
		out_cur 					=> v_out_cur,
		out_roles   				=> v_out_roles_cur
	);
	
	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	-- The table involved here is TEMP_FLOW_FILTER.
	COMMIT;

	LOOP
		FETCH v_out_cur INTO
			v_region_sid,
			v_description,
			v_region_ref,
			v_street_addr_1,
			v_street_addr_2,
			v_city,
			v_state,
			v_postcode,
			v_country_code,
			v_country_name,
			v_country_currency,
			v_property_type_id,
			v_property_type_label,
			v_property_sub_type_id,
			v_property_sub_type_label,
			v_flow_item_id,
			v_current_state_id,
			v_current_state_label,
			v_current_state_colour,
			v_current_state_lookup_key,
			v_active,
			v_acquisition_dtm,
			v_disposal_dtm,
			v_lng,
			v_lat,
			v_is_editable,
			v_mgmt_company_id,
			v_mgmt_company_name,
			v_fund_name,
			v_fund_id,
			v_member_name,
			v_total_sheets,
			v_total_overdue_sheets,
			v_number_of_photos,
			v_energy_star_sync,
			v_energy_star_push,
			v_is_energy_star,
			v_is_energy_star_push,
			v_gresb_asset_id			
		;
		EXIT WHEN v_out_cur%NOTFOUND;
	END LOOP;
END;

PROCEDURE TestSetPropertyFlowStateDoesNotFailIn19c AS
	v_out_cur 						SYS_REFCURSOR;
	v_out_trans_cur					SYS_REFCURSOR;
	v_flow_item_id					NUMBER;
	v_cache_key						security_pkg.T_VARCHAR2_ARRAY;
	
	v_current_state_id				NUMBER;
	v_current_state_label			VARCHAR2(255);
	v_current_state_colour			VARCHAR2(255);
	v_current_state_lookup_key		VARCHAR2(255);
	v_is_editable					NUMBER;
BEGIN
	property_pkg.AddToFlow(test_common_pkg.ChainPropertyRegionSid, v_flow_item_id);
	property_pkg.SetFlowState(
		in_region_sid 		=> test_common_pkg.ChainPropertyRegionSid,
		in_flow_item_id		=> v_flow_item_id,
		in_to_state_Id		=> flow_pkg.GetStateId(test_common_pkg.ChainPropertyFlowSid, 'PROP_DETS_ENTERED'),
		in_comment_text		=> 'Comment',
		in_cache_keys		=> v_cache_key,
		out_property 		=> v_out_cur,
		out_transitions		=> v_out_trans_cur
	);
	
	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	-- The table involved here is TEMP_FLOW_FILTER.
	COMMIT;

	LOOP
		FETCH v_out_cur INTO
			v_current_state_id,
			v_current_state_label,
			v_current_state_colour,
			v_current_state_lookup_key,
			v_is_editable
		;
		EXIT WHEN v_out_cur%NOTFOUND;
	END LOOP;
END;

END test_property_pkg;
/
