CREATE OR REPLACE PACKAGE BODY chain.test_chain_user_dedupe_pkg AS

v_site_name				VARCHAR2(200);
v_user_sid_1			NUMBER;
v_user_sid_2			NUMBER;
v_user_sid_3			NUMBER;
v_source_id				NUMBER;
v_co_staging_tab_sid		NUMBER;
v_user_staging_tab_sid		NUMBER;
v_staging_link_id_1		NUMBER;
v_staging_link_id_2		NUMBER;
v_staging_link_id_3 	NUMBER;
v_mapping_ref_id		NUMBER;
v_reference_company_id	NUMBER;
v_role_sid_1			NUMBER;
v_role_sid_2			NUMBER;
v_role_sid_3			NUMBER;
v_role_sid_na			NUMBER;


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
END;

PROCEDURE SetupSource1(
	in_use_batch_num_col	IN BOOLEAN DEFAULT TRUE
)
AS
	v_mapping_id			NUMBER;
	v_mapping_ids			security.security_pkg.T_SID_IDS;
	v_rule_ids				security.security_pkg.T_SID_IDS;
	v_dedupe_rule_set_id	NUMBER;
BEGIN
	v_co_staging_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'USER_COMPANY_STAGING');
	v_user_staging_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'USER_STAGING');

	dedupe_admin_pkg.SaveImportSource(
		in_import_source_id => -1,
		in_name => 'Company and users integration',
		in_position => 1,
		in_no_match_action_id => chain_pkg.AUTO_CREATE,
		in_lookup_key => 'RANDOM_INTEGRATION',
		out_import_source_id => v_source_id
	);

	--set up staging links
	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id,
		in_description 					=> 'Staging that holds company data',
		in_staging_tab_sid 				=> v_co_staging_tab_sid,
		in_position 					=> 1,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'COMPANY_ID'),
		in_parent_staging_link_id 		=> NULL,
		in_destination_tab_sid 			=> NULL,
		in_staging_batch_num_col_sid	=> CASE WHEN in_use_batch_num_col THEN cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'BATCH_NUM') ELSE NULL END,
		out_dedupe_staging_link_id 		=> v_staging_link_id_1
	);

	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id,
		in_description 					=> 'Staging that holds users data',
		in_staging_tab_sid 				=> v_user_staging_tab_sid,
		in_position 					=> 2,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'COMPANY_ID'),
		in_staging_batch_num_col_sid	=> CASE WHEN in_use_batch_num_col THEN cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'BATCH_NUM') ELSE NULL END,
		in_parent_staging_link_id 		=> v_staging_link_id_1,
		out_dedupe_staging_link_id 		=> v_staging_link_id_2
	);

	--mappings for company data
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_co_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_co_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'COUNTRY'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_co_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'COMPANY_ID'),
		in_reference_id => v_reference_company_id,
		out_dedupe_mapping_id => v_mapping_ref_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_co_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'ACTIVE'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_ACTIVE,
		out_dedupe_mapping_id => v_mapping_id
	);

	--mappings for users data
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'USER_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_USER_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'EMAIL'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_EMAIL,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'FULL_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_FULL_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'FIRST_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_FIRST_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'LAST_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_LAST_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'FRIENDLY_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_FRIENDLY_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'PHONE_NUM'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_PHONE_NUM,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'JOB'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_JOB_TITLE,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'CREATED_DTM'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_CREATED_DTM,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'USER_REF'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_REF,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'ACTIVE'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_ACTIVE,
		out_dedupe_mapping_id => v_mapping_id
	);

	--Set rules
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_ref_id));

	dedupe_admin_pkg.TestSaveRuleSetForExactMatches(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id_1,
		in_rule_set_position		=> 1,
		in_description				=> 'Ref rule set',
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);

	--Move UI system managed source to a lower priority so we can also merge data (it's moved back in the teardown)
	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;
END;

PROCEDURE SetupSource2(
	in_use_batch_num_col	IN BOOLEAN DEFAULT TRUE
)
AS
	v_co_staging_tab_sid		security_pkg.T_SID_ID;
	v_user_staging_tab_sid		security_pkg.T_SID_ID;
	v_cms_tab_sid				security_pkg.T_SID_ID;
	v_destination_tab_sid		security_pkg.T_SID_ID;
	v_mapping_id				NUMBER;
	v_mapping_ids				security.security_pkg.T_SID_IDS;
	v_rule_ids					security.security_pkg.T_SID_IDS;
	v_dedupe_rule_set_id		NUMBER;
BEGIN
	v_co_staging_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'USER_COMPANY_STAGING');
	v_user_staging_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'USER_STAGING');
	v_cms_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'CHILD_CMS_COMPANY_STAGING');
	v_destination_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'COMPANY_SALES_ORG');

	dedupe_admin_pkg.SaveImportSource(
		in_import_source_id => -1,
		in_name => 'Company users and child cms integration',
		in_position => 1,
		in_no_match_action_id => chain_pkg.AUTO_CREATE,
		in_lookup_key => 'MULTI_INTEGRATION',
		out_import_source_id => v_source_id
	);

	--set up staging links
	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id,
		in_description 					=> 'Staging that holds company data',
		in_staging_tab_sid 				=> v_co_staging_tab_sid,
		in_position 					=> 1,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'COMPANY_ID'),
		in_parent_staging_link_id 		=> NULL,
		in_destination_tab_sid 			=> NULL,
		in_staging_batch_num_col_sid	=> CASE WHEN in_use_batch_num_col THEN cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'BATCH_NUM') ELSE NULL END,
		out_dedupe_staging_link_id 		=> v_staging_link_id_1
	);

	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id,
		in_description 					=> 'Staging that holds user data',
		in_staging_tab_sid 				=> v_user_staging_tab_sid,
		in_position 					=> 2,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'COMPANY_ID'),
		in_parent_staging_link_id 		=> v_staging_link_id_1,
		in_destination_tab_sid 			=> NULL,
		in_staging_batch_num_col_sid	=> CASE WHEN in_use_batch_num_col THEN cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'BATCH_NUM') ELSE NULL END,
		out_dedupe_staging_link_id 		=> v_staging_link_id_2
	);

	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id,
		in_description 					=> 'Staging that holds cms data',
		in_staging_tab_sid 				=> v_cms_tab_sid,
		in_position 					=> 3,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_cms_tab_sid, 'COMPANY_ID'),
		in_staging_batch_num_col_sid	=> CASE WHEN in_use_batch_num_col THEN cms.tab_pkg.GetColumnSid(v_cms_tab_sid, 'BATCH_NUM') ELSE NULL END,
		in_parent_staging_link_id 		=> v_staging_link_id_1,
		in_destination_tab_sid 			=> v_destination_tab_sid,
		out_dedupe_staging_link_id 		=> v_staging_link_id_3
	);

	--mappings for company data
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_co_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_co_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'COUNTRY'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_co_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'COMPANY_ID'),
		in_reference_id => v_reference_company_id,
		out_dedupe_mapping_id => v_mapping_ref_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_co_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'ACTIVE'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_ACTIVE,
		out_dedupe_mapping_id => v_mapping_id
	);

	--mappings for users data
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'USER_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_USER_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'FULL_NAME'),
		in_dedupe_field_id => chain_pkg.FLD_USER_FULL_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'EMAIL'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_EMAIL,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'FIRST_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_FIRST_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'LAST_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_LAST_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'FRIENDLY_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_FRIENDLY_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'PHONE_NUM'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_PHONE_NUM,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'JOB'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_JOB_TITLE,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'CREATED_DTM'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_CREATED_DTM,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'USER_REF'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_REF,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'ACTIVE'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_ACTIVE,
		out_dedupe_mapping_id => v_mapping_id
	);

	-- Mappings for cms data
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_3,
		in_tab_sid => v_cms_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_cms_tab_sid, 'SALES_ORG'),
		in_destination_tab_sid	=> v_destination_tab_sid,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'SALES_ORG_ID'),
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_3,
		in_tab_sid => v_cms_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_cms_tab_sid, 'MERCH_CAT'),
		in_destination_tab_sid	=> v_destination_tab_sid,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'MERCH_CAT_ID'),
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_3,
		in_tab_sid => v_cms_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_cms_tab_sid, 'REVENUE'),
		in_destination_tab_sid	=> v_destination_tab_sid,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'REVENUE'),
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_3,
		in_tab_sid => v_cms_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_cms_tab_sid, 'STARTED_BY'),
		in_destination_tab_sid	=> v_destination_tab_sid,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'STARTED_BY_SID'),
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_3,
		in_tab_sid => v_cms_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_cms_tab_sid, 'START_DATE'),
		in_destination_tab_sid	=> v_destination_tab_sid,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'START_DATE'),
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_3,
		in_tab_sid => v_cms_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_cms_tab_sid, 'COMMENTS'),
		in_destination_tab_sid	=> v_destination_tab_sid,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'COMMENTS'),
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_3,
		in_tab_sid => v_cms_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_cms_tab_sid, 'DELETED'),
		in_destination_tab_sid	=> v_destination_tab_sid,
		in_destination_col_sid	=> cms.tab_pkg.GetColumnSid(v_destination_tab_sid, 'DELETED'),
		out_dedupe_mapping_id => v_mapping_id
	);

	--Set rules
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_ref_id));

	dedupe_admin_pkg.TestSaveRuleSetForExactMatches(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id_1,
		in_rule_ids					=> v_rule_ids,
		in_description				=> 'Ref rule set',
		in_rule_set_position		=> 1,
		in_mapping_ids				=> v_mapping_ids,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);

	--Move UI system managed source to a lower priority so we can also merge data (it's moved back in the teardown)
	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;
END;

PROCEDURE SetupSource3(
	in_use_batch_num_col	IN BOOLEAN DEFAULT TRUE
)
AS
	v_mapping_id			NUMBER;
	v_mapping_ids			security.security_pkg.T_SID_IDS;
	v_rule_ids				security.security_pkg.T_SID_IDS;
	v_dedupe_rule_set_id	NUMBER;
BEGIN
	v_co_staging_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'USER_COMPANY_STAGING');
	v_user_staging_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'USER_STAGING');

	dedupe_admin_pkg.SaveImportSource(
		in_import_source_id => -1,
		in_name => 'Company and users integration 2',
		in_position => 1,
		in_no_match_action_id => chain_pkg.AUTO_CREATE,
		in_lookup_key => 'RANDOM_INTEGRATION_2',
		out_import_source_id => v_source_id
	);

	--set up staging links
	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id,
		in_description 					=> 'Staging that holds company data',
		in_staging_tab_sid 				=> v_co_staging_tab_sid,
		in_position 					=> 1,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'COMPANY_ID'),
		in_parent_staging_link_id 		=> NULL,
		in_destination_tab_sid 			=> NULL,
		in_staging_batch_num_col_sid	=> CASE WHEN in_use_batch_num_col THEN cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'BATCH_NUM') ELSE NULL END,
		out_dedupe_staging_link_id 		=> v_staging_link_id_1
	);

	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id,
		in_description 					=> 'Staging that holds users data',
		in_staging_tab_sid 				=> v_user_staging_tab_sid,
		in_position 					=> 2,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'COMPANY_ID'),
		in_staging_batch_num_col_sid	=> CASE WHEN in_use_batch_num_col THEN cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'BATCH_NUM') ELSE NULL END,
		in_parent_staging_link_id 		=> v_staging_link_id_1,
		out_dedupe_staging_link_id 		=> v_staging_link_id_2
	);

	--mappings for company data
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_co_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_co_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'COUNTRY'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_co_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'COMPANY_ID'),
		in_reference_id => v_reference_company_id,
		out_dedupe_mapping_id => v_mapping_ref_id
	);

	--mappings for users data
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'USER_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_USER_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'EMAIL'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_EMAIL,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'FULL_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_FULL_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'FIRST_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_FIRST_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'LAST_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_LAST_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'FRIENDLY_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_FRIENDLY_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	--Set rules
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_ref_id));

	dedupe_admin_pkg.TestSaveRuleSetForExactMatches(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id_1,
		in_description				=> 'Ref rule set',
		in_rule_set_position		=> 1,
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);
END;

