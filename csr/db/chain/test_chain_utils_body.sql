CREATE OR REPLACE PACKAGE BODY chain.test_chain_utils_pkg AS

FUNCTION ToArray(
	t_nested_t	IN T_VARCHAR2_T
)RETURN security_pkg.T_VARCHAR2_ARRAY
AS
	v_results security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	FOR i IN t_nested_t.FIRST .. t_nested_t.LAST LOOP
		v_results(i) := t_nested_t(i);
	END LOOP;
	
	RETURN v_results;
END;

FUNCTION ToArr(
	in_vals		IN VARCHAR2
)RETURN security_pkg.T_VARCHAR2_ARRAY
AS
	v_results security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	SELECT (TRIM(item))
	  BULK COLLECT INTO v_results
	  FROM TABLE(aspen2.utils_pkg.SplitString(in_vals)); 

	RETURN v_results;
END;

FUNCTION GetTagGroupId(
	in_lookup_key	csr.tag_group.lookup_key%TYPE
)RETURN csr.tag_group.tag_group_id%TYPE
AS
	v_tag_group_id	csr.tag_group.tag_group_id%TYPE;
BEGIN
	SELECT tag_group_id
	  INTO v_tag_group_id
	  FROM csr.tag_group
	 WHERE lookup_key = in_lookup_key;
	  
	RETURN v_tag_group_id;
END;

PROCEDURE SetupSingleTier
AS
	v_top_company_sid	NUMBER;
BEGIN
	IF NOT setup_pkg.IsChainEnabled THEN
		setup_pkg.EnableSite;
	END IF;

	company_type_pkg.AddCompanyType('TOP', 'TOP', 'TOP');

	company_type_pkg.SetTopCompanyType('TOP');

	company_type_pkg.AddDefaultCompanyType('SUPPLIER', 'Supplier', 'Suppliers');

	company_type_pkg.AddCompanyTypeRelationship('TOP', 'SUPPLIER');
	company_type_pkg.AddCompanyTypeRelationship('SUPPLIER', 'SUPPLIER');

	company_pkg.CreateCompany(
		in_name=> 'CR360',
		in_country_code=> 'gb',
		in_company_type_id=> company_type_pkg.GetCompanyTypeId('TOP'),
		in_sector_id=> NULL,
		out_company_sid=> v_top_company_sid
	);

	company_pkg.ActivateCompany(v_top_company_sid);
	
	UPDATE customer_options
	   SET top_company_sid = v_top_company_sid
	 WHERE app_sid = security_pkg.getapp;
END;

PROCEDURE SetupTwoTier
AS
	v_top_company_sid	NUMBER;
BEGIN

	IF NOT setup_pkg.IsChainEnabled THEN
		setup_pkg.EnableSite;
	END IF;
	
	company_type_pkg.AddCompanyType('TOP', 'TOP', 'TOP');
	
	company_type_pkg.SetTopCompanyType('TOP');
	
	company_type_pkg.AddDefaultCompanyType('VENDOR', 'Vendor', 'Vendors');
	company_type_pkg.AddCompanyType('SITE', 'Site', 'Sites');
	
	company_type_pkg.AddCompanyTypeRelationship('TOP', 'VENDOR');
	company_type_pkg.AddCompanyTypeRelationship('TOP', 'SITE');
	company_type_pkg.AddCompanyTypeRelationship('VENDOR', 'SITE');
	company_type_pkg.AddCompanyTypeRelationship('SITE', 'VENDOR');
	company_type_pkg.AddCompanyTypeRelationship('SITE', 'SITE');
	
	company_pkg.CreateCompany(
		in_name=> 'CR360',
		in_country_code=> 'gb',
		in_company_type_id=> company_type_pkg.GetCompanyTypeId('TOP'),
		in_sector_id=> NULL,
		out_company_sid=> v_top_company_sid
	);

	company_pkg.ActivateCompany(v_top_company_sid);
	
	UPDATE customer_options
	   SET top_company_sid = v_top_company_sid
	 WHERE app_sid = security_pkg.getapp;
END;

PROCEDURE TearDownSingleTier
AS
	v_supp_ct_id	NUMBER;
	v_top_ct_id		NUMBER;
