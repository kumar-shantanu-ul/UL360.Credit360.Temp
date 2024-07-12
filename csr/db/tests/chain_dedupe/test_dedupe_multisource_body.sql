CREATE OR REPLACE PACKAGE BODY chain.test_dedupe_multisource_pkg AS

v_site_name						VARCHAR2(200);
v_source_id_1					NUMBER;
v_source_id_2					NUMBER;
v_supplier_company_type_id		NUMBER;
v_tab_comp_sid					NUMBER;
v_tab_user_sid					NUMBER;
v_tab_cms_sid					NUMBER;
v_tab_dest_sid					NUMBER;
v_tab_dest2_sid					NUMBER;
v_reference_id_1				NUMBER;
v_reference_id_2				NUMBER;
v_mapping_ref					NUMBER;
v_mapping_id					NUMBER;
v_dedupe_rule_set_id_1			NUMBER;
v_role_sid_1					NUMBER;

SOURCE_A	CONSTANT NUMBER := 1;
SOURCE_B	CONSTANT NUMBER := 2;

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

	helper_pkg.SaveReferenceLabel(
		in_reference_id	=> NULL,
		in_lookup_key => 'COMPANY_ID_SOURCE_A',
		in_label => 'Company id (Source A)',
		in_mandatory => 0,
		in_reference_uniqueness_id => 2, /* Global */
		in_reference_location_id => 0, /* Show on the company details card */
		in_company_type_ids	=> v_company_type_ids,
		out_reference_id => v_reference_id_1
	);

	helper_pkg.SaveReferenceLabel(
		in_reference_id	=> NULL,
		in_lookup_key => 'COMPANY_ID_SOURCE_B',
		in_label => 'Company id (Source B)',
		in_mandatory => 0,
		in_reference_uniqueness_id => 2, /* Global */
		in_reference_location_id => 0, /* Show on the company details card */
		in_company_type_ids	=> v_company_type_ids,
		out_reference_id => v_reference_id_2
	);

	v_role_sid_1 := csr.unit_test_pkg.GetOrCreateRole('ROLE_1');

	chain.test_chain_utils_pkg.LinkRoleToCompanyType(v_role_sid_1, 'SUPPLIER');
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

	DELETE FROM company_type_role
	 WHERE role_sid IN (v_role_sid_1);

	UPDATE csr.role
	   SET is_system_managed = 0
	 WHERE role_sid IN (v_role_sid_1);

	security.securableobject_pkg.DeleteSO(security_pkg.getact, v_role_sid_1);

	test_chain_utils_pkg.DeleteFullyCompaniesOfType('SUPPLIER');

	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.company_product';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.company_extra';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.company_staging';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.user_staging';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.cms_staging';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.product';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.score_band';
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
		 WHERE lookup_key IN ('COMPANY_ID_SOURCE_A', 'COMPANY_ID_SOURCE_B')
	 );

	DELETE FROM reference
	 WHERE lookup_key IN ('COMPANY_ID_SOURCE_A', 'COMPANY_ID_SOURCE_B');

	test_chain_utils_pkg.TearDownSingleTier;
END;

-- private
PROCEDURE AddCompanyStagingRow(
	in_batch_num		IN NUMBER,
	in_company_id		IN VARCHAR2,
	in_source_lookup	IN VARCHAR2,
	in_name				IN VARCHAR2,
	in_country			IN VARCHAR2,
	in_revenue			IN NUMBER DEFAULT NULL,
	in_score_band		IN VARCHAR2 DEFAULT NULL,
	in_score			IN NUMBER DEFAULT NULL,
	in_assessment_date	IN DATE DEFAULT NULL,
	in_comments			IN VARCHAR2 DEFAULT NULL,
	in_expenses_string	IN VARCHAR2 DEFAULT NULL,
	in_purchaser_sid	IN NUMBER DEFAULT NULL
)
AS
BEGIN
	EXECUTE IMMEDIATE ('
		INSERT INTO rag.company_staging(
			company_staging_id,
			batch_num,
			company_id,
			source,
			name,
			country,
			revenue,
			score_band,
			score,
			assessment_date,
			comments,
			expenses_string,
			purchaser_sid
		)
		VALUES(
			cms.item_id_seq.nextval,
			:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12
		)'
	)
	USING in_batch_num, in_company_id, in_source_lookup, in_name, in_country,
		in_revenue, in_score_band, in_score, in_assessment_date,
		in_comments, in_expenses_string, in_purchaser_sid;
