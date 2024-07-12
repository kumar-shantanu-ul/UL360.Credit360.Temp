CREATE OR REPLACE PACKAGE BODY chain.test_chain_capability_pkg AS

-- *** PRIVATE ***
v_site_name				VARCHAR2(200);
v_top_company_sid		NUMBER(10);

v_vendor_1				NUMBER(10);
v_vendor_2				NUMBER(10);
v_vendor_3				NUMBER(10); -- Vendor with no relationships to any sites

v_site_1				NUMBER(10); -- Standard purchaser: Vendor 1
v_site_2				NUMBER(10); -- Primary purchaser: Vendor 1|Standard purchaser: Vendor 2
v_site_3				NUMBER(10); -- Owner: Vendor 1|Standard purchaser: Vendor 2
v_site_4				NUMBER(10);	-- Deleted relationship with vendor 1

-- Vendor 1
v_user_1				NUMBER(10);
v_user_4				NUMBER(10); -- Has company type role on vendor
-- Vendor 2
v_user_2				NUMBER(10);
-- Vendor 3
v_user_3				NUMBER(10);

v_tc_user				NUMBER(10);


v_ct_role_sid			NUMBER(10);

PROCEDURE LogonAsUser(
	in_user_sid			NUMBER,
	in_company_sid		NUMBER
)
AS
	v_app_sid						security.security_pkg.T_SID_ID := security.security_pkg.GetApp;
	v_act_id						security.security_pkg.T_ACT_ID;
BEGIN
	-- Take non autonomous tranaction code from logonauthenticated so can keep 1 session;
	v_act_id := security.user_pkg.GenerateACT();
	security.Security_pkg.SetACTAndSID(v_act_id, in_user_sid);
	security.Security_pkg.SetApp(v_app_sid);
	security.Act_Pkg.Issue(in_user_sid, v_act_id, NULL, v_app_sid);
	csr.csr_user_pkg.LogOn(v_act_id, in_user_sid, NULL, security.security_pkg.LOGON_TYPE_BATCH);
	----------------------------------------------------------------------------------------------
	company_pkg.SetCompany(in_company_sid);
END;

PROCEDURE CreateCompanies
AS
	v_empty_strings			chain_pkg.T_STRINGS;
	v_cur					security.security_pkg.T_OUTPUT_CUR;
