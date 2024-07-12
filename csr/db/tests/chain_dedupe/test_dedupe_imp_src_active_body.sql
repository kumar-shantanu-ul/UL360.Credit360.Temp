CREATE OR REPLACE PACKAGE BODY chain.test_dedupe_imp_src_active_pkg
IS

v_site_name						VARCHAR2(200);
v_top_company_sid				security.security_pkg.T_SID_ID;
v_vendor_company_sid_1			security.security_pkg.T_SID_ID;
v_vendor_company_sid_2			security.security_pkg.T_SID_ID;

v_top_company_type_id			NUMBER;
v_vendor_company_type_id		NUMBER;

v_import_source_id				NUMBER;
v_staging_link_id				NUMBER;

v_mapping_name_id				NUMBER;
v_mapping_country_id			NUMBER;

PROCEDURE LogOnAsAdmin
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
END;

PROCEDURE InitCompanyTypeIds
AS
BEGIN
	BEGIN
		v_top_company_sid := helper_pkg.GetTopCompanySid;
		
		v_top_company_type_id := company_type_pkg.GetCompanyTypeId('TOP');
		v_vendor_company_type_id := company_type_pkg.GetCompanyTypeId('VENDOR');
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
END;

PROCEDURE SetUpCompanies
AS
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
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_tag_group_id				NUMBER;
	v_tag_id					NUMBER;
BEGIN
	v_site_name := in_site_name;
	LogOnAsAdmin;

	test_chain_utils_pkg.SetupTwoTier;
	
	InitCompanyTypeIds;
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
	LogOnAsAdmin;
	--clear dedupe setup + dedupe results + chain supplier companies + staging table
	FOR r IN (
		SELECT lookup_key
		  FROM import_source
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND is_owned_by_system = 0
	)
	LOOP
		test_chain_utils_pkg.TearDownImportSource(r.lookup_key);
	END LOOP;

	--Move UI system managed source back to its original position
	UPDATE import_source
	   SET position = 0
	 WHERE is_owned_by_system = 1;

	--security.security_pkg.SetApp(security.security_pkg.GetApp);
	test_chain_utils_pkg.DeleteFullyCompaniesOfType('VENDOR');
	 
	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.company_staging';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;
END;

PROCEDURE TearDownFixture
AS
BEGIN
	LogOnAsAdmin;

	UPDATE customer_options
	   SET enable_dedupe_preprocess = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	test_chain_utils_pkg.TearDownTwoTier;
END;

PROCEDURE AddStagingRow(
	in_vendor_num				IN NUMBER,
	in_batch_num				IN NUMBER,
	in_vendor_name				IN VARCHAR2,
	in_city						IN VARCHAR2,
	in_country					IN VARCHAR2,
	in_active					IN NUMBER,
	in_activated_dtm			IN DATE DEFAULT NULL,
	in_deactivated_dtm			IN DATE DEFAULT NULL
)
AS
BEGIN
	EXECUTE IMMEDIATE ('
		INSERT INTO rag.company_staging(
			company_staging_id,
			vendor_num,
			batch_num,
			vendor_name,
			city,
			country,
			active,
			activated_dtm,
			deactivated_dtm
		)
		VALUES(
			cms.item_id_seq.nextval,
			:1,:2,:3,:4,:5,:6,:7,:8
		)'
	)
	USING in_vendor_num, in_batch_num, in_vendor_name, in_city, in_country,
		in_active, in_activated_dtm, in_deactivated_dtm;
END;

PROCEDURE SetupImportSource(
	in_override_company_active	IN import_source.override_company_active%TYPE
)
AS
BEGIN
	dedupe_admin_pkg.SaveImportSource(
		in_import_source_id 			=> -1,
		in_name							=> 'Company integration',
		in_position						=> 1,
		in_no_match_action_id			=> chain_pkg.DEDUPE_AUTO,
		in_lookup_key					=> 'COMPANY_DATA',
		in_override_company_active		=> in_override_company_active,
		out_import_source_id			=> v_import_source_id
	);
END;

PROCEDURE SetupSourceLinkAndMappings
AS
	v_tab_sid						NUMBER;
	v_mapping_id					NUMBER;
	v_mapping_ref_id				NUMBER;
BEGIN
	v_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'COMPANY_STAGING');

	--set up staging link
	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_import_source_id,
		in_description 					=> 'Company data integration',
		in_staging_tab_sid 				=> v_tab_sid,
		in_position 					=> 1,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'VENDOR_NUM'),
		in_staging_batch_num_col_sid 	=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'BATCH_NUM'),
		out_dedupe_staging_link_id 		=> v_staging_link_id
	);

	--setup mappings
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
		in_col_sid						=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'COUNTRY'),
		in_dedupe_field_id				=> chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id			=> v_mapping_country_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id			=> -1,
		in_dedupe_staging_link_id		=> v_staging_link_id,
		in_tab_sid						=> v_tab_sid,
		in_col_sid						=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'ACTIVE'),
		in_dedupe_field_id				=> chain_pkg.FLD_COMPANY_ACTIVE,
		out_dedupe_mapping_id			=> v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id			=> -1,
		in_dedupe_staging_link_id		=> v_staging_link_id,
		in_tab_sid						=> v_tab_sid,
		in_col_sid						=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'ACTIVATED_DTM'),
		in_dedupe_field_id				=> chain_pkg.FLD_COMPANY_ACTIVATED_DTM,
		out_dedupe_mapping_id			=> v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id			=> -1,
		in_dedupe_staging_link_id		=> v_staging_link_id,
		in_tab_sid						=> v_tab_sid,
		in_col_sid						=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'DEACTIVATED_DTM'),
		in_dedupe_field_id				=> chain_pkg.FLD_COMPANY_DEACTIVATED_DTM,
		out_dedupe_mapping_id			=> v_mapping_id
	);