BEGIN
	--clear company types + top company
	BEGIN
		SELECT company_type_id
		  INTO v_supp_ct_id
		  FROM company_type
		 WHERE lookup_key = 'SUPPLIER';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	BEGIN
		SELECT company_type_id
		  INTO v_top_ct_id
		  FROM company_type
		 WHERE lookup_key = 'TOP';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
		
	FOR r IN (
		SELECT company_sid 
		  FROM company
		 WHERE company_type_id = v_supp_ct_id
	)
	LOOP
		company_pkg.DeleteCompanyFully(r.company_sid);
	END LOOP;
	
	FOR r IN (
		SELECT company_sid 
		  FROM company
		 WHERE company_type_id = v_top_ct_id
	)
	LOOP
		company_pkg.DeleteCompanyFully(r.company_sid);
	END LOOP;
	
	IF v_supp_ct_id IS NOT NULL AND v_top_ct_id IS NOT NULL THEN 
		company_type_pkg.DeleteCompanyTypeRel_UNSEC(v_top_ct_id, v_supp_ct_id);
	END IF;

	FOR r IN(
	   SELECT company_type_id
		 FROM company_type
		WHERE company_type_id IN (v_top_ct_id, v_supp_ct_id)
	)
	LOOP
		 DELETE FROM company_type_role
		  WHERE company_type_id = r.company_type_id;
		  
		company_type_pkg.DeleteCompanyType(r.company_type_id);
	END LOOP;
END;

PROCEDURE TearDownTwoTier
AS
	v_count		 	NUMBER;
	v_top_ct_id		NUMBER DEFAULT company_type_pkg.GetCompanyTypeId('TOP', TRUE);
	v_vendor_ct_id	NUMBER DEFAULT company_type_pkg.GetCompanyTypeId('VENDOR', TRUE);
	v_site_ct_id	NUMBER DEFAULT company_type_pkg.GetCompanyTypeId('SITE', TRUE);
BEGIN
	--clear company types + top company
	
	IF v_vendor_ct_id IS NOT NULL THEN 
		company_type_pkg.DeleteCompanyTypeRel_UNSEC(
			v_top_ct_id,
			v_vendor_ct_id
		);
	END IF;

	IF v_site_ct_id IS NOT NULL THEN 
		company_type_pkg.DeleteCompanyTypeRel_UNSEC(
			v_top_ct_id,
			v_site_ct_id
		);
	END IF;
	
	FOR r IN (
		SELECT company_sid 
		  FROM company
		 WHERE company_type_id IN (v_site_ct_id, v_vendor_ct_id)
		   AND parent_sid IS NULL -- children get deleted when their parents do
	)
	LOOP
		company_pkg.DeleteCompanyFully(r.company_sid);
	END LOOP;
		
	FOR r IN (
		SELECT company_sid 
		  FROM company
		 WHERE company_type_id = v_top_ct_id
	)
	LOOP
		company_pkg.DeleteCompanyFully(r.company_sid);
	END LOOP;
	
	FOR r IN(
	  SELECT company_type_id
		FROM company_type
	   WHERE company_type_id IN (v_site_ct_id, v_vendor_ct_id, v_top_ct_id)
	)
	LOOP
		company_type_pkg.DeleteCompanyType(r.company_type_id);
	END LOOP;
END;

FUNCTION GetChainCompanySid(
	in_name				company.name%TYPE,
	in_country_code		company.country_code%TYPE
)RETURN security_pkg.T_SID_ID
AS
	v_company_sid  security_pkg.T_SID_ID;
BEGIN
	SELECT company_sid
	  INTO v_company_sid
	  FROM chain.company
	 WHERE nlssort(name,'nls_sort=generic_m_ai') = nlssort(in_name,'nls_sort=generic_m_ai')
	   AND country_code = in_country_code;
	
	RETURN v_company_sid;
END;

PROCEDURE LinkRoleToCompanyType(
	in_role_sid				security_pkg.T_SID_ID,
	in_company_type_lookup	company_type.lookup_key%TYPE
)
AS
BEGIN
	company_type_pkg.LinkRoleToCompanyType_UNSEC(
		in_company_type_id		=> company_type_pkg.GetCompanyTypeId(in_company_type_lookup),
		in_role_sid				=> in_role_sid,
		in_mandatory			=> 0
	);
END;