END;

PROCEDURE AddUserStagingRow(
	in_company_id		IN VARCHAR2,
	in_batch_num		IN NUMBER,
	in_source_lookup	IN VARCHAR2,
	in_username			IN VARCHAR2,
	in_full_name		IN VARCHAR2,
	in_email			IN VARCHAR2,
	in_has_role_1		IN NUMBER
)
AS
BEGIN
	EXECUTE IMMEDIATE ('
		INSERT INTO rag.user_staging(
			user_staging_id,
			company_id,
			batch_num,
			source,
			username,
			fullname,
			email,
			role_1
		)
		VALUES(
			cms.item_id_seq.nextval,
			:1,:2,:3,:4,:5,:6,:7
		)'
	)
	USING in_company_id, in_batch_num, in_source_lookup, in_username, in_full_name, in_email, in_has_role_1;
END;

PROCEDURE AddCMSStagingRow(
	in_company_id		IN VARCHAR2,
	in_batch_num		IN NUMBER,
	in_source_lookup	IN VARCHAR2,
	in_revenue			IN VARCHAR2,
	in_product_descr	IN VARCHAR2
)
AS
BEGIN
	EXECUTE IMMEDIATE ('
		INSERT INTO rag.cms_staging(
			cms_staging_id,
			company_id,
			batch_num,
			source,
			revenue,
			product_description
		)
		VALUES(
			cms.item_id_seq.nextval,
			:1,:2,:3,:4,:5
		)'
	)
	USING in_company_id, in_batch_num, in_source_lookup, in_revenue, in_product_descr;
END;

