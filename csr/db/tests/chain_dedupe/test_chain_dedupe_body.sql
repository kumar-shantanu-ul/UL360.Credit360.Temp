CREATE OR REPLACE PACKAGE BODY chain.test_chain_dedupe_pkg AS

v_site_name						VARCHAR2(200);
v_source_id_sap					NUMBER;
v_source_id_bsci				NUMBER;
v_source_id_try					NUMBER;
v_dedupe_staging_link_id_sap	NUMBER;
v_dedupe_staging_link_id_bsci	NUMBER;
v_dedupe_staging_link_id_try	NUMBER;

v_dedupe_rule_id_country_name	NUMBER;
v_dedupe_rule_id_post_act_ct	NUMBER;
v_dedupe_rule_id_ref			NUMBER;
v_dedupe_rule_id_sect_addr		NUMBER;
v_dedupe_rule_id_tg_addr		NUMBER;

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

-- private
PROCEDURE AddSAPStagingRow(
	in_vendor_num		IN VARCHAR2,
	in_vendor_name		IN VARCHAR2,
	in_city				IN VARCHAR2,
	in_postal_code		IN VARCHAR2,
	in_street			IN VARCHAR2,
	in_company_type		IN VARCHAR2,
	in_country			IN VARCHAR2,
	in_activated_dtm	IN DATE,
	in_state			IN VARCHAR2,
	in_website			IN VARCHAR2,
	in_sector			IN VARCHAR2,
	in_facility_type	IN VARCHAR2,
	in_parent_company	IN VARCHAR2 DEFAULT NULL,
	in_company_secondary_ref IN VARCHAR2 DEFAULT NULL,
	in_active			IN NUMBER DEFAULT NULL,
	in_email			IN VARCHAR DEFAULT NULL,
	in_deactivated_dtm	IN DATE DEFAULT NULL,
	in_ownership_type	IN VARCHAR2 DEFAULT NULL
)
AS
BEGIN
	EXECUTE IMMEDIATE ('
		INSERT INTO rag.sap_company_staging(
			sap_company_staging_id,
			vendor_num,
			vendor_name,
			city,
			postal_code,
			street,
			company_type,
			country,
			activated_dtm,
			state,
			website,
			sector,
			facility_type,
			parent_company,
			company_secondary_ref,
			active,
			email,
			deactivated_dtm
		)
		VALUES(
			cms.item_id_seq.nextval,
			:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13,:14,:15,:16,:17
		)'
	)
	USING in_vendor_num, in_vendor_name, in_city, in_postal_code, in_street, in_company_type,
	in_country, in_activated_dtm, in_state, in_website, in_sector, in_facility_type, in_parent_company,
	in_company_secondary_ref, in_active, in_email, in_deactivated_dtm;
END;

PROCEDURE AddBSCIStagingRow(
	in_vendor_num		IN VARCHAR2,
	in_vendor_name		IN VARCHAR2,
	in_company_type		IN VARCHAR2,
	in_country			IN VARCHAR2,
	in_postal_code		IN VARCHAR2,
	in_website			IN VARCHAR2,
	in_sector			IN VARCHAR2,
	in_facility_type	IN VARCHAR2,
	in_ownership_type	IN VARCHAR2,
	in_active			IN NUMBER,
	in_address			IN VARCHAR2
)
AS
BEGIN
	EXECUTE IMMEDIATE ('
		INSERT INTO rag.bsci_company_staging(
			bsci_company_staging_id,
			bsci_vendor_num,
			vendor_name,
			company_type,
			country,
			postcode,
			website,
			sector,
			facility_type,
			ownership_type,
			is_active,
			address
		)
		VALUES(
			cms.item_id_seq.nextval,
			:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11
		)'
	)
	USING in_vendor_num, in_vendor_name, in_company_type, in_country, in_postal_code,
		in_website, in_sector, in_facility_type, in_ownership_type, in_active, in_address;
END;

PROCEDURE AddTertiaryStagingRow(
	in_vendor_num		IN VARCHAR2,
	in_vendor_name		IN VARCHAR2,
	in_company_type		IN VARCHAR2,
	in_country			IN VARCHAR2,
	in_postal_code		IN VARCHAR2,
	in_website			IN VARCHAR2,
	in_sector			IN VARCHAR2,
	in_facility_type	IN VARCHAR2,
	in_ownership_type	IN VARCHAR2,
	in_active			IN NUMBER,
	in_address			IN VARCHAR2
)
AS
BEGIN
	EXECUTE IMMEDIATE ('
		INSERT INTO rag.tertiary_company_staging(
			try_company_staging_id,
			tertiary_vendor_num,
			vendor_name,
			company_type,
			country,
			postcode,
			website,
			sector,
			facility_type,
			ownership_type,
			is_active,
			address
		)
		VALUES(
			cms.item_id_seq.nextval,
			:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11
		)'
	)
	USING in_vendor_num, in_vendor_name, in_company_type, in_country, in_postal_code,
		in_website, in_sector, in_facility_type, in_ownership_type, in_active, in_address;
END;

--1st rule (SAP):
--company_staging.vendor_name => company_name
--company_staging.country=> Country
PROCEDURE TestMatch_NameCountryRule
AS
	v_results 				security.T_SID_TABLE;
	v_company_ref			VARCHAR(255);
	v_rule_id				NUMBER;
	v_resulted_sid			NUMBER;
	v_expected_company_sid	NUMBER;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	--1st test case match for 'Eco-Products, Inc - BENZSTRASSE, 'de'
	v_results := company_dedupe_pkg.TestFindMatchesForRuleSet(
		in_rule_set_id				=> v_dedupe_rule_id_country_name,
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_sap,
		in_staging_tab_schema		=> 'RAG',
		in_staging_tab_name			=> 'SAP_COMPANY_STAGING',
		in_staging_id_col_name		=> 'VENDOR_NUM',
		in_reference				=> '20009729'
	);

	IF v_results IS NULL OR v_results.count <> 1 THEN
		csr.unit_test_pkg.TestFail('Expected 1 exact match');
	END IF;

	v_expected_company_sid := test_chain_utils_pkg.GetChainCompanySid('Eco-Products, Inc - BENZSTRASSE', 'de');
	csr.unit_test_pkg.AssertAreEqual(v_expected_company_sid, v_results(1), 'Resulted matched company is not the expected one');

	--2nd test case no match for AGRARFROST GMBH..., de
	v_results := company_dedupe_pkg.TestFindMatchesForRuleSet(
		in_rule_set_id				=> v_dedupe_rule_id_country_name,
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_sap,
		in_staging_tab_schema		=> 'RAG',
		in_staging_tab_name			=> 'SAP_COMPANY_STAGING',
		in_staging_id_col_name		=> 'VENDOR_NUM',
		in_reference				=> '99086052'
	);

	IF v_results IS NOT NULL THEN
		csr.unit_test_pkg.TestFail('Expected zero matches');
	END IF;
END;

--2nd rule (SAP):
--=>company_staging.vendor_num => ref (SAP1_COMPANY_REF)
PROCEDURE TestMatch_RefRule
AS
	v_results 			security.T_SID_TABLE;
	v_company_ref		VARCHAR(255);
	v_rule_id			NUMBER;
	v_resulted_sid		NUMBER;

	v_expected_company_sid		NUMBER;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	--test case match for AGRARFROST GMBH.., dee
	v_results := company_dedupe_pkg.TestFindMatchesForRuleSet(
		in_rule_set_id				=> v_dedupe_rule_id_ref,
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_sap,
		in_staging_tab_schema		=> 'RAG',
		in_staging_tab_name			=> 'SAP_COMPANY_STAGING',
		in_staging_id_col_name		=> 'VENDOR_NUM',
		in_reference				=> '99086052'
	);

	IF v_results IS NULL OR v_results.count <> 1 THEN
		csr.unit_test_pkg.TestFail('Expected 1 exact match');
	END IF;

	v_expected_company_sid := test_chain_utils_pkg.GetChainCompanySid('Eco, inc', 'us');
	csr.unit_test_pkg.AssertAreEqual(v_expected_company_sid, v_results(1), 'Resulted matched company is not the expected one');
END;

--3rd rule (SAP):
--company_staging.company_type => company_type
--company_staging.postal_code => postcode
--company_staging.activated_dtm => activated_date
PROCEDURE TestMatch_TypePostDateRule
AS
	v_results 			security.T_SID_TABLE;
	v_expected_company_sid		NUMBER;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	--test case ('AL.M.ME. S.A.', gr) match
	v_results := company_dedupe_pkg.TestFindMatchesForRuleSet(
		in_rule_set_id				=> v_dedupe_rule_id_post_act_ct,
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_sap,
		in_staging_tab_schema		=> 'RAG',
		in_staging_tab_name			=> 'SAP_COMPANY_STAGING',
		in_staging_id_col_name		=> 'VENDOR_NUM',
		in_reference				=> '2000974'
	);

	IF v_results IS NULL OR v_results.count <> 1 THEN
		csr.unit_test_pkg.TestFail('Expected 1 exact match.');
	END IF;

	v_expected_company_sid := test_chain_utils_pkg.GetChainCompanySid('Kouluria Imaathias', 'gr');
	csr.unit_test_pkg.AssertAreEqual(v_expected_company_sid, v_results(1), 'Resulted matched company is not the expected one');
END;

