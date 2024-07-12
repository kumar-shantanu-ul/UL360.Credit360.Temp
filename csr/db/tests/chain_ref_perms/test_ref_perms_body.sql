CREATE OR REPLACE PACKAGE BODY chain.test_ref_perms_pkg
IS

v_site_name						VARCHAR2(200);
v_act_id						security.security_pkg.T_ACT_ID;
v_app_sid						security.security_pkg.T_SID_ID;
v_user_sid						security.security_pkg.T_SID_ID;
v_sa_user_sid					security.security_pkg.T_SID_ID;
v_sa_group_sid					security.security_pkg.T_SID_ID;

v_vendor_company_type_id		NUMBER;
v_vendor_company_sid			security.security_pkg.T_SID_ID;
v_vendor_company_group_sid		security.security_pkg.T_SID_ID;
v_vendor_company_role_sid		security.security_pkg.T_SID_ID;

v_other_vendor_company_sid		security.security_pkg.T_SID_ID;

v_site_company_type_id			NUMBER;
v_site_company_sid				security.security_pkg.T_SID_ID;

v_reference_id_1				NUMBER;
v_reference_id_2				NUMBER;

PROCEDURE LogOnAsAdmin
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
END;

PROCEDURE LogOnAsUser
AS
BEGIN
	security.user_pkg.LogonAuthenticated(v_user_sid, 172800, v_act_id);
	company_pkg.SetCompany(v_vendor_company_sid);
END;

PROCEDURE LogOnAsSuperAdmin
AS
BEGIN
	security.user_pkg.LogonAuthenticated(v_sa_user_sid, 172800, v_act_id);
	company_pkg.SetCompany(v_vendor_company_sid);
END;

PROCEDURE ClearPermissions
AS
BEGIN
	DELETE FROM reference_capability;
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_company_type_ids			helper_pkg.T_NUMBER_ARRAY;
	v_dummy_cur					security_pkg.T_OUTPUT_CUR;
BEGIN
	v_site_name := in_site_name;
	LogOnAsAdmin;

	test_chain_utils_pkg.SetupTwoTier;
	
	v_vendor_company_type_id := company_type_pkg.GetCompanyTypeId('VENDOR');
	v_site_company_type_id := company_type_pkg.GetCompanyTypeId('SITE');

	-- Allow relationships between vendors and vendors

	company_type_pkg.AddCompanyTypeRelationship (
		in_company_type				=> 'VENDOR',
		in_related_company_type		=> 'VENDOR',
		in_use_user_roles			=> 0
	);

	-- Get a group and a role for vendor companies

	v_vendor_company_group_sid := company_pkg.GetCompanyGroupTypeId(chain_pkg.ADMIN_GROUP);

	csr.role_pkg.SetRole('Test role', v_vendor_company_role_sid);
	company_type_pkg.SetCompanyTypeRole(
		in_company_type_id => v_vendor_company_type_id,
		in_role_sid => v_vendor_company_role_sid,
		in_mandatory => 0,
		out_cur => v_dummy_cur
	);
	
	-- Create a vendor company

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> 'Test vendor',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_vendor_company_type_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_vendor_company_sid
	);
	company_pkg.ActivateCompany(v_vendor_company_sid);

	-- Create another vendor company

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> 'Test other vendor',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_vendor_company_type_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_other_vendor_company_sid
	);
	company_pkg.ActivateCompany(v_other_vendor_company_sid);

	company_pkg.StartRelationship(v_vendor_company_sid, v_other_vendor_company_sid, NULL);
	company_pkg.ActivateRelationship(v_vendor_company_sid, v_other_vendor_company_sid);
	
	-- Create a site company

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> 'Test site',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_site_company_type_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_site_company_sid
	);
	company_pkg.ActivateCompany(v_site_company_sid);

	company_pkg.StartRelationship(v_vendor_company_sid, v_site_company_sid, NULL);
	company_pkg.ActivateRelationship(v_vendor_company_sid, v_site_company_sid);

	-- Create a user

	csr.csr_user_pkg.CreateUser(
		in_act			 				=> v_act_id,
		in_app_sid						=> v_app_sid,
		in_user_name					=> 'testy',
		in_password 					=> NULL,
		in_full_name					=> 'Testy McTest',
		in_friendly_name				=> 'Testy',
		in_email						=> 'testy.mctest@example.com',
		in_info_xml						=> NULL,
		in_send_alerts					=> 0,
		out_user_sid 					=> v_user_sid
	);

	company_user_pkg.AddUserToCompany_UNSEC (
		in_company_sid					=> v_vendor_company_sid,
		in_user_sid						=> v_user_sid,
		in_force_admin					=> 1
	);

	-- Add the user to the role (they should already be an admin)
	
	company_user_pkg.UNSEC_AddCompanyTypeRoleToUser(
		in_company_sid					=> v_vendor_company_sid,
		in_user_sid						=> v_user_sid,
		in_role_sid						=> v_vendor_company_role_sid
	);

	-- Create a (fake) super admin
	
	csr.csr_user_pkg.CreateUser(
		in_act			 				=> v_act_id,
		in_app_sid						=> v_app_sid,
		in_user_name					=> 'superman',
		in_password 					=> NULL,
		in_full_name					=> 'Clark Kent',
		in_friendly_name				=> 'Superman',
		in_email						=> 'clark.kent@dailyplanet.com',
		in_info_xml						=> NULL,
		in_send_alerts					=> 0,
		out_user_sid 					=> v_sa_user_sid
	);
	
	v_sa_group_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, security_pkg.SID_ROOT, '//csr/SuperAdmins');
	security.group_pkg.AddMember(v_act_id, v_sa_user_sid, v_sa_group_sid);
	
	-- Create two references

	helper_pkg.SaveReferenceLabel (
		in_reference_id						=> NULL,
		in_lookup_key						=> 'REF1',
		in_label							=> 'Reference 1',
		in_mandatory						=> 0,
		in_reference_uniqueness_id			=> chain_pkg.REF_UNIQUE_NONE,
		in_company_type_ids					=> v_company_type_ids,
		out_reference_id					=> v_reference_id_1
	);
	
	helper_pkg.SaveReferenceLabel (
		in_reference_id						=> NULL,
		in_lookup_key						=> 'REF2',
		in_label							=> 'Reference 2',
		in_mandatory						=> 0,
		in_reference_uniqueness_id			=> chain_pkg.REF_UNIQUE_NONE,
		in_company_type_ids					=> v_company_type_ids,
		out_reference_id					=> v_reference_id_2
	);
	
	COMMIT;
