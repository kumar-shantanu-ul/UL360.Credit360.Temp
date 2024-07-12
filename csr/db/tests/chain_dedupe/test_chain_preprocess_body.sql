CREATE OR REPLACE PACKAGE BODY chain.test_chain_preprocess_pkg AS

v_site_name		VARCHAR2(200);
v_vendor_ct_id	NUMBER;
v_alt_comp_name_id	NUMBER;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);

	test_chain_utils_pkg.SetupTwoTier;
	
	--do some clearing just in case
	UPDATE customer_options
	   SET enable_dedupe_preprocess = 0
	 WHERE app_sid = security_pkg.getapp;
	 
	DELETE FROM dedupe_pp_field_cntry;
	DELETE FROM dedupe_preproc_rule;
	
	v_vendor_ct_id := company_type_pkg.GetCompanyTypeId('VENDOR');
	v_alt_comp_name_id := alt_company_name_id_seq.NEXTVAL;
END;

PROCEDURE TearDownFixture
AS
BEGIN
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
	UPDATE customer_options
	   SET enable_dedupe_preprocess = 0
	 WHERE app_sid = security_pkg.getapp;
	 
	DELETE FROM dedupe_pp_field_cntry;
	DELETE FROM dedupe_preproc_rule;
	
END;


PROCEDURE Test_Output
AS
	v_company_sid		NUMBER;
	v_norm_val			VARCHAR2(255);
	v_dedupe_preproc_rule_id	NUMBER;
	v_dedupe_field_ids	security_pkg.T_SID_IDS;
	v_countries			security_pkg.T_VARCHAR2_ARRAY;
	
	v_comp_name			company.name%TYPE DEFAULT 'Eco-Products, Inc - BENZSTRA'||chr(50079)||'E';--use eszet
	v_expected_name		company.name%TYPE DEFAULT 'eco-products, inc - benzstrasse';--replaced with "SS" 
	
	v_comp_name_2		company.name%TYPE DEFAULT 'Best Florist (St   Ives)';--brackets
	v_expected_name_2	company.name%TYPE DEFAULT 'best florist st ives';--removed brackets and extra spaces
	
	v_comp_name_3		company.name%TYPE DEFAULT 'Caf'||chr(50089)||' d''art';
	v_expected_name_3	company.name%TYPE DEFAULT 'cafe d art';--replaced accent, replaced single quote with space
	v_postcode_3		company.postcode%TYPE DEFAULT '(Z32) 55';
	v_exp_postcode_3	company.postcode%TYPE DEFAULT 'z32 55';
	
	v_comp_name_4			company.name%TYPE DEFAULT 'ACME Co.';
	v_expected_name_4		company.name%TYPE DEFAULT 'acme co.';
	v_alt_comp_name_4		alt_company_name.name%TYPE DEFAULT 'ACME Company';
	v_exp_alt_comp_name_4	alt_company_name.name%TYPE DEFAULT 'acme company';
