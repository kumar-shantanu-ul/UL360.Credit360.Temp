CREATE OR REPLACE PACKAGE BODY chain.test_dedupe_partial_pkg AS

v_site_name						VARCHAR2(200);
v_source_id						NUMBER;
v_tab_sid						NUMBER;
v_reference_id					NUMBER;
v_staging_link_id				NUMBER;
v_tag_group_id					NUMBER;
v_mapping_name_id				NUMBER;
v_mapping_postcode_id			NUMBER;
v_mapping_address_id			NUMBER;
v_mapping_country_id			NUMBER;
v_supplier_company_type_id		NUMBER;
v_dedupe_rule_set_id_1			NUMBER;
v_name_post_addr_rule_set_id	NUMBER;
v_expected_company_sids			T_NUMBER_LIST;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_dedupe_field_ids			security_pkg.T_SID_IDS;
	v_countries					security_pkg.T_VARCHAR2_ARRAY;
	v_dedupe_preproc_rule_id	NUMBER;
	v_company_type_ids			helper_pkg.T_NUMBER_ARRAY;
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);

	test_chain_utils_pkg.SetupSingleTier;

	v_supplier_company_type_id := company_type_pkg.GetCompanyTypeId('SUPPLIER');
	v_company_type_ids(1) := v_supplier_company_type_id;

	--setup preprocess rules
	UPDATE customer_options
	   SET enable_dedupe_preprocess = 1
	 WHERE app_sid = security_pkg.getapp;

	--e accented to e
	dedupe_admin_pkg.SavePreProcRule(
		in_dedupe_preproc_rule_id 	=> NULL,
		in_pattern					=> chr(50089), --e accented
		in_replacement				=> 'e',
		in_run_order				=> 1,
		in_dedupe_field_ids			=> v_dedupe_field_ids,
		in_countries				=> v_countries,
		out_dedupe_preproc_rule_id	=> v_dedupe_preproc_rule_id
	);

	--remove '-()*'
	dedupe_admin_pkg.SavePreProcRule(
		in_dedupe_preproc_rule_id 	=> NULL,
		in_pattern					=> '[*\(\)\-]', --replaces *()- with ' '
		in_replacement				=> ' ',
		in_run_order				=> 2,
		in_dedupe_field_ids			=> v_dedupe_field_ids,
		in_countries				=> v_countries,
		out_dedupe_preproc_rule_id	=> v_dedupe_preproc_rule_id
	);

	--remove extra spaces
	dedupe_admin_pkg.SavePreProcRule(
		in_dedupe_preproc_rule_id 	=> NULL,
		in_pattern					=> '[[:space:]]+',
		in_replacement				=> ' ',
		in_run_order				=> 3,
		in_dedupe_field_ids			=> v_dedupe_field_ids,
		in_countries				=> v_countries,
		out_dedupe_preproc_rule_id	=> v_dedupe_preproc_rule_id
	);

	helper_pkg.SaveReferenceLabel(
		in_reference_id	=> NULL,
		in_lookup_key => 'COMPANY_ID_REF',
		in_label => 'Company import id',
		in_mandatory => 0,
		in_reference_uniqueness_id => 2, /* Global */
		in_reference_location_id => 0, /* Show on the company details card */
		in_company_type_ids	=> v_company_type_ids,
		out_reference_id => v_reference_id
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
	--do noth
	NULL;
END;

PROCEDURE TearDown
AS
BEGIN
	--clear dedupe setup + dedupe results + chain supplier companies + staging table
	FOR r IN (
		SELECT lookup_key
		  FROM import_source
		 WHERE app_sid = security_pkg.getapp
		   AND is_owned_by_system = 0
	)
	LOOP
		test_chain_utils_pkg.TearDownImportSource(r.lookup_key);
	END LOOP;

	--Move UI system managed source back to its original position
	UPDATE import_source
	   SET position = 0
	 WHERE is_owned_by_system = 1;

	test_chain_utils_pkg.DeleteFullyCompaniesOfType('SUPPLIER');

	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.company_staging';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;
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

	DELETE FROM reference_company_type
	 WHERE reference_id IN (
		SELECT reference_id
		  FROM reference
		 WHERE lookup_key IN ('COMPANY_ID_REF')
	 );

	DELETE FROM reference
	 WHERE lookup_key IN ('COMPANY_ID_REF');

	FOR r IN (
		SELECT tag_group_id
		  FROM csr.tag_group
		 WHERE lookup_key IN ('FACILITY_TYPE')
	)
	LOOP
		csr.tag_pkg.DeleteTagGroup(
			in_act_id			=> security_pkg.GetAct,
			in_tag_group_id		=> r.tag_group_id
		);
	END LOOP;

	test_chain_utils_pkg.TearDownSingleTier;
END;

-- private
PROCEDURE AddStagingRow(
	in_vendor_num		IN VARCHAR2,
	in_vendor_name		IN VARCHAR2,
	in_city				IN VARCHAR2,
	in_country			IN VARCHAR2,
	in_postal_code		IN VARCHAR2,
	in_street			IN VARCHAR2,
	in_state			IN VARCHAR2,
	in_website			IN VARCHAR2,
	in_facility_type	IN VARCHAR2,
	in_email			IN VARCHAR DEFAULT NULL,
	in_address_1 		IN VARCHAR2 DEFAULT NULL,
	in_address_2 		IN VARCHAR2 DEFAULT NULL,
	in_address_3 		IN VARCHAR2 DEFAULT NULL,
	in_address_4 		IN VARCHAR2 DEFAULT NULL
)
AS
BEGIN
	EXECUTE IMMEDIATE ('
		INSERT INTO rag.company_staging(
			company_staging_id,
			vendor_num,
			vendor_name,
			city,
			postal_code,
			street,
			country,
			state,
			website,
			facility_type,
			email,
			address_1,
			address_2,
			address_3,
			address_4
		)
		VALUES(
			cms.item_id_seq.nextval,
			:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13,:14
		)'
	)
	USING in_vendor_num, in_vendor_name, in_city, in_postal_code, in_street,
	in_country, in_state, in_website, in_facility_type, in_email, in_address_1, in_address_2, in_address_3, in_address_4;
END;

PROCEDURE SaveImportSource(
	in_no_match_action_id		NUMBER
)
AS
BEGIN
	dedupe_admin_pkg.SaveImportSource(
		in_import_source_id => -1,
		in_name => 'Company integration',
		in_position => 1,
		in_no_match_action_id => in_no_match_action_id,
		in_lookup_key => 'COMPANY_DATA',
		out_import_source_id => v_source_id
	);
END;

PROCEDURE SetupSourceLinkAndMappings1
AS
	v_mapping_id					NUMBER;
	v_mapping_ref_id				NUMBER;
BEGIN
	v_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'COMPANY_STAGING');

	--set up staging link
	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id,
		in_description 					=> 'Company data integration',
		in_staging_tab_sid 				=> v_tab_sid,
		in_position 					=> 1,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'VENDOR_NUM'),
		in_staging_batch_num_col_sid 	=> NULL,
		in_parent_staging_link_id 		=> NULL,
		in_destination_tab_sid 			=> NULL,
		out_dedupe_staging_link_id 		=> v_staging_link_id
	);

	--setup mappings
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'VENDOR_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_NAME,
		out_dedupe_mapping_id => v_mapping_name_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'CITY'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_CITY,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'POSTAL_CODE'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_POSTCODE,
		out_dedupe_mapping_id => v_mapping_postcode_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'STREET'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_ADDRESS,
		out_dedupe_mapping_id => v_mapping_address_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'COUNTRY'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id => v_mapping_country_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'STATE'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_STATE,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'WEBSITE'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_WEBSITE,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'FACILITY_TYPE'),
		in_tag_group_id	=> v_tag_group_id,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'EMAIL'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_EMAIL,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'VENDOR_NUM'),
		in_reference_id => v_reference_id,
		out_dedupe_mapping_id => v_mapping_ref_id
	);
END;


PROCEDURE SavePartialNameCntryPstRuleSet
AS
	v_mapping_ids					security.security_pkg.T_SID_IDS;
	v_rule_ids						security.security_pkg.T_SID_IDS;
	v_rule_type_ids					security.security_pkg.T_SID_IDS;
	v_match_thresholds				helper_pkg.T_NUMBER_ARRAY;