PROCEDURE SetupSourceTestRole(
	in_use_batch_num_col	IN BOOLEAN DEFAULT TRUE
)
AS
	v_mapping_id			NUMBER;
	v_mapping_ids			security.security_pkg.T_SID_IDS;
	v_rule_ids				security.security_pkg.T_SID_IDS;
	v_is_fuzzy_arr			security.security_pkg.T_SID_IDS;
	v_dedupe_rule_set_id		NUMBER;
BEGIN
	v_co_staging_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'USER_COMPANY_STAGING');
	v_user_staging_tab_sid := cms.tab_pkg.GetTableSid('RAG', 'USER_STAGING');

	dedupe_admin_pkg.SaveImportSource(
		in_import_source_id => -1,
		in_name => 'Company and users integration 2',
		in_position => 1,
		in_no_match_action_id => chain_pkg.AUTO_CREATE,
		in_lookup_key => 'RANDOM_INTEGRATION_2',
		out_import_source_id => v_source_id
	);

	--set up staging links
	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id,
		in_description 					=> 'Staging that holds company data',
		in_staging_tab_sid 				=> v_co_staging_tab_sid,
		in_position 					=> 1,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'COMPANY_ID'),
		in_parent_staging_link_id 		=> NULL,
		in_destination_tab_sid 			=> NULL,
		in_staging_batch_num_col_sid	=> CASE WHEN in_use_batch_num_col THEN cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'BATCH_NUM') ELSE NULL END,
		out_dedupe_staging_link_id 		=> v_staging_link_id_1
	);

	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> v_source_id,
		in_description 					=> 'Staging that holds users data',
		in_staging_tab_sid 				=> v_user_staging_tab_sid,
		in_position 					=> 2,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'COMPANY_ID'),
		in_staging_batch_num_col_sid	=> CASE WHEN in_use_batch_num_col THEN cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'BATCH_NUM') ELSE NULL END,
		in_parent_staging_link_id 		=> v_staging_link_id_1,
		out_dedupe_staging_link_id 		=> v_staging_link_id_2
	);

	--mappings for company data
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_co_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_co_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'COUNTRY'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_1,
		in_tab_sid => v_co_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_co_staging_tab_sid, 'COMPANY_ID'),
		in_reference_id => v_reference_company_id,
		out_dedupe_mapping_id => v_mapping_ref_id
	);

	--mappings for users data
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'USER_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_USER_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'EMAIL'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_EMAIL,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'FULL_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_FULL_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'FIRST_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_FIRST_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'LAST_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_LAST_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'FRIENDLY_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_USER_FRIENDLY_NAME,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'ROLE_1'),
		in_role_sid	=> v_role_sid_1,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'ROLE_2'),
		in_role_sid	=> v_role_sid_2,
		out_dedupe_mapping_id => v_mapping_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'ROLE_3'),
		in_role_sid	=> v_role_sid_3,
		out_dedupe_mapping_id => v_mapping_id
	);

	--Normally users shouldn't be able to map a n/a role via the ui
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => v_staging_link_id_2,
		in_tab_sid => v_user_staging_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(v_user_staging_tab_sid, 'ROLE_NOT_APPL'),
		in_role_sid	=> v_role_sid_na,
		out_dedupe_mapping_id => v_mapping_id
	);

	--Set rules
	SELECT column_value, 0
	  BULK COLLECT INTO v_mapping_ids, v_rule_ids
	  FROM TABLE(T_NUMBER_LIST(v_mapping_ref_id));

	dedupe_admin_pkg.TestSaveRuleSetForExactMatches(
		in_dedupe_rule_set_id		=> -1,
		in_dedupe_staging_link_id	=> v_staging_link_id_1,
		in_rule_set_position		=> 1,
		in_description				=> 'Ref rule set',
		in_rule_ids					=> v_rule_ids,
		in_mapping_ids				=> v_mapping_ids,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);
END;

PROCEDURE SetupCmsBasedata
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

PROCEDURE SetUpBasedata
AS
BEGIN
	v_user_sid_1 := csr.unit_test_pkg.GetOrCreateUser('Kate Ryes');
END;

PROCEDURE SetUpBasedata2
AS
BEGIN
	v_user_sid_1 := csr.unit_test_pkg.GetOrCreateUser('MMcKensie');
END;


PROCEDURE SetUpBasedata3
AS
BEGIN
	NULL;
END;

PROCEDURE Setup1
AS
BEGIN
	SetUpBasedata;
	SetupSource1;
END;

PROCEDURE Setup2
AS
BEGIN
	SetUpBasedata2;
	SetupSource2;
	SetupCmsBasedata;
END;

PROCEDURE Setup3
AS
BEGIN
	SetUpBasedata3;
	SetupSource3;
END;

PROCEDURE SetupTestRole
AS
BEGIN
	v_role_sid_1 := csr.unit_test_pkg.GetOrCreateRole('ROLE_1');
	v_role_sid_2 := csr.unit_test_pkg.GetOrCreateRole('ROLE_2');
	v_role_sid_3 := csr.unit_test_pkg.GetOrCreateRole('ROLE_3');
	v_role_sid_na := csr.unit_test_pkg.GetOrCreateRole('ROLE_NA');--not applicable

	chain.test_chain_utils_pkg.LinkRoleToCompanyType(v_role_sid_1, 'SUPPLIER');
	chain.test_chain_utils_pkg.LinkRoleToCompanyType(v_role_sid_2, 'SUPPLIER');
	chain.test_chain_utils_pkg.LinkRoleToCompanyType(v_role_sid_3, 'SUPPLIER');

	SetupSourceTestRole;
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);

	test_chain_utils_pkg.SetupSingleTier;

	SetupCompanyRefs2;
END;

