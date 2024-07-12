CREATE OR REPLACE PACKAGE BODY chain.test_dedupe_purchaser_pkg AS

v_site_name							VARCHAR2(200);
v_vendor_company_type_id			NUMBER;
v_site_company_type_id				NUMBER;
v_vendor_sid_1						NUMBER;
v_vendor_sid_2						NUMBER;
v_vendor_sid_3						NUMBER;
v_site_sid_1						NUMBER;
v_site_sid_2						NUMBER;
v_site_sid_3						NUMBER;
v_tab_sid							NUMBER;
v_import_source_id					NUMBER;
v_staging_link_id					NUMBER;
v_dedupe_rule_set_id				NUMBER;
v_mapping_name_id					NUMBER;
v_mapping_postcode_id				NUMBER;
v_mapping_country_id				NUMBER;


PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_top_company_sid				NUMBER;
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);
	test_chain_utils_pkg.SetupTwoTier;

	SELECT top_company_sid
	  INTO v_top_company_sid
	  FROM customer_options
	 WHERE app_sid = security_pkg.getapp;

	security.security_pkg.SetContext('CHAIN_COMPANY', v_top_company_sid);

	v_vendor_company_type_id := company_type_pkg.GetCompanyTypeId('VENDOR');
	v_site_company_type_id := company_type_pkg.GetCompanyTypeId('SITE');
END;

PROCEDURE SetSite(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
END;

PROCEDURE SetUp
AS
BEGIN
	-- create some vendors
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> 'UL UK Ltd',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_vendor_company_type_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_vendor_sid_1
	);
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> 'UL International Inc',
		in_country_code			=> 'us',
		in_company_type_id		=> v_vendor_company_type_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_vendor_sid_2
	);
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> 'UL Italia',
		in_country_code			=> 'it',
		in_company_type_id		=> v_vendor_company_type_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_vendor_sid_3
	);

	-- create some sites
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> 'UK Site Ltd',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_site_company_type_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_site_sid_1
	);
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> 'US Site Inc',
		in_country_code			=> 'us',
		in_company_type_id		=> v_site_company_type_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_site_sid_2
	);
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> 'UL Site Ltd',
		in_country_code			=> 'us',
		in_company_type_id		=> v_site_company_type_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_site_sid_3
	);

	--test A -> B -> A relationship loop
	company_pkg.StartRelationship(v_site_sid_3, v_vendor_sid_2, null);
	company_pkg.ActivateRelationship(v_site_sid_3, v_vendor_sid_2);

	--test A -> B -> C-> A indirect relationship loop
	company_pkg.StartRelationship(v_site_sid_1, v_site_sid_2, null);
	company_pkg.ActivateRelationship(v_site_sid_1, v_site_sid_2);
	company_pkg.StartRelationship(v_site_sid_2, v_vendor_sid_1, null);
	company_pkg.ActivateRelationship(v_site_sid_2, v_vendor_sid_1);

	-- udpdate postcode
	UPDATE company
	   SET postcode = 'CB24 9BZ'
	 WHERE company_sid = v_vendor_sid_1;

	UPDATE company
	   SET postcode = '37067'
	 WHERE company_sid = v_vendor_sid_2;

	UPDATE company
	   SET postcode = '22060'
	 WHERE company_sid = v_vendor_sid_3;

	UPDATE company
	   SET postcode = 'CB24 8AX'
	 WHERE company_sid = v_site_sid_1;

	UPDATE company
	   SET postcode = '30339'
	 WHERE company_sid = v_site_sid_2;

	UPDATE company
	   SET postcode = '90210'
	 WHERE company_sid = v_site_sid_3;

	UPDATE customer_options
	   SET prevent_relationship_loops = 1;
END;

PROCEDURE TearDown
AS
BEGIN
	--clear dedupe setup + dedupe results + chain site companies + chain vendor companies + staging table
	FOR r IN (
		SELECT lookup_key
		  FROM import_source
		 WHERE app_sid = security.security_pkg.GetApp
		   AND is_owned_by_system = 0
	)
	LOOP
		test_chain_utils_pkg.TearDownImportSource(r.lookup_key);
	END LOOP;

	--Move UI system managed source back to its original position
	UPDATE import_source
	   SET position = 0
	 WHERE is_owned_by_system = 1;

	test_chain_utils_pkg.DeleteFullyCompaniesOfType('SITE');
	test_chain_utils_pkg.DeleteFullyCompaniesOfType('VENDOR');

	UPDATE customer_options
	   SET prevent_relationship_loops = 0;

	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.company_purchaser_staging';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;