BEGIN
	UPDATE company_type_relationship
	   SET can_be_primary = 1
	 WHERE primary_company_type_id = company_type_pkg.GetCompanyTypeId('VENDOR')
	   AND secondary_company_type_id = company_type_pkg.GetCompanyTypeId('SITE');

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Vendor 1',
		in_country_code		=> 'gb',
		in_company_type_id	=> company_type_pkg.GetCompanyTypeId('VENDOR'),
		in_sector_id		=> NULL,
		out_company_sid		=> v_vendor_1
	);

	company_type_pkg.SetCompanyTypeRole (
		in_company_type_id		=> company_type_pkg.GetCompanyTypeId('VENDOR'),
		in_role_name			=> 'Vendor role',
		in_mandatory			=> 0,
		in_cascade_to_supplier	=> 0,
		out_cur					=> v_cur
	);
	
	SELECT role_sid
	  INTO v_ct_role_sid
	  FROM csr.role
	 WHERE name = 'Vendor role';
	
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Vendor 2',
		in_country_code		=> 'gb',
		in_company_type_id	=> company_type_pkg.GetCompanyTypeId('VENDOR'),
		in_sector_id		=> NULL,
		out_company_sid		=> v_vendor_2
	);
	
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Vendor 3',
		in_country_code		=> 'gb',
		in_company_type_id	=> company_type_pkg.GetCompanyTypeId('VENDOR'),
		in_sector_id		=> NULL,
		out_company_sid		=> v_vendor_3
	);
	
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Site 1',
		in_country_code		=> 'gb',
		in_company_type_id	=> company_type_pkg.GetCompanyTypeId('SITE'),
		in_sector_id		=> NULL,
		out_company_sid		=> v_site_1
	);
	
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Site 2',
		in_country_code		=> 'gb',
		in_company_type_id	=> company_type_pkg.GetCompanyTypeId('SITE'),
		in_sector_id		=> NULL,
		out_company_sid		=> v_site_2
	);
	
	company_pkg.CreateSubCompany(
		in_parent_sid				=> v_vendor_1,
		in_name						=> 'Site 3',
		in_country_code				=> 'gb',
		in_company_type_id			=> company_type_pkg.GetCompanyTypeId('SITE'),
		in_sector_id				=> NULL,
		out_company_sid				=> v_site_3
	);
	
	company_pkg.CreateSubCompany(
		in_parent_sid				=> v_vendor_1,
		in_name						=> 'Site 4',
		in_country_code				=> 'gb',
		in_company_type_id			=> company_type_pkg.GetCompanyTypeId('SITE'),
		in_sector_id				=> NULL,
		out_company_sid				=> v_site_4
	);
	
	company_pkg.StartRelationship(v_vendor_1, v_site_1, NULL);
	company_pkg.ActivateRelationship(v_vendor_1, v_site_1);
	
	company_pkg.StartRelationship(v_vendor_1, v_site_2, NULL);
	company_pkg.ActivateRelationship(v_vendor_1, v_site_2);
	company_pkg.SetRelationshipAsPrimary(v_vendor_1, v_site_2);
	
	company_pkg.StartRelationship(v_vendor_2, v_site_2, NULL);
	company_pkg.ActivateRelationship(v_vendor_2, v_site_2);
	
	company_pkg.StartRelationship(v_vendor_2, v_site_3, NULL);
	company_pkg.ActivateRelationship(v_vendor_2, v_site_3);
	
	company_pkg.StartRelationship(v_vendor_1, v_site_4, NULL);
	company_pkg.ActivateRelationship(v_vendor_1, v_site_4);
	company_pkg.DeleteRelationship(
		in_purchaser_company_sid		=> v_vendor_1,
		in_supplier_company_sid			=> v_site_4
	);
END;

PROCEDURE CreateUsers
AS
	v_role_sids					helper_pkg.T_NUMBER_ARRAY;
BEGIN
	v_tc_user := company_user_pkg.CreateUser(
		in_company_sid			=> v_top_company_sid,
		in_full_name			=> 'TC',
		in_friendly_name		=> 'TC',
		in_email				=> 'tc@cdsc.dcd',
		in_user_name			=> 'tc',
		in_phone_number			=> NULL,
		in_job_title			=> NULL
	);
	
	company_user_pkg.SetVisibility(v_tc_user, chain_pkg.FULL);
	company_user_pkg.AddUserToCompany(v_top_company_sid, v_tc_user);
	company_user_pkg.ActivateUser(v_tc_user);

	v_user_1 := company_user_pkg.CreateUser(
		in_company_sid			=> v_vendor_1,
		in_full_name			=> 'User 1',
		in_friendly_name		=> 'User 1',
		in_email				=> 'user1@cdsc.dcd',
		in_user_name			=> 'user1',
		in_phone_number			=> NULL,
		in_job_title			=> NULL
	);
	
	company_user_pkg.SetVisibility(v_user_1, chain_pkg.FULL);
	company_user_pkg.AddUserToCompany(v_vendor_1, v_user_1);
	company_user_pkg.ActivateUser(v_user_1);
	
	v_user_4 := company_user_pkg.CreateUser(
		in_company_sid			=> v_vendor_1,
		in_full_name			=> 'User 4',
		in_friendly_name		=> 'User 4',
		in_email				=> 'user4@cdsc.dcd',
		in_user_name			=> 'user4',
		in_phone_number			=> NULL,
		in_job_title			=> NULL
	);
	
	company_user_pkg.SetVisibility(v_user_4, chain_pkg.FULL);
	company_user_pkg.AddUserToCompany(v_vendor_1, v_user_4);
	company_user_pkg.ActivateUser(v_user_4);
	v_role_sids(1) := v_ct_role_sid;
	company_user_pkg.SetCompanyTypeRoles(v_vendor_1,v_user_4,v_role_sids);
	
	v_user_2 := company_user_pkg.CreateUser(
		in_company_sid			=> v_vendor_2,
		in_full_name			=> 'User 2',
		in_friendly_name		=> 'User 2',
		in_email				=> 'user2@cdsc.dcd',
		in_user_name			=> 'user2',
		in_phone_number			=> NULL,
		in_job_title			=> NULL
	);
	
	company_user_pkg.SetVisibility(v_user_2, chain_pkg.FULL);
	company_user_pkg.AddUserToCompany(v_vendor_2, v_user_2);
	company_user_pkg.ActivateUser(v_user_2);
	
	v_user_3 := company_user_pkg.CreateUser(
		in_company_sid			=> v_vendor_3,
		in_full_name			=> 'User 3',
		in_friendly_name		=> 'User 3',
		in_email				=> 'user3@cdsc.dcd',
		in_user_name			=> 'user3',
		in_phone_number			=> NULL,
		in_job_title			=> NULL
	);
	
	company_user_pkg.SetVisibility(v_user_3, chain_pkg.FULL);
	company_user_pkg.AddUserToCompany(v_vendor_3, v_user_3);
	company_user_pkg.ActivateUser(v_user_3);