END;

PROCEDURE SetupNameAndCountryRuleSet
AS
	v_mapping_ids					security.security_pkg.T_SID_IDS;
	v_rule_ids						security.security_pkg.T_SID_IDS;
	v_rule_type_ids					security.security_pkg.T_SID_IDS;
	v_match_thresholds				helper_pkg.T_NUMBER_ARRAY;
	v_dedupe_rule_set_id			NUMBER;
BEGIN
	--set rule sets
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_name_id, v_mapping_country_id));

	--need arrays of dedupe_rule_id and thresholds
	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_EXACT;
	v_rule_type_ids(2) := chain_pkg.RULE_TYPE_EXACT;
	v_match_thresholds(1) := 100;
	v_match_thresholds(2) := 100;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id			=> -1,
		in_dedupe_staging_link_id		=> v_staging_link_id,
		in_description					=> 'Exact name and country rule set',
		in_dedupe_match_type_id			=> chain_pkg.DEDUPE_AUTO,
		in_rule_set_position			=> 1,
		in_rule_ids						=> v_rule_ids,
		in_mapping_ids					=> v_mapping_ids,
		in_rule_type_ids				=> v_rule_type_ids,
		in_match_thresholds				=> v_match_thresholds,
		out_dedupe_rule_set_id			=> v_dedupe_rule_set_id
	);
END;

PROCEDURE AssertCreatedCompany(
	in_processed_record_id			IN NUMBER,
	in_active_expected				IN NUMBER,
	in_activated_dtm_expected		IN DATE DEFAULT NULL,
	in_deactivated_dtm_expected		IN DATE DEFAULT NULL
)
AS
	v_created_company_sid			security.security_pkg.T_SID_ID;
	v_active_actual					NUMBER;
	v_activated_dtm_actual			DATE;
	v_deactivated_dtm_actual		DATE;
	v_count							NUMBER;
BEGIN
	SELECT created_company_sid
	  INTO v_created_company_sid
	  FROM dedupe_processed_record
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND dedupe_processed_record_id = in_processed_record_id;

	SELECT active, activated_dtm, deactivated_dtm
	  INTO v_active_actual, v_activated_dtm_actual, v_deactivated_dtm_actual
	  FROM company
	 WHERE company_sid = v_created_company_sid;

	csr.unit_test_pkg.AssertAreEqual(in_active_expected, v_active_actual, 'Created company active status is invalid');

	IF in_active_expected = 1 THEN
		SELECT COUNT(*)
		  INTO v_count
		  FROM dedupe_merge_log
		 WHERE dedupe_processed_record_id = in_processed_record_id
		   AND dedupe_field_id = chain_pkg.FLD_COMPANY_ACTIVE
		   AND new_val = 1;

		csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for active field');
	END IF;
	
	IF in_activated_dtm_expected IS NOT NULL THEN
		csr.unit_test_pkg.AssertAreEqual(TRUNC(in_activated_dtm_expected), TRUNC(v_activated_dtm_actual), 'Created company activated date is invalid');
	END IF;

	IF in_deactivated_dtm_expected IS NOT NULL THEN
		csr.unit_test_pkg.AssertAreEqual(TRUNC(in_deactivated_dtm_expected), TRUNC(v_deactivated_dtm_actual), 'Created company deactivated date is invalid');
	END IF;
END;

PROCEDURE AssertRegionActiveStatus(
	in_company_sid		IN NUMBER,
	in_active_expected	IN NUMBER
)
AS
	v_region_sid	NUMBER;
	v_active		NUMBER;
BEGIN
	SELECT region_sid
	  INTO v_region_sid
	  FROM csr.supplier
	 WHERE company_sid = in_company_sid;

	SELECT active
	  INTO v_active
	  FROM csr.region
	 WHERE region_sid = v_region_sid; 

	csr.unit_test_pkg.AssertAreEqual(in_active_expected, v_active, 'Company''s region active status is not the expected one');
END;

PROCEDURE AssertMatchedCompany(
	in_processed_record_id			IN NUMBER,
	in_active_expected				IN NUMBER,
	in_stag_activated_dtm			IN DATE DEFAULT NULL,
	in_stag_deact_dtm				IN DATE DEFAULT NULL,
	in_activated_dtm_expected		IN DATE DEFAULT NULL,
	in_deactivated_dtm_expected		IN DATE DEFAULT NULL
)
AS
	v_matched_to_company_sid		security.security_pkg.T_SID_ID;
	v_active_actual					NUMBER;
	v_count							NUMBER;
	v_activated_dtm_actual			DATE;
	v_deactivated_dtm_actual		DATE;
	v_data_merged					dedupe_processed_record.data_merged%TYPE;