BEGIN
		--Set rule sets
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_name_id, v_mapping_postcode_id, v_mapping_country_id));

	--need arrays of dedupe_rule_id and thresholds
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_LEVENSHTEIN;
	v_rule_type_ids(2) := chain_pkg.RULE_TYPE_EXACT;
	v_rule_type_ids(3) := chain_pkg.RULE_TYPE_EXACT;

	v_match_thresholds(1) := 60;
	v_match_thresholds(2) := 100;
	v_match_thresholds(3) := 100;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id,
		in_description				=> 'Partial name and exact postcode and country rule set',
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id_1
	);
END;

PROCEDURE SavePartNameCntryPstAddRuleSet(
	in_dedupe_match_type_id 		NUMBER
)
AS
	v_mapping_ids					security.security_pkg.T_SID_IDS;
	v_rule_ids						security.security_pkg.T_SID_IDS;
	v_rule_type_ids					security.security_pkg.T_SID_IDS;
	v_match_thresholds				helper_pkg.T_NUMBER_ARRAY;
BEGIN
	--Set rule sets
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_name_id, v_mapping_postcode_id, v_mapping_country_id, v_mapping_address_id));

	--need arrays of dedupe_rule_id and thresholds
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_LEVENSHTEIN;
	v_rule_type_ids(2) := chain_pkg.RULE_TYPE_EXACT;
	v_rule_type_ids(3) := chain_pkg.RULE_TYPE_EXACT;
	v_rule_type_ids(4) := chain_pkg.RULE_TYPE_JAROWINKLER;

	v_match_thresholds(1) := 60;
	v_match_thresholds(2) := 100;
	v_match_thresholds(3) := 100;
	v_match_thresholds(4) := 60;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id,
		in_description				=> 'Partial name, address and exact postcode and country rule set',
		in_dedupe_match_type_id		=> in_dedupe_match_type_id,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id_1
	);
END;

PROCEDURE SaveAddressContainsRuleSet(
	in_dedupe_match_type_id 	NUMBER
)
AS
	v_mapping_ids					security.security_pkg.T_SID_IDS;
	v_rule_ids						security.security_pkg.T_SID_IDS;
	v_rule_type_ids					security.security_pkg.T_SID_IDS;
	v_match_thresholds				helper_pkg.T_NUMBER_ARRAY;
BEGIN
	--Set rule sets
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_address_id));

	--need arrays of dedupe_rule_id and thresholds
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_CONTAINS;
	v_match_thresholds(1) := 100;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id,
		in_description				=> 'Contains address rule set',
		in_dedupe_match_type_id		=> in_dedupe_match_type_id,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id_1
	);
END;

PROCEDURE SaveNamePostRuleSet(
	in_threshold_1		NUMBER DEFAULT 60,
	in_threshold_2		NUMBER DEFAULT 88,
	in_rule_type_id_1	NUMBER DEFAULT chain_pkg.RULE_TYPE_LEVENSHTEIN,
	in_rule_type_id_2	NUMBER DEFAULT chain_pkg.RULE_TYPE_LEVENSHTEIN,
	in_match_type_id	NUMBER DEFAULT chain_pkg.DEDUPE_AUTO
)
AS
	v_mapping_ids					security.security_pkg.T_SID_IDS;
	v_rule_ids						security.security_pkg.T_SID_IDS;
	v_rule_type_ids					security.security_pkg.T_SID_IDS;
	v_match_thresholds				helper_pkg.T_NUMBER_ARRAY;
BEGIN
		--Set rule sets
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_name_id, v_mapping_postcode_id));

	--need arrays of dedupe_rule_id and thresholds
	v_rule_type_ids(1) := in_rule_type_id_1;
	v_rule_type_ids(2) := in_rule_type_id_2;

	v_match_thresholds(1) := in_threshold_1;
	v_match_thresholds(2) := in_threshold_2;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id,
		in_description				=> 'Name and postcode rule set',
		in_dedupe_match_type_id		=> in_match_type_id,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id_1
	);
END;

PROCEDURE SaveNamePostAddressRuleSet(
	in_threshold_1		NUMBER DEFAULT 100,
	in_threshold_2		NUMBER DEFAULT 100,
	in_threshold_3		NUMBER DEFAULT 100,
	in_rule_type_id_1	NUMBER DEFAULT chain_pkg.RULE_TYPE_CONTAINS,
	in_rule_type_id_2	NUMBER DEFAULT chain_pkg.RULE_TYPE_EXACT,
	in_rule_type_id_3	NUMBER DEFAULT chain_pkg.RULE_TYPE_EXACT,
	in_match_type_id	NUMBER DEFAULT chain_pkg.DEDUPE_AUTO
)
AS
	v_mapping_ids					security.security_pkg.T_SID_IDS;
	v_rule_ids						security.security_pkg.T_SID_IDS;
	v_rule_type_ids					security.security_pkg.T_SID_IDS;
	v_match_thresholds				helper_pkg.T_NUMBER_ARRAY;
BEGIN
		--Set rule sets
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_name_id, v_mapping_postcode_id, v_mapping_address_id));

	--need arrays of dedupe_rule_id and thresholds
	v_rule_type_ids(1) := in_rule_type_id_1;
	v_rule_type_ids(2) := in_rule_type_id_2;
	v_rule_type_ids(3) := in_rule_type_id_3;

	v_match_thresholds(1) := in_threshold_1;
	v_match_thresholds(2) := in_threshold_2;
	v_match_thresholds(3) := in_threshold_3;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id,
		in_description				=> 'Name, postcode and address rule set',
		in_dedupe_match_type_id		=> in_match_type_id,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_name_post_addr_rule_set_id
	);
END;

PROCEDURE SaveOneMatchAutoRuleSet
AS
	v_mapping_ids					security.security_pkg.T_SID_IDS;
	v_rule_ids						security.security_pkg.T_SID_IDS;
	v_rule_type_ids					security.security_pkg.T_SID_IDS;
	v_match_thresholds				helper_pkg.T_NUMBER_ARRAY;
BEGIN
		--Set rule sets
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_name_id, v_mapping_postcode_id));

	--need arrays of dedupe_rule_id and thresholds
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_LEVENSHTEIN;
	v_rule_type_ids(2) := chain_pkg.RULE_TYPE_EXACT;

	v_match_thresholds(1) := 80;
	v_match_thresholds(2) := 100;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id,
		in_description				=> 'Partial name and exact post code rule set',
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_AUTO,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id_1
	);
END;

PROCEDURE SaveOneMatchManualRuleSet
AS
	v_mapping_ids					security.security_pkg.T_SID_IDS;
	v_rule_ids						security.security_pkg.T_SID_IDS;
	v_rule_type_ids					security.security_pkg.T_SID_IDS;
	v_match_thresholds				helper_pkg.T_NUMBER_ARRAY;
BEGIN
		--Set rule sets
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_name_id, v_mapping_postcode_id));

	--need arrays of dedupe_rule_id and thresholds
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_LEVENSHTEIN;
	v_rule_type_ids(2) := chain_pkg.RULE_TYPE_EXACT;

	v_match_thresholds(1) := 80;
	v_match_thresholds(2) := 100;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id,
		in_description				=> 'Partial name and exact post code rule set',
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id_1
	);
END;

PROCEDURE SetupChainTestData1
AS
	v_tag_id		NUMBER;
BEGIN

	csr.tag_pkg.SetTagGroup(
		in_tag_group_id			=> NULL,
		in_name					=> 'Facility type',
		in_multi_select			=> 1,
		in_applies_to_regions	=> 1,
		in_applies_to_suppliers	=> 1,
		in_applies_to_chain		=> 1,
		in_lookup_key			=> 'FACILITY_TYPE',
		out_tag_group_id		=> v_tag_group_id
	);

	csr.tag_pkg.SetTag(
		in_tag_group_id		=> v_tag_group_id,
		in_tag				=> 'Garage',
		in_lookup_key		=> 'GARAGE',
		out_tag_id			=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id		=> v_tag_group_id,
		in_tag				=> 'Store',
		in_lookup_key		=> 'STORE',
		out_tag_id			=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id		=> v_tag_group_id,
		in_tag				=> 'Press',
		in_lookup_key		=> 'PRESS',
		out_tag_id			=> v_tag_id
	);
END;

PROCEDURE TestNoMatchPromoted(
	in_processed_record_id		NUMBER
)
AS
	v_data_merged				NUMBER;
	v_created_company_sid		NUMBER;
	v_matched_to_company_sid	NUMBER;
BEGIN
	SELECT data_merged, created_company_sid, matched_to_company_sid
	  INTO v_data_merged, v_created_company_sid, v_matched_to_company_sid
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = in_processed_record_id;

	csr.unit_test_pkg.AssertAreEqual(NULL, v_matched_to_company_sid, 'Didn''t expect a matched company');
	csr.unit_test_pkg.AssertAreEqual(NULL, v_created_company_sid, 'Didn''t expect a new company');
	csr.unit_test_pkg.AssertAreEqual(0, v_data_merged, 'Didn'' expect a data merge');
