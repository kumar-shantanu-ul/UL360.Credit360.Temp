WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
	v_top_company_type_id		NUMBER; 
	v_supplier_company_type_id	NUMBER;
	v_company_sid				NUMBER;
	v_reference_id				NUMBER;
	v_company_type_ids			chain.helper_pkg.T_NUMBER_ARRAY;
BEGIN

	security.user_pkg.logonadmin('&&1');

	v_top_company_type_id := chain.company_type_pkg.GetCompanyTypeId('TOP');
	v_supplier_company_type_id := chain.company_type_pkg.GetCompanyTypeId('SUPPLIERS');
	
	chain.setup_pkg.SetupPlugin(
		in_page_company_type_id		=> v_top_company_type_id,
		in_user_company_type_id		=> v_top_company_type_id,
		in_label					=> 'Company details',
		in_js_class					=> 'Chain.ManageCompany.CompanyDetails',
		in_viewing_own_company		=> 1
	);

	chain.setup_pkg.SetupPlugin(
		in_page_company_type_id		=> v_top_company_type_id,
		in_user_company_type_id		=> v_top_company_type_id,
		in_label					=> 'Company users',
		in_js_class					=> 'Chain.ManageCompany.CompanyUsers',
		in_viewing_own_company		=> 1
	);
	
	chain.setup_pkg.SetupPlugin(
		in_page_company_type_id		=> v_supplier_company_type_id,
		in_user_company_type_id		=> v_top_company_type_id,
		in_label					=> 'Company users',
		in_js_class					=> 'Chain.ManageCompany.CompanyUsers',
		in_viewing_own_company		=> 0
	);

	chain.test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Supplier A',
		in_country_code		=> 'gb',
		in_company_type_id 	=> v_supplier_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_company_sid
	);

	chain.helper_pkg.SaveReferenceLabel(
		in_reference_id	=> NULL,
		in_lookup_key => 'COMPANY_ID_REF',
		in_label => 'Company reference id',
		in_mandatory => 0,
		in_reference_uniqueness_id => 2, /* Global */
		in_reference_location_id => 0, /* Show on the company details card */
		in_company_type_ids	=> v_company_type_ids,
		out_reference_id => v_reference_id
	);

	chain.helper_pkg.SetReferenceCapability (
		in_reference_id					=> v_reference_id,
		in_primary_company_type_id		=> v_top_company_type_id,
		in_primary_comp_group_type_id	=> 1, -- Admins
		in_primary_comp_type_role_sid	=> NULL,
		in_secondary_company_type_id	=> NULL,
		in_permission_set				=> 3
	);

	chain.helper_pkg.SetReferenceCapability (
		in_reference_id					=> v_reference_id,
		in_primary_company_type_id		=> v_top_company_type_id,
		in_primary_comp_group_type_id	=> 1, -- Admins
		in_primary_comp_type_role_sid	=> NULL,
		in_secondary_company_type_id	=> v_supplier_company_type_id,
		in_permission_set				=> 3
	);

	-- open some perms
	chain.type_capability_pkg.SetPermission(
		in_primary_company_type		=> 'TOP',
		in_secondary_company_type	=> 'SUPPLIERS',
		in_group					=> chain.chain_pkg.ADMIN_GROUP,
		in_capability_type			=> chain.chain_pkg.CT_SUPPLIERS,
		in_capability				=> chain.chain_pkg.SPECIFY_USER_NAME
	);
END;
/

commit;
exit;
/