FUNCTION SaveImportSource(
	in_num		NUMBER
)RETURN NUMBER
AS
	v_source_id						NUMBER;
	v_staging_link_id_1				NUMBER;
	v_staging_link_id_2				NUMBER;
	v_staging_link_id_3				NUMBER;
	v_vendor_company_type_id		NUMBER;

	v_mapping_ids					security.security_pkg.T_SID_IDS;
	v_rule_ids						security.security_pkg.T_SID_IDS;
	v_rule_type_ids					security.security_pkg.T_SID_IDS;
	v_match_thresholds				helper_pkg.T_NUMBER_ARRAY;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	v_tab_comp_sid := cms.tab_pkg.GetTableSid('RAG', 'COMPANY_STAGING');
	v_tab_user_sid := cms.tab_pkg.GetTableSid('RAG', 'USER_STAGING');
	v_tab_cms_sid  := cms.tab_pkg.GetTableSid('RAG', 'CMS_STAGING');
	v_tab_dest_sid := cms.tab_pkg.GetTableSid('RAG', 'COMPANY_PRODUCT');
	v_tab_dest2_sid := cms.tab_pkg.GetTableSid('RAG', 'COMPANY_EXTRA');

	dedupe_admin_pkg.SaveImportSource(
		in_import_source_id => -1,
		in_name => CASE in_num WHEN SOURCE_A THEN 'Source A' ELSE 'Source B' END,
		in_position => in_num,
		in_no_match_action_id => chain_pkg.AUTO_CREATE,
		in_lookup_key => CASE in_num WHEN SOURCE_A THEN 'SOURCE_A' ELSE 'SOURCE_B' END,
		out_import_source_id => v_source_id
	);
	
	--set up staging links
	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id,
		in_description 					=> 'Company',
		in_staging_tab_sid 				=> v_tab_comp_sid,
		in_position 					=> 1,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_tab_comp_sid, 'COMPANY_ID'),
		in_staging_batch_num_col_sid 	=> cms.tab_pkg.GetColumnSid(v_tab_comp_sid, 'BATCH_NUM'),
		in_staging_src_lookup_col_sid 	=> cms.tab_pkg.GetColumnSid(v_tab_comp_sid, 'SOURCE'),
		in_parent_staging_link_id 		=> NULL,
		in_destination_tab_sid 			=> v_tab_dest2_sid,
		out_dedupe_staging_link_id 		=> v_staging_link_id_1
	);

	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id,
		in_description 					=> 'Users',
		in_staging_tab_sid 				=> v_tab_user_sid,
		in_position 					=> 2,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_tab_user_sid, 'COMPANY_ID'),
		in_staging_batch_num_col_sid 	=> cms.tab_pkg.GetColumnSid(v_tab_user_sid, 'BATCH_NUM'),
		in_staging_src_lookup_col_sid 	=> cms.tab_pkg.GetColumnSid(v_tab_user_sid, 'SOURCE'),
		in_parent_staging_link_id 		=> v_staging_link_id_1,
		in_destination_tab_sid 			=> NULL,
		out_dedupe_staging_link_id 		=> v_staging_link_id_2
	);

	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id,
		in_description 					=> 'CMS',
		in_staging_tab_sid 				=> v_tab_cms_sid,
		in_position 					=> 3,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_tab_cms_sid, 'COMPANY_ID'),
		in_staging_batch_num_col_sid 	=> cms.tab_pkg.GetColumnSid(v_tab_cms_sid, 'BATCH_NUM'),
		in_staging_src_lookup_col_sid 	=> cms.tab_pkg.GetColumnSid(v_tab_cms_sid, 'SOURCE'),
		in_parent_staging_link_id 		=> v_staging_link_id_1,
		in_destination_tab_sid 			=> v_tab_dest_sid,
		out_dedupe_staging_link_id 		=> v_staging_link_id_3
	);

	--setup mappings
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_tab_comp_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_comp_sid, 'COMPANY_ID'),
		in_reference_id	=> CASE in_num WHEN SOURCE_A THEN v_reference_id_1 WHEN SOURCE_B THEN v_reference_id_2 ELSE NULL END,
		out_dedupe_mapping_id => v_mapping_ref
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_tab_comp_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_comp_sid, 'NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_tab_comp_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_comp_sid, 'COUNTRY'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_tab_comp_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_comp_sid, 'REVENUE'),
		in_destination_tab_sid => v_tab_dest2_sid,
		in_destination_col_sid	=> 	cms.tab_pkg.GetColumnSid(v_tab_dest2_sid, 'REVENUE'),
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_tab_comp_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_comp_sid, 'SCORE_BAND'),
		in_destination_tab_sid => v_tab_dest2_sid,
		in_destination_col_sid	=> 	cms.tab_pkg.GetColumnSid(v_tab_dest2_sid, 'SCORE_BAND_ID'),
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_tab_comp_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_comp_sid, 'SCORE'),
		in_destination_tab_sid => v_tab_dest2_sid,
		in_destination_col_sid	=> 	cms.tab_pkg.GetColumnSid(v_tab_dest2_sid, 'SCORE'),
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_tab_comp_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_comp_sid, 'ASSESSMENT_DATE'),
		in_destination_tab_sid => v_tab_dest2_sid,
		in_destination_col_sid	=> 	cms.tab_pkg.GetColumnSid(v_tab_dest2_sid, 'ASSESSMENT_DATE'),
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_tab_comp_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_comp_sid, 'COMMENTS'),
		in_destination_tab_sid => v_tab_dest2_sid,
		in_destination_col_sid	=> 	cms.tab_pkg.GetColumnSid(v_tab_dest2_sid, 'COMMENTS'),
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_tab_comp_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_comp_sid, 'EXPENSES_STRING'),
		in_destination_tab_sid => v_tab_dest2_sid,
		in_destination_col_sid	=> 	cms.tab_pkg.GetColumnSid(v_tab_dest2_sid, 'EXPENSES_STRING'),
		out_dedupe_mapping_id => v_mapping_id
	);

	--Set rule sets
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_ref));

	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_EXACT;
	v_match_thresholds(1) := 100;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id_1,
		in_description				=> 'Reference rule set',
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_AUTO,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id_1
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_tab_user_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_user_sid, 'FULLNAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_FULL_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_tab_user_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_user_sid, 'USERNAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_USER_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_tab_user_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_user_sid, 'EMAIL'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_EMAIL,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_tab_user_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_user_sid, 'ROLE_1'),
		in_role_sid	=> v_role_sid_1,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_3,
		in_tab_sid => v_tab_cms_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_cms_sid, 'PRODUCT_DESCRIPTION'),
		in_destination_tab_sid => v_tab_dest_sid,
		in_destination_col_sid	=> 	cms.tab_pkg.GetColumnSid(v_tab_dest_sid, 'PRODUCT_ID'),
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_3,
		in_tab_sid => v_tab_cms_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_cms_sid, 'REVENUE'),
		in_destination_tab_sid => v_tab_dest_sid,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_tab_dest_sid, 'REVENUE'),
		out_dedupe_mapping_id => v_mapping_id
	);

	RETURN v_source_id;