END;

PROCEDURE TestMergedCompanyAddress(
	in_company_sid 		NUMBER,
	in_address_1 		VARCHAR2,
	in_address_2 		VARCHAR2,
	in_address_3 		VARCHAR2,
	in_address_4 		VARCHAR2
)
AS
	v_address_1 		VARCHAR2(255);
	v_address_2 		VARCHAR2(255);
	v_address_3 		VARCHAR2(255);
	v_address_4 		VARCHAR2(255);
BEGIN
	SELECT address_1, address_2, address_3, address_4
	  INTO v_address_1, v_address_2, v_address_3, v_address_4
	  FROM company
	 WHERE company_sid = in_company_sid;
/* 
	security.security_pkg.debugmsg('addr1: '||v_address_1||' -- '||in_address_1);
	security.security_pkg.debugmsg('addr2: '||v_address_2||' -- '||in_address_2);
	security.security_pkg.debugmsg('addr3: '||v_address_3||' -- '||in_address_3);
	security.security_pkg.debugmsg('addr4: '||v_address_4||' -- '||in_address_4); */

	csr.unit_test_pkg.AssertAreEqual(v_address_1, in_address_1, 'Merged address field 1 not equal! Expected: '||in_address_1||' got: '||v_address_1);
	csr.unit_test_pkg.AssertAreEqual(v_address_2, in_address_2, 'Merged address field 2 not equal! Expected: '||in_address_2||' got: '||v_address_2);
	csr.unit_test_pkg.AssertAreEqual(v_address_3, in_address_3, 'Merged address field 3 not equal! Expected: '||in_address_3||' got: '||v_address_3);
	csr.unit_test_pkg.AssertAreEqual(v_address_4, in_address_4, 'Merged address field 4 not equal! Expected: '||in_address_4||' got: '||v_address_4);
END;

PROCEDURE TestPotentialMatches(
	in_processed_record_id		NUMBER,
	in_expected_company_sids	T_NUMBER_LIST,
	in_rule_set_id				NUMBER DEFAULT NULL
)
AS
	v_count		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_match
	 WHERE dedupe_processed_record_id = in_processed_record_id
	   AND matched_to_company_sid NOT IN (
			SELECT column_value
			  FROM TABLE(in_expected_company_sids)
	   );

	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Wrong potential matches');

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_match
	 WHERE dedupe_processed_record_id = in_processed_record_id
	   AND matched_to_company_sid IN (
			SELECT column_value
			  FROM TABLE(in_expected_company_sids)
	   )
	   AND (in_rule_set_id IS NULL OR dedupe_rule_set_id = in_rule_set_id);

	csr.unit_test_pkg.AssertAreEqual(in_expected_company_sids.COUNT, v_count, 'Expected potential matches not found');
END;

--1st rule:
--company_name with threshold
--country exact
--postcode exact on normalised
PROCEDURE TestMatch_PartialNameCntryPost
AS
	v_processed_record_ids	security_pkg.T_SID_IDS;
	v_count					NUMBER;
	v_company_sid_1			NUMBER;
	v_company_sid_2			NUMBER;
	v_company_sid_3			NUMBER;
	v_company_sid_4			NUMBER;
	v_company_sid_5			NUMBER;
	v_company_sid_6			NUMBER;
	v_company_sid_7			NUMBER;
	v_company_sid_8			NUMBER;
	v_alt_comp_name_id		NUMBER;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	SetupChainTestData1;
	SaveImportSource(chain_pkg.DEDUPE_AUTO);
	SetupSourceLinkAndMappings1;
	SavePartialNameCntryPstRuleSet;

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'random', --partial match, 60%
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_1
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'entirely different name',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_2
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'other company random',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_3
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'random (inc)*', --exact match (brackets and asterisk will be stripped out)
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_4
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'random-inc2', --this would have been a partial match if it wasn't for the postcode
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_5
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'no match', --this will be partial match on alternative company name
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_6
	);

	v_alt_comp_name_id := alt_company_name_id_seq.nextval;
	company_pkg.savealtcompanyname(v_alt_comp_name_id, v_company_sid_6, 'not a single match');
	v_alt_comp_name_id := alt_company_name_id_seq.nextval;
	company_pkg.savealtcompanyname(v_alt_comp_name_id, v_company_sid_6, 'random i');

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'no match', --this would be partial match on alternative company name if not for country code
		in_country_code=> 'gb',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_7
	);

	v_alt_comp_name_id := alt_company_name_id_seq.nextval;
	company_pkg.savealtcompanyname(v_alt_comp_name_id, v_company_sid_7, 'random');

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'only match on alt company name', --this would be partial match on alternative company name if not for country code
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_8
	);

	v_alt_comp_name_id := alt_company_name_id_seq.nextval;
	company_pkg.savealtcompanyname(v_alt_comp_name_id, v_company_sid_8, 'random (inc)*');

	UPDATE company
	   SET postcode = 'RMO-982' --'-' will be replaced with empty space
	 WHERE company_sid IN (v_company_sid_1, v_company_sid_2, v_company_sid_3, v_company_sid_4, v_company_sid_6, v_company_sid_7, v_company_sid_8);

	UPDATE company
	   SET postcode = 'RM 982'
	 WHERE company_sid IN (v_company_sid_5);

	--process again for the postcode
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_1);
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_2);
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_3);
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_4);
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_5);
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_6);
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_7);
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_8);

	test_chain_shared_dedupe_pkg.AddStagingRow(
		in_vendor_num		=> '12345',
		in_vendor_name		=> 'Random inc',
		in_city				=> 'Roma',
		in_country			=> 'it',
		in_postal_code		=> 'rmo 982',
		in_street			=> 'Via Portuense',
		in_state			=> '',
		in_website			=> 'random-inc.com',
		in_facility_type	=> 'Press',
		in_email			=> 'info@random-inc.com'
	);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id,
		in_reference				=> '12345',
		out_processed_record_ids	=> v_processed_record_ids
	);

	--We configured the rule_set for manual merging so we don't expect any merges
	TestNoMatchPromoted(v_processed_record_ids(1));

	--but we expect some matches
	test_chain_shared_dedupe_pkg.TestPotentialMatches(
		v_processed_record_ids(1),
		T_NUMBER_LIST(v_company_sid_1, v_company_sid_4, v_company_sid_6, v_company_sid_8)
	);

	--#######
	--2nd run
	UPDATE dedupe_rule
	   SET dedupe_rule_type_id = chain_pkg.RULE_TYPE_EXACT,
		   match_threshold = 100
	 WHERE dedupe_rule_set_id = v_dedupe_rule_set_id_1
	   AND dedupe_mapping_id = v_mapping_name_id;

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id,
		in_reference				=> '12345',
		in_force_re_eval			=> 1,
		out_processed_record_ids	=> v_processed_record_ids
	);

	TestNoMatchPromoted(v_processed_record_ids(1));

	test_chain_shared_dedupe_pkg.TestPotentialMatches(
		v_processed_record_ids(1),
		T_NUMBER_LIST(v_company_sid_4, v_company_sid_8)
	);

END;

PROCEDURE SetupOneMatchAutoSource
AS
	v_mapping_id					NUMBER;
	v_mapping_ref_id				NUMBER;
	v_mapping_ids					security.security_pkg.T_SID_IDS;
	v_rule_ids						security.security_pkg.T_SID_IDS;
	v_rule_type_ids					security.security_pkg.T_SID_IDS;
	v_match_thresholds				helper_pkg.T_NUMBER_ARRAY;
	v_company_sid_1			NUMBER;
	v_company_sid_2			NUMBER;
	v_company_sid_3			NUMBER;
	v_company_sid_4			NUMBER;
	v_company_sid_5			NUMBER;
BEGIN
	SetupChainTestData1;
	SaveImportSource(chain_pkg.DEDUPE_AUTO);
	SetupSourceLinkAndMappings1;
	SaveOneMatchAutoRuleSet;

	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'random', --partial match
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_1
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'entirely different name',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_2
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'other company random',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_3
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'random (inc)*', --exact match (brackets and asterisk will be stripped out)
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_4
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'random-inc2', --this would have been a partial match if it wasn't for the postcode
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_5
	);

	UPDATE company
	   SET postcode = 'RMO-982'
	 WHERE company_sid IN (v_company_sid_1, v_company_sid_2, v_company_sid_3, v_company_sid_4);

	UPDATE company
	   SET postcode = 'RMO 982'
	 WHERE company_sid IN (v_company_sid_5);

	test_chain_shared_dedupe_pkg.AddStagingRow(
		in_vendor_num		=> '12345',
		in_vendor_name		=> 'Random inc',
		in_city				=> 'Roma',
		in_country			=> 'it',
		in_postal_code		=> 'rmo 982',
		in_street			=> 'Via Portuense',
		in_state			=> '',
		in_website			=> 'random-inc.com',
		in_facility_type	=> 'Press',
		in_email			=> 'info@random-inc.com'
	);
