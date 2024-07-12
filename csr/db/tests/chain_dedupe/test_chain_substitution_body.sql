CREATE OR REPLACE PACKAGE BODY chain.test_chain_substitution_pkg AS

v_site_name					VARCHAR2(200);
v_vendor_ct_id				NUMBER;
v_top_company_sid			NUMBER;
v_import_source_id			NUMBER;
v_staging_link_id			NUMBER;
v_dedupe_rule_set_id		NUMBER;

-- mappings
v_mapping_name_id			NUMBER;
v_mapping_city_id			NUMBER;
v_mapping_postcode_id		NUMBER;
v_mapping_address_id		NUMBER;
v_mapping_country_id		NUMBER;
v_mapping_state_id			NUMBER;
v_mapping_website_id		NUMBER;
v_mapping_comp_email_id		NUMBER;


PROCEDURE SetUpCityPairsToTry
AS
BEGIN

	INSERT INTO temp_city_matching (id, staging_city, record_city) 
		 VALUES (1, 'Ely', 'Durham');
	INSERT INTO temp_city_matching (id, staging_city, record_city) 
		 VALUES (2, ' Bristol', 'BRistol ');
	INSERT INTO temp_city_matching (id, staging_city, record_city) 
		 VALUES (3, 'Ex'||UNISTR('\00EB')||'ter', 'Exet'||UNISTR('\00EB')||'r');
	INSERT INTO temp_city_matching (id, staging_city, record_city) 
		 VALUES (4, 'Hull', 'Hull');
	INSERT INTO temp_city_matching (id, staging_city, record_city) 
		 VALUES (5, ' Mumba'||UNISTR('\00EF')||'', 'MuMb'||UNISTR('\0101')||'i'||' ');
	INSERT INTO temp_city_matching (id, staging_city, record_city) 
		 VALUES (6, 'C'||UNISTR('\00E6')||'logn'||UNISTR('\00EB'), 'K'||UNISTR('\00E6')||'ln');
	INSERT INTO temp_city_matching (id, staging_city, record_city) 
		 VALUES (7, 'Ist'||UNISTR('\0101')||'nbul', 'Constanstin'||UNISTR('\00E6')||'ple');
	INSERT INTO temp_city_matching (id, staging_city, record_city) 
		 VALUES (8, 'H'||UNISTR('\016B')||'ntly', 'Milton of Str'||UNISTR('\0101')||'thbogie');
	INSERT INTO temp_city_matching (id, staging_city, record_city) 
		 VALUES (9, ' Lundenw'||UNISTR('\00EF')||'c', 'L'||UNISTR('\00E6')||'ndoN ');
	INSERT INTO temp_city_matching (id, staging_city, record_city) 
		 VALUES (10, 'Differentville', 'Differentville');
	INSERT INTO temp_city_matching (id, staging_city, record_city) 
		 VALUES (11, 'Differentville', 'Altville');
	INSERT INTO temp_city_matching (id, staging_city, record_city) 
		 VALUES (12, 'Foo', 'Bar');
	-- nothing done with this - just their to check it's not picked up
	INSERT INTO temp_city_matching (id, staging_city, record_city) 
		 VALUES (13, 'Unmatchington', 'NoMatchVille');

END;

PROCEDURE SetUpPPRules
AS
	v_dedupe_preproc_rule_id	NUMBER;
	v_dedupe_field_ids			security_pkg.T_SID_IDS;
	v_countries					security_pkg.T_VARCHAR2_ARRAY;
	