BEGIN
	SELECT matched_to_company_sid, data_merged
	  INTO v_matched_to_company_sid, v_data_merged
	  FROM dedupe_processed_record
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND dedupe_processed_record_id = in_processed_record_id;

	SELECT active, activated_dtm, deactivated_dtm
	  INTO v_active_actual, v_activated_dtm_actual, v_deactivated_dtm_actual
	  FROM company
	 WHERE company_sid = v_matched_to_company_sid;

	csr.unit_test_pkg.AssertAreEqual(in_active_expected, v_active_actual, 'Matched company active status is invalid'||v_matched_to_company_sid);

	AssertRegionActiveStatus(v_matched_to_company_sid, in_active_expected);
	
	IF in_activated_dtm_expected IS NOT NULL THEN
		csr.unit_test_pkg.AssertAreEqual(TRUNC(in_activated_dtm_expected), TRUNC(v_activated_dtm_actual), 'Matched company activated date is invalid');

		IF v_data_merged = 1 AND in_stag_activated_dtm IS NOT NULL THEN
			SELECT COUNT(*)
			  INTO v_count
			  FROM dedupe_merge_log
			 WHERE dedupe_processed_record_id = in_processed_record_id
			   AND dedupe_field_id = chain_pkg.FLD_COMPANY_ACTIVATED_DTM
			   AND TO_DATE (new_val, 'YYYY-MM-DD') = TO_DATE (v_activated_dtm_actual, 'YYYY-MM-DD');

			csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for activated date field');
		END IF;
	END IF;

	IF in_deactivated_dtm_expected IS NOT NULL THEN
		csr.unit_test_pkg.AssertAreEqual(TRUNC(in_deactivated_dtm_expected), TRUNC(v_deactivated_dtm_actual), 'Matched company deactivated date is invalid');

		IF v_data_merged = 1 AND in_stag_deact_dtm IS NOT NULL THEN
			SELECT COUNT(*)
			  INTO v_count
			  FROM dedupe_merge_log
			 WHERE dedupe_processed_record_id = in_processed_record_id
			   AND dedupe_field_id = chain_pkg.FLD_COMPANY_DEACTIVATED_DTM
			   AND TO_DATE (new_val, 'YYYY-MM-DD') = TO_DATE (v_deactivated_dtm_actual, 'YYYY-MM-DD');

			csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for activated date field');
		END IF;
	END IF;
END;

PROCEDURE TestCreatedCompany(
	in_vendor_num					IN NUMBER,
	in_vendor_name					IN VARCHAR2,
	in_active						IN NUMBER,
	in_active_expected				IN NUMBER
)
AS
	v_processed_record_ids 			security_pkg.T_SID_IDS;
BEGIN
	AddStagingRow(
		in_vendor_num				=> in_vendor_num,
		in_batch_num				=> 1,
		in_vendor_name				=> in_vendor_name,
		in_city						=> 'Cambridge',
		in_country					=> 'gb',
		in_active					=> in_active
	);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_import_source_id,
		in_reference				=> in_vendor_num,
		in_batch_num				=> 1,
		out_processed_record_ids	=> v_processed_record_ids
	);
	
	AssertCreatedCompany(
		in_processed_record_id		=> v_processed_record_ids(1),
		in_active_expected			=> in_active_expected
	);
END;

PROCEDURE TestImpSrcActiveNoNoMatch
AS
	v_vendor_num_list				T_NUMBERS;
	v_vendor_name_list				T_ARRAY;
	v_active_list					T_NUMBERS;
	v_active_expected_list			T_NUMBERS;
BEGIN
	LogOnAsAdmin;

	SetUpCompanies;
	
	SetupImportSource(
		in_override_company_active		=> 0
	);
	SetupSourceLinkAndMappings;
	SetupNameAndCountryRuleSet;
	
	v_vendor_num_list := T_NUMBERS(101, 102, 103);
	v_vendor_name_list := T_ARRAY('Vendor - C', 'Vendor - D', 'Vendor - E');
	v_active_list := T_NUMBERS(1, 0, NULL);
	v_active_expected_list := T_NUMBERS(1, 0, 1);

	-- No match is found, expect company is created with expected active status
	FOR i in 1..v_vendor_num_list.COUNT
	LOOP
		TestCreatedCompany(
			in_vendor_num			=> v_vendor_num_list(i),
			in_vendor_name			=> v_vendor_name_list(i),
			in_active				=> v_active_list(i),
			in_active_expected		=> v_active_expected_list(i)
		);
	END LOOP;
END;

PROCEDURE TestImpSrcActiveYesNoMatch
AS
	v_vendor_num_list				T_NUMBERS;
	v_vendor_name_list				T_ARRAY;
	v_active_list					T_NUMBERS;
	v_active_expected_list			T_NUMBERS;
BEGIN
	LogOnAsAdmin;

	SetUpCompanies;
	
	SetupImportSource(
		in_override_company_active		=> 1
	);
	SetupSourceLinkAndMappings;
	SetupNameAndCountryRuleSet;

	v_vendor_num_list := T_NUMBERS(101, 102, 103);
	v_vendor_name_list := T_ARRAY('Vendor - C', 'Vendor - D', 'Vendor - E');
	v_active_list := T_NUMBERS(1, 0, NULL);
	v_active_expected_list := T_NUMBERS(1, 1, 1);

	-- No match is found, expect company is created as active
	FOR i in 1..v_vendor_num_list.COUNT
	LOOP
		TestCreatedCompany(
			in_vendor_num			=> v_vendor_num_list(i),
			in_vendor_name			=> v_vendor_name_list(i),
			in_active				=> v_active_list(i),
			in_active_expected		=> v_active_expected_list(i)
		);
	END LOOP;