END;

PROCEDURE SetupOneMatchManualSource
AS
	v_mapping_id					NUMBER;
	v_mapping_ref_id				NUMBER;
	v_mapping_ids					security.security_pkg.T_SID_IDS;
	v_rule_ids						security.security_pkg.T_SID_IDS;
	v_rule_type_ids					security.security_pkg.T_SID_IDS;
	v_match_thresholds				helper_pkg.T_NUMBER_ARRAY;
	v_company_sid_1					NUMBER;
	v_company_sid_2					NUMBER;
	v_company_sid_3					NUMBER;
	v_company_sid_4					NUMBER;
	v_company_sid_5					NUMBER;
BEGIN
	SetupChainTestData1;
	SaveImportSource(chain_pkg.DEDUPE_AUTO);
	SetupSourceLinkAndMappings1;
	SaveOneMatchManualRuleSet;

	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'random', --partial match
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_1
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'entirely different name',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_2
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'other company random',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_3
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'random (inc)*', --exact match (brackets and asterisk will be stripped out)
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_4
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'random-inc2', --this would have been a partial match if it wasn't for the postcode
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_5
	);

	UPDATE company
	   SET postcode = 'RMO-982'
	 WHERE company_sid IN (v_company_sid_1, v_company_sid_2, v_company_sid_3, v_company_sid_4);

	UPDATE company
	   SET postcode = 'RMO 982'
	 WHERE company_sid IN (v_company_sid_5);

	test_chain_shared_dedupe_pkg.AddStagingRow(
		in_vendor_num		=> '12345',
		in_vendor_name		=> 'Random inc',
		in_city				=> 'Roma',
		in_country			=> 'it',
		in_postal_code		=> 'rmo 982',
		in_street			=> 'Via Portuense',
		in_state			=> '',
		in_website			=> 'random-inc.com',
		in_facility_type	=> 'Press',
		in_email			=> 'info@random-inc.com'
	);
END;

PROCEDURE TestOneMatchExpectOne(
	in_processed_record_id		NUMBER
)
AS
	v_count						NUMBER;
BEGIN

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_match
	 WHERE dedupe_processed_record_id = in_processed_record_id;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'More than one or no match found.');
END;

PROCEDURE TestNoMatchExpectNone(
	in_processed_record_id		NUMBER
)
AS
	v_count						NUMBER;
BEGIN

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_match
	 WHERE dedupe_processed_record_id = in_processed_record_id;

	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Matched record found, expected none.');
END;

PROCEDURE TestOneMatchAutoExpectMerged(
	in_processed_record_id		NUMBER
)
AS
	v_count						NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = in_processed_record_id
	   AND data_merged = 1
	   AND created_company_sid IS NULL
	   AND matched_to_company_sid IS NOT NULL;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'No merged record found, expected one.');
END;

PROCEDURE TestOneMatchManExpectNotMerged(
	in_processed_record_id		NUMBER
)
AS
	v_count						NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = in_processed_record_id
	   AND data_merged = 0
	   AND created_company_sid IS NULL
	   AND matched_to_company_sid IS NULL;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Didn''t expect a matched or merged company');
END;

PROCEDURE TestProcess_AutoRuleSet
AS
	v_processed_record_ids		security_pkg.T_SID_IDS;
BEGIN
	SetupOneMatchAutoSource;

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id,
		in_reference				=> '12345',
		out_processed_record_ids	=> v_processed_record_ids
	);

	TestOneMatchExpectOne(v_processed_record_ids(1));

	TestOneMatchAutoExpectMerged(v_processed_record_ids(1));
END;

PROCEDURE TestProcess_ManualRuleSet
AS
	v_processed_record_ids		security_pkg.T_SID_IDS;
BEGIN
	SetupOneMatchManualSource;

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id,
		in_reference				=> '12345',
		out_processed_record_ids	=> v_processed_record_ids
	);

	TestOneMatchExpectOne(v_processed_record_ids(1));
	TestOneMatchManExpectNotMerged(v_processed_record_ids(1));
END;

PROCEDURE SaveNoMatchRuleSet
AS
	v_mapping_ids					security.security_pkg.T_SID_IDS;
	v_rule_ids						security.security_pkg.T_SID_IDS;
	v_rule_type_ids					security.security_pkg.T_SID_IDS;
	v_match_thresholds				helper_pkg.T_NUMBER_ARRAY;
BEGIN
	--Set rule sets
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_name_id, v_mapping_postcode_id));

	--need arrays of dedupe_rule_id and thresholds
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_JAROWINKLER;
	v_rule_type_ids(2) := chain_pkg.RULE_TYPE_EXACT;

	v_match_thresholds(1) := 100;
	v_match_thresholds(2) := 100;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id,
		in_description				=> 'Partial name and exact post code rule set',
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id_1
	);
END;

PROCEDURE SetNoMatchSource(
	in_no_match_action_id			chain_pkg.T_DEDUPE_ACTION
)
AS
	v_mapping_id					NUMBER;
	v_mapping_ref_id				NUMBER;
	v_mapping_ids					security.security_pkg.T_SID_IDS;
	v_rule_ids						security.security_pkg.T_SID_IDS;
	v_rule_type_ids					security.security_pkg.T_SID_IDS;
	v_match_thresholds				helper_pkg.T_NUMBER_ARRAY;
	v_company_sid_1					NUMBER;
	v_company_sid_2					NUMBER;
	v_company_sid_3					NUMBER;
	v_company_sid_4					NUMBER;
	v_company_sid_5					NUMBER;
BEGIN
	SetupChainTestData1;
	SaveImportSource(in_no_match_action_id);
	SetupSourceLinkAndMappings1;
	SaveNoMatchRuleSet;

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'random',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_1
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'entirely different name',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_2
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'other company random',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_3
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'random (inc)*',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_4
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'random-inc2',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_5
	);

	UPDATE company
	   SET postcode = 'RMO-982'
	 WHERE company_sid IN (v_company_sid_1, v_company_sid_2, v_company_sid_3, v_company_sid_4);

	UPDATE company
	   SET postcode = 'RMO 982'
	 WHERE company_sid IN (v_company_sid_5);

	test_chain_shared_dedupe_pkg.AddStagingRow(
		in_vendor_num		=> '12345',
		in_vendor_name		=> 'Does not match',
		in_city				=> 'Roma',
		in_country			=> 'it',
		in_postal_code		=> 'DOESNOTMATCH',
		in_street			=> 'Via Portuense',
		in_state			=> '',
		in_website			=> 'random-inc.com',
		in_facility_type	=> 'Press',
		in_email			=> 'info@random-inc.com'
	);
END;

PROCEDURE TestNoMatchExpectCreate(
	in_processed_record_id		NUMBER
)
AS
	v_count						NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = in_processed_record_id
	   AND dedupe_action_type_id = chain_pkg.DEDUPE_AUTO
	   AND dedupe_action = chain_pkg.ACTION_CREATE
	   AND data_merged = 1
	   AND created_company_sid IS NOT NULL
	   AND matched_to_company_sid IS NULL;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Expected created company');
END;

PROCEDURE TestNoMatchAutoCreate
AS
	v_processed_record_ids		security_pkg.T_SID_IDS;
BEGIN
	SetNoMatchSource(chain_pkg.DEDUPE_AUTO);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id,
		in_reference				=> '12345',
		out_processed_record_ids	=> v_processed_record_ids
	);

	TestNoMatchExpectNone(v_processed_record_ids(1));

	TestNoMatchExpectCreate(v_processed_record_ids(1));
END;

PROCEDURE TestNoMatchExpectPark(
	in_processed_record_id		NUMBER
)
AS
	v_count						NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = in_processed_record_id
	   AND dedupe_action = chain_pkg.ACTION_IGNORE
	   AND dedupe_action_type_id = chain_pkg.DEDUPE_MANUAL
	   AND data_merged = 0
	   AND created_company_sid IS NULL
	   AND matched_to_company_sid IS NULL;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Expected record to have been marked as parked');
END;