PROCEDURE TearDownImportSource(
	in_lookup_key	import_source.lookup_key%TYPE
)
AS
	v_import_source_id 	NUMBER;
BEGIN
	BEGIN
		SELECT import_source_id
		  INTO v_import_source_id
		  FROM import_source
		 WHERE app_sid = security_pkg.getapp
		   AND lookup_key = in_lookup_key;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			RETURN;
	END;
		
	DELETE FROM dedupe_match
	 WHERE dedupe_processed_record_id IN(
		SELECT dedupe_processed_record_id
		  FROM dedupe_processed_record
		 WHERE dedupe_staging_link_id IN (
			SELECT dedupe_staging_link_id
			  FROM dedupe_staging_link
			 WHERE import_source_id = v_import_source_id
		 )
	);
	 
	DELETE FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id IN (
		SELECT dedupe_processed_record_id
		  FROM dedupe_processed_record
		 WHERE dedupe_staging_link_id IN (
			SELECT dedupe_staging_link_id
			  FROM dedupe_staging_link
			 WHERE import_source_id = v_import_source_id
		 )
		);
		
	DELETE FROM dedupe_processed_record
	 WHERE dedupe_staging_link_id IN (
		SELECT dedupe_staging_link_id
		  FROM dedupe_staging_link
		 WHERE import_source_id = v_import_source_id
	 );
	 
	FOR r IN(
		SELECT dedupe_rule_set_id
		  FROM dedupe_rule_set
		 WHERE dedupe_staging_link_id IN (
			SELECT dedupe_staging_link_id
			  FROM dedupe_staging_link
			 WHERE import_source_id = v_import_source_id
		 )
	)
	LOOP
		dedupe_admin_pkg.DeleteRuleSet(r.dedupe_rule_set_id);
	END LOOP;
	
	FOR r IN(
		SELECT dedupe_mapping_id
		  FROM dedupe_mapping
		 WHERE dedupe_staging_link_id IN (
			SELECT dedupe_staging_link_id
			  FROM dedupe_staging_link
			 WHERE import_source_id = v_import_source_id
		 )
	)
	LOOP
		dedupe_admin_pkg.DeleteMapping(r.dedupe_mapping_id);
	END LOOP;
	
	DELETE FROM dedupe_staging_link
	 WHERE import_source_id = v_import_source_id;
	
	DELETE FROM import_source_lock
	 WHERE import_source_id = v_import_source_id;
	 
	DELETE FROM import_source
	 WHERE import_source_id = v_import_source_id;
END;

PROCEDURE DeleteFullyCompaniesOfType(
	in_company_type_lookup	IN company_type.lookup_key%TYPE
)
AS
BEGIN
	FOR r IN (
		SELECT company_sid 
		  FROM company
		 WHERE company_type_id = company_type_pkg.GetCompanyTypeId(in_company_type_lookup)
		   AND app_sid = security_pkg.getApp
	)
	LOOP
		company_pkg.DeleteCompanyFully(r.company_sid);
	END LOOP;
END;

PROCEDURE GetCompaniesFromProcessedRec(
	in_processed_record_id		IN NUMBER,
	out_created_company_sid		OUT security.security_pkg.T_SID_ID,
	out_matched_company_sids	OUT security.security_pkg.T_SID_IDS
)
AS
BEGIN
	SELECT created_company_sid
	  INTO out_created_company_sid
	  FROM dedupe_processed_record
	 WHERE app_sid = security_pkg.getapp
	   AND dedupe_processed_record_id = in_processed_record_id;
	   
	SELECT matched_to_company_sid
	  BULK COLLECT INTO out_matched_company_sids
	  FROM dedupe_match
	 WHERE app_sid = security_pkg.getapp
	   AND dedupe_processed_record_id = in_processed_record_id;
END;

PROCEDURE ProcessParentStagingRecord( 
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_reference				IN VARCHAR2,
	in_batch_num				IN NUMBER DEFAULT NULL,
	in_force_re_eval			IN NUMBER DEFAULT 0,
	out_processed_record_ids	OUT security_pkg.T_SID_IDS,
	out_created_company_sid		OUT security.security_pkg.T_SID_ID,
	out_matched_company_sids	OUT security.security_pkg.T_SID_IDS
)
AS
	v_import_source_id			import_source.import_source_id%TYPE;