BEGIN
	-- CITY fields
	INSERT INTO temp_pp_rule (pattern, replacement, apply_to_field, apply_to_country) VALUES (UNISTR('\00E6'), 'o', chain_pkg.FLD_COMPANY_CITY, NULL);
	INSERT INTO temp_pp_rule (pattern, replacement, apply_to_field, apply_to_country) VALUES (UNISTR('\00EF'), 'i', chain_pkg.FLD_COMPANY_CITY, NULL);
	INSERT INTO temp_pp_rule (pattern, replacement, apply_to_field, apply_to_country) VALUES (UNISTR('\016B'), 'u', chain_pkg.FLD_COMPANY_CITY, NULL);
	
	-- ALL fields
	INSERT INTO temp_pp_rule (pattern, replacement, apply_to_field, apply_to_country) VALUES (UNISTR('\00EB'), 'e', NULL, NULL);
	INSERT INTO temp_pp_rule (pattern, replacement, apply_to_field, apply_to_country) VALUES (UNISTR('\0101'), 'a', NULL, NULL);
	
	-- COMP NAME fields
	INSERT INTO temp_pp_rule (pattern, replacement, apply_to_field, apply_to_country) VALUES ('a', 'x', chain_pkg.FLD_COMPANY_NAME, NULL);
	INSERT INTO temp_pp_rule (pattern, replacement, apply_to_field, apply_to_country) VALUES ('e', 'x', chain_pkg.FLD_COMPANY_NAME, NULL);
	INSERT INTO temp_pp_rule (pattern, replacement, apply_to_field, apply_to_country) VALUES ('i', 'x', chain_pkg.FLD_COMPANY_NAME, NULL);
	INSERT INTO temp_pp_rule (pattern, replacement, apply_to_field, apply_to_country) VALUES ('o', 'x', chain_pkg.FLD_COMPANY_NAME, NULL);
	INSERT INTO temp_pp_rule (pattern, replacement, apply_to_field, apply_to_country) VALUES ('u', 'x', chain_pkg.FLD_COMPANY_NAME, NULL);
	
	-- GB country
	INSERT INTO temp_pp_rule (pattern, replacement, apply_to_field, apply_to_country) VALUES ('a', 'x', NULL, 'us');
	INSERT INTO temp_pp_rule (pattern, replacement, apply_to_field, apply_to_country) VALUES ('e', 'x', NULL, 'us');
	INSERT INTO temp_pp_rule (pattern, replacement, apply_to_field, apply_to_country) VALUES ('i', 'x', NULL, 'us');
	INSERT INTO temp_pp_rule (pattern, replacement, apply_to_field, apply_to_country) VALUES ('o', 'x', NULL, 'us');
	INSERT INTO temp_pp_rule (pattern, replacement, apply_to_field, apply_to_country) VALUES ('u', 'x', NULL, 'us');

	FOR r IN (
		SELECT rownum rn, pattern, replacement, apply_to_field, apply_to_country 
		  FROM (
			SELECT pattern, replacement, apply_to_field, apply_to_country
			  FROM temp_pp_rule
			 ORDER BY apply_to_field, pattern
		  )
	) LOOP
		v_dedupe_field_ids(1) := r.apply_to_field;
		v_countries(1) := r.apply_to_country;
		
		dedupe_admin_pkg.SavePreProcRule(
			in_dedupe_preproc_rule_id 	=> NULL,
			in_pattern					=> r.pattern, 
			in_replacement				=> r.replacement,
			in_run_order				=> r.rn,
			in_dedupe_field_ids			=> v_dedupe_field_ids,
			in_countries				=> v_countries,
			out_dedupe_preproc_rule_id	=> v_dedupe_preproc_rule_id
		);
	END LOOP;
		
END;

PROCEDURE SetUpSubs
AS
BEGIN
	INSERT INTO dedupe_sub (dedupe_sub_id, pattern, substitution) VALUES (cms.item_id_seq.nextval, 'C'||UNISTR('\00E6')||'logn'||UNISTR('\00EB'), 'K'||UNISTR('\00E6')||'ln');
	INSERT INTO dedupe_sub (dedupe_sub_id, pattern, substitution) VALUES (cms.item_id_seq.nextval, 'Mumba'||UNISTR('\00EF')||' ', 'Bombay');
	INSERT INTO dedupe_sub (dedupe_sub_id, pattern, substitution) VALUES (cms.item_id_seq.nextval, 'Istanbul', 'Constanstinopl'||UNISTR('\00EB'));
	INSERT INTO dedupe_sub (dedupe_sub_id, pattern, substitution) VALUES (cms.item_id_seq.nextval, 'Hull', 'Hell');
	INSERT INTO dedupe_sub (dedupe_sub_id, pattern, substitution) VALUES (cms.item_id_seq.nextval, 'L'||UNISTR('\00E6')||'ndon', 'Lundenw'||UNISTR('\00EF')||'c');
	INSERT INTO dedupe_sub (dedupe_sub_id, pattern, substitution) VALUES (cms.item_id_seq.nextval, 'Newcastle upon Tyne', 'Monkchester'); 
	INSERT INTO dedupe_sub (dedupe_sub_id, pattern, substitution) VALUES (cms.item_id_seq.nextval, 'Milton of Str'||UNISTR('\0101')||'thbogie', 'H'||UNISTR('\016B')||'ntly');
	INSERT INTO dedupe_sub (dedupe_sub_id, pattern, substitution) VALUES (cms.item_id_seq.nextval, 'ABCDE', '12345');
	INSERT INTO dedupe_sub (dedupe_sub_id, pattern, substitution) VALUES (cms.item_id_seq.nextval, 'D'||UNISTR('\00EF')||'fferentville', 'Altv'||UNISTR('\00EF')||'lle');
	INSERT INTO dedupe_sub (dedupe_sub_id, pattern, substitution) VALUES (cms.item_id_seq.nextval, 'Foo', 'Bar');