END;

PROCEDURE SetUp
AS
BEGIN
	LogOnAsUser;
END;

PROCEDURE TearDown
AS
BEGIN
	ClearPermissions;
END;

PROCEDURE TearDownFixture
AS
BEGIN
	LogOnAsAdmin;

	IF v_user_sid IS NOT NULL THEN
		csr.csr_user_pkg.DeleteUser(
			in_act						=> v_act_id,
			in_user_sid					=> v_user_sid
		);
	END IF;
	
	IF v_sa_user_sid IS NOT NULL THEN
		csr.csr_user_pkg.DeleteUser(
			in_act						=> v_act_id,
			in_user_sid					=> v_sa_user_sid
		);
	END IF;
	
	IF v_vendor_company_role_sid IS NOT NULL THEN
		company_type_pkg.DeleteCompanyTypeRole(
			in_company_type_id			=> v_vendor_company_type_id,
			in_role_sid					=> v_vendor_company_role_sid
		);
	END IF;
	
	IF v_vendor_company_sid IS NOT NULL THEN
		chain.company_pkg.DeleteCompanyFully(
			in_company_sid				=> v_vendor_company_sid
		);
	END IF;
	
	IF v_other_vendor_company_sid IS NOT NULL THEN
		chain.company_pkg.DeleteCompanyFully(
			in_company_sid				=> v_other_vendor_company_sid
		);
	END IF;
	
	IF v_site_company_sid IS NOT NULL THEN
		chain.company_pkg.DeleteCompanyFully(
			in_company_sid				=> v_site_company_sid
		);
	END IF;
	
	IF v_reference_id_1 IS NOT NULL THEN
		helper_pkg.DeleteReferenceLabel(v_reference_id_1);
	END IF;

	IF v_reference_id_2 IS NOT NULL THEN
		helper_pkg.DeleteReferenceLabel(v_reference_id_2);
	END IF;
		
	test_chain_utils_pkg.TearDownTwoTier;
END;

PROCEDURE TestSetOwnReference(
	in_can_set_own_refs			IN	NUMBER,
	in_lookup_key					IN	reference.lookup_key%TYPE DEFAULT 'REF1'
)
AS
	v_did_set_reference				NUMBER;
BEGIN
	BEGIN
		v_did_set_reference := 0;

		company_pkg.UpdateCompanyReference(
			in_company_sid			=> v_vendor_company_sid,
			in_lookup_key			=> in_lookup_key,
			in_value				=> 'Some value'
		);

		v_did_set_reference := 1;
	EXCEPTION
		WHEN security.security_pkg.ACCESS_DENIED THEN
			NULL;
	END;

	csr.unit_test_pkg.AssertAreEqual(in_can_set_own_refs, v_did_set_reference, 'Should ' || CASE in_can_set_own_refs WHEN 1 THEN '' ELSE 'not ' END || 'be able to set reference on own company');