BEGIN
	SELECT import_source_id
	  INTO v_import_source_id
	  FROM dedupe_staging_link
	 WHERE dedupe_staging_link_id = in_dedupe_staging_link_id;

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_import_source_id, 
		in_reference				=> in_reference,
		in_batch_num				=> in_batch_num,
		in_force_re_eval			=> in_force_re_eval,
		out_processed_record_ids	=> out_processed_record_ids
	);
	
	IF out_processed_record_ids IS NOT NULL AND out_processed_record_ids(1) IS NOT NULL THEN
		GetCompaniesFromProcessedRec(
			in_processed_record_id		=> out_processed_record_ids(1),
			out_created_company_sid		=> out_created_company_sid,
			out_matched_company_sids	=> out_matched_company_sids
		);
	END IF;
END;

PROCEDURE CreateSubCompanyHelper(
	in_parent_sid				IN	security.security_pkg.T_SID_ID,
	in_name						IN	company.name%TYPE,
	in_country_code				IN	company.name%TYPE,
	in_company_type_id			IN	company_type.company_type_id%TYPE,
	in_sector_id				IN  company.sector_id%TYPE,
	out_company_sid				OUT security.security_pkg.T_SID_ID
)
AS
BEGIN
	company_pkg.CreateSubCompany(
		in_parent_sid				=>	in_parent_sid,
		in_name						=>	in_name,
		in_country_code				=>	in_country_code,
		in_company_type_id			=>	in_company_type_id,
		in_sector_id				=>	in_sector_id,
		out_company_sid				=>	out_company_sid
	);
END;

PROCEDURE CreateCompanyNoRelationship(
	in_name				IN company.name%TYPE,
	in_country_code		IN company.country_code%TYPE,
	in_company_type_id	IN company.company_type_id%TYPE,
	in_city				IN company.city%TYPE DEFAULT NULL,
	in_state			IN company.state%TYPE DEFAULT NULL,
	in_sector_id		IN company.sector_id%TYPE,
	out_company_sid		OUT security.security_pkg.T_SID_ID
)
AS
BEGIN
	company_pkg.CreateCompany(
		in_name				=> in_name,
		in_country_code 	=> in_country_code,
		in_company_type_id 	=> in_company_type_id,
		in_city				=> in_city,
		in_state			=> in_state,
		in_sector_id		=> in_sector_id,
		out_company_sid		=> out_company_sid
	);
	
	company_pkg.ActivateCompany(out_company_sid);
END;

PROCEDURE ConnectWithTopCompany(
	in_company_sid		IN security.security_pkg.T_SID_ID
)
AS
	v_top_company_sid	security.security_pkg.T_SID_ID DEFAULT chain.helper_pkg.GetTopCompanySid;
BEGIN
	company_pkg.StartRelationship(
		in_purchaser_company_sid		=> v_top_company_sid,
		in_supplier_company_sid			=> in_company_sid
	);

	company_pkg.ActivateRelationship(v_top_company_sid, in_company_sid);
END;

PROCEDURE ConnectCompanies(
	in_purchaser_sid		IN security.security_pkg.T_SID_ID,
	in_supplier_sid			IN security.security_pkg.T_SID_ID
)
AS
BEGIN
	company_pkg.StartRelationship(
		in_purchaser_company_sid		=> in_purchaser_sid,
		in_supplier_company_sid			=> in_supplier_sid
	);

	company_pkg.ActivateRelationship(in_purchaser_sid, in_supplier_sid);
END;

PROCEDURE CreateCompanyHelper(
	in_name				IN company.name%TYPE,
	in_country_code		IN company.country_code%TYPE,
	in_company_type_id	IN company.company_type_id%TYPE,
	in_city				IN company.city%TYPE DEFAULT NULL,
	in_state			IN company.state%TYPE DEFAULT NULL,
	in_sector_id		IN company.sector_id%TYPE,
	out_company_sid		OUT security.security_pkg.T_SID_ID
)
AS
BEGIN
	CreateCompanyNoRelationship(
		in_name				=> in_name,
		in_country_code		=> in_country_code,
		in_company_type_id	=> in_company_type_id,
		in_city				=> in_city,
		in_state			=> in_state,
		in_sector_id		=> in_sector_id,
		out_company_sid		=> out_company_sid
	);

	ConnectWithTopCompany(out_company_sid);
END;

