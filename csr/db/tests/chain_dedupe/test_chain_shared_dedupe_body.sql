CREATE OR REPLACE PACKAGE BODY chain.test_chain_shared_dedupe_pkg AS

-- uses the staging table in create_shared_staging 

PROCEDURE AddStagingRow(
	in_vendor_num		IN VARCHAR2,
	in_vendor_name		IN VARCHAR2,
	in_city				IN VARCHAR2 DEFAULT NULL,
	in_country			IN VARCHAR2 DEFAULT NULL,
	in_postal_code		IN VARCHAR2 DEFAULT NULL,
	in_street			IN VARCHAR2 DEFAULT NULL,
	in_state			IN VARCHAR2 DEFAULT NULL,
	in_website			IN VARCHAR2 DEFAULT NULL,
	in_facility_type	IN VARCHAR2 DEFAULT NULL,
	in_email			IN VARCHAR2 DEFAULT NULL
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
			email
		)
		VALUES(
			cms.item_id_seq.nextval,
			:1,:2,:3,:4,:5,:6,:7,:8,:9,:10
		)'
	)
	USING in_vendor_num, in_vendor_name, in_city, in_postal_code, in_street,
	in_country, in_state, in_website, in_facility_type, in_email;
END;

-- TO DO - refactor this out once merged with ChrisR branch US6960
-- moved to chain.test_chain_shared_dedupe_pkg
PROCEDURE CreateSimpleImportSource(
	in_no_match_action_id		NUMBER,
	out_import_source_id		OUT NUMBER
)
AS
BEGIN
	dedupe_admin_pkg.SaveImportSource(
		in_import_source_id => -1,
		in_name => 'Simplest company integration',
		in_position => 1,
		in_no_match_action_id => in_no_match_action_id,
		in_lookup_key => 'COMPANY_DATA',
		out_import_source_id => out_import_source_id
	);
END;

-- TO DO - refactor this out once merged with ChrisR branch US6960
-- moved to chain.test_chain_shared_dedupe_pkg

PROCEDURE CreateSimpleLinkAndMappings (
	in_tab_sid						NUMBER,
	in_import_source_id				NUMBER, 
	out_staging_link_id				OUT NUMBER, 
	out_mapping_name_id				OUT NUMBER,
	out_mapping_city_id				OUT NUMBER,
	out_mapping_postcode_id			OUT NUMBER,
	out_mapping_address_id			OUT NUMBER,
	out_mapping_country_id			OUT NUMBER,
	out_mapping_state_id			OUT NUMBER,
	out_mapping_website_id			OUT NUMBER,
	out_mapping_comp_email_id		OUT NUMBER
) AS
BEGIN

	--set up staging link
	dedupe_admin_pkg.SaveStagingLink(
		in_dedupe_staging_link_id 		=> -1,
		in_import_source_id 			=> in_import_source_id,
		in_description 					=> 'Simplest company data integration',
		in_staging_tab_sid 				=> in_tab_sid,
		in_position 					=> 1,
		in_staging_id_col_sid 			=> cms.tab_pkg.GetColumnSid(in_tab_sid, 'VENDOR_NUM'),
		in_staging_batch_num_col_sid 	=> NULL,
		in_parent_staging_link_id 		=> NULL,
		in_destination_tab_sid 			=> NULL,
		out_dedupe_staging_link_id 		=> out_staging_link_id
	);

	--setup standard mappings
	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => out_staging_link_id,
		in_tab_sid => in_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(in_tab_sid, 'VENDOR_NAME'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_NAME,
		out_dedupe_mapping_id => out_mapping_name_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => out_staging_link_id,
		in_tab_sid => in_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(in_tab_sid, 'CITY'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_CITY,
		out_dedupe_mapping_id => out_mapping_city_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => out_staging_link_id,
		in_tab_sid => in_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(in_tab_sid, 'POSTAL_CODE'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_POSTCODE,
		out_dedupe_mapping_id => out_mapping_postcode_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => out_staging_link_id,
		in_tab_sid => in_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(in_tab_sid, 'STREET'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_ADDRESS,
		out_dedupe_mapping_id => out_mapping_address_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => out_staging_link_id,
		in_tab_sid => in_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(in_tab_sid, 'COUNTRY'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_COUNTRY,
		out_dedupe_mapping_id => out_mapping_country_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => out_staging_link_id,
		in_tab_sid => in_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(in_tab_sid, 'STATE'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_STATE,
		out_dedupe_mapping_id => out_mapping_state_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => out_staging_link_id,
		in_tab_sid => in_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(in_tab_sid, 'WEBSITE'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_WEBSITE,
		out_dedupe_mapping_id => out_mapping_website_id
	);

	dedupe_admin_pkg.SaveMapping(
		in_dedupe_mapping_id => -1,
		in_dedupe_staging_link_id => out_staging_link_id,
		in_tab_sid => in_tab_sid,
		in_col_sid => cms.tab_pkg.GetColumnSid(in_tab_sid, 'EMAIL'),
		in_dedupe_field_id	=> 	chain_pkg.FLD_COMPANY_EMAIL,
		out_dedupe_mapping_id => out_mapping_comp_email_id
	);

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

END;
/