PROCEDURE TestNoMatchPark
AS
	v_processed_record_ids		security_pkg.T_SID_IDS;
BEGIN
	SetNoMatchSource(chain_pkg.ACTION_IGNORE);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id,
		in_reference				=> '12345',
		out_processed_record_ids	=> v_processed_record_ids
	);

	TestNoMatchExpectNone(v_processed_record_ids(1));

	TestNoMatchExpectPark(v_processed_record_ids(1));
END;

PROCEDURE TestNoMatchExpectManualReview(
	in_processed_record_id		NUMBER
)
AS
	v_count						NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = in_processed_record_id
	   AND dedupe_action_type_id = chain_pkg.DEDUPE_MANUAL
	   AND dedupe_action IS NULL
	   AND data_merged = 0
	   AND created_company_sid IS NULL
	   AND matched_to_company_sid IS NULL;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Expected record to have been marked for manual review');
END;

PROCEDURE TestNoMatchManualReview
AS
	v_processed_record_ids		security_pkg.T_SID_IDS;
BEGIN
	SetNoMatchSource(chain_pkg.DEDUPE_MANUAL);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id,
		in_reference				=> '12345',
		out_processed_record_ids	=> v_processed_record_ids
	);

	TestNoMatchExpectNone(v_processed_record_ids(1));

	TestNoMatchExpectManualReview(v_processed_record_ids(1));
END;

PROCEDURE TestNormalisedValsMatching
AS
	v_company_sid_1			NUMBER;
	v_company_sid_2			NUMBER;
	v_company_sid_3			NUMBER;
	v_company_sid_4			NUMBER;
	v_alt_comp_name_id		NUMBER;
	v_processed_record_ids	security_pkg.T_SID_IDS;
BEGIN
	SetupChainTestData1;
	SaveImportSource(chain_pkg.DEDUPE_AUTO);
	SetupSourceLinkAndMappings1;
	SaveNamePostRuleSet(
		in_threshold_1		=> 60,
		in_threshold_2		=> 88,
		in_rule_type_id_1	=> chain_pkg.RULE_TYPE_LEVENSHTEIN,
		in_rule_type_id_2	=> chain_pkg.RULE_TYPE_LEVENSHTEIN,
		in_match_type_id	=> chain_pkg.DEDUPE_MANUAL
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'random-', --partial match, 60% after preprocessing on both the source and dest data
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_1
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'entirely different name',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_2
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'no match',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_3
	);

	v_alt_comp_name_id := alt_company_name_id_seq.nextval;
	company_pkg.savealtcompanyname(v_alt_comp_name_id, v_company_sid_3, 'random-');

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'no match on alt name',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_4
	);

	v_alt_comp_name_id := alt_company_name_id_seq.nextval;
	company_pkg.savealtcompanyname(v_alt_comp_name_id, v_company_sid_4, 'entirely different name');

	UPDATE company
	   SET postcode = 'RMO-982' --'-' will be replaced with empty space. Should be matched by using distance (88%)
	 WHERE company_sid IN (v_company_sid_1, v_company_sid_2, v_company_sid_3, v_company_sid_4);

	--process again for the postcode
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_1);
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_2);
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_3);
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_4);

	--Random-*(inc) will be normalised to random inc after we apply the preprocessing
	--rules on staging name, so it should give a match
	test_chain_shared_dedupe_pkg.AddStagingRow(
		in_vendor_num		=> '12345',
		in_vendor_name		=> 'Random*(inc)--', -- will be normalised to random inc
		in_city				=> 'Roma',
		in_country			=> 'it',
		in_postal_code		=> 'rmo*9823',-- will be normalised to rmo 9823
		in_street			=> 'Via Portuense',
		in_state			=> '',
		in_website			=> 'random-inc.com',
		in_facility_type	=> 'Press',
		in_email			=> 'info@random-inc.com'
	);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id,
		in_reference				=> '12345',
		out_processed_record_ids	=> v_processed_record_ids
	);

	--We configured the rule_set for manual merging so we don't expect any merges
	TestNoMatchPromoted(v_processed_record_ids(1));

	--but we expect some matches
	test_chain_shared_dedupe_pkg.TestPotentialMatches(
		v_processed_record_ids(1),
		T_NUMBER_LIST(v_company_sid_1, v_company_sid_3)
	);
END;

--same test data with a different threshold for name matching that should return 0 matches this ti,e
PROCEDURE TestNormalisedValsNOMatching
AS
	v_company_sid_1			NUMBER;
	v_company_sid_2			NUMBER;
	v_company_sid_3			NUMBER;
	v_company_sid_4			NUMBER;
	v_alt_comp_name_id		NUMBER;
	v_processed_record_ids	security_pkg.T_SID_IDS;
BEGIN
	SetupChainTestData1;
	SaveImportSource(chain_pkg.MANUAL_REVIEW);
	SetupSourceLinkAndMappings1;
	SaveNamePostRuleSet(61, 88);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'random-', --no match, 60% after preprocessing on both the source and dest data
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_1
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'entirely different name',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_2
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'no match',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_3
	);

	v_alt_comp_name_id := alt_company_name_id_seq.nextval;
	company_pkg.savealtcompanyname(v_alt_comp_name_id, v_company_sid_3, 'random-');

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'no match on alt name',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_4
	);

	v_alt_comp_name_id := alt_company_name_id_seq.nextval;
	company_pkg.savealtcompanyname(v_alt_comp_name_id, v_company_sid_4, 'entirely different name');

	UPDATE company
	   SET postcode = 'RMO-982' --'-' will be replaced with empty space. Should be matched by using distance (88%)
	 WHERE company_sid IN (v_company_sid_1, v_company_sid_2, v_company_sid_3, v_company_sid_4);

	--process again for the postcode
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_1);
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_2);
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_3);
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_4);

	--Random-*(inc) will be normalised to random inc after we apply the preprocessing
	--rules on staging name, so it should give a match
	test_chain_shared_dedupe_pkg.AddStagingRow(
		in_vendor_num		=> '12345',
		in_vendor_name		=> 'Random*(inc)--', -- will be normalised to random inc
		in_city				=> 'Roma',
		in_country			=> 'it',
		in_postal_code		=> 'rmo*9823',-- will be normalised to rmo 9823
		in_street			=> 'Via Portuense',
		in_state			=> '',
		in_website			=> 'random-inc.com',
		in_facility_type	=> 'Press',
		in_email			=> 'info@random-inc.com'
	);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id,
		in_reference				=> '12345',
		out_processed_record_ids	=> v_processed_record_ids
	);

	--We configured the rule_set for manual merging so we don't expect any merges
	TestNoMatchPromoted(v_processed_record_ids(1));

	--but we expect some matches
	test_chain_shared_dedupe_pkg.TestPotentialMatches(
		v_processed_record_ids(1),
		T_NUMBER_LIST()
	);
END;

PROCEDURE TestRuleTypeContains
AS
	v_company_sid_1			NUMBER;
	v_company_sid_2			NUMBER;
	v_company_sid_3			NUMBER;
	v_company_sid_4			NUMBER;
	v_company_sid_5			NUMBER;
	v_alt_comp_name_id		NUMBER;
	v_processed_record_ids	security_pkg.T_SID_IDS;
BEGIN
	SetupChainTestData1;
	SaveImportSource(chain_pkg.AUTO_CREATE);
	SetupSourceLinkAndMappings1;
	SaveNamePostRuleSet(100, 100, chain_pkg.RULE_TYPE_CONTAINS, chain_pkg.RULE_TYPE_EXACT);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'random*582', --match as alphabetical value is contained in staging value
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_1
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'abahhssomethingrandom*582', --match as alphabetical staging is contained in that value
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_2
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'entirely different name',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_3
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'no match',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_4
	);

	v_alt_comp_name_id := alt_company_name_id_seq.nextval;
	company_pkg.savealtcompanyname(v_alt_comp_name_id, v_company_sid_4, 'abahhssomethingrandom*582');

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'no match on alt name',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_5
	);

	v_alt_comp_name_id := alt_company_name_id_seq.nextval;
	company_pkg.savealtcompanyname(v_alt_comp_name_id, v_company_sid_5, 'entirely different name');

	UPDATE company
	   SET postcode = 'RMO-982' --exact match
	 WHERE company_sid IN (v_company_sid_1, v_company_sid_2, v_company_sid_3, v_company_sid_4, v_company_sid_5);

	--process again for the postcode
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_1);
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_2);
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_3);
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_4);
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_5);

	--Random-*(inc) will be normalised to random inc after we apply the preprocessing
	--rules on staging name, so it should give a match
	test_chain_shared_dedupe_pkg.AddStagingRow(
		in_vendor_num		=> '12345',
		in_vendor_name		=> 'somethingrandom-1234567',
		in_city				=> 'Roma',
		in_country			=> 'it',
		in_postal_code		=> 'rmo*982',-- will be normalised to rmo 982
		in_street			=> 'Via Portuense',
		in_state			=> '',
		in_website			=> 'random-inc.com',
		in_facility_type	=> 'Press',
		in_email			=> 'info@random-inc.com'
	);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id,
		in_reference				=> '12345',
		out_processed_record_ids	=> v_processed_record_ids
	);

	--We configured the rule_set for manual merging so we don't expect any merges
	TestNoMatchPromoted(v_processed_record_ids(1));

	--but we expect some matches
	test_chain_shared_dedupe_pkg.TestPotentialMatches(
		v_processed_record_ids(1),
		T_NUMBER_LIST(v_company_sid_1, v_company_sid_2, v_company_sid_4)
	);