END;

PROCEDURE ValidateProcessedRecord(
	in_processed_record_id	NUMBER,
	in_company_sid			security_pkg.T_SID_ID,
	in_expected_new			NUMBER DEFAULT 0
)
AS
	v_count			NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = in_processed_record_id
	   AND (in_expected_new = 0 AND matched_to_company_sid = in_company_sid
		OR in_expected_new = 1 AND created_company_sid = in_company_sid)
	   AND data_merged = 1;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Processed record data is not the expected one');
END;

PROCEDURE ValidateCompanyReference(
	in_company_sid			security_pkg.T_SID_ID,
	in_reference_id			NUMBER,
	in_value				VARCHAR2
)
AS
	v_count			NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM company_reference
	 WHERE company_sid = in_company_sid
	   AND reference_id = in_reference_id
	   AND value = in_value;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Company reference is not the expected one');
END;

PROCEDURE ValidateCmsData(
	in_company_sid	security_pkg.T_SID_ID,
	in_revenue		NUMBER,
	in_product_id	NUMBER
)
AS
	v_count			NUMBER;
	v_sql			VARCHAR2(1000);
BEGIN
	v_sql := '
		SELECT COUNT(*)
		  FROM rag.COMPANY_PRODUCT
		 WHERE company_sid = :1
		   AND revenue = :2
		   AND product_id = :3';

	EXECUTE IMMEDIATE v_sql
	   INTO v_count
	  USING in_company_sid, in_revenue, in_product_id;


	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'CMS data is not the expected one');
END;

PROCEDURE ValidateExtraCmsData(
	in_company_sid		security_pkg.T_SID_ID,
	in_revenue			NUMBER,
	in_band_id			NUMBER,
	in_score			NUMBER,
	in_assessment_date	DATE,
	in_comments			VARCHAR2,
	in_expenses_string	VARCHAR2
)
AS
	v_revenue			NUMBER;
	v_band_id			NUMBER;
	v_score				NUMBER;
	v_assessment_date	DATE;
	v_comments			VARCHAR2(255);
	v_expenses_string	VARCHAR2(255);
	v_sql				VARCHAR2(1000);
BEGIN
	v_sql := '
		SELECT revenue, score_band_id, score, assessment_date, comments, expenses_string
		  FROM rag.COMPANY_EXTRA
		 WHERE company_sid = :1';

	EXECUTE IMMEDIATE v_sql
	   INTO v_revenue, v_band_id, v_score, v_assessment_date, v_comments, v_expenses_string
	  USING in_company_sid;

	IF csr.null_pkg.ne(in_revenue, v_revenue) OR
		csr.null_pkg.ne(in_band_id, v_band_id) OR
		csr.null_pkg.ne(in_score, v_score) OR
		csr.null_pkg.ne(in_assessment_date, v_assessment_date) OR
		csr.null_pkg.ne(in_comments, v_comments) OR
		csr.null_pkg.ne(in_expenses_string, v_expenses_string)
	THEN
		csr.unit_test_pkg.TestFail('CMS extra data is not the expected one');
	END IF;
END;

PROCEDURE ValidateUserSid(
	in_username		csr.csr_user.user_name%TYPE,
	out_user_sid	OUT NUMBER
)
AS
BEGIN
	BEGIN
		SELECT csr_user_sid
		  INTO out_user_sid
		  FROM csr.csr_user
		 WHERE lower(user_name) = lower(in_username);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('User ' || in_username || ' was not created');
	END;
END;

PROCEDURE ValidateUserMembership(
	in_company_sid	security_pkg.T_SID_ID,
	in_user_sid		NUMBER
)
AS
	v_count			NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_user
	 WHERE company_sid = in_company_sid
	   AND user_sid = in_user_sid;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'CMS data is not the expected one');
END;