PROCEDURE SetSite(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
END;

PROCEDURE TearDownFixture
AS
BEGIN
	DELETE FROM reference_company_type
	 WHERE reference_id IN (
		SELECT reference_id
		  FROM reference
		 WHERE lookup_key IN ('COMPANY_ID_REF')
	 );

	DELETE FROM reference
	 WHERE lookup_key IN ('COMPANY_ID_REF');

	test_chain_utils_pkg.TearDownSingleTier;
END;

-- private
PROCEDURE AddCompanyStaging(
	in_company_id		IN VARCHAR2,
	in_country			IN VARCHAR2,
	in_name				IN VARCHAR2,
	in_active			IN VARCHAR2 DEFAULT 1,
	in_batch_num		IN VARCHAR2 DEFAULT NULL
)
AS
BEGIN
	EXECUTE IMMEDIATE ('
		INSERT INTO rag.USER_COMPANY_STAGING(
			company_staging_id,
			company_id,
			country,
			name,
			active,
			batch_num
		)
		VALUES(
			cms.item_id_seq.nextval,
			:1,:2,:3,:4,:5
		)'
	)
	USING in_company_id, in_country, in_name, in_active, in_batch_num;
END;

FUNCTION BuildUserRow(
	in_username			IN VARCHAR2,
	in_email			IN VARCHAR2 DEFAULT NULL,
	in_fullname			IN VARCHAR2 DEFAULT NULL,
	in_first_name		IN VARCHAR2 DEFAULT NULL,
	in_last_name		IN VARCHAR2 DEFAULT NULL,
	in_friendly_name	IN VARCHAR2 DEFAULT NULL,
	in_phone_num		IN VARCHAR2 DEFAULT NULL,
	in_job				IN VARCHAR2 DEFAULT NULL,
	in_created_dtm		IN DATE DEFAULT NULL,
	in_user_ref			IN VARCHAR2 DEFAULT NULL,
	in_active			IN NUMBER DEFAULT NULL
) RETURN T_DEDUPE_USER_ROW
AS
	v_row		T_DEDUPE_USER_ROW DEFAULT T_DEDUPE_USER_ROW;
BEGIN
	v_row := T_DEDUPE_USER_ROW(
		user_name 		=>	in_username,
		email			=>	in_email,
		full_name		=>	in_fullname,
		first_name		=>	in_first_name,
		last_name		=>	in_last_name,
		friendly_name	=>	in_friendly_name,
		phone_num		=>	in_phone_num,
		job_title		=>	in_job,
		created_dtm		=>	in_created_dtm,
		user_ref		=>	in_user_ref,
		active			=>	in_active,
		user_sid		=> NULL
	);

	RETURN v_row;
END;

FUNCTION BuildExpectedRow(
	in_raw_row		IN T_DEDUPE_USER_ROW,
	in_current_row	IN T_DEDUPE_USER_ROW
)RETURN T_DEDUPE_USER_ROW
AS
	v_exp_row	T_DEDUPE_USER_ROW DEFAULT	T_DEDUPE_USER_ROW();
BEGIN
	v_exp_row.user_name 	:= NVL(in_raw_row.user_name, in_current_row.user_name);
	v_exp_row.email 		:= NVL(in_raw_row.email, in_current_row.email);
	v_exp_row.full_name 	:= NVL(in_raw_row.full_name, in_current_row.full_name);
	v_exp_row.phone_num 	:= NVL(in_raw_row.phone_num, in_current_row.phone_num);
	v_exp_row.job_title 	:= NVL(in_raw_row.job_title, in_current_row.job_title);
	v_exp_row.user_ref 		:= NVL(in_raw_row.user_ref, in_current_row.user_ref);
	v_exp_row.created_dtm 	:= NVL(in_raw_row.created_dtm, in_current_row.created_dtm);
	v_exp_row.active 		:= NVL(in_raw_row.active, in_current_row.active);

	IF v_exp_row.full_name IS NULL AND in_raw_row.first_name IS NOT NULL AND in_raw_row.last_name IS NOT NULL THEN
		v_exp_row.full_name := in_raw_row.first_name || ' ' || in_raw_row.last_name;
	END IF;

	v_exp_row.friendly_name	:= COALESCE(in_raw_row.friendly_name, in_current_row.friendly_name, REGEXP_SUBSTR(v_exp_row.full_name,'[^ ]+', 1, 1)); --copied from csr_user_body

	RETURN v_exp_row;
END;

FUNCTION GetCurrentRow(
	in_username	VARCHAR2
)RETURN T_DEDUPE_USER_ROW
AS
	v_curr_row	T_DEDUPE_USER_ROW DEFAULT T_DEDUPE_USER_ROW();
BEGIN
	BEGIN
		SELECT T_DEDUPE_USER_ROW(
			user_name 		=>	user_name,
			email			=>	email,
			full_name		=>	full_name,
			first_name		=>	NULL,
			last_name		=>	NULL,
			friendly_name	=>	friendly_name,
			phone_num		=>	phone_number,
			job_title		=>	job_title,
			created_dtm		=>	created_dtm,
			user_ref		=>	user_ref,
			active			=>	active,
			user_sid		=>	NULL
		)
		  INTO v_curr_row
		  FROM csr.v$csr_user
		 WHERE lower(user_name) = lower(in_username); --user_name is always lower
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	RETURN v_curr_row;
END;

PROCEDURE AddUserStaging(
	in_company_id		VARCHAR2,
	in_batch_num		NUMBER DEFAULT NULL,
	in_raw_vals			IN T_DEDUPE_USER_ROW,
	in_has_role_1		NUMBER DEFAULT NULL,
	in_has_role_2		NUMBER DEFAULT NULL,
	in_has_role_3		NUMBER DEFAULT NULL,
	in_has_role_na		NUMBER DEFAULT NULL
)
AS
BEGIN
	EXECUTE IMMEDIATE ('
		INSERT INTO rag.user_staging(
			user_staging_id,
			company_id,
			user_name,
			email,
			full_name,
			first_name,
			last_name,
			friendly_name,
			phone_num,
			job,
			created_dtm,
			user_ref,
			active,
			batch_num,
			role_1,
			role_2,
			role_3,
			role_not_appl
		)
		VALUES(
			cms.item_id_seq.nextval,
			:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13,
			:14,:15,:16,:17
		)'
	)
	USING in_company_id, in_raw_vals.user_name, in_raw_vals.email, in_raw_vals.full_name, in_raw_vals.first_name, in_raw_vals.last_name, in_raw_vals.friendly_name,
		in_raw_vals.phone_num, in_raw_vals.job_title, in_raw_vals.created_dtm, in_raw_vals.user_ref, in_raw_vals.active, in_batch_num,
		in_has_role_1, in_has_role_2, in_has_role_3, in_has_role_na;
END;

PROCEDURE AddStagingRow(
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

PROCEDURE AddChildCmsStagingRow(
	in_company_id				IN  VARCHAR2,
	in_sales_org				IN  VARCHAR2,
	in_merch_cat				IN  VARCHAR2,
	in_cms_company_staging_id 	IN 	NUMBER DEFAULT NULL,
	in_started_by				IN  VARCHAR2 DEFAULT NULL,
	in_revenue					IN  NUMBER DEFAULT NULL,
	in_started_date				IN  DATE DEFAULT NULL,
	in_comments					IN  VARCHAR2 DEFAULT NULL,
	in_batch_num				IN  NUMBER DEFAULT NULL,
	in_deleted					IN  NUMBER DEFAULT NULL,
	in_band_label				IN  VARCHAR2 DEFAULT NULL
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

PROCEDURE SetUp
AS
BEGIN
	NULL;
END;

PROCEDURE TearDown
AS
	v_imported_user_sids	security_pkg.T_SID_IDS;
BEGIN
	SELECT imported_user_sid
	  BULK COLLECT INTO v_imported_user_sids
	  FROM dedupe_processed_record
	 WHERE app_sid = security_pkg.getapp
	   AND imported_user_sid IS NOT NULL;

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

	IF v_imported_user_sids.EXISTS(v_imported_user_sids.FIRST) THEN
		FOR i IN v_imported_user_sids.FIRST .. v_imported_user_sids.LAST
		LOOP
			security.securableobject_pkg.DeleteSO(security_pkg.getact, v_imported_user_sids(i));
		END LOOP;
	END IF;

	security.securableobject_pkg.DeleteSO(security_pkg.getact, v_user_sid_1);
	security.securableobject_pkg.DeleteSO(security_pkg.getact, v_user_sid_2);
	security.securableobject_pkg.DeleteSO(security_pkg.getact, v_user_sid_3);

	DELETE FROM company_type_role
	 WHERE role_sid IN (v_role_sid_1, v_role_sid_2, v_role_sid_3);

	--make them unmanaged first
	UPDATE csr.role
	   SET is_system_managed = 0
	 WHERE role_sid IN (v_role_sid_1, v_role_sid_2, v_role_sid_3);

	security.securableobject_pkg.DeleteSO(security_pkg.getact, v_role_sid_1);
	security.securableobject_pkg.DeleteSO(security_pkg.getact, v_role_sid_2);
	security.securableobject_pkg.DeleteSO(security_pkg.getact, v_role_sid_3);
	security.securableobject_pkg.DeleteSO(security_pkg.getact, v_role_sid_na);

	--Move UI system managed source back to its original position
	UPDATE import_source
	   SET position = 0
	 WHERE is_owned_by_system = 1;

	test_chain_utils_pkg.DeleteFullyCompaniesOfType('SUPPLIER');


	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.CHILD_CMS_COMPANY_STAGING';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.USER_COMPANY_STAGING';
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
		EXECUTE IMMEDIATE 'DELETE FROM rag.CMS_COMPANY_STAGING_3';
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

	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM rag.SCORE_BAND';
	EXCEPTION
		WHEN test_chain_utils_pkg.TAB_NOT_FOUND THEN
			NULL;
	END;
END;

FUNCTION GetNewCompany(
	in_processed_record_id			NUMBER,
	in_batch_num					NUMBER,
	in_company_name					VARCHAR2
)
RETURN security_pkg.T_SID_ID
AS
	v_company_sid		security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT created_company_sid
		  INTO v_company_sid
		  FROM dedupe_processed_record
		 WHERE (in_batch_num IS NULL OR batch_num = in_batch_num)
		   AND dedupe_processed_record_id = in_processed_record_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Company '||in_company_name||' was not created');
	END;

	RETURN v_company_sid;
END;

FUNCTION GetUpdatedCompany(
	in_processed_record_id			NUMBER,
	in_batch_num					NUMBER
)
RETURN security_pkg.T_SID_ID
AS
	v_company_sid		security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT matched_to_company_sid
		  INTO v_company_sid
		  FROM dedupe_processed_record
		 WHERE batch_num = in_batch_num
		   AND dedupe_processed_record_id = in_processed_record_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Processed record for company data not found');
	END;

	RETURN v_company_sid;
END;

PROCEDURE ValidateUserFieldLog(
	in_processed_record_id			dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_dedupe_field_id				dedupe_merge_log.dedupe_field_id%TYPE,
	in_old_val						dedupe_merge_log.old_val%TYPE,
	in_new_val						dedupe_merge_log.new_val%TYPE
)
AS
	v_logged_old_val				dedupe_merge_log.old_val%TYPE;
	v_logged_new_val				dedupe_merge_log.old_val%TYPE;
	v_count							NUMBER;
BEGIN
	IF csr.null_pkg.eq(in_old_val, in_new_val) THEN
		--we do log the new_val when it is equal to the old val unless the raw val is null.
		IF in_new_val IS NULL THEN
			SELECT COUNT(*)
			  INTO v_count
			  FROM dedupe_merge_log
			 WHERE dedupe_processed_record_id = in_processed_record_id
			   AND dedupe_field_id = in_dedupe_field_id;

			IF v_count > 0 THEN
				csr.unit_test_pkg.TestFail('Didn''t expect merge log for the field '||in_dedupe_field_id);
			END IF;
		END IF;

		RETURN;
	END IF;

	IF in_new_val IS NULL THEN
		SELECT COUNT(*)
		  INTO v_count
		  FROM dedupe_merge_log
		 WHERE dedupe_processed_record_id = in_processed_record_id
		   AND dedupe_field_id = in_dedupe_field_id;

		IF v_count > 0 THEN
			csr.unit_test_pkg.TestFail('Didn''t expect merge log for the field '||in_dedupe_field_id||' old val:'||in_old_val||' new val:'||in_new_val);
		END IF;
	ELSE
		BEGIN
			SELECT CASE WHEN dedupe_field_id = chain_pkg.FLD_USER_USER_NAME THEN lower(old_val) ELSE old_val END,
				   CASE WHEN dedupe_field_id = chain_pkg.FLD_USER_USER_NAME THEN lower(new_val) ELSE new_val END
			  INTO v_logged_old_val, v_logged_new_val
			  FROM dedupe_merge_log
			 WHERE dedupe_processed_record_id = in_processed_record_id
			   AND dedupe_field_id = in_dedupe_field_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				csr.unit_test_pkg.TestFail('Expected data in the merge log for the field '||in_dedupe_field_id||' old val:'||in_old_val||' new val:'||in_new_val);
		END;

		-- TODO: this isn't go to be very helpful - log somewhere higher up the stack with more
		-- info on where the test failed
		csr.unit_test_pkg.AssertAreEqual(in_old_val, v_logged_old_val, 'Incorrect old value logged for field ' || in_dedupe_field_id);
		csr.unit_test_pkg.AssertAreEqual(in_new_val, v_logged_new_val, 'Incorrect new value logged for field ' || in_dedupe_field_id);
	END IF;
END;

PROCEDURE ValidateMergeLog(
	in_processed_record_id			dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_old_values					T_DEDUPE_USER_ROW,
	in_raw_values					T_DEDUPE_USER_ROW
)
AS
	v_fullname		VARCHAR2(255) DEFAULT in_raw_values.full_name;
BEGIN
	IF in_raw_values.user_name IS NULL THEN
		ValidateUserFieldLog(in_processed_record_id, chain_pkg.FLD_USER_USER_NAME, lower(in_old_values.user_name), lower(in_raw_values.email));
	ELSE
		ValidateUserFieldLog(in_processed_record_id, chain_pkg.FLD_USER_USER_NAME, lower(in_old_values.user_name), lower(in_raw_values.user_name));
	END IF;

	ValidateUserFieldLog(in_processed_record_id, chain_pkg.FLD_USER_EMAIL, in_old_values.email, in_raw_values.email);
	ValidateUserFieldLog(in_processed_record_id, chain_pkg.FLD_USER_PHONE_NUM, in_old_values.phone_num, in_raw_values.phone_num);
	ValidateUserFieldLog(in_processed_record_id, chain_pkg.FLD_USER_JOB_TITLE, in_old_values.job_title, in_raw_values.job_title);
	ValidateUserFieldLog(in_processed_record_id, chain_pkg.FLD_USER_CREATED_DTM, in_old_values.created_dtm, in_raw_values.created_dtm);
	ValidateUserFieldLog(in_processed_record_id, chain_pkg.FLD_USER_REF, in_old_values.user_ref, in_raw_values.user_ref);
	ValidateUserFieldLog(in_processed_record_id, chain_pkg.FLD_USER_ACTIVE, in_old_values.active, in_raw_values.active);

	--if full_name is not provide we concat first and last (we log it under full_name in merge log)
	IF v_fullname IS NULL AND in_raw_values.first_name IS NOT NULL AND in_raw_values.last_name IS NOT NULL THEN
		v_fullname := in_raw_values.first_name || ' ' || in_raw_values.last_name;
	END IF;

	ValidateUserFieldLog(in_processed_record_id, chain_pkg.FLD_USER_FULL_NAME, in_old_values.full_name, v_fullname);

	--note: friendly_name is auto-generated if there is no value. We dont log the auto-generation
	ValidateUserFieldLog(in_processed_record_id, chain_pkg.FLD_USER_FRIENDLY_NAME, in_old_values.friendly_name, in_raw_values.friendly_name);
END;

PROCEDURE ValidateProcessedRecord(
	in_processed_record_id	NUMBER,
	in_company_sid			security_pkg.T_SID_ID
)
AS
	v_count			NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = in_processed_record_id
	   AND matched_to_company_sid = in_company_sid
	   AND imported_user_sid IS NOT NULL;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Processed record data for user is not the expected ones');
END;

PROCEDURE ValidateUserData(
	in_username						csr.csr_user.user_name%TYPE,
	in_old_values					T_DEDUPE_USER_ROW,
	in_new_values					T_DEDUPE_USER_ROW
)
AS
	v_user_details					csr.v$csr_user%ROWTYPE;
BEGIN
	BEGIN
		SELECT *
		  INTO v_user_details
		  FROM csr.v$csr_user
		 WHERE lower(user_name) = lower(in_username); --user_name is always lower
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('User ' || in_username || ' was not created');
	END;

	IF in_new_values.user_name IS NULL THEN
		csr.unit_test_pkg.AssertAreEqual(lower(in_new_values.email), lower(v_user_details.user_name), 'User name is incorrect');
	ELSE
		csr.unit_test_pkg.AssertAreEqual(lower(in_new_values.user_name), lower(v_user_details.user_name), 'User name is incorrect');
	END IF;

	csr.unit_test_pkg.AssertAreEqual(in_new_values.email, v_user_details.email,  'User email is incorrect');
	csr.unit_test_pkg.AssertAreEqual(in_new_values.full_name, v_user_details.full_name,  'User full name is incorrect');
	csr.unit_test_pkg.AssertAreEqual(in_new_values.friendly_name, v_user_details.friendly_name, 'User friendly name is incorrect');
	csr.unit_test_pkg.AssertAreEqual(in_new_values.phone_num, v_user_details.phone_number, 'User phone number is incorrect');
	csr.unit_test_pkg.AssertAreEqual(in_new_values.user_ref, v_user_details.user_ref, 'User ref is incorrect');
	csr.unit_test_pkg.AssertAreEqual(in_new_values.job_title, v_user_details.job_title, 'User job title is incorrect');

	-- Only check the active flag if it has changed
	IF in_new_values.active IS NOT NULL THEN
		csr.unit_test_pkg.AssertAreEqual(in_new_values.active, v_user_details.active, 'User active state is incorrect');
	END IF;
END;

PROCEDURE ValidateUserNameIsEmail(
	in_username 		csr.csr_user.user_name%TYPE,
	in_old_values	 	T_DEDUPE_USER_ROW,
	in_new_values 		T_DEDUPE_USER_ROW
) AS
	v_user_details					csr.csr_user%ROWTYPE;
BEGIN
	BEGIN
		SELECT *
		  INTO v_user_details
		  FROM csr.csr_user
		 WHERE lower(user_name) = lower(in_username); --user_name is always lower
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('User ' || in_username || ' was not created');
	END;

	csr.unit_test_pkg.AssertAreEqual(in_new_values.email, in_username,  'User email is incorrect');
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

PROCEDURE ValidateUserCompanyMembership(
	in_username						csr.csr_user.user_name%TYPE,
	in_expected_companies			T_NUMBER_LIST,
	in_exclude_top_company			NUMBER DEFAULT 0
)
AS
	v_user_sid						security_pkg.T_SID_ID;
BEGIN
	ValidateUserSid(in_username, v_user_sid);

	FOR r IN (
		SELECT column_value company_sid, DECODE(cu.company_sid, NULL, 0, 1) is_company_member, c.name
		  FROM TABLE(in_expected_companies) ec
		  JOIN company c ON ec.column_value = c.company_sid
		  LEFT JOIN v$company_user cu ON cu.company_sid = ec.column_value AND cu.user_sid = v_user_sid
	)
	LOOP
		csr.unit_test_pkg.AssertAreEqual(r.is_company_member, 1, 'User '||in_username||' should be a member of the company '|| r.name);
	END LOOP;

	FOR r IN (
		SELECT c.name
		  FROM v$company_user cu
		  JOIN company c ON cu.company_sid = c.company_sid
		 WHERE NOT EXISTS (
				SELECT 1
				  FROM TABLE(in_expected_companies) ec
				 WHERE ec.column_value = cu.company_sid
		  )
		   AND cu.user_sid = v_user_sid
		   AND (in_exclude_top_company = 0 OR c.company_sid != helper_pkg.getTopCompanySid)
	)
	LOOP
		csr.unit_test_pkg.TestFail('User '||in_username||' should not be a member of the company '|| r.name);
	END LOOP;
END;

FUNCTION GetRoleName(
	in_role_sid	NUMBER
)RETURN VARCHAR2
AS
	v_role_name		VARCHAR2(255);
BEGIN
	 SELECT name
	   INTO v_role_name
	   FROM csr.role
	  WHERE role_sid = in_role_sid;

	RETURN v_role_name;
END;

PROCEDURE ValidateRRM(
	in_processed_record_id	NUMBER,
	in_roles_sids			security.T_ORDERED_SID_TABLE,
	in_val_changes			security.T_ORDERED_SID_TABLE --order needs to be synced to in_roles_sids
)
AS
	v_user_sid			NUMBER;
	v_region_sid		NUMBER;
	v_temp_role_sid		NUMBER;
	v_temp_is_set		NUMBER;
	v_count				NUMBER;
BEGIN
	SELECT dpr.imported_user_sid, s.region_sid
	  INTO v_user_sid, v_region_sid
	  FROM dedupe_processed_record dpr
	  JOIN csr.supplier s ON s.company_sid = NVL(created_company_sid, matched_to_company_sid)
	 WHERE dpr.app_sid = security_pkg.getapp
	   AND dpr.dedupe_processed_record_id = in_processed_record_id;

	FOR i IN in_roles_sids.FIRST .. in_roles_sids.LAST LOOP
		v_temp_role_sid := in_roles_sids(i).sid_id;
		v_temp_is_set := in_roles_sids(i).pos; --0 for remove, 1 for add

		SELECT COUNT(*)
		  INTO v_count
		  FROM csr.region_role_member
		 WHERE app_sid = security_pkg.getapp
		   AND region_sid = v_region_sid
		   AND user_sid = v_user_sid
		   AND role_sid = v_temp_role_sid;

		csr.unit_test_pkg.AssertAreEqual(v_temp_is_set, v_count, 'Number of rows is region role membership is not the expected one for role:'||GetRoleName(v_temp_role_sid));

		IF in_val_changes.EXISTS(i) AND in_val_changes(i) IS NOT NULL THEN --convention: even for new user record the old val will be 0 not null
			SELECT COUNT(*)
			  INTO v_count
			  FROM dedupe_merge_log
			 WHERE dedupe_processed_record_id = in_processed_record_id
			   AND role_sid = v_temp_role_sid
			   AND new_val = in_val_changes(i).sid_id
			   AND old_val = in_val_changes(i).pos;

			csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Results in merge log are not the expected ones for role:'||GetRoleName(v_temp_role_sid));
		ELSE
			SELECT COUNT(*)
			  INTO v_count
			  FROM dedupe_merge_log
			 WHERE dedupe_processed_record_id = in_processed_record_id
			   AND role_sid = v_temp_role_sid;

			csr.unit_test_pkg.AssertAreEqual(0, v_count, 'We don''t expect merge log data for role:'||GetRoleName(v_temp_role_sid));
		END IF;
	END LOOP;
END;

-- helper fn for ValidateRRMInverse
FUNCTION GetRegionRoleCounts(
	in_user_sid					NUMBER,
	in_role_sid					NUMBER,
	in_exlude_region_sids		T_NUMBER_LIST
) RETURN NUMBER
AS
	v_count						NUMBER;
BEGIN

	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.region_role_member
	 WHERE app_sid = security_pkg.getapp
	   AND user_sid = in_user_sid
	   AND region_sid NOT IN (SELECT column_value FROM TABLE(in_exlude_region_sids))
	   AND role_sid = in_role_sid;

	--security_pkg.debugmsg('GetRegionRoleCounts ('||GetRoleName(in_role_sid)||') ' || v_count);

	RETURN v_count;
END;

-- check no other company roles have been affected
PROCEDURE ValidateRRMInverse(
	in_user_sid					NUMBER,
	in_roles_sids				T_NUMBER_LIST,
	in_exlude_region_sids		T_NUMBER_LIST,
	in_expected_counts			security.T_SID_TABLE
)
AS
	v_count						NUMBER;
BEGIN
	FOR i IN in_roles_sids.FIRST .. in_roles_sids.LAST LOOP
		v_count := GetRegionRoleCounts(in_user_sid, in_roles_sids(i), in_exlude_region_sids);
		csr.unit_test_pkg.AssertAreEqual(in_expected_counts(i), v_count, 'Inverse check: Number of unaffected company rows in region role membership is not the expected one for role:'||GetRoleName(in_roles_sids(i)));
	END LOOP;
END;

PROCEDURE Test_UserImport
AS
	v_company_1_sid				NUMBER;
	v_company_2_sid				NUMBER;
	v_company_1_id				VARCHAR2(20) := '11111111';
	v_company_2_id				VARCHAR2(20) := '22222222';

	v_import_user_1_username	VARCHAR2(20) DEFAULT  'impUser1';
	v_import_user_2_username	VARCHAR2(20) DEFAULT  'impUser2';
	v_import_user_3_username	VARCHAR2(20) DEFAULT  'impUser3';
	v_import_user_4_username	VARCHAR2(20) DEFAULT  'impUser4';

	v_import_user_expected		T_DEDUPE_USER_ROW;
	v_user_old					T_DEDUPE_USER_ROW;
	v_user_old_2				T_DEDUPE_USER_ROW;
	v_user_old_3				T_DEDUPE_USER_ROW;
	v_user_old_4				T_DEDUPE_USER_ROW;

	v_raw_vals_1				T_DEDUPE_USER_ROW;
	v_raw_vals_2				T_DEDUPE_USER_ROW;
	v_raw_vals_3				T_DEDUPE_USER_ROW;
	v_raw_vals_4				T_DEDUPE_USER_ROW;

	v_processed_record_ids		security_pkg.T_SID_IDS;
BEGIN
	Setup1;

	/* Test 1: Create two new companies, one unique user each and one shared user */
	AddCompanyStaging(
		in_company_id => v_company_1_id,
		in_country => 'gb',
		in_name => 'User import company 1',
		in_active => 1,
		in_batch_num => 1
	);

	--first user
	v_raw_vals_1 := BuildUserRow(
		in_username => v_import_user_1_username,
		in_email => 'imp1@rrrr.com',
		in_fullname => 'imp user 1',
		in_first_name => 'Imp',
		in_last_name => 'User 1 xx',
		in_friendly_name => 'Impy',
		in_phone_num => '3453409809',
		in_job => 'PM',
		in_created_dtm => DATE '2012-1-1',
		in_user_ref => '1111',
		in_active => 1
	);

	AddUserStaging(
		in_company_id	=> v_company_1_id,
		in_raw_vals		=> 	v_raw_vals_1,
		in_batch_num	=> 1
	);

	v_user_old := GetCurrentRow(v_import_user_1_username);

	--second user
	v_raw_vals_2 := BuildUserRow(
		in_username => v_import_user_2_username,
		in_email => 'imp2@rrrr.com',
		in_fullname => 'Imp user 2',
		in_first_name => 'Imp',
		in_last_name => 'User 2',
		in_friendly_name => 'Impy',
		in_phone_num => '3453409809',
		in_job => 'PM',
		in_created_dtm => NULL,
		in_user_ref => '1112',
		in_active => 1
	);

	AddUserStaging(
		in_company_id	=> v_company_1_id,
		in_raw_vals		=> 	v_raw_vals_2,
		in_batch_num	=> 1
	);

	v_user_old_2:= GetCurrentRow(v_import_user_2_username);

	--process
	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id => v_source_id,
		in_reference => v_company_1_id,
		in_batch_num => 1,
		in_force_re_eval => 0,
		out_processed_record_ids => v_processed_record_ids
	);

	v_company_1_sid := GetNewCompany(v_processed_record_ids(1), 1, 'Company 1');

	--create expected record set and validate
	v_import_user_expected := BuildExpectedRow(v_raw_vals_1, v_user_old);

	ValidateProcessedRecord(v_processed_record_ids(2), v_company_1_sid);
	ValidateUserData(v_import_user_1_username, v_user_old, v_import_user_expected);
	ValidateUserCompanyMembership(v_import_user_1_username, T_NUMBER_LIST(v_company_1_sid));
	ValidateMergeLog(v_processed_record_ids(2), v_user_old, v_raw_vals_1);

	--create expected record set and validate
	v_import_user_expected := BuildExpectedRow(v_raw_vals_2, v_user_old_2);

	ValidateUserData(v_import_user_2_username, v_user_old_2, v_import_user_expected);
	ValidateUserCompanyMembership(v_import_user_2_username, T_NUMBER_LIST(v_company_1_sid));
	ValidateMergeLog(v_processed_record_ids(3), v_user_old_2, v_raw_vals_2);

	--new test case
	AddCompanyStaging(
		in_company_id => v_company_2_id,
		in_country => 'gb',
		in_name => 'User import company 2',
		in_active => 1,
		in_batch_num => 1
	);

	v_raw_vals_2 := BuildUserRow(
		in_username => v_import_user_2_username
	);

	AddUserStaging(
		in_company_id	=> v_company_2_id,
		in_batch_num	=> 1,
		in_raw_vals		=> v_raw_vals_2
	);

	v_user_old_2:= GetCurrentRow(v_import_user_2_username);

	v_raw_vals_3 := BuildUserRow(
		in_username => v_import_user_3_username,
		in_email => 'imp3@rrrr.com',
		in_fullname => 'Imp user 3',
		in_first_name => 'Imp',
		in_last_name => 'User 3',
		in_friendly_name => 'Impy',
		in_phone_num => '3453409809',
		in_job => 'PM',
		in_created_dtm => DATE '2015-03-02',
		in_user_ref => '1113',
		in_active => 1
	);

	AddUserStaging(
		in_company_id => v_company_2_id,
		in_batch_num => 1,
		in_raw_vals => v_raw_vals_3
	);

	v_user_old_3 := GetCurrentRow(v_import_user_3_username);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id => v_source_id,
		in_reference => v_company_2_id,
		in_batch_num => 1,
		in_force_re_eval => 0,
		out_processed_record_ids => v_processed_record_ids
	);

	--create expected record set and validate
	v_import_user_expected := BuildExpectedRow(v_raw_vals_2, v_user_old_2);

	v_company_2_sid := GetNewCompany(v_processed_record_ids(1), 1, 'Company 2');
	ValidateUserData(v_import_user_2_username, v_user_old_2, v_import_user_expected);
	ValidateUserCompanyMembership(v_import_user_2_username, T_NUMBER_LIST(v_company_1_sid, v_company_2_sid));
	ValidateMergeLog(v_processed_record_ids(2), v_user_old_2, v_raw_vals_2);

	--create expected record set and validate
	v_import_user_expected := BuildExpectedRow(v_raw_vals_3, v_user_old_3);

	ValidateUserData(v_import_user_3_username, v_user_old_3, v_import_user_expected);
	ValidateUserCompanyMembership(v_import_user_3_username, T_NUMBER_LIST(v_company_2_sid));
	ValidateMergeLog(v_processed_record_ids(3), v_user_old_3, v_raw_vals_3);

	--Check the first user we created is still in company 1
	ValidateUserCompanyMembership('impUser1', T_NUMBER_LIST(v_company_1_sid));

	/* Test 2: Update company 1 - add a new user, update an existing user, add a new user with no user name supplied */

	AddCompanyStaging(
		in_company_id => v_company_1_id,
		in_country => 'gb',
		in_name => 'User import company 1',
		in_active => 1,
		in_batch_num => 2
	);

	v_raw_vals_1 := BuildUserRow(
		in_username => v_import_user_1_username,
		in_email => 'imp1Upd@rrrr.com',
		in_fullname => 'Imp user 1 UPDATE',
		in_first_name => NULL,
		in_last_name => NULL,
		in_friendly_name => 'Impy UPDATE',
		in_phone_num => '3453409809 UPDATE',
		in_job => 'Numpty',
		in_created_dtm =>  DATE '2011-03-02',
		in_user_ref => '9999',
		in_active => 1
	);

	AddUserStaging(
		in_company_id => v_company_1_id,
		in_batch_num => 2,
		in_raw_vals => v_raw_vals_1
	);

	v_user_old:= GetCurrentRow(v_import_user_1_username);

	v_raw_vals_4 := BuildUserRow(
		in_username => v_import_user_4_username,
		in_email => 'imp4@rrrr.com',
		in_fullname => 'Imp user 4',
		in_first_name => 'Imp',
		in_last_name => 'User 4',
		in_friendly_name => 'Impy',
		in_phone_num => '4766467565',
		in_job => 'PM',
		in_created_dtm =>  DATE '2010-03-02',
		in_user_ref => '1114',
		in_active => 1
	);

	AddUserStaging(
		in_company_id => v_company_1_id,
		in_batch_num => 2,
		in_raw_vals => v_raw_vals_4
	);

	v_user_old_4:= GetCurrentRow(v_import_user_4_username);

	-- Add user with no username - email address will be used to user_name
	v_raw_vals_2 := BuildUserRow(
		in_username => NULL,
		in_email => 'imp2Upd@rrrr.com',
		in_fullname => 'Imp user 2 NEW',
		in_first_name => NULL,
		in_last_name => NULL,
		in_friendly_name => 'Impy NEW',
		in_phone_num => '3453409809 NEW',
		in_job => 'Numpty',
		in_created_dtm =>  DATE '2011-03-02',
		in_user_ref => '666',
		in_active => 1
	);

	AddUserStaging(
		in_company_id => v_company_1_id,
		in_batch_num => 2,
		in_raw_vals => v_raw_vals_2
	);

	v_user_old_2:= GetCurrentRow(NULL);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id => v_source_id,
		in_reference => v_company_1_id,
		in_batch_num => 2,
		in_force_re_eval => 0,
		out_processed_record_ids => v_processed_record_ids
	);

	--create expected record set and validate
	v_import_user_expected := BuildExpectedRow(v_raw_vals_1, v_user_old);

	v_company_1_sid := GetUpdatedCompany(v_processed_record_ids(1), 2); --2nd batch
	ValidateUserData(v_import_user_1_username, v_user_old, v_import_user_expected);
	ValidateUserCompanyMembership(v_import_user_1_username, T_NUMBER_LIST(v_company_1_sid));
	ValidateMergeLog(v_processed_record_ids(2), v_user_old, v_raw_vals_1);

	--create expected record set and validate
	v_import_user_expected := BuildExpectedRow(v_raw_vals_4, v_user_old_4);

	ValidateUserData(v_import_user_4_username, v_user_old_4, v_import_user_expected);
	ValidateUserCompanyMembership(v_import_user_4_username, T_NUMBER_LIST(v_company_1_sid));
	ValidateMergeLog(v_processed_record_ids(3), v_user_old_4, v_raw_vals_4);

	ValidateUserCompanyMembership('impUser2', T_NUMBER_LIST(v_company_1_sid, v_company_2_sid));

	--create new user with email as username
	v_import_user_expected := BuildExpectedRow(v_raw_vals_2, v_user_old_2);

	ValidateUserData('imp2Upd@rrrr.com', v_user_old_2, v_import_user_expected);
	ValidateUserNameIsEmail('imp2Upd@rrrr.com', v_user_old_2, v_import_user_expected);
	ValidateMergeLog(v_processed_record_ids(4), v_user_old_2, v_raw_vals_2);

	ValidateUserCompanyMembership('imp2Upd@rrrr.com', T_NUMBER_LIST(v_company_1_sid));

	/* Test 3: Move a user from one company to another */

	-- impUser3 belongs to company 2. First add them to company 1 then remove
	-- from company 1
	AddCompanyStaging(
		in_company_id => v_company_1_id,
		in_country => 'gb',
		in_name => 'User import company 1',
		in_active => 1,
		in_batch_num => 4
	);

	v_raw_vals_3 := BuildUserRow(
		in_username => v_import_user_3_username,
		in_active => 1
	);

	AddUserStaging(
		in_company_id => v_company_1_id,
		in_raw_vals => v_raw_vals_3,
		in_batch_num => 4
	);

	v_user_old := GetCurrentRow(v_import_user_3_username);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id => v_source_id,
		in_reference => v_company_1_id,
		in_batch_num => 4,
		in_force_re_eval => 0,
		out_processed_record_ids => v_processed_record_ids
	);

	--validate
	ValidateUserCompanyMembership(v_import_user_3_username, T_NUMBER_LIST(v_company_1_sid, v_company_2_sid));
	ValidateMergeLog(v_processed_record_ids(2), v_user_old, v_raw_vals_3);

	--new test case
	AddCompanyStaging(
		in_company_id => v_company_2_id,
		in_country => 'gb',
		in_name => 'User import company 2',
		in_active => 1,
		in_batch_num => 4
	);

	v_raw_vals_3 := BuildUserRow(
		in_username => v_import_user_3_username,
		in_active => 0
	);

	AddUserStaging(
		in_company_id => v_company_2_id,
		in_batch_num => 4,
		in_raw_vals => v_raw_vals_3
	);

	v_user_old := GetCurrentRow(v_import_user_3_username);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id => v_source_id,
		in_reference => v_company_2_id,
		in_batch_num => 4,
		in_force_re_eval => 0,
		out_processed_record_ids => v_processed_record_ids
	);

	--validate
	ValidateUserCompanyMembership(v_import_user_3_username, T_NUMBER_LIST(v_company_1_sid));
	ValidateMergeLog(v_processed_record_ids(2), v_user_old, v_raw_vals_3);

	/* Test 5: Remove a user from all companies */
	AddCompanyStaging(
		in_company_id => v_company_1_id,
		in_country => 'gb',
		in_name => 'User import company 1',
		in_active => 1,
		in_batch_num => 5
	);

	AddCompanyStaging(
		in_company_id => v_company_2_id,
		in_country => 'gb',
		in_name => 'User import company 2',
		in_active => 1,
		in_batch_num => 5
	);

	v_raw_vals_2 := BuildUserRow(
		in_username => v_import_user_2_username,
		in_email => 'imp2@rrrr.com',
		in_fullname => 'Imp user 2',
		in_first_name => 'Imp',
		in_last_name => 'User 2',
		in_friendly_name => 'Impy',
		in_phone_num => '3453409809',
		in_job => 'PM',
		in_user_ref => '1112',
		in_active => 0
	);

	AddUserStaging(
		in_company_id => v_company_1_id,
		in_batch_num => 5,
		in_raw_vals => v_raw_vals_2
	);

	v_raw_vals_2 := BuildUserRow(
		in_username => v_import_user_2_username,
		in_email => 'imp2@rrrr.com',
		in_active => 0
	);

	AddUserStaging(
		in_company_id => v_company_2_id,
		in_batch_num => 5,
		in_raw_vals => v_raw_vals_2
	);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id => v_source_id,
		in_reference => v_company_1_id,
		in_batch_num => 5,
		out_processed_record_ids => v_processed_record_ids
	);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id => v_source_id,
		in_reference => v_company_2_id,
		in_batch_num => 5,
		out_processed_record_ids => v_processed_record_ids
	);

	ValidateUserCompanyMembership(v_import_user_2_username, T_NUMBER_LIST());