FUNCTION GetTopCompanyTypeLookup
RETURN company_type.lookup_key%TYPE
AS
	v_top_lookup		company_type.lookup_key%TYPE;
BEGIN
	BEGIN
		SELECT lookup_key
		  INTO v_top_lookup
		  FROM company_type
		 WHERE is_top_company = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Top company type not found');
	END;

	RETURN v_top_lookup;
END;

PROCEDURE SetupUITest_CTStructure
AS
	v_top_lookup		company_type.lookup_key%TYPE;
	v_supplier_lookup	company_type.lookup_key%TYPE;
BEGIN
	--we assume there is already a two tier site enabled
	v_top_lookup := GetTopCompanyTypeLookup;

	BEGIN
		SELECT lookup_key
		  INTO v_supplier_lookup
		  FROM company_type
		 WHERE is_default = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Default suppliers company type not found');
	END;

	company_type_pkg.AddCompanyType('FACTORY', 'Factory', 'Factories');
	company_type_pkg.AddCompanyType('SUPPLIER_DONOTUSE', 'SUPPLIER_DONOTUSE', 'SUPPLIER_DONOTUSE');
	company_type_pkg.AddCompanyType('FACTORY_DONOTUSE', 'FACTORY_DONOTUSE', 'FACTORY_DONOTUSE');

	company_type_pkg.AddCompanyTypeRelationship(v_top_lookup, 'FACTORY');
	company_type_pkg.AddCompanyTypeRelationship(v_supplier_lookup, 'FACTORY');
	company_type_pkg.AddTertiaryRelationship(v_top_lookup, v_supplier_lookup, 'FACTORY');
END;

PROCEDURE SetupUITest_EnableRemoveUser
AS
	v_top_lookup		company_type.lookup_key%TYPE;
BEGIN
	--we assume there is already a two tier site enabled
	v_top_lookup := GetTopCompanyTypeLookup;

	type_capability_pkg.SetPermission(
		v_top_lookup, 
		chain_pkg.ADMIN_GROUP, 
		chain_pkg.CT_COMPANY, 
		chain_pkg.REMOVE_USER_FROM_COMPANY, 
		TRUE
	);
END;

FUNCTION SetupUITest_AddTopCompUser(
	in_user_name		csr.csr_user.user_name%TYPE,
	in_email			csr.csr_user.email%TYPE,
	in_pwd				VARCHAR2
) RETURN security.security_pkg.T_SID_ID
AS
	v_top_company_sid	security.security_pkg.T_SID_ID DEFAULT helper_pkg.GetTopCompanySid;
	v_user_sid			security.security_pkg.T_SID_ID;
BEGIN
	company_pkg.setCompany(v_top_company_sid);

	v_user_sid := company_user_pkg.CreateUser(
		in_company_sid		=> v_top_company_sid,
		in_user_name		=> in_user_name,
		in_full_name		=> in_user_name,
		in_password			=> in_pwd,
		in_friendly_name	=> in_user_name,
		in_email			=> in_email
	);

	company_user_pkg.ActivateUser(v_user_sid);
	company_user_pkg.SetRegistrationStatus(v_user_sid, 1); /* Registered */	
	company_user_pkg.AddUserToCompany(v_top_company_sid, v_user_sid);
	
	RETURN v_user_sid;
END;

PROCEDURE UpdateCompanyTypeLayout(
	in_lookup_key				company_type.lookup_key%TYPE,
	in_default_region_layout	company_type.default_region_layout%TYPE
)
AS
BEGIN
	FOR r IN (
		SELECT singular, plural, allow_lower_case, use_user_role, css_class, default_region_type,
			region_root_sid, create_subsids_under_parent, create_doc_library_folder
		  FROM company_type
		 WHERE app_sid = security_pkg.getapp
		   AND lookup_key = in_lookup_key
	)
	LOOP
		company_type_pkg.SetCompanyType(
			in_lookup_key					=> in_lookup_key,
			in_singular						=> r.singular,
			in_plural						=> r.plural,
			in_allow_lower					=> r.allow_lower_case,
			in_use_user_role				=> r.use_user_role,
			in_css_class					=> r.css_class,
			in_default_region_type			=> r.default_region_type,
			in_region_root_sid				=> r.region_root_sid,
			in_default_region_layout		=> in_default_region_layout,
			in_create_subsids_under_parent	=> r.create_subsids_under_parent,
			in_create_doc_library_folder    => r.create_doc_library_folder
		);
	END LOOP;
