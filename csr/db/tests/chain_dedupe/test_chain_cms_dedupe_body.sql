CREATE OR REPLACE PACKAGE BODY chain.test_chain_cms_dedupe_pkg AS

v_site_name					VARCHAR2(200);
v_source_id_1_1				NUMBER;
v_source_id_2_1				NUMBER;
v_source_id_2_2				NUMBER;
v_source_id_for_child		NUMBER;
v_source_id_for_turnover	NUMBER;
v_staging_link_id_1_1		NUMBER;
v_staging_link_id_2_1		NUMBER;
v_staging_link_id_2_2		NUMBER;
v_staging_link_id_3_1		NUMBER;
v_staging_link_id_3_2 		NUMBER;
v_staging_link_id_4_1		NUMBER;
v_staging_link_id_4_2		NUMBER;
v_staging_link_id_6_1		NUMBER;
v_staging_link_id_6_2		NUMBER;
v_staging_link_id_6_3		NUMBER;
v_staging_link_id_1_mult	NUMBER;
v_staging_link_id_2_mult	NUMBER;

v_mapping_ref_id			NUMBER;
v_reference_id				NUMBER;
v_mapping_user_id			NUMBER;
v_expected_user_sid_1		NUMBER;
v_expected_user_sid_2		NUMBER;
v_expected_user_sid_3		NUMBER;
v_mapping_revenue_id		NUMBER;
v_mapping_score_band_id		NUMBER;
v_expected_company_sid		NUMBER;
v_mapping_name_id			NUMBER;
v_another_company_sid_1		NUMBER;
v_another_company_sid_2		NUMBER;
v_another_company_sid_3		NUMBER;

v_reference_id_1			NUMBER;
v_reference_id_2			NUMBER;
v_reference_id_3			NUMBER;
v_reference_company_id		NUMBER;

v_staging_tab_sid_2_1		NUMBER;
v_staging_tab_sid_2_2		NUMBER;
v_destination_tab_sid_2		NUMBER;

v_staging_tab_sid_3_1		NUMBER;
v_staging_tab_sid_3_2		NUMBER;
v_destination_tab_sid_3		NUMBER;

v_staging_tab_sid_4_1		NUMBER;
v_staging_tab_sid_4_2		NUMBER;
v_destination_tab_sid_4		NUMBER;

v_staging_tab_sid_6_1		NUMBER;
v_staging_tab_sid_6_2		NUMBER;
v_staging_tab_sid_6_3		NUMBER;
v_destination_tab_sid_6_1	NUMBER;
v_destination_tab_sid_6_2	NUMBER;

PROCEDURE AddCmsChildRow (
	in_company_sid 		IN NUMBER,
	in_sales_org_id 	IN NUMBER,
	in_merch_cat_id 	IN NUMBER,
	in_revenue 			IN NUMBER,
	in_started_by_sid 	IN NUMBER,
	in_start_date 		IN DATE,
	in_comments 		IN VARCHAR2
)
AS
BEGIN
	EXECUTE IMMEDIATE ('
		INSERT INTO rag.COMPANY_SALES_ORG(
			COMPANY_SALES_ORG_ID,
			COMPANY_SID,
			SALES_ORG_ID,
			MERCH_CAT_ID,
			REVENUE,
			STARTED_BY_SID,
			START_DATE,
			COMMENTS
		)
		VALUES(
			cms.item_id_seq.nextval,
			:1,:2,:3,:4,:5,:6,:7
		)'
	)
	USING in_company_sid,
		in_sales_org_id,
		in_merch_cat_id,
		in_revenue,
		in_started_by_sid,
		in_start_date,
		in_comments;
END;

PROCEDURE AddCmsChild5Row (
	in_company_sid			IN NUMBER,
	in_reporting_year		IN NUMBER,
	in_revenue				IN NUMBER,
	in_another_company_sid	IN NUMBER DEFAULT NULL
)
AS
BEGIN
	EXECUTE IMMEDIATE ('
		INSERT INTO rag.COMPANY_DATA_4(
			COMPANY_DATA_ID,
			COMPANY_SID,
			REPORTING_YEAR,
			REVENUE,
			ANOTHER_COMPANY_SID
		)
		VALUES(
			cms.item_id_seq.nextval,
			:1,:2,:3,:4
		)'
	)
	USING in_company_sid,
		in_reporting_year,
		in_revenue,
		in_another_company_sid;
END;

-- private
PROCEDURE AddStagingRow(
	in_company_reference	IN VARCHAR2,
	in_name					IN VARCHAR2,
	in_country				IN VARCHAR2,
	in_revenue				IN NUMBER DEFAULT NULL,
	in_assessed_by			IN VARCHAR2 DEFAULT NULL,
	in_score_band			IN VARCHAR2 DEFAULT NULL,
	in_score				IN NUMBER DEFAULT NULL,
	in_assessment_date		IN DATE DEFAULT NULL,
	in_comments				IN VARCHAR2 DEFAULT NULL,
	in_expenses_string		IN VARCHAR2 DEFAULT NULL,
	in_fac_company_sid		IN NUMBER DEFAULT NULL,
	in_staging_table		IN VARCHAR2 DEFAULT 'CMS_COMPANY_STAGING'
)
AS
BEGIN
	EXECUTE IMMEDIATE ('
		INSERT INTO rag.'||in_staging_table||'(
			CMS_COMPANY_STAGING_ID,
			COMPANY_REFERENCE,
			NAME,
			COUNTRY,
			REVENUE,
			ASSESSED_BY,
			SCORE_BAND,
			SCORE,
			ASSESSMENT_DATE,
			COMMENTS,
			EXPENSES_STRING,
			FAC_COMPANY_SID
		)
		VALUES(
			cms.item_id_seq.nextval,
			:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11
		)'
	)
	USING in_company_reference,
		in_name,
		in_country,
		in_revenue,
		in_assessed_by,
		in_score_band,
		in_score,
		in_assessment_date,
		in_comments,
		in_expenses_string,
		in_fac_company_sid;
END;

PROCEDURE AddStaging3Row(
	in_company_id			IN VARCHAR2,
	in_ref_1				IN VARCHAR2,
	in_ref_2				IN VARCHAR2 DEFAULT NULL,
	in_ref_3				IN VARCHAR2 DEFAULT NULL,
	in_batch_num			IN NUMBER DEFAULT NULL,
	in_name					IN VARCHAR2,
	in_country				IN VARCHAR2
)
AS
BEGIN
	EXECUTE IMMEDIATE ('
		INSERT INTO rag.CMS_COMPANY_STAGING_3(
			CMS_COMPANY_STAGING_ID,
			COMPANY_ID,
			REF_1,
			REF_2,
			REF_3,
			BATCH_NUM,
			NAME,
			COUNTRY
		)
		VALUES(
			cms.item_id_seq.nextval,
			:1,:2,:3,:4,:5,:6,:7
		)'
	)
	USING in_company_id,
		in_ref_1,
		in_ref_2,
		in_ref_3,
		in_batch_num,
		in_name,
		in_country;
END;

PROCEDURE AddStaging4Row(
	in_company_id			IN NUMBER,
	in_name					IN VARCHAR2,
	in_country				IN VARCHAR2
)
AS
BEGIN
	EXECUTE IMMEDIATE ('
		INSERT INTO rag.CMS_COMPANY_STAGING_4(
			CMS_COMPANY_STAGING_ID,
			COMPANY_ID,
			NAME,
			COUNTRY
		)
		VALUES(
			cms.item_id_seq.nextval,
			:1,:2,:3
		)'
	)
	USING in_company_id,
		in_name,
		in_country;
END;

PROCEDURE AddChildStagingRow(
	in_company_id			IN VARCHAR2,
	in_sales_org			IN VARCHAR2,
	in_merch_cat			IN VARCHAR2,
	in_started_by			IN VARCHAR2 DEFAULT NULL,
	in_revenue				IN NUMBER DEFAULT NULL,
	in_started_date			IN DATE DEFAULT NULL,
	in_comments				IN VARCHAR2 DEFAULT NULL,
	in_batch_num			IN NUMBER DEFAULT NULL,
	in_deleted				IN NUMBER DEFAULT NULL,
	in_band_label			IN VARCHAR2 DEFAULT NULL
)
AS
BEGIN
	EXECUTE IMMEDIATE ('
		INSERT INTO rag.CHILD_CMS_COMPANY_STAGING(
			CMS_COMPANY_STAGING_ID,
			COMPANY_ID,
			SALES_ORG,
			MERCH_CAT,
			STARTED_BY,
			REVENUE,
			START_DATE,
			COMMENTS,
			BATCH_NUM,
			DELETED,
			BAND_LABEL
		)
		VALUES(
			cms.item_id_seq.nextval,
			:1,:2,:3,:4,:5,:6,:7,:8,:9,:10
		)'
	)
	USING in_company_id,
		in_sales_org,
		in_merch_cat,
		in_started_by,
		in_revenue,
		in_started_date,
		in_comments,
		in_batch_num,
		in_deleted,
		in_band_label;
END;

PROCEDURE AddChildStaging4Row(
	in_company_id			IN NUMBER,
	in_reporting_year		IN NUMBER,
	in_revenue				IN NUMBER,
	in_another_company_sid	IN NUMBER DEFAULT NULL
)
AS
BEGIN
	EXECUTE IMMEDIATE ('
		INSERT INTO RAG.CHILD_CMS_COMPANY_STAGING_4(
			CHILD_CMS_COMPANY_STAGING_ID,
			COMPANY_ID,
			REPORTING_YEAR,
			REVENUE,
			ANOTHER_COMPANY_SID
		)
		VALUES(
			cms.item_id_seq.nextval,
			:1,:2,:3,:4
		)'
	)
	USING in_company_id,
		in_reporting_year,
		in_revenue,
		in_another_company_sid;
END;

PROCEDURE AddTurnoverStagingRow(
	in_supplier_id			IN NUMBER,
	in_m_company_sid		IN NUMBER,
	in_month_year			IN VARCHAR2,
	in_revenue				IN NUMBER,
	in_another_company_sid	IN NUMBER,
	in_batch_num			IN NUMBER
)
AS
BEGIN
	EXECUTE IMMEDIATE ('
		INSERT INTO RAG.TURNOVER_STAGING(
			TURNOVER_STAGING_ID,
			SUPPLIER_ID,
			M_COMPANY_SID,
			MONTH_YEAR,
			REVENUE,
			ANOTHER_COMPANY_SID,
			BATCH_NUM
		)
		VALUES(
			cms.item_id_seq.nextval,
			:1,:2,:3,:4,:5,:6
		)'
	)
	USING in_supplier_id,
		in_m_company_sid,
		in_month_year,
		in_revenue,
		in_another_company_sid,
		in_batch_num;
END;

PROCEDURE PopulateStagingCompanies
AS
BEGIN
	AddStagingRow(
		in_company_reference	=> '12345',
		in_name					=> 'Random inc',
		in_country				=> 'it',
		in_revenue				=> 500000.25,
		in_assessed_by			=> 'Kate Rye',
		in_score				=> 79.5,
		in_score_band			=> 'GREEN',
		in_assessment_date		=> DATE '2016-06-01',
		in_comments				=> 'Assessment completed',
		in_expenses_string		=> NULL
	);	
END;

PROCEDURE PopulateStagingCompanies2
AS
BEGIN
	NULL;
END;

PROCEDURE PopulateStagingCompanies3
AS
BEGIN
	NULL;
END;

PROCEDURE PopulateStagingCompanies4
AS
	v_supplier_company_type_id 		NUMBER := company_type_pkg.GetCompanyTypeId('SUPPLIER');
BEGIN
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> 'Another Random 1 inc',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_supplier_company_type_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_another_company_sid_1
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> 'Another Random 2 inc',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_supplier_company_type_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_another_company_sid_2
	);

	AddStaging4Row(
		in_company_id			=> 12345,
		in_name					=> 'Random inc',
		in_country				=> 'gb'
	);

	AddChildStaging4Row(
		in_company_id			=> 12345,
		in_reporting_year		=> 2014,
		in_revenue				=> 10000000,
		in_another_company_sid	=> v_another_company_sid_1
	);

	AddChildStaging4Row(
		in_company_id			=> 12345,
		in_reporting_year		=> 2015,
		in_revenue				=> 5000000,
		in_another_company_sid	=> v_another_company_sid_2
	);
END;

PROCEDURE PopulateStagingCompanies5
AS
	v_supplier_company_type_id 		NUMBER := company_type_pkg.GetCompanyTypeId('SUPPLIER');
BEGIN

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> 'Random inc',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_supplier_company_type_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_another_company_sid_1
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> 'Another Random 1 inc',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_supplier_company_type_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_another_company_sid_2
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> 'Another Random 2 inc',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_supplier_company_type_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_another_company_sid_3
	);

	-- exact name match with v_another_company_sid_1
	AddStaging4Row(
		in_company_id			=> 12345,
		in_name					=> 'Random inc',
		in_country				=> 'gb'
	);

	AddChildStaging4Row(
		in_company_id			=> 12345,
		in_reporting_year		=> 2016,
		in_revenue				=> 100000,
		in_another_company_sid	=> v_another_company_sid_3
	);

	AddChildStaging4Row(
		in_company_id			=> 12345,
		in_reporting_year		=> 2017,
		in_revenue				=> 500000,
		in_another_company_sid	=> v_another_company_sid_3
	);

	-- this record will be updated after dedupe process
	AddCmsChild5Row(
		in_company_sid			=> v_another_company_sid_1,
		in_reporting_year		=> 2016,
		in_revenue				=> 50000,
		in_another_company_sid	=> v_another_company_sid_2
	);
END;

PROCEDURE PopulateStagingCompanies6
AS
BEGIN
	-- reusing
	PopulateStagingCompanies5;

	AddChildStagingRow(
		in_company_id	=> '12345',
		in_sales_org	=> 'Salling',
		in_merch_cat	=> 'R5726 (S) LADIES COATS',
		in_started_by	=> NULL,
		in_revenue		=> 1010,
		in_started_date	=> NULL,
		in_comments		=> 'Exciting new range'
	);
	
	AddChildStagingRow(
		in_company_id	=> '12345',
		in_sales_org	=> 'E-Commerce',
		in_merch_cat	=> 'R5726 (S) LADIES COATS',
		in_started_by	=> NULL,
		in_revenue		=> 990,
		in_started_date	=> DATE '2012-1-15',
		in_comments		=> 'Thrilled to bits'
	);

	-- this record will be updated after dedupe process
	AddCmsChildRow(
		in_company_sid 	 	=> v_another_company_sid_1, -- set up in PopulateStagingCompanies5 - 12345
		in_sales_org_id  	=> 5, --E-Commerce
		in_merch_cat_id  	=> 1, --R5726 (S) LADIES COATS
		in_revenue 		 	=> 1000,
		in_started_by_sid 	=> NULL,
		in_start_date 	 	=> NULL,
		in_comments 	 	=> 'No comments'
	);
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);

	test_chain_utils_pkg.SetupSingleTier;
END;

PROCEDURE SetSite(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
END;

PROCEDURE TearDownFixture
AS
	v_count		 	NUMBER;
BEGIN
	test_chain_utils_pkg.TearDownSingleTier;
END;

PROCEDURE SetupSource(
	in_staging_table				IN VARCHAR2,
	in_destination_table			IN VARCHAR2,
	in_name							IN VARCHAR2,
	in_position						IN NUMBER,
	out_import_source_id			OUT NUMBER,
	out_dedupe_staging_link_id		OUT NUMBER
)
AS
	v_tab_sid						NUMBER;
	v_destination_tab_sid			NUMBER;
	v_mapping_id					NUMBER;
	v_mapping_ids					security.security_pkg.T_SID_IDS;
	v_rule_ids						security.security_pkg.T_SID_IDS;
	v_dedupe_rule_set_id			NUMBER;
BEGIN
	v_tab_sid := cms.tab_pkg.GetTableSid('RAG', in_staging_table);
	v_destination_tab_sid := cms.tab_pkg.GetTableSid('RAG', in_destination_table);
	
	dedupe_admin_pkg.SaveImportSource(
		in_import_source_id => -1, 
		in_name => in_name, 
		in_position => in_position, 
		in_no_match_action_id => chain_pkg.AUTO_CREATE, 
		in_lookup_key => in_name,
		out_import_source_id => out_import_source_id
	);
	
	--set up staging link 
	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> out_import_source_id,
		in_description 					=> 'Company data integration',
		in_staging_tab_sid 				=> v_tab_sid,
		in_position 					=> 1,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_tab_sid, 'COMPANY_REFERENCE'),
		in_staging_batch_num_col_sid 	=> NULL,
		in_parent_staging_link_id 		=> NULL,
		in_destination_tab_sid 			=> v_destination_tab_sid,
		out_dedupe_staging_link_id 		=> out_dedupe_staging_link_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => out_dedupe_staging_link_id, 
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => out_dedupe_staging_link_id,
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'COUNTRY'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id => v_mapping_id
	);
	
	--setup mappings
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => out_dedupe_staging_link_id, 
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'COMPANY_REFERENCE'),
		in_reference_id => v_reference_id,
		out_dedupe_mapping_id => v_mapping_ref_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => out_dedupe_staging_link_id, 
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'ASSESSED_BY'),
		in_destination_tab_sid	=> v_destination_tab_sid,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'ASSESSED_BY_SID'),
		out_dedupe_mapping_id => v_mapping_user_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => out_dedupe_staging_link_id, 
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'REVENUE'),
		in_destination_tab_sid	=> v_destination_tab_sid,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'REVENUE'),
		out_dedupe_mapping_id => v_mapping_revenue_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => out_dedupe_staging_link_id, 
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'SCORE_BAND'),
		in_destination_tab_sid	=> v_destination_tab_sid,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'SCORE_BAND_ID'),
		out_dedupe_mapping_id => v_mapping_score_band_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => out_dedupe_staging_link_id, 
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'SCORE'),
		in_destination_tab_sid	=> v_destination_tab_sid,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'SCORE'),
		out_dedupe_mapping_id => v_mapping_score_band_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => out_dedupe_staging_link_id, 
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'COMMENTS'),
		in_destination_tab_sid	=> v_destination_tab_sid,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'COMMENTS'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => out_dedupe_staging_link_id, 
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'ASSESSMENT_DATE'),
		in_destination_tab_sid	=> v_destination_tab_sid,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'LAST_ASSESS_DATE'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => out_dedupe_staging_link_id, 
		in_tab_sid => v_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'EXPENSES_STRING'),
		in_destination_tab_sid	=> v_destination_tab_sid,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'EXPENSES'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	IF in_staging_table = 'CMS_COMPANY_STAGING' THEN
		dedupe_admin_pkg.SaveMapping(
			in_dedupe_mapping_id => -1, 
			in_dedupe_staging_link_id => out_dedupe_staging_link_id, 
			in_tab_sid => v_tab_sid,
			in_col_sid => cms.tab_pkg.GetColumnSid(v_tab_sid, 'FAC_COMPANY_SID'),
			in_destination_tab_sid	=> v_destination_tab_sid,
			in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'FACILITY_COMPANY_SID'),
			out_dedupe_mapping_id => v_mapping_id
		);
	END IF;
	
	--Set rules
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_ref_id));
	  
	dedupe_admin_pkg.TestSaveRuleSetForExactMatches(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> out_dedupe_staging_link_id, 
		in_description				=> 'Ref rule set',
		in_rule_ids					=> v_rule_ids,
		in_rule_set_position		=> 1,
		in_mapping_ids				=> v_mapping_ids,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);
END;

PROCEDURE SetupCompanyRefs2
AS
	v_company_types		chain.helper_pkg.T_NUMBER_ARRAY;
BEGIN
	--set up references
	helper_pkg.SaveReferenceLabel(
		in_reference_id	=> NULL,
		in_lookup_key => 'COMPANY_ID_REF',
		in_label => 'Company import id',
		in_mandatory => 0,
		in_reference_uniqueness_id => 2, /* Global */
		in_reference_location_id => 0, /* Show on the company details card */
		in_company_type_ids	=> v_company_types,
		out_reference_id => v_reference_company_id
	);
	 
	helper_pkg.SaveReferenceLabel(
		in_reference_id	=> NULL,
		in_lookup_key => 'COMPANY_REF_1',
		in_label => 'Company ref 1',
		in_mandatory => 0,
		in_reference_uniqueness_id => 2, /* Global */
		in_reference_location_id => 0, /* Show on the company details card */
		in_company_type_ids	=> v_company_types,
		out_reference_id => v_reference_id_1
	);

	 helper_pkg.SaveReferenceLabel(
		in_reference_id	=> NULL,
		in_lookup_key => 'COMPANY_REF_2',
		in_label => 'Company import id',
		in_mandatory => 0,
		in_reference_uniqueness_id => 2, /* Global */
		in_reference_location_id => 0, /* Show on the company details card */
		in_company_type_ids	=> v_company_types,
		out_reference_id => v_reference_id_2
	);
	 
	 helper_pkg.SaveReferenceLabel(
		in_reference_id	=> NULL,
		in_lookup_key => 'COMPANY_REF_3',
		in_label => 'Company import id',
		in_mandatory => 0,
		in_reference_uniqueness_id => 2, /* Global */
		in_reference_location_id => 0, /* Show on the company details card */
		in_company_type_ids	=> v_company_types,
		out_reference_id => v_reference_id_3
	);