PROCEDURE TestMatch_AllRules
AS
	v_results				security_pkg.T_SID_IDS;
	v_expected_company_sid	NUMBER;
	v_resulted_sid			NUMBER;

	v_dedupe_processed_record_id 	dedupe_processed_record.dedupe_processed_record_id%TYPE;
	v_rule_set_id					dedupe_rule_set.dedupe_rule_set_id%TYPE;
	v_resulted_match_type_id		dedupe_rule_set.dedupe_match_type_id%TYPE;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	--test case match ('AL.M.ME. S.A.', gr)
	v_results := company_dedupe_pkg.FindAndStoreMatches(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_sap,
		in_staging_tab_schema		=> 'RAG',
		in_staging_tab_name			=> 'SAP_COMPANY_STAGING',
		in_staging_id_col_name		=> 'VENDOR_NUM',
		in_reference				=> '2000974',
		out_rule_set_id				=> v_rule_set_id,
		out_resulted_match_type_id	=> v_resulted_match_type_id,
		out_processed_record_id		=> v_dedupe_processed_record_id
	);

	IF v_results IS NULL OR v_results.count <> 1 THEN
		csr.unit_test_pkg.TestFail('Expected 1 exact match');
	END IF;

	v_expected_company_sid := test_chain_utils_pkg.GetChainCompanySid('Kouluria Imaathias', 'gr');
	csr.unit_test_pkg.AssertAreEqual(v_expected_company_sid, v_results(1), 'Resulted matched company is not the expected one');

	--2nd test case: 2 matches
	v_results := company_dedupe_pkg.FindAndStoreMatches(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_sap,
		in_staging_tab_schema		=> 'RAG',
		in_staging_tab_name			=> 'SAP_COMPANY_STAGING',
		in_staging_id_col_name		=> 'VENDOR_NUM',
		in_reference				=> '5555444',
		out_rule_set_id				=> v_rule_set_id,
		out_resulted_match_type_id	=> v_resulted_match_type_id,
		out_processed_record_id		=> v_dedupe_processed_record_id
	);

	IF v_results IS NULL OR v_results.count <> 2 THEN
		csr.unit_test_pkg.TestFail('Expected 2 matches');
	END IF;
END;

PROCEDURE TestMatch_SectorAddress
AS
	v_results				security_pkg.T_SID_IDS;
	v_expected_company_sid	NUMBER;
	v_resulted_sid			NUMBER;

	v_dedupe_processed_record_id 	dedupe_processed_record.dedupe_processed_record_id%TYPE;
	v_rule_set_id					dedupe_rule_set.dedupe_rule_set_id%TYPE;
	v_resulted_match_type_id		dedupe_rule_set.dedupe_match_type_id%TYPE;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	--test case match (EGHOYAN''S PITTA BAKERY LTD.)
	v_results := company_dedupe_pkg.FindAndStoreMatches(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_bsci,
		in_staging_tab_schema		=> 'RAG',
		in_staging_tab_name			=> 'BSCI_COMPANY_STAGING',
		in_staging_id_col_name		=> 'BSCI_VENDOR_NUM',
		in_reference				=> '2222ABC',
		out_rule_set_id				=> v_rule_set_id,
		out_resulted_match_type_id	=> v_resulted_match_type_id,
		out_processed_record_id		=> v_dedupe_processed_record_id
	);

	IF v_results IS NULL OR v_results.count <> 1 THEN
		csr.unit_test_pkg.TestFail('Expected 1 exact match');
	END IF;

	v_expected_company_sid := test_chain_utils_pkg.GetChainCompanySid('EGHOYAN', 'gb');
	csr.unit_test_pkg.AssertAreEqual(v_expected_company_sid, v_results(1), 'Resulted matched company is not the expected one');
END;

PROCEDURE TestMatch_AddressTagGroup
AS
	v_results				security_pkg.T_SID_IDS;
	v_expected_company_sid	NUMBER;
	v_resulted_sid			NUMBER;

	v_dedupe_processed_record_id dedupe_processed_record.dedupe_processed_record_id%TYPE;
	v_rule_set_id				dedupe_rule_set.dedupe_rule_set_id%TYPE;
	v_resulted_match_type_id	dedupe_rule_set.dedupe_match_type_id%TYPE;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	--test case match ('BOLLORE', fr)
	v_results := company_dedupe_pkg.FindAndStoreMatches(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_bsci,
		in_staging_tab_schema		=> 'RAG',
		in_staging_tab_name			=> 'BSCI_COMPANY_STAGING',
		in_staging_id_col_name		=> 'BSCI_VENDOR_NUM',
		in_reference				=> '45245',
		out_rule_set_id				=> v_rule_set_id,
		out_resulted_match_type_id	=> v_resulted_match_type_id,
		out_processed_record_id		=> v_dedupe_processed_record_id
	);

	IF v_results IS NULL OR v_results.count <> 1 THEN
		csr.unit_test_pkg.TestFail('Expected 1 exact match');
	END IF;

	v_expected_company_sid := test_chain_utils_pkg.GetChainCompanySid('ANTOINES', 'fr');
	csr.unit_test_pkg.AssertAreEqual(v_expected_company_sid, v_results(1), 'Resulted matched company is not the expected one');

	--test case match ('ALLORE', fr)
	v_results := company_dedupe_pkg.FindAndStoreMatches(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_bsci,
		in_staging_tab_schema		=> 'RAG',
		in_staging_tab_name			=> 'BSCI_COMPANY_STAGING',
		in_staging_id_col_name		=> 'BSCI_VENDOR_NUM',
		in_reference				=> '1111',
		out_rule_set_id				=> v_rule_set_id,
		out_resulted_match_type_id	=> v_resulted_match_type_id,
		out_processed_record_id		=> v_dedupe_processed_record_id
	);

	IF v_results IS NOT NULL AND v_results.count > 0 THEN
		csr.unit_test_pkg.TestFail('Expected no matches');
	END IF;
END;

PROCEDURE TestNoMatch_CreateCompany
AS
	v_results				SECURITY.T_ORDERED_SID_TABLE; /*rule_set_id, company_sid*/
	v_expected_company_sid	NUMBER;
	v_resulted_sid			NUMBER;
	v_count					NUMBER;

	v_created_company_sid	security.security_pkg.T_SID_ID;
	v_matched_company_sids	security.security_pkg.T_SID_IDS;
	v_processed_record_ids	security_pkg.T_SID_IDS;
	v_processed_record_id	dedupe_processed_record.dedupe_processed_record_id%TYPE;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_sap,
		in_reference				=> '99-88-77',
		out_processed_record_ids	=> v_processed_record_ids,
		out_created_company_sid 	=>	v_created_company_sid,
		out_matched_company_sids	=>	v_matched_company_sids
	);

	v_processed_record_id := v_processed_record_ids(1);

	IF v_matched_company_sids.count <> 0 OR v_created_company_sid IS NULL THEN
		csr.unit_test_pkg.TestFail('Expected 0 matches and a new company as a result of it');
	END IF;

	v_expected_company_sid := test_chain_utils_pkg.GetChainCompanySid('Robot Manufacturers', 'ie');
	csr.unit_test_pkg.AssertAreEqual(v_expected_company_sid, v_created_company_sid, 'Newly created company is not the expected one');

	SELECT COUNT(*)
	  INTO v_count
	  FROM company
	 WHERE company_sid = v_expected_company_sid
	   AND website = 'www.robot-manufacturers.com'
	   AND city = 'Galway'
	   AND active = 1
	   AND activated_dtm = DATE '2006-08-15'
	   AND sector_id = 1;

	IF v_count = 0 THEN
		csr.unit_test_pkg.TestFail('Data for the new company is not the expected one');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_tag
	 WHERE tag_group_id = test_chain_utils_pkg.GetTagGroupId('FACILITY_TYPE')
	   AND company_sid = v_expected_company_sid;

	IF v_count <> 2 THEN
		csr.unit_test_pkg.TestFail('Tags count for the new company is not the expected one');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM company_reference
	 WHERE company_sid = v_expected_company_sid
	   AND value = '99-88-77';

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('References count for the new company is not the expected one');
	END IF;

	--test that our logging is correct
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND reference_id IS NOT NULL
	   AND old_val IS NULL
	   AND new_val = '99-88-77';

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('References logging for the new company is not the expected one');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND tag_group_id = test_chain_utils_pkg.GetTagGroupId('FACILITY_TYPE')
	   AND old_val IS NULL
	   AND new_val = 'Garage, Store';

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Tags logging for the new company is not the expected one');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND dedupe_field_id = chain_pkg.FLD_COMPANY_NAME
	   AND old_val IS NULL
	   AND new_val = 'Robot Manufacturers';

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Name field logging for the new company is not the expected one');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND dedupe_field_id = chain_pkg.FLD_COMPANY_CITY
	   AND old_val IS NULL
	   AND new_val = 'Galway';
	   
	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('City field logging for the new company is not the expected one');
	END IF;

	--2nd case - test parent sid
	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_sap,
		in_reference				=> '88-77-66',
		out_processed_record_ids	=>	v_processed_record_ids,
		out_created_company_sid 	=>	v_created_company_sid,
		out_matched_company_sids	=>	v_matched_company_sids
	);

	v_processed_record_id := v_processed_record_ids(1);

	IF v_matched_company_sids.count <> 0 OR v_created_company_sid IS NULL THEN
		csr.unit_test_pkg.TestFail('Expected 0 matches and a new company as a result of it');
	END IF;

	v_expected_company_sid := test_chain_utils_pkg.GetChainCompanySid('Kitchenware super plant', 'fr');
	csr.unit_test_pkg.AssertAreEqual(v_expected_company_sid, v_created_company_sid, 'Newly created company is not the expected one');

	SELECT COUNT(*)
	  INTO v_count
	  FROM company
	 WHERE company_sid = v_expected_company_sid
	   AND parent_sid IS NOT NULL;

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Data for the new company is not the expected one');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND dedupe_field_id = chain_pkg.FLD_COMPANY_PARENT
	   AND old_val IS NULL
	   AND new_val IS NOT NULL;

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Parent company field logging for the new company is not the expected one');
	END IF;

	--test that when matches are found we don't create a company
	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_sap,
		in_reference				=> '2000974',
		out_processed_record_ids	=>	v_processed_record_ids,
		out_created_company_sid 	=>	v_created_company_sid,
		out_matched_company_sids	=>	v_matched_company_sids
	);

	IF v_matched_company_sids.count <> 1 OR v_created_company_sid IS NOT NULL THEN
		csr.unit_test_pkg.TestFail('Expected 1 exact match');
	END IF;
END;