END;

PROCEDURE ToggleCreateSubsUnderParentForCompanyType(
	in_lookup_key					company_type.lookup_key%TYPE,
	in_create_subsids_under_parent 	company_type.create_subsids_under_parent%TYPE
)
AS
BEGIN
	FOR r IN (
		SELECT singular, plural, allow_lower_case, use_user_role, css_class, default_region_type,
			region_root_sid, create_subsids_under_parent, create_doc_library_folder, default_region_layout
		  FROM company_type
		 WHERE app_sid = security_pkg.getapp
		   AND lookup_key = in_lookup_key
	)
	LOOP
		company_type_pkg.SetCompanyType(
			in_lookup_key					=> in_lookup_key,
			in_singular						=> r.singular,
			in_plural						=> r.plural,
			in_allow_lower					=> r.allow_lower_case,
			in_use_user_role				=> r.use_user_role,
			in_css_class					=> r.css_class,
			in_default_region_type			=> r.default_region_type,
			in_region_root_sid				=> r.region_root_sid,
			in_default_region_layout		=> r.default_region_layout,
			in_create_subsids_under_parent	=> in_create_subsids_under_parent,
			in_create_doc_library_folder    => r.create_doc_library_folder
		);
	END LOOP;
END;

PROCEDURE EnableRoleForCompanyType(
	in_lookup_key	company_type.lookup_key%TYPE
)
AS
BEGIN
	FOR r IN (
		SELECT singular, plural, allow_lower_case
		  FROM company_type
		 WHERE app_sid = security_pkg.getapp
		   AND lookup_key = in_lookup_key
	)
	LOOP
		company_type_pkg.SetCompanyType(
			in_lookup_key		=> in_lookup_key,
			in_singular			=> r.singular,
			in_plural			=> r.plural,
			in_use_user_role	=> 1,
			in_allow_lower		=> r.allow_lower_case
		);
	END LOOP;
END;

PROCEDURE EnableCascadeRoleForCTR(
	in_prim_lookup_key	company_type.lookup_key%TYPE,
	in_sec_lookup_key	company_type.lookup_key%TYPE
)
AS
BEGIN
	UPDATE company_type_relationship
	   SET use_user_roles = 1
	 WHERE primary_company_type_id = company_type_pkg.GetCompanyTypeId(in_prim_lookup_key)
	   AND secondary_company_type_id = company_type_pkg.GetCompanyTypeId(in_sec_lookup_key);
END;

FUNCTION EnableFollowerRoleForCompTypeRel(
	in_vendor_key	company_type.lookup_key%TYPE,
	in_supplier_key	company_type.lookup_key%TYPE
) RETURN NUMBER
AS
	v_follower_role_sid	NUMBER;
BEGIN
	company_type_pkg.AddCompanyTypeRelationship (
		in_company_type			=> in_vendor_key,	
		in_related_company_type	=> in_supplier_key,
		in_has_follower_role	=> 1
	);

	SELECT follower_role_sid
	  INTO v_follower_role_sid 
	  FROM company_type_relationship
	 WHERE primary_company_type_id = company_type_pkg.GetCompanyTypeId('VENDOR')
	   AND secondary_company_type_id = company_type_pkg.GetCompanyTypeId('SITE');

	RETURN v_follower_role_sid;
END;

FUNCTION CreateCompanyUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_name			IN  csr.csr_user.user_name%TYPE
) RETURN security.security_pkg.T_SID_ID
AS
	v_user_sid security.security_pkg.T_SID_ID;
BEGIN
	v_user_sid := company_user_pkg.CreateUser(
		in_company_sid			=> in_company_sid,
		in_full_name			=> in_user_name,
		in_friendly_name		=> in_user_name,
		in_email				=> in_user_name||'@cr360.com',
		in_user_name			=> in_user_name,
		in_phone_number			=> NULL, 
		in_job_title			=> NULL
	);

	company_user_pkg.ActivateUser(v_user_sid);
	
	company_user_pkg.AddUserToCompany(in_company_sid => in_company_sid, in_user_sid => v_user_sid);

	RETURN v_user_sid;
END;

END;
/