PROCEDURE ValidateRegionRoles(
	in_company_sid		NUMBER,
	in_user_sid			NUMBER,
	in_role_sid			NUMBER,
	in_exp_count		NUMBER
)
AS
	v_count						NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.region_role_member
	 WHERE app_sid = security_pkg.getapp
	   AND user_sid = in_user_sid
	   AND region_sid IN (SELECT region_sid FROM csr.supplier WHERE company_sid = in_company_sid)
	   AND role_sid = in_role_sid;

	csr.unit_test_pkg.AssertAreEqual(in_exp_count, v_count, 'Region roles data is not the expected one');
END;

PROCEDURE Test_Merge
AS
	v_processed_record_ids	security_pkg.T_SID_IDS;
	v_company_sid				NUMBER;
	v_user_sid					NUMBER;
BEGIN
	v_source_id_1 := SaveImportSource(SOURCE_A);
	v_source_id_2 := SaveImportSource(SOURCE_B);

	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;

	EXECUTE IMMEDIATE 'INSERT INTO rag.PRODUCT(PRODUCT_ID, DESCRIPTION) VALUES(1, ''Toothpaste'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.PRODUCT(PRODUCT_ID, DESCRIPTION) VALUES(2, ''Red wine'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.PRODUCT(PRODUCT_ID, DESCRIPTION) VALUES(3, ''Soap'')';

	EXECUTE IMMEDIATE 'INSERT INTO rag.SCORE_BAND(SCORE_BAND_ID, DESCRIPTION) VALUES(1, ''Green'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.SCORE_BAND(SCORE_BAND_ID, DESCRIPTION) VALUES(2, ''Amber'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.SCORE_BAND(SCORE_BAND_ID, DESCRIPTION) VALUES(3, ''Red'')';

	AddCompanyStagingRow(
		in_batch_num		=> 1,
		in_company_id		=> '100A',
		in_source_lookup	=> 'SOURCE_A',
		in_name				=> 'Company A',
		in_country			=> 'de',
		in_revenue			=> '90000',
		in_score_band		=> 'RED',
		in_score			=> '22',
		in_assessment_date	=> NULL,
		in_comments			=> NULL,
		in_expenses_string	=> NULL
	);

	AddCMSStagingRow(
		in_company_id		=> '100A',
		in_batch_num		=> '1',
		in_source_lookup	=> 'SOURCE_A',
		in_revenue			=> '500',
		in_product_descr	=> 'Toothpaste'
	);

	AddCMSStagingRow(
		in_company_id		=> '100A',
		in_batch_num		=> '1',
		in_source_lookup	=> 'SOURCE_A',
		in_revenue			=> '100',
		in_product_descr	=> 'Soap'
	);

	AddCompanyStagingRow(
		in_batch_num		=> 1,
		in_company_id		=> '100A',
		in_source_lookup	=> 'SOURCE_B',
		in_name				=> 'Company B',
		in_country			=> 'de',
		in_revenue			=> '85000',
		in_score_band		=> 'RED',
		in_score			=> '30',
		in_assessment_date	=> DATE '2000-12-24',
		in_comments			=> 'some comments',
		in_expenses_string	=> NULL
	);

	AddCMSStagingRow(
		in_company_id		=> '100A',
		in_batch_num		=> '1',
		in_source_lookup	=> 'SOURCE_B',
		in_revenue			=> '30000',
		in_product_descr	=> 'Red wine'
	);

	AddUserStagingRow(
		in_company_id		=> '100A',
		in_batch_num		=> '1',
		in_source_lookup	=> 'SOURCE_B',
		in_username			=> 'usr100200',
		in_full_name		=> 'Rachel Weissman',
		in_email			=> 'rachel.weis@globus.de',
		in_has_role_1		=> 1
	);

	AddUserStagingRow(
		in_company_id		=> '100A',
		in_batch_num		=> '1',
		in_source_lookup	=> 'SOURCE_B',
		in_username			=> 'usr200300',
		in_full_name		=> 'Nicholas Petterson',
		in_email			=> 'nick.p@globus.de',
		in_has_role_1		=> 0
	);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id_1,
		in_reference				=> '100A',
		in_batch_num				=> 1,
		out_processed_record_ids	=> v_processed_record_ids
	);

	csr.unit_test_pkg.AssertAreEqual(3, v_processed_record_ids.COUNT, 'Expected number of processed records is not the expected one');
	v_company_sid := test_chain_utils_pkg.GetChainCompanySid('Company A', 'de');

	ValidateProcessedRecord(v_processed_record_ids(1), v_company_sid, 1);
	ValidateCompanyReference(v_company_sid, v_reference_id_1, '100A');
	ValidateExtraCmsData(
		in_company_sid		=> v_company_sid,
		in_revenue			=> 90000,
		in_band_id			=> 3,
		in_score			=> 22,
		in_assessment_date	=> NULL,
		in_comments			=> NULL,
		in_expenses_string	=> NULL
	);
	ValidateCmsData(v_company_sid, 500, 1);
	ValidateCmsData(v_company_sid, 100, 3);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id_2,
		in_reference				=> '100A',
		in_batch_num				=> 1,
		out_processed_record_ids	=> v_processed_record_ids
	);

	csr.unit_test_pkg.AssertAreEqual(4, v_processed_record_ids.COUNT, 'Expected number of processed records is not the expected one');
	v_company_sid := test_chain_utils_pkg.GetChainCompanySid('Company B', 'de');

	ValidateProcessedRecord(v_processed_record_ids(1), v_company_sid, 1);
	ValidateCompanyReference(v_company_sid, v_reference_id_2, '100A');
	ValidateExtraCmsData(
		in_company_sid		=> v_company_sid,
		in_revenue			=> 85000,
		in_band_id			=> 3,
		in_score			=> 30,
		in_assessment_date	=> DATE '2000-12-24',
		in_comments			=> 'some comments',
		in_expenses_string	=> NULL
	);
	ValidateCmsData(v_company_sid, 30000, 2);

	ValidateUserSid('usr100200', v_user_sid);
	ValidateUserMembership(v_company_sid, v_user_sid);
	ValidateRegionRoles(
		in_company_sid	=> v_company_sid,
		in_user_sid		=> v_user_sid,
		in_role_sid		=> v_role_sid_1,
		in_exp_count	=> 1
	);

	ValidateUserSid('usr200300', v_user_sid);
	ValidateUserMembership(v_company_sid, v_user_sid);
	ValidateRegionRoles(
		in_company_sid	=> v_company_sid,
		in_user_sid		=> v_user_sid,
		in_role_sid		=> v_role_sid_1,
		in_exp_count	=> 0
	);