END;

PROCEDURE SaveCustomerInvolvementType(
	in_involvement_type_id	IN NUMBER,
	in_label				IN VARCHAR2,
	in_product_area			IN VARCHAR2,
	in_flow_alert_classes	IN VARCHAR2,
	in_lookup_key			IN VARCHAR2,
	in_user_company_type_id	IN NUMBER,
	in_page_company_type_id	IN NUMBER,
	in_purchaser_type		IN NUMBER,
	in_restrict_to_role_sid	IN NUMBER,
	out_involvement_type_id	OUT NUMBER
)
AS
	v_flow_inv_type_id				NUMBER;
	v_flow_alert_classes			security.security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	SELECT column_value
	  BULK COLLECT INTO v_flow_alert_classes
	  FROM TABLE(aspen2.utils_pkg.SplitString2(in_flow_alert_classes));
	
	csr.flow_pkg.SaveCustomerInvolvementType (
		in_involvement_type_id			=> in_involvement_type_id,
		in_label						=> in_label,
		in_product_area					=> in_product_area,
		in_flow_alert_classes			=> v_flow_alert_classes,
		in_lookup_key					=> in_lookup_key,
		out_involvement_type_id			=> v_flow_inv_type_id
	);
	chain.supplier_flow_pkg.SetSupplierInvolvementType(
		in_involvement_type_id			=> v_flow_inv_type_id,
		in_user_company_type_id			=> in_user_company_type_id,
		in_page_company_type_id			=> in_page_company_type_id,
		in_purchaser_type				=> in_purchaser_type,
		in_restrict_to_role_sid			=> in_restrict_to_role_sid
	);
END;

PROCEDURE SetupInvolvementTypes
AS
	v_flow_inv_type_id				NUMBER;