END;

PROCEDURE TestMultFldMatchUsingPreproc
AS
	v_dedupe_field_ids			security_pkg.T_SID_IDS;
	v_countries					security_pkg.T_VARCHAR2_ARRAY;
	v_processed_record_ids		security_pkg.T_SID_IDS;
	v_dedupe_preproc_rule_id	NUMBER;
	v_company_sid_1				NUMBER;
	v_company_sid_2				NUMBER;
	v_company_sid_3				NUMBER;
	v_alt_comp_name_id			NUMBER;
	v_count						NUMBER;
BEGIN
	SetupChainTestData1;
	SaveImportSource(chain_pkg.DEDUPE_AUTO);
	SetupSourceLinkAndMappings1;

	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;

	--2 rules sets, the first will not return a match so it will move to the 2nd
	SaveNamePostRuleSet(
		in_threshold_1		=> 100,
		in_threshold_2		=> 100,
		in_rule_type_id_1	=> chain_pkg.RULE_TYPE_EXACT,
		in_rule_type_id_2	=> chain_pkg.RULE_TYPE_EXACT,
		in_match_type_id	=> chain_pkg.DEDUPE_MANUAL
	);

	--this will return a match
	SaveNamePostAddressRuleSet(
		in_threshold_1		=> 100,
		in_threshold_2		=> 100,
		in_threshold_3		=> 100,
		in_rule_type_id_1	=> chain_pkg.RULE_TYPE_CONTAINS,
		in_rule_type_id_2	=> chain_pkg.RULE_TYPE_EXACT,
		in_rule_type_id_3	=> chain_pkg.RULE_TYPE_EXACT,
		in_match_type_id	=> chain_pkg.DEDUPE_MANUAL
	);

	--preprocessing rules
	v_countries(1) := 'de';
	--replaces eszett
	dedupe_admin_pkg.SavePreProcRule(
		in_dedupe_preproc_rule_id 	=> NULL,
		in_pattern					=> chr(50079),
		in_replacement				=> 'ss',
		in_run_order				=> 100,
		in_dedupe_field_ids			=> v_dedupe_field_ids,
		in_countries				=> v_countries,
		out_dedupe_preproc_rule_id	=> v_dedupe_preproc_rule_id
	);

	--the following rule will only apply to italian companies
	v_countries(1) := 'it';
	dedupe_admin_pkg.SavePreProcRule(
		in_dedupe_preproc_rule_id 	=> NULL,
		in_pattern					=> chr(50079),
		in_replacement				=> 's',
		in_run_order				=> 101,
		in_dedupe_field_ids			=> v_dedupe_field_ids,
		in_countries				=> v_countries,
		out_dedupe_preproc_rule_id	=> v_dedupe_preproc_rule_id
	);

	v_countries.DELETE;

	dedupe_admin_pkg.SavePreProcRule(
		in_dedupe_preproc_rule_id 	=> NULL,
		in_pattern					=> chr(50080),
		in_replacement				=> 'a',
		in_run_order				=> 102,
		in_dedupe_field_ids			=> v_dedupe_field_ids,
		in_countries				=> v_countries,
		out_dedupe_preproc_rule_id	=> v_dedupe_preproc_rule_id
	);

	dedupe_admin_pkg.SavePreProcRule(
		in_dedupe_preproc_rule_id 	=> NULL,
		in_pattern					=> chr(50102),--o umlaut lowercase
		in_replacement				=> 'o',
		in_run_order				=> 103,
		in_dedupe_field_ids			=> v_dedupe_field_ids,
		in_countries				=> v_countries,
		out_dedupe_preproc_rule_id	=> v_dedupe_preproc_rule_id
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> chr(50070)||'l Carl-Zei'||chr(50079)||'-Stiftung', --50070 = O umlaut, should return a match with contains rule type
		in_country_code=> 'de',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_1
	);

	UPDATE company
	   SET address_1 = 'Orsenstrasse',
		   postcode = 'fr982'||chr(50079) --eszet
	 WHERE company_sid = v_company_sid_1;

	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_1);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'random company '||chr(50079), -- eszet to 's' because the country is italy
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_2
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'no match',
		in_country_code=> 'de',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_3
	);
	
	UPDATE company
	   SET address_1 = 'Orsenstrasse',
		   postcode = 'fr982'||chr(50079) --eszet
	 WHERE company_sid = v_company_sid_3;
	 
	v_alt_comp_name_id := alt_company_name_id_seq.nextval;
	company_pkg.savealtcompanyname(v_alt_comp_name_id, v_company_sid_3, chr(50070)||'l Carl-Zei'||chr(50079)||'-Stiftung'); --contains match on alt comp name

	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid_3);

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_preproc_comp
	 WHERE company_sid = v_company_sid_1
	   AND name = 'ol carl zeiss stiftung'
	   AND postcode = 'fr982ss';

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong preprocessed values');

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_preproc_comp
	 WHERE company_sid = v_company_sid_2
	   AND name = 'random company s';

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong preprocessed values');

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_pp_alt_comp_name
	 WHERE company_sid = v_company_sid_3
	   AND name = 'ol carl zeiss stiftung';

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong preprocessed values');

	test_chain_shared_dedupe_pkg.AddStagingRow(
		in_vendor_num		=> '987654321',
		in_vendor_name		=> 'Ol Carl-Zei'||chr(50079),
		in_city				=> 'Frankfurt',
		in_country			=> 'de',
		in_postal_code		=> 'fr982'||chr(50079),-- will be normalised to fr982ss
		in_street			=> chr(50070)||'rsenstrasse', --o umlaut uppercase
		in_state			=> '',
		in_website			=> 'random-inc.com',
		in_facility_type	=> 'Press',
		in_email			=> 'info@carlzei.com'
	);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id,
		in_reference				=> '987654321',
		out_processed_record_ids	=> v_processed_record_ids
	);

	--We configured the 2nd rule_set for manual merging so we don't expect any merges
	TestNoMatchPromoted(v_processed_record_ids(1));

	--but we expect some matches
	test_chain_shared_dedupe_pkg.TestPotentialMatches(
		v_processed_record_ids(1),
		T_NUMBER_LIST(v_company_sid_1, v_company_sid_3),
		v_name_post_addr_rule_set_id
	);

END;

PROCEDURE SaveMultiMatchAutoRuleSet
AS
	v_mapping_ids					security.security_pkg.T_SID_IDS;
	v_rule_ids						security.security_pkg.T_SID_IDS;
	v_rule_type_ids					security.security_pkg.T_SID_IDS;
	v_match_thresholds				helper_pkg.T_NUMBER_ARRAY;
BEGIN
		--Set rule sets
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_name_id, v_mapping_postcode_id));

	--need arrays of dedupe_rule_id and thresholds
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_LEVENSHTEIN;
	v_rule_type_ids(2) := chain_pkg.RULE_TYPE_EXACT;

	v_match_thresholds(1) := 80;
	v_match_thresholds(2) := 100;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id,
		in_description				=> 'Partial name and exact post code rule set',
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_AUTO,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id_1
	);
END;

PROCEDURE SetupMultiMatchAutoRuleSource
AS
	v_mapping_id					NUMBER;
	v_mapping_ref_id				NUMBER;
	v_mapping_ids					security.security_pkg.T_SID_IDS;
	v_rule_ids						security.security_pkg.T_SID_IDS;
	v_rule_type_ids					security.security_pkg.T_SID_IDS;
	v_match_thresholds				helper_pkg.T_NUMBER_ARRAY;
	v_company_sid_1					NUMBER;
	v_company_sid_2					NUMBER;
	v_company_sid_3					NUMBER;
	v_company_sid_4					NUMBER;
	v_company_sid_5					NUMBER;
