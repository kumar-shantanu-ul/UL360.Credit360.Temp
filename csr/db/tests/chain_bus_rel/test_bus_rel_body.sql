CREATE OR REPLACE PACKAGE BODY chain.test_bus_rel_pkg
IS

v_site_name						VARCHAR2(200);
v_act_id						security.security_pkg.T_ACT_ID;
v_app_sid						security.security_pkg.T_SID_ID;

v_top_company_sid				security.security_pkg.T_SID_ID;
v_vendor_company_sid_1			security.security_pkg.T_SID_ID;
v_vendor_company_sid_2			security.security_pkg.T_SID_ID;
v_site_company_sid_1			security.security_pkg.T_SID_ID;

v_bus_rel_user_sid				security.security_pkg.T_SID_ID;
v_top_company_type_id			NUMBER;
v_vendor_company_type_id		NUMBER;
v_site_company_type_id			NUMBER;

v_annual_bus_rel_type_id		NUMBER;
v_annual_bus_rel_tier_id_1		NUMBER;
v_annual_bus_rel_tier_id_2		NUMBER;
v_annual_bus_rel_tier_id_3		NUMBER;

PROCEDURE SetUpBusRelPerms;

PROCEDURE InitCompanyTypeIds
AS
BEGIN
	BEGIN
		v_top_company_sid := helper_pkg.GetTopCompanySid;
		
		v_top_company_type_id := company_type_pkg.GetCompanyTypeId('TOP');
		v_vendor_company_type_id := company_type_pkg.GetCompanyTypeId('VENDOR');
		v_site_company_type_id := company_type_pkg.GetCompanyTypeId('SITE');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
		WHEN OTHERS THEN
			NULL;
	END;
END;

PROCEDURE CreateBusReluser(
	in_act_id					security.security_pkg.T_ACT_ID,
	in_app_sid					security.security_pkg.T_SID_ID
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
	v_user_name					VARCHAR2(50) := 'test_bus_rel_user';
	v_full_name					VARCHAR2(50) := 'Test Business Relationship User';
	v_email						VARCHAR2(50) := 'tbru@cr360.com';
	v_sa_group_sid				security.security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_bus_rel_user_sid := security.securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, '/Users/'||v_user_name);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;

	IF v_bus_rel_user_sid IS NOT NULL THEN
		COMMIT;
		RETURN;
	END IF;

	csr.csr_user_pkg.CreateUser(
		in_act			 				=> in_act_id,
		in_app_sid						=> in_app_sid,
		in_user_name					=> v_user_name,
		in_password 					=> NULL,
		in_full_name					=> v_full_name,
		in_friendly_name				=> v_full_name,
		in_email						=> v_email,
		in_job_title					=> NULL,
		in_phone_number					=> NULL,
		in_info_xml						=> NULL,
		in_send_alerts					=> 0,
		in_enable_aria					=> 0,
		in_line_manager_sid				=> NULL,
		in_primary_region_sid			=> NULL,
		in_user_ref						=> NULL,
		in_account_expiry_enabled		=> 1,
		out_user_sid 					=> v_bus_rel_user_sid
	);

	v_sa_group_sid := security.securableobject_pkg.GetSIDFromPath(in_act_id, security_pkg.SID_ROOT, '//csr/SuperAdmins');
	security.group_pkg.AddMember(in_act_id, v_bus_rel_user_sid, v_sa_group_sid);
	COMMIT;
END;

PROCEDURE LogOnAsAdmin
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
END;

PROCEDURE LogOnAsBusRelUser
AS
BEGIN
	LogOnAsAdmin;
	IF v_bus_rel_user_sid IS NULL THEN
		CreateBusReluser(
			in_act_id					=> v_act_id,
			in_app_sid					=> v_app_sid
		);
	END IF;
	
	IF v_top_company_sid IS NULL THEN 
		InitCompanyTypeIds;
	END IF;

	security.user_pkg.LogonAuthenticated(v_bus_rel_user_sid, 172800, v_act_id);
	security.security_pkg.SetContext('CHAIN_COMPANY', v_top_company_sid);