BEGIN
	-- Should exist out-of-the-box, but just make sure
	SaveCustomerInvolvementType (
		in_involvement_type_id			=> csr.csr_data_pkg.FLOW_INV_TYPE_PURCHASER,
		in_label						=> 'Purchaser',
		in_product_area					=> 'supplier',
		in_flow_alert_classes			=> 'supplier',
		in_lookup_key					=> 'PURCHASER',
		in_user_company_type_id			=> NULL,
		in_page_company_type_id			=> NULL,
		in_purchaser_type				=> chain_pkg.PURCHASER_TYPE_ANY,
		in_restrict_to_role_sid			=> NULL,
		out_involvement_type_id			=> v_flow_inv_type_id
	);
	
	SaveCustomerInvolvementType (
		in_involvement_type_id			=> NULL,
		in_label						=> 'Factory primary purchaser',
		in_product_area					=> 'supplier',
		in_flow_alert_classes			=> 'supplier',
		in_lookup_key					=> 'PRIM_PURCHASER',
		in_user_company_type_id			=> NULL,
		in_page_company_type_id			=> NULL,
		in_purchaser_type				=> chain_pkg.PURCHASER_TYPE_PRIMARY,
		in_restrict_to_role_sid			=> NULL,
		out_involvement_type_id			=> v_flow_inv_type_id
	);
	
	SaveCustomerInvolvementType (
		in_involvement_type_id			=> NULL,
		in_label						=> 'Factory owner',
		in_product_area					=> 'supplier',
		in_flow_alert_classes			=> 'supplier',
		in_lookup_key					=> 'OWNER',
		in_user_company_type_id			=> NULL,
		in_page_company_type_id			=> NULL,
		in_purchaser_type				=> chain_pkg.PURCHASER_TYPE_OWNER,
		in_restrict_to_role_sid			=> NULL,
		out_involvement_type_id			=> v_flow_inv_type_id
	);
	
	SaveCustomerInvolvementType (
		in_involvement_type_id			=> NULL,
		in_label						=> 'Vendor role',
		in_product_area					=> 'supplier',
		in_flow_alert_classes			=> 'supplier',
		in_lookup_key					=> 'VENDOR_ROLE',
		in_user_company_type_id			=> company_type_pkg.GetCompanyTypeId('VENDOR'),
		in_page_company_type_id			=> NULL,
		in_purchaser_type				=> chain_pkg.PURCHASER_TYPE_ANY,
		in_restrict_to_role_sid			=> v_ct_role_sid,
		out_involvement_type_id			=> v_flow_inv_type_id
	);
	
	SaveCustomerInvolvementType (
		in_involvement_type_id			=> NULL,
		in_label						=> 'Vendor role and primary',
		in_product_area					=> 'supplier',
		in_flow_alert_classes			=> 'supplier',
		in_lookup_key					=> 'VENDOR_ROLE_PRIM',
		in_user_company_type_id			=> company_type_pkg.GetCompanyTypeId('VENDOR'),
		in_page_company_type_id			=> NULL,
		in_purchaser_type				=> chain_pkg.PURCHASER_TYPE_PRIMARY,
		in_restrict_to_role_sid			=> v_ct_role_sid,
		out_involvement_type_id			=> v_flow_inv_type_id
	);
	
	SaveCustomerInvolvementType (
		in_involvement_type_id			=> NULL,
		in_label						=> 'Vendor role and owner',
		in_product_area					=> 'supplier',
		in_flow_alert_classes			=> 'supplier',
		in_lookup_key					=> 'VENDOR_ROLE_OWNER',
		in_user_company_type_id			=> company_type_pkg.GetCompanyTypeId('VENDOR'),
		in_page_company_type_id			=> NULL,
		in_purchaser_type				=> chain_pkg.PURCHASER_TYPE_OWNER,
		in_restrict_to_role_sid			=> v_ct_role_sid,
		out_involvement_type_id			=> v_flow_inv_type_id
	);
	
	SaveCustomerInvolvementType (
		in_involvement_type_id			=> NULL,
		in_label						=> 'Specific purchaser',
		in_product_area					=> 'supplier',
		in_flow_alert_classes			=> 'supplier',
		in_lookup_key					=> 'PURCHASER_VEND',
		in_user_company_type_id			=> company_type_pkg.GetCompanyTypeId('VENDOR'),
		in_page_company_type_id			=> NULL,
		in_purchaser_type				=> chain_pkg.PURCHASER_TYPE_ANY,
		in_restrict_to_role_sid			=> NULL,
		out_involvement_type_id			=> v_flow_inv_type_id
	);
	
	SaveCustomerInvolvementType (
		in_involvement_type_id			=> NULL,
		in_label						=> 'Specific supplier',
		in_product_area					=> 'supplier',
		in_flow_alert_classes			=> 'supplier',
		in_lookup_key					=> 'SUPPLIER_FAC',
		in_user_company_type_id			=> NULL,
		in_page_company_type_id			=> company_type_pkg.GetCompanyTypeId('SITE'),
		in_purchaser_type				=> chain_pkg.PURCHASER_TYPE_ANY,
		in_restrict_to_role_sid			=> NULL,
		out_involvement_type_id			=> v_flow_inv_type_id
	);
	
	SaveCustomerInvolvementType (
		in_involvement_type_id			=> NULL,
		in_label						=> 'Vendor to factory',
		in_product_area					=> 'supplier',
		in_flow_alert_classes			=> 'supplier',
		in_lookup_key					=> 'VENDOR_FACTORY',
		in_user_company_type_id			=> company_type_pkg.GetCompanyTypeId('VENDOR'),
		in_page_company_type_id			=> company_type_pkg.GetCompanyTypeId('SITE'),
		in_purchaser_type				=> chain_pkg.PURCHASER_TYPE_ANY,
		in_restrict_to_role_sid			=> NULL,
		out_involvement_type_id			=> v_flow_inv_type_id
	);