END;

PROCEDURE Test_ImportExistingUser
AS
	v_company_1_sid					security_pkg.T_SID_ID;
	v_username						VARCHAR2(20) := 'Kate Ryes'; -- A user that already exists in the system as a member of top company.
	v_user_old					T_DEDUPE_USER_ROW;
	v_expected_data					T_DEDUPE_USER_ROW;
	v_raw_vals						T_DEDUPE_USER_ROW;
	v_processed_record_ids			security_pkg.T_SID_IDS;
BEGIN
	Setup1;

	AddCompanyStaging(
		in_company_id => '99999',
		in_country => 'gb',
		in_name => 'User import company 1',
		in_active => 1,
		in_batch_num => 3
	);

	v_raw_vals := BuildUserRow(
		in_username => v_username,
		in_active => 1
	);

	AddUserStaging(
		in_company_id => '99999',
		in_batch_num => 3,
		in_raw_vals => v_raw_vals
	);

	v_user_old	:= GetCurrentRow(v_username);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id => v_source_id,
		in_reference => '99999',
		in_batch_num => 3,
		in_force_re_eval => 0,
		out_processed_record_ids => v_processed_record_ids
	);

	--create expected record set and validate
	v_expected_data := BuildExpectedRow(v_raw_vals, v_user_old);

	v_company_1_sid := GetNewCompany(v_processed_record_ids(1), 3, 'User import company 1');
	ValidateUserData(v_username, v_user_old, v_expected_data);
	ValidateUserCompanyMembership(v_username, T_NUMBER_LIST(v_company_1_sid), 1);
	ValidateMergeLog(v_processed_record_ids(2), v_user_old, v_raw_vals);