PROCEDURE Test_DataMergedFromHigherPrior
AS
	v_expected_company_sid		NUMBER;
	v_system_import_source_id 	NUMBER;
	v_processed_record_ids		security_pkg.T_SID_IDS;
	v_processed_record_id		NUMBER;
	v_data_merged_from_prior	NUMBER;

	v_created_company_sid	security.security_pkg.T_SID_ID;
	v_matched_company_sids	security.security_pkg.T_SID_IDS;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	--Process a record, expect a match
	v_expected_company_sid := test_chain_utils_pkg.GetChainCompanySid('Eco-Products, Inc - BENZSTRASSE', 'de');

	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_sap,
		in_reference				=> '20009729',
		out_processed_record_ids	=> v_processed_record_ids,
		out_created_company_sid 	=>	v_created_company_sid,
		out_matched_company_sids	=>	v_matched_company_sids
	);

	v_processed_record_id := v_processed_record_ids(1);

	IF v_matched_company_sids.count <> 1 OR v_created_company_sid IS NOT NULL THEN
		csr.unit_test_pkg.TestFail('Expected 1 exact match and not a new company');
	END IF;

	SELECT import_source_id
	  INTO v_system_import_source_id
	  FROM import_source
	 WHERE is_owned_by_system = 1;

	v_data_merged_from_prior := company_dedupe_pkg.DataMergedFromHigherPriorSrc(v_matched_company_sids(1), v_system_import_source_id);

	csr.unit_test_pkg.AssertAreEqual(v_data_merged_from_prior, 1, 'Expected data to have been merged from a higher priority source');

	--now create a company from a lower priority source and check the function result
	UPDATE chain.import_source
	   SET dedupe_no_match_action_id = chain_pkg.AUTO_CREATE
	 WHERE lookup_key = 'BSCI_COMPANIES';

	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_bsci,
		in_reference				=> '1111',
		out_processed_record_ids	=>	v_processed_record_ids,
		out_created_company_sid 	=>	v_created_company_sid,
		out_matched_company_sids	=>	v_matched_company_sids
	);

	v_processed_record_id := v_processed_record_ids(1);

	IF v_matched_company_sids.count <> 0 OR v_created_company_sid IS NULL THEN
		csr.unit_test_pkg.TestFail('Expected a new company');
	END IF;

	v_data_merged_from_prior := company_dedupe_pkg.DataMergedFromHigherPriorSrc(v_created_company_sid, v_system_import_source_id);

	csr.unit_test_pkg.AssertAreEqual(v_data_merged_from_prior, 0, 'Expected data to have been merged from a lower priority source');

	--just in case, although we tear down the setup anyway
	UPDATE chain.import_source
	   SET dedupe_no_match_action_id = chain_pkg.IGNORE_RECORD
	 WHERE lookup_key = 'BSCI_COMPANIES';
END;

PROCEDURE TestMatch_MergeCompanyData
AS
	v_results				SECURITY.T_ORDERED_SID_TABLE; /*rule_set_id, company_sid*/
	v_expected_company_sid	NUMBER;
	v_resulted_sid			NUMBER;
	v_count					NUMBER;
	v_tab_sid				security_pkg.T_SID_ID;
	v_bsci_import_source_id	NUMBER;
	v_reference_id			NUMBER;
	v_mapping_id_vendor_ref NUMBER;
	v_dedupe_rule_id		NUMBER;
	v_mapping_ids			security.security_pkg.T_SID_IDS;
	v_rule_ids				security.security_pkg.T_SID_IDS;
	v_processed_record_ids	security.security_pkg.T_SID_IDS;
	v_created_company_sid	security.security_pkg.T_SID_ID;
	v_matched_company_sids	security.security_pkg.T_SID_IDS;
	v_processed_record_id	dedupe_processed_record.dedupe_processed_record_id%TYPE;
	v_mapping_id_postcode	NUMBER;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	--1st test case match for 'Eco-Products, Inc - BENZSTRASSE, 'de'
	v_expected_company_sid := test_chain_utils_pkg.GetChainCompanySid('Eco-Products, Inc - BENZSTRASSE', 'de');

	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_sap,
		in_reference				=> '20009729',
		out_processed_record_ids	=>	v_processed_record_ids,
		out_created_company_sid 	=>	v_created_company_sid,
		out_matched_company_sids	=>	v_matched_company_sids
	);

	v_processed_record_id := v_processed_record_ids(1);

	IF v_matched_company_sids.count <> 1 OR v_created_company_sid IS NOT NULL THEN
		csr.unit_test_pkg.TestFail('Expected 1 exact match and not a new company');
	END IF;

	csr.unit_test_pkg.AssertAreEqual(v_expected_company_sid, v_matched_company_sids(1), 'Resulted matched company is not the expected one');

	--test merged data
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_tag
	 WHERE tag_group_id = test_chain_utils_pkg.GetTagGroupId('FACILITY_TYPE')
	   AND company_sid = v_expected_company_sid;

	IF v_count <> 3 THEN
		csr.unit_test_pkg.TestFail('Tags count after merge is not the expected one.  Expected 3, encountered '||v_count);
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM company_reference
	 WHERE company_sid = v_expected_company_sid
	   AND value = '20009729';

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('References data after merge is not the expected one');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM company
	 WHERE company_sid = v_expected_company_sid
	   AND state = 'Bavaria'
	   AND website = 'www.eco-products.com'
	   AND city = 'MERENBERG'
	   AND activated_dtm = DATE '2009-09-29'
	   AND company_type_id = chain.company_type_pkg.GetCompanyTypeId('VENDOR')
	   AND UPPER(country_code) = 'DE'
	   AND postcode = '35799';

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Data after merge is not the expected one');
	END IF;

	--check field logging
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND tag_group_id = test_chain_utils_pkg.GetTagGroupId('FACILITY_TYPE')
	   AND old_val = 'Construction site'
	   AND new_val = 'Construction site, Garage, Store';
	   
	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Tags logging after the merge is not the expected one.');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND dedupe_field_id = chain_pkg.FLD_COMPANY_WEBSITE
	   AND old_val IS NULL
	   AND new_val = 'www.eco-products.com';

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Website field logging after the merge is not the expected one');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND dedupe_field_id = chain_pkg.FLD_COMPANY_NAME
	   AND old_val='Eco-Products, Inc - BENZSTRASSE'
	   AND new_val='Eco-Products, Inc - BENZSTRASSE';

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Name field logging after the merge is not the expected one');
	END IF;

	--2nd test case process a record with an import source of a lower priority
	v_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'BSCI_COMPANY_STAGING');

	--first add a new BSCI rule mapping on SAP1_COMPANY_REF reference
	SELECT import_source_id
	  INTO v_bsci_import_source_id
	  FROM import_source
	 WHERE lookup_key = 'BSCI_COMPANIES';

	 UPDATE import_source
	    SET dedupe_no_match_action_id = chain_pkg.AUTO_CREATE
	  WHERE lookup_key = 'BSCI_COMPANIES';

	 SELECT reference_id
	   INTO v_reference_id
	   FROM reference
	  WHERE lookup_key = ('SAP1_COMPANY_REF');

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_bsci,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'BSCI_VENDOR_NUM'),
		in_reference_id => v_reference_id,
		out_dedupe_mapping_id => v_mapping_id_vendor_ref
	);

	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_id_vendor_ref));

	dedupe_admin_pkg.TestSaveRuleSetForExactMatches(
		in_dedupe_rule_set_id		=> -1,
		in_description				=> 'Vendor ref rule set',
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_bsci,
		in_rule_set_position		=> 3,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		out_dedupe_rule_set_id		=> v_dedupe_rule_id
	);

	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_bsci,
		in_reference				=> '20009729',
		out_processed_record_ids	=>	v_processed_record_ids,
		out_created_company_sid 	=>	v_created_company_sid,
		out_matched_company_sids	=>	v_matched_company_sids
	);

	v_processed_record_id := v_processed_record_ids(1);

	--expected company sid is the same with the one in the first test case
	IF v_matched_company_sids.count <> 1 OR v_created_company_sid IS NOT NULL THEN
		csr.unit_test_pkg.TestFail('Expected 1 exact match and not a new company');
	END IF;

	csr.unit_test_pkg.AssertAreEqual(v_expected_company_sid, v_matched_company_sids(1), 'Resulted matched company is not the expected one');

	--no merge expected
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND data_merged = 0;

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Expected the company data merged flag to be 0 as the system managed source has higher priority');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id;

	IF v_count <> 0 THEN
		csr.unit_test_pkg.TestFail('Expected no data merge for none of the fields as the system managed source has higher priority');
	END IF;

	--ok now set the system-managed priority lower and re-try a merge. It should merge fields not merged previously
	UPDATE chain.import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;

	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_bsci,
		in_reference				=> '20009729',
		out_processed_record_ids	=> v_processed_record_ids,
		out_created_company_sid 	=>	v_created_company_sid,
		out_matched_company_sids	=>	v_matched_company_sids,
		in_force_re_eval			=> 1
	);

	v_processed_record_id := v_processed_record_ids(1);

	--merge expected
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND data_merged = 1;

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Expected the data merged flag to have been set');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND tag_group_id = test_chain_utils_pkg.GetTagGroupId('FACILITY_TYPE');
	   
	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Should have merged tags here, as tags bypass the previous merge at higher priority rule.');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND tag_group_id = test_chain_utils_pkg.GetTagGroupId('OWNERSHIP_TYPE')
	   AND new_val = 'Is private property';

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Should have merged tags for this tag group as there is no previous merge by a higher priority source');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_tag
	 WHERE tag_group_id = test_chain_utils_pkg.GetTagGroupId('OWNERSHIP_TYPE')
	   AND company_sid = v_expected_company_sid;

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Tags count for this tag group after merge is not the expected one');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_tag
	 WHERE tag_group_id = test_chain_utils_pkg.GetTagGroupId('FACILITY_TYPE')
	   AND company_sid = v_expected_company_sid;

	IF v_count <> 4 THEN
		csr.unit_test_pkg.TestFail('Tags count for this tag group after merge should have been changed');
	END IF;

	--address is only mapped for bsci
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND dedupe_field_id = chain_pkg.FLD_COMPANY_ADDRESS
	   AND old_val IS NULL
	   AND new_val = '22 Leuschnerdamm';

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Address field logging after the merge is not the expected one');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM company
	 WHERE company_sid = v_expected_company_sid
	   AND state = 'Bavaria'
	   AND website = 'www.eco-products.com'
	   AND city = 'MERENBERG'
	   AND activated_dtm = DATE '2009-09-29'
	   AND address_1 = '22 Leuschnerdamm' --address changed
	   AND sector_id = 1 -- sector should have change as the SAP source didnt provide a value (although there was a mapping)
	   AND postcode = '35799'
	   AND UPPER(country_code) = 'DE';

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Data after merge is not the expected one');
	END IF;

	--increase priority for bsci and re-try merge - should overwrite all mapped fields
	UPDATE chain.import_source
	   SET position = -1
	 WHERE lookup_key = 'BSCI_COMPANIES';

	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_bsci,
		in_reference				=> '20009729',
		out_processed_record_ids	=> v_processed_record_ids,
		out_created_company_sid 	=>	v_created_company_sid,
		out_matched_company_sids	=>	v_matched_company_sids,
		in_force_re_eval			=> 1
	);

	v_processed_record_id := v_processed_record_ids(1);

	--postcode value should have been amended
	SELECT COUNT(*)
	  INTO v_count
	  FROM company
	 WHERE company_sid = v_expected_company_sid
	   AND state = 'Bavaria'
	   AND website = 'www.eco-products.com'
	   AND city = 'MERENBERG'
	   AND activated_dtm = DATE '2009-09-29'
	   AND address_1 = '22 Leuschnerdamm'
	   AND postcode = 'N17 OPR'
	   AND sector_id = 1;

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Data after merge is not the expected one');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND dedupe_field_id = chain_pkg.FLD_COMPANY_POSTCODE
	   AND old_val = '35799'
	   AND new_val = 'N17 OPR';

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Log for the postcode field is not the expected one');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_tag
	 WHERE tag_group_id = test_chain_utils_pkg.GetTagGroupId('FACILITY_TYPE')
	   AND company_sid = v_expected_company_sid;

	IF v_count <> 4 THEN
		csr.unit_test_pkg.TestFail('Tags for this tag group should remain.');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND tag_group_id = test_chain_utils_pkg.GetTagGroupId('FACILITY_TYPE')
	   AND old_val = 'Construction site, Factory, Garage, Store'
	   AND new_val = 'Construction site, Factory, Garage, Store';

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Log for this tag group is not the expected one.');
	END IF;

	--check references are still right
	SELECT COUNT(*)
	  INTO v_count
	  FROM company_reference
	 WHERE company_sid = v_expected_company_sid
	   AND value = '20009729';

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Reference value shouldn''t have been amended after the last merge try');
	END IF;

	--revert priorities
	UPDATE chain.import_source
	   SET position = 2
	 WHERE is_owned_by_system = 1;

	UPDATE chain.import_source
	   SET position = 3
	 WHERE lookup_key = 'BSCI_COMPANIES';

	--3rd test case: first create a company, process it then update some of the staging values and re-process
	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_sap,
		in_reference				=> 'WM-33-22-77-1',
		out_processed_record_ids	=> v_processed_record_ids,
		out_created_company_sid 	=>	v_created_company_sid,
		out_matched_company_sids	=>	v_matched_company_sids
	);

	v_processed_record_id := v_processed_record_ids(1);

	IF v_matched_company_sids.count <> 0 OR v_created_company_sid IS NULL THEN
		csr.unit_test_pkg.TestFail('Expected 0 matches and a new company as a result of it');
	END IF;

	v_expected_company_sid := test_chain_utils_pkg.GetChainCompanySid('Washing machines store', 'de');
	csr.unit_test_pkg.AssertAreEqual(v_expected_company_sid, v_created_company_sid, 'Newly created company is not the expected one');

	SELECT COUNT(*)
	  INTO v_count
	  FROM company_reference
	 WHERE company_sid = v_expected_company_sid
	   AND value = 'WM ST 33 BR'
	   AND reference_id = (
		SELECT reference_id
		  FROM reference
		 WHERE lookup_key = 'COMPANY_SECONDARY_REF'
		);

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('References data after merge is not the expected one');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM company
	 WHERE company_sid = v_expected_company_sid
	   AND active = 1
	   AND email = 'someone@wm.de'
	   AND company_type_id = (
		SELECT company_type_id
		  FROM company_type
		 WHERE lookup_key = 'SITE'
	   );

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Data for the new company is not the expected one');
	END IF;

	--check reference logging
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND reference_id = (
		SELECT reference_id
		  FROM reference
		 WHERE lookup_key = 'COMPANY_SECONDARY_REF'
		)
	   AND old_val IS NULL
	   AND new_val = 'WM ST 33 BR';

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Reference logging after the merge is not the expected one');
	END IF;

	--now change some values in the sap staging and re-process
	EXECUTE IMMEDIATE 'UPDATE rag.sap_company_staging' ||
		' SET postal_code=''it-8877'', country=''it'', facility_type = NULL, company_secondary_ref = ''NEW - WM ST 33 BR''' ||
	  ' WHERE vendor_num = ''WM-33-22-77-1''';

	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_sap,
		in_reference				=> 'WM-33-22-77-1',
		in_force_re_eval			=> 1,
		out_processed_record_ids	=> v_processed_record_ids,
		out_created_company_sid 	=>	v_created_company_sid,
		out_matched_company_sids	=>	v_matched_company_sids
	);

	v_processed_record_id := v_processed_record_ids(1);

	IF v_matched_company_sids.count <> 1 OR v_created_company_sid IS NOT NULL THEN
		csr.unit_test_pkg.TestFail('Expected 1 exact match');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM company_reference
	 WHERE company_sid = v_expected_company_sid
	   AND value = 'NEW - WM ST 33 BR'
	   AND reference_id = (
		SELECT reference_id
		  FROM reference
		 WHERE lookup_key = 'COMPANY_SECONDARY_REF'
		);

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('References data after merge is not the expected one');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM company
	 WHERE company_sid = v_expected_company_sid
	   AND active = 1
	   AND email = 'someone@wm.de'
	   AND postcode= 'it-8877'
	   AND country_code ='it'
	   AND company_type_id = (
		SELECT company_type_id
		  FROM company_type
		 WHERE lookup_key = 'SITE'
	   );

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Merged data for the company is not the expected one');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_tag
	 WHERE tag_group_id = test_chain_utils_pkg.GetTagGroupId('FACILITY_TYPE')
	   AND company_sid = v_expected_company_sid;

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Tags for this tag group should remain');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND dedupe_field_id = chain_pkg.FLD_COMPANY_COUNTRY
	   AND old_val = 'de'
	   AND new_val = 'it';

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Country field logging after the merge is not the expected one');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND new_val = 'NEW - WM ST 33 BR'
	   AND old_val = 'WM ST 33 BR'
	   AND reference_id = (
		SELECT reference_id
		  FROM reference
		 WHERE lookup_key = 'COMPANY_SECONDARY_REF'
		);

	IF v_count <> 1 THEN
		csr.unit_test_pkg.TestFail('Reference field logging after the merge is not the expected one');
	END IF;

	--revert
	UPDATE import_source
	   SET dedupe_no_match_action_id = chain_pkg.IGNORE_RECORD
	 WHERE lookup_key = 'BSCI_COMPANIES';