END;

PROCEDURE TearDownFixture
AS
	v_count							NUMBER;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	UPDATE customer_options
	   SET enable_dedupe_preprocess = 0
	 WHERE app_sid = security.security_pkg.GetApp;

	test_chain_utils_pkg.TearDownTwoTier;
END;

-- private
PROCEDURE AddStagingRow(
	in_batch_num				IN	NUMBER,
	in_vendor_num				IN	VARCHAR2,
	in_vendor_name				IN	VARCHAR2,
	in_city						IN	VARCHAR2,
	in_postal_code				IN	VARCHAR2,
	in_country					IN	VARCHAR2,
	in_purchaser_company_sid	IN	VARCHAR2,
	in_company_type				IN	VARCHAR2 DEFAULT NULL
)
AS
BEGIN
	EXECUTE IMMEDIATE ('
		INSERT INTO rag.company_purchaser_staging(
			company_staging_id,
			batch_num,
			vendor_num,
			vendor_name,
			city,
			postal_code,
			country,
			purchaser_company_sid,
			company_type
		)
		VALUES(
			cms.item_id_seq.nextval,
			:1,:2,:3,:4,:5,:6,:7,:8
		)'
	)
	USING in_batch_num, in_vendor_num, in_vendor_name, in_city, in_postal_code,	in_country, in_purchaser_company_sid, in_company_type;
END;

PROCEDURE TestNoMatchPromoted(
	in_processed_record_id			NUMBER
)
AS
	v_data_merged					NUMBER;
	v_created_company_sid			NUMBER;
	v_matched_to_company_sid		NUMBER;
BEGIN
	SELECT data_merged, created_company_sid, matched_to_company_sid
	  INTO v_data_merged, v_created_company_sid, v_matched_to_company_sid
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = in_processed_record_id;

	csr.unit_test_pkg.AssertAreEqual(NULL, v_matched_to_company_sid, 'Didn''t expect a matched company');
	csr.unit_test_pkg.AssertAreEqual(NULL, v_created_company_sid, 'Didn''t expect a new company');
	csr.unit_test_pkg.AssertAreEqual(0, v_data_merged, 'Didn'' expect a data merge');
END;

PROCEDURE TestPotentialMatches(
	in_processed_record_id			NUMBER,
	in_expected_company_sids		T_NUMBER_LIST,
	in_rule_set_id					NUMBER DEFAULT NULL
)
AS
	v_count							NUMBER;
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

PROCEDURE TestNoMatchExpectNone(
	in_processed_record_id			NUMBER
)
AS
	v_count							NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_match
	 WHERE dedupe_processed_record_id = in_processed_record_id;

	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Matched record found, expected none');
END;

PROCEDURE TestNoMatchExpectCreate(
	in_processed_record_id			NUMBER
)
AS
	v_count							NUMBER;
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

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Expected one company is created');
END;

PROCEDURE TestRelationshipExists(
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
)
AS 
BEGIN
	csr.unit_test_pkg.AssertIsTrue(
		in_actual		=> company_pkg.CompanyTypeRelationshipExists(in_purchaser_company_sid, in_supplier_company_sid),
		in_message		=> 'Expected company type relataionship between purchaser '||in_purchaser_company_sid||' and supplier '||in_supplier_company_sid
	);
END;

PROCEDURE TestRelationshipDoesNotExist(
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
)
AS 
BEGIN
	csr.unit_test_pkg.AssertIsFalse(
		in_actual		=> company_pkg.CompanyTypeRelationshipExists(in_purchaser_company_sid, in_supplier_company_sid),
		in_message		=> 'Expected no company type relataionship between purchaser '||in_purchaser_company_sid||' and supplier '||in_supplier_company_sid
	);
END;

PROCEDURE TestDirectionalRelationship(
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_expected					IN	NUMBER
)
AS
	v_count						NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM supplier_relationship
	 WHERE purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid;

	IF in_expected = 0 THEN
		csr.unit_test_pkg.AssertAreEqual(in_expected, v_count, 'There should be no relationship - '||in_purchaser_company_sid||' -> '||in_supplier_company_sid);
	ELSE
		csr.unit_test_pkg.AssertAreEqual(in_expected, v_count, 'The should be a relationship - '||in_purchaser_company_sid||' -> '||in_supplier_company_sid);
	END IF;
END;