END;

PROCEDURE SetupCompanyRefs3
AS
	v_company_types		chain.helper_pkg.T_NUMBER_ARRAY;
BEGIN
	--set up references
	helper_pkg.SaveReferenceLabel(
		in_reference_id	=> NULL,
		in_lookup_key => 'COMPANY_ID_REF',
		in_label => 'Company import id',
		in_mandatory => 0,
		in_reference_uniqueness_id => 2, /* Global */
		in_reference_location_id => 0, /* Show on the company details card */
		in_company_type_ids	=> v_company_types,
		out_reference_id => v_reference_company_id
	);
END;

PROCEDURE SetupSources3
AS
	v_mapping_id			NUMBER;
	v_mapping_ids			security.security_pkg.T_SID_IDS;
	v_rule_ids				security.security_pkg.T_SID_IDS;
	v_dedupe_rule_set_id	NUMBER;
BEGIN
	v_staging_tab_sid_3_1 := cms.tab_pkg.GetTableSid('RAG', 'CMS_COMPANY_STAGING_3');
	v_staging_tab_sid_3_2 := cms.tab_pkg.GetTableSid('RAG', 'CHILD_CMS_COMPANY_STAGING');
	v_destination_tab_sid_3 := cms.tab_pkg.GetTableSid('RAG', 'COMPANY_SALES_ORG');

	dedupe_admin_pkg.SaveImportSource(
		in_import_source_id => -1, 
		in_name => 'Update company child cms data integration', 
		in_position => 1, 
		in_no_match_action_id => chain_pkg.AUTO_CREATE, 
		in_lookup_key => 'UPDATE_CHILD_CMS_DATA',
		out_import_source_id => v_source_id_for_child
	);
	
	--set up staging links
	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id_for_child,
		in_description 					=> 'Staging that holds cms update data',
		in_staging_tab_sid 				=> v_staging_tab_sid_3_1,
		in_position 					=> 1,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_staging_tab_sid_3_1, 'COMPANY_ID'),
		in_parent_staging_link_id 		=> NULL,
		in_destination_tab_sid 			=> NULL,
		in_staging_batch_num_col_sid	=> NULL,
		out_dedupe_staging_link_id 		=> v_staging_link_id_3_1
	);

	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id_for_child,
		in_description 					=> 'Staging that holds cms update child data',
		in_staging_tab_sid 				=> v_staging_tab_sid_3_2,
		in_position 					=> 2,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_staging_tab_sid_3_2, 'COMPANY_ID'),
		in_staging_batch_num_col_sid	=> NULL,
		in_parent_staging_link_id 		=> v_staging_link_id_3_1,
		in_destination_tab_sid 			=> v_destination_tab_sid_3,
		out_dedupe_staging_link_id 		=> v_staging_link_id_3_2
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_3_1, 
		in_tab_sid => v_staging_tab_sid_3_1,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_3_1, 'NAME'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_3_1, 
		in_tab_sid => v_staging_tab_sid_3_1,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_3_1, 'COUNTRY'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_3_1, 
		in_tab_sid => v_staging_tab_sid_3_1,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_3_1, 'COMPANY_ID'),
		in_reference_id => v_reference_company_id,
		out_dedupe_mapping_id => v_mapping_ref_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_3_2, 
		in_tab_sid => v_staging_tab_sid_3_2,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_3_2, 'SALES_ORG'),
		in_destination_tab_sid => v_destination_tab_sid_3,
		in_destination_col_sid => cms.tab_pkg.GetColumnSid(v_destination_tab_sid_3, 'SALES_ORG_ID'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_3_2, 
		in_tab_sid => v_staging_tab_sid_3_2,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_3_2, 'MERCH_CAT'),
		in_destination_tab_sid => v_destination_tab_sid_3,
		in_destination_col_sid => cms.tab_pkg.GetColumnSid(v_destination_tab_sid_3, 'MERCH_CAT_ID'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_3_2, 
		in_tab_sid => v_staging_tab_sid_3_2,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_3_2, 'STARTED_BY'),
		in_destination_tab_sid => v_destination_tab_sid_3,
		in_destination_col_sid => cms.tab_pkg.GetColumnSid(v_destination_tab_sid_3, 'STARTED_BY_SID'),
		out_dedupe_mapping_id => v_mapping_id
	);
			
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_3_2, 
		in_tab_sid => v_staging_tab_sid_3_2,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_3_2, 'REVENUE'),
		in_destination_tab_sid => v_destination_tab_sid_3,
		in_destination_col_sid => cms.tab_pkg.GetColumnSid(v_destination_tab_sid_3, 'REVENUE'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_3_2, 
		in_tab_sid => v_staging_tab_sid_3_2,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_3_2, 'START_DATE'),
		in_destination_tab_sid => v_destination_tab_sid_3,
		in_destination_col_sid => cms.tab_pkg.GetColumnSid(v_destination_tab_sid_3, 'START_DATE'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_3_2, 
		in_tab_sid => v_staging_tab_sid_3_2,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_3_2, 'COMMENTS'),
		in_destination_tab_sid => v_destination_tab_sid_3,
		in_destination_col_sid => cms.tab_pkg.GetColumnSid(v_destination_tab_sid_3, 'COMMENTS'),
		out_dedupe_mapping_id => v_mapping_id
	);

	--Set rules
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_ref_id));
	  
	dedupe_admin_pkg.TestSaveRuleSetForExactMatches(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id_3_1, 
		in_rule_set_position		=> 1,
		in_description				=> 'Ref rule set',
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);
END;

PROCEDURE SetupSources2(
	in_use_batch_num_col	IN BOOLEAN DEFAULT FALSE
)
AS
	v_mapping_id			NUMBER;
	v_mapping_ids			security.security_pkg.T_SID_IDS;
	v_rule_ids				security.security_pkg.T_SID_IDS;
	v_dedupe_rule_set_id	NUMBER;
BEGIN 
	v_staging_tab_sid_2_1 := cms.tab_pkg.GetTableSid('RAG', 'CMS_COMPANY_STAGING_3');
	v_staging_tab_sid_2_2 := cms.tab_pkg.GetTableSid('RAG', 'CHILD_CMS_COMPANY_STAGING');
	v_destination_tab_sid_2 := cms.tab_pkg.GetTableSid('RAG', 'COMPANY_SALES_ORG');
	
	dedupe_admin_pkg.SaveImportSource(
		in_import_source_id => -1, 
		in_name => 'Company child cms data integration', 
		in_position => 1, 
		in_no_match_action_id => chain_pkg.AUTO_CREATE,  
		in_lookup_key => 'CHILD_CMS_DATA',
		out_import_source_id => v_source_id_for_child
	);
	
	--set up staging links
	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id_for_child,
		in_description 					=> 'Staging that holds 1-1 data',
		in_staging_tab_sid 				=> v_staging_tab_sid_2_1,
		in_position 					=> 1,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_staging_tab_sid_2_1, 'COMPANY_ID'),
		in_parent_staging_link_id 		=> NULL,
		in_destination_tab_sid 			=> NULL,
		in_staging_batch_num_col_sid	=> CASE WHEN in_use_batch_num_col THEN cms.tab_pkg.GetColumnSid(v_staging_tab_sid_2_1, 'BATCH_NUM') ELSE NULL END,
		out_dedupe_staging_link_id 		=> v_staging_link_id_2_1
	);
	
	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id_for_child,
		in_description 					=> 'Staging that holds 1-1 data',
		in_staging_tab_sid 				=> v_staging_tab_sid_2_2,
		in_position 					=> 2,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_staging_tab_sid_2_2, 'COMPANY_ID'),
		in_staging_batch_num_col_sid	=> CASE WHEN in_use_batch_num_col THEN cms.tab_pkg.GetColumnSid(v_staging_tab_sid_2_2, 'BATCH_NUM') ELSE NULL END,
		in_parent_staging_link_id 		=> v_staging_link_id_2_1,
		in_destination_tab_sid 			=> v_destination_tab_sid_2,
		out_dedupe_staging_link_id 		=> v_staging_link_id_2_2
	);
	
	--mappings
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_2_1, 
		in_tab_sid => v_staging_tab_sid_2_1,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_2_1, 'NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_2_1, 
		in_tab_sid => v_staging_tab_sid_2_1,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_2_1, 'COUNTRY'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_2_1, 
		in_tab_sid => v_staging_tab_sid_2_1,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_2_1, 'COMPANY_ID'),
		in_reference_id => v_reference_company_id,
		out_dedupe_mapping_id => v_mapping_ref_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_2_1, 
		in_tab_sid => v_staging_tab_sid_2_1,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_2_1, 'REF_1'),
		in_reference_id => v_reference_id_1,
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_2_1, 
		in_tab_sid => v_staging_tab_sid_2_1,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_2_1, 'REF_2'),
		in_reference_id => v_reference_id_2,
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_2_1, 
		in_tab_sid => v_staging_tab_sid_2_1,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_2_1, 'REF_3'),
		in_reference_id => v_reference_id_3,
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_2_2, 
		in_tab_sid => v_staging_tab_sid_2_2,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_2_2, 'SALES_ORG'),
		in_destination_tab_sid	=> 	v_destination_tab_sid_2,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'SALES_ORG_ID'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_2_2, 
		in_tab_sid => v_staging_tab_sid_2_2,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_2_2, 'MERCH_CAT'),
		in_destination_tab_sid	=> 	v_destination_tab_sid_2,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'MERCH_CAT_ID'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_2_2, 
		in_tab_sid => v_staging_tab_sid_2_2,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_2_2, 'STARTED_BY'),
		in_destination_tab_sid	=> 	v_destination_tab_sid_2,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'STARTED_BY_SID'),
		out_dedupe_mapping_id => v_mapping_id
	);
			
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_2_2, 
		in_tab_sid => v_staging_tab_sid_2_2,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_2_2, 'REVENUE'),
		in_destination_tab_sid	=> 	v_destination_tab_sid_2,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'REVENUE'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_2_2, 
		in_tab_sid => v_staging_tab_sid_2_2,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_2_2, 'START_DATE'),
		in_destination_tab_sid	=> 	v_destination_tab_sid_2,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'START_DATE'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_2_2, 
		in_tab_sid => v_staging_tab_sid_2_2,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_2_2, 'COMMENTS'),
		in_destination_tab_sid	=> 	v_destination_tab_sid_2,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'COMMENTS'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_2_2, 
		in_tab_sid => v_staging_tab_sid_2_2,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_2_2, 'DELETED'),
		in_destination_tab_sid	=> 	v_destination_tab_sid_2,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'DELETED'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_2_2, 
		in_tab_sid => v_staging_tab_sid_2_2,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_2_2, 'BAND_LABEL'),
		in_destination_tab_sid	=> 	v_destination_tab_sid_2,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'SCORE_BAND_ID'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	--Set rules
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_ref_id));
	  
	dedupe_admin_pkg.TestSaveRuleSetForExactMatches(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id_2_1, 
		in_rule_ids					=> v_rule_ids,
		in_description				=> 'Ref rule set',
		in_rule_set_position		=> 1,
		in_mapping_ids				=> v_mapping_ids,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);
END;

PROCEDURE SetupSources4
AS
	v_mapping_id			NUMBER;
	v_mapping_ids			security.security_pkg.T_SID_IDS;
	v_rule_ids				security.security_pkg.T_SID_IDS;
	v_dedupe_rule_set_id	NUMBER;
BEGIN
	v_staging_tab_sid_4_1 := cms.tab_pkg.GetTableSid('RAG', 'CMS_COMPANY_STAGING_4');
	v_staging_tab_sid_4_2 := cms.tab_pkg.GetTableSid('RAG', 'CHILD_CMS_COMPANY_STAGING_4');
	v_destination_tab_sid_4 := cms.tab_pkg.GetTableSid('RAG', 'COMPANY_DATA_4');

	dedupe_admin_pkg.SaveImportSource(
		in_import_source_id => -1, 
		in_name => 'Update company child cms data with company type column', 
		in_position => 1, 
		in_no_match_action_id => chain_pkg.AUTO_CREATE, 
		in_lookup_key => 'UPDATE_CHILD_CMS_DATA',
		out_import_source_id => v_source_id_for_child
	);
	
	--set up staging links
	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id_for_child,
		in_description 					=> 'Staging that holds cms update data',
		in_staging_tab_sid 				=> v_staging_tab_sid_4_1,
		in_position 					=> 1,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_staging_tab_sid_4_1, 'COMPANY_ID'),
		in_parent_staging_link_id 		=> NULL,
		in_destination_tab_sid 			=> NULL,
		in_staging_batch_num_col_sid	=> NULL,
		out_dedupe_staging_link_id 		=> v_staging_link_id_4_1
	);

	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id_for_child,
		in_description 					=> 'Staging that holds cms update child data',
		in_staging_tab_sid 				=> v_staging_tab_sid_4_2,
		in_position 					=> 2,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_staging_tab_sid_4_2, 'COMPANY_ID'),
		in_staging_batch_num_col_sid	=> NULL,
		in_parent_staging_link_id 		=> v_staging_link_id_4_1,
		in_destination_tab_sid 			=> v_destination_tab_sid_4,
		out_dedupe_staging_link_id 		=> v_staging_link_id_4_2
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_4_1, 
		in_tab_sid => v_staging_tab_sid_4_1,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_4_1, 'NAME'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_NAME,
		out_dedupe_mapping_id => v_mapping_name_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_4_1, 
		in_tab_sid => v_staging_tab_sid_4_1,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_4_1, 'COUNTRY'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_4_2, 
		in_tab_sid => v_staging_tab_sid_4_2,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_4_2, 'REPORTING_YEAR'),
		in_destination_tab_sid => v_destination_tab_sid_4,
		in_destination_col_sid => cms.tab_pkg.GetColumnSid(v_destination_tab_sid_4, 'REPORTING_YEAR'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_4_2, 
		in_tab_sid => v_staging_tab_sid_4_2,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_4_2, 'REVENUE'),
		in_destination_tab_sid => v_destination_tab_sid_4,
		in_destination_col_sid => cms.tab_pkg.GetColumnSid(v_destination_tab_sid_4, 'REVENUE'),
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_4_2, 
		in_tab_sid => v_staging_tab_sid_4_2,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_4_2, 'ANOTHER_COMPANY_SID'),
		in_destination_tab_sid => v_destination_tab_sid_4,
		in_destination_col_sid => cms.tab_pkg.GetColumnSid(v_destination_tab_sid_4, 'ANOTHER_COMPANY_SID'),
		out_dedupe_mapping_id => v_mapping_id
	);	
	
	--Set rules
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_name_id));
	  
	dedupe_admin_pkg.TestSaveRuleSetForExactMatches(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id_4_1, 
		in_rule_set_position		=> 1,
		in_description				=> 'Name rule set',
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);
END;

PROCEDURE SetupSources5
AS
	v_mapping_id			NUMBER;
	v_mapping_ids			security.security_pkg.T_SID_IDS;
	v_rule_ids				security.security_pkg.T_SID_IDS;
	v_dedupe_rule_set_id	NUMBER;
BEGIN
	v_staging_tab_sid_4_1 := cms.tab_pkg.GetTableSid('RAG', 'CMS_COMPANY_STAGING_4');
	v_staging_tab_sid_4_2 := cms.tab_pkg.GetTableSid('RAG', 'CHILD_CMS_COMPANY_STAGING_4');
	v_destination_tab_sid_4 := cms.tab_pkg.GetTableSid('RAG', 'COMPANY_DATA_4');

	dedupe_admin_pkg.SaveImportSource(
		in_import_source_id => -1, 
		in_name => 'Update company child cms data with company type column', 
		in_position => 1, 
		in_no_match_action_id => chain_pkg.AUTO_CREATE, 
		in_lookup_key => 'UPDATE_CHILD_CMS_DATA',
		out_import_source_id => v_source_id_for_child
	);
	
	--set up staging links
	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id_for_child,
		in_description 					=> 'Staging that holds cms update data',
		in_staging_tab_sid 				=> v_staging_tab_sid_4_1,
		in_position 					=> 1,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_staging_tab_sid_4_1, 'COMPANY_ID'),
		in_parent_staging_link_id 		=> NULL,
		in_destination_tab_sid 			=> NULL,
		in_staging_batch_num_col_sid	=> NULL,
		out_dedupe_staging_link_id 		=> v_staging_link_id_4_1
	);

	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id_for_child,
		in_description 					=> 'Staging that holds cms update child data',
		in_staging_tab_sid 				=> v_staging_tab_sid_4_2,
		in_position 					=> 2,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_staging_tab_sid_4_2, 'COMPANY_ID'),
		in_staging_batch_num_col_sid	=> NULL,
		in_parent_staging_link_id 		=> v_staging_link_id_4_1,
		in_destination_tab_sid 			=> v_destination_tab_sid_4,
		out_dedupe_staging_link_id 		=> v_staging_link_id_4_2
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_4_1, 
		in_tab_sid => v_staging_tab_sid_4_1,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_4_1, 'NAME'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_NAME,
		out_dedupe_mapping_id => v_mapping_name_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_4_1, 
		in_tab_sid => v_staging_tab_sid_4_1,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_4_1, 'COUNTRY'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_4_2, 
		in_tab_sid => v_staging_tab_sid_4_2,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_4_2, 'REPORTING_YEAR'),
		in_destination_tab_sid => v_destination_tab_sid_4,
		in_destination_col_sid => cms.tab_pkg.GetColumnSid(v_destination_tab_sid_4, 'REPORTING_YEAR'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_4_2, 
		in_tab_sid => v_staging_tab_sid_4_2,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_4_2, 'REVENUE'),
		in_destination_tab_sid => v_destination_tab_sid_4,
		in_destination_col_sid => cms.tab_pkg.GetColumnSid(v_destination_tab_sid_4, 'REVENUE'),
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_4_2, 
		in_tab_sid => v_staging_tab_sid_4_2,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_4_2, 'ANOTHER_COMPANY_SID'),
		in_destination_tab_sid => v_destination_tab_sid_4,
		in_destination_col_sid => cms.tab_pkg.GetColumnSid(v_destination_tab_sid_4, 'ANOTHER_COMPANY_SID'),
		out_dedupe_mapping_id => v_mapping_id
	);	
	
	--Set rules
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_name_id));
	  
	dedupe_admin_pkg.TestSaveRuleSetForExactMatches(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id_4_1, 
		in_rule_set_position		=> 1,
		in_description				=> 'Name rule set',
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);
	
	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;
END;

PROCEDURE SetupSources6
AS
	v_mapping_id			NUMBER;
BEGIN
	SetupSources5; -- reusing
	
	-- just to get the test variable naming consistent as I think it's a bit borked in test 5
	v_staging_tab_sid_6_1 := v_staging_tab_sid_4_1;
	v_staging_tab_sid_6_2 := v_staging_tab_sid_4_2;
	v_destination_tab_sid_6_1 := v_destination_tab_sid_4;
	v_staging_link_id_6_1 := v_staging_link_id_4_1;
	v_staging_link_id_6_2 := v_staging_link_id_4_2;
	
	-- 2nd CMS child table
	v_staging_tab_sid_6_3 := cms.tab_pkg.GetTableSid('RAG', 'CHILD_CMS_COMPANY_STAGING');
	v_destination_tab_sid_6_2 := cms.tab_pkg.GetTableSid('RAG', 'COMPANY_SALES_ORG');

	-- add 2nd CMS table link to import source
	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id_for_child,
		in_description 					=> 'Staging that holds cms update child data - table 2',
		in_staging_tab_sid 				=> v_staging_tab_sid_6_3,
		in_position 					=> 3,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_staging_tab_sid_6_3, 'COMPANY_ID'),
		in_staging_batch_num_col_sid	=> NULL,
		in_parent_staging_link_id 		=> v_staging_link_id_6_1,
		in_destination_tab_sid 			=> v_destination_tab_sid_6_2,
		out_dedupe_staging_link_id 		=> v_staging_link_id_6_3
	);
	
	-- 5 mappings for second CMS table
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_6_3, 
		in_tab_sid => v_staging_tab_sid_6_3,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_6_3, 'SALES_ORG'),
		in_destination_tab_sid	=> 	v_destination_tab_sid_6_2,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid_6_2, 'SALES_ORG_ID'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_6_3, 
		in_tab_sid => v_staging_tab_sid_6_3,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_6_3, 'MERCH_CAT'),
		in_destination_tab_sid	=> 	v_destination_tab_sid_6_2,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid_6_2, 'MERCH_CAT_ID'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_6_3, 
		in_tab_sid => v_staging_tab_sid_6_3,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_6_3, 'REVENUE'),
		in_destination_tab_sid	=> 	v_destination_tab_sid_6_2,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid_6_2, 'REVENUE'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_6_3, 
		in_tab_sid => v_staging_tab_sid_6_3,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_6_3, 'START_DATE'),
		in_destination_tab_sid	=> 	v_destination_tab_sid_6_2,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid_6_2, 'START_DATE'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_6_3, 
		in_tab_sid => v_staging_tab_sid_6_3,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_tab_sid_6_3, 'COMMENTS'),
		in_destination_tab_sid	=> 	v_destination_tab_sid_6_2,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid_6_2, 'COMMENTS'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
END;

PROCEDURE SetupSources
AS
	v_company_types		chain.helper_pkg.T_NUMBER_ARRAY;