END;

PROCEDURE TestManualReview_Create
AS
	v_results				SECURITY.T_ORDERED_SID_TABLE; /*rule_set_id, company_sid*/
	v_expected_company_sid	NUMBER;
	v_resulted_sid			NUMBER;
	v_count					NUMBER;

	v_created_company_sid	security.security_pkg.T_SID_ID;
	v_matched_company_sids	security.security_pkg.T_SID_IDS;
	v_processed_record_ids	security.security_pkg.T_SID_IDS;
	v_processed_record_id	dedupe_processed_record.dedupe_processed_record_id%TYPE;
	v_auto_action_id		chain_pkg.T_DEDUPE_NO_MATCH_ACTION;
	v_action_type_id		dedupe_processed_record.dedupe_action_type_id%TYPE;
	v_action				dedupe_processed_record.dedupe_action%TYPE;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	UPDATE import_source
	   SET dedupe_no_match_action_id = chain_pkg.IGNORE_RECORD
	 WHERE import_source_id = v_source_id_sap;

	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_sap,
		in_reference				=> '99-88-77',
		out_processed_record_ids	=> v_processed_record_ids,
		out_created_company_sid 	=>	v_created_company_sid,
		out_matched_company_sids	=>	v_matched_company_sids
	);

	v_processed_record_id := v_processed_record_ids(1);

	IF v_matched_company_sids.count <> 0 THEN
		csr.unit_test_pkg.TestFail('Expected 0 matches and a new company as a result of it');
	END IF;

	IF v_created_company_sid IS NOT NULL THEN
		csr.unit_test_pkg.TestFail('Expected new company creation to be postponed');
	END IF;

	SELECT dedupe_action
	  INTO v_action
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = v_processed_record_id;

	IF v_action <> chain_pkg.ACTION_IGNORE THEN
		csr.unit_test_pkg.TestFail('Action should be ignore');
	END IF;

	UPDATE import_source
	   SET dedupe_no_match_action_id = chain_pkg.MANUAL_REVIEW
	 WHERE import_source_id = v_source_id_sap;

	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_sap,
		in_reference				=> '99-88-77',
		in_force_re_eval			=> 1,
		out_processed_record_ids	=> v_processed_record_ids,
		out_created_company_sid 	=>	v_created_company_sid,
		out_matched_company_sids	=>	v_matched_company_sids
	);

	v_processed_record_id := v_processed_record_ids(1);

	IF v_matched_company_sids.count <> 0 THEN
		csr.unit_test_pkg.TestFail('Expected 0 matches and a new company as a result of it');
	END IF;

	IF v_created_company_sid IS NOT NULL THEN
		csr.unit_test_pkg.TestFail('Expected new company creation to be postponed');
	END IF;

	SELECT dedupe_action_type_id
	  INTO v_action_type_id
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = v_processed_record_id;

	IF v_action_type_id <> chain_pkg.DEDUPE_MANUAL THEN
		csr.unit_test_pkg.TestFail('Action type should be manual');
	END IF;

	company_dedupe_pkg.MergeRecord(v_processed_record_id, NULL);

	SELECT dedupe_action, dedupe_action_type_id, created_company_sid
	  INTO v_action, v_action_type_id, v_created_company_sid
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = v_processed_record_id;

	IF v_created_company_sid IS NULL THEN
		csr.unit_test_pkg.TestFail('Expected new company to be created');
	END IF;

	IF v_action_type_id <> chain_pkg.DEDUPE_MANUAL THEN
		csr.unit_test_pkg.TestFail('Action type should be manual');
	END IF;

	IF v_action <> chain_pkg.ACTION_CREATE THEN
		csr.unit_test_pkg.TestFail('Action should be create');
	END IF;