END;

FUNCTION GetInvolvementType(
	in_lookup_key				VARCHAR2
)
RETURN NUMBER
AS
	v_inv_type_id			NUMBER;
BEGIN
	SELECT flow_involvement_type_id
	  INTO v_inv_type_id
	  FROM csr.flow_involvement_type
	 WHERE lookup_key = in_lookup_key;
	
	RETURN v_inv_type_id;
END;

PROCEDURE AssertUserInvolvement(
	in_involvement_type_id	NUMBER,
	in_supplier_sid			NUMBER,
	in_is_involved			NUMBER
)
AS
	v_is_involved			NUMBER;
	v_cnt					NUMBER;
BEGIN
	SELECT DECODE(COUNT(*), 0, 0, 1)
	  INTO v_cnt
	  FROM v$purchaser_involvement
	 WHERE flow_involvement_type_id = in_involvement_type_id
	   AND supplier_company_sid = in_supplier_sid;
	
	csr.unit_test_pkg.AssertAreEqual(v_cnt, in_is_involved, 'User 1 should ' || CASE WHEN in_is_involved = 0 THEN 'not ' ELSE '' END || 'be a purchaser for Site 1');
END;

--*** PUBLIC ***
PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);

	test_chain_utils_pkg.SetupTwoTier;
	
	SELECT top_company_sid
	  INTO v_top_company_sid
	  FROM customer_options
	 WHERE app_sid = security.security_pkg.GetApp;
	
	CreateCompanies;
	CreateUsers;
	SetupInvolvementTypes;
END;

PROCEDURE SetSite(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
END;

PROCEDURE SetUp
AS
BEGIN
	NULL;
END;

PROCEDURE TearDown
AS
BEGIN
	NULL;
END;

PROCEDURE TearDownFixture
AS
	v_purchaser_inv_type_id			NUMBER;
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	
	BEGIN
		SELECT flow_involvement_type_id
		  INTO v_purchaser_inv_type_id
		  FROM csr.flow_involvement_type
		 WHERE lookup_key = 'PURCHASER';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_purchaser_inv_type_id := 0;
	END;
	
	FOR r IN (
		SELECT flow_involvement_type_id
		  FROM supplier_involvement_type
		 WHERE app_sid = security.security_pkg.GetApp
	)
	LOOP
		IF r.flow_involvement_type_id <> v_purchaser_inv_type_id THEN
			chain.supplier_flow_pkg.DeleteSupplierInvolvementType(r.flow_involvement_type_id);
			csr.flow_pkg.DeleteCustomerInvolvementType(r.flow_involvement_type_id);
		END IF;
	END LOOP;
	
	test_chain_utils_pkg.TearDownSingleTier;
	test_chain_utils_pkg.TearDownTwoTier;

	DELETE FROM sector;
END;

/* ** TESTS ** */

/*
	Tests are designed to have one per combination of company type/role/purchaser type options (and as such are not
	complete). As a rule, all user involvements are checked for each test (although in many cases this probably doesn't
	say anything meaningful).
*/

PROCEDURE Test_PurchaserInvolvement
AS
	v_inv_type_id			NUMBER;
BEGIN
	v_inv_type_id := GetInvolvementType('PURCHASER');
	
	LogonAsUser(v_tc_user, v_top_company_sid);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0); -- We created this as a subsid of a vendor but didn't link it to the top company
	AssertUserInvolvement(v_inv_type_id, v_vendor_1, 1);
	
	LogonAsUser(v_user_1, v_vendor_1);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 1);
	
	LogonAsUser(v_user_2, v_vendor_2);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 1);
	
	LogonAsUser(v_user_3, v_vendor_3);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	
	LogonAsUser(v_user_4, v_vendor_1);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 1);