END;

PROCEDURE TestSetOtherVendorRef(
	in_can_set_other_vendor_refs	IN	NUMBER,
	in_lookup_key					IN	reference.lookup_key%TYPE DEFAULT 'REF1'
)
AS
	v_did_set_reference				NUMBER;
BEGIN
	BEGIN
		v_did_set_reference := 0;

		company_pkg.UpdateCompanyReference(
			in_company_sid			=> v_other_vendor_company_sid,
			in_lookup_key			=> in_lookup_key,
			in_value				=> 'Some value'
		);

		v_did_set_reference := 1;
	EXCEPTION
		WHEN security.security_pkg.ACCESS_DENIED THEN
			NULL;
	END;

	csr.unit_test_pkg.AssertAreEqual(in_can_set_other_vendor_refs, v_did_set_reference, 'Should ' || CASE in_can_set_other_vendor_refs WHEN 1 THEN '' ELSE 'not ' END || 'be able to set reference on another vendor');
END;

PROCEDURE TestSetSiteReference(
	in_can_set_site_refs			IN	NUMBER,
	in_lookup_key					IN	reference.lookup_key%TYPE DEFAULT 'REF1'
)
AS
	v_did_set_reference				NUMBER;
BEGIN
	BEGIN
		v_did_set_reference := 0;

		company_pkg.UpdateCompanyReference(
			in_company_sid			=> v_site_company_sid,
			in_lookup_key			=> in_lookup_key,
			in_value				=> 'Some value'
		);

		v_did_set_reference := 1;
	EXCEPTION
		WHEN security.security_pkg.ACCESS_DENIED THEN
			NULL;
	END;

	csr.unit_test_pkg.AssertAreEqual(in_can_set_site_refs, v_did_set_reference, 'Should ' || CASE in_can_set_site_refs WHEN 1 THEN '' ELSE 'not ' END || 'be able to set reference on a site');
END;

PROCEDURE TestSetReferences (
	in_can_set_own_refs				IN	NUMBER,
	in_can_set_other_vendor_refs	IN	NUMBER,
	in_can_set_site_refs			IN	NUMBER,
	in_lookup_key					IN	reference.lookup_key%TYPE DEFAULT 'REF1'
)
AS
BEGIN
	TestSetOwnReference(
		in_can_set_own_refs				=> in_can_set_own_refs,
		in_lookup_key					=> in_lookup_key
	);

	TestSetOtherVendorRef(
		in_can_set_other_vendor_refs	=> in_can_set_other_vendor_refs,
		in_lookup_key					=> in_lookup_key
	);

	TestSetSiteReference(
		in_can_set_site_refs			=> in_can_set_site_refs,
		in_lookup_key					=> in_lookup_key
	);
END;

PROCEDURE TestCannotSetRefsWithNoPerms
AS
BEGIN
	ClearPermissions;
	TestSetReferences(0, 0, 0);
END;

PROCEDURE TestCanSetRefsWithGroupPerms
AS
BEGIN
	-- The primary group permission should allow us to set references on our own company, but not on other vendors or on sites
	
	LogonAsAdmin;

	ClearPermissions;
	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_1,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> 1, -- Admins
		in_primary_comp_type_role_sid		=> NULL,
		in_secondary_company_type_id		=> NULL,
		in_permission_set					=> 3
	);

	LogonAsUser;
		
	TestSetReferences(1, 0, 0);

	-- The secondary group permission on vendors should allow us to set references on other vendors, but not on our own company or on sites
	
	LogonAsAdmin;

	ClearPermissions;
	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_1,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> 1, -- Admins
		in_primary_comp_type_role_sid		=> NULL,
		in_secondary_company_type_id		=> v_vendor_company_type_id,
		in_permission_set					=> 3
	);
	
	LogonAsUser;

	TestSetReferences(0, 1, 0);
	
	-- The secondary group permission on sites should allow us to set references on sites, but not on our own company or on other vendors
	
	LogonAsAdmin;

	ClearPermissions;
	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_1,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> 1, -- Admins
		in_primary_comp_type_role_sid		=> NULL,
		in_secondary_company_type_id		=> v_site_company_type_id,
		in_permission_set					=> 3
	);
	
	LogonAsUser;

	TestSetReferences(0, 0, 1);
