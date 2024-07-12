CREATE OR REPLACE PACKAGE BODY CHAIN.test_dedupe_pending_pkg AS

v_site_name					VARCHAR2(200);
v_site_company_type_id 		NUMBER; 
v_vend_company_type_id 		NUMBER; 
v_source_staging_link_id	NUMBER;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_dedupe_field_ids			security_pkg.T_SID_IDS;
	v_countries					security_pkg.T_VARCHAR2_ARRAY;
	v_dedupe_preproc_rule_id	NUMBER;
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);
	
	test_chain_utils_pkg.SetupTwoTier;

	v_site_company_type_id	:= company_type_pkg.GetCompanyTypeId('SITE');
	v_vend_company_type_id	:= company_type_pkg.GetCompanyTypeId('VENDOR');
	
	UPDATE customer_options
	   SET enable_dedupe_preprocess = 1
	 WHERE app_sid = security_pkg.getapp;
	 
	INSERT INTO chain.dd_customer_blcklst_email (email_domain) VALUES ('example');
	INSERT INTO chain.dd_customer_blcklst_email (email_domain) VALUES ('gmail');
	INSERT INTO chain.dd_customer_blcklst_email (email_domain) VALUES ('googlemail');
	INSERT INTO chain.dd_customer_blcklst_email (email_domain) VALUES ('yahoo');
	
	--remove '-()*'
	dedupe_admin_pkg.SavePreProcRule(
		in_dedupe_preproc_rule_id 	=> NULL,
		in_pattern					=> '[*\(\)\-]', --replaces *()- with ' '
		in_replacement				=> ' ',
		in_run_order				=> 1,
		in_dedupe_field_ids			=> v_dedupe_field_ids,
		in_countries				=> v_countries,
		out_dedupe_preproc_rule_id	=> v_dedupe_preproc_rule_id
	);
	
	SELECT dedupe_staging_link_id
	  INTO v_source_staging_link_id
	  FROM dedupe_staging_link
	 WHERE is_owned_by_system = 1;
END;

PROCEDURE SetUp
AS
BEGIN
	NULL;
END;

PROCEDURE ClearSystemRules
AS
BEGIN
	DELETE FROM dedupe_rule
	 WHERE dedupe_mapping_id IN(
		SELECT dedupe_mapping_id
		  FROM dedupe_mapping
		 WHERE app_sid = security_pkg.getApp
		   AND is_owned_by_system = 1
	 );
	 
	DELETE FROM dedupe_rule_set
	 WHERE dedupe_staging_link_id IN(
		SELECT dedupe_staging_link_id
		  FROM dedupe_staging_link
		 WHERE app_sid = security_pkg.getApp
		   AND is_owned_by_system = 1
	 );
	 
	DELETE FROM dedupe_mapping
	 WHERE is_owned_by_system = 1;
END;

PROCEDURE TearDown
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	test_chain_utils_pkg.DeleteFullyCompaniesOfType('SITE');
	test_chain_utils_pkg.DeleteFullyCompaniesOfType('VENDOR');
	ClearSystemRules;
	DELETE FROM chain.reference;
END;

PROCEDURE TearDownFixture
AS
	v_count		 	NUMBER;
BEGIN
	UPDATE customer_options
	   SET enable_dedupe_preprocess = 0
	 WHERE app_sid = security_pkg.getapp;

	DELETE FROM dedupe_pp_field_cntry;
	DELETE FROM dedupe_preproc_rule;
	DELETE FROM dd_customer_blcklst_email;

	dedupe_admin_pkg.SetSystemDefaultMapAndRules(in_try_reset => 1);
	
	FOR r IN (
		SELECT tag_group_id
		  FROM csr.tag_group
		 WHERE lookup_key IN ('FACILITY_TYPE', 'OWNERSHIP_TYPE')
	)
	LOOP
		csr.tag_pkg.DeleteTagGroup(
			in_act_id			=> security_pkg.GetAct,
			in_tag_group_id		=> r.tag_group_id
		);
	END LOOP;

	test_chain_utils_pkg.TearDownTwoTier;
END;

PROCEDURE AssertCreatedData(
	in_company_sid	IN NUMBER,
	in_tag_ids		IN security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_ref_ids		IN security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_ref_vals 	IN chain_pkg.T_STRINGS DEFAULT chain_pkg.EMPTY_VALUES
)
AS
	v_count		NUMBER;
	v_ref_t		security.T_SID_TABLE;
BEGIN
	--first check if an active relationship has been created
	SELECT COUNT(*)
	  INTO v_count
	  FROM supplier_relationship
	 WHERE purchaser_company_sid = helper_pkg.GetTopCompanySid
	   AND supplier_company_sid = in_company_sid
	   AND active = 1
	   AND deleted = 0;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Expected an active relationship with the top company');
	
	IF in_ref_ids IS NOT NULL AND in_ref_ids.COUNT > 0 THEN
		v_ref_t := security_pkg.SidArrayToTable(in_tag_ids);
		
		SELECT COUNT(*)
		  INTO v_count
		  FROM csr.region_tag rt
		  JOIN csr.supplier s ON rt.region_sid = s.region_sid
		 WHERE s.company_sid = in_company_sid
		   AND rt.tag_id IN (
			SELECT column_value
			  FROM TABLE(v_ref_t) t
			 WHERE t.column_value = rt.tag_id
		 );
		
		csr.unit_test_pkg.AssertAreEqual(v_ref_t.COUNT, v_count, 'Wrong number of saved tags');
	END IF;
	
	IF in_ref_ids IS NOT NULL AND in_ref_ids.COUNT > 0 THEN
		FOR i IN in_ref_ids.FIRST .. in_ref_ids.LAST
		LOOP
			SELECT COUNT(*)
			  INTO v_count
			  FROM company_reference
			 WHERE company_sid = in_company_sid
			   AND reference_id = in_ref_ids(i)
			   AND value = in_ref_vals(i);
			
			csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong company reference for value:'||in_ref_vals(i));
		END LOOP;
	END IF;
END;

PROCEDURE AssertMatches(
	in_expected_matched_sids	security_pkg.T_SID_IDS,
	in_returned_matched_sids	security_pkg.T_SID_IDS
)
AS
	v_expected_matched_sids		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_expected_matched_sids);
	v_returned_matched_sids		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_returned_matched_sids);
	v_count						NUMBER;
BEGIN
	csr.unit_test_pkg.AssertAreEqual(in_expected_matched_sids.COUNT, in_returned_matched_sids.COUNT, 'Number of matches is not the expected one');

	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(v_expected_matched_sids) t1
	  FULL JOIN TABLE(v_returned_matched_sids) t2 ON t1.column_value = t2.column_value
	 WHERE t1.column_value IS NULL OR t2.column_value IS NULL;
	
	IF v_count != 0 THEN
		csr.unit_test_pkg.TestFail('There are differences between expected and returned matches');
	END IF;
END;

PROCEDURE AssertCompanyState(
	in_company_sid				security_pkg.T_SID_ID,
	in_requested_by_comp_sid 	security_pkg.T_SID_ID,
	in_is_pending				NUMBER
)
AS
	v_count				NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM company c
	  LEFT JOIN security.securable_object so 
		ON c.company_sid = so.sid_id 
	   AND so.parent_sid_id = securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Chain/Companies/Pending')
	 WHERE company_sid = in_company_sid
	   AND pending = in_is_pending
	   AND (so.sid_id IS NOT NULL OR in_is_pending = 0)
	   AND active != in_is_pending
	   AND requested_by_company_sid = in_requested_by_comp_sid;
	
	IF v_count != 1 THEN
		csr.unit_test_pkg.TestFail('Wrong company state');
	END IF;
END;

PROCEDURE AssertRelationship(
	in_purch_company_sid	security_pkg.T_SID_ID,
	in_sup_company_sid		security_pkg.T_SID_ID,
	in_expected 			NUMBER 
)
AS
	v_count					NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM supplier_relationship
	 WHERE purchaser_company_sid = in_purch_company_sid
	   AND supplier_company_sid = in_sup_company_sid
	   AND active = 1
	   AND deleted = 0;
	
	IF v_count != in_expected THEN
		csr.unit_test_pkg.TestFail('Wrong relationship state');
	END IF;
END;

PROCEDURE TestMatchesDefaultSet
AS
	v_existing_company_sid_1	NUMBER;
	v_existing_company_sid_2	NUMBER;
	v_new_company_sid_1			NUMBER;
	v_matched_sids				security_pkg.T_SID_IDS;
	v_expected_matched_sids		security_pkg.T_SID_IDS;
	v_can_create_unique			NUMBER;
	v_logged_in_company			NUMBER;
	v_pending_company_sid		NUMBER;
	v_pend_request_creatd		NUMBER;
BEGIN
	security_pkg.SetContext('CHAIN_COMPANY', helper_pkg.GetTopCompanySid);
	
	--name (50%) + country
	dedupe_admin_pkg.SetSystemDefaultMapAndRules(in_try_reset => 1);
	
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company A',
		in_country_code		=> 'it',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_1
	);
	
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Random',
		in_country_code		=> 'it',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_2
	);
	
	company_pkg.DedupeNewCompany_Unsec(
		in_name				=> 'COMPANY AA',
		in_country_code		=> 'it',
		in_company_type_id	=> v_vend_company_type_id,
		in_address_1 		=> 'Via de Victoria',
		in_state 			=> 'Tivoli',
		in_postcode 		=> 'ME28',
		in_phone 			=> '2043434',
		in_city 			=> 'Medio',
		out_company_sid		=> v_new_company_sid_1,
		out_matched_sids	=> v_matched_sids,
		out_can_create_unique	=> v_can_create_unique
	);
	
	csr.unit_test_pkg.AssertAreEqual(v_new_company_sid_1, NULL, 'Didn''t expect a new company');
	csr.unit_test_pkg.AssertAreEqual(1, v_can_create_unique, '"Can create a unique company" was expected to be true');
	
	v_expected_matched_sids(1) := v_existing_company_sid_1;
	
	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);
	
	--same scenario for a company request made by a supplier:
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Toothpicks Vendor',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_logged_in_company
	);
	
	security_pkg.SetContext('CHAIN_COMPANY', v_logged_in_company);
	
	company_pkg.RequestNewCompany(
		in_name					=> 'Company AA',
		in_country_code			=> 'it',
		in_company_type_id		=> v_vend_company_type_id,
		in_address_1			=> 'Via de Victoria',
		in_address_2			=> 'Tivoli',
		out_company_sid			=> v_pending_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);
	
	csr.unit_test_pkg.AssertAreEqual(1, v_pend_request_creatd, 'Expected a pending request for a new company');
	csr.unit_test_pkg.AssertAreEqual(NULL, v_can_create_unique, '"Can create a unique company" was expected to be empty');
	AssertCompanyState(in_company_sid => v_pending_company_sid, in_requested_by_comp_sid => v_logged_in_company, in_is_pending => 1);
	
	v_expected_matched_sids(1) := v_existing_company_sid_1;
	
	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);
	
	security_pkg.SetContext('CHAIN_COMPANY', NULL);