BEGIN
	security.user_pkg.logonadmin(v_site_name);
	--config some preprocess rules
	UPDATE customer_options
	   SET enable_dedupe_preprocess = 1
	 WHERE app_sid = security_pkg.getapp;
	
	dedupe_admin_pkg.SavePreProcRule(
		in_dedupe_preproc_rule_id 	=> NULL,
		in_pattern					=> chr(50079), --eszet
		in_replacement				=> 'ss',
		in_run_order				=> 1,
		in_dedupe_field_ids			=> v_dedupe_field_ids,
		in_countries				=> v_countries,
		out_dedupe_preproc_rule_id	=> v_dedupe_preproc_rule_id
	);
	
	v_dedupe_field_ids(1) := chain_pkg.FLD_COMPANY_NAME;
	v_dedupe_field_ids(2) := chain_pkg.FLD_COMPANY_POSTCODE;
	
	dedupe_admin_pkg.SavePreProcRule(
		in_dedupe_preproc_rule_id 	=> NULL,
		in_pattern					=> '[()]',
		in_replacement				=> '',
		in_run_order				=> 2,
		in_dedupe_field_ids			=> v_dedupe_field_ids,
		in_countries				=> v_countries,
		out_dedupe_preproc_rule_id	=> v_dedupe_preproc_rule_id
	);
	
	v_dedupe_field_ids.delete;
	
	dedupe_admin_pkg.SavePreProcRule(
		in_dedupe_preproc_rule_id 	=> NULL,
		in_pattern					=> '['']',
		in_replacement				=> ' ',
		in_run_order				=> 3,
		in_dedupe_field_ids			=> v_dedupe_field_ids,
		in_countries				=> v_countries,
		out_dedupe_preproc_rule_id	=> v_dedupe_preproc_rule_id
	);
	
	dedupe_admin_pkg.SavePreProcRule(
		in_dedupe_preproc_rule_id 	=> NULL,
		in_pattern					=> chr(50089), --e accented
		in_replacement				=> 'e',
		in_run_order				=> 4,
		in_dedupe_field_ids			=> v_dedupe_field_ids,
		in_countries				=> v_countries,
		out_dedupe_preproc_rule_id	=> v_dedupe_preproc_rule_id
	);
	
	dedupe_admin_pkg.SavePreProcRule(
		in_dedupe_preproc_rule_id 	=> NULL,
		in_pattern					=> '[[:space:]]+',
		in_replacement				=> ' ',
		in_run_order				=> 5,
		in_dedupe_field_ids			=> v_dedupe_field_ids,
		in_countries				=> v_countries,
		out_dedupe_preproc_rule_id	=> v_dedupe_preproc_rule_id
	);	
	
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> v_comp_name, 
		in_country_code=> 'de',
		in_company_type_id=> v_vendor_ct_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid
	);
	
	--do the preprocess
	dedupe_preprocess_pkg.PreprocessCompany(v_company_sid);
	
	SELECT name
	  INTO v_norm_val
	  FROM dedupe_preproc_comp
	 WHERE app_sid = security_pkg.getapp
	   AND company_sid = v_company_sid;

	csr.unit_test_pkg.AssertAreEqual(v_expected_name, v_norm_val, 'Wrong normalised value for company name');
	
	--######################################
	--2nd case
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> v_comp_name_2, 
		in_country_code=> 'de',
		in_company_type_id=> v_vendor_ct_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid
	);
	
	--do the preprocess
	dedupe_preprocess_pkg.PreprocessCompany(v_company_sid);
	
	SELECT name
	  INTO v_norm_val
	  FROM dedupe_preproc_comp
	 WHERE app_sid = security_pkg.getapp
	   AND company_sid = v_company_sid;

	csr.unit_test_pkg.AssertAreEqual(v_expected_name_2, v_norm_val, 'Wrong normalised value for company name');
	
	--######################################
	--3rd case
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> v_comp_name_3, 
		in_country_code=> 'de',
		in_company_type_id=> v_vendor_ct_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid
	);
	
	UPDATE company
	   SET postcode = v_postcode_3
	 WHERE company_sid = v_company_sid;
	 
	--do the preprocess
	dedupe_preprocess_pkg.PreprocessCompany(v_company_sid);
	
	SELECT name
	  INTO v_norm_val
	  FROM dedupe_preproc_comp
	 WHERE app_sid = security_pkg.getapp
	   AND company_sid = v_company_sid;

	csr.unit_test_pkg.AssertAreEqual(v_expected_name_3, v_norm_val, 'Wrong normalised value for company name');
	
	SELECT postcode
	  INTO v_norm_val
	  FROM dedupe_preproc_comp
	 WHERE app_sid = security_pkg.getapp
	   AND company_sid = v_company_sid;

	csr.unit_test_pkg.AssertAreEqual(v_exp_postcode_3, v_norm_val, 'Wrong normalised value for company post code');

	--######################################
	--4th case
	test_chain_utils_pkg.CreateCompanyHelper(
		in_name=> v_comp_name_4, 
		in_country_code=> 'gb',
		in_company_type_id=> v_vendor_ct_id,
		in_sector_id=> NULL,
		out_company_sid=> v_company_sid
	);

	company_pkg.savealtcompanyname(v_alt_comp_name_id, v_company_sid, v_alt_comp_name_4);

	--do the preprocess
	dedupe_preprocess_pkg.PreprocessCompany(v_company_sid);

	SELECT name
	  INTO v_norm_val
	  FROM dedupe_preproc_comp
	 WHERE app_sid = security_pkg.getapp
	   AND company_sid = v_company_sid;

	csr.unit_test_pkg.AssertAreEqual(v_expected_name_4, v_norm_val, 'Wrong normalised value for company name');

	SELECT name
	  INTO v_norm_val
	  FROM dedupe_pp_alt_comp_name
	 WHERE app_sid = security_pkg.getapp
	   AND company_sid = v_company_sid
	   AND alt_company_name_id = v_alt_comp_name_id;

	csr.unit_test_pkg.AssertAreEqual(v_exp_alt_comp_name_4, v_norm_val, 'Wrong normalised value for company post code');
END;

END;
/