END;

PROCEDURE SetUpBusinessRelType(
	in_label					IN	VARCHAR2,
	in_period_set_id			IN	NUMBER,
	in_period_interval_id		IN	NUMBER,
	out_bus_rel_type_id			OUT	NUMBER
)
AS
BEGIN
	business_relationship_pkg.SaveBusinessRelationshipType(
		in_bus_rel_type_id				=> NULL,
		in_label						=> in_label,
		in_form_path					=> NULL,
		in_tab_sid						=> NULL,
		in_column_sid					=> NULL,
		in_use_specific_dates			=> 0,
		in_period_set_id				=> in_period_set_id,
		in_period_interval_id			=> in_period_interval_id,
		out_bus_rel_type_id				=> out_bus_rel_type_id
	);
END;

PROCEDURE SetUpBusinessRelTier(
	in_bus_rel_type_id			IN	NUMBER,
	in_tier						IN	NUMBER,
	in_label					IN	VARCHAR2,
	in_company_type_ids			IN	security.security_pkg.T_SID_IDS,
	out_bus_rel_tier_id			OUT	NUMBER
)
AS
BEGIN
	business_relationship_pkg.SaveBusinessRelationshipTier(
		in_bus_rel_type_id				=> in_bus_rel_type_id,
		in_bus_rel_tier_id				=> NULL,
		in_tier							=> in_tier,
		in_label						=> in_label,
		in_direct						=> 0,
		in_create_supplier_rel			=> 1,
		in_create_new_company			=> 0,
		in_allow_multiple_companies		=> 0,
		in_crt_sup_rels_w_lower_tiers	=> 1,
		in_company_type_ids				=> in_company_type_ids,
		out_bus_rel_tier_id				=> out_bus_rel_tier_id
	);
END;

PROCEDURE SetUpBusinessRelTypes
AS
	v_period_set_id				NUMBER := 1; -- Calendar Months
	v_annually_pi_id			NUMBER := 4; -- Annually
	v_bus_rel_type_id			NUMBER;
	v_company_type_ids			security.security_pkg.T_SID_IDS;
BEGIN
	SetUpBusinessRelType(
		in_label					=> 'Test BR Type',
		in_period_set_id			=> v_period_set_id,
		in_period_interval_id		=> v_annually_pi_id,
		out_bus_rel_type_id			=> v_bus_rel_type_id
	);

	SELECT v_top_company_type_id
	  BULK COLLECT INTO v_company_type_ids
	  FROM DUAL;

	SetUpBusinessRelTier(
		in_bus_rel_type_id			=> v_bus_rel_type_id,
		in_tier						=> 1,
		in_label					=> 'Tier - 1',
		in_company_type_ids			=> v_company_type_ids,
		out_bus_rel_tier_id			=> v_annual_bus_rel_tier_id_1
	);

	SELECT v_vendor_company_type_id
	  BULK COLLECT INTO v_company_type_ids
	  FROM DUAL;

	SetUpBusinessRelTier(
		in_bus_rel_type_id			=> v_bus_rel_type_id,
		in_tier						=> 2,
		in_label					=> 'Tier - 2',
		in_company_type_ids			=> v_company_type_ids,
		out_bus_rel_tier_id			=> v_annual_bus_rel_tier_id_2
	);

	SELECT v_site_company_type_id
	  BULK COLLECT INTO v_company_type_ids
	  FROM DUAL;

	SetUpBusinessRelTier(
		in_bus_rel_type_id			=> v_bus_rel_type_id,
		in_tier						=> 3,
		in_label					=> 'Tier - 3',
		in_company_type_ids			=> v_company_type_ids,
		out_bus_rel_tier_id			=> v_annual_bus_rel_tier_id_3
	);

	business_relationship_pkg.DeleteBusRelTiers(
		in_bus_rel_type_id			=> v_bus_rel_type_id,
		in_from_tier				=> 4
	);
	
	v_annual_bus_rel_type_id:= v_bus_rel_type_id;