END;

/* tests both against new company date and company requests */
PROCEDURE TestDedupeNewCompanyMatches
AS
	v_company_type_ids			helper_pkg.T_NUMBER_ARRAY;
	
	v_reference_tax				NUMBER;
	v_reference_bsci			NUMBER;
	
	v_tag_group_id_fac			NUMBER;
	v_tag_group_id_own			NUMBER;
	v_tag_garage_id				NUMBER;
	v_tag_store_id				NUMBER;
	v_tag_factory_id			NUMBER;
	v_tag_private_id			NUMBER;
	v_tag_public_id				NUMBER;
	
	v_mapping_id_tax			NUMBER;
	v_mapping_id_bsci			NUMBER;
	v_mapping_id_fac			NUMBER;
	v_mapping_id_own			NUMBER;
	v_mapping_id_ct				NUMBER;
	
	v_dedupe_rule_set_id		NUMBER;
	v_matched_sids				security_pkg.T_SID_IDS;
	v_expected_matched_sids		security_pkg.T_SID_IDS;
	v_mapping_ids				security_pkg.T_SID_IDS;
	v_rule_ids					security_pkg.T_SID_IDS;
	v_rule_type_ids				security_pkg.T_SID_IDS;
	v_match_thresholds			helper_pkg.T_NUMBER_ARRAY;
	v_existing_company_sid_1	NUMBER;
	v_existing_company_sid_2	NUMBER;
	v_existing_company_sid_3	NUMBER;
	v_new_company_sid			NUMBER;
	v_expected_company_sid		NUMBER;
	v_logged_in_company			NUMBER;
	v_pending_company_sid		NUMBER;
	v_pend_request_creatd		NUMBER;
	
	v_ref_ids					security_pkg.T_SID_IDS;
	v_ref_vals					chain_pkg.T_STRINGS;
	v_tag_ids					security_pkg.T_SID_IDS;
	
	v_can_create_unique			NUMBER;
BEGIN

	security_pkg.SetContext('CHAIN_COMPANY', helper_pkg.GetTopCompanySid);
	
	--setup some references
	helper_pkg.SaveReferenceLabel(
		in_reference_id	=> NULL,
		in_lookup_key => 'TAX_CODE',
		in_label => 'Tax code',
		in_mandatory => 0,
		in_reference_uniqueness_id => 1, /* Per country */
		in_reference_location_id => 0, /* Show on the company details card */
		in_company_type_ids	=> v_company_type_ids,
		out_reference_id	=> v_reference_tax
	);
	
	helper_pkg.SaveReferenceLabel(
		in_reference_id	=> NULL,
		in_lookup_key => 'BSCI_CODE',
		in_label => 'BSCI code',
		in_mandatory => 0,
		in_reference_uniqueness_id => 0, /* None */
		in_reference_location_id => 0, /* Show on the company details card */
		in_company_type_ids	=> v_company_type_ids,
		out_reference_id	=> v_reference_bsci
	);
	
	--and tag groups:
	csr.tag_pkg.SetTagGroup(
		in_tag_group_id			=> NULL,
		in_name					=> 'Facility type',
		in_multi_select			=> 1,
		in_applies_to_regions	=> 1,
		in_applies_to_suppliers	=> 1,
		in_applies_to_chain		=> 1,
		in_lookup_key			=> 'FACILITY_TYPE',
		out_tag_group_id		=> v_tag_group_id_fac
	);

	csr.tag_pkg.SetTag(
		in_tag_group_id		=> v_tag_group_id_fac,
		in_tag				=> 'Garage',
		in_lookup_key		=> 'GARAGE',
		out_tag_id			=> v_tag_garage_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id		=> v_tag_group_id_fac,
		in_tag				=> 'Store',
		in_lookup_key		=> 'STORE',
		out_tag_id			=> v_tag_store_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id		=> v_tag_group_id_fac,
		in_tag				=> 'Factory',
		in_lookup_key		=> 'FACTORY',
		out_tag_id			=> v_tag_factory_id
	);

	csr.tag_pkg.SetTagGroup(
		in_tag_group_id			=> NULL,
		in_name					=> 'Ownership type',
		in_applies_to_regions	=> 1,
		in_applies_to_suppliers	=> 1,
		in_applies_to_chain		=> 1,
		in_lookup_key			=> 'OWNERSHIP_TYPE',
		out_tag_group_id		=> v_tag_group_id_own
	);
	
	csr.tag_pkg.SetTag(
		in_tag_group_id		=> v_tag_group_id_own,
		in_tag				=> 'Private company',
		in_lookup_key		=> 'PRIVATE_COMPANY',
		out_tag_id			=> v_tag_private_id
	);
	
	csr.tag_pkg.SetTag(
		in_tag_group_id		=> v_tag_group_id_own,
		in_tag				=> 'Public company',
		in_lookup_key		=> 'PUBLIC_COMPANY',
		out_tag_id			=> v_tag_public_id
	);

	--set up some mappings for the system managed import source
	ClearSystemRules;
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> NULL,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_reference_id 			=> v_reference_tax,
		out_dedupe_mapping_id		=> v_mapping_id_tax
	);
		
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> NULL,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_reference_id 			=> v_reference_bsci,
		out_dedupe_mapping_id		=> v_mapping_id_bsci
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> NULL,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_tag_group_id 			=> v_tag_group_id_fac,
		out_dedupe_mapping_id		=> v_mapping_id_fac
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> NULL,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_tag_group_id 			=> v_tag_group_id_own,
		out_dedupe_mapping_id		=> v_mapping_id_own
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> NULL,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_COMPANY_TYPE,
		out_dedupe_mapping_id		=> v_mapping_id_ct
	);
	
	--add 1st rule set:
	v_rule_ids(1) := 0;
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_EXACT;
	v_match_thresholds(1) := 100;
	v_mapping_ids(1) :=	v_mapping_id_tax;
		
	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> NULL,
		in_description				=> 'System Default Match Rule (unique ref per country)',
		in_dedupe_staging_link_id	=> v_source_staging_link_id,
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);
	
	--2nd rule set:
	v_rule_ids(1) := 0;
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_EXACT;
	v_match_thresholds(1) := 100;
	v_mapping_ids(1) :=	v_mapping_id_bsci;
	
	v_rule_ids(2) := 0;
	v_rule_type_ids(2) := chain_pkg.RULE_TYPE_EXACT;
	v_match_thresholds(2) := 100;
	v_mapping_ids(2) :=	v_mapping_id_fac;
	
	v_rule_ids(3) := 0;
	v_rule_type_ids(3) := chain_pkg.RULE_TYPE_EXACT;
	v_match_thresholds(3) := 100;
	v_mapping_ids(3) :=	v_mapping_id_own;
		
	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> NULL,
		in_description				=> 'System Match Rule (ref and tag groups)',
		in_dedupe_staging_link_id	=> v_source_staging_link_id,
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 2,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);
	
	--add companies
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company A',
		in_country_code		=> 'it',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_1
	);
	
	INSERT INTO company_reference (company_sid, value, reference_id, company_reference_id)
		VALUES(v_existing_company_sid_1, '9999-888', v_reference_tax, company_reference_id_seq.nextval);
		
	INSERT INTO company_reference (company_sid, value, reference_id, company_reference_id)
		VALUES(v_existing_company_sid_1, '8888-777', v_reference_bsci, company_reference_id_seq.nextval);
	
	v_tag_ids(1) := v_tag_store_id;
	v_tag_ids(2) := v_tag_garage_id;
	v_tag_ids(3) := v_tag_private_id;
	
	company_pkg.SetTags(v_existing_company_sid_1, v_tag_ids);
	
	--2nd no-match company
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company B',
		in_country_code		=> 'it',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_2
	);
	
	--1st case. Exact match is expected using the unique tax code per country
	v_ref_ids(1) := v_reference_tax;
	v_ref_vals(1) := '9999-888';
	
	company_pkg.DedupeNewCompany_Unsec(
		in_name				=> 'Some random name',
		in_country_code		=> 'it',
		in_company_type_id	=> v_vend_company_type_id,
		in_address_1 		=> 'Via de Victoria',
		in_state 			=> 'Tivoli',
		in_postcode 		=> 'ME28',
		in_phone 			=> '2043434',
		in_city 			=> 'Medio',
		in_reference_ids	=> v_ref_ids,
		in_values			=> v_ref_vals,
		in_tag_ids			=> v_tag_ids,
		out_company_sid		=> v_new_company_sid,
		out_matched_sids	=> v_matched_sids,
		out_can_create_unique	=> v_can_create_unique
	);

	csr.unit_test_pkg.AssertAreEqual(NULL, v_new_company_sid, 'Didn''t expect a new company');
	csr.unit_test_pkg.AssertAreEqual(0, v_can_create_unique, '"Can create a unique company" was expected to be false as an exact match was found');
	
	v_expected_matched_sids(1) := v_existing_company_sid_1;
	
	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);
	
	v_expected_matched_sids.delete;
	
	--2nd case. No match is expected. New company is created
	v_ref_ids(1) := v_reference_tax;
	v_ref_vals(1) := '9999-886'; --no match
	
	company_pkg.DedupeNewCompany_Unsec(
		in_name				=> 'Some random name',
		in_country_code		=> 'it',
		in_company_type_id	=> v_vend_company_type_id,
		in_address_1 		=> 'Via de Victoria',
		in_state 			=> 'Tivoli',
		in_postcode 		=> 'ME28',
		in_phone 			=> '2043434',
		in_city 			=> 'Medio',
		in_reference_ids	=> v_ref_ids,
		in_values			=> v_ref_vals,
		in_tag_ids			=> v_tag_ids,
		out_company_sid		=> v_new_company_sid,
		out_matched_sids	=> v_matched_sids,
		out_can_create_unique	=> v_can_create_unique
	);

	v_expected_company_sid := test_chain_utils_pkg.GetChainCompanySid('Some random name', 'it');
	csr.unit_test_pkg.AssertAreEqual(v_expected_company_sid, v_new_company_sid, 'The created company is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(0, v_can_create_unique, '"Can create a unique company" was expected to be false as the new company has been created');
	
	AssertCreatedData(
		in_company_sid	=> v_new_company_sid,
		in_tag_ids		=> v_tag_ids,
		in_ref_ids		=> v_ref_ids,
		in_ref_vals 	=> v_ref_vals
	);
	
	IF v_matched_sids IS NOT NULL AND v_matched_sids.COUNT > 0 THEN
		csr.unit_test_pkg.TestFail('No matches were expected');
	END IF;

	--3rd case. A non-exact match is expected based on tags and non-unique bsci ref
	v_ref_ids.delete;
	v_ref_vals.delete;
	
	v_ref_ids(1) := v_reference_bsci;
	v_ref_vals(1) := '8888-777'; 
	
	company_pkg.DedupeNewCompany_Unsec(
		in_name				=> 'Some random name 2',--no partial match on name has been defined in that test so we don't expect a match on name
		in_country_code		=> 'it',
		in_company_type_id	=> v_vend_company_type_id,
		in_address_1 		=> 'Via de Victoria',
		in_state 			=> 'Tivoli',
		in_postcode 		=> 'ME28',
		in_phone 			=> '2043434',
		in_city 			=> 'Medio',
		in_reference_ids	=> v_ref_ids,
		in_values			=> v_ref_vals,
		in_tag_ids			=> v_tag_ids,
		out_company_sid		=> v_new_company_sid,
		out_matched_sids	=> v_matched_sids,
		out_can_create_unique	=> v_can_create_unique
	);
	
	csr.unit_test_pkg.AssertAreEqual(NULL, v_new_company_sid, 'Didn''t expect a new company');
	csr.unit_test_pkg.AssertAreEqual(1, v_can_create_unique, '"Can create a unique company" was expected to be true');
	
	v_expected_matched_sids(1) := v_existing_company_sid_1;
	
	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);
	v_expected_matched_sids.delete;
	
	------------------------------------------------------
	--Now try against a company request made by a supplier:
	--set the company context and send a request for a new company
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Toothpicks Vendor',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_logged_in_company
	);
	
	security_pkg.SetContext('CHAIN_COMPANY', v_logged_in_company);
	
	--the supplier requests a new site with the same refs and tags
	company_pkg.RequestNewCompany(
		in_name					=> 'Some random name 2',
		in_country_code			=> 'it',
		in_company_type_id		=> v_site_company_type_id,
		in_address_1			=> 'Via de Victoria',
		in_address_2			=> 'Tivoli',
		in_reference_ids		=> v_ref_ids,
		in_values				=> v_ref_vals,
		in_tag_ids				=> v_tag_ids,
		out_company_sid			=> v_pending_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);
	
	csr.unit_test_pkg.AssertAreEqual(1, v_pend_request_creatd, 'Expected a pending request for a new company');
	csr.unit_test_pkg.AssertAreEqual(NULL, v_can_create_unique, '"Can create a unique company" was expected to be empty');
	AssertCompanyState(in_company_sid => v_pending_company_sid, in_requested_by_comp_sid => v_logged_in_company, in_is_pending => 1);
	
	v_expected_matched_sids(1) := v_existing_company_sid_1;
	
	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);
	
	security_pkg.SetContext('CHAIN_COMPANY', helper_pkg.GetTopCompanySid);
	--------------------------------------------------------
	
	--4th case: add 3rd rule set with company type and non-unique reference
	--3rd rule set:
	v_mapping_ids.delete;
	v_rule_ids.delete;
	v_match_thresholds.delete;
	v_rule_type_ids.delete;
	
	v_rule_ids(1) := 0;
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_EXACT;
	v_match_thresholds(1) := 100;
	v_mapping_ids(1) :=	v_mapping_id_bsci;
	
	v_rule_ids(2) := 0;
	v_rule_type_ids(2) := chain_pkg.RULE_TYPE_EXACT;
	v_match_thresholds(2) := 100;
	v_mapping_ids(2) :=	v_mapping_id_ct;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> NULL,
		in_description				=> 'System Match Rule (ref and company type)',
		in_dedupe_staging_link_id	=> v_source_staging_link_id,
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 3,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);
	
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company AA',
		in_country_code		=> 'de',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_3
	);
			
	INSERT INTO company_reference (company_sid, value, reference_id, company_reference_id)
		VALUES(v_existing_company_sid_3, 'abcde-22', v_reference_bsci, company_reference_id_seq.nextval);
		
	v_tag_ids.delete;
	v_ref_ids.delete;
	v_ref_vals.delete;
	
	v_ref_ids(1) := v_reference_bsci;
	v_ref_vals(1) := 'abcde-22'; 
	
	company_pkg.DedupeNewCompany_Unsec(
		in_name				=> 'Some random name 3',--no partial match on name has been defined in that test so we don't expect a match on name
		in_country_code		=> 'it',
		in_company_type_id	=> v_vend_company_type_id,
		in_address_1 		=> 'Via de Victoria',
		in_state 			=> 'Tivoli',
		in_postcode 		=> 'ME28',
		in_phone 			=> '2043434',
		in_city 			=> 'Medio',
		in_reference_ids	=> v_ref_ids,
		in_values			=> v_ref_vals,
		in_tag_ids			=> v_tag_ids,
		out_company_sid		=> v_new_company_sid,
		out_matched_sids	=> v_matched_sids,
		out_can_create_unique	=> v_can_create_unique
	);
	
	csr.unit_test_pkg.AssertAreEqual(NULL, v_new_company_sid, 'Didn''t expect a new company');
	csr.unit_test_pkg.AssertAreEqual(1, v_can_create_unique, '"Can create a unique company" was expected to be true');
	
	v_expected_matched_sids(1) := v_existing_company_sid_3;
	
	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);
	v_expected_matched_sids.delete;
	
	security_pkg.SetContext('CHAIN_COMPANY', v_logged_in_company);
	
	--same scenario for a company request, company type (vendor) and non-unique reference
	company_pkg.RequestNewCompany(
		in_name					=> 'Some random name 3',
		in_country_code			=> 'it',
		in_company_type_id		=> v_vend_company_type_id,
		in_address_1			=> 'Via de Victoria',
		in_address_2			=> 'Tivoli',
		in_reference_ids		=> v_ref_ids,
		in_values				=> v_ref_vals,
		in_tag_ids				=> v_tag_ids,
		out_company_sid			=> v_pending_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);
	
	csr.unit_test_pkg.AssertAreEqual(1, v_pend_request_creatd, 'Expected a pending request for a new company');
	csr.unit_test_pkg.AssertAreEqual(NULL, v_can_create_unique, '"Can create a unique company" was expected to be empty');
	AssertCompanyState(in_company_sid => v_pending_company_sid, in_requested_by_comp_sid => v_logged_in_company, in_is_pending => 1);
	
	v_expected_matched_sids(1) := v_existing_company_sid_3;
	
	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);
	
	security_pkg.SetContext('CHAIN_COMPANY', NULL);