BEGIN
	SetupChainTestData1;
	SaveImportSource(chain_pkg.DEDUPE_AUTO);
	SetupSourceLinkAndMappings1;
	SaveMultiMatchAutoRuleSet;

	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'random', --partial match
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_1
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'entirely different name',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_2
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'other company random',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_3
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'random (inc)*', --exact match (brackets and asterisk will be stripped out)
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_4
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'random-inc2',
		in_country_code=> 'it',
		in_company_type_id=> v_supplier_company_type_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid_5
	);

	UPDATE company
	   SET postcode = 'RMO-982'
	 WHERE company_sid IN (v_company_sid_1, v_company_sid_2, v_company_sid_3);

	UPDATE company
	   SET postcode = 'RMO 982'
	 WHERE company_sid IN (v_company_sid_4, v_company_sid_5);

	test_chain_shared_dedupe_pkg.AddStagingRow(
		in_vendor_num		=> '12345',
		in_vendor_name		=> 'Random inc',
		in_city				=> 'Roma',
		in_country			=> 'it',
		in_postal_code		=> 'rmo 982',
		in_street			=> 'Via Portuense',
		in_state			=> '',
		in_website			=> 'random-inc.com',
		in_facility_type	=> 'Press',
		in_email			=> 'info@random-inc.com'
	);

	v_expected_company_sids := T_NUMBER_LIST(v_company_sid_4, v_company_sid_5);
END;

PROCEDURE TestMultipleMatchAutoRuleSet
AS
	v_processed_record_ids		security_pkg.T_SID_IDS;
BEGIN

	SetupMultiMatchAutoRuleSource;

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id,
		in_reference				=> '12345',
		out_processed_record_ids	=> v_processed_record_ids
	);

	test_chain_shared_dedupe_pkg.TestPotentialMatches(
		in_processed_record_id		=> v_processed_record_ids(1),
		in_expected_company_sids	=> v_expected_company_sids
	);

	TestNoMatchPromoted(
		in_processed_record_id		=> v_processed_record_ids(1)
	);
END;

PROCEDURE SetupSourceLinkAndMappings2
AS
	v_mapping_id					NUMBER;
	v_mapping_ref_id				NUMBER;
BEGIN
	v_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'COMPANY_STAGING');

	--set up staging link
	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id,
		in_description 					=> 'Company data integration',
		in_staging_tab_sid 				=> v_tab_sid,
		in_position 					=> 1,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'VENDOR_NUM'),
		in_staging_batch_num_col_sid 	=> NULL,
		in_parent_staging_link_id 		=> NULL,
		in_destination_tab_sid 			=> NULL,
		out_dedupe_staging_link_id 		=> v_staging_link_id
	);

	--setup mappings
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'ADDRESS_1'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_ADDRESS,
		out_dedupe_mapping_id => v_mapping_address_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'VENDOR_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_NAME,
		in_allow_create_alt_comp_name => 1,
		out_dedupe_mapping_id => v_mapping_name_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'COUNTRY'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id => v_mapping_country_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'CITY'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_CITY,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'POSTAL_CODE'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_POSTCODE,
		out_dedupe_mapping_id => v_mapping_postcode_id
	);
END;

PROCEDURE SetupAddressMatchRuleSet
AS
	v_mapping_ids					security.security_pkg.T_SID_IDS;
	v_rule_ids						security.security_pkg.T_SID_IDS;
	v_rule_type_ids					security.security_pkg.T_SID_IDS;
	v_match_thresholds				helper_pkg.T_NUMBER_ARRAY;
BEGIN
		--Set rule sets
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_address_id));

	--need arrays of dedupe_rule_id and thresholds
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_LEVENSHTEIN;
	v_match_thresholds(1) := 50;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id,
		in_description				=> 'Partial address rule set',
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id_1
	);
END;

PROCEDURE SetupAddressNoMatchRuleSet
AS
	v_mapping_ids					security.security_pkg.T_SID_IDS;
	v_rule_ids						security.security_pkg.T_SID_IDS;
	v_rule_type_ids					security.security_pkg.T_SID_IDS;
	v_match_thresholds				helper_pkg.T_NUMBER_ARRAY;
BEGIN
		--Set rule sets
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_address_id));

	--need arrays of dedupe_rule_id and thresholds
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_JAROWINKLER;
	v_match_thresholds(1) := 70;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id,
		in_description				=> 'Partial address rule set',
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_MANUAL,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id_1
	);
END;

PROCEDURE TestMatchAddressMultiColumns
AS
	v_processed_record_ids		security_pkg.T_SID_IDS;
	v_company_sid 				NUMBER;
	v_company_1_sid				NUMBER;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	SaveImportSource(chain_pkg.DEDUPE_MANUAL);
	SetupSourceLinkAndMappings2;
	SetupAddressMatchRuleSet;

	-- Add a staging row and company data
	AddStagingRow(
		in_vendor_num		=> '23',
		in_vendor_name		=> 'Denim Jayskits',
		in_city				=> 'Glesga',
		in_country			=> 'sc',
		in_postal_code		=> 'G8 E3',
		in_street			=> 'High Street',
		in_state			=> '',
		in_website			=> 'jayskits.com',
		in_facility_type	=> 'Apparel',
		in_email			=> 'GloryDays@jayskits.com',
		in_address_1 		=> '23 High Street',
		in_address_2 		=> 'Glesga',
		in_address_3 		=> 'Scotland',
		in_address_4 		=> 'United Kingdom'
	);

	company_pkg.CreateCompany(
		in_name => 'Denim Jayskits',
		in_country_code => 'gb',
		in_company_type_id => company_type_pkg.GetCompanyTypeId('SUPPLIER'),
		in_sector_id => NULL,
		out_company_sid => v_company_sid
	);

	company_pkg.UpdateCompany(
		in_company_sid => v_company_sid,
		in_address_1 => '24 High Street',
		in_address_2 => 'Glesga',
		in_address_3 => 'Scotland',
		in_address_4 => 'United Kingdom'
	);

	company_pkg.CreateCompany(
		in_name=> 'Leather Jackets',
		in_country_code=> 'it',
		in_company_type_id=> company_type_pkg.GetCompanyTypeId('SUPPLIER'),
		in_sector_id=> NULL,
		out_company_sid=> v_company_1_sid
	);

	company_pkg.UpdateCompany(
		in_company_sid => v_company_1_sid,
		in_address_1 => '23 High Street',
		in_address_2 => 'Glesga',
		in_address_3 => 'Scotland',
		in_postcode => 'R5 F34'
	);

	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid);
	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_1_sid);

	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;

	company_dedupe_pkg.ProcessParentStagingRecord(
  		in_import_source_id			=> v_source_id,
  		in_reference				=> '23',
  		out_processed_record_ids	=> v_processed_record_ids
  	);

	TestPotentialMatches(v_processed_record_ids(1), T_NUMBER_LIST(v_company_sid, v_company_1_sid));

	-- Merge the data and check it is what we expect.
	company_dedupe_pkg.MergeRecord(v_processed_record_ids(1), v_company_sid);

	TestMergedCompanyAddress(v_company_sid, '23 High Street', 'Glesga', 'Scotland', 'United Kingdom');
END;

PROCEDURE TestMatchAddressSingleColumn
AS
	v_processed_record_ids 		security_pkg.T_SID_IDS;
	v_company_sid 				NUMBER;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	SaveImportSource(chain_pkg.DEDUPE_MANUAL);
	SetupSourceLinkAndMappings2;
	SetupAddressMatchRuleSet;

	-- Add a staging row and create company data to match
	AddStagingRow(
		in_vendor_num		=> '23',
		in_vendor_name		=> 'Denim Jayskits',
		in_city				=> 'Glesga',
		in_country			=> 'sc',
		in_postal_code		=> 'G8 E3',
		in_street			=> 'High Street',
		in_state			=> '',
		in_website			=> 'jayskits.com',
		in_facility_type	=> 'Apparel',
		in_email			=> 'GloryDays@jayskits.com',
		in_address_1 		=> '23 High Street'
	);

	company_pkg.CreateCompany(
		in_name=> 'Denim Jayskits',
		in_country_code=> 'gb',
		in_company_type_id=> company_type_pkg.GetCompanyTypeId('SUPPLIER'),
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid
	);

	company_pkg.UpdateCompany(
		in_company_sid => v_company_sid,
		in_address_1 => 'High Street'
	);

	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid);

	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;

	company_dedupe_pkg.ProcessParentStagingRecord(
 		in_import_source_id			=> v_source_id,
 		in_reference				=> '23',
 		out_processed_record_ids	=> v_processed_record_ids
 	);

	TestNoMatchPromoted(v_processed_record_ids(1));
	TestPotentialMatches(v_processed_record_ids(1), T_NUMBER_LIST(v_company_sid));