END;

PROCEDURE TestMatchedCompany(
	in_batch_num					IN NUMBER,
	in_active						IN NUMBER,
	in_active_expected				IN NUMBER
)
AS
	v_processed_record_ids 			security_pkg.T_SID_IDS;
BEGIN
	AddStagingRow(
		in_vendor_num				=> 101,
		in_batch_num				=> in_batch_num,
		in_vendor_name				=> 'Vendor - A',
		in_city						=> 'Cambridge',
		in_country					=> 'gb',
		in_active					=> in_active
	);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_import_source_id,
		in_reference				=> 101,
		in_batch_num				=> in_batch_num,
		out_processed_record_ids	=> v_processed_record_ids
	);
	
	AssertMatchedCompany(
		in_processed_record_id		=> v_processed_record_ids(1),
		in_active_expected			=> in_active_expected
	);	
END;

PROCEDURE TestImpSrcActiveNoMatch
AS
	TYPE T_NUMBERS                	IS TABLE OF NUMBER(10);
	v_batch_num_list				T_NUMBERS;
	v_active_list					T_NUMBERS := T_NUMBERS(1, 0, NULL);
	v_active_expected_list			T_NUMBERS;
BEGIN
	LogOnAsAdmin;

	SetUpCompanies;
	
	SetupImportSource(
		in_override_company_active		=> 0
	);
	SetupSourceLinkAndMappings;
	SetupNameAndCountryRuleSet;

	-- company is active
	-- match is found, expect company stays active (lower priority import source)
	v_batch_num_list := T_NUMBERS(101, 102, 103);
	v_active_expected_list := T_NUMBERS(1, 1, 1);
	
	FOR i in 1..v_batch_num_list.COUNT
	LOOP
		company_pkg.ReActivateCompany(
			in_company_sid				=> v_vendor_company_sid_1
		);
		TestMatchedCompany(
			in_batch_num			=> v_batch_num_list(i),
			in_active				=> v_active_list(i),
			in_active_expected		=> v_active_expected_list(i)
		);
	END LOOP;

	-- company is inactive
	-- match is found, expect company stays inactive (lower priority import source)
	v_batch_num_list := T_NUMBERS(104, 105, 106);
	v_active_expected_list := T_NUMBERS(0, 0, 0);
	
	FOR i in 1..v_batch_num_list.COUNT
	LOOP
		company_pkg.DeactivateCompany(
			in_company_sid				=> v_vendor_company_sid_1
		);
		TestMatchedCompany(
			in_batch_num			=> v_batch_num_list(i),
			in_active				=> v_active_list(i),
			in_active_expected		=> v_active_expected_list(i)
		);
	END LOOP;
	
	-- set UI import source to lower priority
	UPDATE chain.import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;

	-- company is active
	-- match is found, expect company active status is updated
	v_batch_num_list := T_NUMBERS(107, 108, 109);
	v_active_expected_list := T_NUMBERS(1, 0, 1);
	
	FOR i in 1..v_batch_num_list.COUNT
	LOOP
		company_pkg.ReActivateCompany(
			in_company_sid				=> v_vendor_company_sid_1
		);
		TestMatchedCompany(
			in_batch_num			=> v_batch_num_list(i),
			in_active				=> v_active_list(i),
			in_active_expected		=> v_active_expected_list(i)
		);
	END LOOP;

	-- company is inactive
	-- match is found, expect company active status is updated
	v_batch_num_list := T_NUMBERS(110, 111, 112);
	v_active_expected_list := T_NUMBERS(1, 0, 0);
	
	FOR i in 1..v_batch_num_list.COUNT
	LOOP
		company_pkg.DeactivateCompany(
			in_company_sid				=> v_vendor_company_sid_1
		);
		TestMatchedCompany(
			in_batch_num			=> v_batch_num_list(i),
			in_active				=> v_active_list(i),
			in_active_expected		=> v_active_expected_list(i)
		);
	END LOOP;
END;

PROCEDURE TestImpSrcActiveYesMatch
AS
	TYPE T_NUMBERS                	IS TABLE OF NUMBER(10);
	v_batch_num_list				T_NUMBERS;
	v_active_list					T_NUMBERS := T_NUMBERS(1, 0, NULL);
	v_active_expected_list			T_NUMBERS;