PROCEDURE SetupImportSource(
	in_no_match_action_id		NUMBER
)
AS
BEGIN
	dedupe_admin_pkg.SaveImportSource(
		in_import_source_id 		=> -1,
		in_name						=> 'Company and purchaser integration',
		in_position					=> 1,
		in_no_match_action_id		=> in_no_match_action_id,
		in_lookup_key				=> 'COMPANY_PURCHASER_DATA',
		out_import_source_id		=> v_import_source_id
	);
END;

PROCEDURE SetupSourceLinkAndMappings
AS
	v_mapping_id					NUMBER;
BEGIN
	v_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'COMPANY_PURCHASER_STAGING');

	-- set up staging link
	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_import_source_id,
		in_description 					=> 'Company (purchaser) data integration',
		in_staging_tab_sid 				=> v_tab_sid,
		in_position 					=> 1,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'VENDOR_NUM'),
		in_staging_batch_num_col_sid 	=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'BATCH_NUM'),
		in_parent_staging_link_id 		=> NULL,
		in_destination_tab_sid 			=> NULL,
		out_dedupe_staging_link_id 		=> v_staging_link_id
	);

	-- setup mappings
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id			=> -1,
		in_dedupe_staging_link_id		=> v_staging_link_id,
		in_tab_sid						=> v_tab_sid,
		in_col_sid						=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'VENDOR_NAME'),
		in_dedupe_field_id				=> chain_pkg.FLD_COMPANY_NAME,
		out_dedupe_mapping_id			=> v_mapping_name_id
	);
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id			=> -1,
		in_dedupe_staging_link_id		=> v_staging_link_id,
		in_tab_sid						=> v_tab_sid,
		in_col_sid						=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'CITY'),
		in_dedupe_field_id				=> chain_pkg.FLD_COMPANY_CITY,
		out_dedupe_mapping_id			=> v_mapping_id
	);
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id			=> -1,
		in_dedupe_staging_link_id		=> v_staging_link_id,
		in_tab_sid						=> v_tab_sid,
		in_col_sid						=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'POSTAL_CODE'),
		in_dedupe_field_id				=> chain_pkg.FLD_COMPANY_POSTCODE,
		out_dedupe_mapping_id			=> v_mapping_postcode_id
	);
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id			=> -1,
		in_dedupe_staging_link_id		=> v_staging_link_id,
		in_tab_sid						=> v_tab_sid,
		in_col_sid						=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'COUNTRY'),
		in_dedupe_field_id				=> chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id			=> v_mapping_country_id
	);
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id			=> -1,
		in_dedupe_staging_link_id		=> v_staging_link_id,
		in_tab_sid						=> v_tab_sid,
		in_col_sid						=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'COMPANY_TYPE'),
		in_dedupe_field_id				=> chain_pkg.FLD_COMPANY_COMPANY_TYPE,
		out_dedupe_mapping_id			=> v_mapping_id
	);
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id			=> -1,
		in_dedupe_staging_link_id		=> v_staging_link_id,
		in_tab_sid						=> v_tab_sid,
		in_col_sid						=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'PURCHASER_COMPANY_SID'),
		in_dedupe_field_id				=> chain_pkg.FLD_COMPANY_PURCHASER_COMPANY,
		out_dedupe_mapping_id			=> v_mapping_id
	);
END;

PROCEDURE SetupMatchingRules(
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
		in_dedupe_match_type_id		=> in_dedupe_match_type_id,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);
END;

PROCEDURE SetupNoMatchAutoCreateSource
AS
BEGIN
	SetupImportSource(chain_pkg.AUTO_CREATE);
	SetupSourceLinkAndMappings;
	SetupMatchingRules(chain_pkg.DEDUPE_AUTO);

	-- expected no match,
	-- new site 'NPSL Ltd' is created
	-- and v_vendor_sid_1 => 'NPSL Ltd' company type relationship is established
	AddStagingRow(
		in_batch_num				=> 1,
		in_vendor_num				=> '1A',
		in_vendor_name				=> 'NPSL Ltd',
		in_city						=> 'Cambridge',
		in_postal_code				=> 'CB24 7AB',
		in_country					=> 'gb',
		in_purchaser_company_sid	=> v_vendor_sid_1,
		in_company_type				=> 'SITE'
	);
END;

PROCEDURE TestNoMatchAutoCreate
AS
	v_processed_record_ids			security_pkg.T_SID_IDS;
	v_created_company_sid			NUMBER;