END;

PROCEDURE LoadStagingCompanies
AS
	v_company_sid		NUMBER;
BEGIN
	FOR r IN (
		SELECT id, staging_city
		  FROM temp_city_matching
		 ORDER BY id
	) LOOP
		test_chain_shared_dedupe_pkg.AddStagingRow(
			in_vendor_num => r.id,
			in_vendor_name => 'A Company ' || r.id,
			in_city	=> r.staging_city,
			in_country => 'gb'
		);	
	END LOOP;
END;

PROCEDURE LoadCompanies
AS
	v_company_sid		NUMBER;
BEGIN
	FOR r IN (
		SELECT id, record_city
		  FROM temp_city_matching
		 ORDER BY id
	) LOOP
		company_pkg.CreateCompany(
			in_name=> 'Company ' || r.id,
			in_country_code=> 'gb',
			in_company_type_id=> v_vendor_ct_id,
			in_sector_id=> NULL,
			out_company_sid=> v_company_sid
		);
			
		company_pkg.UpdateCompany(
			in_company_sid		=> v_company_sid,
			in_city				=> r.record_city
		);
		
		company_pkg.ActivateCompany(v_company_sid);	
		company_pkg.StartRelationship(v_top_company_sid, v_company_sid, null);
		company_pkg.ActivateRelationship(v_top_company_sid, v_company_sid);	
	END LOOP;
END;

PROCEDURE CreateNameCityRuleSet(
	out_dedupe_rule_set_id			OUT NUMBER
) AS
	v_mapping_ids					security.security_pkg.T_SID_IDS;
	v_rule_ids						security.security_pkg.T_SID_IDS;
	v_rule_type_ids					security.security_pkg.T_SID_IDS;
	v_match_thresholds				helper_pkg.T_NUMBER_ARRAY;
	
	v_count							NUMBER;
	v_unused_rule_set_id			NUMBER;
BEGIN
		--Set rule sets
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_name_id, v_mapping_city_id));

	--need arrays of dedupe_rule_id and thresholds
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_LEVENSHTEIN;
	v_rule_type_ids(2) := chain_pkg.RULE_TYPE_EXACT;
	
	v_match_thresholds(1) := 30; -- v low - we want company match to pass and all companies called "company #"
	v_match_thresholds(2) := 100;
	
	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id,
		in_description				=> 'Partial name and city with subs rule set',
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_AUTO,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> out_dedupe_rule_set_id
	);

	v_rule_type_ids.DELETE;
	v_match_thresholds.DELETE;
	
	--Set rule set - UNUSED
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_name_id));

	--need arrays of dedupe_rule_id and thresholds
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_LEVENSHTEIN;
	
	v_match_thresholds(1) := 99; -- v high - we want company match to fail and all companies called "company #"
	
	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id,
		in_description				=> 'UNUSED Partial name and city with subs rule set',
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_AUTO,
		in_rule_set_position		=> 2,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_unused_rule_set_id
	);
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_tab_sid				NUMBER;
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);

	test_chain_utils_pkg.SetupTwoTier;
	
	--do some clearing just in case
	UPDATE customer_options
	   SET enable_dedupe_preprocess = 1
	 WHERE app_sid = security_pkg.getapp;
	 
	DELETE FROM dedupe_pp_field_cntry;
	DELETE FROM dedupe_preproc_rule;
	
	v_vendor_ct_id := company_type_pkg.GetCompanyTypeId('VENDOR');
	
	v_top_company_sid := helper_pkg.getTopCompanySid;
	v_vendor_ct_id := company_type_pkg.GetCompanyTypeId('VENDOR');
	
	-- create some pre-proc rules
	SetUpPPRules;
	
	-- poke some SUBS rules into the CMS table
	SetUpSubs;
	
	-- this is just to make setup easier and each row represents a "test" match attempt
	SetUpCityPairsToTry;
	
	-- create some staging record rows
	LoadCompanies;

	-- create some companies
	LoadStagingCompanies;
	
	-- run the preproc rules on company
	-- run the preproc rules APPLYING to CITY on SUBS rules table
	dedupe_preprocess_pkg.PreprocessAllRulesForCompanies;
	dedupe_preprocess_pkg.PreprocessAllRulesForSubst;
	
	-- setup a basic company integration
	test_chain_shared_dedupe_pkg.CreateSimpleImportSource(
		in_no_match_action_id => chain_pkg.DEDUPE_AUTO,
		out_import_source_id => v_import_source_id
	);	
	
	v_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'COMPANY_STAGING');	
	test_chain_shared_dedupe_pkg.CreateSimpleLinkAndMappings(
		in_tab_sid => v_tab_sid,
		in_import_source_id => v_import_source_id, 
		out_staging_link_id	=> v_staging_link_id,
		out_mapping_name_id => v_mapping_name_id,		
		out_mapping_city_id => v_mapping_city_id,		
		out_mapping_postcode_id => v_mapping_postcode_id,		
		out_mapping_address_id => v_mapping_address_id,		
		out_mapping_country_id => v_mapping_country_id,		
		out_mapping_state_id => v_mapping_state_id,			
		out_mapping_website_id => v_mapping_website_id,		
		out_mapping_comp_email_id => v_mapping_comp_email_id	
	);
	
	-- create a rule setup
	CreateNameCityRuleSet(
		out_dedupe_rule_set_id => v_dedupe_rule_set_id
	);