END;

PROCEDURE SetUpCompanies
AS
	v_company_sid				NUMBER;
BEGIN
	-- Vendor - A
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name							=> 'Vendor - A',
		in_country_code					=> 'gb',
		in_company_type_id				=> v_vendor_company_type_id,
		in_sector_id					=> NULL,
		out_company_sid					=> v_vendor_company_sid_1
	);
	
	company_pkg.ActivateCompany(v_vendor_company_sid_1);
	company_pkg.StartRelationship(v_top_company_sid, v_vendor_company_sid_1, NULL);
	company_pkg.ActivateRelationship(v_top_company_sid, v_vendor_company_sid_1);

	-- Vendor - B
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name							=> 'Vendor - B',
		in_country_code					=> 'de',
		in_company_type_id				=> v_vendor_company_type_id,
		in_sector_id					=> NULL,
		out_company_sid					=> v_vendor_company_sid_2
	);
	company_pkg.ActivateCompany(v_vendor_company_sid_2);
	company_pkg.StartRelationship(v_top_company_sid, v_vendor_company_sid_2, NULL);
	company_pkg.ActivateRelationship(v_top_company_sid, v_vendor_company_sid_2);
	
	-- Site - A
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name							=> 'Site - A',
		in_country_code					=> 'gb',
		in_company_type_id				=> v_site_company_type_id,
		in_sector_id					=> NULL,
		out_company_sid					=> v_site_company_sid_1
	);
	company_pkg.ActivateCompany(v_site_company_sid_1);
	company_pkg.StartRelationship(v_top_company_sid, v_site_company_sid_1, NULL);
	company_pkg.ActivateRelationship(v_top_company_sid, v_site_company_sid_1);
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_tag_group_id				NUMBER;
	v_tag_id					NUMBER;
BEGIN
	v_site_name := in_site_name;
	LogOnAsAdmin;

	test_chain_utils_pkg.SetupTwoTier;
	
	company_type_pkg.AddTertiaryRelationship(
		in_primary_company_type		=> 'TOP',
		in_secondary_company_type	=> 'VENDOR',
		in_tertiary_company_type	=> 'SITE'
	);

	InitCompanyTypeIds;

	SetUpCompanies;

	CreateBusReluser(
		in_act_id					=> v_act_id,
		in_app_sid					=> v_app_sid
	);
END;