END;

PROCEDURE TestRuleManualReview_Merge
AS
	v_results				SECURITY.T_ORDERED_SID_TABLE; /*rule_set_id, company_sid*/
	v_expected_company_sid	NUMBER;
	v_resulted_sid			NUMBER;
	v_count					NUMBER;

	v_created_company_sid	security.security_pkg.T_SID_ID;
	v_matched_company_sids	security.security_pkg.T_SID_IDS;
	v_processed_record_ids	security_pkg.T_SID_IDS;
	v_processed_record_id	dedupe_processed_record.dedupe_processed_record_id%TYPE;
	v_action_type_id		dedupe_processed_record.dedupe_action_type_id%TYPE;
	v_action				dedupe_processed_record.dedupe_action%TYPE;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	UPDATE dedupe_rule_set
	   SET dedupe_match_type_id = chain_pkg.DEDUPE_MANUAL
	 WHERE dedupe_rule_set_id = (
		SELECT dedupe_rule_set_id
		  FROM dedupe_rule_set
		 WHERE dedupe_rule_set_id = v_dedupe_rule_id_post_act_ct
	);

	--test that when matches are found we don't create a company
	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_sap,
		in_reference				=> '2000974',
		out_processed_record_ids	=>	v_processed_record_ids,
		out_created_company_sid 	=>	v_created_company_sid,
		out_matched_company_sids	=>	v_matched_company_sids
	);

	v_processed_record_id := v_processed_record_ids(1);

	IF v_matched_company_sids.count <> 1 OR v_created_company_sid IS NOT NULL THEN
		csr.unit_test_pkg.TestFail('Expected 1 exact match');
	END IF;

	SELECT dedupe_action_type_id
	  INTO v_action_type_id
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = v_processed_record_id;

	IF v_action_type_id <> chain_pkg.DEDUPE_MANUAL THEN
		csr.unit_test_pkg.TestFail('Action type should be manual');
	END IF;

	company_dedupe_pkg.MergeRecord(v_processed_record_id, v_matched_company_sids(1));

	SELECT dedupe_action_type_id, dedupe_action
	  INTO v_action_type_id, v_action
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = v_processed_record_id;

	IF v_action_type_id <> chain_pkg.DEDUPE_MANUAL THEN
		csr.unit_test_pkg.TestFail('Action type should be manual');
	END IF;

	IF v_action <> chain_pkg.ACTION_UPDATE THEN
		csr.unit_test_pkg.TestFail('Action should be update');
	END IF;
END;

/* auto create source and auto matches*/
PROCEDURE TestAuto_MultipleMatches
AS
	v_count						NUMBER;
	v_matched_to_company_sid	NUMBER;
	v_created_company_sid		security.security_pkg.T_SID_ID;
	v_matched_company_sids		security.security_pkg.T_SID_IDS;
	v_processed_record_ids		security_pkg.T_SID_IDS;
	v_processed_record_id		dedupe_processed_record.dedupe_processed_record_id%TYPE;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_sap,
		in_reference				=> '5555444',
		out_processed_record_ids	=> v_processed_record_ids,
		out_created_company_sid 	=>	v_created_company_sid,
		out_matched_company_sids	=>	v_matched_company_sids
	);

	v_processed_record_id := v_processed_record_ids(1);

	IF v_matched_company_sids.COUNT <> 2 THEN
		csr.unit_test_pkg.TestFail('Expected 2 potential matches');
	END IF;

	IF v_created_company_sid IS NOT NULL THEN
		csr.unit_test_pkg.TestFail('Didn''t expect a new company');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND created_company_sid IS NULL
	   AND matched_to_company_sid IS NULL
	   AND data_merged = 0
	   AND dedupe_action IS NULL
	   AND dedupe_action_type_id = chain_pkg.DEDUPE_MANUAL; --failed to create or match to 1 company, so set it to manual

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Values in processed record are not the expected ones');

	v_matched_to_company_sid := test_chain_utils_pkg.GetChainCompanySid('Rice partners', 'it');

	--merge it manually
	company_dedupe_pkg.MergeRecord(v_processed_record_id, v_matched_to_company_sid);

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND created_company_sid IS NULL
	   AND matched_to_company_sid = v_matched_to_company_sid
	   AND data_merged = 1
	   AND dedupe_action = chain_pkg.ACTION_UPDATE
	   AND dedupe_action_type_id = chain_pkg.DEDUPE_MANUAL;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Values in processed record are not the expected ones');
END;

PROCEDURE TestFlagFillNullsUnderUI
AS
	v_results					NUMBER;
	v_processed_record_ids		security.security_pkg.T_SID_IDS;
	v_created_company_sid		security.security_pkg.T_SID_ID;
	v_matched_company_sids		security.security_pkg.T_SID_IDS;
	v_matched_company_sid		security.security_pkg.T_SID_ID;
	v_previous_ui_source_pos	NUMBER;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	 SELECT	position
	   INTO	v_previous_ui_source_pos
	   FROM	chain.import_source
	  WHERE	is_owned_by_system = 1;

	UPDATE chain.import_source
	   SET position = 2
	 WHERE is_owned_by_system = 1;

	UPDATE chain.import_source
	   SET dedupe_no_match_action_id = chain_pkg.AUTO_CREATE
	 WHERE lookup_key = 'BSCI_COMPANIES';

	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=>	v_dedupe_staging_link_id_bsci,
		in_reference				=>	'1234567890',
		out_processed_record_ids	=>	v_processed_record_ids,
		out_created_company_sid 	=>	v_created_company_sid,
		out_matched_company_sids	=>	v_matched_company_sids
	);

	IF v_created_company_sid IS NULL THEN
		csr.unit_test_pkg.TestFail('Expected company wasn''t created');
	END IF;

	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=>	v_dedupe_staging_link_id_try,
		in_reference				=>	'1234567890',
		out_processed_record_ids	=>	v_processed_record_ids,
		out_created_company_sid 	=>	v_created_company_sid,
		out_matched_company_sids	=>	v_matched_company_sids
	);

	--Both post code and address are null, but only post code has fill nulls flag
	v_matched_company_sid := v_matched_company_sids(1);

	 SELECT	COUNT(company_sid)
	   INTO	v_results
	   FROM	chain.company
	  WHERE	company_sid = v_matched_company_sid
	    AND	postcode = 'CB2 1LT';

	csr.unit_test_pkg.AssertAreEqual(1, v_results, 'Postcode should have merged via fill nulls flag');

	 SELECT	COUNT(company_sid)
	   INTO	v_results
	   FROM	chain.company
	  WHERE	company_sid = v_matched_company_sid
	    AND	address_1 IS NULL;

	csr.unit_test_pkg.AssertAreEqual(1, v_results, 'Address should not have merged');

	 SELECT	COUNT(company_sid)
	   INTO	v_results
	   FROM	chain.company c
	   JOIN chain.sector s ON c.sector_id = s.sector_id
	  WHERE	company_sid = v_matched_company_sid
	    AND	s.description = 'Restaurant';

	csr.unit_test_pkg.AssertAreEqual(1, v_results, 'Company sector was previously merged and should not have been overwritten');

	UPDATE chain.import_source
	   SET position = v_previous_ui_source_pos
	 WHERE is_owned_by_system = 1;

	UPDATE chain.import_source
	   SET dedupe_no_match_action_id = chain_pkg.IGNORE_RECORD
	 WHERE lookup_key = 'BSCI_COMPANIES';
END;

--Test matching name on alternate company name with exact match on name/country.
PROCEDURE TestMatch_AltNameCountryRule
AS
	v_results 				security.T_SID_TABLE;
	v_company_ref			VARCHAR(255);
	v_rule_id				NUMBER;
	v_resulted_sid			NUMBER;
	v_expected_company_sid	NUMBER;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	--Match for alternate company name 'ACME Company', with country 'gb'
	v_results := company_dedupe_pkg.TestFindMatchesForRuleSet(
		in_rule_set_id				=> v_dedupe_rule_id_country_name,
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_sap,
		in_staging_tab_schema		=> 'RAG',
		in_staging_tab_name			=> 'SAP_COMPANY_STAGING',
		in_staging_id_col_name		=> 'VENDOR_NUM',
		in_reference				=> '9516284'
	);

	IF v_results IS NULL OR v_results.count <> 1 THEN
		csr.unit_test_pkg.TestFail('Expected 1 exact match');
	END IF;

	v_expected_company_sid := test_chain_utils_pkg.GetChainCompanySid('ACME Co.', 'gb');
	csr.unit_test_pkg.AssertAreEqual(v_expected_company_sid, v_results(1), 'Resulted matched company is not the expected one');

	--2nd test case no match for AGRARFROST GMBH..., de
	v_results := company_dedupe_pkg.TestFindMatchesForRuleSet(
		in_rule_set_id				=> v_dedupe_rule_id_country_name,
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id_sap,
		in_staging_tab_schema		=> 'RAG',
		in_staging_tab_name			=> 'SAP_COMPANY_STAGING',
		in_staging_id_col_name		=> 'VENDOR_NUM',
		in_reference				=> '99086052'
	);

	IF v_results IS NOT NULL THEN
		csr.unit_test_pkg.TestFail('Expected zero matches');
	END IF;
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_tag_group_id		NUMBER;
	v_tag_id			NUMBER;
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);

	test_chain_utils_pkg.SetupTwoTier;

	--plugins not really needed for the testing, could be handy for demoing before tearing down
	plugin_pkg.SetCompanyTab(
		in_page_company_type_lookup => 'VENDOR',
		in_user_company_type_lookup => 'TOP',
		in_viewing_own_company => 0,
		in_js_class => 'Chain.ManageCompany.CompanyDetails',
		in_form_path => NULL,
		in_group_key => NULL,
		in_pos => 1,
		in_label => 'Company details',
		in_options => '',
		in_page_company_col_name => '',
		in_user_company_col_name => '',
		in_flow_capability_id => ''
	);

	plugin_pkg.SetCompanyTab(
		in_page_company_type_lookup => 'TOP',
		in_user_company_type_lookup => 'TOP',
		in_viewing_own_company => 1,
		in_js_class => 'Chain.ManageCompany.SupplierListTab',
		in_form_path => NULL,
		in_group_key => NULL,
		in_pos => 1,
		in_label => 'Company list',
		in_options => '',
		in_page_company_col_name => '',
		in_user_company_col_name => '',
		in_flow_capability_id => ''
	);

	INSERT INTO sector (sector_id, description, active, is_other) VALUES(1, 'Restaurant', 1, 0);
	INSERT INTO sector (sector_id, description, active, is_other) VALUES(2, 'Bakery', 1, 0);

	csr.tag_pkg.SetTagGroup(
		in_tag_group_id					=> NULL,
		in_name							=> 'Facility type',
		in_multi_select					=> 1,
		in_applies_to_regions			=> 1,
		in_applies_to_suppliers			=> 1,
		in_applies_to_chain				=> 1,
		in_lookup_key					=> 'FACILITY_TYPE',
		out_tag_group_id				=> v_tag_group_id
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
		in_tag				=> 'Factory',
		in_lookup_key		=> 'FACTORY',
		out_tag_id			=> v_tag_id
	);
	csr.tag_pkg.SetTag(
		in_tag_group_id		=> v_tag_group_id,
		in_tag				=> 'Construction site',
		in_lookup_key		=> 'CONSTRUCTION_SITE',
		out_tag_id			=> v_tag_id
	);

	csr.tag_pkg.SetTagGroup(
		in_tag_group_id					=> NULL,
		in_name							=> 'Ownership type',
		in_applies_to_regions			=> 1,
		in_applies_to_suppliers			=> 1,
		in_applies_to_chain				=> 1,
		in_lookup_key					=> 'OWNERSHIP_TYPE',
		out_tag_group_id				=> v_tag_group_id
	);

	csr.tag_pkg.SetTag(
		in_tag_group_id		=> v_tag_group_id,
		in_tag				=> 'Is private property',
		in_lookup_key		=> 'IS_PRIVATE_PROPERY',
		out_tag_id			=> v_tag_id
	);