END;

PROCEDURE TestCanSetRefsWithRolePerms
AS
BEGIN
	-- The primary group permission should allow us to set references on our own company, but not on other vendors or on sites
	
	LogonAsAdmin;

	ClearPermissions;
	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_1,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> NULL,
		in_primary_comp_type_role_sid		=> v_vendor_company_role_sid,
		in_secondary_company_type_id		=> NULL,
		in_permission_set					=> 3
	);

	LogonAsUser;
		
	TestSetReferences(1, 0, 0);

	-- The secondary group permission on vendors should allow us to set references on other vendors, but not on our own company or on sites
	
	LogonAsAdmin;

	ClearPermissions;
	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_1,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> NULL,
		in_primary_comp_type_role_sid		=> v_vendor_company_role_sid,
		in_secondary_company_type_id		=> v_vendor_company_type_id,
		in_permission_set					=> 3
	);
	
	LogonAsUser;

	TestSetReferences(0, 1, 0);
	
	-- The secondary group permission on sites should allow us to set references on sites, but not on our own company or on other vendors
	
	LogonAsAdmin;

	ClearPermissions;
	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_1,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> NULL,
		in_primary_comp_type_role_sid		=> v_vendor_company_role_sid,
		in_secondary_company_type_id		=> v_site_company_type_id,
		in_permission_set					=> 3
	);
	
	LogonAsUser;

	TestSetReferences(0, 0, 1);
END;

PROCEDURE TestCannotSetRefsWithROPerms
AS
BEGIN
	-- Read-only permissions should not be enough
	
	LogonAsAdmin;

	ClearPermissions;
	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_1,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> 1, -- Admins
		in_primary_comp_type_role_sid		=> NULL,
		in_secondary_company_type_id		=> NULL,
		in_permission_set					=> 1
	);
	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_1,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> NULL,
		in_primary_comp_type_role_sid		=> v_vendor_company_role_sid,
		in_secondary_company_type_id		=> NULL,
		in_permission_set					=> 1
	);

	LogonAsUser;
		
	TestSetOwnReference(0);
	
	-- Read/write by group should let us set the reference
	
	LogonAsAdmin;

	ClearPermissions;
	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_1,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> 1, -- Admins
		in_primary_comp_type_role_sid		=> NULL,
		in_secondary_company_type_id		=> NULL,
		in_permission_set					=> 3
	);
	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_1,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> NULL,
		in_primary_comp_type_role_sid		=> v_vendor_company_role_sid,
		in_secondary_company_type_id		=> NULL,
		in_permission_set					=> 1
	);

	LogonAsUser;
		
	TestSetOwnReference(1);
	
	-- Read/write by role should also let us set the reference
	
	LogonAsAdmin;

	ClearPermissions;
	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_1,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> 1, -- Admins
		in_primary_comp_type_role_sid		=> NULL,
		in_secondary_company_type_id		=> NULL,
		in_permission_set					=> 3
	);
	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_1,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> NULL,
		in_primary_comp_type_role_sid		=> v_vendor_company_role_sid,
		in_secondary_company_type_id		=> NULL,
		in_permission_set					=> 1
	);

	LogonAsUser;
		
	TestSetOwnReference(1);
END;

PROCEDURE TestRefPermsApplyByRef
AS
BEGIN
	ClearPermissions;

	-- The capability on one reference should not allow us to update another

	LogonAsAdmin;

	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_1,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> 1, -- Admins
		in_primary_comp_type_role_sid		=> NULL,
		in_secondary_company_type_id		=> NULL,
		in_permission_set					=> 3
	);

	LogonAsUser;
	
	TestSetOwnReference(1, 'REF1');
	TestSetOwnReference(0, 'REF2');

	-- If we have both, we should be able to update both.
	
	LogonAsAdmin;

	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_2,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> 1, -- Admins
		in_primary_comp_type_role_sid		=> NULL,
		in_secondary_company_type_id		=> NULL,
		in_permission_set					=> 3
	);

	LogonAsUser;
	
	TestSetOwnReference(1, 'REF1');
	TestSetOwnReference(1, 'REF2');
END;

PROCEDURE TestCannotSetRefForBadCompType
AS
	v_company_type_ids			helper_pkg.T_NUMBER_ARRAY;