BEGIN
	LogOnAsAdmin;

	SetUpCompanies;
	
	SetupImportSource(
		in_override_company_active		=> 1
	);
	SetupSourceLinkAndMappings;
	SetupNameAndCountryRuleSet;

	-- company is active
	-- match is found, expect company active status is updated
	v_batch_num_list := T_NUMBERS(1, 2, 3);
	v_active_expected_list := T_NUMBERS(1, 1, 1);
	
	FOR i in 1..v_batch_num_list.COUNT
	LOOP
		company_pkg.ReActivateCompany(
			in_company_sid				=> v_vendor_company_sid_1
		);
		TestMatchedCompany(
			in_batch_num			=> v_batch_num_list(i),
			in_active				=> v_active_list(i),
			in_active_expected		=> v_active_expected_list(i)
		);
	END LOOP;

	-- company is inactive
	-- match is found, expect company active status is updated
	v_batch_num_list := T_NUMBERS(4, 5, 6);
	v_active_expected_list := T_NUMBERS(1, 0, 1);
	
	FOR i in 1..v_batch_num_list.COUNT
	LOOP
		company_pkg.DeactivateCompany(
			in_company_sid				=> v_vendor_company_sid_1
		);
		TestMatchedCompany(
			in_batch_num			=> v_batch_num_list(i),
			in_active				=> v_active_list(i),
			in_active_expected		=> v_active_expected_list(i)
		);
	END LOOP;
END;

PROCEDURE TestCreatedCompanyActDeactDtm(
	in_vendor_num					IN NUMBER,
	in_vendor_name					IN VARCHAR2,
	in_activated_dtm				IN DATE,
	in_deactivated_dtm				IN DATE,
	in_active_expected				IN NUMBER,
	in_activated_dtm_expected		IN DATE,
	in_deactivated_dtm_expected		IN DATE
)
AS
	v_processed_record_ids 			security_pkg.T_SID_IDS;
BEGIN
	AddStagingRow(
		in_vendor_num				=> in_vendor_num,
		in_batch_num				=> 1,
		in_vendor_name				=> in_vendor_name,
		in_city						=> 'Cambridge',
		in_country					=> 'gb',
		in_active					=> NULL,
		in_activated_dtm			=> in_activated_dtm,
		in_deactivated_dtm			=> in_deactivated_dtm
	);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_import_source_id,
		in_reference				=> in_vendor_num,
		in_batch_num				=> 1,
		out_processed_record_ids	=> v_processed_record_ids
	);
	
	AssertCreatedCompany(
		in_processed_record_id		=> v_processed_record_ids(1),
		in_active_expected			=> in_active_expected,
		in_activated_dtm_expected	=> in_activated_dtm_expected,
		in_deactivated_dtm_expected	=> in_deactivated_dtm_expected
	);
END;

PROCEDURE TestImpSrcNoNoMatchActDeactDtm
AS
	v_vendor_num_list				T_NUMBERS;
	v_vendor_name_list				T_ARRAY;
	v_active_list_expected			T_NUMBERS;
	v_activated_dtm_lst				T_DATE_ARRAY;
	v_activated_dtm_lst_expected	T_DATE_ARRAY;
	v_deactivated_dtm_lst			T_DATE_ARRAY;
	v_deactivated_dtm_lst_expected	T_DATE_ARRAY;
BEGIN
	LogOnAsAdmin;

	SetUpCompanies;
	
	SetupImportSource(
		in_override_company_active		=> 0
	);
	SetupSourceLinkAndMappings;
	SetupNameAndCountryRuleSet;
	
	v_vendor_num_list := T_NUMBERS(101, 102, 103, 104, 105);
	v_vendor_name_list := T_ARRAY('Vendor - C', 'Vendor - D', 'Vendor - E', 'Vendor - F', 'Vendor - G');

	v_activated_dtm_lst := T_DATE_ARRAY('5-AUG-2018', NULL, '10-JUL-2018', '01-AUG-2018', NULL);
	v_deactivated_dtm_lst := T_DATE_ARRAY(NULL, SYSDATE + 5, '10-JUN-2018', '10-AUG-2018', NULL);

	v_active_list_expected := T_NUMBERS(1, 0, 1, 0, 1);
	v_activated_dtm_lst_expected := T_DATE_ARRAY('5-AUG-2018', NULL, '10-JUL-2018', NULL, SYSDATE);
	v_deactivated_dtm_lst_expected := T_DATE_ARRAY(NULL, SYSDATE + 5, NULL, '10-AUG-2018', NULL);

	-- No match is found, expect company is created with expected active status
	FOR i in 1..v_vendor_num_list.COUNT
	LOOP
		TestCreatedCompanyActDeactDtm(
			in_vendor_num				=> v_vendor_num_list(i),
			in_vendor_name				=> v_vendor_name_list(i),
			in_activated_dtm			=> v_activated_dtm_lst(i),
			in_deactivated_dtm			=> v_deactivated_dtm_lst(i),
			in_active_expected			=> v_active_list_expected(i),
			in_activated_dtm_expected	=> v_activated_dtm_lst_expected(i),
			in_deactivated_dtm_expected	=> v_deactivated_dtm_lst_expected(i)
		);
	END LOOP;
END;

PROCEDURE TestImpSrcYsNoMatchActDeactDtm
AS
	v_vendor_num_list				T_NUMBERS;
	v_vendor_name_list				T_ARRAY;
	v_active_list_expected			T_NUMBERS;
	v_activated_dtm_lst				T_DATE_ARRAY;
	v_activated_dtm_lst_expected	T_DATE_ARRAY;
	v_deactivated_dtm_lst			T_DATE_ARRAY;
	v_deactivated_dtm_lst_expected	T_DATE_ARRAY;