BEGIN
	SetupNoMatchAutoCreateSource;

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_import_source_id,
		in_reference				=> '1A',
		in_batch_num				=> 1,
		out_processed_record_ids	=> v_processed_record_ids
	);

	TestNoMatchExpectNone(v_processed_record_ids(1));
	TestNoMatchExpectCreate(v_processed_record_ids(1));
	
	SELECT created_company_sid
	  INTO v_created_company_sid
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = v_processed_record_ids(1);

	TestRelationshipExists(v_vendor_sid_1, v_created_company_sid);
END;

PROCEDURE SetupOneMatchAutoMergeSource
AS
BEGIN
	SetupImportSource(chain_pkg.ACTION_CREATE);
	SetupSourceLinkAndMappings;
	SetupMatchingRules(chain_pkg.DEDUPE_AUTO);

	-- expected to match with v_site_sid_1,
	-- city is set to 'Cambridge'
	-- and v_vendor_sid_2 => v_site_sid_1 company type relationship is established
	AddStagingRow(
		in_batch_num				=> 1,
		in_vendor_num				=> '1B',
		in_vendor_name				=> 'UK Site Ltd',
		in_city						=> 'Cambridge',
		in_postal_code				=> 'CB24 8AX',
		in_country					=> 'gb',
		in_purchaser_company_sid	=> v_vendor_sid_2,
		in_company_type				=> 'SITE'
	);
	-- lower system managed import source priority for merging
	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;
END;

PROCEDURE TestOneMatchAutoMerge
AS
	v_processed_record_ids			security_pkg.T_SID_IDS;
	v_city							VARCHAR2(255);
BEGIN
	SetupOneMatchAutoMergeSource;

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_import_source_id,
		in_reference				=> '1B',
		in_batch_num				=> 1,
		out_processed_record_ids	=> v_processed_record_ids
	);

	TestPotentialMatches(v_processed_record_ids(1), T_NUMBER_LIST(v_site_sid_1));

	SELECT city
	  INTO v_city
	  FROM company
	 WHERE company_sid = v_site_sid_1;

	csr.unit_test_pkg.AssertAreEqual('Cambridge', v_city, 'Merged city field not equal! Expected: Cambridge'||' got: '||v_city);
	TestRelationshipExists(v_vendor_sid_2, v_site_sid_1);
END;

PROCEDURE SetupNoMatchManualCreateSource
AS
BEGIN
	SetupImportSource(chain_pkg.MANUAL_REVIEW);
	SetupSourceLinkAndMappings;
	SetupMatchingRules(chain_pkg.DEDUPE_AUTO);

	-- expected no match,
	-- no site is created
	-- and no company type relationshipp is established
	AddStagingRow(
		in_batch_num				=> 1,
		in_vendor_num				=> '1A',
		in_vendor_name				=> 'NPSL Ltd',
		in_city						=> 'Cambridge',
		in_postal_code				=> 'CB24 7AB',
		in_country					=> 'gb',
		in_purchaser_company_sid	=> v_vendor_sid_1,
		in_company_type				=> 'SITE'
	);
END;

PROCEDURE TestNoMatchManualCreate
AS
	v_processed_record_ids			security_pkg.T_SID_IDS;
	v_created_company_sid			NUMBER;
BEGIN
	SetupNoMatchManualCreateSource;

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_import_source_id,
		in_reference				=> '1A',
		in_batch_num				=> 1,
		out_processed_record_ids	=> v_processed_record_ids
	);

	TestNoMatchPromoted(v_processed_record_ids(1));

	-- Merge/create manually
	company_dedupe_pkg.MergeRecord(
		in_processed_record_id 		=> v_processed_record_ids(1),
		in_company_sid 				=> NULL
	);
	
	SELECT created_company_sid
	  INTO v_created_company_sid
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = v_processed_record_ids(1);

	TestRelationshipExists(v_vendor_sid_1, v_created_company_sid);
END;

PROCEDURE SetupOneMatchManualMergeSource
AS
BEGIN
	SetupImportSource(chain_pkg.MANUAL_REVIEW);
	SetupSourceLinkAndMappings;
	SetupMatchingRules(chain_pkg.DEDUPE_MANUAL);

	-- expected to match with v_site_sid_1,
	-- rule set is set to manual so city is not set to 'Cambridge'
	-- and v_vendor_sid_2 => v_site_sid_1 company type relationship is not established
	AddStagingRow(
		in_batch_num				=> 1,
		in_vendor_num				=> '1B',
		in_vendor_name				=> 'UK Site Ltd',
		in_city						=> 'Cambridge',
		in_postal_code				=> 'CB24 8AX',
		in_country					=> 'gb',
		in_purchaser_company_sid	=> v_vendor_sid_2,
		in_company_type				=> 'SITE'
	);
	-- lower system managed import source priority for merging
	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;