END;

PROCEDURE Test_PrimPurchaserInvolvement
AS
	v_inv_type_id			NUMBER;
	v_cnt							NUMBER;
BEGIN
	v_inv_type_id := GetInvolvementType('PRIM_PURCHASER');
	
	LogonAsUser(v_tc_user, v_top_company_sid);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	AssertUserInvolvement(v_inv_type_id, v_vendor_1, 0);
	
	LogonAsUser(v_user_1, v_vendor_1);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	
	LogonAsUser(v_user_2, v_vendor_2);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	
	LogonAsUser(v_user_3, v_vendor_3);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	
	LogonAsUser(v_user_4, v_vendor_1);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
END;

PROCEDURE Test_OwnerInvolvement
AS
	v_inv_type_id			NUMBER;
	v_cnt							NUMBER;
BEGIN
	v_inv_type_id := GetInvolvementType('OWNER');
	
	LogonAsUser(v_tc_user, v_top_company_sid);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	AssertUserInvolvement(v_inv_type_id, v_vendor_1, 0);
	
	LogonAsUser(v_user_1, v_vendor_1);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 1);
	
	LogonAsUser(v_user_2, v_vendor_2);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	
	LogonAsUser(v_user_3, v_vendor_3);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	
	LogonAsUser(v_user_4, v_vendor_1);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 1);
END;

PROCEDURE Test_RoleInvolvement
AS
	v_inv_type_id			NUMBER;
	v_cnt							NUMBER;
BEGIN
	v_inv_type_id := GetInvolvementType('VENDOR_ROLE');
	
	LogonAsUser(v_tc_user, v_top_company_sid);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	AssertUserInvolvement(v_inv_type_id, v_vendor_1, 0);
	
	LogonAsUser(v_user_1, v_vendor_1);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	
	LogonAsUser(v_user_2, v_vendor_2);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	
	LogonAsUser(v_user_3, v_vendor_3);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	
	LogonAsUser(v_user_4, v_vendor_1);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 1);
END;

PROCEDURE Test_RoleWithPrimaryInv
AS
	v_inv_type_id			NUMBER;
	v_cnt							NUMBER;
BEGIN
	v_inv_type_id := GetInvolvementType('VENDOR_ROLE_PRIM');
	
	LogonAsUser(v_tc_user, v_top_company_sid);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	AssertUserInvolvement(v_inv_type_id, v_vendor_1, 0);
	
	LogonAsUser(v_user_1, v_vendor_1);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	
	LogonAsUser(v_user_2, v_vendor_2);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	
	LogonAsUser(v_user_3, v_vendor_3);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	
	LogonAsUser(v_user_4, v_vendor_1);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
END;

PROCEDURE Test_RoleWithOwnerInv
AS
	v_inv_type_id			NUMBER;
	v_cnt							NUMBER;
BEGIN
	v_inv_type_id := GetInvolvementType('VENDOR_ROLE_OWNER');
	
	LogonAsUser(v_tc_user, v_top_company_sid);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	AssertUserInvolvement(v_inv_type_id, v_vendor_1, 0);
	
	LogonAsUser(v_user_1, v_vendor_1);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	
	LogonAsUser(v_user_2, v_vendor_2);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	
	LogonAsUser(v_user_3, v_vendor_3);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	
	LogonAsUser(v_user_4, v_vendor_1);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 1);
END;

PROCEDURE Test_SpecificPurchaser
AS
	v_inv_type_id			NUMBER;