END;

PROCEDURE TestMultipleMatchTypeNameCntr
AS
	v_existing_company_sid_1	NUMBER;
	v_existing_company_sid_2	NUMBER;
	v_existing_company_sid_3	NUMBER;
	v_existing_company_sid_4	NUMBER;
	v_mapping_id_name			NUMBER;
	v_mapping_id_cntr			NUMBER;
	v_mapping_id_ct				NUMBER;
	v_dedupe_rule_set_id		NUMBER;
	v_new_company_sid			NUMBER;
	v_expected_company_sid		NUMBER;
	v_can_create_unique			NUMBER;
	v_expected_company_sid		NUMBER;
	v_logged_in_company			NUMBER;
	v_pending_company_sid		NUMBER;
	v_pend_request_creatd		NUMBER;
	v_expected_matched_sids		security_pkg.T_SID_IDS;
	v_matched_sids				security_pkg.T_SID_IDS;
	v_rule_ids					security_pkg.T_SID_IDS;
	v_mapping_ids				security_pkg.T_SID_IDS;
	v_rule_type_ids				security_pkg.T_SID_IDS;
	v_match_thresholds			helper_pkg.T_NUMBER_ARRAY;
BEGIN
	security_pkg.SetContext('CHAIN_COMPANY', helper_pkg.GetTopCompanySid);
	
	--set up some mappings for the system managed import source
	ClearSystemRules;
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> NULL,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_NAME,
		out_dedupe_mapping_id		=> v_mapping_id_name
	);
		
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> NULL,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id		=> v_mapping_id_cntr
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> NULL,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_COMPANY_TYPE,
		out_dedupe_mapping_id		=> v_mapping_id_ct
	);
	
	v_rule_ids(1):= 0;
	v_mapping_ids(1) := v_mapping_id_name;
	v_match_thresholds(1) := 50;
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_LEVENSHTEIN;
	
	v_rule_ids(2):= 0;
	v_mapping_ids(2) := v_mapping_id_cntr;
	v_match_thresholds(2) := 100;
	v_rule_type_ids(2) := chain_pkg.RULE_TYPE_EXACT;
	
	v_rule_ids(3):= 0;
	v_mapping_ids(3) := v_mapping_id_ct;
	v_match_thresholds(3) := 100;
	v_rule_type_ids(3) := chain_pkg.RULE_TYPE_EXACT;
	
	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> NULL,
		in_description				=> 'System Match Rule (name fuzzy, country and company type)',
		in_dedupe_staging_link_id	=> v_source_staging_link_id,
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);
	
	--setup some companies:
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Histon florists',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_1
	);
	
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Cambs florists',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_2
	);
	
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Camb florists',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_3
	);
	
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Cheese factory',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_4
	);
	
	company_pkg.DedupeNewCompany_Unsec(
		in_name				=> 'Histon-florist',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_address_1 		=> 'Station Rd',
		in_state 			=> 'Cambs',
		in_postcode 		=> 'CB3TY2',
		in_phone 			=> '-',
		in_city 			=> 'Histon',
		out_company_sid		=> v_new_company_sid,
		out_matched_sids	=> v_matched_sids,
		out_can_create_unique	=> v_can_create_unique
	);
	
	csr.unit_test_pkg.AssertAreEqual(NULL, v_new_company_sid, 'Didn''t expect a new company');
	csr.unit_test_pkg.AssertAreEqual(1, v_can_create_unique, '"Can create a unique company" was expected to be true');
	
	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;
	
	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);
	
	--same scenario for a company request made by a supplier:
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Toothpicks Vendor',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_logged_in_company
	);
	
	security_pkg.SetContext('CHAIN_COMPANY', v_logged_in_company);
	
	company_pkg.RequestNewCompany(
		in_name					=> 'Histon-florist',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_vend_company_type_id,
		in_address_1			=> 'Via de Victoria',
		in_address_2			=> 'Tivoli',
		out_company_sid			=> v_pending_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);
	
	csr.unit_test_pkg.AssertAreEqual(1, v_pend_request_creatd, 'Expected a pending request for a new company');
	csr.unit_test_pkg.AssertAreEqual(NULL, v_can_create_unique, '"Can create a unique company" was expected to be empty');
	AssertCompanyState(in_company_sid => v_pending_company_sid, in_requested_by_comp_sid => v_logged_in_company, in_is_pending => 1);
	
	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;
	
	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);
	
	security_pkg.SetContext('CHAIN_COMPANY', NULL);
END;

PROCEDURE TestRequestExactMatchRef
AS
	v_existing_company_sid_1	NUMBER;
	v_existing_company_sid_2	NUMBER;
	v_existing_company_sid_3	NUMBER;
	v_reference_tax				NUMBER;
	v_company_type_ids			helper_pkg.T_NUMBER_ARRAY;
	v_company_sid				security_pkg.T_SID_ID;
	v_pend_request_creatd		NUMBER;
	v_can_create_unique			NUMBER;
	v_company_type_relat_err	NUMBER;
	v_count						NUMBER;
	v_matched_sids				security_pkg.T_SID_IDS;
	v_expected_matched_sids		security_pkg.T_SID_IDS;
	v_reference_ids				security_pkg.T_SID_IDS;
	v_values					chain_pkg.T_STRINGS;
	v_bool	 					BOOLEAN;