END;

PROCEDURE TestPotentialAddressNoMatch
AS
	v_processed_record_ids 		security_pkg.T_SID_IDS;
	v_company_sid 				NUMBER;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	SaveImportSource(chain_pkg.DEDUPE_MANUAL);
	SetupSourceLinkAndMappings2;
	SetupAddressNoMatchRuleSet;

	-- Add a staging row and create company data to match
	AddStagingRow(
		in_vendor_num		=> '23',
		in_vendor_name		=> 'Denim Jayskits',
		in_city				=> 'Glesga',
		in_country			=> 'sc',
		in_postal_code		=> 'G8 E3',
		in_street			=> 'High Street',
		in_state			=> '',
		in_website			=> 'jayskits.com',
		in_facility_type	=> 'Apparel',
		in_email			=> 'GloryDays@jayskits.com',
		in_address_1 		=> '9 The High Road'
	);

	company_pkg.CreateCompany(
		in_name=> 'Denim Jayskits',
		in_country_code=> 'gb',
		in_company_type_id=> company_type_pkg.GetCompanyTypeId('SUPPLIER'),
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid
	);

	company_pkg.UpdateCompany(
		in_company_sid => v_company_sid,
		in_address_1 => '23 High Street'
	);

	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid);

	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id,
		in_reference				=> '23',
		out_processed_record_ids	=> v_processed_record_ids
	);

	TestNoMatchPromoted(v_processed_record_ids(1));
	TestPotentialMatches(v_processed_record_ids(1), T_NUMBER_LIST());
END;

PROCEDURE TestPartAddNameExactPCCntry
AS
	v_processed_record_ids 		security_pkg.T_SID_IDS;
	v_company_sid 				NUMBER;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	SaveImportSource(chain_pkg.DEDUPE_MANUAL);
	SetupSourceLinkAndMappings2;
	SavePartNameCntryPstAddRuleSet(chain_pkg.DEDUPE_MANUAL);

	-- Add a staging row and create company data to match
	AddStagingRow(
		in_vendor_num		=> '23',
		in_vendor_name		=> 'Denim Jayskits',
		in_city				=> 'Glesga',
		in_country			=> 'gb',
		in_postal_code		=> 'G8 E3',
		in_street			=> 'High Street',
		in_state			=> '',
		in_website			=> 'jayskits.com',
		in_facility_type	=> 'Apparel',
		in_email			=> 'GloryDays@jayskits.com',
		in_address_1 		=> '9 High Street'
	);

	company_pkg.CreateCompany(
		in_name=> 'Denim Jaykits',
		in_country_code=> 'gb',
		in_company_type_id=> company_type_pkg.GetCompanyTypeId('SUPPLIER'),
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid
	);

	company_pkg.UpdateCompany(
		in_company_sid => v_company_sid,
		in_address_1 => '23 High Street',
		in_postcode => 'G8 E3'
	);

	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid);

	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id,
		in_reference				=> '23',
		out_processed_record_ids	=> v_processed_record_ids
	);

	TestPotentialMatches(v_processed_record_ids(1), T_NUMBER_LIST(v_company_sid));

	-- Merge the data and check it is what we expect.
	company_dedupe_pkg.MergeRecord(v_processed_record_ids(1), v_company_sid);

	TestMergedCompanyAddress(v_company_sid, '9 High Street', NULL, NULL, NULL);
END;

PROCEDURE TestAutoAddrNamePCCntryMatch
AS
	v_processed_record_ids 		security_pkg.T_SID_IDS;
	v_company_sid 				NUMBER;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	SaveImportSource(chain_pkg.DEDUPE_AUTO);
	SetupSourceLinkAndMappings2;
	SavePartNameCntryPstAddRuleSet(chain_pkg.DEDUPE_AUTO);

	AddStagingRow(
		in_vendor_num		=> '2323',
		in_vendor_name		=> 'Finest Coffee',
		in_city				=> 'Amsterdam',
		in_country			=> 'nl',
		in_postal_code		=> 'N7 3LT',
		in_street			=> 'Coffee street',
		in_state			=> 'Amsterdam',
		in_website			=> 'finestCoffeeNL.com',
		in_facility_type	=> 'SUPPLIER',
		in_email			=> 'support@finestCoffeeNL.com',
		in_address_1 		=> '2323 Coffee Street',
		in_address_2 		=> 'Red Light District',
		in_address_3 		=> 'Amsterdam',
		in_address_4 		=> ''
	);

	company_pkg.CreateCompany(
		in_name=> 'Finest Coffee Inc',
		in_country_code=> 'nl',
		in_company_type_id=> company_type_pkg.GetCompanyTypeId('SUPPLIER'),
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid
	);

	company_pkg.UpdateCompany(
		in_company_sid 	=> v_company_sid,
		in_address_1 	=> '2323 Coffee Lane',
		in_address_2 	=> 'Red Light District',
		in_address_3 	=> 'Amsterdam',
		in_address_4 	=> 'Netherlands',
		in_postcode		=> 'N7 3LT'
	);

	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid);

	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id,
		in_reference				=> '2323',
		out_processed_record_ids	=> v_processed_record_ids
	);

	TestOneMatchExpectOne(v_processed_record_ids(1));
	TestOneMatchAutoExpectMerged(v_processed_record_ids(1));

	-- Check the merged address matches
	TestMergedCompanyAddress(v_company_sid, '2323 Coffee Street', 'Red Light District', 'Amsterdam', '');
END;

PROCEDURE TestMergedAltCompName(
	in_company_sid 		NUMBER,
	in_old_name		 	VARCHAR2,
	in_new_name		 	VARCHAR2
)
AS
	v_name 		VARCHAR2(255);
BEGIN
	SELECT name
	  INTO v_name
	  FROM alt_company_name
	 WHERE company_sid = in_company_sid;

	csr.unit_test_pkg.AssertAreEqual(v_name, in_old_name, 'Old company name not equal! Expected: '||in_old_name||' got: '||v_name);

	SELECT name
	  INTO v_name
	  FROM company
	 WHERE company_sid = in_company_sid;

	csr.unit_test_pkg.AssertAreEqual(v_name, in_new_name, 'New company name not equal! Expected: '||in_new_name||' got: '||v_name);
END;

PROCEDURE TestMergeAltCompNameAddress
AS
	v_processed_record_ids 		security_pkg.T_SID_IDS;
	v_company_sid 				NUMBER;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	SaveImportSource(chain_pkg.DEDUPE_AUTO);
	SetupSourceLinkAndMappings2;
	SaveAddressContainsRuleSet(chain_pkg.DEDUPE_AUTO);

	AddStagingRow(
		in_vendor_num		=> '2323',
		in_vendor_name		=> 'Finest Coffee',
		in_city				=> 'Amsterdam',
		in_country			=> 'nl',
		in_postal_code		=> 'N7 3LT',
		in_street			=> 'Coffee street',
		in_state			=> 'Amsterdam',
		in_website			=> 'finestCoffeeNL.com',
		in_facility_type	=> 'SUPPLIER',
		in_email			=> 'support@finestCoffeeNL.com',
		in_address_1 		=> '2323 Coffee Street',
		in_address_2 		=> 'Red Light District',
		in_address_3 		=> 'Amsterdam',
		in_address_4 		=> ''
	);

	company_pkg.CreateCompany(
		in_name=> 'Finest Coffee Inc',
		in_country_code=> 'nl',
		in_company_type_id=> company_type_pkg.GetCompanyTypeId('SUPPLIER'),
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid
	);

	company_pkg.UpdateCompany(
		in_company_sid 	=> v_company_sid,
		in_address_1 	=> '2323 Coffee Street',
		in_postcode		=> 'N7 3LT'
	);

	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid);

	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id,
		in_reference				=> '2323',
		out_processed_record_ids	=> v_processed_record_ids
	);

	TestOneMatchExpectOne(v_processed_record_ids(1));
	TestOneMatchAutoExpectMerged(v_processed_record_ids(1));

	-- Check the merged address matches
	TestMergedCompanyAddress(v_company_sid, '2323 Coffee Street', 'Red Light District', 'Amsterdam', '');
	-- Check the old company name has been moved to the alternative company name table.
	TestMergedAltCompName(v_company_sid, 'Finest Coffee Inc', 'Finest Coffee');
END;

END;
/