END;

PROCEDURE PopulateStagingCompanies
AS
BEGIN
		--##########################
	--POPULATE STAGING COMPANIES

	--used in name, country rule (match)
	AddSAPStagingRow(
		in_vendor_num	 => '20009729',
		in_vendor_name	 => 'Eco-Products, Inc - BENZSTRASSE',
		in_city			 => 'MERENBERG',
		in_postal_code	 => '35799',
		in_street		 => 'BENZSTRASSE 12',
		in_company_type	 => 'VENDOR',
		in_country		 => 'DE',
		in_activated_dtm => DATE '2009-09-29',
		in_state		 => 'Bavaria',
		in_website		 => 'www.eco-products.com',
		in_sector		 => NULL,
		in_facility_type => 'Garage,Store',
		in_parent_company =>  NULL
	);

	--Used in ref rule (match), name country (no match)
	AddSAPStagingRow(
		in_vendor_num	 => '99086052',
		in_vendor_name	 => 'AGRARFROST GMBH'||chr(38)||'CO. KG',
		in_city			 => 'WILDESHAUSEN',
		in_postal_code	 => '27793',
		in_street		 => 'EXPORT DEPARTMENT ALDRUP 3"',
		in_company_type	 => 'VENDOR',
		in_country		 => 'DE',
		in_activated_dtm => DATE '2010-02-01',
		in_state		 => NULL,
		in_website		 => NULL,
		in_sector		 => NULL,
		in_facility_type => NULL,
		in_parent_company =>  NULL
	);

	--used in postcode, activated_date, company type rule (match)
	AddSAPStagingRow(
		in_vendor_num	 => '2000974',
		in_vendor_name	 => 'AL.M.ME. S.A.',
		in_city			 => 'VERIA',
		in_postal_code	 => '59100',
		in_street		 => 'KOULOURA IMATHIAS',
		in_company_type	 => 'VENDOR',
		in_country		 => 'GR',
		in_activated_dtm => DATE '2000-08-15',
		in_state		 => NULL,
		in_website		 => NULL,
		in_sector		 => NULL,
		in_facility_type => NULL,
		in_parent_company =>  NULL
	);

	--used in ref (multiple matches)
	AddSAPStagingRow(
		in_vendor_num	 => '5555444',
		in_vendor_name	 => 'Rice.',
		in_city			 => 'Bologna',
		in_postal_code	 => '54211',
		in_street		 => '',
		in_company_type	 => 'VENDOR',
		in_country		 => 'IT',
		in_activated_dtm => DATE '2005-08-15',
		in_state		 => NULL,
		in_website		 => NULL,
		in_sector		 => NULL,
		in_facility_type => NULL,
		in_parent_company =>  NULL
	);

	--for no matches, create company
	AddSAPStagingRow(
		in_vendor_num	 => '99-88-77',
		in_vendor_name	 => 'Robot Manufacturers',
		in_city			 => 'Galway',
		in_postal_code	 => 'LNGF22',
		in_street		 => 'Rue de plante',
		in_company_type	 => 'VENDOR',
		in_country		 => 'ie',
		in_activated_dtm => DATE '2006-08-15',
		in_state		 => 'Connacht',
		in_website		 => 'www.robot-manufacturers.com',
		in_sector		 => 'Restaurant',
		in_facility_type => 'Store, Garage',
		in_parent_company =>  NULL
	);

	AddSAPStagingRow(
		in_vendor_num	 => '88-77-66',
		in_vendor_name	 => 'Kitchenware super plant',
		in_city			 => 'Paris',
		in_postal_code	 => 'PAR22',
		in_street		 => 'Rue de plante',
		in_company_type	 => 'SITE',
		in_country		 => 'fr',
		in_activated_dtm => NULL,
		in_state		 => NULL,
		in_website		 => NULL,
		in_sector		 => NULL,
		in_facility_type => NULL,
		in_parent_company => 'ANTOINES'
	);

	AddSAPStagingRow(
		in_vendor_num	 => 'WM-33-22-77-1',
		in_vendor_name	 => 'Washing machines store',
		in_city			 => 'Berlin',
		in_postal_code	 => 'BR 22',
		in_street		 =>  NULL,
		in_company_type	 => 'SITE',
		in_country		 => 'de',
		in_activated_dtm => NULL,
		in_state		 => NULL,
		in_website		 => NULL,
		in_sector		 => NULL,
		in_facility_type => 'Store',
		in_parent_company => NULL,
		in_company_secondary_ref => 'WM ST 33 BR',
		in_active		=> 1,
		in_email		=> 'someone@wm.de'
	);

	--matches the SAP company with the same vendor num
	AddBSCIStagingRow(
		in_vendor_num		=> '20009729',
		in_vendor_name		=> 'Eco-Products, Inc - BENZSTRASSE',
		in_postal_code		=> 'N17 OPR',
		in_address			=> '22 Leuschnerdamm',
		in_company_type		=> 'VENDOR',
		in_country			=> 'GB',
		in_website			=> 'www.new-eco-products.com',
		in_sector			=> 'Restaurant',
		in_facility_type 	=> 'Factory',
		in_ownership_type	=> 'Is private property',
		in_active			=> NULL
	);

	--used in bsci import source (sector, address_1)
	AddBSCIStagingRow(
		in_vendor_num		=> '2222ABC',
		in_vendor_name		=> 'EGHOYAN''S PITTA BAKERY LTD.',
		in_postal_code		=> 'N17 OPR',
		in_address			=> '18 WEST ROAD',
		in_company_type		=> 'VENDOR',
		in_country			=> 'GB',
		in_website			=> NULL,
		in_sector			=> 'Restaurant',
		in_facility_type 	=> NULL,
		in_ownership_type	=> NULL,
		in_active			=> NULL
	);

	--used in bsci import source (tags)
	AddBSCIStagingRow(
		in_vendor_num		=> '45245',
		in_vendor_name		=> 'BOLLORE',
		in_postal_code		=> 'C3REOO',
		in_address			=> '183 LACE Ave',
		in_company_type		=> 'VENDOR',
		in_country			=> 'FR',
		in_website			=> NULL,
		in_sector			=> NULL,
		in_facility_type	=> 'Garage,Store',
		in_ownership_type 	=> NULL,
		in_active			=> NULL
	);

	AddBSCIStagingRow(
		in_vendor_num		=> '1111',
		in_vendor_name		=> 'ALLORE',
		in_postal_code		=> 'C3REOO',
		in_address			=> '183 LACE Ave',
		in_company_type		=> 'VENDOR',
		in_country			=> 'FR',
		in_website			=> NULL,
		in_sector			=> NULL,
		in_facility_type	=> 'Store',
		in_ownership_type 	=> NULL,
		in_active			=> NULL
	);

	--used in name, country rule (match on alternate company name)
	AddSAPStagingRow(
		in_vendor_num	 => '9516284',
		in_vendor_name	 => 'ACME Company',
		in_city			 => 'London',
		in_postal_code	 => 'AC1ME2',
		in_street		 => '73 Acme Ave',
		in_company_type	 => 'VENDOR',
		in_country		 => 'GB',
		in_activated_dtm => DATE '2003-01-01',
		in_state		 => 'London',
		in_website		 => 'www.acme-company.com',
		in_sector		 => NULL,
		in_facility_type => 'Store',
		in_parent_company =>  NULL
	);

	--used in testing for fill nulls under ui source
	AddBSCIStagingRow(
		in_vendor_num		=> '1234567890',
		in_vendor_name		=> 'Fox Rocks PLC',
		in_postal_code		=> NULL,
		in_address			=> NULL,
		in_company_type		=> 'VENDOR',
		in_country			=> 'GB',
		in_website			=> 'www.fox-rocks-this-site.com',
		in_sector			=> 'Restaurant',
		in_facility_type 	=> 'Factory',
		in_ownership_type	=> 'Is private property',
		in_active			=> NULL
	);

	AddTertiaryStagingRow(
		in_vendor_num		=> '1234567890',
		in_vendor_name		=> 'Fox Rocks PLC',
		in_postal_code		=> 'CB2 1LT',
		in_address			=> '1 Should Not Show Drive',
		in_company_type		=> 'VENDOR',
		in_country			=> 'GB',
		in_website			=> 'www.fox-rocks-this-site.com',
		in_sector			=> 'Invalid',
		in_facility_type 	=> 'Factory',
		in_ownership_type	=> 'Wrong',
		in_active			=> NULL
	);
END;