BEGIN
	LogOnAsAdmin;

	SetUpCompanies;
	
	SetupImportSource(
		in_override_company_active		=> 1
	);
	SetupSourceLinkAndMappings;
	SetupNameAndCountryRuleSet;
	
	v_vendor_num_list := T_NUMBERS(101, 102, 103, 104, 105);
	v_vendor_name_list := T_ARRAY('Vendor - C', 'Vendor - D', 'Vendor - E', 'Vendor - F', 'Vendor - G');

	v_activated_dtm_lst := T_DATE_ARRAY('5-AUG-2018', NULL, '10-JUL-2018', '01-AUG-2018', NULL);
	v_deactivated_dtm_lst := T_DATE_ARRAY(NULL, SYSDATE + 5, '10-JUN-2018', '10-AUG-2018', NULL);

	v_active_list_expected := T_NUMBERS(1, 1, 1, 1, 1);
	v_activated_dtm_lst_expected := T_DATE_ARRAY('5-AUG-2018', SYSDATE, '10-JUL-2018', SYSDATE, SYSDATE);
	v_deactivated_dtm_lst_expected := T_DATE_ARRAY(NULL, NULL, NULL, NULL, NULL);

	-- No match is found, expect company is created with expected active status
	FOR i in 1..v_vendor_num_list.COUNT
	LOOP
		TestCreatedCompanyActDeactDtm(
			in_vendor_num				=> v_vendor_num_list(i),
			in_vendor_name				=> v_vendor_name_list(i),
			in_activated_dtm			=> v_activated_dtm_lst(i),
			in_deactivated_dtm			=> v_deactivated_dtm_lst(i),
			in_active_expected			=> v_active_list_expected(i),
			in_activated_dtm_expected	=> v_activated_dtm_lst_expected(i),
			in_deactivated_dtm_expected	=> v_deactivated_dtm_lst_expected(i)
		);
	END LOOP;
END;

PROCEDURE TestMatchedCompanyActDeactDtm(
	in_batch_num					IN NUMBER,
	in_activated_dtm				IN DATE,
	in_deactivated_dtm				IN DATE,
	in_active_expected				IN NUMBER,
	in_activated_dtm_expected		IN DATE,
	in_deactivated_dtm_expected		IN DATE
)
AS
	v_processed_record_ids 			security_pkg.T_SID_IDS;
BEGIN
	AddStagingRow(
		in_vendor_num				=> 101,
		in_batch_num				=> in_batch_num,
		in_vendor_name				=> 'Vendor - A',
		in_city						=> 'Cambridge',
		in_country					=> 'gb',
		in_active					=> NULL,
		in_activated_dtm			=> in_activated_dtm,
		in_deactivated_dtm			=> in_deactivated_dtm
	);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_import_source_id,
		in_reference				=> 101,
		in_batch_num				=> in_batch_num,
		out_processed_record_ids	=> v_processed_record_ids
	);
	
	AssertMatchedCompany(
		in_processed_record_id		=> v_processed_record_ids(1),
		in_active_expected			=> in_active_expected,
		in_stag_activated_dtm		=> in_activated_dtm,
		in_stag_deact_dtm			=> in_deactivated_dtm,
		in_activated_dtm_expected	=> in_activated_dtm_expected,
		in_deactivated_dtm_expected	=> in_deactivated_dtm_expected
	);
END;

PROCEDURE TestImpSrcNoMatchActDeactDtm
AS
	v_batch_num_list				T_NUMBERS;
	v_active_list_expected			T_NUMBERS;
	v_activated_dtm_lst				T_DATE_ARRAY;
	v_activated_dtm_lst_expected	T_DATE_ARRAY;
	v_deactivated_dtm_lst			T_DATE_ARRAY;
	v_deactivated_dtm_lst_expected	T_DATE_ARRAY;
	v_activated_dtm_expected		DATE;
	v_deactivated_dtm_expected		DATE;