END;

PROCEDURE Test_MandatoryFields
AS
	v_company_1_sid				security_pkg.T_SID_ID;
	v_username					VARCHAR2(20) := 'kate_ryes_meyer';
	v_fullname					VARCHAR2(20) := 'Kate Ryes Meyer';
	v_user_old				T_DEDUPE_USER_ROW;
	v_expected_data				T_DEDUPE_USER_ROW;
	v_processed_record_ids		security_pkg.T_SID_IDS;
	v_count						NUMBER;
	v_company_sid				NUMBER;
	v_raw_vals					T_DEDUPE_USER_ROW;
BEGIN
	Setup1;

	--we dont expect a user to have been created but still we expect a processed
	--record for the staging user data with a missing full_name error
	AddCompanyStaging(
		in_company_id => '55555',
		in_country => 'gb',
		in_name => 'User import company Test mandatory',
		in_active => 1
	);

	v_raw_vals := BuildUserRow(
		in_username => v_username,
		in_active => 1
	);

	AddUserStaging(
		in_company_id	=> '55555',
		in_raw_vals		=> v_raw_vals
	);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id => v_source_id,
		in_reference => '55555',
		out_processed_record_ids => v_processed_record_ids
	);

	v_company_1_sid := GetNewCompany(v_processed_record_ids(1), NULL, 'User import company Test mandatory');

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = v_processed_record_ids(2)
	   AND imported_user_sid IS NULL;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Expected a processed record with an empty imported user');

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = v_processed_record_ids(2)
	   AND error_message IS NOT NULL
	   AND dedupe_field_id  = chain_pkg.FLD_USER_FULL_NAME;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Expected a merge error log for full_name');

	--now the user should be created
	AddCompanyStaging(
		in_company_id => '55555',
		in_country => 'gb',
		in_name => 'User import company Test mandatory',
		in_active => 1,
		in_batch_num => 2
	);

	v_raw_vals := BuildUserRow(
		in_username => v_username,
		in_fullname => v_fullname,
		in_active => 1
	);

	AddUserStaging(
		in_company_id => '55555',
		in_batch_num => 2,
		in_raw_vals => v_raw_vals
	);

	v_user_old	:= GetCurrentRow(v_username);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id => v_source_id,
		in_reference => '55555',
		in_batch_num => 2,
		out_processed_record_ids => v_processed_record_ids
	);

	v_company_sid := GetUpdatedCompany(v_processed_record_ids(1), 2);

	--create expected record set and validate
	v_expected_data := BuildExpectedRow(v_raw_vals, v_user_old);

	ValidateUserData(v_username, v_user_old, v_expected_data);
	ValidateUserCompanyMembership(v_username, T_NUMBER_LIST(v_company_1_sid));
	ValidateMergeLog(v_processed_record_ids(2), v_user_old, v_raw_vals);