BEGIN 
	--set up references
	helper_pkg.SaveReferenceLabel(
		in_reference_id		=> NULL,
		in_lookup_key => 'CMS_COMPANY_REFERENCE',
		in_label => 'Company reference',
		in_mandatory => 0,
		in_reference_uniqueness_id => 2, /* Global */
		in_reference_location_id => 0, /* Show on the company details card */
		in_company_type_ids		=> v_company_types,
		out_reference_id => v_reference_id
	);

	SetupSource('CMS_COMPANY_STAGING','COMPANY_DATA', 'CMS_1_1', 1, v_source_id_1_1, v_staging_link_id_1_1);
	SetupSource('CMS_COMPANY_STAGING_2','COMPANY_DATA_2', 'CMS_2_2', 2, v_source_id_2_2, v_staging_link_id_2_2);
	SetupSource('CMS_COMPANY_STAGING_2','COMPANY_DATA', 'CMS_2_1', 3, v_source_id_2_1, v_staging_link_id_2_1);
	
	--decrease system import source priority to allow merging
	UPDATE import_source
	   SET position = 4
	 WHERE app_sid = security_pkg.getapp
	   AND is_owned_by_system = 1;
END;

PROCEDURE SetupCmsBasedata
AS
BEGIN
	EXECUTE IMMEDIATE 'INSERT INTO rag.SCORE_BAND (SCORE_BAND_ID, LABEL) VALUES (1, ''Green'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.SCORE_BAND (SCORE_BAND_ID, LABEL) VALUES (2, ''Amber'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.SCORE_BAND (SCORE_BAND_ID, LABEL) VALUES (3, ''Red'')';
END;

PROCEDURE SetupCmsBasedata2
AS
BEGIN
	EXECUTE IMMEDIATE 'INSERT INTO rag.SALES_ORG (SALES_ORG_ID, LABEL) VALUES (1, ''Netto SE'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.SALES_ORG (SALES_ORG_ID, LABEL) VALUES (2, :1)' USING 'f'||unistr('\00F8')||'tex food';
	EXECUTE IMMEDIATE 'INSERT INTO rag.SALES_ORG (SALES_ORG_ID, LABEL) VALUES (3, ''Salling'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.SALES_ORG (SALES_ORG_ID, LABEL) VALUES (4, ''Starbucks'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.SALES_ORG (SALES_ORG_ID, LABEL) VALUES (5, ''E-Commerce'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.SALES_ORG (SALES_ORG_ID, LABEL) VALUES (6, :1)' USING 'Carl''s Jr.';
	
	EXECUTE IMMEDIATE 'INSERT INTO rag.MERCH_CAT (MERCH_CAT_ID, LABEL) VALUES (1, ''R5726 (S) LADIES COATS'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.MERCH_CAT (MERCH_CAT_ID, LABEL) VALUES (2, ''R5687 (S) MENS KNITTING'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.MERCH_CAT (MERCH_CAT_ID, LABEL) VALUES (3, ''R5663 (S) PERFUMES'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.MERCH_CAT (MERCH_CAT_ID, LABEL) VALUES (4, ''R5707 (S) YOUNG SHOP MEN TOPS'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.MERCH_CAT (MERCH_CAT_ID, LABEL) VALUES (5, ''R5440 APPLES/PEARS'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.MERCH_CAT (MERCH_CAT_ID, LABEL) VALUES (6, ''R5104 BED'||chr(38)||' MATTRESSES'')';
	
	EXECUTE IMMEDIATE 'INSERT INTO rag.SCORE_BAND (SCORE_BAND_ID, LABEL) VALUES (1, ''Green'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.SCORE_BAND (SCORE_BAND_ID, LABEL) VALUES (2, ''Amber'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.SCORE_BAND (SCORE_BAND_ID, LABEL) VALUES (3, ''Red'')';
END;

PROCEDURE SetupCmsBasedata3
AS
BEGIN
	EXECUTE IMMEDIATE 'INSERT INTO rag.SALES_ORG (SALES_ORG_ID, LABEL) VALUES (1, ''Netto SE'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.SALES_ORG (SALES_ORG_ID, LABEL) VALUES (2, :1)' USING 'f'||unistr('\00F8')||'tex food';
	EXECUTE IMMEDIATE 'INSERT INTO rag.SALES_ORG (SALES_ORG_ID, LABEL) VALUES (3, ''Salling'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.SALES_ORG (SALES_ORG_ID, LABEL) VALUES (4, ''Starbucks'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.SALES_ORG (SALES_ORG_ID, LABEL) VALUES (5, ''E-Commerce'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.SALES_ORG (SALES_ORG_ID, LABEL) VALUES (6, :1)' USING 'Carl''s Jr.';
	
	EXECUTE IMMEDIATE 'INSERT INTO rag.MERCH_CAT (MERCH_CAT_ID, LABEL) VALUES (1, ''R5726 (S) LADIES COATS'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.MERCH_CAT (MERCH_CAT_ID, LABEL) VALUES (2, ''R5687 (S) MENS KNITTING'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.MERCH_CAT (MERCH_CAT_ID, LABEL) VALUES (3, ''R5663 (S) PERFUMES'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.MERCH_CAT (MERCH_CAT_ID, LABEL) VALUES (4, ''R5707 (S) YOUNG SHOP MEN TOPS'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.MERCH_CAT (MERCH_CAT_ID, LABEL) VALUES (5, ''R5440 APPLES/PEARS'')';
	EXECUTE IMMEDIATE 'INSERT INTO rag.MERCH_CAT (MERCH_CAT_ID, LABEL) VALUES (6, ''R5104 BED'||chr(38)||' MATTRESSES'')';


	--EXECUTE IMMEDIATE 'INSERT INTO rag.COMPANY_SALES_ORG (COMPANY_SALES_ORG_ID, COMPANY_SID, SALES_ORG_ID, MERCH_CAT_ID,
	--					REVENUE, STARTED_BY_SID, START_DATE, COMMENTS) VALUES (1, '||v_company_sid||', 1, 1, 50, '||v_expected_user_sid_1||', '||SYSDATE||', "Test thing 1")';
	--EXECUTE IMMEDIATE 'INSERT INTO rag.COMPANY_SALES_ORG (COMPANY_SALES_ORG_ID, COMPANY_SID, SALES_ORG_ID, MERCH_CAT_ID,
	--													  REVENUE, STARTED_BY_SID, START_DATE, COMMENTS) VALUES ()';
	--EXECUTE IMMEDIATE 'INSERT INTO rag.COMPANY_SALES_ORG (COMPANY_SALES_ORG_ID, COMPANY_SID, SALES_ORG_ID, MERCH_CAT_ID,
	--													  REVENUE, STARTED_BY_SID, START_DATE, COMMENTS) VALUES ()';
	--EXECUTE IMMEDIATE 'INSERT INTO rag.COMPANY_SALES_ORG (COMPANY_SALES_ORG_ID, COMPANY_SID, SALES_ORG_ID, MERCH_CAT_ID,
	--													  REVENUE, STARTED_BY_SID, START_DATE, COMMENTS) VALUES ()';
END;

PROCEDURE SetupCmsBasedata6
AS
BEGIN
	-- reusing
	SetupCmsBasedata2;
END;

PROCEDURE SetupTestdata
AS
BEGIN
	v_expected_user_sid_1 := csr.unit_test_pkg.GetOrCreateUser('Kate Rye');
	v_expected_user_sid_2 := csr.unit_test_pkg.GetOrCreateUser('Random Pearson');
	v_expected_user_sid_3 := csr.unit_test_pkg.GetOrCreateUser('Antoine Winterbottom');
END;

PROCEDURE SetupTestdata2
AS
BEGIN
	v_expected_user_sid_1 := csr.unit_test_pkg.GetOrCreateUser('Kate Rye');
	v_expected_user_sid_2 := csr.unit_test_pkg.GetOrCreateUser('Random Pearson');
END;

PROCEDURE SetupTestdata3
AS
BEGIN
	v_expected_user_sid_1 := csr.unit_test_pkg.GetOrCreateUser('Kate Rye');
END;

PROCEDURE SetUp
AS
BEGIN
	--do noth
	NULL;
END;

PROCEDURE SetUpConfig1
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	SetupSources;
	PopulateStagingCompanies;
	SetupTestdata;
	SetupCmsBasedata;
END;

PROCEDURE SetUpConfig2(
	in_use_batch_num_col	IN BOOLEAN DEFAULT FALSE
)
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	SetupCompanyRefs2;
	SetupSources2(in_use_batch_num_col);
	PopulateStagingCompanies2;
	SetupTestdata2;
	SetupCmsBasedata2;
END;

PROCEDURE SetUpConfig3
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	SetupCompanyRefs3;
	SetupSources3;
	PopulateStagingCompanies3;
	SetupTestdata3;
	SetupCmsBasedata3;
END;

PROCEDURE SetUpConfig4
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	SetupSources4;
	PopulateStagingCompanies4;
END;

PROCEDURE SetUpConfig5
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	SetupSources5;
	PopulateStagingCompanies5;
END;

PROCEDURE SetUpConfig6
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	SetupSources6;
	SetupCmsBasedata6;
	PopulateStagingCompanies6;
END;

-- Tears down all configs
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
	
	security.securableobject_pkg.DeleteSO(security_pkg.getact, v_expected_user_sid_1); 
	security.securableobject_pkg.DeleteSO(security_pkg.getact, v_expected_user_sid_2); 
	security.securableobject_pkg.DeleteSO(security_pkg.getact, v_expected_user_sid_3); 
	
	test_chain_utils_pkg.DeleteFullyCompaniesOfType('SUPPLIER'); 
	
	DELETE FROM reference_company_type
	 WHERE reference_id IN ( 
		SELECT reference_id
		  FROM reference
		 WHERE lookup_key IN ('CMS_COMPANY_REFERENCE', 'COMPANY_ID_REF', 'COMPANY_REF_1', 'COMPANY_REF_2', 'COMPANY_REF_3')
	 );
	 
	DELETE FROM reference
	 WHERE lookup_key IN ('CMS_COMPANY_REFERENCE', 'COMPANY_ID_REF', 'COMPANY_REF_1', 'COMPANY_REF_2', 'COMPANY_REF_3');
	
	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.cms_company_staging';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.cms_company_staging_2';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.cms_company_staging_3';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.cms_company_staging_4';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.child_cms_company_staging';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.child_cms_company_staging_4';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.COMPANY_DATA';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.COMPANY_DATA_2';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.COMPANY_DATA_4';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.COMPANY_SALES_ORG';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.SCORE_BAND_MAP';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.SCORE_BAND';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.SALES_ORG';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.MERCH_CAT';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;
	
	DELETE FROM tt_dedupe_cms_data;
END;

PROCEDURE Test_ParseEnumData
AS
	v_destination_tab_sid	NUMBER;
	v_enum_val_id			NUMBER;
	v_raw_val				VARCHAR2(4000);
	v_translated_val		VARCHAR2(4000);
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	SetUpConfig1;
	
	v_destination_tab_sid	:= cms.tab_pkg.GetTableSid('RAG', 'COMPANY_DATA');
	
	IF NOT company_dedupe_pkg.TryParseEnumVal(
		in_dedupe_staging_link_id	=> v_staging_link_id_1_1,
		in_staging_tab_schema		=> 'RAG',
		in_staging_tab_name			=> 'CMS_COMPANY_STAGING',
		in_staging_id_col_name		=> 'COMPANY_REFERENCE',
		in_reference				=> '12345',
		in_mapped_column			=> 'SCORE_BAND',
		in_destination_col_sid		=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'SCORE_BAND_ID'),
		out_enum_value_id			=> v_enum_val_id,
		out_staging_val				=> v_raw_val,
		out_translated_val			=> v_translated_val
	)		
	THEN
		csr.unit_test_pkg.TestFail('Error parsing the enum value');
	END IF;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_enum_val_id, 'Returned value for the enum is not the expected one');
	
	EXECUTE IMMEDIATE ('
		UPDATE rag.cms_company_staging
		   SET score_band= ''verde''
		 WHERE company_reference = ''12345''');
	
	--let it fail...
	v_enum_val_id := NULL;
	v_raw_val := NULL;
	IF company_dedupe_pkg.TryParseEnumVal(
		in_dedupe_staging_link_id	=> v_staging_link_id_1_1,
		in_staging_tab_schema		=> 'RAG',
		in_staging_tab_name			=> 'CMS_COMPANY_STAGING',
		in_staging_id_col_name		=> 'COMPANY_REFERENCE',
		in_reference				=> '12345',
		in_mapped_column			=> 'SCORE_BAND',
		in_destination_col_sid		=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'SCORE_BAND_ID'),
		out_enum_value_id			=> v_enum_val_id,
		out_staging_val				=> v_raw_val,
		out_translated_val			=> v_translated_val
	)
	THEN
		csr.unit_test_pkg.TestFail('Parsing was expected to fail');
	END IF;
	
	--now it should get the val from the translation table
	EXECUTE IMMEDIATE ('INSERT INTO RAG.SCORE_BAND_MAP (SCORE_BAND_MAP_ID, SCORE_BAND_ID, ORIGINAL_TEXT) VALUES (10001, 1, ''VErdE'')');
	
	v_enum_val_id := NULL;
	v_raw_val := NULL;
	IF NOT company_dedupe_pkg.TryParseEnumVal(
		in_dedupe_staging_link_id	=> v_staging_link_id_1_1,
		in_staging_tab_schema		=> 'RAG',
		in_staging_tab_name			=> 'CMS_COMPANY_STAGING',
		in_staging_id_col_name		=> 'COMPANY_REFERENCE',
		in_reference				=> '12345',
		in_mapped_column			=> 'SCORE_BAND',
		in_destination_col_sid		=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'SCORE_BAND_ID'),
		out_enum_value_id			=> v_enum_val_id,
		out_staging_val				=> v_raw_val,
		out_translated_val			=> v_translated_val
	)
	THEN
		csr.unit_test_pkg.TestFail('Error parsing the enum value');
	END IF;

	csr.unit_test_pkg.AssertAreEqual(1, v_enum_val_id, 'Returned value for the enum is not the expected one');
END;

PROCEDURE Test_ParseCmsData
AS
	v_user_sid		NUMBER;
	v_val			VARCHAR2(4000);
	v_raw_val		VARCHAR2(4000);
	v_date_val		DATE;
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	SetUpConfig1;
	
	--test user parsing
	IF NOT company_dedupe_pkg.TryParseUserSid(
		in_dedupe_staging_link_id	=> v_staging_link_id_1_1,
		in_staging_tab_schema		=> 'RAG',
		in_staging_tab_name			=> 'CMS_COMPANY_STAGING',
		in_staging_id_col_name		=> 'COMPANY_REFERENCE',
		in_reference				=> '12345',
		in_mapped_column			=> 'ASSESSED_BY',
		out_user_sid				=> v_user_sid,
		out_raw_val					=> v_raw_val
	)
	THEN
		csr.unit_test_pkg.TestFail('Error matching a csr user with the staging value');
	END IF;
	
	csr.unit_test_pkg.AssertAreEqual(v_expected_user_sid_1, v_user_sid, 'Returned user sid is not the expected one');
	
	IF NOT company_dedupe_pkg.TryParseVal(
		in_dedupe_staging_link_id	=> v_staging_link_id_1_1,
		in_staging_tab_schema		=> 'RAG',
		in_staging_tab_name			=> 'CMS_COMPANY_STAGING',
		in_staging_id_col_name		=> 'COMPANY_REFERENCE',
		in_reference				=> '12345',
		in_mapped_column			=> 'REVENUE',
		in_data_type				=> 'NUMBER',
		out_str_val					=> v_val,
		out_date_val				=> v_date_val
	)
	THEN
		csr.unit_test_pkg.TestFail('Error parsing to a numeric value');
	END IF;
	
	csr.unit_test_pkg.AssertAreEqual(500000.25, TO_NUMBER(v_val), 'Returned parsed value is not the expected one');
	
	-- Test string value
	IF NOT company_dedupe_pkg.TryParseVal(
		in_dedupe_staging_link_id	=> v_staging_link_id_1_1,
		in_staging_tab_schema		=> 'RAG',
		in_staging_tab_name			=> 'CMS_COMPANY_STAGING',
		in_staging_id_col_name		=> 'COMPANY_REFERENCE',
		in_reference				=> '12345',
		in_mapped_column			=> 'NAME',
		in_data_type				=> 'VARCHAR2',
		out_str_val					=> v_val,
		out_date_val				=> v_date_val
	)
	THEN
		csr.unit_test_pkg.TestFail('Error parsing to a string value');
	END IF;
	
	csr.unit_test_pkg.AssertAreEqual('Random inc', v_val, 'Returned parsed value is not the expected one');
	
	-- Test date value
	IF NOT company_dedupe_pkg.TryParseVal(
		in_dedupe_staging_link_id	=> v_staging_link_id_1_1,
		in_staging_tab_schema		=> 'RAG',
		in_staging_tab_name			=> 'CMS_COMPANY_STAGING',
		in_staging_id_col_name		=> 'COMPANY_REFERENCE',
		in_reference				=> '12345',
		in_mapped_column 			=> 'ASSESSMENT_DATE',
		in_data_type				=> 'DATE',
		out_str_val					=> v_val,
		out_date_val				=> v_date_val
	)
	THEN
		csr.unit_test_pkg.TestFail('Error parsing to a date value');
	END IF;
	
	csr.unit_test_pkg.AssertAreEqual(DATE '2016-06-01', v_date_val, 'Returned parsed value is not the expected one');
END;

PROCEDURE Test_ProcessRecord
AS
	v_company_type_id			NUMBER;
	v_company_sid				NUMBER;
	v_created_company_sid		NUMBER;
	v_processed_record_ids		security_pkg.T_SID_IDS;
	v_processed_record_id		NUMBER;
	v_score_band_id				NUMBER;
	v_expected_score_band_id	NUMBER DEFAULT 3;
	v_score						NUMBER;
	v_expected_score			NUMBER DEFAULT 15.5;
	v_assessed_by_sid			NUMBER;
	v_revenue					NUMBER;
	v_expected_revenue			NUMBER DEFAULT 9999999.10;
	v_destination_tab_sid		NUMBER;
	v_count						NUMBER;
	v_reference_id_1			NUMBER;
	v_last_assess_date			DATE;
	v_expected_last_assess_date	DATE DEFAULT DATE '2014-01-15';
	v_comments					VARCHAR2(4000);
	v_expected_comments			VARCHAR2(4000) DEFAULT 'Assessment failed due to company''s illegal activities';
	v_matched_company_sids		security.security_pkg.T_SID_IDS;
	v_expenses					NUMBER;
	v_fac_company_sid			NUMBER;
	v_facility_company_sid		NUMBER;
BEGIN	
	security.user_pkg.logonadmin(v_site_name);
	SetUpConfig1;
	
	v_destination_tab_sid	:= cms.tab_pkg.GetTableSid('RAG', 'COMPANY_DATA');
	v_company_type_id := company_type_pkg.GetCompanyTypeId('SUPPLIER');
	
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name						=> 'Chocolate industry',
		in_country_code				=> 'gb',
		in_company_type_id			=> v_company_type_id,
		in_sector_id				=> NULL,
		out_company_sid				=> v_company_sid
	);
	INSERT INTO company_reference (company_sid, value, reference_id, company_reference_id)
		VALUES(v_company_sid, '54321', v_reference_id, company_reference_id_seq.nextval);
	
	company_pkg.ActivateCompany(v_company_sid);
	company_pkg.ActivateRelationship(chain.helper_pkg.GetTopCompanySid, v_company_sid);
	
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name						=> 'Cocoa beans',
		in_country_code				=> 'gb',
		in_company_type_id			=> v_company_type_id,
		in_sector_id				=> NULL,
		out_company_sid				=> v_fac_company_sid
	);
	
	company_pkg.ActivateCompany(v_fac_company_sid);
	company_pkg.ActivateRelationship(chain.helper_pkg.GetTopCompanySid, v_fac_company_sid);
		
	AddStagingRow(
		in_company_reference	=> '54321',
		in_name					=> 'Chocolate bunnies inc',
		in_country				=> 'de',
		in_revenue				=> v_expected_revenue,
		in_assessed_by			=> 'Antoine Winterbottom',
		in_score				=> v_expected_score,
		in_score_band			=> 'Red',
		in_assessment_date		=> v_expected_last_assess_date,
		in_comments				=> v_expected_comments,
		in_expenses_string		=> '232.21',
		in_fac_company_sid		=> v_fac_company_sid
	);
	
	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id		=> v_staging_link_id_1_1, 
		in_reference					=> '54321',
		out_created_company_sid			=> v_created_company_sid,
		out_matched_company_sids		=> v_matched_company_sids,
		out_processed_record_ids		=> v_processed_record_ids
	);
	
	v_processed_record_id := v_processed_record_ids(1);
	
	IF v_matched_company_sids.count <> 1 THEN
		csr.unit_test_pkg.TestFail('Expected 1 exact match and not a new company');
	END IF;
	
	csr.unit_test_pkg.AssertAreEqual(v_company_sid, v_matched_company_sids(1), 'Resulted matched company is not the expected one');
	
	BEGIN
		EXECUTE IMMEDIATE('
			SELECT score_band_id, score, assessed_by_sid, revenue, last_assess_date, comments, expenses, facility_company_sid
			  FROM rag.company_data 
			 WHERE company_sid = :1
		')
		 INTO v_score_band_id, v_score, v_assessed_by_sid, v_revenue, v_last_assess_date, v_comments, v_expenses, v_facility_company_sid
		USING v_company_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected CMS company data to have been created');
	END;
	
	csr.unit_test_pkg.AssertAreEqual(v_expected_score_band_id, v_score_band_id, 'Saved value for score_band_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_score, v_score, 'Saved value for score is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_user_sid_3, v_assessed_by_sid, 'Saved value for assessed_by_sid is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_revenue, v_revenue, 'Saved value for revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_last_assess_date, v_last_assess_date, 'Saved value for last_assess_date is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_comments, v_comments, 'Saved value for comments is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(232.21, v_expenses, 'Saved value for expenses is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_fac_company_sid, v_facility_company_sid, 'Saved value for facility company sid is not the expected one');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'SCORE')
	   AND old_val IS NULL
	   AND new_val = to_char(v_expected_score);
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for SCORE');
			
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'SCORE_BAND_ID')
	   AND old_val IS NULL
	   AND new_val = to_char(v_expected_score_band_id)
	   AND new_raw_val = 'Red';
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for SCORE_BAND_ID');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'ASSESSED_BY_SID')
	   AND old_val IS NULL
	   AND new_val = to_char(v_expected_user_sid_3)
	   AND new_raw_val = 'Antoine Winterbottom';
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for ASSESSED_BY_SID');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'REVENUE')
	   AND old_val IS NULL
	   AND new_val = to_char(v_expected_revenue);
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for REVENUE');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'LAST_ASSESS_DATE')
	   AND old_val IS NULL
	   AND new_val = to_char(v_expected_last_assess_date);
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for LAST_ASSESS_DATE');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'COMMENTS')
	   AND old_val IS NULL
	   AND new_val = v_expected_comments;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for COMMENTS');
	
	------------------------------------
	--ok now try to update the cms data and re-process
	EXECUTE IMMEDIATE '
		UPDATE rag.cms_company_staging
		   SET score_band = ''green'', score= 99, comments=''Ignore previous comment''
		 WHERE company_reference = 54321
	';
		
	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id		=> v_staging_link_id_1_1, 
		in_reference					=> '54321',
		out_created_company_sid			=> v_created_company_sid,
		out_matched_company_sids		=> v_matched_company_sids,
		out_processed_record_ids		=> v_processed_record_ids,
		in_force_re_eval				=> 1
	);
	
	v_processed_record_id := v_processed_record_ids(1);
	
	IF v_matched_company_sids.count <> 1 THEN
		csr.unit_test_pkg.TestFail('Expected 1 exact match and not a new company');
	END IF;
	
	csr.unit_test_pkg.AssertAreEqual(v_company_sid, v_matched_company_sids(1), 'Resulted matched company is not the expected one');
	
	EXECUTE IMMEDIATE('
		SELECT score_band_id, score, assessed_by_sid, revenue, last_assess_date, comments
		  FROM rag.company_data 
		 WHERE company_sid = :1
	')
	 INTO v_score_band_id, v_score, v_assessed_by_sid, v_revenue, v_last_assess_date, v_comments
	USING v_company_sid;

	csr.unit_test_pkg.AssertAreEqual(1, v_score_band_id, 'Saved value for score_band_id is not the expected one.');
	csr.unit_test_pkg.AssertAreEqual(99, v_score, 'Saved value for score is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_user_sid_3, v_assessed_by_sid, 'Saved value for assessed_by_sid is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_revenue, v_revenue, 'Saved value for revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_last_assess_date, v_last_assess_date, 'Saved value for last_assess_date is not the expected one');
	csr.unit_test_pkg.AssertAreEqual('Ignore previous comment', v_comments, 'Saved value for comments is not the expected one');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'LAST_ASSESS_DATE')
	   AND old_val = to_char(v_expected_last_assess_date)
	   AND new_val = to_char(v_expected_last_assess_date);
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for LAST_ASSESS_DATE');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'ASSESSED_BY_SID')
	   AND old_val =  to_char(v_expected_user_sid_3)
	   AND current_desc_val = 'Antoine Winterbottom'
	   AND new_val = to_char(v_expected_user_sid_3)
	   AND new_raw_val = 'Antoine Winterbottom';
	   
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for ASSESSED_BY_SID');
	
	-- Try to set 'expenses' to something that isn't a number
	EXECUTE IMMEDIATE '
		UPDATE rag.cms_company_staging
		   SET expenses_string = ''nan''
		 WHERE company_reference = 54321
	';
		
	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_staging_link_id_1_1,
		in_reference				=> '54321', 
		out_created_company_sid		=> v_created_company_sid,
		out_matched_company_sids	=> v_matched_company_sids,
		out_processed_record_ids	=> v_processed_record_ids,
		in_force_re_eval			=> 1
	);
	
	v_processed_record_id := v_processed_record_ids(1);
	
	EXECUTE IMMEDIATE('
		SELECT expenses
		  FROM rag.company_data 
		 WHERE company_sid = :1
	')
	 INTO v_expenses
	USING v_company_sid;
	
	csr.unit_test_pkg.AssertAreEqual(232.21, v_expenses, 'Saved value for expenses is not the expected one');
	
	-- Check the parse error is logged. (N.B. old_val is not stored in this case.)
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'EXPENSES')
	   AND new_val IS NULL
	   AND new_raw_val = 'nan'
	   AND error_message IS NOT NULL;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for EXPENSES');
	
	--put deliberately a wrong enum and check whether the error is logged
	EXECUTE IMMEDIATE '
		UPDATE rag.cms_company_staging
		   SET score_band = ''fish'', score= 95, comments=''Wrong enum parsing will fail but the rest should be good''
		 WHERE company_reference = 54321
	';
		
	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_staging_link_id_1_1,
		in_reference				=> '54321',
		out_created_company_sid		=> v_created_company_sid,
		out_matched_company_sids	=> v_matched_company_sids,
		out_processed_record_ids	=> v_processed_record_ids,
		in_force_re_eval			=> 1
	);
	
	v_processed_record_id := v_processed_record_ids(1);
	
	IF v_matched_company_sids.count <> 1 THEN
		csr.unit_test_pkg.TestFail('Expected 1 exact match and not a new company');
	END IF;
	
	csr.unit_test_pkg.AssertAreEqual(v_company_sid, v_matched_company_sids(1), 'Resulted matched company is not the expected one');
	
	EXECUTE IMMEDIATE('
		SELECT score_band_id, score, assessed_by_sid, revenue, last_assess_date, comments
		  FROM rag.company_data 
		 WHERE company_sid = :1
	')
	 INTO v_score_band_id, v_score, v_assessed_by_sid, v_revenue, v_last_assess_date, v_comments
	USING v_company_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_score_band_id, 'Stored value for SCORE_BAND_ID is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(95, v_score, 'Stored value for SCORE is not the expected one');
			
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid,'SCORE')
	   AND old_val = to_char(99)
	   AND new_val = to_char(95);
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for SCORE');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid,'SCORE_BAND_ID')
	   AND error_message IS NOT NULL
	   AND new_raw_val = 'fish'
	   AND new_val IS NULL;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong error log data for SCORE_BAND_ID');
	
	----------------------------------------------
	--test case: create new company with cms data
	v_created_company_sid := NULL;
	
	AddStagingRow(
		in_company_reference	=> '99999',
		in_name					=> 'Clean water company',
		in_country				=> 'br',
		in_revenue				=> v_expected_revenue,
		in_assessed_by			=> 'Kate Rye',
		in_score				=> v_expected_score,
		in_score_band			=> 'Amber',
		in_assessment_date		=> v_expected_last_assess_date,
		in_comments				=> NULL,
		in_expenses_string		=> NULL
	);
	
	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_staging_link_id_1_1,
		in_reference				=> '99999',
		out_created_company_sid		=> v_created_company_sid,
		out_matched_company_sids	=> v_matched_company_sids,
		out_processed_record_ids	=> v_processed_record_ids,
		in_force_re_eval			=> 1
	);
	
	v_processed_record_id := v_processed_record_ids(1);

	IF v_created_company_sid IS NULL THEN
		csr.unit_test_pkg.TestFail('Expected a new company');
	END IF;
	
	v_expected_company_sid := test_chain_utils_pkg.GetChainCompanySid('Clean water company', 'br');
	csr.unit_test_pkg.AssertAreEqual(v_expected_company_sid, v_created_company_sid, 'Created company is not the expected one');	
	
	EXECUTE IMMEDIATE('
		SELECT score_band_id, score, assessed_by_sid, revenue, last_assess_date, comments
		  FROM rag.company_data 
		 WHERE company_sid = :1
	')
	 INTO v_score_band_id, v_score, v_assessed_by_sid, v_revenue, v_last_assess_date, v_comments
	USING v_created_company_sid;
	csr.unit_test_pkg.AssertAreEqual(2, v_score_band_id, 'Saved value for score_band_id is not the expected one');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid,'SCORE_BAND_ID')
	   AND new_val = to_char(2)
	   AND old_val IS NULL
	   AND current_desc_val IS NULL
	   AND new_raw_val = 'Amber'
	   AND new_translated_val IS NULL;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for SCORE_BAND_ID');
	
	--- score_band, add translation record
	EXECUTE IMMEDIATE '
		UPDATE rag.cms_company_staging
		   SET score_band = ''rojo''
		 WHERE company_reference = 99999
	';
	
	EXECUTE IMMEDIATE ('INSERT INTO RAG.SCORE_BAND_MAP (SCORE_BAND_MAP_ID, SCORE_BAND_ID, ORIGINAL_TEXT) VALUES (10002, 3, ''roJo'')');
	
	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_staging_link_id_1_1,
		in_reference				=> '99999',
		out_created_company_sid		=> v_created_company_sid,
		out_matched_company_sids	=> v_matched_company_sids,
		out_processed_record_ids	=> v_processed_record_ids,
		in_force_re_eval			=> 1
	);
	
	v_processed_record_id := v_processed_record_ids(1);
			
	IF v_matched_company_sids.count <> 1 OR v_created_company_sid IS NOT NULL THEN
		csr.unit_test_pkg.TestFail('Expected 1 exact match and not a new company');
	END IF;
	
	csr.unit_test_pkg.AssertAreEqual(v_expected_company_sid, v_matched_company_sids(1), 'Resulted matched company is not the expected one');
	
	EXECUTE IMMEDIATE('
		SELECT score_band_id
		  FROM rag.company_data 
		 WHERE company_sid = :1
	')
	 INTO v_score_band_id
	USING v_expected_company_sid;
	
	csr.unit_test_pkg.AssertAreEqual(3, v_score_band_id, 'Saved value for score_band_id is not the expected one');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid,'SCORE_BAND_ID')
	   AND error_message IS NULL
	   AND old_val = to_char(2)
	   AND current_desc_val = 'Amber'
	   AND new_val = to_char(3)
	   AND lower(new_raw_val) = lower('rojo')
	   AND new_translated_val = 'Red';
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for SCORE_BAND_ID');
END;

PROCEDURE Test_TwoSourcesSameDest
AS
	v_created_company_sid		NUMBER;
	v_processed_record_id		NUMBER;
	v_processed_record_ids		security_pkg.T_SID_IDS;
	v_score_band_id				NUMBER;
	v_score						NUMBER;
	v_assessed_by_sid			NUMBER;
	v_revenue					NUMBER;
	v_last_assess_date			DATE;
	v_comments					VARCHAR2(4000);
	v_matched_company_sids		security.security_pkg.T_SID_IDS;
BEGIN
	SetUpConfig1;
	
	AddStagingRow(
		in_company_reference	=> '54321',
		in_name					=> 'Chocolate bunnies inc',
		in_country				=> 'de',
		in_revenue				=> 232.21,
		in_assessed_by			=> 'Antoine Winterbottom',
		in_score				=> 12,
		in_score_band			=> 'Red',
		in_assessment_date		=> DATE '2016-05-02',
		in_comments				=> 'This is from table 1',
		in_expenses_string		=> NULL
	);
	
	AddStagingRow(
		in_company_reference	=> '54321',
		in_name					=> 'Chocolate bunnies inc',
		in_country				=> 'de',
		in_revenue				=> 542.1,
		in_assessed_by			=> 'Kate Rye',
		in_score				=> 76,
		in_score_band			=> 'Green',
		in_assessment_date		=> DATE '2016-01-03',
		in_comments				=> 'This is from table 2',
		in_expenses_string		=> NULL,
		in_staging_table		=> 'CMS_COMPANY_STAGING_2'
	);
	
	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_staging_link_id_2_1,
		in_reference				=> '54321',
		out_created_company_sid		=> v_created_company_sid,
		out_matched_company_sids	=> v_matched_company_sids,
		out_processed_record_ids	=> v_processed_record_ids,
		in_force_re_eval			=> 1
	);
	
	v_processed_record_id := v_processed_record_ids(1);
	
	IF v_created_company_sid IS NULL THEN
		csr.unit_test_pkg.TestFail('Expected company to be created');
	END IF;
	
	EXECUTE IMMEDIATE('
		SELECT score_band_id, score, assessed_by_sid, revenue, last_assess_date, comments
		  FROM rag.company_data 
		 WHERE company_sid = :1
	')
	 INTO v_score_band_id, v_score, v_assessed_by_sid, v_revenue, v_last_assess_date, v_comments
	USING v_created_company_sid;
	
	-- Expect source CMS_1_1 to overwrite data based on priority
	csr.unit_test_pkg.AssertAreEqual(1, v_score_band_id, 'Saved value for score_band_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(76, v_score, 'Saved value for score is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_user_sid_1, v_assessed_by_sid, 'Saved value for assessed_by_sid is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(542.1, v_revenue, 'Saved value for revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(DATE '2016-01-03', v_last_assess_date, 'Saved value for last_assess_date is not the expected one');
	csr.unit_test_pkg.AssertAreEqual('This is from table 2', v_comments, 'Saved value for comments is not the expected one');
			
	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_staging_link_id_1_1,
		in_reference				=> '54321',
		out_created_company_sid		=> v_created_company_sid,
		out_matched_company_sids	=> v_matched_company_sids,
		out_processed_record_ids	=> v_processed_record_ids,
		in_force_re_eval			=> 1
	);

	v_processed_record_id := v_processed_record_ids(1);
	
	EXECUTE IMMEDIATE('
		SELECT score_band_id, score, assessed_by_sid, revenue, last_assess_date, comments
		  FROM rag.company_data 
		 WHERE company_sid = :1
	')
	   INTO v_score_band_id, v_score, v_assessed_by_sid, v_revenue, v_last_assess_date, v_comments
	  USING v_matched_company_sids(1);
	
	-- Expect source CMS_1_1 to overwrite data based on priority
	csr.unit_test_pkg.AssertAreEqual(3, v_score_band_id, 'Saved value for score_band_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(12, v_score, 'Saved value for score is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_user_sid_3, v_assessed_by_sid, 'Saved value for assessed_by_sid is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(232.21, v_revenue, 'Saved value for revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(DATE '2016-05-02', v_last_assess_date, 'Saved value for last_assess_date is not the expected one');
	csr.unit_test_pkg.AssertAreEqual('This is from table 1', v_comments, 'Saved value for comments is not the expected one');
	
	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_staging_link_id_2_1,
		in_reference				=> '54321',
		out_created_company_sid		=> v_created_company_sid,
		out_matched_company_sids	=> v_matched_company_sids,
		out_processed_record_ids	=> v_processed_record_ids,
		in_force_re_eval			=> 1
	);
	
	v_processed_record_id := v_processed_record_ids(1);
	
	EXECUTE IMMEDIATE('
		SELECT score_band_id, score, assessed_by_sid, revenue, last_assess_date, comments
		  FROM rag.company_data 
		 WHERE company_sid = :1
	')
	   INTO v_score_band_id, v_score, v_assessed_by_sid, v_revenue, v_last_assess_date, v_comments
	  USING v_matched_company_sids(1);
	
	-- Do not expect source CMS_2_1 to overwrite data based on priority
	csr.unit_test_pkg.AssertAreEqual(3, v_score_band_id, 'Saved value for score_band_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(12, v_score, 'Saved value for score is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_user_sid_3, v_assessed_by_sid, 'Saved value for assessed_by_sid is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(232.21, v_revenue, 'Saved value for revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(DATE '2016-05-02', v_last_assess_date, 'Saved value for last_assess_date is not the expected one');
	csr.unit_test_pkg.AssertAreEqual('This is from table 1', v_comments, 'Saved value for comments is not the expected one');
END;

PROCEDURE Test_TwoSourcesDiffDest
AS
	v_created_company_sid		NUMBER;
	v_processed_record_id		NUMBER;
	v_processed_record_ids		security_pkg.T_SID_IDS;
	v_score_band_id				NUMBER;
	v_score						NUMBER;
	v_assessed_by_sid			NUMBER;
	v_revenue					NUMBER;
	v_last_assess_date			DATE;
	v_comments					VARCHAR2(4000);
	v_matched_company_sids		security.security_pkg.T_SID_IDS;
	v_count						NUMBER;
BEGIN
	SetUpConfig1;
	
	AddStagingRow(
		in_company_reference	=> '54321',
		in_name					=> 'Chocolate bunnies inc',
		in_country				=> 'de',
		in_revenue				=> 232.21,
		in_assessed_by			=> 'Antoine Winterbottom',
		in_score				=> 12,
		in_score_band			=> 'Red',
		in_assessment_date		=> DATE '2016-05-02',
		in_comments				=> 'This is from table 1',
		in_expenses_string		=> NULL
	);
	
	AddStagingRow(
		in_company_reference	=> '54321',
		in_name					=> 'Chocolate bunnies inc',
		in_country				=> 'de',
		in_revenue				=> 542.1,
		in_assessed_by			=> 'Kate Rye',
		in_score				=> 76,
		in_score_band			=> 'Green',
		in_assessment_date		=> DATE '2016-01-03',
		in_comments				=> 'This is from table 2',
		in_expenses_string		=> NULL,
		in_staging_table		=> 'CMS_COMPANY_STAGING_2'
	);
	
	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_staging_link_id_2_2,
		in_reference				=> '54321',
		out_created_company_sid		=> v_created_company_sid,
		out_matched_company_sids	=> v_matched_company_sids,
		out_processed_record_ids	=> v_processed_record_ids,
		in_force_re_eval			=> 1
	);
	
	v_processed_record_id := v_processed_record_ids(1);
	
	IF v_created_company_sid IS NULL THEN
		csr.unit_test_pkg.TestFail('Expected company to be created');
	END IF;
	
	-- Check company_data
	EXECUTE IMMEDIATE '
		SELECT COUNT(*)
		  FROM rag.company_data
		 WHERE company_sid = :1
	'
	   INTO v_count
	  USING v_created_company_sid;
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'No data should have been inserted into COMPANY_DATA');
	
	-- Check company_data_2
	EXECUTE IMMEDIATE('
		SELECT score_band_id, score, assessed_by_sid, revenue, last_assess_date, comments
		  FROM rag.company_data_2
		 WHERE company_sid = :1
	')
	 INTO v_score_band_id, v_score, v_assessed_by_sid, v_revenue, v_last_assess_date, v_comments
	USING v_created_company_sid;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_score_band_id, 'Saved value for company_data_2.score_band_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(76, v_score, 'Saved value for company_data_2.score is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_user_sid_1, v_assessed_by_sid, 'Saved value for company_data_2.assessed_by_sid is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(542.1, v_revenue, 'Saved value for company_data_2.revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(DATE '2016-01-03', v_last_assess_date, 'Saved value for company_data_2.last_assess_date is not the expected one');
	csr.unit_test_pkg.AssertAreEqual('This is from table 2', v_comments, 'Saved value for company_data_2.comments is not the expected one');
	
	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_staging_link_id_1_1,
		in_reference				=> '54321',
		out_created_company_sid		=> v_created_company_sid,
		out_matched_company_sids	=> v_matched_company_sids,
		out_processed_record_ids	=> v_processed_record_ids,
		in_force_re_eval			=> 1
	);
	
	v_processed_record_id := v_processed_record_ids(1);
	
	-- Check company_data
	EXECUTE IMMEDIATE('
		SELECT score_band_id, score, assessed_by_sid, revenue, last_assess_date, comments
		  FROM rag.company_data 
		 WHERE company_sid = :2
	')
	   INTO v_score_band_id, v_score, v_assessed_by_sid, v_revenue, v_last_assess_date, v_comments
	  USING v_matched_company_sids(1);
	
	csr.unit_test_pkg.AssertAreEqual(3, v_score_band_id, 'Saved value for company_data.score_band_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(12, v_score, 'Saved value for company_data.score is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_user_sid_3, v_assessed_by_sid, 'Saved value for company_data.assessed_by_sid is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(232.21, v_revenue, 'Saved value for company_data.revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(DATE '2016-05-02', v_last_assess_date, 'Saved value for company_data.last_assess_date is not the expected one');
	csr.unit_test_pkg.AssertAreEqual('This is from table 1', v_comments, 'Saved value for company_data.comments is not the expected one');
	
	-- Check company_data_2
	EXECUTE IMMEDIATE('
		SELECT score_band_id, score, assessed_by_sid, revenue, last_assess_date, comments
		  FROM rag.company_data_2
		 WHERE company_sid = :1
	')
	 INTO v_score_band_id, v_score, v_assessed_by_sid, v_revenue, v_last_assess_date, v_comments
	USING v_matched_company_sids(1);
	
	csr.unit_test_pkg.AssertAreEqual(1, v_score_band_id, 'Saved value for company_data_2.score_band_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(76, v_score, 'Saved value for company_data_2.score is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_user_sid_1, v_assessed_by_sid, 'Saved value for company_data_2.assessed_by_sid is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(542.1, v_revenue, 'Saved value for company_data_2.revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(DATE '2016-01-03', v_last_assess_date, 'Saved value for company_data_2.last_assess_date is not the expected one');
	csr.unit_test_pkg.AssertAreEqual('This is from table 2', v_comments, 'Saved value for company_data_2.comments is not the expected one');
	
	EXECUTE IMMEDIATE '
		UPDATE rag.cms_company_staging_2
		   SET score_band = ''Red''
		 WHERE company_reference = 54321';
	
	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_staging_link_id_2_2,
		in_reference				=> '54321',
		out_created_company_sid		=> v_created_company_sid,
		out_matched_company_sids	=> v_matched_company_sids,
		out_processed_record_ids	=> v_processed_record_ids,
		in_force_re_eval			=> 1
	);
	
	v_processed_record_id := v_processed_record_ids(1);

	-- Check company_data
	EXECUTE IMMEDIATE('
		SELECT score_band_id, score, assessed_by_sid, revenue, last_assess_date, comments
		  FROM rag.company_data 
		 WHERE company_sid = :2
	')
	   INTO v_score_band_id, v_score, v_assessed_by_sid, v_revenue, v_last_assess_date, v_comments
	  USING v_matched_company_sids(1);
	
	csr.unit_test_pkg.AssertAreEqual(3, v_score_band_id, 'Saved value for company_data.score_band_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(12, v_score, 'Saved value for company_data.score is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_user_sid_3, v_assessed_by_sid, 'Saved value for company_data.assessed_by_sid is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(232.21, v_revenue, 'Saved value for company_data.revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(DATE '2016-05-02', v_last_assess_date, 'Saved value for company_data.last_assess_date is not the expected one');
	csr.unit_test_pkg.AssertAreEqual('This is from table 1', v_comments, 'Saved value for company_data.comments is not the expected one');
	
	-- Check company_data_2
	EXECUTE IMMEDIATE('
		SELECT score_band_id, score, assessed_by_sid, revenue, last_assess_date, comments
		  FROM rag.company_data_2
		 WHERE company_sid = :1
	')
	 INTO v_score_band_id, v_score, v_assessed_by_sid, v_revenue, v_last_assess_date, v_comments
	USING v_matched_company_sids(1);
	
	csr.unit_test_pkg.AssertAreEqual(3, v_score_band_id, 'Saved value for company_data_2.score_band_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(76, v_score, 'Saved value for company_data_2.score is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_user_sid_1, v_assessed_by_sid, 'Saved value for company_data_2.assessed_by_sid is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(542.1, v_revenue, 'Saved value for company_data_2.revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(DATE '2016-01-03', v_last_assess_date, 'Saved value for company_data_2.last_assess_date is not the expected one');
	csr.unit_test_pkg.AssertAreEqual('This is from table 2', v_comments, 'Saved value for company_data_2.comments is not the expected one');
	
	-- Try the other way around i.e. insert via the higher priority source, then check the lower priority source inserts into its own table
	
	AddStagingRow(
		in_company_reference	=> '76585',
		in_name					=> 'Monkeys''r''us',
		in_country				=> 'de',
		in_revenue				=> 232.21,
		in_assessed_by			=> 'Antoine Winterbottom',
		in_score				=> 12,
		in_score_band			=> 'Red',
		in_assessment_date		=> DATE '2016-05-02',
		in_comments				=> 'This is from table 1',
		in_expenses_string		=> NULL
	);
	
	AddStagingRow(
		in_company_reference	=> '76585',
		in_name					=> 'Monkeys''r''us',
		in_country				=> 'de',
		in_revenue				=> 542.1,
		in_assessed_by			=> 'Kate Rye',
		in_score				=> 76,
		in_score_band			=> 'Green',
		in_assessment_date		=> DATE '2016-01-03',
		in_comments				=> 'This is from table 2',
		in_expenses_string		=> NULL,
		in_staging_table		=> 'CMS_COMPANY_STAGING_2'
	);
	
	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_staging_link_id_1_1,
		in_reference				=> '76585',
		out_created_company_sid		=> v_created_company_sid,
		out_matched_company_sids	=> v_matched_company_sids,
		out_processed_record_ids	=> v_processed_record_ids,
		in_force_re_eval			=> 1
	);
	
	v_processed_record_id := v_processed_record_ids(1);
	
	IF v_created_company_sid IS NULL THEN
		csr.unit_test_pkg.TestFail('Expected company to be created');
	END IF;
	
	-- Check company_data_2
	EXECUTE IMMEDIATE '
		SELECT COUNT(*)
		  FROM rag.company_data_2
		 WHERE company_sid = :1
	'
	   INTO v_count
	  USING v_created_company_sid;
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'No data should have been inserted into COMPANY_DATA_2');
	
	-- Check company_data
	EXECUTE IMMEDIATE('
		SELECT score_band_id, score, assessed_by_sid, revenue, last_assess_date, comments
		  FROM rag.company_data 
		 WHERE company_sid = :2
	')
	   INTO v_score_band_id, v_score, v_assessed_by_sid, v_revenue, v_last_assess_date, v_comments
	  USING v_created_company_sid;
	
	csr.unit_test_pkg.AssertAreEqual(3, v_score_band_id, 'Saved value for company_data.score_band_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(12, v_score, 'Saved value for company_data.score is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_user_sid_3, v_assessed_by_sid, 'Saved value for company_data.assessed_by_sid is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(232.21, v_revenue, 'Saved value for company_data.revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(DATE '2016-05-02', v_last_assess_date, 'Saved value for company_data.last_assess_date is not the expected one');
	csr.unit_test_pkg.AssertAreEqual('This is from table 1', v_comments, 'Saved value for company_data.comments is not the expected one');
	
	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_staging_link_id_2_2,
		in_reference				=> '76585',
		out_created_company_sid		=> v_created_company_sid,
		out_matched_company_sids	=> v_matched_company_sids,
		out_processed_record_ids	=> v_processed_record_ids,
		in_force_re_eval			=> 1
	);
	
	v_processed_record_id := v_processed_record_ids(1);
	
	-- Check company_data
	EXECUTE IMMEDIATE('
		SELECT score_band_id, score, assessed_by_sid, revenue, last_assess_date, comments
		  FROM rag.company_data 
		 WHERE company_sid = :2
	')
	   INTO v_score_band_id, v_score, v_assessed_by_sid, v_revenue, v_last_assess_date, v_comments
	  USING v_matched_company_sids(1);
	
	csr.unit_test_pkg.AssertAreEqual(3, v_score_band_id, 'Saved value for company_data.score_band_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(12, v_score, 'Saved value for company_data.score is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_user_sid_3, v_assessed_by_sid, 'Saved value for company_data.assessed_by_sid is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(232.21, v_revenue, 'Saved value for company_data.revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(DATE '2016-05-02', v_last_assess_date, 'Saved value for company_data.last_assess_date is not the expected one');
	csr.unit_test_pkg.AssertAreEqual('This is from table 1', v_comments, 'Saved value for company_data.comments is not the expected one');
	
	-- Check company_data_2
	EXECUTE IMMEDIATE('
		SELECT score_band_id, score, assessed_by_sid, revenue, last_assess_date, comments
		  FROM rag.company_data_2
		 WHERE company_sid = :1
	')
	 INTO v_score_band_id, v_score, v_assessed_by_sid, v_revenue, v_last_assess_date, v_comments
	USING v_matched_company_sids(1);
	
	-- Expect source CMS_1_1 to overwrite data based on priority
	csr.unit_test_pkg.AssertAreEqual(1, v_score_band_id, 'Saved value for company_data_2.score_band_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(76, v_score, 'Saved value for company_data_2.score is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_user_sid_1, v_assessed_by_sid, 'Saved value for company_data_2.assessed_by_sid is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(542.1, v_revenue, 'Saved value for company_data_2.revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(DATE '2016-01-03', v_last_assess_date, 'Saved value for company_data_2.last_assess_date is not the expected one');
	csr.unit_test_pkg.AssertAreEqual('This is from table 2', v_comments, 'Saved value for company_data_2.comments is not the expected one');
END;

PROCEDURE Test_ProcessWithMissingMand
AS
	v_created_company_sid security.security_pkg.T_SID_ID;
	v_count NUMBER;
	v_matched_company_sids security.security_pkg.T_SID_IDS;
	v_destination_tab_sid security.security_pkg.T_SID_ID;
	v_processed_record_id NUMBER;
	v_processed_record_ids security_pkg.T_SID_IDS;
BEGIN
	SetUpConfig1;
	
	-- Test missing mandatory fields
	v_destination_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'COMPANY_DATA');
	
	AddStagingRow(
		in_company_reference	=> '56548',
		in_name					=> 'Running out of test names',
		in_country				=> 'br',
		in_revenue				=> NULL,
		in_assessed_by			=> 'Not a user', /* will fail parse and consequently null test */
		in_score				=> 34,
		in_score_band			=> 'Amber',
		in_assessment_date		=> DATE '2016-03-21',
		in_comments				=> NULL,
		in_expenses_string		=> NULL,
		in_staging_table		=> 'CMS_COMPANY_STAGING'
	);
		
	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id	=> v_staging_link_id_1_1,
		in_reference				=> '56548',
		out_created_company_sid		=> v_created_company_sid,
		out_matched_company_sids	=> v_matched_company_sids,
		out_processed_record_ids	=> v_processed_record_ids,
		in_force_re_eval			=> 1
	);
	
	v_processed_record_id := v_processed_record_ids(1);
	
	IF v_created_company_sid IS NULL THEN
		csr.unit_test_pkg.TestFail('Expected a new company');
	END IF;
	
	v_expected_company_sid := test_chain_utils_pkg.GetChainCompanySid('Running out of test names', 'br');
	csr.unit_test_pkg.AssertAreEqual(v_expected_company_sid, v_created_company_sid, 'Created company is not the expected one');
	
	EXECUTE IMMEDIATE('
		SELECT COUNT(*)
		  FROM rag.company_data 
		 WHERE company_sid = :1
	')
	 INTO v_count
	USING v_created_company_sid;
	
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Expected CMS insert to fail');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid,'REVENUE')
	   AND error_message IS NOT NULL;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Missing mandatory error log for REVENUE');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_id
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid,'ASSESSED_BY_SID')
	   AND error_message IS NOT NULL;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Missing mandatory error log for ASSESSED_BY_SID');
END;

PROCEDURE Test_MergeCmsData
AS
	v_company_sid					security.security_pkg.T_SID_ID;
	v_count							NUMBER(10);
	v_company_type_id				company_type.company_type_id%TYPE := company_type_pkg.GetCompanyTypeId('SUPPLIER');
	v_assessed_by_1					security.security_pkg.T_SID_ID;
	v_assessed_by_2					security.security_pkg.T_SID_ID;
	v_processed_record_id			dedupe_processed_record.dedupe_processed_record_id%TYPE;
	v_sql							VARCHAR2(4000);
	PROCEDURE AddTempTableRow(
		in_src_col_name				VARCHAR2,
		in_dest_col_name			VARCHAR2,
		in_str_val					VARCHAR2,
		in_date_val					DATE
	)
	AS
	BEGIN
		IF in_str_val IS NOT NULL OR in_date_val IS NOT NULL THEN
			INSERT INTO chain.tt_dedupe_cms_data (processed_record_id, oracle_schema, source_table, source_tab_sid, source_column, source_col_sid,
				source_col_type, source_data_type, destination_table, destination_tab_sid, destination_column,
				destination_col_sid, destination_col_type, destination_data_type, new_str_value, new_date_value)
			SELECT 9999999999, 'RAG', t.oracle_table, t.tab_sid, tc.oracle_column, tc.column_sid, tc.col_type, tc.data_type, 
				dt.oracle_table, dt.tab_sid, dtc.oracle_column, dtc.column_sid, dtc.col_type, dtc.data_type, in_str_val, in_date_val
			  FROM cms.tab t
			  JOIN cms.tab_column tc ON t.tab_sid = tc.tab_sid
			 CROSS JOIN cms.tab dt
			  JOIN cms.tab_column dtc ON dtc.tab_sid = dt.tab_sid
			 WHERE t.oracle_schema = 'RAG'
			   AND dt.oracle_schema = 'RAG'
			   AND t.oracle_table = 'CMS_COMPANY_STAGING'
			   AND tc.oracle_column = in_src_col_name
			   AND dt.oracle_table = 'COMPANY_DATA'
			   AND dtc.oracle_column = in_dest_col_name;
		END IF;
	END;
	PROCEDURE SetupCmsDestinationData (
		in_revenue			VARCHAR2,
		in_last_assess_date DATE,
		in_assessed_by_sid	NUMBER,
		in_comments			VARCHAR2,
		in_score_band_id	NUMBER
	)
	AS
	BEGIN
		AddTempTableRow('REVENUE', 'REVENUE', in_revenue, NULL);
		AddTempTableRow('ASSESSMENT_DATE', 'LAST_ASSESS_DATE', NULL, in_last_assess_date);
		AddTempTableRow('ASSESSED_BY', 'ASSESSED_BY_SID', TO_CHAR(in_assessed_by_sid), NULL);
		AddTempTableRow('COMMENTS', 'COMMENTS', in_comments, NULL);
		AddTempTableRow('SCORE_BAND', 'SCORE_BAND_ID', in_score_band_id, NULL);
	END;
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	SetUpConfig1;
	
	v_assessed_by_1 := csr.unit_test_pkg.GetOrCreateUser('Kate Rye');
	v_assessed_by_2 := csr.unit_test_pkg.GetOrCreateUser('Random Pearson');
	
	-- Create supplier (doesn't need to be tied to the import source)
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name						=> 'Merge test',
		in_country_code				=> 'gb',
		in_company_type_id			=> v_company_type_id,
		in_sector_id				=> NULL,
		out_company_sid				=> v_company_sid
	);
	
	INSERT INTO dedupe_processed_record (dedupe_processed_record_id, dedupe_staging_link_id, reference, 
		iteration_num, processed_dtm, data_merged)
	VALUES (dedupe_processed_record_id_seq.NEXTVAL, v_staging_link_id_1_1, '12345', 1, SYSDATE, 0)
	RETURNING dedupe_processed_record_id INTO v_processed_record_id;
	
	SetupCmsDestinationData('1234.56', TO_DATE('2015-05-17', 'yyyy-MM-dd'), v_assessed_by_1, 'A test comment', 1);
	
	company_dedupe_pkg.MergePreparedCmsData(
		in_oracle_schema			=> 'RAG',
		in_destination_table		=> 'COMPANY_DATA',
		in_destination_tab_sid		=> cms.tab_pkg.GetTableSid('RAG', 'COMPANY_DATA'),
		in_company_sid				=> v_company_sid,
		in_dedupe_staging_link_id	=> v_staging_link_id_1_1,
		in_processed_record_id		=> v_processed_record_id
	);
	
	v_sql := '
		SELECT COUNT(*)
		  FROM rag.COMPANY_DATA
		 WHERE company_sid = :1
		   AND revenue = :2
		   AND last_assess_date = :3
		   AND assessed_by_sid = :4
		   AND comments = :5
		   AND score_band_id = :6';
	
	EXECUTE IMMEDIATE v_sql
	   INTO v_count
	  USING v_company_sid, 1234.56, TO_DATE('2015-05-17', 'yyyy-MM-dd'), v_assessed_by_1, 'A test comment', 1;
	
	IF v_count = 0 THEN
		csr.unit_test_pkg.TestFail('Create COMPANY_DATA record failed');
	END IF;
	
	SetupCmsDestinationData('9876.54', TO_DATE('2016-03-17', 'yyyy-MM-dd'), v_assessed_by_2, 'An updated comment', 2);
	
	company_dedupe_pkg.MergePreparedCmsData(
		in_oracle_schema			=> 'RAG',
		in_destination_table		=> 'COMPANY_DATA',
		in_destination_tab_sid		=> cms.tab_pkg.GetTableSid('RAG', 'COMPANY_DATA'),
		in_company_sid				=> v_company_sid,
		in_processed_record_id		=> v_processed_record_id,
		in_dedupe_staging_link_id	=> v_staging_link_id_1_1
	);
	
	EXECUTE IMMEDIATE v_sql
	   INTO v_count
	  USING v_company_sid, 9876.54, TO_DATE('2016-03-17', 'yyyy-MM-dd'), v_assessed_by_2, 'An updated comment', 2;
	
	IF v_count = 0 THEN
		csr.unit_test_pkg.TestFail('Update COMPANY_DATA record failed');
	END IF;
END;

PROCEDURE Test_ChildCmsDataCreate
AS
	v_count					NUMBER;
	v_company_type_id		NUMBER;
	v_created_company_sid	NUMBER;
	v_processed_record_ids	security_pkg.T_SID_IDS;
	v_sales_org_id			NUMBER;
	v_merch_cat_id			NUMBER;
	v_revenue 				NUMBER;
	v_started_by_sid		NUMBER;
	v_start_date			DATE;
	v_comments				VARCHAR2(4000);
	v_cms_record_ids	security.security_pkg.T_SID_IDS;
BEGIN	
	security.user_pkg.logonadmin(v_site_name);
	SetUpConfig2;	
	
	v_company_type_id := company_type_pkg.GetCompanyTypeId('SUPPLIER');
		
	AddStaging3Row(
		in_company_id	=> '100200300',
		in_name			=> 'Best commerce company',
		in_country		=> 'it',
		in_ref_1		=> 'Hsw cmm',
		in_ref_2		=> 'Hsw cmm 2'
	);
	
	AddChildStagingRow(
		in_company_id	=> '100200300',
		in_sales_org	=> 'f'||unistr('\00F8')||'tex FOOD',
		in_merch_cat	=> 'R5726 (S) LADIES coats',
		in_started_by	=> NULL,
		in_revenue		=> 100.5,
		in_started_date	=> NULL,
		in_comments		=> 'Nothing interesting to comment'
	);
	
	AddChildStagingRow(
		in_company_id	=> '100200300',
		in_sales_org	=> 'Carl''s Jr.',
		in_merch_cat	=> 'R5663 (S) PERFUMES',
		in_started_by	=> 'Kate Rye',
		in_revenue		=> 99,
		in_started_date	=> DATE '2012-1-12',
		in_comments		=> 'Again, nothing interesting to comment'
	);
	
	AddChildStagingRow(
		in_company_id	=> '100200300',
		in_sales_org	=> 'f'||unistr('\00F8')||'tex food',
		in_merch_cat	=> 'R5663 (S) PERFUMES',
		in_started_by	=> 'Kate Rye',
		in_revenue		=> 88,
		in_started_date	=> DATE '2010-06-30',
		in_comments		=> NULL
	);
	
	AddChildStagingRow(
		in_company_id	=> '100200300',
		in_sales_org	=> 'f'||unistr('\00F8')||'tex food',
		in_merch_cat	=> 'an enum value that doesn''t exist',--that will not match hence it should log a mandatory field missing error
		in_started_by	=> 'Kate Ryes', 
		in_revenue		=> 88,
		in_started_date	=> DATE '2010-06-30',
		in_comments		=> NULL
	);

	--expect to process both the parent and child staging records
	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id		=> v_source_id_for_child, 
		in_reference			=> '100200300',
		out_processed_record_ids=> v_processed_record_ids
	);
	
	BEGIN
		SELECT created_company_sid
		  INTO v_created_company_sid
		  FROM dedupe_processed_record
		 WHERE reference = '100200300'
		   AND dedupe_staging_link_id = v_staging_link_id_2_1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected chain company to have been created');
	END;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM company_reference
	 WHERE company_sid = v_created_company_sid
	   AND reference_id = v_reference_company_id
	   AND value = '100200300';

	csr.unit_test_pkg.AssertAreEqual(v_count, 1, 'Wrong or no value for company reference field');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM company_reference
	 WHERE company_sid = v_created_company_sid
	   AND reference_id = v_reference_id_1
	   AND value = 'Hsw cmm';

	csr.unit_test_pkg.AssertAreEqual(v_count, 1, 'Wrong or no value for company reference field');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM company_reference
	 WHERE company_sid = v_created_company_sid
	   AND reference_id = v_reference_id_2
	   AND value = 'Hsw cmm 2';

	csr.unit_test_pkg.AssertAreEqual(v_count, 1, 'Wrong or no value for company reference field');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_processed_record
	 WHERE reference = '100200300'
	   AND dedupe_staging_link_id IN (v_staging_link_id_2_1, v_staging_link_id_2_2)
	   AND data_merged = 1
	 ORDER BY dedupe_processed_record_id;
	
	csr.unit_test_pkg.AssertAreEqual(4, v_count, 'Wrong number of merged processed records');

	SELECT cms_record_id
	  BULK COLLECT INTO v_cms_record_ids
	  FROM dedupe_processed_record
	 WHERE reference = '100200300'
	   AND dedupe_staging_link_id = v_staging_link_id_2_2
	   AND cms_record_id IS NOT NULL
	   AND data_merged = 1
	   AND batch_num IS NULL
	 ORDER BY dedupe_processed_record_id;
	
	csr.unit_test_pkg.AssertAreEqual(3, v_cms_record_ids.COUNT,'Wrong number of created child records');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_processed_record
	 WHERE reference = '100200300'
	  AND dedupe_staging_link_id IN (v_staging_link_id_2_1, v_staging_link_id_2_2)
	  AND batch_num IS NULL
	 ORDER BY dedupe_processed_record_id;
	
	csr.unit_test_pkg.AssertAreEqual(5, v_count,'Wrong number of total processed records');

	--assert the first child cms record
	BEGIN
		EXECUTE IMMEDIATE('
			SELECT sales_org_id, merch_cat_id,
				revenue, started_by_sid, start_date, comments
			  FROM rag.company_sales_org 
			 WHERE company_sid = :1
			   AND company_sales_org_id = :2
		')
		 INTO v_sales_org_id, v_merch_cat_id, v_revenue, 
		 v_started_by_sid, v_start_date, v_comments
		USING v_created_company_sid, v_cms_record_ids(1);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected a CMS company record with id:'|| v_cms_record_ids(1));
	END;
	
	csr.unit_test_pkg.AssertAreEqual(2, v_sales_org_id, 'Saved value for sales_org_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(1, v_merch_cat_id, 'Saved value for merch_cat_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(100.5, v_revenue, 'Saved value for revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(NULL, v_started_by_sid, 'Saved value for started_by_sid is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(NULL, v_start_date, 'Saved value for start_date is not the expected one');
	csr.unit_test_pkg.AssertAreEqual('Nothing interesting to comment', v_comments, 'Saved value for comments is not the expected one');

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(1))
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'MERCH_CAT_ID')
	   AND old_val IS NULL
	   AND new_val = to_char(1)
	   AND lower(new_raw_val) = 'r5726 (s) ladies coats';
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for MERCH_CAT_ID');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(1))
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'SALES_ORG_ID')
	   AND old_val IS NULL
	   AND new_val = to_char(2)
	   AND lower(new_raw_val) = 'f'||unistr('\00F8')||'tex food';
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for SALES_ORG_ID');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(1))
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'REVENUE')
	   AND old_val IS NULL
	   AND new_val = to_char('100.5')
	   AND new_raw_val = to_char('100.5');
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for REVENUE');
	
	--assert the second child cms record
	BEGIN
		EXECUTE IMMEDIATE('
			SELECT sales_org_id, merch_cat_id,
				revenue, started_by_sid, start_date, comments
			  FROM rag.company_sales_org 
			 WHERE company_sid = :1
			   AND company_sales_org_id = :2
		')
		 INTO v_sales_org_id, v_merch_cat_id, v_revenue, 
		 v_started_by_sid, v_start_date, v_comments
		USING v_created_company_sid, v_cms_record_ids(2);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected a CMS company record with id:'|| v_cms_record_ids(2));
	END;
	
	csr.unit_test_pkg.AssertAreEqual(6, v_sales_org_id, 'Saved value for sales_org_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(3, v_merch_cat_id, 'Saved value for merch_cat_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(99, v_revenue, 'Saved value for revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_user_sid_1, v_started_by_sid, 'Saved value for started_by_sid is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(DATE '2012-1-12', v_start_date, 'Saved value for start_date is not the expected one');
	csr.unit_test_pkg.AssertAreEqual('Again, nothing interesting to comment', v_comments, 'Saved value for comments is not the expected one');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(2))
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'SALES_ORG_ID')
	   AND old_val IS NULL
	   AND new_val = to_char(6)
	   AND lower(new_raw_val) = 'carl''s jr.';
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for SALES_ORG_ID');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(2))
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'MERCH_CAT_ID')
	   AND old_val IS NULL
	   AND new_val = to_char(3)
	   AND lower(new_raw_val) = 'r5663 (s) perfumes';
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for merch_cat_id');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(2))
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'START_DATE')
	   AND old_val IS NULL
	   AND new_val IS NOT NULL;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for START_DATE');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(2))
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'COMMENTS')
	   AND old_val IS NULL
	   AND lower(new_val) = 'again, nothing interesting to comment';
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for comments');
	
	--assert the third child cms record
	BEGIN
		EXECUTE IMMEDIATE('
			SELECT sales_org_id, merch_cat_id,
				revenue, started_by_sid, start_date, comments
			  FROM rag.company_sales_org 
			 WHERE company_sid = :1
			   AND company_sales_org_id = :2
		')
		 INTO v_sales_org_id, v_merch_cat_id, v_revenue, 
		 v_started_by_sid, v_start_date, v_comments
		USING v_created_company_sid, v_cms_record_ids(3);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected a CMS company record with id:'|| v_cms_record_ids(3));
	END;
	
	csr.unit_test_pkg.AssertAreEqual(2, v_sales_org_id, 'Saved value for sales_org_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(3, v_merch_cat_id, 'Saved value for merch_cat_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(88, v_revenue, 'Saved value for revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_user_sid_1, v_started_by_sid, 'Saved value for started_by_sid is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(DATE '2010-06-30', v_start_date, 'Saved value for start_date is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(NULL, v_comments, 'Saved value for comments is not the expected one');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(3))
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'SALES_ORG_ID')
	   AND old_val IS NULL
	   AND new_val = to_char(2)
	   AND new_raw_val = 'f'||unistr('\00F8')||'tex food';
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for SALES_ORG_ID');
	
	--assert the fourth child cms record
	--todo: check that the error was logged
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_processed_record
	 WHERE reference = '100200300'
	   AND dedupe_staging_link_id = v_staging_link_id_2_2
	   AND cms_record_id IS NULL
	   AND data_merged = 0
	 ORDER BY dedupe_processed_record_id;
	 
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Expected one non merged child record');
	
	security.security_pkg.DebugMsg(NVL(v_processed_record_ids.COUNT, -1));
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_ids(5)
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'MERCH_CAT_ID')
	   AND error_message IS NOT NULL
	   AND new_raw_val = 'an enum value that doesn''t exist';
	   
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for MERCH_CAT_ID');
END;

PROCEDURE Test_ChildCmsDataCreateUpdate
AS
	v_count						NUMBER;
	v_company_type_id			NUMBER;
	v_created_company_sid_1		NUMBER;
	v_created_company_sid_2		NUMBER;
	v_matched_to_company_sid 	NUMBER;
	v_processed_record_ids_1	security_pkg.T_SID_IDS;
	v_processed_record_ids_2	security_pkg.T_SID_IDS;
	v_sales_org_id				NUMBER;
	v_merch_cat_id				NUMBER;
	v_revenue 					NUMBER;
	v_started_by_sid			NUMBER;
	v_start_date				DATE;
	v_comments					VARCHAR2(4000);
	v_comment_batch_1			VARCHAR2(4000) DEFAULT 'Again, nothing interesting to comment';
	v_comment_batch_2			VARCHAR2(4000) DEFAULT 'Again, nothing interesting to comment - second batch comments';
	v_cms_record_ids			security.security_pkg.T_SID_IDS;
	v_score_band_id 			NUMBER;
	v_deleted					NUMBER;
BEGIN	
	security.user_pkg.logonadmin(v_site_name);
	SetUpConfig2(in_use_batch_num_col => TRUE);	
	
	v_company_type_id := company_type_pkg.GetCompanyTypeId('SUPPLIER');
	
	--test batch num
	AddStaging3Row(
		in_company_id	=> '100200300',
		in_name			=> 'Best commerce company',
		in_country		=> 'it',
		in_ref_1		=> 'Hsw cmm',
		in_ref_2		=> 'Hsw cmm 2',
		in_batch_num	=> 1
	);
	
	AddStaging3Row(
		in_company_id	=> '100200400',
		in_name			=> 'Even better commerce company',
		in_country		=> 'es',
		in_ref_1		=> 'Hsw cmm 400',
		in_ref_2		=> 'Hsw cmm 400',
		in_batch_num	=> 1
	);

	AddChildStagingRow(
		in_company_id	=> '100200300',
		in_sales_org	=> 'Carl''s Jr.',
		in_merch_cat	=> 'R5663 (S) PERFUMES',
		in_started_by	=> 'Kate Rye',
		in_revenue		=> 99,
		in_started_date	=> DATE '2012-1-12',
		in_comments		=> v_comment_batch_1,
		in_batch_num	=> 1,
		in_band_label	=> 'Amber'
	);
	
	AddChildStagingRow(
		in_company_id	=> '100200300',
		in_sales_org	=> 'f'||unistr('\00F8')||'tex food',
		in_merch_cat	=> 'R5663 (S) PERFUMES',
		in_started_by	=> 'Kate Rye',
		in_revenue		=> 88,
		in_started_date	=> DATE '2010-06-30',
		in_comments		=> NULL,
		in_batch_num	=> 1
	);
	
	AddChildStagingRow(
		in_company_id	=> '100200400',
		in_sales_org	=> 'f'||unistr('\00F8')||'tex food',
		in_merch_cat	=> 'R5663 (S) PERFUMES',
		in_started_by	=> 'Kate Rye',
		in_revenue		=> 88,
		in_started_date	=> DATE '2010-06-30',
		in_comments		=> NULL,
		in_batch_num	=> 1
	);

	--process the first ref
	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id		=> v_source_id_for_child, 
		in_reference			=> '100200300',
		out_processed_record_ids=> v_processed_record_ids_1,
		in_batch_num			=> 1
	);
	
	--process the second ref
	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id		=> v_source_id_for_child, 
		in_reference			=> '100200400',
		out_processed_record_ids=> v_processed_record_ids_2,
		in_batch_num			=> 1
	);
	
	--assert for the 1st ref
	BEGIN
		SELECT created_company_sid
		  INTO v_created_company_sid_1
		  FROM dedupe_processed_record
		 WHERE reference = '100200300'
		   AND batch_num = 1
		   AND dedupe_staging_link_id = v_staging_link_id_2_1
		   AND iteration_num = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected chain company to have been created');
	END;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM company_reference
	 WHERE company_sid = v_created_company_sid_1
	   AND reference_id = v_reference_company_id
	   AND value = '100200300';

	csr.unit_test_pkg.AssertAreEqual(v_count, 1, 'Wrong or no value for company reference field');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM company_reference
	 WHERE company_sid = v_created_company_sid_1
	   AND reference_id = v_reference_id_1
	   AND value = 'Hsw cmm';

	csr.unit_test_pkg.AssertAreEqual(v_count, 1, 'Wrong or no value for company reference field');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM company_reference
	 WHERE company_sid = v_created_company_sid_1
	   AND reference_id = v_reference_id_2
	   AND value = 'Hsw cmm 2';

	csr.unit_test_pkg.AssertAreEqual(v_count, 1, 'Wrong or no value for company reference field');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_processed_record
	 WHERE reference = '100200300'
	   AND dedupe_staging_link_id IN (v_staging_link_id_2_1, v_staging_link_id_2_2)
	   AND data_merged = 1
	   AND batch_num = 1
	 ORDER BY dedupe_processed_record_id;
	
	csr.unit_test_pkg.AssertAreEqual(3, v_count, 'Wrong number of processed records with merged values');

	SELECT cms_record_id
	  BULK COLLECT INTO v_cms_record_ids
	  FROM dedupe_processed_record
	 WHERE reference = '100200300'
	   AND dedupe_staging_link_id = v_staging_link_id_2_2
	   AND cms_record_id IS NOT NULL
	   AND data_merged = 1
	   AND batch_num = 1
	   AND matched_to_company_sid = v_created_company_sid_1
	   AND parent_processed_record_id = v_processed_record_ids_1(1)
	   AND iteration_num = 1
	 ORDER BY dedupe_processed_record_id;
	
	csr.unit_test_pkg.AssertAreEqual(2, v_cms_record_ids.COUNT,'Wrong number of created child records');

	BEGIN
		EXECUTE IMMEDIATE('
			SELECT sales_org_id, merch_cat_id,
				revenue, started_by_sid, start_date, comments, score_band_id
			  FROM rag.company_sales_org 
			 WHERE company_sid = :1
			   AND company_sales_org_id = :2
		')
		 INTO v_sales_org_id, v_merch_cat_id, v_revenue, 
		 v_started_by_sid, v_start_date, v_comments, v_score_band_id
		USING v_created_company_sid_1, v_cms_record_ids(1);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected a CMS company record with id:'|| v_cms_record_ids(1));
	END;
	
	csr.unit_test_pkg.AssertAreEqual(6, v_sales_org_id, 'Saved value for sales_org_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(3, v_merch_cat_id, 'Saved value for merch_cat_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(99, v_revenue, 'Saved value for revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_user_sid_1, v_started_by_sid, 'Saved value for started_by_sid is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(DATE '2012-1-12', v_start_date, 'Saved value for start_date is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_comment_batch_1, v_comments, 'Saved value for comments is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(2, v_score_band_id, 'Saved value for SCORE_BAND_ID is not the expected one');

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(1))
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'MERCH_CAT_ID')
	   AND old_val IS NULL
	   AND new_val = to_char(3)
	   AND error_message IS NULL
	   AND lower(new_raw_val) = 'r5663 (s) perfumes';
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for MERCH_CAT_ID');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(1))
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'SCORE_BAND_ID')
	   AND old_val IS NULL
	   AND new_val = to_char(2)
	   AND error_message IS NULL
	   AND lower(new_raw_val) = 'amber';
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log data for SCORE_BAND_ID');
	
	--assert for the 2nd ref
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_processed_record
	 WHERE reference = '100200400'
	   AND dedupe_staging_link_id IN (v_staging_link_id_2_1, v_staging_link_id_2_2)
	   AND data_merged = 1
	   AND batch_num = 1
	 ORDER BY dedupe_processed_record_id;
	
	csr.unit_test_pkg.AssertAreEqual(2, v_count, 'Wrong number of processed records with merged values');

	BEGIN
		SELECT created_company_sid
		  INTO v_created_company_sid_2
		  FROM dedupe_processed_record
		 WHERE reference = '100200400'
		   AND batch_num = 1
		   AND dedupe_processed_record_id = v_processed_record_ids_2(1)
		   AND dedupe_staging_link_id = v_staging_link_id_2_1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected chain company to have been created');
	END;
	
	SELECT cms_record_id
	  BULK COLLECT INTO v_cms_record_ids
	  FROM dedupe_processed_record
	 WHERE reference = '100200400'
	   AND dedupe_staging_link_id = v_staging_link_id_2_2
	   AND cms_record_id IS NOT NULL
	   AND data_merged = 1
	   AND batch_num = 1
	 ORDER BY dedupe_processed_record_id;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_cms_record_ids.COUNT, 'Wrong number of created child records');
	
	BEGIN
		EXECUTE IMMEDIATE('
			SELECT sales_org_id, merch_cat_id,
				revenue, started_by_sid, start_date, comments
			  FROM rag.company_sales_org 
			 WHERE company_sid = :1
		')
		 INTO v_sales_org_id, v_merch_cat_id, v_revenue, 
		 v_started_by_sid, v_start_date, v_comments
		USING v_created_company_sid_2;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected exactly one CMS company record for the second ref: 100200400');
		WHEN TOO_MANY_ROWS THEN
			csr.unit_test_pkg.TestFail('Expected exactly one CMS company record for the second ref: 100200400');
	END;
	
	csr.unit_test_pkg.AssertAreEqual(2, v_sales_org_id, 'Saved value for sales_org_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(3, v_merch_cat_id, 'Saved value for merch_cat_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(88, v_revenue, 'Saved value for revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_user_sid_1, v_started_by_sid, 'Saved value for started_by_sid is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(DATE '2010-06-30', v_start_date, 'Saved value for start_date is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(NULL, v_comments, 'Saved value for comments is not the expected one');
	
	--add a new child cms record for the second ref
	AddChildStagingRow(
		in_company_id	=> '100200300',
		in_sales_org	=> 'E-Commerce',
		in_merch_cat	=> 'R5440 APPLES/PEARS',
		in_started_by	=> 'Kate Rye',
		in_revenue		=> 80000,
		in_started_date	=> DATE '2015-1-12',
		in_comments		=> 'new cms record',
		in_batch_num	=> 1
	);
	
	--force a re-eval. We expect the parent record to have been matched to an existing company_sid
	--and a new child record to have been created
	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id		=> v_source_id_for_child, 
		in_reference			=> '100200300',
		out_processed_record_ids=> v_processed_record_ids_1,
		in_batch_num			=> 1,
		in_force_re_eval		=> 1
	);
	
	SELECT matched_to_company_sid
	  INTO v_matched_to_company_sid
	  FROM dedupe_processed_record
	 WHERE reference = '100200300'
	   AND dedupe_staging_link_id IN (v_staging_link_id_2_1)
	   AND data_merged = 0
	   AND batch_num = 1
	   AND iteration_num = 2
	 ORDER BY dedupe_processed_record_id;
	
	csr.unit_test_pkg.AssertAreEqual(v_created_company_sid_1, v_matched_to_company_sid, 'Expected 1 exact match');

	--only 1 record was merged...
	SELECT cms_record_id
	  BULK COLLECT INTO v_cms_record_ids
	  FROM dedupe_processed_record
	 WHERE reference = '100200300'
	   AND dedupe_staging_link_id IN (v_staging_link_id_2_2)
	   AND data_merged = 1
	   AND batch_num = 1
	   AND iteration_num = 2
	   AND matched_to_company_sid = v_matched_to_company_sid
	   AND parent_processed_record_id = v_processed_record_ids_1(1)
	 ORDER BY dedupe_processed_record_id;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_cms_record_ids.count, 'Not the expected count for the merged child processed record of the new iteration');
	
	--...but all 3 record were processed
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_processed_record
	 WHERE reference = '100200300'
	   AND dedupe_staging_link_id IN (v_staging_link_id_2_2)
	   AND batch_num = 1
	   AND iteration_num = 2
	   AND cms_record_id IS NOT NULL
	   AND matched_to_company_sid = v_matched_to_company_sid
	   AND parent_processed_record_id = v_processed_record_ids_1(1)
	 ORDER BY dedupe_processed_record_id;
	
	csr.unit_test_pkg.AssertAreEqual(3, v_count, 'Not the expected count for the child processed record of the new iteration');
	
	EXECUTE IMMEDIATE('
		SELECT COUNT(*)
		  FROM rag.company_sales_org 
		 WHERE company_sid = :1
	')
	 INTO v_count
	USING v_created_company_sid_1;
	
	csr.unit_test_pkg.AssertAreEqual(3, v_count, 'Wrong total count of child cms records of the new iteration');
	
	BEGIN
		EXECUTE IMMEDIATE('
			SELECT sales_org_id, merch_cat_id,
				revenue, started_by_sid, start_date, comments
			  FROM rag.company_sales_org 
			 WHERE company_sid = :1 AND company_sales_org_id=:2
		')
		 INTO v_sales_org_id, v_merch_cat_id, v_revenue, 
		 v_started_by_sid, v_start_date, v_comments
		USING v_created_company_sid_1, v_cms_record_ids(1);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected exactly one CMS company record');
		WHEN TOO_MANY_ROWS THEN
			csr.unit_test_pkg.TestFail('Expected exactly one CMS company record');
	END;
	
	csr.unit_test_pkg.AssertAreEqual(5, v_sales_org_id, 'Saved value for sales_org_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(5, v_merch_cat_id, 'Saved value for merch_cat_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(80000, v_revenue, 'Saved value for revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual('new cms record', v_comments, 'Saved value for comments is not the expected one');
	
	---------------------------
	--now add a second batch 
	
	AddStaging3Row(
		in_company_id	=> '100200300',
		in_name			=> 'Best commerce company',
		in_country		=> 'it',
		in_ref_1		=> 'Hsw cmm',
		in_ref_2		=> 'Hsw cmm 2',
		in_batch_num	=> 2
	);
	
	AddStaging3Row(
		in_company_id	=> '100200400',
		in_name			=> 'Even better commerce company',
		in_country		=> 'es',
		in_ref_1		=> 'Hsw cmm 400',
		in_ref_2		=> 'Hsw cmm 400',
		in_batch_num	=> 2
	);
	
	--existing cms record NOT expected to be updated=> not merged
	AddChildStagingRow(
		in_company_id	=> '100200300',
		in_sales_org	=> 'Carl''s Jr.',
		in_merch_cat	=> 'R5663 (S) PERFUMES',
		in_started_by	=> 'Kate Rye',
		in_revenue		=> 99,
		in_started_date	=> DATE '2012-1-12',
		in_comments		=> v_comment_batch_2,
		in_batch_num	=> 2
	);
	
	--new child cms record expected to be created
	AddChildStagingRow(
		in_company_id	=> '100200300',
		in_sales_org	=> 'E-Commerce',
		in_merch_cat	=> 'R5707 (S) YOUNG SHOP MEN TOPS',
		in_started_by	=> 'Kate Rye',
		in_revenue		=> 80000,
		in_started_date	=> DATE '2015-1-12',
		in_comments		=> 'new cms record',
		in_batch_num	=> 2
	);
	
	--process the second batch of the first ref
	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id		=> v_source_id_for_child, 
		in_reference			=> '100200300',
		out_processed_record_ids=> v_processed_record_ids_1,
		in_batch_num			=> 2
	);
	
	--no merge for the parent
	SELECT matched_to_company_sid
	  INTO v_matched_to_company_sid
	  FROM dedupe_processed_record
	 WHERE reference = '100200300'
	   AND dedupe_staging_link_id IN (v_staging_link_id_2_1)
	   AND data_merged = 0
	   AND batch_num = 2
	   AND iteration_num = 1
	 ORDER BY dedupe_processed_record_id;
	
	csr.unit_test_pkg.AssertAreEqual(v_created_company_sid_1, v_matched_to_company_sid, 'Expected 1 exact match');

	SELECT cms_record_id
	  BULK COLLECT INTO v_cms_record_ids
	  FROM dedupe_processed_record
	 WHERE reference = '100200300'
	   AND dedupe_staging_link_id IN (v_staging_link_id_2_2)
	   AND data_merged = 1
	   AND batch_num = 2
	   AND iteration_num = 1
	   AND parent_processed_record_id = v_processed_record_ids_1(1)
	   AND matched_to_company_sid = v_matched_to_company_sid
	 ORDER BY dedupe_processed_record_id;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_cms_record_ids.count, 'Not the expected count for the merged child processed record');
	
	BEGIN
		EXECUTE IMMEDIATE('
			SELECT sales_org_id, merch_cat_id,
				revenue, started_by_sid, start_date, comments
			  FROM rag.company_sales_org 
			 WHERE company_sales_org_id = :1
		')
		 INTO v_sales_org_id, v_merch_cat_id, v_revenue, 
		 v_started_by_sid, v_start_date, v_comments
		USING v_cms_record_ids(1);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected exactly one CMS company record');
		WHEN TOO_MANY_ROWS THEN
			csr.unit_test_pkg.TestFail('Expected exactly one CMS company record');
	END;
	
	csr.unit_test_pkg.AssertAreEqual(5, v_sales_org_id, 'Saved value for sales_org_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(4, v_merch_cat_id, 'Saved value for merch_cat_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(80000, v_revenue, 'Saved value for revenue is not the expected one.'); 
	csr.unit_test_pkg.AssertAreEqual('new cms record', v_comments, 'Saved value for comments is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_expected_user_sid_1, v_started_by_sid, 'Saved value for started_by_sid is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(DATE '2015-1-12', v_start_date, 'Saved value for start_date is not the expected one');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(1)
			   AND batch_num = 2
			)	
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'COMMENTS')
	   AND old_val IS NULL
	   AND new_val = 'new cms record'
	   AND error_message IS NULL;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log value for COMMENTS');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(1)
			   AND batch_num = 2
			)	
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'REVENUE')
	   AND old_val IS NULL
	   AND current_desc_val IS NULL
	   AND new_val = TO_CHAR(80000)
	   AND new_raw_val = TO_CHAR(80000)
	   AND error_message IS NULL;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log value for REVENUE');
		
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(1)
			   AND batch_num = 2
			)	
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'SALES_ORG_ID')
	   AND old_val IS NULL
	   AND new_val = TO_CHAR(5)
	   AND lower(new_raw_val) = lower('E-Commerce')
	   AND error_message IS NULL;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log value for SALES_ORG_ID');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(1)
			   AND batch_num = 2
			)	
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'STARTED_BY_SID')
	   AND old_val IS NULL
	   AND new_val = TO_CHAR(v_expected_user_sid_1)
	   AND lower(new_raw_val) = lower('Kate Rye')
	   AND error_message IS NULL;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log value for STARTED_BY_SID');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(1)
			   AND batch_num = 2
			)	
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'START_DATE')
	   AND old_val IS NULL
	   AND current_desc_val IS NULL
	   AND new_val IS NOT NULL
	   AND new_raw_val IS NULL
	   AND error_message IS NULL;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log value for START_DATE');
	
	--///////////////////////////////////////////
	--now let's try an update on a child record
	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;
	
	--we need a 3rd batch for the parent record first
	AddStaging3Row(
		in_company_id	=> '100200300',
		in_name			=> 'Best commerce company',
		in_country		=> 'it',
		in_ref_1		=> 'Hsw cmm',
		in_ref_2		=> 'Hsw cmm 2',
		in_batch_num	=> 3
	);
	
	AddChildStagingRow(
		in_company_id	=> '100200300',
		in_sales_org	=> 'E-Commerce',
		in_merch_cat	=> 'R5707 (S) YOUNG SHOP MEN TOPS',
		in_started_by	=> 'Random non Pearson', --update to a user that doesnt exist
		in_revenue		=> NULL, --revenue cleared
		in_started_date	=> DATE '1999-1-12', --date updated
		in_comments		=> 'updated comments on an existing record',
		in_batch_num	=> 3
	);
	
	--process the third batch of the first ref
	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id		=> v_source_id_for_child, 
		in_reference			=> '100200300',
		out_processed_record_ids=> v_processed_record_ids_1,
		in_batch_num			=> 3
	);

	SELECT cms_record_id
	  BULK COLLECT INTO v_cms_record_ids
	  FROM dedupe_processed_record
	 WHERE reference = '100200300'
	   AND dedupe_staging_link_id IN (v_staging_link_id_2_2)
	   AND data_merged = 1
	   AND batch_num = 3
	   AND iteration_num = 1
	   AND cms_record_id IS NOT NULL
	   AND parent_processed_record_id = v_processed_record_ids_1(1)
	   AND matched_to_company_sid = test_chain_utils_pkg.GetChainCompanySid('Best commerce company', 'it')
	 ORDER BY dedupe_processed_record_id;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_cms_record_ids.count, 'Expected 1 merged child record');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(1)
			   AND batch_num = 3
			)	
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'STARTED_BY_SID')
	   AND old_val IS NULL --we dont log the existing value on error as this is going to be persisted anyway when the parse fails
	   AND current_desc_val IS NULL
	   AND new_val IS NULL
	   AND lower(new_raw_val) = lower('Random non Pearson')
	   AND error_message IS NOT NULL;
	   
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log value for STARTED_BY_SID');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(1)
			   AND batch_num = 3
			)	
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'REVENUE');
		   
	csr.unit_test_pkg.AssertAreEqual(0, v_count, 'Wrong merge log value for REVENUE. We dont clear values hence we dont log blank values');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(1)
			   AND batch_num = 3
			)	
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'COMMENTS')
	   AND old_val = 'new cms record'
	   AND current_desc_val IS NULL
	   AND new_val = 'updated comments on an existing record'
	   AND lower(new_raw_val) = lower('updated comments on an existing record')
	   AND error_message IS NULL;
	   
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log value for COMMENTS');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(1)
			   AND batch_num = 3
			)	
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'START_DATE')
	   AND old_val <> new_val
	   AND new_raw_val IS NULL
	   AND current_desc_val IS NULL
	   AND error_message IS NULL;
	   
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log value for START_DATE');
	   
	BEGIN
		EXECUTE IMMEDIATE('
			SELECT sales_org_id, merch_cat_id,
				revenue, started_by_sid, start_date, comments
			  FROM rag.company_sales_org 
			 WHERE company_sales_org_id = :1
		')
		 INTO v_sales_org_id, v_merch_cat_id, v_revenue, 
		 v_started_by_sid, v_start_date, v_comments
		USING v_cms_record_ids(1);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected exactly one CMS company record');
		WHEN TOO_MANY_ROWS THEN
			csr.unit_test_pkg.TestFail('Expected exactly one CMS company record');
	END;
	
	csr.unit_test_pkg.AssertAreEqual(5, v_sales_org_id, 'Saved value for sales_org_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(4, v_merch_cat_id, 'Saved value for merch_cat_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(80000, v_revenue, 'Saved value for revenue is not the expected one.'); --no change as we dont clear values
	csr.unit_test_pkg.AssertAreEqual(v_expected_user_sid_1, v_started_by_sid, 'Saved value for started_by_sid is not the expected one');--no change as new user value cannot be matched
	csr.unit_test_pkg.AssertAreEqual('updated comments on an existing record', lower(v_comments), 'Saved value for comments is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(DATE '1999-1-12', v_start_date, 'Saved value for start_date is not the expected one');


	--///////////////////////////////////////////
	--Try an update on 2 child records
	
	--we need a 4th batch for the parent record first
	AddStaging3Row(
		in_company_id	=> '100200300',
		in_name			=> 'Best commerce company',
		in_country		=> 'fr',--updated
		in_ref_1		=> 'Hsw cmm',
		in_ref_2		=> 'Hsw cmm 2 (updated)',
		in_ref_3		=> 'Hsw cmm 3 (new)',
		in_batch_num	=> 4
	);
	
	AddChildStagingRow(
		in_company_id	=> '100200300',
		in_sales_org	=> 'E-Commerce',
		in_merch_cat	=> 'R5707 (S) YOUNG SHOP MEN TOPS',
		in_started_by	=> 'Random Pearson', --updated
		in_revenue		=> 90000, --revenue updated
		in_started_date	=> NULL,
		in_comments		=> 'SeCoNd update on comments on an existing record',
		in_batch_num	=> 4
	);
	
	AddChildStagingRow(
		in_company_id	=> '100200300',
		in_sales_org	=> 'Carl''s Jr.',
		in_merch_cat	=> 'R5663 (S) PERFUMES',
		in_started_by	=> 'Kate Rye',
		in_revenue		=> 100.01, --updated
		in_started_date	=> DATE '2012-1-12',
		in_comments		=> NULL, --cleared but the existing value should be maintained
		in_batch_num	=> 4,
		in_deleted		=> 1, --added
		in_band_label	=> 'Green'--updated
	);
	
	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id		=> v_source_id_for_child, 
		in_reference			=> '100200300',
		out_processed_record_ids=> v_processed_record_ids_1,
		in_batch_num			=> 4
	);
	
	csr.unit_test_pkg.AssertAreEqual(3, v_processed_record_ids_1.count, 'Expected 3 processed records in total (1 parent and 2 child recs)');
	
	SELECT cms_record_id
	  BULK COLLECT INTO v_cms_record_ids
	  FROM dedupe_processed_record
	 WHERE reference = '100200300'
	   AND dedupe_staging_link_id IN (v_staging_link_id_2_2)
	   AND data_merged = 1
	   AND batch_num = 4
	   AND iteration_num = 1
	   AND cms_record_id IS NOT NULL
	   AND parent_processed_record_id = v_processed_record_ids_1(1)
	   AND matched_to_company_sid = test_chain_utils_pkg.GetChainCompanySid('Best commerce company', 'fr') --country has changed
	 ORDER BY dedupe_processed_record_id;
	
	csr.unit_test_pkg.AssertAreEqual(2, v_cms_record_ids.count, 'Expected 2 merged child records');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(1)
			   AND batch_num = 4
			)	
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'STARTED_BY_SID')
	   AND old_val = to_char(v_expected_user_sid_1)
	   AND lower(current_desc_val) = lower('Kate Rye')
	   AND new_val = to_char(v_expected_user_sid_2)
	   AND lower(new_raw_val) = lower('Random Pearson')
	   AND error_message IS NULL;
	   
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log value for STARTED_BY_SID');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(1)
			   AND batch_num = 4
			)	
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'REVENUE')
	   AND old_val = to_char(80000)
	   AND current_desc_val IS NULL
	   AND new_val = to_char(90000)
	   AND new_raw_val = to_char(90000)
	   AND error_message IS NULL;
	   
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log value for REVENUE');
	
	BEGIN
		EXECUTE IMMEDIATE('
			SELECT sales_org_id, merch_cat_id,
				revenue, started_by_sid, start_date, comments
			  FROM rag.company_sales_org 
			 WHERE company_sales_org_id = :1
		')
		 INTO v_sales_org_id, v_merch_cat_id, v_revenue, 
		 v_started_by_sid, v_start_date, v_comments
		USING v_cms_record_ids(1);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected exactly one CMS company record');
		WHEN TOO_MANY_ROWS THEN
			csr.unit_test_pkg.TestFail('Expected exactly one CMS company record');
	END;
	
	csr.unit_test_pkg.AssertAreEqual(5, v_sales_org_id, 'Saved value for sales_org_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(4, v_merch_cat_id, 'Saved value for merch_cat_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(90000, v_revenue, 'Saved value for revenue is not the expected one.'); --updated
	csr.unit_test_pkg.AssertAreEqual(v_expected_user_sid_2, v_started_by_sid, 'Saved value for started_by_sid is not the expected one');--updated
	csr.unit_test_pkg.AssertAreEqual('SeCoNd update on comments on an existing record', v_comments, 'Saved value for comments is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(DATE '1999-1-12', v_start_date, 'Saved value for start_date is not the expected one'); --although was blank in staging we dont clear it

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(2)
			   AND batch_num = 4
			)	
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'REVENUE')
	   AND old_val = to_char(99)
	   AND current_desc_val IS NULL
	   AND new_val = to_char(100.01)
	   AND new_raw_val = to_char(100.01)
	   AND error_message IS NULL;
	   
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log value for REVENUE');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(2)
			   AND batch_num = 4
			)	
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'DELETED')
	   AND old_val IS NULL
	   AND current_desc_val IS NULL
	   AND new_val = to_char(1)
	   AND new_raw_val = to_char(1)
	   AND error_message IS NULL;
	   
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log value for DELETED');
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = (
			SELECT dedupe_processed_record_id
			  FROM dedupe_processed_record
			 WHERE cms_record_id = v_cms_record_ids(2)
			   AND batch_num = 4
			)	
	   AND destination_col_sid = cms.tab_pkg.GetColumnSid(v_destination_tab_sid_2, 'SCORE_BAND_ID')
	   AND old_val = to_char(2)
	   AND current_desc_val = 'Amber'
	   AND new_val = to_char(1)
	   AND new_raw_val = 'Green'
	   AND new_translated_val IS NULL
	   AND error_message IS NULL;
	   
	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong merge log value for SCORE_BAND_ID');
	
	BEGIN
		EXECUTE IMMEDIATE('
			SELECT sales_org_id, merch_cat_id,
				revenue, started_by_sid, start_date, comments, score_band_id, deleted
			  FROM rag.company_sales_org 
			 WHERE company_sales_org_id = :1
		')
		 INTO v_sales_org_id, v_merch_cat_id, v_revenue, 
		 v_started_by_sid, v_start_date, v_comments, v_score_band_id, v_deleted
		USING v_cms_record_ids(2);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected exactly one CMS company record');
		WHEN TOO_MANY_ROWS THEN
			csr.unit_test_pkg.TestFail('Expected exactly one CMS company record');
	END;
	
	csr.unit_test_pkg.AssertAreEqual(3, v_merch_cat_id, 'Saved value for merch_cat_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(100.01, v_revenue, 'Saved value for revenue is not the expected one.'); --updated
	csr.unit_test_pkg.AssertAreEqual(v_comment_batch_1, v_comments, 'Saved value for comments is not the expected one.'); --kept the old comments
	csr.unit_test_pkg.AssertAreEqual(1, v_deleted, 'Saved value for DELETED is not the expected one.'); --added
	csr.unit_test_pkg.AssertAreEqual(1, v_score_band_id, 'Saved value for SCORE_BAND_ID is not the expected one.'); --updated
END;

PROCEDURE Test_ChildCmsDataUpdate
AS
	v_company_type_id			NUMBER;
	v_company_sid				NUMBER;
	v_matched_to_company_sid 	NUMBER;
	v_processed_record_ids_1	security_pkg.T_SID_IDS;
	v_sales_org_id				NUMBER;
	v_merch_cat_id				NUMBER;
	v_revenue 					NUMBER;
	v_started_by_sid			NUMBER;
	v_start_date				DATE;
	v_comments					VARCHAR2(4000);
	v_cms_record_ids			security.security_pkg.T_SID_IDS;
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	SetUpConfig3;

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name						=> 'Mervins Mackintoshes',
		in_country_code				=> 'gb',
		in_company_type_id			=> v_company_type_id,
		in_sector_id				=> NULL,
		out_company_sid				=> v_company_sid
	);
	INSERT INTO company_reference (company_sid, value, reference_id, company_reference_id)
		VALUES(v_company_sid, '100200300', v_reference_company_id, company_reference_id_seq.nextval);

	v_sales_org_id := 2;
	v_merch_cat_id := 1;
	v_start_date := SYSDATE;
	v_revenue := 100.5;
	v_started_by_sid := v_expected_user_sid_1;
	v_comments := 'Updated child cms row';

	AddStaging3Row(
		in_company_id	=> '100200300',
		in_name			=> 'Mervins Mackintoshes',
		in_country		=> 'gb',
		in_ref_1		=> 'mm',
		in_ref_2		=> 'mm2'
	);
	
	AddChildStagingRow(
		in_company_id	=> '100200300',
		in_sales_org	=> 'f'||unistr('\00F8')||'tex FOOD',
		in_merch_cat	=> 'R5726 (S) LADIES coats',
		in_started_by	=> v_started_by_sid,
		in_revenue		=> v_revenue,
		in_started_date	=> v_start_date,
		in_comments		=> v_comments
	);

	v_comments := 'Nothing interesting to comment';

	AddCmsChildRow(
		in_company_sid 	 	=> v_company_sid,
		in_sales_org_id  	=> v_sales_org_id,
		in_merch_cat_id  	=> v_merch_cat_id,
		in_revenue 		 	=> v_revenue,
		in_started_by_sid 	=> v_started_by_sid,
		in_start_date 	 	=> v_start_date,
		in_comments 	 	=> v_comments
	);

	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;
	 
	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id		=> v_source_id_for_child,
		in_reference			=> '100200300',
		out_processed_record_ids=> v_processed_record_ids_1,
		in_batch_num			=> NULL
	);
	
	SELECT matched_to_company_sid
	  INTO v_matched_to_company_sid
	  FROM dedupe_processed_record
	 WHERE reference = '100200300'
	   AND dedupe_staging_link_id IN (v_staging_link_id_3_1)
	   AND data_merged = 1
	   AND batch_num IS NULL
	   AND parent_processed_record_id IS NULL
	   AND dedupe_processed_record_id = v_processed_record_ids_1(1)
	 ORDER BY dedupe_processed_record_id;

	csr.unit_test_pkg.AssertAreEqual(v_company_sid, v_matched_to_company_sid, 'Wrong merge data for the parent record');
	 
	SELECT cms_record_id
	  BULK COLLECT INTO v_cms_record_ids
	  FROM dedupe_processed_record
	 WHERE reference = '100200300'
	   AND dedupe_staging_link_id = v_staging_link_id_3_2
	   AND cms_record_id IS NOT NULL
	   AND data_merged = 1
	   AND batch_num IS NULL
	   AND parent_processed_record_id = v_processed_record_ids_1(1)
	   AND dedupe_processed_record_id = v_processed_record_ids_1(2)
	   AND matched_to_company_sid = v_matched_to_company_sid
	 ORDER BY dedupe_processed_record_id;
	
	csr.unit_test_pkg.AssertAreEqual(1, v_cms_record_ids.count, 'Wrong merge data for the child record');
	
	BEGIN
		EXECUTE IMMEDIATE('
			SELECT sales_org_id, merch_cat_id,
				revenue, started_by_sid, start_date, comments
			  FROM rag.company_sales_org 
			 WHERE company_sales_org_id = :1
		')
		 INTO v_sales_org_id, v_merch_cat_id, v_revenue, 
		 v_started_by_sid, v_start_date, v_comments
		USING v_cms_record_ids(1);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected a CMS company record with id:'|| v_cms_record_ids(1));
	END;

	csr.unit_test_pkg.AssertAreEqual('Updated child cms row', v_comments, 'Saved value for COMMENTS is not the expected one');
END;

PROCEDURE Test_CmsDataAnotherCmpnyCreate
AS
	v_created_company_sid		NUMBER;
	v_processed_record_ids		security_pkg.T_SID_IDS;
	v_revenue 					NUMBER;
	v_reporting_year			NUMBER;
	v_another_company_sid		NUMBER;
	v_cms_record_ids			security.security_pkg.T_SID_IDS;
BEGIN
	SetUpConfig4;

	--expect to process both the parent and child staging records
	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id		=> v_source_id_for_child, 
		in_reference			=> '12345',
		out_processed_record_ids=> v_processed_record_ids
	);

	BEGIN
		SELECT created_company_sid
		  INTO v_created_company_sid
		  FROM dedupe_processed_record
		 WHERE reference = '12345'
		   AND dedupe_staging_link_id = v_staging_link_id_4_1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected chain company to have been created');
	END;

	SELECT cms_record_id
	  BULK COLLECT INTO v_cms_record_ids
	  FROM dedupe_processed_record
	 WHERE parent_processed_record_id = v_processed_record_ids(1)
	   AND cms_record_id IS NOT NULL
	   AND data_merged = 1
	   AND batch_num IS NULL
	 ORDER BY dedupe_processed_record_id;
	
	csr.unit_test_pkg.AssertAreEqual(2, v_cms_record_ids.COUNT,'Wrong number of created child records');
	
	BEGIN
		EXECUTE IMMEDIATE('
			SELECT reporting_year,
				   revenue, another_company_sid
			  FROM rag.company_data_4
			 WHERE company_sid = :1
			   AND company_data_id = :2
		')
		 INTO v_reporting_year,
			  v_revenue, v_another_company_sid
		USING v_created_company_sid, v_cms_record_ids(1);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected a CMS company record with id:'|| v_cms_record_ids(1));
	END;
	
	csr.unit_test_pkg.AssertAreEqual(2014, v_reporting_year, 'Saved value for reporting_year is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(10000000, v_revenue, 'Saved value for revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_another_company_sid_1, v_another_company_sid, 'Saved value for another_company_id is not the expected one');

	BEGIN
		EXECUTE IMMEDIATE('
			SELECT reporting_year,
				   revenue, another_company_sid
			  FROM rag.company_data_4
			 WHERE company_sid = :1
			   AND company_data_id = :2
		')
		 INTO v_reporting_year,
			  v_revenue, v_another_company_sid
		USING v_created_company_sid, v_cms_record_ids(2);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected a CMS company record with id:'|| v_cms_record_ids(2));
	END;
	
	csr.unit_test_pkg.AssertAreEqual(2015, v_reporting_year, 'Saved value for reporting_year is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(5000000, v_revenue, 'Saved value for revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_another_company_sid_2, v_another_company_sid, 'Saved value for another_company_id is not the expected one');
END;

-- used by Test_CmsDataAnotherCmpnyUpdate and Test_TwoCmsChildTab as they have some common results and overlap - but in different setup scenarios
PROCEDURE Check_CompanyData4Table(
	in_matched_to_company_sid	NUMBER,
	in_cms_record_ids			security.security_pkg.T_SID_IDS
)
AS
	v_revenue 					NUMBER;
	v_reporting_year			NUMBER;
	v_another_company_sid		NUMBER;
BEGIN
	
	BEGIN
		EXECUTE IMMEDIATE('
			SELECT reporting_year,
				   revenue, another_company_sid
			  FROM rag.company_data_4
			 WHERE company_sid = :1
			   AND company_data_id = :2
		')
		 INTO v_reporting_year,
			  v_revenue, v_another_company_sid
		USING in_matched_to_company_sid, in_cms_record_ids(1);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected a CMS company record with id:'|| in_cms_record_ids(1));
	END;
	
	csr.unit_test_pkg.AssertAreEqual(2016, v_reporting_year, 'Saved value for reporting_year is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(100000, v_revenue, 'Saved value for revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_another_company_sid_3, v_another_company_sid, 'Saved value for another_company_id is not the expected one');

	BEGIN
		EXECUTE IMMEDIATE('
			SELECT reporting_year,
				   revenue, another_company_sid
			  FROM rag.company_data_4
			 WHERE company_sid = :1
			   AND company_data_id = :2
		')
		 INTO v_reporting_year,
			  v_revenue, v_another_company_sid
		USING in_matched_to_company_sid, in_cms_record_ids(2);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected a CMS company record with id:'|| in_cms_record_ids(2));
	END;
	
	csr.unit_test_pkg.AssertAreEqual(2017, v_reporting_year, 'Saved value for reporting_year is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(500000, v_revenue, 'Saved value for revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(v_another_company_sid_3, v_another_company_sid, 'Saved value for another_company_id is not the expected one');

END;

PROCEDURE Test_CmsDataAnotherCmpnyUpdate
AS
	v_matched_to_company_sid	NUMBER;
	v_processed_record_ids		security_pkg.T_SID_IDS;
	v_cms_record_ids			security.security_pkg.T_SID_IDS;
BEGIN

	SetUpConfig5;

	--expect to process both the parent and child staging records
	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id		=> v_source_id_for_child, 
		in_reference			=> '12345',
		out_processed_record_ids=> v_processed_record_ids
	);

	BEGIN
		SELECT matched_to_company_sid
		  INTO v_matched_to_company_sid
		  FROM dedupe_processed_record
		 WHERE reference = '12345'
		   AND dedupe_staging_link_id = v_staging_link_id_4_1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected chain company to have been created');
	END;
    
	SELECT cms_record_id
	  BULK COLLECT INTO v_cms_record_ids
	  FROM dedupe_processed_record
	 WHERE parent_processed_record_id = v_processed_record_ids(1)
	   AND cms_record_id IS NOT NULL
	   AND data_merged = 1
	   AND batch_num IS NULL
	 ORDER BY dedupe_processed_record_id;
	
	csr.unit_test_pkg.AssertAreEqual(2, v_cms_record_ids.COUNT,'Wrong number of created child records');
	
	Check_CompanyData4Table(v_matched_to_company_sid, v_cms_record_ids);
	
END;

PROCEDURE Test_TwoCmsChildTab
AS
	v_matched_to_company_sid	NUMBER;
	v_processed_record_ids		security_pkg.T_SID_IDS;
	v_sales_org_id 				NUMBER;
	v_merch_cat_id 				NUMBER;
	v_revenue 					NUMBER;
	v_reporting_year			NUMBER;
	v_date						DATE;
	v_comment					VARCHAR2(100);
	v_cms_record_ids			security.security_pkg.T_SID_IDS;
	v_cnt						NUMBER;
BEGIN

	SetUpConfig6;
	
	SELECT COUNT(*) 
	  INTO v_cnt
	  FROM dedupe_staging_link
	 WHERE import_source_id = v_source_id_for_child;
	csr.unit_test_pkg.AssertAreEqual(3, v_cnt, 'Wrong number of staging links created');

	--expect to process both the parent and child staging records
	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id		=> v_source_id_for_child, 
		in_reference			=> '12345',
		out_processed_record_ids=> v_processed_record_ids
	);
	
	BEGIN
		EXECUTE IMMEDIATE('
			SELECT COUNT(*)
			  FROM rag.company_data_4
		')
		 INTO v_cnt;
	END;
	csr.unit_test_pkg.AssertAreEqual(2, v_cnt, 'Expected 2 rows - 1 new 1 updated in rag.company_data_4');
	BEGIN
		EXECUTE IMMEDIATE('
			SELECT COUNT(*)
			  FROM rag.company_sales_org
		')
		 INTO v_cnt;
	END;
	csr.unit_test_pkg.AssertAreEqual(2, v_cnt, 'Expected 2 rows - 1 new 1 updated in rag.company_sales_org');

	BEGIN
		SELECT matched_to_company_sid
		  INTO v_matched_to_company_sid
		  FROM dedupe_processed_record
		 WHERE reference = '12345'
		   AND dedupe_staging_link_id = v_staging_link_id_6_1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected chain company to have been created');
	END;

	SELECT cms_record_id
	  BULK COLLECT INTO v_cms_record_ids
	  FROM dedupe_processed_record
	 WHERE parent_processed_record_id = v_processed_record_ids(1)
	   AND cms_record_id IS NOT NULL
	   AND data_merged = 1
	   AND batch_num IS NULL
	 ORDER BY dedupe_processed_record_id;
	csr.unit_test_pkg.AssertAreEqual(4, v_cms_record_ids.COUNT,'Wrong number of created child records');

	SELECT cms_record_id
	  BULK COLLECT INTO v_cms_record_ids
	  FROM dedupe_processed_record
	 WHERE parent_processed_record_id = v_processed_record_ids(1)
	   AND cms_record_id IS NOT NULL
	   AND data_merged = 1
	   AND batch_num IS NULL
	   AND dedupe_staging_link_id = v_staging_link_id_6_2
	 ORDER BY dedupe_processed_record_id;
	csr.unit_test_pkg.AssertAreEqual(2, v_cms_record_ids.COUNT,'Wrong number of created child records');
	
	Check_CompanyData4Table(v_matched_to_company_sid, v_cms_record_ids);
	
	SELECT cms_record_id
	  BULK COLLECT INTO v_cms_record_ids
	  FROM dedupe_processed_record
	 WHERE parent_processed_record_id = v_processed_record_ids(1)
	   AND cms_record_id IS NOT NULL
	   AND data_merged = 1
	   AND batch_num IS NULL
	   AND dedupe_staging_link_id = v_staging_link_id_6_3
	 ORDER BY dedupe_processed_record_id;
	csr.unit_test_pkg.AssertAreEqual(2, v_cms_record_ids.COUNT,'Wrong number of created child records');
	
	BEGIN
		EXECUTE IMMEDIATE('
			SELECT revenue, sales_org_id, merch_cat_id, start_date, comments
			  FROM rag.company_sales_org
			 WHERE company_sid = :1
			   AND company_sales_org_id = :2
		')
		 INTO v_revenue, v_sales_org_id, v_merch_cat_id, v_date, v_comment
		USING v_matched_to_company_sid, v_cms_record_ids(1);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected a CMS company record with id:'|| v_cms_record_ids(1));
	END;
	csr.unit_test_pkg.AssertAreEqual(3, v_sales_org_id, 'Saved value for sales_org_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(1, v_merch_cat_id, 'Saved value for merch_cat_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(1010, v_revenue, 'Saved value for revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(NULL, v_date, 'Saved value for start_date is not the expected one');
	csr.unit_test_pkg.AssertAreEqual('Exciting new range', v_comment, 'Saved value for comment is not the expected one');
		
	BEGIN
		EXECUTE IMMEDIATE('
			SELECT revenue, sales_org_id, merch_cat_id, start_date, comments
			  FROM rag.company_sales_org
			 WHERE company_sid = :1
			   AND company_sales_org_id = :2
		')
		 INTO v_revenue, v_sales_org_id, v_merch_cat_id, v_date, v_comment
		USING v_matched_to_company_sid, v_cms_record_ids(2);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected a CMS company record with id:'|| v_cms_record_ids(2));
	END;
	csr.unit_test_pkg.AssertAreEqual(5, v_sales_org_id, 'Saved value for sales_org_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(1, v_merch_cat_id, 'Saved value for merch_cat_id is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(990, v_revenue, 'Saved value for revenue is not the expected one');
	csr.unit_test_pkg.AssertAreEqual(DATE '2012-1-15', v_date, 'Saved value for start_date is not the expected one');
	csr.unit_test_pkg.AssertAreEqual('Thrilled to bits', v_comment, 'Saved value for comment is not the expected one');
	
END;

PROCEDURE Setup_MultipleCompSource
AS
	v_staging_parent_tab_sid	NUMBER;
	v_staging_child_tab_sid		NUMBER;
	v_destination_tab_sid		NUMBER;
	v_mapping_id				NUMBER;
	v_mapping_ids				security.security_pkg.T_SID_IDS;
	v_rule_ids					security.security_pkg.T_SID_IDS;
	v_dedupe_rule_set_id		NUMBER;
BEGIN
	v_staging_parent_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'CMS_COMPANY_STAGING_3');
	v_staging_child_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'TURNOVER_STAGING');
	v_destination_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'COMPANY_TURNOVER');

	dedupe_admin_pkg.SaveImportSource(
		in_import_source_id => -1, 
		in_name => 'Turnover data with multiple companies in unique key', 
		in_position => 1, 
		in_no_match_action_id => chain_pkg.AUTO_CREATE, 
		in_lookup_key => 'TURNOVER_DATA',
		out_import_source_id => v_source_id_for_turnover
	);

	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id_for_turnover,
		in_description 					=> 'Staging that holds company data',
		in_staging_tab_sid 				=> v_staging_parent_tab_sid,
		in_position 					=> 1,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_staging_parent_tab_sid, 'COMPANY_ID'),
		in_parent_staging_link_id 		=> NULL,
		in_destination_tab_sid 			=> NULL,
		in_staging_batch_num_col_sid	=> cms.tab_pkg.GetColumnSid(v_staging_parent_tab_sid, 'BATCH_NUM'),
		out_dedupe_staging_link_id 		=> v_staging_link_id_1_mult
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_1_mult, 
		in_tab_sid => v_staging_parent_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_parent_tab_sid, 'NAME'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_1_mult, 
		in_tab_sid => v_staging_parent_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_parent_tab_sid, 'COUNTRY'),
		in_dedupe_field_id => chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_1_mult, 
		in_tab_sid => v_staging_parent_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_parent_tab_sid, 'COMPANY_ID'),
		in_reference_id => v_reference_company_id,
		out_dedupe_mapping_id => v_mapping_ref_id
	);

	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id_for_turnover,
		in_description 					=> 'Staging that holds turnover data',
		in_staging_tab_sid 				=> v_staging_child_tab_sid,
		in_position 					=> 2,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_staging_child_tab_sid, 'SUPPLIER_ID'),
		in_parent_staging_link_id 		=> v_staging_link_id_1_mult,
		in_destination_tab_sid 			=> v_destination_tab_sid,
		in_staging_batch_num_col_sid	=> cms.tab_pkg.GetColumnSid(v_staging_child_tab_sid, 'BATCH_NUM'),
		out_dedupe_staging_link_id 		=> v_staging_link_id_2_mult
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_2_mult, 
		in_tab_sid => v_staging_child_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_child_tab_sid, 'M_COMPANY_SID'),
		in_destination_tab_sid	=> 	v_destination_tab_sid,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'M_COMPANY_SID'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_2_mult, 
		in_tab_sid => v_staging_child_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_child_tab_sid, 'MONTH_YEAR'),
		in_destination_tab_sid	=> 	v_destination_tab_sid,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'MONTH_YEAR'),
		out_dedupe_mapping_id => v_mapping_id
	);
	
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_2_mult, 
		in_tab_sid => v_staging_child_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_child_tab_sid, 'REVENUE'),
		in_destination_tab_sid	=> 	v_destination_tab_sid,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'REVENUE'),
		out_dedupe_mapping_id => v_mapping_id
	);
			
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1, 
		in_dedupe_staging_link_id => v_staging_link_id_2_mult, 
		in_tab_sid => v_staging_child_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_staging_child_tab_sid, 'ANOTHER_COMPANY_SID'),
		in_destination_tab_sid	=> 	v_destination_tab_sid,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'ANOTHER_COMPANY_SID'),
		out_dedupe_mapping_id => v_mapping_id
	);

	--Set rules
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_ref_id));
	  
	dedupe_admin_pkg.TestSaveRuleSetForExactMatches(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id_1_mult, 
		in_rule_set_position		=> 1,
		in_description				=> 'Reference matching rule set',
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);

	--lower ui source priority to allow updates
	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;
END;

PROCEDURE Setup_MultipleComp
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	SetupCompanyRefs2;
	Setup_MultipleCompSource;
END;

PROCEDURE Arrange_MultipleComp
AS
	v_staging_link_id_1			NUMBER;
	v_staging_link_id_2			NUMBER;
	v_supplier_company_type_id 	NUMBER := company_type_pkg.GetCompanyTypeId('SUPPLIER');
	v_m_company_sid_1 			NUMBER;
	v_m_company_sid_2 			NUMBER;
BEGIN
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> 'M company 1',
		in_country_code			=> 'se',
		in_company_type_id		=> v_supplier_company_type_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_m_company_sid_1
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> 'M company 2',
		in_country_code			=> 'it',
		in_company_type_id		=> v_supplier_company_type_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_m_company_sid_2
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> 'Another Random 1 inc',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_supplier_company_type_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_another_company_sid_1
	);

	test_chain_utils_pkg.CreateCompanyHelper(
		in_name					=> 'Another Random 2 inc',
		in_country_code			=> 'gb',
		in_company_type_id		=> v_supplier_company_type_id,
		in_sector_id			=> NULL,
		out_company_sid			=> v_another_company_sid_2
	);

	AddStaging3Row(
		in_company_id	=> '100200300',
		in_name			=> 'Best commerce company',
		in_country		=> 'it',
		in_ref_1		=> 'Hsw cmm',
		in_ref_2		=> 'Hsw cmm 2',
		in_batch_num	=> 1
	);

	AddTurnoverStagingRow(
		in_supplier_id		=> '100200300',
		in_m_company_sid	=> v_m_company_sid_1,
		in_month_year		=> '022016',
		in_revenue			=> 100.5,
		in_another_company_sid	=> v_another_company_sid_1,
		in_batch_num		=> 1
	);

	AddTurnoverStagingRow(
		in_supplier_id		=> '100200300',
		in_m_company_sid	=> v_m_company_sid_2,
		in_month_year		=> '022016',
		in_revenue			=> 99,
		in_another_company_sid	=> v_another_company_sid_2,
		in_batch_num		=> 1
	);

	AddStaging3Row(
		in_company_id	=> '100200400',
		in_name			=> 'Company B',
		in_country		=> 'it',
		in_ref_1		=> 'CB',
		in_batch_num	=> 1
	);

	AddTurnoverStagingRow(
		in_supplier_id		=> '100200400',
		in_m_company_sid	=> v_m_company_sid_1,
		in_month_year		=> '022017',
		in_revenue			=> 99,
		in_another_company_sid	=> v_another_company_sid_2,
		in_batch_num		=> 1
	);
END;

PROCEDURE AssertRowCompanyTurnover(
	in_supplier_sid 		NUMBER,
	in_m_company_sid 		NUMBER,
	in_month_year	 		VARCHAR2,
	in_revenue		 		VARCHAR2,
	in_another_company_sid	NUMBER
)
AS
	v_count		NUMBER;
BEGIN
	EXECUTE IMMEDIATE('
		SELECT COUNT(*)
		  FROM rag.company_turnover 
		 WHERE supplier_sid = :1
		   AND m_company_sid = :2
		   AND month_year = :3
		   AND another_company_sid = :4
		   AND revenue = :5
	')
	 INTO v_count
	USING in_supplier_sid, in_m_company_sid, in_month_year, in_another_company_sid, in_revenue;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Expected row in the destination table not found');
END;

PROCEDURE Test_ChildCmsDataMultipleComp
AS
	v_processed_record_ids		security_pkg.T_SID_IDS;
	v_matched_company_sids		security_pkg.T_SID_IDS;
	v_created_company_sid		security_pkg.T_SID_ID;
	v_count						NUMBER;
BEGIN
	--set up config
	Setup_MultipleComp;

	--arrange data
	Arrange_MultipleComp;

	--act
	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id		=> v_staging_link_id_1_mult, 
		in_reference					=> '100200300',
		in_batch_num					=> 1,
		out_created_company_sid			=> v_created_company_sid,
		out_matched_company_sids		=> v_matched_company_sids,
		out_processed_record_ids		=> v_processed_record_ids
	);
	
	--assert
	IF v_matched_company_sids.COUNT <> 0 THEN
		csr.unit_test_pkg.TestFail('Expected 0 matches');
	END IF;

	IF v_created_company_sid IS NULL THEN
		csr.unit_test_pkg.TestFail('Expected a new company');
	END IF;

	AssertRowCompanyTurnover(
		in_supplier_sid 		=> v_created_company_sid,
		in_m_company_sid 		=> test_chain_utils_pkg.GetChainCompanySid('M company 1', 'se'),
		in_month_year	 		=> '022016',
		in_revenue		 		=> 100.5,
		in_another_company_sid	=> 	v_another_company_sid_1
	);
	
	AssertRowCompanyTurnover(
		in_supplier_sid 		=> v_created_company_sid,
		in_m_company_sid 		=> test_chain_utils_pkg.GetChainCompanySid('M company 2', 'it'),
		in_month_year	 		=> '022016',
		in_revenue		 		=> 99,
		in_another_company_sid	=> 	v_another_company_sid_2
	);

	--add a second version with 2 records in turnover staging (one for insert and one for update)
	AddStaging3Row(
		in_company_id	=> '100200300',
		in_name			=> 'Best commerce company',
		in_country		=> 'it',
		in_ref_1		=> 'Hsw cmm',
		in_ref_2		=> 'Hsw cmm 2',
		in_batch_num	=> 2
	);

	--for update
	AddTurnoverStagingRow(
		in_supplier_id		=> '100200300',
		in_m_company_sid	=>  test_chain_utils_pkg.GetChainCompanySid('M company 1', 'se'),
		in_month_year		=> '022016',
		in_revenue			=> 128.5, --changed
		in_another_company_sid	=> v_another_company_sid_2, --changed
		in_batch_num		=> 2
	);

	--for insert
	AddTurnoverStagingRow(
		in_supplier_id		=> '100200300',
		in_m_company_sid	=>  test_chain_utils_pkg.GetChainCompanySid('M company 1', 'se'),
		in_month_year		=> '022017',
		in_revenue			=> 92,
		in_another_company_sid	=> v_another_company_sid_2,
		in_batch_num		=> 2
	);

	test_chain_utils_pkg.ProcessParentStagingRecord(
		in_dedupe_staging_link_id		=> v_staging_link_id_1_mult, 
		in_reference					=> '100200300',
		in_batch_num					=> 2,
		out_created_company_sid			=> v_created_company_sid,
		out_matched_company_sids		=> v_matched_company_sids,
		out_processed_record_ids		=> v_processed_record_ids
	);

	IF v_matched_company_sids.COUNT <> 1 THEN
		csr.unit_test_pkg.TestFail('Expected 1 match');
	END IF;
	
	AssertRowCompanyTurnover(
	 	in_supplier_sid 		=> v_matched_company_sids(1),
	 	in_m_company_sid 		=> test_chain_utils_pkg.GetChainCompanySid('M company 1', 'se'),
	 	in_month_year	 		=> '022016',
	 	in_revenue		 		=> 128.5,
	 	in_another_company_sid	=> 	v_another_company_sid_2
	);

	AssertRowCompanyTurnover(
		in_supplier_sid 		=> v_matched_company_sids(1),
		in_m_company_sid 		=> test_chain_utils_pkg.GetChainCompanySid('M company 1', 'se'),
		in_month_year	 		=> '022017',
		in_revenue		 		=> 92,
		in_another_company_sid	=> 	v_another_company_sid_2
	);

END;

END;
/