END;

FUNCTION SaveImportSource2(
	in_num		NUMBER
)RETURN NUMBER
AS
	v_source_id			NUMBER;
	v_staging_link_id_1	NUMBER;

	v_mapping_ids					security.security_pkg.T_SID_IDS;
	v_rule_ids						security.security_pkg.T_SID_IDS;
	v_rule_type_ids					security.security_pkg.T_SID_IDS;
	v_match_thresholds				helper_pkg.T_NUMBER_ARRAY;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	v_tab_comp_sid := cms.tab_pkg.GetTableSid('RAG', 'COMPANY_STAGING');

	dedupe_admin_pkg.SaveImportSource(
		in_import_source_id => -1,
		in_name => CASE in_num WHEN SOURCE_A THEN 'Source A' ELSE 'Source B' END,
		in_position => in_num,
		in_no_match_action_id => chain_pkg.AUTO_CREATE,
		in_lookup_key => CASE in_num WHEN SOURCE_A THEN 'SOURCE_A' ELSE 'SOURCE_B' END,
		out_import_source_id => v_source_id
	);

	--set up staging links
	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id,
		in_description 					=> 'Company',
		in_staging_tab_sid 				=> v_tab_comp_sid,
		in_position 					=> 1,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_tab_comp_sid, 'COMPANY_ID'),
		in_staging_batch_num_col_sid 	=> cms.tab_pkg.GetColumnSid(v_tab_comp_sid, 'BATCH_NUM'),
		in_staging_src_lookup_col_sid 	=> cms.tab_pkg.GetColumnSid(v_tab_comp_sid, 'SOURCE'),
		in_parent_staging_link_id 		=> NULL,
		in_destination_tab_sid 			=> v_tab_dest2_sid,
		out_dedupe_staging_link_id 		=> v_staging_link_id_1
	);

	--setup mappings
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_tab_comp_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_comp_sid, 'COMPANY_ID'),
		in_reference_id	=> CASE in_num WHEN SOURCE_A THEN v_reference_id_1 WHEN SOURCE_B THEN v_reference_id_2 ELSE NULL END,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_tab_comp_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_comp_sid, 'NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_NAME,
		in_allow_create_alt_comp_name => 1,
		out_dedupe_mapping_id => v_mapping_ref
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_tab_comp_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_comp_sid, 'COUNTRY'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_tab_comp_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_comp_sid, 'PURCHASER_SID'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_PURCHASER_COMPANY,
		out_dedupe_mapping_id => v_mapping_id
	);

	--Set rule sets
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_ref));

	v_rule_type_ids(1) := chain_pkg.RULE_TYPE_LEVENSHTEIN;
	v_match_thresholds(1) := 60;

	dedupe_admin_pkg.SaveRuleSet(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id_1,
		in_description				=> 'Reference rule set',
		in_dedupe_match_type_id		=> chain_pkg.DEDUPE_AUTO,
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		in_rule_type_ids			=> v_rule_type_ids,
		in_match_thresholds			=> v_match_thresholds,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id_1
	);

	RETURN v_source_id;