PROCEDURE SetSite(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
END;

PROCEDURE SetUp
AS
BEGIN
	LogOnAsBusRelUser;
	SetUpBusinessRelTypes;
END;

PROCEDURE TearDown
AS
BEGIN
	LogOnAsBusRelUser;

	FOR r IN (
		SELECT business_relationship_id
		  FROM business_relationship
	)
	LOOP
		business_relationship_pkg.DeleteBusinessRelationship(
			in_bus_rel_id				=> r.business_relationship_id
		);
	END LOOP;

	FOR r IN (
		SELECT business_relationship_type_id
		  FROM business_relationship_type
	)
	LOOP
		business_relationship_pkg.DeleteBusinessRelationshipType(
			in_bus_rel_type_id			=> r.business_relationship_type_id
		);
	END LOOP;
END;

PROCEDURE TearDownFixture
AS
BEGIN
	LogOnAsAdmin;

	company_type_pkg.DeleteTertiaryRelationship(
		in_primary_company_type		=> v_top_company_type_id,
		in_secondary_company_type	=> v_vendor_company_type_id,
		in_tertiary_company_type	=> v_site_company_type_id
	);

	csr.csr_user_pkg.DeleteObject(
		in_act						=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_sid_id					=> v_bus_rel_user_sid
	);

	v_bus_rel_user_sid := NULL;
	
	test_chain_utils_pkg.TearDownTwoTier;
END;

PROCEDURE SetUpBusRelPerms
AS
BEGIN
	type_capability_pkg.SetPermission(
		in_primary_company_type		=> 'TOP',
		in_secondary_company_type	=> NULL,
		in_tertiary_company_type	=> NULL,
		in_group					=> chain_pkg.ADMIN_GROUP,
		in_capability_type			=> chain_pkg.CT_COMPANY,
		in_capability				=> chain_pkg.CREATE_BUSINESS_RELATIONSHIPS
	);

	type_capability_pkg.SetPermission(
		in_primary_company_type		=> 'TOP',
		in_secondary_company_type	=> NULL,
		in_tertiary_company_type	=> NULL,
		in_group					=> chain_pkg.ADMIN_GROUP,
		in_capability_type			=> chain_pkg.CT_COMPANY,
		in_capability				=> chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS
	);

	type_capability_pkg.SetPermission(
		in_primary_company_type		=> 'TOP',
		in_secondary_company_type	=> 'VENDOR',
		in_tertiary_company_type	=> NULL,
		in_group					=> chain_pkg.ADMIN_GROUP,
		in_capability_type			=> chain_pkg.CT_SUPPLIERS,
		in_capability				=> chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS
	);

	type_capability_pkg.SetPermission(
		in_primary_company_type		=> 'TOP',
		in_secondary_company_type	=> 'VENDOR',
		in_tertiary_company_type	=> 'SITE',
		in_group					=> chain_pkg.ADMIN_GROUP,
		in_capability_type			=> chain_pkg.CT_ON_BEHALF_OF,
		in_capability				=> chain_pkg.ADD_REMOVE_RELATIONSHIPS
	);
	
	type_capability_pkg.SetPermission(
		in_primary_company_type		=> 'TOP',
		in_secondary_company_type	=> 'SITE',
		in_tertiary_company_type	=> NULL,
		in_group					=> chain_pkg.ADMIN_GROUP,
		in_capability_type			=> chain_pkg.CT_SUPPLIERS,
		in_capability				=> chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS
	);
END;

PROCEDURE CreateBusinessRelationship(
	out_bus_rel_id				OUT NUMBER
)
AS
	v_bus_rel_id				NUMBER;
	v_bus_rel_period_id			NUMBER;
BEGIN
	SetUpBusRelPerms;

	business_relationship_pkg.CreateBusinessRelationship(
		in_bus_rel_type_id			=> v_annual_bus_rel_type_id,
		out_bus_rel_id				=> v_bus_rel_id
	);

	business_relationship_pkg.SaveBusinessRelationshipPeriod(
		in_bus_rel_id				=> v_bus_rel_id,
		in_bus_rel_period_id		=> NULL,
		in_start_dtm				=> '01-JAN-18',
		in_end_dtm					=> NULL,
		out_bus_rel_period_id		=> v_bus_rel_period_id
	);

	business_relationship_pkg.AddBusinessRelationshipCompany(
		in_bus_rel_id				=> v_bus_rel_id,
		in_bus_rel_tier_id			=> v_annual_bus_rel_tier_id_1,
		in_pos						=> 0,
		in_company_sid				=> v_top_company_sid,
		in_allow_inactive			=> 0
	);

	business_relationship_pkg.AddBusinessRelationshipCompany(
		in_bus_rel_id				=> v_bus_rel_id,
		in_bus_rel_tier_id			=> v_annual_bus_rel_tier_id_2,
		in_pos						=> 0,
		in_company_sid				=> v_vendor_company_sid_1,
		in_allow_inactive			=> 0
	);

	business_relationship_pkg.AddBusinessRelationshipCompany(
		in_bus_rel_id				=> v_bus_rel_id,
		in_bus_rel_tier_id			=> v_annual_bus_rel_tier_id_3,
		in_pos						=> 0,
		in_company_sid				=> v_site_company_sid_1,
		in_allow_inactive			=> 0
	);

	business_relationship_pkg.DidCreateBusinessRelationship(
		in_bus_rel_id				=> v_bus_rel_id,
		in_merge_if_duplicate		=> 0,
		out_bus_rel_id				=> out_bus_rel_id
	);
	
	csr.unit_test_pkg.AssertAreEqual(v_bus_rel_id, out_bus_rel_id, 'Expected business relationship id: '||v_bus_rel_id||', Actual: '||out_bus_rel_id);
END;

PROCEDURE TestCreateBusRel
AS
	v_out_bus_rel_id			NUMBER;
	v_expected_src_records		NUMBER := 4;
	v_actual_src_records		NUMBER;
	v_exists					NUMBER;
BEGIN
	CreateBusinessRelationship(
		out_bus_rel_id				=> v_out_bus_rel_id
	);

	-- CR360 -> Vendor - A -> Site - A
	SELECT COUNT(*)
	  INTO v_actual_src_records
	  FROM supplier_relationship_source
	 WHERE object_id = v_out_bus_rel_id;

	csr.unit_test_pkg.AssertAreEqual(v_expected_src_records, v_actual_src_records, 'Supplier relationship sources for business relationship id '||v_out_bus_rel_id);

	-- Vendor - A -> Site - A
	SELECT COUNT(*)
	  INTO v_exists
	  FROM supplier_relationship
	 WHERE deleted = 0
	   AND purchaser_company_sid = v_vendor_company_sid_1
	   AND supplier_company_sid = v_site_company_sid_1;

	csr.unit_test_pkg.AssertAreEqual(1, v_exists, 'Supplier relationship is not established between '||v_vendor_company_sid_1||' and '||v_site_company_sid_1);
END;

PROCEDURE TestDeleteBusRel
AS
	v_out_bus_rel_id			NUMBER;
	v_bus_rel_period_id			NUMBER;
	v_expected_src_records		NUMBER := 0;
	v_actual_src_records		NUMBER;
	v_exists					NUMBER;
BEGIN
	CreateBusinessRelationship(
		out_bus_rel_id				=> v_out_bus_rel_id
	);

	business_relationship_pkg.DeleteBusinessRelationship(
		in_bus_rel_id				=> v_out_bus_rel_id
	);
	
	SELECT COUNT(*)
	  INTO v_actual_src_records
	  FROM supplier_relationship_source
	 WHERE object_id = v_out_bus_rel_id;

	csr.unit_test_pkg.AssertAreEqual(v_expected_src_records, v_actual_src_records, 'Supplier relationship sources for business relationship id '||v_out_bus_rel_id);

	-- Supplier relationship is also deleted as it was only created by business relationship
	-- Vendor - A -> Site - A
	SELECT COUNT(*)
	  INTO v_exists
	  FROM supplier_relationship
	 WHERE deleted = 1
	   AND purchaser_company_sid = v_vendor_company_sid_1
	   AND supplier_company_sid = v_site_company_sid_1;

	csr.unit_test_pkg.AssertAreEqual(1, v_exists, 'Supplier relationship is not deleted between '||v_vendor_company_sid_1||' and '||v_site_company_sid_1);
END;

PROCEDURE TestDelBusRelExpctAccessDnied1
AS
	v_out_bus_rel_id			NUMBER;
	v_expected_access_denied	NUMBER := 1;
	v_actual_access_denied		NUMBER;
BEGIN
	CreateBusinessRelationship(
		out_bus_rel_id				=> v_out_bus_rel_id
	);

	-- Revoke permisssion
	type_capability_pkg.SetPermission(
		in_primary_company_type		=> 'TOP',
		in_secondary_company_type	=> NULL,
		in_tertiary_company_type	=> NULL,
		in_group					=> chain_pkg.ADMIN_GROUP,
		in_capability_type			=> chain_pkg.CT_COMPANY,
		in_capability				=> chain_pkg.CREATE_BUSINESS_RELATIONSHIPS,
		in_state					=> FALSE
	);

	BEGIN
		business_relationship_pkg.DeleteBusinessRelationship(
			in_bus_rel_id				=> v_out_bus_rel_id
		);
	EXCEPTION
		WHEN security.security_pkg.ACCESS_DENIED THEN
			v_actual_access_denied := 1;
	END;
	
	csr.unit_test_pkg.AssertAreEqual(v_expected_access_denied, v_actual_access_denied, ' Access denied');

	-- Grant permisssions back for tear down
	type_capability_pkg.SetPermission(
		in_primary_company_type		=> 'TOP',
		in_secondary_company_type	=> NULL,
		in_tertiary_company_type	=> NULL,
		in_group					=> chain_pkg.ADMIN_GROUP,
		in_capability_type			=> chain_pkg.CT_COMPANY,
		in_capability				=> chain_pkg.CREATE_BUSINESS_RELATIONSHIPS,
		in_state					=> TRUE
	);	
END;

PROCEDURE TestDelBusRelExpctAccessDnied2
AS
	v_out_bus_rel_id			NUMBER;
	v_expected_access_denied	NUMBER := 1;
	v_actual_access_denied		NUMBER;
BEGIN
	CreateBusinessRelationship(
		out_bus_rel_id				=> v_out_bus_rel_id
	);

	-- Revoke permisssion
	type_capability_pkg.SetPermission(
		in_primary_company_type		=> 'TOP',
		in_secondary_company_type	=> NULL,
		in_tertiary_company_type	=> NULL,
		in_group					=> chain_pkg.ADMIN_GROUP,
		in_capability_type			=> chain_pkg.CT_COMPANY,
		in_capability				=> chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS,
		in_state					=> FALSE
	);

	BEGIN
		business_relationship_pkg.DeleteBusinessRelationship(
			in_bus_rel_id				=> v_out_bus_rel_id
		);
	EXCEPTION
		WHEN security.security_pkg.ACCESS_DENIED THEN
			v_actual_access_denied := 1;
	END;
	
	csr.unit_test_pkg.AssertAreEqual(v_expected_access_denied, v_actual_access_denied, ' Access denied');

	-- Grant permisssions back for tear down
	type_capability_pkg.SetPermission(
		in_primary_company_type		=> 'TOP',
		in_secondary_company_type	=> NULL,
		in_tertiary_company_type	=> NULL,
		in_group					=> chain_pkg.ADMIN_GROUP,
		in_capability_type			=> chain_pkg.CT_COMPANY,
		in_capability				=> chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS,
		in_state					=> TRUE
	);	
END;

PROCEDURE TestDelBusRelExpctAccessDnied3
AS
	v_out_bus_rel_id			NUMBER;
	v_expected_access_denied	NUMBER := 1;
	v_actual_access_denied		NUMBER;
BEGIN
	CreateBusinessRelationship(
		out_bus_rel_id				=> v_out_bus_rel_id
	);

	-- Revoke permisssion
	type_capability_pkg.SetPermission(
		in_primary_company_type		=> 'TOP',
		in_secondary_company_type	=> 'VENDOR',
		in_tertiary_company_type	=> NULL,
		in_group					=> chain_pkg.ADMIN_GROUP,
		in_capability_type			=> chain_pkg.CT_SUPPLIERS,
		in_capability				=> chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS,
		in_state					=> FALSE
	);

	BEGIN
		business_relationship_pkg.DeleteBusinessRelationship(
			in_bus_rel_id				=> v_out_bus_rel_id
		);
	EXCEPTION
		WHEN security.security_pkg.ACCESS_DENIED THEN
			v_actual_access_denied := 1;
	END;
	
	csr.unit_test_pkg.AssertAreEqual(v_expected_access_denied, v_actual_access_denied, ' Access denied');

	-- Grant permisssions back for tear down
	type_capability_pkg.SetPermission(
		in_primary_company_type		=> 'TOP',
		in_secondary_company_type	=> 'VENDOR',
		in_tertiary_company_type	=> NULL,
		in_group					=> chain_pkg.ADMIN_GROUP,
		in_capability_type			=> chain_pkg.CT_SUPPLIERS,
		in_capability				=> chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS,
		in_state					=> TRUE
	);	
END;

PROCEDURE TestDelBusRelExpctAccessDnied4
AS
	v_out_bus_rel_id			NUMBER;
	v_expected_access_denied	NUMBER := 1;
	v_actual_access_denied		NUMBER;
BEGIN
	CreateBusinessRelationship(
		out_bus_rel_id				=> v_out_bus_rel_id
	);

	-- Revoke permisssion
	type_capability_pkg.SetPermission(
		in_primary_company_type		=> 'TOP',
		in_secondary_company_type	=> 'VENDOR',
		in_tertiary_company_type	=> 'SITE',
		in_group					=> chain_pkg.ADMIN_GROUP,
		in_capability_type			=> chain_pkg.CT_ON_BEHALF_OF,
		in_capability				=> chain_pkg.ADD_REMOVE_RELATIONSHIPS,
		in_state					=> FALSE
	);

	BEGIN
		business_relationship_pkg.DeleteBusinessRelationship(
			in_bus_rel_id				=> v_out_bus_rel_id
		);
	EXCEPTION
		WHEN chain_pkg.BUS_REL_DELETE_FAILED THEN
			v_actual_access_denied := 1;
	END;

	csr.unit_test_pkg.AssertAreEqual(v_expected_access_denied, v_actual_access_denied, ' Access denied');

	-- Grant permisssions back for tear down
	type_capability_pkg.SetPermission(
		in_primary_company_type		=> 'TOP',
		in_secondary_company_type	=> 'VENDOR',
		in_tertiary_company_type	=> 'SITE',
		in_group					=> chain_pkg.ADMIN_GROUP,
		in_capability_type			=> chain_pkg.CT_ON_BEHALF_OF,
		in_capability				=> chain_pkg.ADD_REMOVE_RELATIONSHIPS,
		in_state					=> TRUE
	);
END;

PROCEDURE TestDelBusRelExpctAccessDnied5
AS
	v_out_bus_rel_id			NUMBER;
	v_expected_access_denied	NUMBER := 1;
	v_actual_access_denied		NUMBER;
BEGIN
	CreateBusinessRelationship(
		out_bus_rel_id				=> v_out_bus_rel_id
	);

	-- Revoke permisssion
	type_capability_pkg.SetPermission(
		in_primary_company_type		=> 'TOP',
		in_secondary_company_type	=> 'SITE',
		in_tertiary_company_type	=> NULL,
		in_group					=> chain_pkg.ADMIN_GROUP,
		in_capability_type			=> chain_pkg.CT_SUPPLIERS,
		in_capability				=> chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS,
		in_state					=> FALSE
	);

	BEGIN
		business_relationship_pkg.DeleteBusinessRelationship(
			in_bus_rel_id				=> v_out_bus_rel_id
		);
	EXCEPTION
		WHEN security.security_pkg.ACCESS_DENIED THEN
			v_actual_access_denied := 1;
	END;
	
	csr.unit_test_pkg.AssertAreEqual(v_expected_access_denied, v_actual_access_denied, ' Access denied');

	-- Grant permisssions back for tear down
	type_capability_pkg.SetPermission(
		in_primary_company_type		=> 'TOP',
		in_secondary_company_type	=> 'SITE',
		in_tertiary_company_type	=> NULL,
		in_group					=> chain_pkg.ADMIN_GROUP,
		in_capability_type			=> chain_pkg.CT_SUPPLIERS,
		in_capability				=> chain_pkg.ADD_TO_BUSINESS_RELATIONSHIPS,
		in_state					=> TRUE
	);	
END;

END;
/