END;

PROCEDURE INTERNAL_CmsAndUserImport (
	in_manual_review			NUMBER
)
AS
	v_company_1_sid				NUMBER;
	v_company_1_id 				VARCHAR2(20) := '66666666';
	v_username 					VARCHAR2(256) DEFAULT 'MMcKensie';
	v_user_old 		T_DEDUPE_USER_ROW;
	v_import_user_expected		T_DEDUPE_USER_ROW;
	v_processed_record_ids		security_pkg.T_SID_IDS;
	v_child_record_ids			security_pkg.T_SID_IDS;
	v_cms_company_staging_id	security_pkg.T_SID_ID;
	v_raw_values 				T_DEDUPE_USER_ROW;
	v_cms_record_ids 			security_pkg.T_SID_IDS;
	v_sales_org_id 				NUMBER;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	Setup2;

	IF in_manual_review = 1 THEN
		UPDATE import_source
		   SET dedupe_no_match_action_id = chain_pkg.MANUAL_REVIEW
		 WHERE import_source_id = v_source_id;
	END IF;

	-- Add a company import source
	AddCompanyStaging(
		in_company_id => v_company_1_id,
		in_country => 'gb',
		in_name => 'Widden Pallets',
		in_active => 1
	);

	AddStagingRow(
		in_company_id	=> v_company_1_id,
		in_name			=> 'Widden Pallets',
		in_country		=> 'it',
		in_ref_1		=> 'WP',
		in_ref_2		=> 'WP 2'
	);

	-- Add user child data
	v_raw_values := BuildUserRow(
		in_username => v_username,
		in_email => 'Milds@widden.com',
		in_fullname => 'Mildred McKensie',
		in_active => 1
	);

	AddUserStaging(
		in_company_id	=> v_company_1_id,
		in_raw_vals		=> v_raw_values
	);

	-- Add child cms
	AddChildCmsStagingRow(
		in_company_id				=> v_company_1_id,
		in_sales_org				=> 'E-Commerce',
		in_merch_cat				=> 'R5440 APPLES/PEARS',
		in_cms_company_staging_id	=> v_cms_company_staging_id,
		in_started_by				=> v_username,
		in_revenue					=> 500,
		in_batch_num 				=> NULL,
		in_started_date				=> DATE '2012-01-12',
		in_comments					=> 'Apples and pears on a WIDDEN PALLET!'
	);

	v_user_old := GetCurrentRow(v_username);

	-- Process records
	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id => v_source_id,
		in_reference => v_company_1_id,
		in_batch_num => NULL,
		in_force_re_eval => 0,
		out_processed_record_ids => v_processed_record_ids
	);

	-- Test to see if the new company was created
	v_company_1_sid := GetNewCompany(
		in_processed_record_id => v_processed_record_ids(1),
		in_batch_num => NULL,
		in_company_name => 'Widden Pallets'
	);

	IF in_manual_review = 0 THEN
		IF v_company_1_sid IS NULL THEN
			csr.unit_test_pkg.TestFail('Expected chain company to have been created');
		END IF;
	ELSE
		IF v_company_1_sid IS NOT NULL THEN
			csr.unit_test_pkg.TestFail('Expected chain company to require manual review before creation');
		END IF;

		company_dedupe_pkg.MergeRecord(
			in_processed_record_id => v_processed_record_ids(1),
			in_company_sid => NULL,
			out_child_proc_record_ids => v_child_record_ids);

		IF v_child_record_ids IS NOT NULL AND v_child_record_ids.COUNT > 0 THEN
			FOR i IN v_child_record_ids.FIRST .. v_child_record_ids.LAST
			LOOP
				v_processed_record_ids(v_processed_record_ids.COUNT + 1) := v_child_record_ids(i);
			END LOOP;
		END IF;

		v_company_1_sid := GetNewCompany(
			in_processed_record_id => v_processed_record_ids(1),
			in_batch_num => NULL,
			in_company_name => 'Widden Pallets'
		);

		IF v_company_1_sid IS NULL THEN
			csr.unit_test_pkg.TestFail('Expected chain company to have been created');
		END IF;
	END IF;

	--create expected record set and validate
	v_import_user_expected	:= BuildExpectedRow(v_raw_values, v_user_old);

	ValidateUserData(v_username, v_user_old, v_import_user_expected);
	ValidateUserCompanyMembership(v_username, T_NUMBER_LIST(v_company_1_sid), 1);
	ValidateMergeLog(v_processed_record_ids(2), v_user_old, v_raw_values);

	SELECT cms_record_id
	  BULK COLLECT INTO v_cms_record_ids
	  FROM dedupe_processed_record
	 WHERE reference = v_company_1_id
	   AND data_merged = 1
	   AND batch_num IS NULL
	   AND iteration_num = 1
	   AND parent_processed_record_id = v_processed_record_ids(1)
	   AND matched_to_company_sid = v_company_1_sid
	   AND dedupe_processed_record_id = v_processed_record_ids(3)
	 ORDER BY dedupe_processed_record_id;

	csr.unit_test_pkg.AssertAreEqual(1, v_cms_record_ids.count, 'Not the expected count for the merged child processed record');

	BEGIN
		EXECUTE IMMEDIATE('
			SELECT sales_org_id
			  FROM rag.company_sales_org
			 WHERE company_sales_org_id = :1
		')
		 INTO v_sales_org_id
		USING v_cms_record_ids(1);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.unit_test_pkg.TestFail('Expected exactly one CMS company record');
		WHEN TOO_MANY_ROWS THEN
			csr.unit_test_pkg.TestFail('Expected exactly one CMS company record');
	END;

	csr.unit_test_pkg.AssertAreEqual(5, v_sales_org_id, 'Saved value for sales_org_id is not the expected one');
END;

PROCEDURE Test_CmsAndUserImport
AS
BEGIN
	INTERNAL_CmsAndUserImport(0);
END;

PROCEDURE Test_CmsAndUserImportManual
AS
BEGIN
	INTERNAL_CmsAndUserImport(1);
END;

PROCEDURE Test_PriorityFullFriendly
AS
	v_username				VARCHAR2(4000) DEFAULT 'colin_23';
	v_user_old			T_DEDUPE_USER_ROW;
	v_expected_data			T_DEDUPE_USER_ROW;
	v_raw_vals				T_DEDUPE_USER_ROW;
	v_processed_record_ids	security_pkg.T_SID_IDS;
	v_company_1_sid			NUMBER;
	v_count					NUMBER;
	v_user_sid				NUMBER;
BEGIN
	Setup3;

	--1st create a user
	AddCompanyStaging(
		in_company_id => '12345',
		in_country => 'gb',
		in_name => 'Colin''s Bakery',
		in_active => 1
	);

	--Dont set the active val. Still the user should be added as a member
	--full_name is not set but it should be set by concatenating first and last
	v_raw_vals := BuildUserRow(
		in_username => v_username,
		in_first_name	=> 'Jonathan',
		in_last_name	=> 'Lucas',
		in_friendly_name => 'Jon'
	);

	AddUserStaging(
		in_company_id => '12345',
		in_raw_vals => v_raw_vals
	);

	v_user_old	:= GetCurrentRow(v_username);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id => v_source_id,
		in_reference => '12345',
		out_processed_record_ids => v_processed_record_ids
	);

	v_company_1_sid := GetNewCompany(v_processed_record_ids(1), NULL, 'Colin''s Bakery');

	--create expected record set and validate
	v_expected_data := BuildExpectedRow(v_raw_vals, v_user_old);

	ValidateUserSid(v_username, v_user_sid);
	ValidateUserData(v_username, v_user_old, v_expected_data);
	ValidateUserCompanyMembership(v_username, T_NUMBER_LIST(v_company_1_sid));
	ValidateMergeLog(v_processed_record_ids(2), v_user_old, v_raw_vals);

	--Now try to update the user. That should be skipped as our import source has a lower priority than the system managed
	AddCompanyStaging(
		in_company_id 	=> '12345',
		in_country 		=> 'gb',
		in_name 		=> 'Colin''s Bakery',
		in_active 		=> 1,
		in_batch_num	=> 2
	);

	v_raw_vals := BuildUserRow(
		in_username 	=> v_username,
		in_first_name	=> 'Jonathan',
		in_last_name	=> 'Lucas',
		in_friendly_name => 'Jon',
		in_active 		=> 1
	);

	AddUserStaging(
		in_company_id 	=> '12345',
		in_batch_num	=> 2,
		in_raw_vals => v_raw_vals
	);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id => v_source_id,
		in_reference => '12345',
		in_batch_num => 2,
		out_processed_record_ids => v_processed_record_ids
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = v_processed_record_ids(2)
	   AND data_merged = 0
	   AND batch_num = 2
	   AND iteration_num = 1
	   AND imported_user_sid = v_user_sid;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong number of non merged processed records for the previously created user');

	--now descrease priority of system managed and re-val
	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id => v_source_id,
		in_reference => '12345',
		in_batch_num => 2,
		in_force_re_eval => 1,
		out_processed_record_ids => v_processed_record_ids
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = v_processed_record_ids(2)
	   AND data_merged = 1
	   AND batch_num = 2
	   AND iteration_num = 2 --2nd iteration of the same batch
	   AND imported_user_sid = v_user_sid;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Wrong number of merged processed records for the previously created user');