END;

PROCEDURE ValidateCompNameCntry(
	in_company_sid			security_pkg.T_SID_ID,
	in_expected_name		company.name%TYPE,
	in_expected_country		company.country_code%TYPE
)
AS
	v_company_name			company.name%TYPE;
	v_country_code			company.country_code%TYPE;
BEGIN
	SELECT name, country_code
	  INTO v_company_name, v_country_code
	  FROM company
	 WHERE company_sid = in_company_sid;

	csr.unit_test_pkg.AssertAreEqual(in_expected_name, v_company_name, 'Incorrect company name. Got - '||v_company_name||', Expected - '||in_expected_name);

	csr.unit_test_pkg.AssertAreEqual(in_expected_country, v_country_code, 'Incorrect country code. Got - '||v_country_code||', Expected - '||in_expected_country);
END;

PROCEDURE ValidateAltCompNames(
	in_company_sid			security_pkg.T_SID_ID,
	in_expected_count		NUMBER
)
AS
	v_count					NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_count
	  FROM alt_company_name
	 WHERE company_sid = in_company_sid
	   AND name IN ('Company B', 'Company C');

	csr.unit_test_pkg.AssertAreEqual(in_expected_count, v_count, 'Incorrect number of alternative company names. Got - '||v_count||', Expected - '||in_expected_count);
END;

PROCEDURE ValidateAltCompNameMergeLog(
	in_processed_record_id	dedupe_merge_log.dedupe_processed_record_id%TYPE,
	in_expected_desc		VARCHAR2
)
AS
	v_count					NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = in_processed_record_id
	   AND alt_comp_name_downgrade = 1
	   AND lower(current_desc_val) like in_expected_desc;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'There should be a merge log record for alternative company name.');
END;

PROCEDURE ValidateRelationship(
	in_company_sid			security_pkg.T_SID_ID,
	in_purchaser_sid		security_pkg.T_SID_ID
)
AS
	v_relationship_count	NUMBER;
BEGIN
	 SELECT	COUNT(*)
	   INTO	v_relationship_count
	   FROM	supplier_relationship
	  WHERE	purchaser_company_sid = in_purchaser_sid
	    AND	supplier_company_sid = in_company_sid;

	csr.unit_test_pkg.AssertAreEqual(1, v_relationship_count, 'No relationship found between supplier ('||in_company_sid||') and purchaser ('||in_purchaser_sid||')');
END;

PROCEDURE TestMultiSrcAltCompNameMerge
AS
	v_count 				NUMBER;
	v_company_sid			NUMBER;
	v_processed_record_ids	security_pkg.T_SID_IDS;