BEGIN
	dedupe_admin_pkg.SetSystemDefaultMapAndRules(in_try_reset => 1);
	
	--setup some references
	helper_pkg.SaveReferenceLabel(
		in_reference_id	=> NULL,
		in_lookup_key => 'TAX_CODE',
		in_label => 'Tax code',
		in_mandatory => 0,
		in_reference_uniqueness_id => chain_pkg.REF_UNIQUE_GLOBAL ,
		in_reference_location_id => 0, /* Show on the company details card */
		in_company_type_ids	=> v_company_type_ids,
		out_reference_id	=> v_reference_tax
	);
	
	--setup some companies:
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Histon florists vendor',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_1
	);
	INSERT INTO company_reference (company_sid, value, reference_id, company_reference_id)
		VALUES(v_existing_company_sid_1, '9999-888', v_reference_tax, company_reference_id_seq.nextval);
		
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Cambs florists site',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_2
	);
	INSERT INTO company_reference (company_sid, value, reference_id, company_reference_id)
		VALUES(v_existing_company_sid_2, '9999888', v_reference_tax, company_reference_id_seq.nextval);
	
	
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Super big vendor',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_3
	);
	
	--set the company context and send a request for a new company	
	security_pkg.SetContext('CHAIN_COMPANY', v_existing_company_sid_3);
	
	--initially the supplier requests a company that cannot be related with anyway because of the company type
	v_reference_ids(1) := v_reference_tax;
	v_values(1) := '9999-888';
	
	company_pkg.RequestNewCompany(
		in_name					=> 'I don''t know the name of the company but I rely on dedupe to find it',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_vend_company_type_id,
		in_reference_ids		=> v_reference_ids,
		in_values				=> v_values,
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);
	
	csr.unit_test_pkg.AssertAreEqual(1, v_pend_request_creatd, 'Expected a pending request for a new company');
	csr.unit_test_pkg.AssertAreEqual(NULL, v_can_create_unique, '"Can create a unique company" was expected to be empty');
	AssertCompanyState(in_company_sid => v_company_sid, in_requested_by_comp_sid => v_existing_company_sid_3, in_is_pending => 1);
	
	v_expected_matched_sids(1) := v_existing_company_sid_1;
	
	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);
	
	--set an action for matching
	INSERT INTO company_request_action(company_sid, matched_company_sid, action)
	VALUES(v_company_sid, v_existing_company_sid_1, chain_pkg.MERGE_PENDING_COMPANY);

	--now try to process it, expect an error message for COMPANY_TYPE_RELATION_NA
	v_bool := company_pkg.ProcessPendingRequest_UNSEC(v_company_sid);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM company_request_action
	 WHERE company_sid = v_company_sid
	   AND lower(error_message) LIKE '%this type of relationship is not supported%';
	
	IF v_count = 0 THEN
		csr.unit_test_pkg.TestFail('Expected a "N/A company type relationship" error');
	END IF;
	
	AssertCompanyState(in_company_sid => v_company_sid, in_requested_by_comp_sid => v_existing_company_sid_3, in_is_pending => 1); --company state after match should be still pending
	--no new relationship expected neither against pending nor against matched
	AssertRelationship(v_existing_company_sid_3, v_company_sid, 0);
	AssertRelationship(v_existing_company_sid_3, v_existing_company_sid_1, 0);
	
	--now reject the request
	UPDATE company_request_action
	   SET matched_company_sid = NULL,
	   is_processed = 0,
	   error_message = NULL,
	   action = chain_pkg.REJECT_PENDING_COMPANY
	 WHERE company_sid = v_company_sid;
	
	v_bool := company_pkg.ProcessPendingRequest_UNSEC(v_company_sid);
	AssertCompanyState(in_company_sid => v_company_sid, in_requested_by_comp_sid => v_existing_company_sid_3, in_is_pending => 1); --company state after reject should be still pending
	
	--clear context
	security_pkg.SetContext('CHAIN_COMPANY', NULL);
END;

PROCEDURE TestRequestExactMatchNameCnt
AS
	v_existing_company_sid_1	NUMBER;
	v_existing_company_sid_2	NUMBER;
	v_existing_company_sid_3	NUMBER;
	v_reference_tax				NUMBER;
	v_company_type_ids			helper_pkg.T_NUMBER_ARRAY;
	v_company_sid				security_pkg.T_SID_ID;
	v_pend_request_creatd		NUMBER;
	v_can_create_unique			NUMBER;
	v_company_type_relat_err	NUMBER;
	v_count						NUMBER;
	v_matched_sids				security_pkg.T_SID_IDS;
	v_expected_matched_sids		security_pkg.T_SID_IDS;
	v_reference_ids				security_pkg.T_SID_IDS;
	v_values					chain_pkg.T_STRINGS;
	v_bool						BOOLEAN;
BEGIN
	dedupe_admin_pkg.SetSystemDefaultMapAndRules(in_try_reset => 1);
	
	--setup some companies:
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Histon florists vendor',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_1
	);
		
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Cambs florists site',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_2
	);	
	
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Super big vendor',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_3
	);
	
	--set the company context and send a request for a new company	
	security_pkg.SetContext('CHAIN_COMPANY', v_existing_company_sid_3);
	
	--initially the supplier requests a company
	company_pkg.RequestNewCompany(
		in_name					=> 'Cambs florists site',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_site_company_type_id,
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);
			
	--clear context
	security_pkg.SetContext('CHAIN_COMPANY', NULL);
	
	csr.unit_test_pkg.AssertAreEqual(1, v_pend_request_creatd, 'Expected a pending request for a new company');
	csr.unit_test_pkg.AssertAreEqual(NULL, v_can_create_unique, '"Can create a unique company" was expected to be empty');
	
	AssertCompanyState(in_company_sid => v_company_sid, in_requested_by_comp_sid => v_existing_company_sid_3, in_is_pending => 1);
	
	v_expected_matched_sids(1) := v_existing_company_sid_2;
	
	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);
	
	--set an action for matching
	INSERT INTO company_request_action(company_sid, matched_company_sid, action)
	VALUES(v_company_sid, v_existing_company_sid_2, chain_pkg.MERGE_PENDING_COMPANY);

	--now try to process it, it should create a relationship
	v_bool := company_pkg.ProcessPendingRequest_UNSEC(v_company_sid);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM company_request_action
	 WHERE company_sid = v_company_sid
	   AND error_message IS NULL
	   AND is_processed = 1;
	
	IF v_count = 0 THEN
		csr.unit_test_pkg.TestFail('Wrong state on company requested action table');
	END IF;
	
	AssertCompanyState(in_company_sid => v_company_sid, in_requested_by_comp_sid => v_existing_company_sid_3, in_is_pending => 1); --still pending as we chose a different company to match and not the requested one
	AssertRelationship(v_existing_company_sid_3, v_existing_company_sid_2, 1);
END;

PROCEDURE TestRequestSuggMatchNameAddr
AS
	v_existing_company_sid_1	NUMBER;
	v_existing_company_sid_2	NUMBER;
	v_existing_company_sid_3	NUMBER;
	v_existing_company_sid_4	NUMBER;
	
	v_company_type_ids			helper_pkg.T_NUMBER_ARRAY;
	v_company_sid				security_pkg.T_SID_ID;
	v_company_sid_2				security_pkg.T_SID_ID;
	v_pend_request_creatd		NUMBER;
	v_pend_request_creatd_2		NUMBER;
	v_can_create_unique			NUMBER;
	v_can_create_unique_2		NUMBER;
	v_company_type_relat_err	NUMBER;
	v_count						NUMBER;
	v_matched_sids				security_pkg.T_SID_IDS;
	v_matched_sids_2			security_pkg.T_SID_IDS;
	v_expected_matched_sids		security_pkg.T_SID_IDS;
	
	v_mapping_id_ct				NUMBER;
	v_mapping_address_id		NUMBER;
	v_mapping_id_cntr			NUMBER;
	v_mapping_id_name			NUMBER;
	
	v_dedupe_rule_set_id		NUMBER;
	v_mapping_ids				security_pkg.T_SID_IDS;
	v_rule_ids					security_pkg.T_SID_IDS;
	v_rule_type_ids				security_pkg.T_SID_IDS;
	v_match_thresholds			helper_pkg.T_NUMBER_ARRAY;
	v_bool 						BOOLEAN;
BEGIN
	ClearSystemRules;
	
	--setup some references
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> NULL,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_NAME,
		out_dedupe_mapping_id		=> v_mapping_id_name
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> NULL,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id		=> v_mapping_id_cntr
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> NULL,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_COMPANY_TYPE,
		out_dedupe_mapping_id		=> v_mapping_id_ct
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id 		=> NULL,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id			=> chain_pkg.FLD_COMPANY_ADDRESS,
		out_dedupe_mapping_id 		=> v_mapping_address_id
	);
	
	v_mapping_ids(1) := v_mapping_id_name;
	v_mapping_ids(2) := v_mapping_id_cntr;
	v_mapping_ids(3) := v_mapping_id_ct;
	v_mapping_ids(4) := v_mapping_address_id;
	
	FOR i IN 1 .. 4 LOOP
		IF i IN (1, 4) THEN
			v_match_thresholds(i) := 60;
			v_rule_type_ids(i) := chain_pkg.RULE_TYPE_LEVENSHTEIN;
		ELSE 
			v_match_thresholds(i) := 100;
			v_rule_type_ids(i) := chain_pkg.RULE_TYPE_EXACT;
		END IF;
		
		v_rule_ids(i) := 0;
	END LOOP;
	
	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> NULL,
		in_description				=> 'System Match Rule (fuzzy name, country, fuzzy address, company type)',
		in_dedupe_staging_link_id	=> v_source_staging_link_id,
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);
		
	--setup some companies:
	--1st
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Histon florists site',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_1
	);
	
	UPDATE company
	   SET address_1 = '22 Station Rd',
		address_2 = 'Histon'
	 WHERE company_sid = v_existing_company_sid_1;
	 
	--2nd
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Cambs florists site',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_2
	);	
	
	UPDATE company
	   SET address_1 = '23 Chesterton Rd',
		address_2 = 'Cambs'
	 WHERE company_sid = v_existing_company_sid_2;
	
	--3rd, no address
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Histon florists',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_3
	);	
	
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Super big vendor',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_4
	);
	
	--set the company context and send a request for a new company	
	security_pkg.SetContext('CHAIN_COMPANY', v_existing_company_sid_4);
	
	--the supplier requests a new site
	company_pkg.RequestNewCompany(
		in_name					=> 'Histn florists', --misspelled on purpose => 70% match with company 1, 48% vs company 2
		in_country_code			=> 'gb',
		in_company_type_id		=> v_site_company_type_id,
		in_address_1			=> '22 Station road',
		in_address_2			=> 'Hiton',--misspelled on purpose
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);
	
	--user is quite persisent and tries to request the same company again - just testing we are not causing dup obj name error on SO name
	company_pkg.RequestNewCompany(
		in_name					=> 'Histn florists', --misspelled on purpose => 70% match with company 1, 48% vs company 2
		in_country_code			=> 'gb',
		in_company_type_id		=> v_site_company_type_id,
		in_address_1			=> '22 Station road',
		in_address_2			=> 'Hiton',--misspelled on purpose
		out_company_sid			=> v_company_sid_2,
		out_pend_request_creatd => v_pend_request_creatd_2,
		out_can_create_unique	=> v_can_create_unique_2,
		out_matched_sids		=> v_matched_sids_2
	);
	
	--set context to top company
	security_pkg.SetContext('CHAIN_COMPANY', chain.helper_pkg.GetTopCompanySid);
	
	csr.unit_test_pkg.AssertAreEqual(1, v_pend_request_creatd, 'Expected a pending request for a new company');
	csr.unit_test_pkg.AssertAreEqual(NULL, v_can_create_unique, '"Can create a unique company" was expected to be empty');
	AssertCompanyState(in_company_sid => v_company_sid, in_requested_by_comp_sid => v_existing_company_sid_4, in_is_pending => 1);
	
	v_expected_matched_sids(1) := v_existing_company_sid_1;
	
	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);
	
 	--set an action for promoting the pending instead of using the matching, admin prefers the misspelled version
	INSERT INTO company_request_action(company_sid, matched_company_sid, action)
	VALUES(v_company_sid, NULL, chain_pkg.ACCEPT_PENDING_COMPANY);

	v_bool := company_pkg.ProcessPendingRequest_UNSEC(v_company_sid);
		
	AssertCompanyState(in_company_sid => v_company_sid, in_requested_by_comp_sid => v_existing_company_sid_4, in_is_pending => 0); --company state after match should be still pending
	--expect relationships bot against requesting and top
	AssertRelationship(v_existing_company_sid_4, v_company_sid, 1);
	AssertRelationship(chain.helper_pkg.GetTopCompanySid, v_company_sid, 1);
	
	--clear context
	security_pkg.SetContext('CHAIN_COMPANY', NULL);