END;

PROCEDURE TestMatchManualMerge
AS
	v_processed_record_ids			security_pkg.T_SID_IDS;
	v_city							VARCHAR2(255);
BEGIN
	SetupOneMatchManualMergeSource;

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_import_source_id,
		in_reference				=> '1B',
		in_batch_num				=> 1,
		out_processed_record_ids	=> v_processed_record_ids
	);

	TestNoMatchPromoted(v_processed_record_ids(1));

	-- Merge/create manually
	company_dedupe_pkg.MergeRecord(
		in_processed_record_id 		=> v_processed_record_ids(1),
		in_company_sid 				=> v_site_sid_1
	);
	
	SELECT city
	  INTO v_city
	  FROM company
	 WHERE company_sid = v_site_sid_1;

	csr.unit_test_pkg.AssertAreEqual('Cambridge', v_city, 'Merged city field not equal! Expected: Cambridge'||' got: '||v_city);
	TestRelationshipExists(v_vendor_sid_2, v_site_sid_1);
END;

PROCEDURE SetupNoMatchCreateCompFailRel
AS
BEGIN
	SetupImportSource(chain_pkg.AUTO_CREATE);
	SetupSourceLinkAndMappings;
	SetupMatchingRules(chain_pkg.DEDUPE_AUTO);

	-- expected no match,
	-- new vendor 'NPSL Ltd' is created
	-- and v_vendor_sid_1 => 'NPSL Ltd' company type relationship is not established (vendor => vendor company type relationship is not allowed)
	AddStagingRow(
		in_batch_num				=> 1,
		in_vendor_num				=> '1A',
		in_vendor_name				=> 'NPSL Ltd',
		in_city						=> 'Cambridge',
		in_postal_code				=> 'CB24 7AB',
		in_country					=> 'gb',
		in_purchaser_company_sid	=> v_vendor_sid_1,
		in_company_type				=> 'VENDOR'
	);
END;

PROCEDURE TestNoMatchCreateCompFailRel
AS
	v_processed_record_ids			security_pkg.T_SID_IDS;
	v_created_company_sid			NUMBER;
BEGIN
	SetupNoMatchCreateCompFailRel;

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_import_source_id,
		in_reference				=> '1A',
		in_batch_num				=> 1,
		out_processed_record_ids	=> v_processed_record_ids
	);

	TestNoMatchExpectNone(v_processed_record_ids(1));
	TestNoMatchExpectCreate(v_processed_record_ids(1));

	SELECT created_company_sid
	  INTO v_created_company_sid
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = v_processed_record_ids(1);

	TestRelationshipDoesNotExist(v_vendor_sid_1, v_created_company_sid);
END;

PROCEDURE SetupOneMatchMergeCompFailRel
AS
BEGIN
	SetupImportSource(chain_pkg.ACTION_CREATE);
	SetupSourceLinkAndMappings;
	SetupMatchingRules(chain_pkg.DEDUPE_AUTO);

	-- expected to match with v_vendor_sid_3,
	-- city is set to 'Cabiate (CO)'
	-- and v_vendor_sid_2 => v_vendor_sid_3 company type relationship is not established (vendor => vendor company type relationship is not allowed)
	AddStagingRow(
		in_batch_num				=> 1,
		in_vendor_num				=> '1B',
		in_vendor_name				=> 'UL Italia',
		in_city						=> 'Cabiate (CO)',
		in_postal_code				=> '22060',
		in_country					=> 'it',
		in_purchaser_company_sid	=> v_vendor_sid_2,
		in_company_type				=> 'VENDOR'
	);
	-- lower system managed import source priority for merging
	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;
END;

PROCEDURE TestOneMatchMergeCompFailRel
AS
	v_processed_record_ids			security_pkg.T_SID_IDS;
	v_city							VARCHAR2(255);