END;

PROCEDURE Test_CTRoles
AS
	v_username				VARCHAR2(4000) DEFAULT 'colin_23_new';
	v_user_old				T_DEDUPE_USER_ROW;
	v_expected_data			T_DEDUPE_USER_ROW;
	v_raw_vals				T_DEDUPE_USER_ROW;
	v_processed_record_ids	security_pkg.T_SID_IDS;
	v_company_1_sid			NUMBER;
	v_user_sid				NUMBER;
	v_roles					security.T_ORDERED_SID_TABLE DEFAULT security.T_ORDERED_SID_TABLE();
	v_val_changes			security.T_ORDERED_SID_TABLE DEFAULT security.T_ORDERED_SID_TABLE();
BEGIN
	SetupTestRole;

	--first create a company and an user
	AddCompanyStaging(
		in_company_id => '12345-54321a',
		in_country => 'gb',
		in_name => 'Colin''s Bakery',
		in_active => 1
	);

	v_raw_vals := BuildUserRow(
		in_username => v_username,
		in_first_name	=> 'Colin',
		in_last_name	=> 'Lucas',
		in_friendly_name => 'Colin'
	);

	AddUserStaging(
		in_company_id 	=> '12345-54321a',
		in_raw_vals 	=> v_raw_vals,
		in_has_role_1	=> 1,
		in_has_role_2	=> 1,
		in_has_role_3	=> 0
	);

	--create expected roles dataset
	v_roles.extend;
	v_roles(v_roles.count) := security.T_ORDERED_SID_ROW(v_role_sid_1, 1); /* sid_id, pos => role_sid, enabled*/
	v_roles.extend;
	v_roles(v_roles.count) := security.T_ORDERED_SID_ROW(v_role_sid_2, 1);
	v_roles.extend;
	v_roles(v_roles.count) := security.T_ORDERED_SID_ROW(v_role_sid_3, 0);

	--we only log the first two
	v_val_changes.extend;
	v_val_changes(v_val_changes.count) := security.T_ORDERED_SID_ROW(1,0); /* sid_id, pos => new_val, old_val*/
	v_val_changes.extend;
	v_val_changes(v_val_changes.count) := security.T_ORDERED_SID_ROW(1,0);

	v_user_old	:= GetCurrentRow(v_username);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id => v_source_id,
		in_reference => '12345-54321a',
		out_processed_record_ids => v_processed_record_ids
	);

	v_company_1_sid := GetNewCompany(v_processed_record_ids(1), NULL, 'Colin''s new Bakery');

	--create expected record set and validate
	v_expected_data := BuildExpectedRow(v_raw_vals, v_user_old);

	ValidateUserSid(v_username, v_user_sid);
	ValidateUserData(v_username, v_user_old, v_expected_data);
	ValidateUserCompanyMembership(v_username, T_NUMBER_LIST(v_company_1_sid));
	ValidateMergeLog(v_processed_record_ids(2), v_user_old, v_raw_vals);
	ValidateRRM(v_processed_record_ids(2), v_roles, v_val_changes);

	--new test case:
	--Second batch, remove/add roles. It will not update the roles as the source priority is lower than the system managed
	AddCompanyStaging(
		in_company_id => '12345-54321a',
		in_country => 'gb',
		in_name => 'Colin''s Bakery',
		in_active => 1,
		in_batch_num	=> 2
	);

	AddUserStaging(
		in_company_id 	=> '12345-54321a',
		in_raw_vals 	=> v_raw_vals,
		in_has_role_1	=> 0,--changed
		in_has_role_2	=> 1,
		in_has_role_3	=> 1, --changed
		in_batch_num	=> 2
	);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id => v_source_id,
		in_reference => '12345-54321a',
		in_batch_num	=> 2,
		out_processed_record_ids => v_processed_record_ids
	);

	--we leave the roles record set unchanged and expect no changes
	v_val_changes := security.T_ORDERED_SID_TABLE();
	ValidateRRM(v_processed_record_ids(2), v_roles, v_val_changes);

	--...however now we lower the system source priority so we expect an update
	UPDATE import_source
	   SET position = 99
	 WHERE is_owned_by_system = 1;

	v_roles := security.T_ORDERED_SID_TABLE();
	v_roles.extend;
	v_roles(v_roles.count) := security.T_ORDERED_SID_ROW(v_role_sid_1, 0); /* sid_id, pos => role_sid, enabled*/
	v_roles.extend;
	v_roles(v_roles.count) := security.T_ORDERED_SID_ROW(v_role_sid_2, 1);
	v_roles.extend;
	v_roles(v_roles.count) := security.T_ORDERED_SID_ROW(v_role_sid_3, 1);

	v_val_changes	:= 	security.T_ORDERED_SID_TABLE();
	v_val_changes.extend;
	v_val_changes(1) :=  security.T_ORDERED_SID_ROW(0, 1);
	v_val_changes.extend;
	v_val_changes(2) :=  NULL; --no change happened
	v_val_changes.extend;
	v_val_changes(3) :=  security.T_ORDERED_SID_ROW(1, 0);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id => v_source_id,
		in_reference => '12345-54321a',
		in_batch_num	=> 2,
		in_force_re_eval	=> 1, --needed re-eavl for this batch num
		out_processed_record_ids => v_processed_record_ids
	);

	ValidateRRM(v_processed_record_ids(2), v_roles, v_val_changes);
END;

PROCEDURE Test_CTRoles2
AS
	v_username_1			VARCHAR2(4000) DEFAULT 'kevinj';
	v_username_2			VARCHAR2(4000) DEFAULT 'markm';
	v_username_3			VARCHAR2(4000) DEFAULT 'amyw';

	v_user_old_1			T_DEDUPE_USER_ROW;
	v_expected_data_1		T_DEDUPE_USER_ROW;
	v_raw_vals_1			T_DEDUPE_USER_ROW;

	v_user_old_2			T_DEDUPE_USER_ROW;
	v_expected_data_2		T_DEDUPE_USER_ROW;
	v_raw_vals_2			T_DEDUPE_USER_ROW;

	v_user_old_3			T_DEDUPE_USER_ROW;
	v_expected_data_3		T_DEDUPE_USER_ROW;
	v_raw_vals_3			T_DEDUPE_USER_ROW;

	v_processed_record_ids	security_pkg.T_SID_IDS;

	v_company_1_sid			NUMBER;
	v_company_2_sid			NUMBER;
	v_count					NUMBER;

	v_user_sid_1			NUMBER;

	v_roles_1				security.T_ORDERED_SID_TABLE DEFAULT security.T_ORDERED_SID_TABLE();
	v_val_changes_1			security.T_ORDERED_SID_TABLE DEFAULT security.T_ORDERED_SID_TABLE();
	v_roles_2				security.T_ORDERED_SID_TABLE DEFAULT security.T_ORDERED_SID_TABLE();
	v_val_changes_2			security.T_ORDERED_SID_TABLE DEFAULT security.T_ORDERED_SID_TABLE();
	v_roles_3				security.T_ORDERED_SID_TABLE DEFAULT security.T_ORDERED_SID_TABLE();
	v_val_changes_3			security.T_ORDERED_SID_TABLE DEFAULT security.T_ORDERED_SID_TABLE();

	v_other_comp_role_cnt	security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