PROCEDURE SetSite(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
END;

PROCEDURE SetUp
AS
	v_mapping_ids		security.security_pkg.T_SID_IDS;
	v_rule_ids			security.security_pkg.T_SID_IDS;
	v_reference_id_1			NUMBER;
	v_reference_id_2			NUMBER;
	v_tab_sid					NUMBER;

	v_mapping_id_activated_dtm	NUMBER;
	v_mapping_id_active			NUMBER;
	v_mapping_id_bsci_address	NUMBER;
	v_mapping_id_bsci_fac_type	NUMBER;
	v_mapping_id_bsci_own_type	NUMBER;
	v_mapping_id_bsci_postcode	NUMBER;
	v_mapping_id_bsci_sector	NUMBER;
	v_mapping_id_bsci_country	NUMBER;
	v_mapping_id_bsci_name		NUMBER;
	v_mapping_id_city			NUMBER;
	v_mapping_id_company_type	NUMBER;
	v_mapping_id_country		NUMBER;
	v_mapping_id_email			NUMBER;
	v_mapping_id_facility_type	NUMBER;
	v_mapping_id_name			NUMBER;
	v_mapping_id_parent			NUMBER;
	v_mapping_id_postcode		NUMBER;
	v_mapping_id_ref_second		NUMBER;
	v_mapping_id_sector			NUMBER;
	v_mapping_id_state			NUMBER;
	v_mapping_id_vendor_ref		NUMBER;
	v_mapping_id_website		NUMBER;
	v_mapping_id_tertiary		NUMBER;
	v_mapping_id_try_name		NUMBER;

	v_vendor_ct_id		NUMBER;
	v_alt_comp_name_id	NUMBER;

	v_company_sid		NUMBER;
	v_top_company_sid	NUMBER;

	v_tag_ids			security.security_pkg.T_SID_IDS;
	v_company_types		chain.helper_pkg.T_NUMBER_ARRAY;
BEGIN
	-- Safest to log on once per test (instead of in StartupFixture) because we unset
	-- the user sid futher down (otherwise any permission test on any ACT returns true)

	security.user_pkg.logonadmin(v_site_name);
	v_top_company_sid := chain.helper_pkg.getTopCompanySid;
	v_vendor_ct_id := company_type_pkg.GetCompanyTypeId('VENDOR');
	v_alt_comp_name_id := alt_company_name_id_seq.NEXTVAL;

	--set up references
	helper_pkg.SaveReferenceLabel(
		in_reference_id	=> NULL,
		in_lookup_key => 'SAP1_COMPANY_REF',
		in_label => 'SAP 1 company reference',
		in_mandatory => 0,
		in_reference_uniqueness_id => 2, /* Global */
		in_reference_location_id => 0, /* Show on the company details card */
		in_company_type_ids	=> v_company_types,
		out_reference_id => v_reference_id_1
	);

	helper_pkg.SaveReferenceLabel(
		in_reference_id	=> NULL,
		in_lookup_key => 'COMPANY_SECONDARY_REF',
		in_label => 'Company secondary reference',
		in_mandatory => 0,
		in_reference_uniqueness_id => 2, /* Global */
		in_reference_location_id => 0, /* Show on the company details card */
		in_company_type_ids	=> v_company_types,
		out_reference_id => v_reference_id_2
	);

	v_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'SAP_COMPANY_STAGING');

	dedupe_admin_pkg.SaveImportSource(
		in_import_source_id => -1,
		in_name => 'SAP',
		in_position => 1,
		in_no_match_action_id => chain_pkg.AUTO_CREATE,
		in_lookup_key => 'SAP',
		out_import_source_id => v_source_id_sap
	);

	--set up staging link
	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id_sap,
		in_description 					=> 'Company data integration',
		in_staging_tab_sid 				=> v_tab_sid,
		in_position 					=> 1,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'VENDOR_NUM'),
		in_staging_batch_num_col_sid 	=> NULL,
		in_parent_staging_link_id 		=> NULL,
		in_destination_tab_sid 			=> NULL,
		out_dedupe_staging_link_id 		=> v_dedupe_staging_link_id_sap
	);

	--setup mappings
	--name
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_sap,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'VENDOR_NAME'),
		in_dedupe_field_id => chain.chain_pkg.FLD_COMPANY_NAME,
		out_dedupe_mapping_id => v_mapping_id_name
	);

	--ref 1
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_sap,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'VENDOR_NUM'),
		in_reference_id => v_reference_id_1,
		out_dedupe_mapping_id => v_mapping_id_vendor_ref
	);

	--ref 2
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_sap,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'COMPANY_SECONDARY_REF'),
		in_reference_id => v_reference_id_2,
		out_dedupe_mapping_id => v_mapping_id_ref_second
	);

	--country
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_sap,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'COUNTRY'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id => v_mapping_id_country
	);

	--company type
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_sap,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'COMPANY_TYPE'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_COMPANY_TYPE,
		out_dedupe_mapping_id => v_mapping_id_company_type
	);

	--postal_code
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_sap,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'POSTAL_CODE'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_POSTCODE,
		out_dedupe_mapping_id => v_mapping_id_postcode
	);

	--activated
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_sap,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'ACTIVATED_DTM'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_ACTIVATED_DTM,
		out_dedupe_mapping_id => v_mapping_id_activated_dtm
	);

	--city
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_sap,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'CITY'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_CITY,
		out_dedupe_mapping_id => v_mapping_id_city
	);

	--website
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_sap,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'WEBSITE'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_WEBSITE,
		out_dedupe_mapping_id => v_mapping_id_website
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_sap,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'PARENT_COMPANY'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_PARENT,
		out_dedupe_mapping_id => v_mapping_id_parent
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_sap,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'SECTOR'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_SECTOR,
		out_dedupe_mapping_id => v_mapping_id_sector
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_sap,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'EMAIL'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_EMAIL,
		out_dedupe_mapping_id => v_mapping_id_email
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_sap,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'ACTIVE'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_ACTIVE,
		out_dedupe_mapping_id => v_mapping_id_active
	);

	--state
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_sap,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'STATE'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_STATE,
		out_dedupe_mapping_id => v_mapping_id_state
	);

	--tag_groups
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_sap,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'FACILITY_TYPE'),
		in_tag_group_id => test_chain_utils_pkg.GetTagGroupId('FACILITY_TYPE'),
		out_dedupe_mapping_id => v_mapping_id_facility_type
	);

	--Set rules
	--1st rule: country and name
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_id_country, v_mapping_id_name));

	dedupe_admin_pkg.TestSaveRuleSetForExactMatches(
		in_dedupe_rule_set_id	=> -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_sap,
		in_description			=> 'Country and name rule set',
		in_rule_set_position	=> 1,
		in_rule_ids				=> v_rule_ids,
		in_mapping_ids			=> v_mapping_ids,
		out_dedupe_rule_set_id	=> v_dedupe_rule_id_country_name
	);


	--2nd rule: company ref
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_id_vendor_ref));

	dedupe_admin_pkg.TestSaveRuleSetForExactMatches(
		in_dedupe_rule_set_id	=> -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_sap,
		in_description			=> 'Vendor ref rule set',
		in_rule_set_position	=> 2,
		in_rule_ids				=> v_rule_ids,
		in_mapping_ids			=> v_mapping_ids,
		out_dedupe_rule_set_id	=> v_dedupe_rule_id_ref
	);

	--3rd rule: postal_code, activated dtm and company type
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_id_postcode, v_mapping_id_activated_dtm, v_mapping_id_company_type));

	dedupe_admin_pkg.TestSaveRuleSetForExactMatches(
		in_dedupe_rule_set_id	=> -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_sap,
		in_description			=> 'Postcode, date and company type rule set',
		in_rule_set_position	=> 3,
		in_rule_ids				=> v_rule_ids,
		in_mapping_ids			=> v_mapping_ids,
		out_dedupe_rule_set_id	=> v_dedupe_rule_id_post_act_ct
	);

	--Move UI system managed source to 2nd position
	UPDATE chain.import_source
	   SET position = 2
	 WHERE is_owned_by_system = 1;

	-----------------------
	--ADD NEW IMPORT SOURCE
	-----------------------
	v_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'BSCI_COMPANY_STAGING');

	dedupe_admin_pkg.SaveImportSource(
		in_import_source_id => -1,
		in_name => 'BSCI Company Integration',
		in_position => 3,
		in_no_match_action_id => chain_pkg.IGNORE_RECORD,
		in_lookup_key => 'BSCI_COMPANIES',
		out_import_source_id => v_source_id_bsci
	);

	--set up staging link
	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id_bsci,
		in_description 					=> 'BSCI company data integration',
		in_staging_tab_sid 				=> v_tab_sid,
		in_position 					=> 1,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'BSCI_VENDOR_NUM'),
		in_staging_batch_num_col_sid 	=> NULL,
		in_parent_staging_link_id 		=> NULL,
		in_destination_tab_sid 			=> NULL,
		out_dedupe_staging_link_id 		=> v_dedupe_staging_link_id_bsci
	);

	--Sector
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_bsci,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'SECTOR'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_SECTOR,
		out_dedupe_mapping_id => v_mapping_id_bsci_sector
	);

	--address
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_bsci,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'ADDRESS'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_ADDRESS,
		out_dedupe_mapping_id => v_mapping_id_bsci_address
	);

	--postcode
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_bsci,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'POSTCODE'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_POSTCODE,
		out_dedupe_mapping_id => v_mapping_id_bsci_postcode
	);

	--tag_groups
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_bsci,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'FACILITY_TYPE'),
		in_tag_group_id => test_chain_utils_pkg.GetTagGroupId('FACILITY_TYPE'),
		out_dedupe_mapping_id => v_mapping_id_bsci_fac_type
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_bsci,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'OWNERSHIP_TYPE'),
		in_tag_group_id => test_chain_utils_pkg.GetTagGroupId('OWNERSHIP_TYPE'),
		out_dedupe_mapping_id => v_mapping_id_bsci_own_type
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_bsci,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'COUNTRY'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id => v_mapping_id_bsci_country
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_bsci,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'VENDOR_NAME'),
		in_dedupe_field_id => chain.chain_pkg.FLD_COMPANY_NAME,
		out_dedupe_mapping_id => v_mapping_id_bsci_name
	);

	-----------------------
	--ADD NEW IMPORT SOURCE
	-----------------------
	v_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'TERTIARY_COMPANY_STAGING');

	dedupe_admin_pkg.SaveImportSource(
		in_import_source_id => -1,
		in_name => 'Tertiary Company Integration',
		in_position => 4,
		in_no_match_action_id => chain_pkg.IGNORE_RECORD,
		in_lookup_key => 'TERTIARY_COMPANIES',
		out_import_source_id => v_source_id_try
	);

	--set up staging link
	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id_try,
		in_description 					=> 'Tertiary company data integration',
		in_staging_tab_sid 				=> v_tab_sid,
		in_position 					=> 1,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'TERTIARY_VENDOR_NUM'),
		in_staging_batch_num_col_sid 	=> NULL,
		in_parent_staging_link_id 		=> NULL,
		in_destination_tab_sid 			=> NULL,
		out_dedupe_staging_link_id 		=> v_dedupe_staging_link_id_try
	);

	--Sector
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_try,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'SECTOR'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_SECTOR,
		out_dedupe_mapping_id => v_mapping_id_tertiary
	);

	--address
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_try,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'ADDRESS'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_ADDRESS,
		out_dedupe_mapping_id => v_mapping_id_tertiary
	);

	--postcode
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_try,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'POSTCODE'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_POSTCODE,
		in_fill_nulls_under_ui_source => 1,
		out_dedupe_mapping_id => v_mapping_id_tertiary
	);

	--tag_groups
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_try,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'FACILITY_TYPE'),
		in_tag_group_id => test_chain_utils_pkg.GetTagGroupId('FACILITY_TYPE'),
		out_dedupe_mapping_id => v_mapping_id_tertiary
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_try,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'OWNERSHIP_TYPE'),
		in_tag_group_id => test_chain_utils_pkg.GetTagGroupId('OWNERSHIP_TYPE'),
		out_dedupe_mapping_id => v_mapping_id_tertiary
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_try,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'COUNTRY'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id => v_mapping_id_tertiary
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_try,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'VENDOR_NAME'),
		in_dedupe_field_id => chain.chain_pkg.FLD_COMPANY_NAME,
		out_dedupe_mapping_id => v_mapping_id_try_name
	);
	
	--Set rules 2.1 (sector, address)
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_id_bsci_sector, v_mapping_id_bsci_address));

	dedupe_admin_pkg.TestSaveRuleSetForExactMatches(
		in_dedupe_rule_set_id	=> -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_bsci,
		in_description			=> 'Sector and address rule set',
		in_rule_set_position	=> 3,
		in_rule_ids				=> v_rule_ids,
		in_mapping_ids			=> v_mapping_ids,
		out_dedupe_rule_set_id	=> v_dedupe_rule_id_sect_addr
	);

	--Set rules 2.2 (tag_group, address)
	SELECT column_value
	  BULK COLLECT INTO v_mapping_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_id_bsci_fac_type, v_mapping_id_bsci_address));

	dedupe_admin_pkg.TestSaveRuleSetForExactMatches(
		in_dedupe_rule_set_id	=> -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_bsci,
		in_description			=> 'Facility type and address rule set',
		in_rule_set_position	=> 1,
		in_mapping_ids			=> v_mapping_ids,
		in_rule_ids				=> v_rule_ids,
		out_dedupe_rule_set_id	=> v_dedupe_rule_id_tg_addr
	);

	--Set rules 3.1 (reference)
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_id_try_name));

	dedupe_admin_pkg.TestSaveRuleSetForExactMatches(
		in_dedupe_rule_set_id	=> -1,
		in_dedupe_staging_link_id => v_dedupe_staging_link_id_try,
		in_description			=> 'Company Name',
		in_rule_set_position	=> 1,
		in_mapping_ids			=> v_mapping_ids,
		in_rule_ids				=> v_rule_ids,
		out_dedupe_rule_set_id	=> v_dedupe_rule_id_tg_addr
	);

	PopulateStagingCompanies;

	-----------------------
	--CREATE CHAIN COMPANIES
	--company 1 (should match using the name, country)
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'Eco-Products, Inc - BENZSTRASSE',
		in_country_code=> 'de',
		in_company_type_id=> v_vendor_ct_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid
	);

	company_pkg.ActivateCompany(v_company_sid);
	company_pkg.StartRelationship(v_top_company_sid, v_company_sid, null);
	company_pkg.ActivateRelationship(v_top_company_sid, v_company_sid);

	SELECT tag_id
	  BULK COLLECT INTO v_tag_ids
	  FROM csr.tag
	 WHERE lookup_key = 'CONSTRUCTION_SITE';

	company_pkg.SetTags(v_company_sid, v_tag_ids);

	--company 2 (should match using the ref)
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'Eco, inc',
		in_country_code=> 'us',
		in_company_type_id=> v_vendor_ct_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid
	);

	company_pkg.ActivateCompany(v_company_sid);
	company_pkg.StartRelationship(v_top_company_sid, v_company_sid, null);
	company_pkg.ActivateRelationship(v_top_company_sid, v_company_sid);

	INSERT INTO chain.company_reference (company_sid, value, reference_id, company_reference_id)
		VALUES(v_company_sid, '99086052', v_reference_id_1, company_reference_id_seq.nextval);

	--company 3 (no match)
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'Banvit A.'||chr(50590)||'.', --Ş
		in_country_code=> 'iq',
		in_company_type_id=> v_vendor_ct_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid
	);

	company_pkg.ActivateCompany(v_company_sid);
	company_pkg.StartRelationship(v_top_company_sid, v_company_sid, null);
	company_pkg.ActivateRelationship(v_top_company_sid, v_company_sid);

	--company 4 (match using postal_code, company type, activated_dtm)
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'Kouluria Imaathias', --mispelled on purpose
		in_country_code=> 'gr',
		in_company_type_id=> v_vendor_ct_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid
	);

	company_pkg.ActivateCompany(v_company_sid);
	company_pkg.StartRelationship(v_top_company_sid, v_company_sid, null);
	company_pkg.ActivateRelationship(v_top_company_sid, v_company_sid);

	UPDATE company
	   SET postcode = '59100',
	   activated_dtm = DATE '2000-08-15'
	 WHERE company_sid = v_company_sid;

	 --company 5 (multiple matches in ref rule with company 6)
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'Rice associates',
		in_country_code=> 'it',
		in_company_type_id=> v_vendor_ct_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid
	);

	company_pkg.ActivateCompany(v_company_sid);
	company_pkg.StartRelationship(v_top_company_sid, v_company_sid, null);
	company_pkg.ActivateRelationship(v_top_company_sid, v_company_sid);

	INSERT INTO chain.company_reference (company_sid, value, reference_id, company_reference_id)
		VALUES(v_company_sid, '5555444', v_reference_id_1, company_reference_id_seq.nextval);

	--company 6 (multiple matches in ref rule with company 5)
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'Rice partners',
		in_country_code=> 'it',
		in_company_type_id=> v_vendor_ct_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid
	);

	company_pkg.ActivateCompany(v_company_sid);
	company_pkg.StartRelationship(v_top_company_sid, v_company_sid, null);
	company_pkg.ActivateRelationship(v_top_company_sid, v_company_sid);

	INSERT INTO chain.company_reference (company_sid, value, reference_id, company_reference_id)
		VALUES(v_company_sid, '5555444', v_reference_id_1, company_reference_id_seq.nextval);

	--company 7 (used for bsci)
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'EGHOYAN',
		in_country_code=> 'gb',
		in_company_type_id=> v_vendor_ct_id,
		in_sector_id=> 1,
		out_company_sid=> v_company_sid
	);

	UPDATE company
	   SET address_1 = '18 WEST ROAD'
	 WHERE company_sid = v_company_sid;

	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid);

	company_pkg.ActivateCompany(v_company_sid);
	company_pkg.StartRelationship(v_top_company_sid, v_company_sid, null);
	company_pkg.ActivateRelationship(v_top_company_sid, v_company_sid);

	--company 8 (used for bsci)
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'ANTOINES',
		in_country_code=> 'fr',
		in_company_type_id=> v_vendor_ct_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid
	);

	UPDATE company
	   SET address_1 = '183 LACE AVE'
	 WHERE company_sid = v_company_sid;

	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid);

	company_pkg.ActivateCompany(v_company_sid);
	company_pkg.StartRelationship(v_top_company_sid, v_company_sid, null);
	company_pkg.ActivateRelationship(v_top_company_sid, v_company_sid);

	SELECT tag_id
	  BULK COLLECT INTO v_tag_ids
	  FROM csr.tag
	 WHERE lookup_key IN ('STORE', 'GARAGE');

	chain.company_pkg.SetTags (
		in_company_sid		=> v_company_sid,
		in_tag_ids			=> v_tag_ids
	);

	--company 9 (match on alternate company name)
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> 'ACME Co.',
		in_country_code=> 'gb',
		in_company_type_id=> v_vendor_ct_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid
	);

	company_pkg.savealtcompanyname(v_alt_comp_name_id, v_company_sid, 'ACME Company');

	chain.dedupe_preprocess_pkg.PreprocessCompany(v_company_sid);

	company_pkg.ActivateCompany(v_company_sid);
	company_pkg.StartRelationship(v_top_company_sid, v_company_sid, null);
	company_pkg.ActivateRelationship(v_top_company_sid, v_company_sid);
END;

PROCEDURE TearDown
AS
BEGIN
	--clear dedupe setup + dedupe results + chain supplier companies + staging table
	FOR r IN (
		SELECT lookup_key
		  FROM import_source
		 WHERE is_owned_by_system = 0
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

	DELETE FROM reference_company_type
	 WHERE reference_id IN (
		SELECT reference_id
		  FROM reference
		 WHERE lookup_key IN ('SAP1_COMPANY_REF', 'COMPANY_SECONDARY_REF')
	 );

	DELETE FROM reference
	 WHERE lookup_key IN ('SAP1_COMPANY_REF', 'COMPANY_SECONDARY_REF');

	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.sap_company_staging';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.bsci_company_staging';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.tertiary_company_staging';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;
END;

PROCEDURE TearDownFixture
AS
BEGIN
	test_chain_utils_pkg.TearDownSingleTier;
	test_chain_utils_pkg.TearDownTwoTier;

	DELETE FROM sector;

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
END;

END;
/