END;

PROCEDURE TestLevenshteinEmailMatch
AS
	v_existing_company_sid_1	NUMBER;
	v_existing_company_sid_2	NUMBER;
	v_existing_company_sid_3	NUMBER;
	v_logged_in_company			NUMBER;

	v_company_sid				security_pkg.T_SID_ID;
	v_pend_request_creatd		NUMBER;
	v_can_create_unique			NUMBER;
	v_matched_sids				security_pkg.T_SID_IDS;
	v_expected_matched_sids		security_pkg.T_SID_IDS;
	
	v_mapping_email_addr_id		NUMBER;
	v_dedupe_rule_set_id		NUMBER;
	v_mapping_ids				security_pkg.T_SID_IDS;
	v_rule_ids					security_pkg.T_SID_IDS;
	v_rule_type_ids				security_pkg.T_SID_IDS;
	v_match_thresholds			helper_pkg.T_NUMBER_ARRAY;
BEGIN
	ClearSystemRules;

	--setup some references
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> -1,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_EMAIL,
		out_dedupe_mapping_id		=> v_mapping_email_addr_id
	);

	v_mapping_ids(1) := v_mapping_email_addr_id;

	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_LEVENSHTEIN;

	v_match_thresholds(1) := 60;

	--Set rule sets
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_email_addr_id));

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> NULL,
		in_description				=> 'Levenshtein email partial match',
		in_dedupe_staging_link_id	=> v_source_staging_link_id,
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);

	--setup some companies:
	--1st
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Histon florists site',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_1
	);

	UPDATE company
	   SET email = 'b@uka.com'
	 WHERE company_sid = v_existing_company_sid_1;

	dedupe_preprocess_pkg.PreprocessCompany(v_existing_company_sid_1);

	--2nd
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Cambs florists site',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_2
	);

	UPDATE company
	   SET email = 'a@uk.com'
	 WHERE company_sid = v_existing_company_sid_2;

	dedupe_preprocess_pkg.PreprocessCompany(v_existing_company_sid_2);
	
	--3nd - not matched
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Cambs butchers',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_3
	);

	UPDATE company
	   SET email = 'a@uc.com'
	 WHERE company_sid = v_existing_company_sid_3;

	dedupe_preprocess_pkg.PreprocessCompany(v_existing_company_sid_3);

	--set the company context and send a request for a new company
	security_pkg.SetContext('CHAIN_COMPANY', chain.helper_pkg.GetTopCompanySid);

	--the supplier requests a new site
	company_pkg.RequestNewCompany(
		in_name					=> 'Histn florists',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_site_company_type_id,
		in_email				=> 'a@uk.com',
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;


	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	csr.unit_test_pkg.AssertAreEqual(0, v_pend_request_creatd, 'Expected a pending request for a new company');
	csr.unit_test_pkg.AssertAreEqual(1, v_can_create_unique, '"Can create a unique company" was expected to be empty');

	--same scenario for a company request made by a supplier:
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Toothpicks Vendor',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_logged_in_company
	);

	security_pkg.SetContext('CHAIN_COMPANY', v_logged_in_company);

	--the supplier requests a new site
	company_pkg.RequestNewCompany(
		in_name					=> 'Some random name 2',
		in_country_code			=> 'it',
		in_company_type_id		=> v_site_company_type_id,
		in_email				=> 'abc@uk.com',
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	--clear context
	security_pkg.SetContext('CHAIN_COMPANY', NULL);
END;

PROCEDURE TestExactMatchEmail
AS
	v_existing_company_sid_1	NUMBER;
	v_existing_company_sid_2	NUMBER;
	v_existing_company_sid_3	NUMBER;
	v_logged_in_company			NUMBER;
	v_new_company_email			VARCHAR2(255);

	v_company_sid				security_pkg.T_SID_ID;
	v_pend_request_creatd		NUMBER;
	v_can_create_unique			NUMBER;
	v_matched_sids				security_pkg.T_SID_IDS;
	v_expected_matched_sids		security_pkg.T_SID_IDS;

	v_mapping_email_addr_id		NUMBER;

	v_dedupe_rule_set_id		NUMBER;
	v_mapping_ids				security_pkg.T_SID_IDS;
	v_rule_ids					security_pkg.T_SID_IDS;
	v_rule_type_ids				security_pkg.T_SID_IDS;
	v_match_thresholds			helper_pkg.T_NUMBER_ARRAY;
BEGIN
	ClearSystemRules;

	--setup some references
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> -1,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_EMAIL,
		out_dedupe_mapping_id		=> v_mapping_email_addr_id
	);

	v_mapping_ids(1) := v_mapping_email_addr_id;

	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_EXACT;

	v_match_thresholds(1) := 100;

	--Set rule sets
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_email_addr_id));

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> NULL,
		in_description				=> 'Email exact match',
		in_dedupe_staging_link_id	=> v_source_staging_link_id,
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);

	--setup some companies:
	--1st
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Histon florists site',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_1
	);

	UPDATE company
	   SET email = 'a@us.com'
	 WHERE company_sid = v_existing_company_sid_1;

	dedupe_preprocess_pkg.PreprocessCompany(v_existing_company_sid_1);

	--2nd
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Cambs florists site',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_2
	);

	UPDATE company
	   SET email = 'b@us.com'
	 WHERE company_sid = v_existing_company_sid_2;

	dedupe_preprocess_pkg.PreprocessCompany(v_existing_company_sid_2);
	
	--3rd no match
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Cambs butchers',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_3
	);

	UPDATE company
	   SET email = 'b@uk.com'
	 WHERE company_sid = v_existing_company_sid_3;

	dedupe_preprocess_pkg.PreprocessCompany(v_existing_company_sid_3);

	--set the company context and send a request for a new company
	security_pkg.SetContext('CHAIN_COMPANY', chain.helper_pkg.GetTopCompanySid);

	--the supplier requests a new site
	company_pkg.RequestNewCompany(
		in_name					=> 'Histn florists',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_site_company_type_id,
		in_email				=>'a@us.com',
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;

	v_new_company_email := 'a@us.com';

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	csr.unit_test_pkg.AssertAreEqual(0, v_pend_request_creatd, 'Expected a pending request for a new company');
	csr.unit_test_pkg.AssertAreEqual(1, v_can_create_unique, '"Can create a unique company" was expected to be empty');

	--same scenario for a company request made by a supplier:
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Toothpicks Vendor',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_logged_in_company
	);

	security_pkg.SetContext('CHAIN_COMPANY', v_logged_in_company);

	--the supplier requests a new site
	company_pkg.RequestNewCompany(
		in_name					=> 'test random no',
		in_country_code			=> 'it',
		in_company_type_id		=> v_site_company_type_id,
		in_email				=> 'abc@us.com',
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	--clear context
	security_pkg.SetContext('CHAIN_COMPANY', NULL);
END;

PROCEDURE TestJarowinklerMatchEmail
AS
	v_existing_company_sid_1	NUMBER;
	v_existing_company_sid_2	NUMBER;
	v_existing_company_sid_3	NUMBER;
	v_logged_in_company			NUMBER;
	
	v_company_sid				security_pkg.T_SID_ID;
	v_pend_request_creatd		NUMBER;
	v_can_create_unique			NUMBER;
	v_matched_sids				security_pkg.T_SID_IDS;
	v_expected_matched_sids		security_pkg.T_SID_IDS;
	
	v_mapping_email_addr_id		NUMBER;
	
	v_dedupe_rule_set_id		NUMBER;
	v_mapping_ids				security_pkg.T_SID_IDS;
	v_rule_ids					security_pkg.T_SID_IDS;
	v_rule_type_ids				security_pkg.T_SID_IDS;
	v_match_thresholds			helper_pkg.T_NUMBER_ARRAY;
BEGIN
	ClearSystemRules;

	--setup some references
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> -1,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_EMAIL,
		out_dedupe_mapping_id		=> v_mapping_email_addr_id
	);

	v_mapping_ids(1) := v_mapping_email_addr_id;
	
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_JAROWINKLER;
	
	v_match_thresholds(1) := 70;

	--Set rule sets
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_email_addr_id));

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> NULL,
		in_description				=> 'Jarowinkler email partial match',
		in_dedupe_staging_link_id	=> v_source_staging_link_id,
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);

	--setup some companies:
	--1st
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Histon florists site',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_1
	);

	UPDATE company
	   SET email = 'a@rocky.com'
	 WHERE company_sid = v_existing_company_sid_1;

	dedupe_preprocess_pkg.PreprocessCompany(v_existing_company_sid_1);

	--2nd
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Cambs florists site',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_2
	);

	UPDATE company
	   SET email = 'j@rocki.com'
	 WHERE company_sid = v_existing_company_sid_2;

	dedupe_preprocess_pkg.PreprocessCompany(v_existing_company_sid_2);
	
	--3rd no match
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Cambs butchers',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_3
	);

	UPDATE company
	   SET email = 'a@roall.com'
	 WHERE company_sid = v_existing_company_sid_3;

	dedupe_preprocess_pkg.PreprocessCompany(v_existing_company_sid_3);

	--set the company context and send a request for a new company
	security_pkg.SetContext('CHAIN_COMPANY', chain.helper_pkg.GetTopCompanySid);

	--the supplier requests a new site
	company_pkg.RequestNewCompany(
		in_name					=> 'Histn florists',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_site_company_type_id,
		in_email				=>'a@rocKyx.com ',
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	csr.unit_test_pkg.AssertAreEqual(0, v_pend_request_creatd, 'Expected a pending request for a new company');
	csr.unit_test_pkg.AssertAreEqual(1, v_can_create_unique, '"Can create a unique company" was expected to be empty');

	--same scenario for a company request made by a supplier:
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Toothpicks Vendor',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_logged_in_company
	);

	security_pkg.SetContext('CHAIN_COMPANY', v_logged_in_company);

	--the supplier requests a new site
	company_pkg.RequestNewCompany(
		in_name					=> 'Some random name 2',
		in_country_code			=> 'it',
		in_company_type_id		=> v_site_company_type_id,
		in_email				=> 'xyz@rocki.com',
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	--clear context
	security_pkg.SetContext('CHAIN_COMPANY', NULL);
END;

PROCEDURE TestContainsMatchEmail
AS
	v_existing_company_sid_1	NUMBER;
	v_existing_company_sid_2	NUMBER;
	v_existing_company_sid_3	NUMBER;
	v_logged_in_company			NUMBER;
	v_new_company_email			VARCHAR2(255);

	v_company_sid				security_pkg.T_SID_ID;
	v_pend_request_creatd		NUMBER;
	v_can_create_unique			NUMBER;
	v_matched_sids				security_pkg.T_SID_IDS;
	v_expected_matched_sids		security_pkg.T_SID_IDS;

	v_mapping_email_addr_id		NUMBER;

	v_dedupe_rule_set_id		NUMBER;
	v_mapping_ids				security_pkg.T_SID_IDS;
	v_rule_ids					security_pkg.T_SID_IDS;
	v_rule_type_ids				security_pkg.T_SID_IDS;
	v_match_thresholds			helper_pkg.T_NUMBER_ARRAY;
BEGIN
	ClearSystemRules;

	--setup some references
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> -1,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_EMAIL,
		out_dedupe_mapping_id		=> v_mapping_email_addr_id
	);

	v_mapping_ids(1) := v_mapping_email_addr_id;

	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_CONTAINS;

	v_match_thresholds(1) := 100;

	--Set rule sets
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_email_addr_id));

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> NULL,
		in_description				=> 'Email contains match',
		in_dedupe_staging_link_id	=> v_source_staging_link_id,
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);

	--setup some companies:
	--1st
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Test Company',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_1
	);

	UPDATE company
	   SET email = 'a@ul.com'
	 WHERE company_sid = v_existing_company_sid_1;

	dedupe_preprocess_pkg.PreprocessCompany(v_existing_company_sid_1);

	--2nd
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Mindtree',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_2
	);

	UPDATE company
	   SET email = 'j@ul2.com'
	 WHERE company_sid = v_existing_company_sid_2;

	dedupe_preprocess_pkg.PreprocessCompany(v_existing_company_sid_2);
	
	--2nd
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Mindtree UK',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_3
	);

	UPDATE company
	   SET email = 'j@uk2.com'
	 WHERE company_sid = v_existing_company_sid_3;

	dedupe_preprocess_pkg.PreprocessCompany(v_existing_company_sid_3);

	--set the company context and send a request for a new company
	security_pkg.SetContext('CHAIN_COMPANY', chain.helper_pkg.GetTopCompanySid);

	--the supplier requests a new site
	company_pkg.RequestNewCompany(
		in_name					=> 'test name',
		in_country_code			=> 'er',
		in_company_type_id		=> v_site_company_type_id,
		in_email				=>'a@ul.com',
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);
	
	v_expected_matched_sids.delete;
	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	csr.unit_test_pkg.AssertAreEqual(0, v_pend_request_creatd, 'Expected a pending request for a new company');
	csr.unit_test_pkg.AssertAreEqual(1, v_can_create_unique, '"Can create a unique company" was expected to be empty');

	--same scenario for a company request made by a supplier:
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Toothpicks Vendor',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_logged_in_company
	);

	security_pkg.SetContext('CHAIN_COMPANY', v_logged_in_company);

	--the supplier requests a new site
	company_pkg.RequestNewCompany(
		in_name					=> 'Some random name 2',
		in_country_code			=> 'it',
		in_company_type_id		=> v_site_company_type_id,
		in_email				=> 'abc@ul.com',
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	--clear context
	security_pkg.SetContext('CHAIN_COMPANY', NULL);
END;

PROCEDURE TestBlackListedEmail
AS
	v_existing_company_sid_1	NUMBER;
	v_existing_company_sid_2	NUMBER;
	v_existing_company_sid_3	NUMBER;
	v_logged_in_company			NUMBER;
	v_new_company_email			VARCHAR2(255);

	v_company_sid				security_pkg.T_SID_ID;
	v_pend_request_creatd		NUMBER;
	v_can_create_unique			NUMBER;
	v_matched_sids				security_pkg.T_SID_IDS;
	v_expected_matched_sids		security_pkg.T_SID_IDS;

	v_mapping_email_addr_id		NUMBER;

	v_dedupe_rule_set_id		NUMBER;
	v_mapping_ids				security_pkg.T_SID_IDS;
	v_rule_ids					security_pkg.T_SID_IDS;
	v_rule_type_ids				security_pkg.T_SID_IDS;
	v_match_thresholds			helper_pkg.T_NUMBER_ARRAY;
BEGIN
	ClearSystemRules;

	--setup some references
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> -1,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_EMAIL,
		out_dedupe_mapping_id		=> v_mapping_email_addr_id
	);

	v_mapping_ids(1) := v_mapping_email_addr_id;

	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_EXACT;

	v_match_thresholds(1) := 100;

	--Set rule sets
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_email_addr_id));

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> NULL,
		in_description				=> 'Exact match email',
		in_dedupe_staging_link_id	=> v_source_staging_link_id,
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);

	--setup some companies:
	--1st
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Histon florists site',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_1
	);

	UPDATE company
	   SET email = 'a@yahoo.com'
	 WHERE company_sid = v_existing_company_sid_1;

	dedupe_preprocess_pkg.PreprocessCompany(v_existing_company_sid_1);

	--2nd
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Cambs florists site',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_2
	);

	UPDATE company
	   SET email = 'b@yahoo.com'
	 WHERE company_sid = v_existing_company_sid_2;

	dedupe_preprocess_pkg.PreprocessCompany(v_existing_company_sid_2);
	
	--3rd no match
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Cambs butchers',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_3
	);

	UPDATE company
	   SET email = 'b@fahoo.com'
	 WHERE company_sid = v_existing_company_sid_3;

	dedupe_preprocess_pkg.PreprocessCompany(v_existing_company_sid_3);

	--set the company context and send a request for a new company
	security_pkg.SetContext('CHAIN_COMPANY', chain.helper_pkg.GetTopCompanySid);

	--the supplier requests a new site
	company_pkg.RequestNewCompany(
		in_name					=> 'Histn florists',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_site_company_type_id,
		in_email				=>'c@yahoo.com',
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	csr.unit_test_pkg.AssertAreEqual(0, v_matched_sids.COUNT, 'Expected no match for blacklisted domain.');
	
	company_pkg.RequestNewCompany(
		in_name					=> 'Histn florists',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_site_company_type_id,
		in_email				=>'c@fahoo.com',
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	csr.unit_test_pkg.AssertAreEqual(1, v_matched_sids.COUNT, 'Expected 1 for non blacklisted domain.');

	--clear context
	security_pkg.SetContext('CHAIN_COMPANY', NULL);
END;


PROCEDURE TestRequestExactMatchWebsite
AS
	v_existing_company_sid_1	NUMBER;
	v_existing_company_sid_2	NUMBER;
	v_existing_company_sid_3	NUMBER;
	v_logged_in_company			NUMBER;

	v_company_sid				security_pkg.T_SID_ID;
	v_pend_request_creatd		NUMBER;
	v_can_create_unique			NUMBER;
	v_matched_sids				security_pkg.T_SID_IDS;
	v_expected_matched_sids		security_pkg.T_SID_IDS;

	v_mapping_website_id		NUMBER;

	v_dedupe_rule_set_id		NUMBER;
	v_mapping_ids				security_pkg.T_SID_IDS;
	v_rule_ids					security_pkg.T_SID_IDS;
	v_rule_type_ids				security_pkg.T_SID_IDS;
	v_match_thresholds			helper_pkg.T_NUMBER_ARRAY;
BEGIN
	ClearSystemRules;

	--setup some references
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> -1,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_WEBSITE,
		out_dedupe_mapping_id		=> v_mapping_website_id
	);

	v_mapping_ids(1) := v_mapping_website_id;
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_EXACT;
	v_match_thresholds(1) := 100;

	--Set rule sets
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_website_id));

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> NULL,
		in_description				=> 'Website exact match',
		in_dedupe_staging_link_id	=> v_source_staging_link_id,
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);

	--setup some companies:
	--1st
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Histon florists site',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_1
	);

	UPDATE company
	   SET website = 'www.abcdef.com'
	 WHERE company_sid = v_existing_company_sid_1;

	--dedupe_preprocess_pkg.PreprocessCompany(v_existing_company_sid_1);

	--2nd
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Cambs florists site',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_2
	);

	UPDATE company
	   SET website = 'www.Abcdef.co.uk '
	 WHERE company_sid = v_existing_company_sid_2;

	--dedupe_preprocess_pkg.PreprocessCompany(v_existing_company_sid_2);
	
	--3rd no match
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Cambs butchers',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_3
	);

	UPDATE company
	   SET website = 'www.abcdefXXX.com'
	 WHERE company_sid = v_existing_company_sid_3;

	dedupe_preprocess_pkg.PreprocessCompany(v_existing_company_sid_3);

	--set the company context and send a request for a new company
	security_pkg.SetContext('CHAIN_COMPANY', chain.helper_pkg.GetTopCompanySid);

	--the supplier requests a new site
	company_pkg.RequestNewCompany(
		in_name					=> 'Histn florists',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_site_company_type_id,
		in_website				=>'http://www.abcdef.coM ',
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	csr.unit_test_pkg.AssertAreEqual(0, v_pend_request_creatd, 'Expected a pending request for a new company');
	csr.unit_test_pkg.AssertAreEqual(1, v_can_create_unique, '"Can create a unique company" was expected to be empty');

	--same scenario for a company request made by a supplier:
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Toothpicks Vendor',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_logged_in_company
	);

	security_pkg.SetContext('CHAIN_COMPANY', v_logged_in_company);

	--the supplier requests a new site
	company_pkg.RequestNewCompany(
		in_name					=> 'test random no',
		in_country_code			=> 'it',
		in_company_type_id		=> v_site_company_type_id,
		in_website				=> 'https://www2.abcdef.com',
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	--clear context
	security_pkg.SetContext('CHAIN_COMPANY', NULL);
END;


PROCEDURE TestRequestHttpWebsite
AS
	v_existing_company_sid_1	NUMBER;
	v_existing_company_sid_2	NUMBER;
	v_logged_in_company			NUMBER;

	v_company_sid				security_pkg.T_SID_ID;
	v_pend_request_creatd		NUMBER;
	v_can_create_unique			NUMBER;
	v_matched_sids				security_pkg.T_SID_IDS;
	v_expected_matched_sids		security_pkg.T_SID_IDS;
	v_pending_company_sid		NUMBER;

	v_mapping_id_website		NUMBER;

	v_dedupe_rule_set_id		NUMBER;
	v_mapping_ids				security_pkg.T_SID_IDS;
	v_rule_ids					security_pkg.T_SID_IDS;
	v_rule_type_ids				security_pkg.T_SID_IDS;
	v_match_thresholds			helper_pkg.T_NUMBER_ARRAY;
BEGIN
	ClearSystemRules;

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> -1,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_WEBSITE,
		out_dedupe_mapping_id		=> v_mapping_id_website
	);

	v_rule_ids(1) := 0;
	v_mapping_ids(1) := v_mapping_id_website;
	v_match_thresholds(1) := 50;
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_JAROWINKLER;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_description				=> 'Partial match website',
		in_dedupe_staging_link_id	=> v_source_staging_link_id,
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);

	--setup some companies:
	--1st
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company 1',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_1
	);

	UPDATE company
	   SET website = 'https://www.abcde.com'
	 WHERE company_sid = v_existing_company_sid_1;

	 --1st
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company 2',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_2
	);

	UPDATE company
	   SET website = 'https://www.abcdefg.com'
	 WHERE company_sid = v_existing_company_sid_2;

	--set the company context and send a request for a new company
	security_pkg.SetContext('CHAIN_COMPANY', v_existing_company_sid_2);

	--the supplier requests a new site
	company_pkg.RequestNewCompany(
		in_name					=> 'Company 3 x',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_site_company_type_id,
		in_website				=> 'http://www.abcde.com',
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	--set context to top company
	security_pkg.SetContext('CHAIN_COMPANY', chain.helper_pkg.GetTopCompanySid);

	csr.unit_test_pkg.AssertAreEqual(NULL, v_can_create_unique, '"Can create a unique company" was expected to be empty');

	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	--same scenario for a company request made by a supplier:
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Vendor company 1',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_logged_in_company
	);

	--set context to supplier company
	security_pkg.SetContext('CHAIN_COMPANY', v_logged_in_company);

	company_pkg.RequestNewCompany(
		in_name					=> 'Vendor company 2',
		in_country_code			=> 'it',
		in_company_type_id		=> v_vend_company_type_id,
		in_website				=> 'www.abcdef.co.uk',
		out_company_sid			=> v_pending_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	csr.unit_test_pkg.AssertAreEqual(NULL, v_can_create_unique, '"Can create a unique company" was expected to be empty');

	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	--clear context
	security_pkg.SetContext('CHAIN_COMPANY', NULL);
END;


PROCEDURE TestRequestRestriDomainSite
AS
	v_existing_company_sid_1	NUMBER;
	v_existing_company_sid_2	NUMBER;
	v_existing_company_sid_3	NUMBER;
	v_logged_in_company			NUMBER;

	v_company_sid				security_pkg.T_SID_ID;
	v_pend_request_creatd		NUMBER;
	v_can_create_unique			NUMBER;
	v_matched_sids				security_pkg.T_SID_IDS;
	v_expected_matched_sids		security_pkg.T_SID_IDS;
	v_pending_company_sid		NUMBER;

	v_mapping_id_website		NUMBER;

	v_dedupe_rule_set_id		NUMBER;
	v_mapping_ids				security_pkg.T_SID_IDS;
	v_rule_ids					security_pkg.T_SID_IDS;
	v_rule_type_ids				security_pkg.T_SID_IDS;
	v_match_thresholds			helper_pkg.T_NUMBER_ARRAY;
BEGIN
	ClearSystemRules;

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> -1,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_WEBSITE,
		out_dedupe_mapping_id		=> v_mapping_id_website
	);

	v_rule_ids(1) := 0;
	v_mapping_ids(1) := v_mapping_id_website;
	v_match_thresholds(1) := 100;
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_CONTAINS;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_description				=> 'Contains match company website',
		in_dedupe_staging_link_id	=> v_source_staging_link_id,
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);

	--setup some companies:
	--1st
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company 1',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_1
	);

	UPDATE company
	   SET website = 'https://www.abcdefghijk.co.uk'
	 WHERE company_sid = v_existing_company_sid_1;

	 --2nd
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company 2',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_2
	);

	UPDATE company
	   SET website = 'https://www.abcdefghi.com'
	 WHERE company_sid = v_existing_company_sid_2;
	 
	 --3rd no match
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company X',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_3
	);

	UPDATE company
	   SET website = 'https://www.abxxxxxxxx.com'
	 WHERE company_sid = v_existing_company_sid_3;

	--the supplier requests a new site
	company_pkg.RequestNewCompany(
		in_name					=> 'Company 3',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_site_company_type_id,
		in_website				=> 'https://www.abcdefgh.co.uk',
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	--set context to top company
	security_pkg.SetContext('CHAIN_COMPANY', chain.helper_pkg.GetTopCompanySid);

	csr.unit_test_pkg.AssertAreEqual(NULL, v_can_create_unique, '"Can create a unique company" was expected to be empty');

	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	--same scenario for a company request made by a supplier:
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Vendor company 1',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_logged_in_company
	);

	--set context to supplier company
	security_pkg.SetContext('CHAIN_COMPANY', v_logged_in_company);

	company_pkg.RequestNewCompany(
		in_name					=> 'Vendor company 2',
		in_country_code			=> 'it',
		in_company_type_id		=> v_vend_company_type_id,
		in_website				=> 'https://www.abcdefG.com',
		out_company_sid			=> v_pending_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	csr.unit_test_pkg.AssertAreEqual(NULL, v_can_create_unique, '"Can create a unique company" was expected to be empty');

	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	--clear context
	security_pkg.SetContext('CHAIN_COMPANY', NULL);
END;

PROCEDURE TestRequestPartMatchWebsite
AS
	v_existing_company_sid_1	NUMBER;
	v_existing_company_sid_2	NUMBER;
	v_existing_company_sid_3	NUMBER;
	v_logged_in_company			NUMBER;

	v_company_sid				security_pkg.T_SID_ID;
	v_pend_request_creatd		NUMBER;
	v_can_create_unique			NUMBER;
	v_matched_sids				security_pkg.T_SID_IDS;
	v_expected_matched_sids		security_pkg.T_SID_IDS;
	v_pending_company_sid		NUMBER;

	v_mapping_id_website		NUMBER;

	v_dedupe_rule_set_id		NUMBER;
	v_mapping_ids				security_pkg.T_SID_IDS;
	v_rule_ids					security_pkg.T_SID_IDS;
	v_rule_type_ids				security_pkg.T_SID_IDS;
	v_match_thresholds			helper_pkg.T_NUMBER_ARRAY;
BEGIN
	ClearSystemRules;

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> -1,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_WEBSITE,
		out_dedupe_mapping_id		=> v_mapping_id_website
	);

	v_rule_ids(1) := 0;
	v_mapping_ids(1) := v_mapping_id_website;
	v_match_thresholds(1) := 40;
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_LEVENSHTEIN;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_description				=> 'Partial Jarowinkler match company website',
		in_dedupe_staging_link_id	=> v_source_staging_link_id,
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);

	--setup some companies:
	--1st
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company 1',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_1
	);

	UPDATE company
	   SET website = 'https://www.abcdefghijk.co.in'
	 WHERE company_sid = v_existing_company_sid_1;
	 
	--2nd
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company 2x',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_2
	);

	UPDATE company
	   SET website = 'https://www.abcdefghixx.co.uk'
	 WHERE company_sid = v_existing_company_sid_2;
	 
	--3rd no match
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company 3x',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_3
	);

	UPDATE company
	   SET website = 'https://www.absdwweewexx.co.uk'
	 WHERE company_sid = v_existing_company_sid_3;

	--set the company context and send a request for a new company
	security_pkg.SetContext('CHAIN_COMPANY', v_existing_company_sid_1);

	--the supplier requests a new site
	company_pkg.RequestNewCompany(
		in_name					=> 'Company 3',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_site_company_type_id,
		in_website				=> 'https://www.abcdefgh.co.in',
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	--set context to top company
	security_pkg.SetContext('CHAIN_COMPANY', chain.helper_pkg.GetTopCompanySid);

	csr.unit_test_pkg.AssertAreEqual(NULL, v_can_create_unique, '"Can create a unique company" was expected to be empty');

	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	--same scenario for a company request made by a supplier:
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Vendor company 1',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_logged_in_company
	);

	--set context to supplier company
	security_pkg.SetContext('CHAIN_COMPANY', v_logged_in_company);

	company_pkg.RequestNewCompany(
		in_name					=> 'Vendor company 2',
		in_country_code			=> 'it',
		in_company_type_id		=> v_vend_company_type_id,
		in_website				=> 'https://www.abcdefghi.com',
		out_company_sid			=> v_pending_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	csr.unit_test_pkg.AssertAreEqual(NULL, v_can_create_unique, '"Can create a unique company" was expected to be empty');

	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	--clear context
	security_pkg.SetContext('CHAIN_COMPANY', NULL);
END;

PROCEDURE TestRequestExactMatchPhone
AS
	v_existing_company_sid_1	NUMBER;
	v_existing_company_sid_2	NUMBER;
	v_existing_company_sid_3	NUMBER;

	v_company_sid				security_pkg.T_SID_ID;
	v_pend_request_creatd		NUMBER;
	v_can_create_unique			NUMBER;
	v_matched_sids				security_pkg.T_SID_IDS;
	v_expected_matched_sids		security_pkg.T_SID_IDS;

	v_mapping_id_country_phone	NUMBER;

	v_dedupe_rule_set_id		NUMBER;
	v_mapping_ids				security_pkg.T_SID_IDS;
	v_rule_ids					security_pkg.T_SID_IDS;
	v_rule_type_ids				security_pkg.T_SID_IDS;
	v_match_thresholds			helper_pkg.T_NUMBER_ARRAY;
BEGIN
	ClearSystemRules;

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> -1,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_PHONE,
		out_dedupe_mapping_id		=> v_mapping_id_country_phone
	);

	v_mapping_ids(1) := v_mapping_id_country_phone;
	v_match_thresholds(1) := 100;
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_EXACT;
	v_rule_ids(1) := 0;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_description				=> 'Exact match company phone rule',
		in_dedupe_staging_link_id	=> v_source_staging_link_id,
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);

	--setup some companies:
	--1st
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company 1',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_1
	);

	UPDATE company
	   SET phone = '9999888822'
	 WHERE company_sid = v_existing_company_sid_1;
	 
	--2nd
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company 2x',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_2
	);

	UPDATE company
	   SET phone = '+999.9888-822'
	 WHERE company_sid = v_existing_company_sid_2;
	 
	--3rd no match
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company 3x',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_3
	);

	UPDATE company
	   SET phone = '+9199888822'
	 WHERE company_sid = v_existing_company_sid_3;

	--the supplier requests a new site
	company_pkg.RequestNewCompany(
		in_name					=> 'Company 2',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_site_company_type_id,
		in_phone				=> '9999888822', -- Exact match phone number
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	--set context to top company
	security_pkg.SetContext('CHAIN_COMPANY', chain.helper_pkg.GetTopCompanySid);

	csr.unit_test_pkg.AssertAreEqual(1, v_pend_request_creatd, 'Expected a pending request for a new company');
	csr.unit_test_pkg.AssertAreEqual(NULL, v_can_create_unique, '"Can create a unique company" was expected to be empty');

	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	--clear context
	security_pkg.SetContext('CHAIN_COMPANY', NULL);
END;

PROCEDURE TestRequestPartMatchPhone
AS
	v_existing_company_sid_1	NUMBER;
	v_existing_company_sid_2	NUMBER;
	v_existing_company_sid_3	NUMBER;
	v_logged_in_company			NUMBER;

	v_company_sid				security_pkg.T_SID_ID;
	v_pend_request_creatd		NUMBER;
	v_can_create_unique			NUMBER;
	v_matched_sids				security_pkg.T_SID_IDS;
	v_expected_matched_sids		security_pkg.T_SID_IDS;
	v_pending_company_sid		NUMBER;

	v_mapping_id_country_phone	NUMBER;

	v_dedupe_rule_set_id		NUMBER;
	v_mapping_ids				security_pkg.T_SID_IDS;
	v_rule_ids					security_pkg.T_SID_IDS;
	v_rule_type_ids				security_pkg.T_SID_IDS;
	v_match_thresholds			helper_pkg.T_NUMBER_ARRAY;
BEGIN
	ClearSystemRules;

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> -1,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_PHONE,
		out_dedupe_mapping_id		=> v_mapping_id_country_phone
	);

	v_rule_ids(1) := 0;
	v_mapping_ids(1) := v_mapping_id_country_phone;
	v_match_thresholds(1) := 50;
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_LEVENSHTEIN;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_description				=> 'Partial match company phone rule',
		in_dedupe_staging_link_id	=> v_source_staging_link_id,
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);

	--setup some companies:
	--1st
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company 1',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_1
	);

	UPDATE company
	   SET phone = '9999888822'
	 WHERE company_sid = v_existing_company_sid_1;

	 --setup some companies:
	--2nd
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company 2',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_2
	);

	UPDATE company
	   SET phone = 'tel: 0099998-88834'
	 WHERE company_sid = v_existing_company_sid_2;
	 
	--3rd no match
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company 3x',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_3
	);

	UPDATE company
	   SET phone = '4449482234'
	 WHERE company_sid = v_existing_company_sid_3;

	--set the company context and send a request for a new company
	security_pkg.SetContext('CHAIN_COMPANY', v_existing_company_sid_2);

	--the supplier requests a new site
	company_pkg.RequestNewCompany(
		in_name					=> 'Company 3',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_site_company_type_id,
		in_phone				=> '9999888 ', -- Partial match phone number with 50%
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	--set context to top company
	security_pkg.SetContext('CHAIN_COMPANY', chain.helper_pkg.GetTopCompanySid);

	csr.unit_test_pkg.AssertAreEqual(NULL, v_can_create_unique, '"Can create a unique company" was expected to be empty');

	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	--same scenario for a company request made by a supplier:
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Vendor company 1',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_logged_in_company
	);

	--set context to supplier company
	security_pkg.SetContext('CHAIN_COMPANY', v_logged_in_company);

	company_pkg.RequestNewCompany(
		in_name					=> 'Vendor company 2',
		in_country_code			=> 'it',
		in_company_type_id		=> v_vend_company_type_id,
		in_phone				=> ' 999888',
		out_company_sid			=> v_pending_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	csr.unit_test_pkg.AssertAreEqual(NULL, v_can_create_unique, '"Can create a unique company" was expected to be empty');

	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	--clear context
	security_pkg.SetContext('CHAIN_COMPANY', NULL);
END;

PROCEDURE TestRequestNonNumericPhone
AS
	v_existing_company_sid_1	NUMBER;
	v_logged_in_company			NUMBER;

	v_company_sid				security_pkg.T_SID_ID;
	v_pend_request_creatd		NUMBER;
	v_can_create_unique			NUMBER;
	v_matched_sids				security_pkg.T_SID_IDS;
	v_expected_matched_sids		security_pkg.T_SID_IDS;
	v_pending_company_sid		NUMBER;

	v_mapping_id_country_phone	NUMBER;

	v_dedupe_rule_set_id		NUMBER;
	v_mapping_ids				security_pkg.T_SID_IDS;
	v_rule_ids					security_pkg.T_SID_IDS;
	v_rule_type_ids				security_pkg.T_SID_IDS;
	v_match_thresholds			helper_pkg.T_NUMBER_ARRAY;
BEGIN
	ClearSystemRules;

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> -1,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_PHONE,
		out_dedupe_mapping_id		=> v_mapping_id_country_phone
	);

	v_rule_ids(1) := 0;
	v_mapping_ids(1) := v_mapping_id_country_phone;
	v_match_thresholds(1) := 100;
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_CONTAINS;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_description				=> 'Contains match company phone rule',
		in_dedupe_staging_link_id	=> v_source_staging_link_id,
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);

	--setup some companies:
	--1st
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company 1',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_1
	);

	UPDATE company
	   SET phone = '123-123-8475'
	 WHERE company_sid = v_existing_company_sid_1;

	--set the company context and send a request for a new company
	security_pkg.SetContext('CHAIN_COMPANY', v_existing_company_sid_1);

	--the supplier requests a new site
	company_pkg.RequestNewCompany(
		in_name					=> 'Company 2',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_site_company_type_id,
		in_phone				=> ' 123-1238475', -- Non-numeric character
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	--set context to top company
	security_pkg.SetContext('CHAIN_COMPANY', chain.helper_pkg.GetTopCompanySid);

	csr.unit_test_pkg.AssertAreEqual(NULL, v_can_create_unique, '"Can create a unique company" was expected to be empty');

	v_expected_matched_sids(1) := v_existing_company_sid_1;

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	--same scenario for a company request made by a supplier:
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Vendor company 1',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_logged_in_company
	);

	--set context to supplier company
	security_pkg.SetContext('CHAIN_COMPANY', v_logged_in_company);

	company_pkg.RequestNewCompany(
		in_name					=> 'Vendor company 2',
		in_country_code			=> 'it',
		in_company_type_id		=> v_vend_company_type_id,
		in_phone				=> '+12312384',
		out_company_sid			=> v_pending_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	csr.unit_test_pkg.AssertAreEqual(NULL, v_can_create_unique, '"Can create a unique company" was expected to be empty');

	v_expected_matched_sids(1) := v_existing_company_sid_1;

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	--clear context
	security_pkg.SetContext('CHAIN_COMPANY', NULL);
END;

PROCEDURE TestRequestContainsPhone
AS
	v_existing_company_sid_1	NUMBER;
	v_existing_company_sid_2	NUMBER;
	v_existing_company_sid_3	NUMBER;
	v_logged_in_company			NUMBER;

	v_company_sid				security_pkg.T_SID_ID;
	v_pend_request_creatd		NUMBER;
	v_can_create_unique			NUMBER;
	v_matched_sids				security_pkg.T_SID_IDS;
	v_expected_matched_sids		security_pkg.T_SID_IDS;
	v_pending_company_sid		NUMBER;

	v_mapping_id_country_phone	NUMBER;

	v_dedupe_rule_set_id		NUMBER;
	v_mapping_ids				security_pkg.T_SID_IDS;
	v_rule_ids					security_pkg.T_SID_IDS;
	v_rule_type_ids				security_pkg.T_SID_IDS;
	v_match_thresholds			helper_pkg.T_NUMBER_ARRAY;
BEGIN
	ClearSystemRules;

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id		=> -1,
		in_dedupe_staging_link_id 	=> v_source_staging_link_id,
		in_tab_sid 					=> NULL,
		in_col_sid 					=> NULL,
		in_dedupe_field_id 			=> chain_pkg.FLD_COMPANY_PHONE,
		out_dedupe_mapping_id		=> v_mapping_id_country_phone
	);

	v_rule_ids(1) := 0;
	v_mapping_ids(1) := v_mapping_id_country_phone;
	v_match_thresholds(1) := 100;
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_CONTAINS;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_description				=> 'Partial match with non-numeric company phone rule',
		in_dedupe_staging_link_id	=> v_source_staging_link_id,
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);

	--setup some companies:
	--1st
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company 1',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_1
	);

	UPDATE company
	   SET phone = '1231 23-8475 '
	 WHERE company_sid = v_existing_company_sid_1;
	 
	-- 2nd
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company 2x',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_2
	);

	UPDATE company
	   SET phone = 'tel: 123 ' -- TO DO - dangerous - raise as "min length for contains" feature to ed
	 WHERE company_sid = v_existing_company_sid_2;
	 
	-- 3rd
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Company 3x',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_site_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_existing_company_sid_3
	);

	UPDATE company
	   SET phone = 'tel: 99 99 22 22 '
	 WHERE company_sid = v_existing_company_sid_3;

	--the supplier requests a new site
	company_pkg.RequestNewCompany(
		in_name					=> 'Company 2',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_site_company_type_id,
		in_phone				=> ' 1231-238475 ', -- Non-numeric character
		out_company_sid			=> v_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	csr.unit_test_pkg.AssertAreEqual(NULL, v_can_create_unique, '"Can create a unique company" was expected to be empty');

	v_expected_matched_sids(1) := v_existing_company_sid_1;
	v_expected_matched_sids(2) := v_existing_company_sid_2;

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	--same scenario for a company request made by a supplier:
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name				=> 'Vendor company 1',
		in_country_code		=> 'gb',
		in_company_type_id	=> v_vend_company_type_id,
		in_sector_id		=> NULL,
		out_company_sid		=> v_logged_in_company
	);

	--set context to supplier company
	security_pkg.SetContext('CHAIN_COMPANY', v_logged_in_company);

	company_pkg.RequestNewCompany(
		in_name					=> 'Vendor company 2',
		in_country_code			=> 'it',
		in_company_type_id		=> v_vend_company_type_id,
		in_phone				=> '123123847',
		out_company_sid			=> v_pending_company_sid,
		out_pend_request_creatd => v_pend_request_creatd,
		out_can_create_unique	=> v_can_create_unique,
		out_matched_sids		=> v_matched_sids
	);

	csr.unit_test_pkg.AssertAreEqual(NULL, v_can_create_unique, '"Can create a unique company" was expected to be empty');

	v_expected_matched_sids(1) := v_existing_company_sid_1;

	AssertMatches(
		in_expected_matched_sids	=> v_expected_matched_sids,
		in_returned_matched_sids	=> v_matched_sids
	);

	--clear context
	security_pkg.SetContext('CHAIN_COMPANY', NULL);
END;

END test_dedupe_pending_pkg;
/