BEGIN
	-- Suppose we have permission to set a reference in each of the three cases

	LogonAsAdmin;

	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_1,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> 1, -- Admins
		in_primary_comp_type_role_sid		=> NULL,
		in_secondary_company_type_id		=> NULL,
		in_permission_set					=> 3
	);
	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_1,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> 1, -- Admins
		in_primary_comp_type_role_sid		=> NULL,
		in_secondary_company_type_id		=> v_vendor_company_type_id,
		in_permission_set					=> 3
	);
	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_1,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> 1, -- Admins
		in_primary_comp_type_role_sid		=> NULL,
		in_secondary_company_type_id		=> v_site_company_type_id,
		in_permission_set					=> 3
	);

	LogonAsUser;

	TestSetReferences(1, 1, 1);

	-- Now suppose that the reference applies only to vendors. Then we should not be able to set it on sites.
	
	LogonAsAdmin;

	v_company_type_ids(1) := v_vendor_company_type_id;

	helper_pkg.SaveReferenceLabel (
		in_reference_id						=> v_reference_id_1,
		in_lookup_key						=> 'REF1',
		in_label							=> 'Reference 1',
		in_mandatory						=> 0,
		in_reference_uniqueness_id			=> chain_pkg.REF_UNIQUE_NONE,
		in_company_type_ids					=> v_company_type_ids,
		out_reference_id					=> v_reference_id_1
	);
	
	LogonAsUser;

	TestSetReferences(1, 1, 0);

	-- Now suppose that the reference applies only to sites. Then we should not be able to set it on our own company or on other sites.
	
	LogonAsAdmin;

	v_company_type_ids(1) := v_site_company_type_id;

	helper_pkg.SaveReferenceLabel (
		in_reference_id						=> v_reference_id_1,
		in_lookup_key						=> 'REF1',
		in_label							=> 'Reference 1',
		in_mandatory						=> 0,
		in_reference_uniqueness_id			=> chain_pkg.REF_UNIQUE_NONE,
		in_company_type_ids					=> v_company_type_ids,
		out_reference_id					=> v_reference_id_1
	);
	
	LogonAsUser;

	TestSetReferences(0, 0, 1);

	-- Clean up
	
	LogonAsAdmin;

	v_company_type_ids.DELETE(1);

	helper_pkg.SaveReferenceLabel (
		in_reference_id						=> v_reference_id_1,
		in_lookup_key						=> 'REF1',
		in_label							=> 'Reference 1',
		in_mandatory						=> 0,
		in_reference_uniqueness_id			=> chain_pkg.REF_UNIQUE_NONE,
		in_company_type_ids					=> v_company_type_ids,
		out_reference_id					=> v_reference_id_1
	);
END;

PROCEDURE TestChainAdminsGetBestPerms
AS
BEGIN
	-- The superadmin is not a member of the company group or the company type role.
	-- However, the superadmin group is a member of the chain admins group, and so
	-- the superadmin ought to get the best permissions of any group.
	-- Initially, that's no permissions.
	
	ClearPermissions;

	LogOnAsSuperAdmin;
	
	TestSetOwnReference(0);

	-- If we grant a group permission, that should propagate to the chain admins

	LogonAsAdmin;
	
	ClearPermissions;
	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_1,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> 1, -- Admins
		in_primary_comp_type_role_sid		=> NULL,
		in_secondary_company_type_id		=> NULL,
		in_permission_set					=> 3
	);

	LogOnAsSuperAdmin;

	TestSetOwnReference(1);

	-- If we grant a role permission, that should also propagate to the chain admins

	LogonAsAdmin;
	
	ClearPermissions;
	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_1,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> NULL,
		in_primary_comp_type_role_sid		=> v_vendor_company_role_sid,
		in_secondary_company_type_id		=> NULL,
		in_permission_set					=> 3
	);
	
	LogOnAsSuperAdmin;

	TestSetOwnReference(1);

	-- If we take away the group permission, the CAs should still have the role permission

	LogonAsAdmin;

	ClearPermissions;
	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_1,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> 1, -- Admins
		in_primary_comp_type_role_sid		=> NULL,
		in_secondary_company_type_id		=> NULL,
		in_permission_set					=> 3
	);
	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_1,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> NULL,
		in_primary_comp_type_role_sid		=> v_vendor_company_role_sid,
		in_secondary_company_type_id		=> NULL,
		in_permission_set					=> 3
	);
	helper_pkg.SetReferenceCapability (
		in_reference_id						=> v_reference_id_1,
		in_primary_company_type_id			=> v_vendor_company_type_id,
		in_primary_comp_group_type_id		=> 1, -- Admins
		in_primary_comp_type_role_sid		=> NULL,
		in_secondary_company_type_id		=> NULL,
		in_permission_set					=> 0
	);
	
	LogOnAsSuperAdmin;

	TestSetOwnReference(1);
END;

END;
/