BEGIN
	v_inv_type_id := GetInvolvementType('PURCHASER_VEND');
	
	LogonAsUser(v_tc_user, v_top_company_sid);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	AssertUserInvolvement(v_inv_type_id, v_vendor_1, 0);
	
	LogonAsUser(v_user_1, v_vendor_1);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 1);
	
	LogonAsUser(v_user_2, v_vendor_2);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 1);
	
	LogonAsUser(v_user_3, v_vendor_3);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	
	LogonAsUser(v_user_4, v_vendor_1);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 1);
END;

PROCEDURE Test_SpecificSupplier
AS
	v_inv_type_id			NUMBER;
BEGIN
	v_inv_type_id := GetInvolvementType('SUPPLIER_FAC');
	
	LogonAsUser(v_tc_user, v_top_company_sid);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	AssertUserInvolvement(v_inv_type_id, v_vendor_1, 0);
	
	LogonAsUser(v_user_1, v_vendor_1);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 1);
	
	LogonAsUser(v_user_2, v_vendor_2);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 1);
	
	LogonAsUser(v_user_3, v_vendor_3);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	
	LogonAsUser(v_user_4, v_vendor_1);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 1);
END;

PROCEDURE Test_SpecificPurAndSupp
AS
	v_inv_type_id			NUMBER;
BEGIN
	v_inv_type_id := GetInvolvementType('VENDOR_FACTORY');
	-- Doesn't currently cover a case where the purchaser is a vendor but the
	-- supplier is not a factory (will need an extra company type for this)
	
	LogonAsUser(v_tc_user, v_top_company_sid);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	AssertUserInvolvement(v_inv_type_id, v_vendor_1, 0);
	
	LogonAsUser(v_user_1, v_vendor_1);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 1);
	
	LogonAsUser(v_user_2, v_vendor_2);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 1);
	
	LogonAsUser(v_user_3, v_vendor_3);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 0);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 0);
	
	LogonAsUser(v_user_4, v_vendor_1);
	AssertUserInvolvement(v_inv_type_id, v_site_1, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_2, 1);
	AssertUserInvolvement(v_inv_type_id, v_site_3, 1);
END;

PROCEDURE Test_DeletedRelationship
AS
	v_inv_type_id			NUMBER;
BEGIN
	v_inv_type_id := GetInvolvementType('PURCHASER');
		
	LogonAsUser(v_user_1, v_vendor_1);
	AssertUserInvolvement(v_inv_type_id, v_site_4, 0);
	
	LogonAsUser(v_user_4, v_vendor_1);
	AssertUserInvolvement(v_inv_type_id, v_site_4, 0);
END;

PROCEDURE Test_CapabilityGroups
AS
	v_first_capability_id	NUMBER;
	v_new_capability_group_id	NUMBER;
	v_capability_group_id	NUMBER(10, 0);
	v_group_name			VARCHAR2(255);
	v_group_position		NUMBER(10, 0);
	v_is_visible			NUMBER(1, 0);
	v_count					NUMBER(10, 0):= 0;
	v_data_cur 				security_pkg.T_OUTPUT_CUR;
BEGIN
	v_new_capability_group_id := 9999;

	
	INSERT INTO chain.capability_group 
	VALUES (v_new_capability_group_id, 'Test Group', 0, 1);

	BEGIN
		capability_pkg.GetCapabilityGroups(v_data_cur);
	END;

	LOOP
		FETCH v_data_cur 
		INTO  v_capability_group_id, v_group_name, v_group_position, v_is_visible;
		EXIT WHEN v_data_cur%NOTFOUND;
		v_count := v_count + 1;

		IF v_capability_group_id = v_new_capability_group_id AND (v_group_name != 'Test Group' OR v_group_position != 0 OR v_is_visible != 1) THEN
			csr.unit_test_pkg.TestFail('Unexpected capability group found');
		END IF;
	END LOOP;

	csr.unit_test_pkg.AssertIsTrue(v_count > 0, 'Expected cur entries');

	DELETE FROM chain.capability_group WHERE capability_group_id = v_new_capability_group_id;

END;


END;
/