BEGIN
	SetupTestRole;

	--create 2 companies ...
	AddCompanyStaging(
		in_company_id => 'abc123',
		in_country => 'gb',
		in_name => 'Cambridge Solicitors',
		in_active => 1
	);

	AddCompanyStaging(
		in_company_id => 'abc456',
		in_country => 'gb',
		in_name => ' Fresh Flowers',
		in_active => 1
	);

	--...and 3 users (first 2 for the 1st company and the 3rd for both)
	v_raw_vals_1 := BuildUserRow(
		in_username => v_username_1,
		in_first_name	=> 'Kevin',
		in_last_name	=> 'Janison',
		in_friendly_name => 'Kev'
	);

	AddUserStaging(
		in_company_id 	=> 'abc123',
		in_raw_vals 	=> v_raw_vals_1,
		in_has_role_1	=> 1,
		in_has_role_2	=> 0,
		in_has_role_3	=> NULL
	);

	--2nd
	v_raw_vals_2 := BuildUserRow(
		in_username => v_username_2,
		in_first_name	=> 'Mark',
		in_last_name	=> 'Mass'
	);

	AddUserStaging(
		in_company_id 	=> 'abc123',
		in_raw_vals 	=> v_raw_vals_2,
		in_has_role_1	=> 0,
		in_has_role_2	=> NULL,
		in_has_role_3	=> 1
	);

	--3rd
	v_raw_vals_3 := BuildUserRow(
		in_username => v_username_3,
		in_first_name	=> 'Amy',
		in_last_name	=> 'Peacock'
	);

	AddUserStaging(
		in_company_id 	=> 'abc456',
		in_raw_vals 	=> v_raw_vals_3,
		in_has_role_1	=> 0,
		in_has_role_2	=> 1,
		in_has_role_3	=> 1
	);

	AddUserStaging(
		in_company_id 	=> 'abc123',
		in_raw_vals 	=> v_raw_vals_3,
		in_has_role_1	=> 1,
		in_has_role_2	=> 0,
		in_has_role_3	=> 1,
		in_has_role_na	=> 1 --that should trigger an error log
	);

	--create expected roles dataset
	v_roles_1.extend;
	v_roles_1(1) := security.T_ORDERED_SID_ROW(v_role_sid_1, 1); /* sid_id, pos => role_sid, enabled*/
	v_roles_1.extend;
	v_roles_1(2) := security.T_ORDERED_SID_ROW(v_role_sid_2, 0);

	v_val_changes_1.extend;
	v_val_changes_1(1) := security.T_ORDERED_SID_ROW(1,0); /* sid_id, pos => new_val, old_val*/

	v_user_old_1	:= GetCurrentRow(v_username_1);

	v_roles_2.extend;
	v_roles_2(1) := security.T_ORDERED_SID_ROW(v_role_sid_1, 0); /* sid_id, pos => role_sid, enabled*/
	v_roles_2.extend;
	v_roles_2(2) := security.T_ORDERED_SID_ROW(v_role_sid_2, 0);
	v_roles_2.extend;
	v_roles_2(3) := security.T_ORDERED_SID_ROW(v_role_sid_3, 1);

	v_val_changes_2.extend;
	v_val_changes_2(1) := NULL; /* sid_id, pos => new_val, old_val*/
	v_val_changes_2.extend;
	v_val_changes_2(2) := NULL;
	v_val_changes_2.extend;
	v_val_changes_2(3) := security.T_ORDERED_SID_ROW(1, 0);

	v_roles_3.extend;
	v_roles_3(1) := security.T_ORDERED_SID_ROW(v_role_sid_1, 1); /* sid_id, pos => role_sid, enabled*/
	v_roles_3.extend;
	v_roles_3(2) := security.T_ORDERED_SID_ROW(v_role_sid_2, 0);
	v_roles_3.extend;
	v_roles_3(3) := security.T_ORDERED_SID_ROW(v_role_sid_3, 1);

	v_val_changes_3.extend;
	v_val_changes_3(1) := security.T_ORDERED_SID_ROW(1, 0); /* sid_id, pos => new_val, old_val*/
	v_val_changes_3.extend;
	v_val_changes_3(2) := NULL;
	v_val_changes_3.extend;
	v_val_changes_3(3) := security.T_ORDERED_SID_ROW(1, 0);

	v_user_old_1	:= GetCurrentRow(v_username_1);
	v_user_old_2	:= GetCurrentRow(v_username_2);
	v_user_old_3	:= GetCurrentRow(v_username_3);

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id => v_source_id,
		in_reference => 'abc123',
		out_processed_record_ids => v_processed_record_ids
	);

	v_company_1_sid := GetNewCompany(v_processed_record_ids(1), NULL, 'Cambridge Solicitors');

	--create expected record set and validate
	v_expected_data_1 := BuildExpectedRow(v_raw_vals_1, v_user_old_1);

	ValidateUserSid(v_username_1, v_user_sid_1);
	ValidateUserData(v_username_1, v_user_old_1, v_expected_data_1);
	ValidateUserCompanyMembership(v_username_1, T_NUMBER_LIST(v_company_1_sid));
	ValidateMergeLog(v_processed_record_ids(2), v_user_old_1, v_raw_vals_1);
	ValidateRRM(v_processed_record_ids(2), v_roles_1, v_val_changes_1);

	v_expected_data_2 := BuildExpectedRow(v_raw_vals_2, v_user_old_2);

	ValidateUserSid(v_username_2, v_user_sid_2);
	ValidateUserData(v_username_2, v_user_old_2, v_expected_data_2);
	ValidateUserCompanyMembership(v_username_2, T_NUMBER_LIST(v_company_1_sid));
	ValidateMergeLog(v_processed_record_ids(3), v_user_old_2, v_raw_vals_2);
	ValidateRRM(v_processed_record_ids(3), v_roles_2, v_val_changes_2);

	v_expected_data_3 := BuildExpectedRow(v_raw_vals_3, v_user_old_3);

	ValidateUserSid(v_username_3, v_user_sid_3);
	ValidateUserData(v_username_3, v_user_old_3, v_expected_data_3);
	ValidateUserCompanyMembership(v_username_3, T_NUMBER_LIST(v_company_1_sid));
	ValidateMergeLog(v_processed_record_ids(4), v_user_old_3, v_raw_vals_3);
	ValidateRRM(v_processed_record_ids(4), v_roles_3, v_val_changes_3);

	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE role_sid = v_role_sid_na
	   AND dedupe_processed_record_id = v_processed_record_ids(4)
	   AND error_message IS NOT NULL;

	csr.unit_test_pkg.AssertAreEqual(1, v_count, 'Expected an error message logged for a non applicable role');

	--now process the 2nd company. 3rd user is an expected member
	--build the new data set of roles for the 3rd user
	--we dont need to change the system source priority for setting roles/applying membership for a new company
	v_roles_3 := security.T_ORDERED_SID_TABLE();
	v_roles_3.extend;
	v_roles_3(1) := security.T_ORDERED_SID_ROW(v_role_sid_1, 0); /* sid_id, pos => role_sid, enabled*/
	v_roles_3.extend;
	v_roles_3(2) := security.T_ORDERED_SID_ROW(v_role_sid_2, 1);
	v_roles_3.extend;
	v_roles_3(3) := security.T_ORDERED_SID_ROW(v_role_sid_3, 1);

	v_val_changes_3 := security.T_ORDERED_SID_TABLE();
	v_val_changes_3.extend;
	v_val_changes_3(1) := NULL; /* sid_id, pos => new_val, old_val*/
	v_val_changes_3.extend;
	v_val_changes_3(2) := security.T_ORDERED_SID_ROW(1, 0);
	v_val_changes_3.extend;
	v_val_changes_3(3) := security.T_ORDERED_SID_ROW(1, 0);

	v_user_old_3 := GetCurrentRow(v_username_3);

	v_other_comp_role_cnt := security.T_SID_TABLE();
	v_other_comp_role_cnt.extend;
	v_other_comp_role_cnt(1) := GetRegionRoleCounts(v_user_sid_3, v_role_sid_1, T_NUMBER_LIST()); -- not created company 2 yet
	v_other_comp_role_cnt.extend;
	v_other_comp_role_cnt(2) := GetRegionRoleCounts(v_user_sid_3, v_role_sid_2, T_NUMBER_LIST()); -- not created company 2 yet
	v_other_comp_role_cnt.extend;
	v_other_comp_role_cnt(3) := GetRegionRoleCounts(v_user_sid_3, v_role_sid_3, T_NUMBER_LIST()); -- not created company 2 yet

	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id => v_source_id,
		in_reference => 'abc456',
		out_processed_record_ids => v_processed_record_ids
	);

	v_company_2_sid := GetNewCompany(v_processed_record_ids(1), NULL, 'Fresh Flowers');
	--security_pkg.debugmsg('v_company_2_sid ' || v_company_2_sid);

	ValidateUserSid(v_username_3, v_user_sid_3);
	ValidateUserData(v_username_3, v_user_old_3, v_expected_data_3);
	ValidateUserCompanyMembership(v_username_3, T_NUMBER_LIST(v_company_1_sid, v_company_2_sid));
	ValidateMergeLog(v_processed_record_ids(2), v_user_old_3, v_raw_vals_3);
	ValidateRRM(v_processed_record_ids(2), v_roles_3, v_val_changes_3);
	ValidateRRMInverse(v_user_sid_3, T_NUMBER_LIST(v_role_sid_1, v_role_sid_2, v_role_sid_3), T_NUMBER_LIST(csr.supplier_pkg.GetRegionSid(v_company_2_sid)), v_other_comp_role_cnt);

END;

PROCEDURE Test_ImportUserNowAnonymised
AS
	v_user_sid					NUMBER;
	v_name						VARCHAR2(20) 	:= 'Kate Ryes';
	v_user_ref					VARCHAR2(128)	:= '123';
	v_test_user_ref				VARCHAR2(128);
	v_profile_count				NUMBER;

	v_company_id				VARCHAR2(20) := '11111111';
	v_company_sid				NUMBER;

	v_import_user_username		VARCHAR2(20) DEFAULT  'impUser1';
	v_user_old					T_DEDUPE_USER_ROW;
	v_raw_vals					T_DEDUPE_USER_ROW;
	v_import_user_expected		T_DEDUPE_USER_ROW;

	v_processed_record_ids		security_pkg.T_SID_IDS;
BEGIN
	security.user_pkg.logonadmin(v_site_name);

	v_user_sid := csr.unit_test_pkg.GetOrCreateUserAndProfile(v_user_ref, v_name, v_name, v_name||'@credit360.com', null, null, null, null, null, null);
	SetupSource1;

	SELECT COUNT(*)
	  INTO v_profile_count
	 FROM csr.user_profile
	WHERE app_sid = security.security_pkg.GetApp
	  AND csr_user_sid = v_user_sid;
	csr.unit_test_pkg.AssertAreEqual(1, v_profile_count, 'User Profile not created correctly');

	SELECT user_ref
	  INTO v_test_user_ref
	  FROM csr.csr_user
	 WHERE app_sid = security.security_pkg.GetApp
	   AND csr_user_sid = v_user_sid;
	csr.unit_test_pkg.AssertAreEqual('123', v_test_user_ref, 'User Reference not populated correctly');

	csr.unit_test_pkg.DeactivateUser(v_user_sid);
	csr.unit_test_pkg.AnonymiseUser(v_user_sid);

	SELECT COUNT(*)
	  INTO v_profile_count
	 FROM csr.user_profile
	WHERE app_sid = security.security_pkg.GetApp
	  AND csr_user_sid = v_user_sid;
	csr.unit_test_pkg.AssertAreEqual(0, v_profile_count, 'User Profile not deleted correctly');

	SELECT user_ref
	  INTO v_test_user_ref
	  FROM csr.csr_user
	 WHERE app_sid = security.security_pkg.GetApp
	   AND csr_user_sid = v_user_sid;
	csr.unit_test_pkg.AssertIsNull(v_test_user_ref, 'User Reference not cleared correctly');

	-- At this point we've:
	-- 1. Created a user that had a user profile and a user reference
	-- 2. Anonymised that user, which has deleted that user profile and cleared the user reference
	-- Our next step is now to try import a new user import using that same user reference and
	-- make sure the user and profile are created fine

	-- Create Company
	AddCompanyStaging(
		in_company_id => v_company_id,
		in_country => 'gb',
		in_name => 'User import company 1',
		in_active => 1,
		in_batch_num => 1
	);

	-- Create User
	v_raw_vals := BuildUserRow(
		in_username => v_import_user_username,
		in_email => 'imp1@rrrr.com',
		in_fullname => 'imp user 1',
		in_first_name => 'Imp',
		in_last_name => 'User 1 xx',
		in_friendly_name => 'Impy',
		in_phone_num => '3453409809',
		in_job => 'PM',
		in_created_dtm => DATE '2012-1-1',
		in_user_ref => '1111',
		in_active => 1
	);

	AddUserStaging(
		in_company_id	=> 	v_company_id,
		in_raw_vals		=> 	v_raw_vals,
		in_batch_num	=> 1
	);

	v_user_old := GetCurrentRow(v_import_user_username);

	-- Process
	company_dedupe_pkg.ProcessParentStagingRecord(
		in_import_source_id => v_source_id,
		in_reference => v_company_id,
		in_batch_num => 1,
		in_force_re_eval => 0,
		out_processed_record_ids => v_processed_record_ids
	);

	v_company_sid := GetNewCompany(v_processed_record_ids(1), 1, 'Company 1');

	-- Create expected record set and validate
	v_import_user_expected := BuildExpectedRow(v_raw_vals, v_user_old);

	ValidateProcessedRecord(v_processed_record_ids(2), v_company_sid);
	ValidateUserData(v_import_user_username, v_user_old, v_import_user_expected);
	ValidateUserCompanyMembership(v_import_user_username, T_NUMBER_LIST(v_company_sid));
	ValidateMergeLog(v_processed_record_ids(2), v_user_old, v_raw_vals);
END;

END;
/