BEGIN
	LogOnAsAdmin;

	SetUpCompanies;
	
	SetupImportSource(
		in_override_company_active		=> 0
	);
	SetupSourceLinkAndMappings;
	SetupNameAndCountryRuleSet;
	
	-- company is active
	-- match is found, expect company stays active (lower priority import source)
	v_batch_num_list := T_NUMBERS(1, 2, 3, 4, 5);
	v_activated_dtm_lst := T_DATE_ARRAY('5-AUG-2018', NULL, '10-JUL-2018', '01-AUG-2018', NULL);
	v_deactivated_dtm_lst := T_DATE_ARRAY(NULL, SYSDATE + 5, '10-JUN-2018', '10-AUG-2018', NULL);

	v_active_list_expected := T_NUMBERS(1, 1, 1, 1, 1);
	v_activated_dtm_lst_expected := T_DATE_ARRAY(SYSDATE, SYSDATE, SYSDATE, SYSDATE, SYSDATE);
	v_deactivated_dtm_lst_expected := T_DATE_ARRAY(NULL, NULL, NULL, NULL, NULL);

	FOR i in 1..v_batch_num_list.COUNT
	LOOP
		company_pkg.ReActivateCompany(
			in_company_sid				=> v_vendor_company_sid_1
		);

		TestMatchedCompanyActDeactDtm(
			in_batch_num				=> v_batch_num_list(i),
			in_activated_dtm			=> v_activated_dtm_lst(i),
			in_deactivated_dtm			=> v_deactivated_dtm_lst(i),
			in_active_expected			=> v_active_list_expected(i),
			in_activated_dtm_expected	=> v_activated_dtm_lst_expected(i),
			in_deactivated_dtm_expected	=> v_deactivated_dtm_expected
		);
	END LOOP;

	-- company is inactive
	-- match is found, expect company stays inactive (lower priority import source)
	v_batch_num_list := T_NUMBERS(6, 7, 8, 9, 10);
	v_activated_dtm_lst := T_DATE_ARRAY('5-AUG-2018', NULL, '10-JUL-2018', '01-AUG-2018', NULL);
	v_deactivated_dtm_lst := T_DATE_ARRAY(NULL, SYSDATE + 5, '10-JUN-2018', '10-AUG-2018', NULL);

	v_active_list_expected := T_NUMBERS(0, 0, 0, 0, 0);
	v_activated_dtm_lst_expected := T_DATE_ARRAY(SYSDATE, SYSDATE, SYSDATE, SYSDATE, SYSDATE);
	v_deactivated_dtm_lst_expected := T_DATE_ARRAY(SYSDATE, SYSDATE, SYSDATE, SYSDATE, SYSDATE);

	FOR i in 1..v_batch_num_list.COUNT
	LOOP
		company_pkg.ReActivateCompany(
			in_company_sid				=> v_vendor_company_sid_1
		);
		company_pkg.DeactivateCompany(
			in_company_sid				=> v_vendor_company_sid_1
		);

		TestMatchedCompanyActDeactDtm(
			in_batch_num				=> v_batch_num_list(i),
			in_activated_dtm			=> v_activated_dtm_lst(i),
			in_deactivated_dtm			=> v_deactivated_dtm_lst(i),
			in_active_expected			=> v_active_list_expected(i),
			in_activated_dtm_expected	=> v_activated_dtm_lst_expected(i),
			in_deactivated_dtm_expected	=> v_deactivated_dtm_lst_expected(i)
		);
	END LOOP;

	-- set UI import source to lower priority
	UPDATE chain.import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;

	-- company is active
	-- match is found, expect company active status is updated
	v_batch_num_list := T_NUMBERS(11, 12, 13, 14, 15);
	v_activated_dtm_lst := T_DATE_ARRAY('5-AUG-2018', NULL, '10-JUL-2018', '01-AUG-2018', NULL);
	v_deactivated_dtm_lst := T_DATE_ARRAY(NULL, SYSDATE + 5, '10-JUN-2018', '10-AUG-2018', NULL);

	v_active_list_expected := T_NUMBERS(1, 0, 1, 0, 1);
	v_activated_dtm_lst_expected := T_DATE_ARRAY('05-AUG-2018', NULL, '10-JUL-2018', NULL, SYSDATE);
	v_deactivated_dtm_lst_expected := T_DATE_ARRAY(NULL, SYSDATE + 5, NULL, '10-AUG-2018', NULL);

	FOR i in 1..v_batch_num_list.COUNT
	LOOP
		company_pkg.ReActivateCompany(
			in_company_sid				=> v_vendor_company_sid_1
		);

		TestMatchedCompanyActDeactDtm(
			in_batch_num				=> v_batch_num_list(i),
			in_activated_dtm			=> v_activated_dtm_lst(i),
			in_deactivated_dtm			=> v_deactivated_dtm_lst(i),
			in_active_expected			=> v_active_list_expected(i),
			in_activated_dtm_expected	=> v_activated_dtm_lst_expected(i),
			in_deactivated_dtm_expected	=> v_deactivated_dtm_lst_expected(i)
		);
	END LOOP;

	-- company is inactive
	-- match is found, expect company active status is updated
	v_batch_num_list := T_NUMBERS(16, 17, 18, 19, 20);
	v_activated_dtm_lst := T_DATE_ARRAY('5-AUG-2018', NULL, '10-JUL-2018', '01-AUG-2018', NULL);
	v_deactivated_dtm_lst := T_DATE_ARRAY(NULL, SYSDATE + 5, '10-JUN-2018', '10-AUG-2018', NULL);

	v_active_list_expected := T_NUMBERS(1, 0, 1, 0, 0);
	v_activated_dtm_lst_expected := T_DATE_ARRAY('05-AUG-2018', NULL, '10-JUL-2018', NULL, NULL);
	v_deactivated_dtm_lst_expected := T_DATE_ARRAY(NULL, SYSDATE + 5, NULL, '10-AUG-2018', NULL);

	FOR i in 1..v_batch_num_list.COUNT
	LOOP
		company_pkg.DeactivateCompany(
			in_company_sid				=> v_vendor_company_sid_1
		);

		TestMatchedCompanyActDeactDtm(
			in_batch_num				=> v_batch_num_list(i),
			in_activated_dtm			=> v_activated_dtm_lst(i),
			in_deactivated_dtm			=> v_deactivated_dtm_lst(i),
			in_active_expected			=> v_active_list_expected(i),
			in_activated_dtm_expected	=> v_activated_dtm_lst_expected(i),
			in_deactivated_dtm_expected	=> v_deactivated_dtm_lst_expected(i)
		);
	END LOOP;
END;

PROCEDURE TestImpSrcYesMatchActDeactDtm
AS
	v_batch_num_list				T_NUMBERS;
	v_active_list_expected			T_NUMBERS;
	v_activated_dtm_lst				T_DATE_ARRAY;
	v_activated_dtm_lst_expected	T_DATE_ARRAY;
	v_deactivated_dtm_lst			T_DATE_ARRAY;
	v_deactivated_dtm_lst_expected	T_DATE_ARRAY;
	v_activated_dtm_expected		DATE;
	v_deactivated_dtm_expected		DATE;
