CREATE OR REPLACE PACKAGE chain.test_chain_shared_dedupe_pkg AS

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
);

-- TO DO - refactor this out once merged with ChrisR branch US6960
-- moved to chain.test_chain_shared_dedupe_pkg
PROCEDURE CreateSimpleImportSource(
	in_no_match_action_id		NUMBER,
	out_import_source_id		OUT NUMBER
);

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
);

PROCEDURE TestPotentialMatches(
	in_processed_record_id		NUMBER,
	in_expected_company_sids	T_NUMBER_LIST,
	in_rule_set_id				NUMBER DEFAULT NULL
);

END;
/