BEGIN
	SetupOneMatchMergeCompFailRel;

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_import_source_id,
		in_reference				=> '1B',
		in_batch_num				=> 1,
		out_processed_record_ids	=> v_processed_record_ids
	);

	TestPotentialMatches(v_processed_record_ids(1), T_NUMBER_LIST(v_vendor_sid_3));
	
	SELECT city
	  INTO v_city
	  FROM company
	 WHERE company_sid = v_vendor_sid_3;

	csr.unit_test_pkg.AssertAreEqual('Cabiate (CO)', v_city, 'Merged city field not equal! Expected: Cabiate (CO)'||' got: '||v_city);

	TestRelationshipDoesNotExist(v_vendor_sid_2, v_vendor_sid_3);
END;

PROCEDURE SetupLoopRelSource
AS
BEGIN
	SetupImportSource(chain_pkg.ACTION_CREATE);
	SetupSourceLinkAndMappings;
	SetupMatchingRules(chain_pkg.DEDUPE_AUTO);

	-- expected to match with v_site_sid_1,
	-- city is set to 'Cambridge'
	-- and v_vendor_sid_2 => v_site_sid_1 company type relationship is established
	AddStagingRow(
		in_batch_num				=> 1,
		in_vendor_num				=> '1C',
		in_vendor_name				=> 'UL Site Ltd',
		in_city						=> 'California',
		in_postal_code				=> '90210',
		in_country					=> 'us',
		in_purchaser_company_sid	=> v_vendor_sid_2,
		in_company_type				=> 'SITE'
	);
	-- lower system managed import source priority for merging
	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;
END;

PROCEDURE TestLoopRelMerge
AS
	v_processed_record_ids			security_pkg.T_SID_IDS;
	v_city							VARCHAR2(255);
	v_count							NUMBER;
BEGIN
	SetupLoopRelSource;

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_import_source_id,
		in_reference				=> '1C',
		in_batch_num				=> 1,
		out_processed_record_ids	=> v_processed_record_ids
	);

	TestPotentialMatches(v_processed_record_ids(1), T_NUMBER_LIST(v_site_sid_3));

	SELECT city
	  INTO v_city
	  FROM company
	 WHERE company_sid = v_site_sid_3;

	csr.unit_test_pkg.AssertAreEqual('California', v_city, 'Merged city field not equal! Expected: California got: '||v_city);

	TestDirectionalRelationship(v_vendor_sid_2, v_site_sid_3, 0);
	TestDirectionalRelationship(v_site_sid_3, v_vendor_sid_2, 1);

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_ids(1)
	   AND dedupe_field_id = chain_pkg.FLD_COMPANY_PURCHASER_COMPANY
	   AND new_raw_val = v_vendor_sid_2;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Loop error message not found.');
END;

PROCEDURE SetupIndirectLoopRelSource
AS
BEGIN
	SetupImportSource(chain_pkg.ACTION_CREATE);
	SetupSourceLinkAndMappings;
	SetupMatchingRules(chain_pkg.DEDUPE_AUTO);

	-- expected to match with v_site_sid_1,
	-- city is set to 'Cambridge'
	-- and v_vendor_sid_2 => v_site_sid_1 company type relationship is established
	AddStagingRow(
		in_batch_num				=> 1,
		in_vendor_num				=> '1D',
		in_vendor_name				=> 'UK Site Ltd',
		in_city						=> 'London',
		in_postal_code				=> 'CB24 8AX',
		in_country					=> 'gb',
		in_purchaser_company_sid	=> v_vendor_sid_1,
		in_company_type				=> 'SITE'
	);
	-- lower system managed import source priority for merging
	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;
END;

PROCEDURE TestIndirectLoopRelMerge
AS
	v_processed_record_ids			security_pkg.T_SID_IDS;
	v_city							VARCHAR2(255);
	v_count							NUMBER;
BEGIN
	SetupIndirectLoopRelSource;

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_import_source_id,
		in_reference				=> '1D',
		in_batch_num				=> 1,
		out_processed_record_ids	=> v_processed_record_ids
	);

	TestPotentialMatches(v_processed_record_ids(1), T_NUMBER_LIST(v_site_sid_1));

	SELECT city
	  INTO v_city
	  FROM company
	 WHERE company_sid = v_site_sid_1;

	csr.unit_test_pkg.AssertAreEqual('London', v_city, 'Merged city field not equal! Expected: London got: '||v_city);

	TestDirectionalRelationship(v_site_sid_1, v_vendor_sid_1, 0);

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_ids(1)
	   AND dedupe_field_id = chain_pkg.FLD_COMPANY_PURCHASER_COMPANY
	   AND new_raw_val = v_vendor_sid_1;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Loop error message not found.');
END;
END;
/