BEGIN
	LogOnAsAdmin;

	SetUpCompanies;
	
	SetupImportSource(
		in_override_company_active		=> 1
	);
	SetupSourceLinkAndMappings;
	SetupNameAndCountryRuleSet;
	
	-- company is active
	-- match is found, expect company stays active (lower priority import source)
	v_batch_num_list := T_NUMBERS(1, 2, 3, 4, 5);
	v_activated_dtm_lst := T_DATE_ARRAY('5-AUG-2018', NULL, '10-JUL-2018', '01-AUG-2018', NULL);
	v_deactivated_dtm_lst := T_DATE_ARRAY(NULL, SYSDATE + 5, '10-JUN-2018', '10-AUG-2018', NULL);

	v_active_list_expected := T_NUMBERS(1, 1, 1, 1, 1);
	v_activated_dtm_lst_expected := T_DATE_ARRAY('5-AUG-2018', '5-AUG-2018', '10-JUL-2018', '10-JUL-2018', '10-JUL-2018');
	v_deactivated_dtm_lst_expected := T_DATE_ARRAY(NULL, NULL, NULL, NULL, NULL);

	FOR i in 1..v_batch_num_list.COUNT
	LOOP
		company_pkg.ReActivateCompany(
			in_company_sid				=> v_vendor_company_sid_1
		);

		TestMatchedCompanyActDeactDtm(
			in_batch_num				=> v_batch_num_list(i),
			in_activated_dtm			=> v_activated_dtm_lst(i),
			in_deactivated_dtm			=> v_deactivated_dtm_lst(i),
			in_active_expected			=> v_active_list_expected(i),
			in_activated_dtm_expected	=> v_activated_dtm_lst_expected(i),
			in_deactivated_dtm_expected	=> v_deactivated_dtm_lst_expected(i)
		);
	END LOOP;

	-- company is inactive
	-- match is found, expect company status is updated as expected for activate
	v_batch_num_list := T_NUMBERS(6, 7, 8, 9, 10);
	v_activated_dtm_lst := T_DATE_ARRAY('5-AUG-2018', NULL, '10-JUL-2018', '01-AUG-2018', NULL);
	v_deactivated_dtm_lst := T_DATE_ARRAY(NULL, SYSDATE + 5, '10-JUN-2018', '10-AUG-2018', NULL);

	v_active_list_expected := T_NUMBERS(1, 0, 1, 0, 1);
	v_activated_dtm_lst_expected := T_DATE_ARRAY('05-AUG-2018', NULL, '10-JUL-2018', NULL, SYSDATE);
	v_deactivated_dtm_lst_expected := T_DATE_ARRAY(NULL, SYSDATE, NULL, SYSDATE, NULL);

	FOR i in 1..v_batch_num_list.COUNT
	LOOP
		company_pkg.DeactivateCompany(
			in_company_sid				=> v_vendor_company_sid_1
		);

		TestMatchedCompanyActDeactDtm(
			in_batch_num				=> v_batch_num_list(i),
			in_activated_dtm			=> v_activated_dtm_lst(i),
			in_deactivated_dtm			=> v_deactivated_dtm_lst(i),
			in_active_expected			=> v_active_list_expected(i),
			in_activated_dtm_expected	=> v_activated_dtm_lst_expected(i),
			in_deactivated_dtm_expected	=> v_deactivated_dtm_lst_expected(i)
		);
	END LOOP;
	
	-- set UI import source to lower priority
	UPDATE chain.import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;

	-- company is active
	-- match is found, expect company active status is updated
	v_batch_num_list := T_NUMBERS(11, 12, 13, 14, 15);
	v_activated_dtm_lst := T_DATE_ARRAY('5-AUG-2018', NULL, '10-JUL-2018', '01-AUG-2018', NULL);
	v_deactivated_dtm_lst := T_DATE_ARRAY(NULL, SYSDATE + 5, '10-JUN-2018', '10-AUG-2018', NULL);

	v_active_list_expected := T_NUMBERS(1, 0, 1, 0, 1);
	v_activated_dtm_lst_expected := T_DATE_ARRAY('5-AUG-2018', NULL, '10-JUL-2018', NULL, SYSDATE);
	v_deactivated_dtm_lst_expected := T_DATE_ARRAY(NULL, SYSDATE + 5, NULL, '10-AUG-2018', NULL);

	FOR i in 1..v_batch_num_list.COUNT
	LOOP
		company_pkg.ReActivateCompany(
			in_company_sid				=> v_vendor_company_sid_1
		);

		TestMatchedCompanyActDeactDtm(
			in_batch_num				=> v_batch_num_list(i),
			in_activated_dtm			=> v_activated_dtm_lst(i),
			in_deactivated_dtm			=> v_deactivated_dtm_lst(i),
			in_active_expected			=> v_active_list_expected(i),
			in_activated_dtm_expected	=> v_activated_dtm_lst_expected(i),
			in_deactivated_dtm_expected	=> v_deactivated_dtm_lst_expected(i)
		);
	END LOOP;
END;

END;
/