BEGIN
	v_source_id_1 := SaveImportSource2(SOURCE_A);
	v_source_id_2 := SaveImportSource2(SOURCE_B);
	
	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;

	AddCompanyStagingRow(
		in_batch_num		=> 1,
		in_company_id		=> '100A',
		in_source_lookup	=> 'SOURCE_A',
		in_name				=> 'Company A',
		in_country			=> 'de'
	);

	AddCompanyStagingRow(
		in_batch_num		=> 1,
		in_company_id		=> '100A',
		in_source_lookup	=> 'SOURCE_B',
		in_name				=> 'Company B',
		in_country			=> 'gb'
	);

	company_pkg.CreateCompany(
		in_name=> 'Company C',
		in_country_code=> 'de',
		in_company_type_id=> company_type_pkg.GetCompanyTypeId('SUPPLIER'),
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid
	);

	ValidateCompNameCntry(v_company_sid, 'Company C', 'de');

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id_1,
		in_reference				=> '100A',
		in_batch_num				=> 1,
		out_processed_record_ids	=> v_processed_record_ids
	);

	ValidateCompNameCntry(v_company_sid, 'Company A', 'de');

	ValidateAltCompNames(v_company_sid, 1);

	SELECT count(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_ids(1)
	   AND dedupe_field_id = chain_pkg.FLD_COMPANY_NAME;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'There should be a merge log record on company name.');

	ValidateAltCompNameMergeLog(v_processed_record_ids(1), '%higher%');

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id_2,
		in_reference				=> '100A',
		in_batch_num				=> 1,
		out_processed_record_ids	=> v_processed_record_ids
	);

	ValidateCompNameCntry(v_company_sid, 'Company A', 'de');

	ValidateAltCompNames(v_company_sid, 2);

	ValidateAltCompNameMergeLog(v_processed_record_ids(1), '%lower%');

	SELECT count(*)
	  INTO v_count
	  FROM company
	 WHERE name like '%Company %';

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Too many companies created.');
END;

PROCEDURE Test_Relationship_Merge
AS
	v_processed_record_ids		security_pkg.T_SID_IDS;
	v_company_sid				NUMBER;
	v_user_sid					NUMBER;
	v_supplier_company_type_id	NUMBER;
	v_supplier_sid_1			NUMBER;
	v_supplier_sid_2			NUMBER;
BEGIN
	v_source_id_1 := SaveImportSource2(SOURCE_A);
	v_source_id_2 := SaveImportSource2(SOURCE_B);

	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;

	v_supplier_company_type_id := company_type_pkg.GetCompanyTypeId('SUPPLIER');

	-- create some purchasers
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> 'UL Purchaser 1',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_supplier_company_type_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_supplier_sid_1
	);
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> 'UL Purchaser 2',
		in_country_code			=> 'us',
		in_company_type_id		=> v_supplier_company_type_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_supplier_sid_2
	);

	AddCompanyStagingRow(
		in_batch_num		=> 1,
		in_company_id		=> '100A',
		in_source_lookup	=> 'SOURCE_A',
		in_name				=> 'Company A',
		in_country			=> 'de',
		in_revenue			=> '90000',
		in_score_band		=> 'RED',
		in_score			=> '22',
		in_assessment_date	=> NULL,
		in_comments			=> NULL,
		in_expenses_string	=> NULL,
		in_purchaser_sid	=> v_supplier_sid_1
	);

	AddCompanyStagingRow(
		in_batch_num		=> 1,
		in_company_id		=> '100A',
		in_source_lookup	=> 'SOURCE_B',
		in_name				=> 'Company A',
		in_country			=> 'de',
		in_revenue			=> '90000',
		in_score_band		=> 'RED',
		in_score			=> '22',
		in_assessment_date	=> NULL,
		in_comments			=> NULL,
		in_expenses_string	=> NULL,
		in_purchaser_sid	=> v_supplier_sid_2
	);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id_1,
		in_reference				=> '100A',
		in_batch_num				=> 1,
		out_processed_record_ids	=> v_processed_record_ids
	);

	csr.unit_test_pkg.AssertAreEqual(1, v_processed_record_ids.COUNT, 'Expected number of processed records is not the expected one');

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id			=> v_source_id_2,
		in_reference				=> '100A',
		in_batch_num				=> 1,
		out_processed_record_ids	=> v_processed_record_ids
	);

	csr.unit_test_pkg.AssertAreEqual(1, v_processed_record_ids.COUNT, 'Expected number of processed records is not the expected one');

	v_company_sid := test_chain_utils_pkg.GetChainCompanySid('Company A', 'de');

	ValidateRelationship(
		in_company_sid		=> v_company_sid,
		in_purchaser_sid	=> v_supplier_sid_1
	);

	ValidateRelationship(
		in_company_sid		=> v_company_sid,
		in_purchaser_sid	=> v_supplier_sid_2
	);
END;

END;
/