END;

PROCEDURE SetSite(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
END;

PROCEDURE TearDownFixture
AS
BEGIN
	FOR r IN (
		SELECT lookup_key
		  FROM import_source
		 WHERE app_sid = security_pkg.getapp
		   AND is_owned_by_system = 0
	)
	LOOP
		test_chain_utils_pkg.TearDownImportSource(r.lookup_key);
	END LOOP;
	
	UPDATE customer_options
	   SET enable_dedupe_preprocess = 0
	 WHERE app_sid = security_pkg.getapp;
	 
	DELETE FROM temp_pp_rule;
	DELETE FROM temp_city_matching;
	DELETE FROM dedupe_sub;
	 
	DELETE FROM dedupe_pp_field_cntry;
	DELETE FROM dedupe_preproc_rule;

	test_chain_utils_pkg.TearDownTwoTier;
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
	
PROCEDURE TestMatch (
	in_test_id						NUMBER,
	in_matches_expected				T_NUMBER_LIST,
	in_processed_record_ids			OUT security_pkg.T_SID_IDS,
	in_created_company_sid			OUT security_pkg.T_SID_ID,
	in_matched_company_sids			OUT security_pkg.T_SID_IDS
)
AS
BEGIN
	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_staging_link_id, 
		in_reference				=> TO_CHAR(in_test_id),
		out_processed_record_ids	=>	in_processed_record_ids,
		out_created_company_sid 	=>	in_created_company_sid,
		out_matched_company_sids	=>	in_matched_company_sids
	);
	
	test_chain_shared_dedupe_pkg.TestPotentialMatches(
		in_processed_record_ids(1),
		in_matches_expected,
		v_dedupe_rule_set_id
	);
END;

PROCEDURE Test_SingleMatchNoSubNoPP 
AS
	v_created_company_sid	security.security_pkg.T_SID_ID;
	v_matched_company_sids	security.security_pkg.T_SID_IDS;
	v_processed_record_ids	security_pkg.T_SID_IDS;
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	
	TestMatch(
		2, 
		T_NUMBER_LIST(test_chain_utils_pkg.GetChainCompanySid('Company 2', 'gb')), 
		v_processed_record_ids, 
		v_created_company_sid, 
		v_matched_company_sids
	);	
	TestMatch(
		4, 
		T_NUMBER_LIST(test_chain_utils_pkg.GetChainCompanySid('Company 4', 'gb')), 
		v_processed_record_ids, 
		v_created_company_sid, 
		v_matched_company_sids
	);	

END;

PROCEDURE Test_SingleMatchNoSubWithPP 
AS
	v_created_company_sid	security.security_pkg.T_SID_ID;
	v_matched_company_sids	security.security_pkg.T_SID_IDS;
	v_processed_record_ids	security_pkg.T_SID_IDS;
BEGIN 	
	security.user_pkg.logonadmin(v_site_name);
	
	TestMatch(
		3, 
		T_NUMBER_LIST(test_chain_utils_pkg.GetChainCompanySid('Company 3', 'gb')), 
		v_processed_record_ids, 
		v_created_company_sid, 
		v_matched_company_sids
	);	
	TestMatch(
		5, 
		T_NUMBER_LIST(test_chain_utils_pkg.GetChainCompanySid('Company 5', 'gb')), 
		v_processed_record_ids, 
		v_created_company_sid, 
		v_matched_company_sids
	);		
END;

PROCEDURE Test_NoMatch
AS
	v_created_company_sid	security.security_pkg.T_SID_ID;
	v_matched_company_sids	security.security_pkg.T_SID_IDS;
	v_processed_record_ids	security_pkg.T_SID_IDS;
BEGIN 	
	security.user_pkg.logonadmin(v_site_name);
	
	TestMatch(
		1, 
		T_NUMBER_LIST(), 
		v_processed_record_ids, 
		v_created_company_sid, 
		v_matched_company_sids
	);
END;

PROCEDURE Test_SingleMatchWithSubNoPP
AS
	v_created_company_sid	security.security_pkg.T_SID_ID;
	v_matched_company_sids	security.security_pkg.T_SID_IDS;
	v_processed_record_ids	security_pkg.T_SID_IDS;
BEGIN 	
	security.user_pkg.logonadmin(v_site_name);
	
	TestMatch(
		12, 
		T_NUMBER_LIST(test_chain_utils_pkg.GetChainCompanySid('Company 12', 'gb')), 
		v_processed_record_ids, 
		v_created_company_sid, 
		v_matched_company_sids
	);
END;

PROCEDURE Test_SingleMatchWithSubWithPP
AS
	v_created_company_sid	security.security_pkg.T_SID_ID;
	v_matched_company_sids	security.security_pkg.T_SID_IDS;
	v_processed_record_ids	security_pkg.T_SID_IDS;
BEGIN 	
	security.user_pkg.logonadmin(v_site_name);
	
	TestMatch(
		6, 
		T_NUMBER_LIST(test_chain_utils_pkg.GetChainCompanySid('Company 6', 'gb')), 
		v_processed_record_ids, 
		v_created_company_sid, 
		v_matched_company_sids
	);
	
	TestMatch(
		7, 
		T_NUMBER_LIST(test_chain_utils_pkg.GetChainCompanySid('Company 7', 'gb')), 
		v_processed_record_ids, 
		v_created_company_sid, 
		v_matched_company_sids
	);
	
	TestMatch(
		8, 
		T_NUMBER_LIST(test_chain_utils_pkg.GetChainCompanySid('Company 8', 'gb')), 
		v_processed_record_ids, 
		v_created_company_sid, 
		v_matched_company_sids
	);
	
	TestMatch(
		9, 
		T_NUMBER_LIST(test_chain_utils_pkg.GetChainCompanySid('Company 9', 'gb')), 
		v_processed_record_ids, 
		v_created_company_sid, 
		v_matched_company_sids
	);
END;

PROCEDURE Test_MultiMatchWithWithoutSub
AS
	v_created_company_sid	security.security_pkg.T_SID_ID;
	v_matched_company_sids	security.security_pkg.T_SID_IDS;
	v_processed_record_ids	security_pkg.T_SID_IDS;
BEGIN 	
	security.user_pkg.logonadmin(v_site_name);
	
	TestMatch(
		10, 
		T_NUMBER_LIST(test_chain_utils_pkg.GetChainCompanySid('Company 10', 'gb'), test_chain_utils_pkg.GetChainCompanySid('Company 11', 'gb')), 
		v_processed_record_ids, 
		v_created_company_sid, 
		v_matched_company_sids
	);
	TestMatch(
		11, 
		T_NUMBER_LIST(test_chain_utils_pkg.GetChainCompanySid('Company 10', 'gb'), test_chain_utils_pkg.GetChainCompanySid('Company 11', 'gb')), 
		v_processed_record_ids, 
		v_created_company_sid, 
		v_matched_company_sids
	);
END;

END;
/
