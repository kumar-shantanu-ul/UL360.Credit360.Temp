CREATE OR REPLACE PACKAGE BODY CHAIN.dedupe_preprocess_pkg
IS

FUNCTION PreprocessRule(
	in_input_val			VARCHAR2,
	in_pattern				dedupe_preproc_rule.pattern%TYPE,
	in_replacement			dedupe_preproc_rule.replacement%TYPE
)RETURN VARCHAR2 DETERMINISTIC
AS
	v_subst_val	VARCHAR2(1000);
BEGIN
	v_subst_val := regexp_replace(LOWER(in_input_val), LOWER(in_pattern), LOWER(in_replacement));

	RETURN TRIM(LOWER(v_subst_val));
END;

PROCEDURE EvalPreprocessRule(
	in_pattern				dedupe_preproc_rule.pattern%TYPE,
	in_replacement			dedupe_preproc_rule.replacement%TYPE,
	in_dedupe_field_id		dedupe_field.dedupe_field_id%TYPE,
	in_out_company_row		IN OUT company%ROWTYPE
)
AS
	v_supported_ded_fd_ids	T_NUMBER_LIST := T_NUMBER_LIST(
		chain_pkg.FLD_COMPANY_NAME,
		chain_pkg.FLD_COMPANY_ADDRESS,
		chain_pkg.FLD_COMPANY_STATE,
		chain_pkg.FLD_COMPANY_POSTCODE,
		chain_pkg.FLD_COMPANY_WEBSITE,
		chain_pkg.FLD_COMPANY_EMAIL,
		chain_pkg.FLD_COMPANY_CITY);
	v_fld_to_process		T_NUMBER_LIST := T_NUMBER_LIST();
	v_alt_comp_name			VARCHAR2(255);
BEGIN
	IF in_dedupe_field_id IS NULL THEN
		v_fld_to_process := v_supported_ded_fd_ids;
	ELSIF in_dedupe_field_id MEMBER OF v_supported_ded_fd_ids THEN
		v_fld_to_process := T_NUMBER_LIST(in_dedupe_field_id);
	END IF;

	IF v_fld_to_process IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Preprocessing field with id:'||in_dedupe_field_id||' is not supported');
	END IF;

	FOR i IN v_fld_to_process.FIRST .. v_fld_to_process.LAST
	LOOP
		IF v_fld_to_process(i) = chain_pkg.FLD_COMPANY_NAME THEN
			in_out_company_row.name := PreprocessRule(
				in_input_val		=> in_out_company_row.name,
				in_pattern			=> in_pattern,
				in_replacement		=> in_replacement
			);

			FOR r IN (
				SELECT alt_company_name_id, name
				  FROM dedupe_pp_alt_comp_name
				 WHERE company_sid = in_out_company_row.company_sid
			)
			LOOP
				v_alt_comp_name := PreprocessRule(
					in_input_val 		=> r.name,
					in_pattern			=> in_pattern,
					in_replacement		=> in_replacement
				);

				UPDATE dedupe_pp_alt_comp_name
				   SET name = v_alt_comp_name
				 WHERE company_sid = in_out_company_row.company_sid
				   AND alt_company_name_id = r.alt_company_name_id;
			END LOOP;

		ELSIF v_fld_to_process(i) = chain_pkg.FLD_COMPANY_POSTCODE THEN
			in_out_company_row.postcode := PreprocessRule(
				in_input_val		=> in_out_company_row.postcode,
				in_pattern			=> in_pattern,
				in_replacement		=> in_replacement
			);
		ELSIF v_fld_to_process(i) = chain_pkg.FLD_COMPANY_ADDRESS THEN
			in_out_company_row.address_1 := PreprocessRule(
				in_input_val		=> in_out_company_row.address_1,
				in_pattern			=> in_pattern,
				in_replacement		=> in_replacement
			);
			in_out_company_row.address_2 := PreprocessRule(
				in_input_val		=> in_out_company_row.address_2,
				in_pattern			=> in_pattern,
				in_replacement		=> in_replacement
			);
			in_out_company_row.address_3 := PreprocessRule(
				in_input_val		=> in_out_company_row.address_3,
				in_pattern			=> in_pattern,
				in_replacement		=> in_replacement
			);
			in_out_company_row.address_4 := PreprocessRule(
				in_input_val		=> in_out_company_row.address_4,
				in_pattern			=> in_pattern,
				in_replacement		=> in_replacement
			);
		ELSIF v_fld_to_process(i) = chain_pkg.FLD_COMPANY_CITY THEN
			in_out_company_row.city := PreprocessRule(
				in_input_val		=> in_out_company_row.city,
				in_pattern			=> in_pattern,
				in_replacement		=> in_replacement
			);
		END IF;

	END LOOP;
END;

PROCEDURE ApplyRulesToCompanyRow(
	in_out_company_row		IN OUT company%ROWTYPE
)
AS
BEGIN
	FOR r IN (
		SELECT dpr.pattern, dpr.replacement, dpfc.dedupe_field_id, dpfc.country_code
		  FROM dedupe_preproc_rule dpr
		  LEFT JOIN dedupe_pp_field_cntry dpfc ON dpfc.dedupe_preproc_rule_id = dpr.dedupe_preproc_rule_id
		 WHERE dpr.app_sid = security_pkg.getApp
		 ORDER BY dpr.run_order
	)
	LOOP
		IF r.country_code IS NULL OR r.country_code = in_out_company_row.country_code THEN
			EvalPreprocessRule(
				in_pattern				=> r.pattern,
				in_replacement			=> r.replacement,
				in_dedupe_field_id		=> r.dedupe_field_id,
				in_out_company_row		=> in_out_company_row
			);
		END IF;
	END LOOP;
END;

/* Adapter between T_DEDUPE_COMPANY_ROW and company_row.
	It will be removed once we sort the address_1-4 field matching */
PROCEDURE ApplyRulesToCompanyRow(
	in_out_company_row		IN OUT T_DEDUPE_COMPANY_ROW
)
AS
	v_company_row	company%ROWTYPE;
BEGIN
	v_company_row.name := in_out_company_row.name;
	v_company_row.postcode := in_out_company_row.postcode;
	v_company_row.address_1 := in_out_company_row.address_1;
	v_company_row.address_2 := in_out_company_row.address_2;
	v_company_row.address_3 := in_out_company_row.address_3;
	v_company_row.address_4 := in_out_company_row.address_4;
	v_company_row.country_code := in_out_company_row.country_code;
	v_company_row.city := in_out_company_row.city;
	v_company_row.email := in_out_company_row.email;

	ApplyRulesToCompanyRow(v_company_row);

	in_out_company_row.name := v_company_row.name;
	in_out_company_row.postcode := v_company_row.postcode;
	in_out_company_row.address := TRIM(v_company_row.address_1||' '||v_company_row.address_2||' '||v_company_row.address_3||' '||v_company_row.address_4);
	in_out_company_row.address_1 := v_company_row.address_1;
	in_out_company_row.address_2 := v_company_row.address_2;
	in_out_company_row.address_3 := v_company_row.address_3;
	in_out_company_row.address_4 := v_company_row.address_4;
	in_out_company_row.city := v_company_row.city;
	in_out_company_row.email := ApplyBlkLstDomain(GetDomainNameFromEmail(v_company_row.email));
END;

PROCEDURE PreprocessCompany(
	in_company_sid 		company.company_sid%TYPE
)
AS
	v_company_row			company%ROWTYPE;
	v_alt_comp_name_ids		security_pkg.T_SID_IDS;
BEGIN

	SELECT *
	  INTO v_company_row
	  FROM company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
	    
	--create a record if this is the first time we pre-process the company
	BEGIN
		INSERT INTO dedupe_preproc_comp(
			company_sid,
			name,
			address,
			city,
			state, 
			postcode, 
			website, 
			phone, 
			email_domain
		) 
		 SELECT in_company_sid,
			LOWER(TRIM(name)),
			LOWER(TRIM(address_1||' '||address_2||' '||address_3||' '||address_4)),
			LOWER(TRIM(city)),
			LOWER(TRIM(state)),
			LOWER(TRIM(postcode)),
			LOWER(TRIM(website)),
			LOWER(TRIM(phone)),
			ApplyBlkLstDomain(GetDomainNameFromEmail(email))
 		   FROM company
		  WHERE company_sid = in_company_sid;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	INSERT INTO dedupe_pp_alt_comp_name(
		alt_company_name_id,
		company_sid,
		name
	) 
	SELECT alt_company_name_id,
		in_company_sid,
		LOWER(TRIM(name))
	  FROM alt_company_name acn
	 WHERE company_sid = in_company_sid
	   AND NOT EXISTS (
			SELECT 'x' 
			  FROM dedupe_pp_alt_comp_name dpacn 
			 WHERE dpacn.alt_company_name_id = acn.alt_company_name_id
		);

	ApplyRulesToCompanyRow(in_out_company_row => v_company_row);

	UPDATE dedupe_preproc_comp
	   SET name = v_company_row.name,
		   postcode = v_company_row.postcode,
		   address = TRIM(v_company_row.address_1||' '||v_company_row.address_2||' '||v_company_row.address_3||' '||v_company_row.address_4),
		   updated_dtm = SYSDATE,
		   city = v_company_row.city,
		   email_domain = ApplyBlkLstDomain(GetDomainNameFromEmail(v_company_row.email))
	 WHERE company_sid = in_company_sid;
END;

PROCEDURE PreprocessAllRulesForCompanies
AS
BEGIN

	IF helper_pkg.IsDedupePreprocessEnabled = 1 THEN
		FOR r IN (
			SELECT c.company_sid
			  FROM company c
			  LEFT JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
			 WHERE c.app_sid = security_pkg.getApp
			   AND (dpc.updated_dtm IS NULL OR dpc.updated_dtm < SYSDATE -1)
			   AND c.deleted = 0
			   AND c.pending = 0
		)
		LOOP

			PreprocessCompany(r.company_sid);
		END LOOP;
	END IF;
END;

PROCEDURE PreprocessAllRulesForSubst
AS
	v_new_pattern		dedupe_sub.pattern%TYPE;
	v_new_sub			dedupe_sub.substitution%TYPE;
BEGIN

	IF helper_pkg.IsDedupePreprocessEnabled = 1 THEN
	-- Note: we're only supporting cities at the moment so find all rules that apply for cities (no field id or chain_pkg.FLD_COMPANY_CITY) 
	-- and "all countries" as there are no "country" restrictions on this
		FOR s IN (
			SELECT dedupe_sub_id, LOWER(TRIM(pattern)) pattern, LOWER(TRIM(substitution)) substitution
			  FROM dedupe_sub 
			 WHERE (updated_dtm IS NULL OR updated_dtm < SYSDATE -1)
		)
		LOOP
			v_new_pattern := s.pattern;
			v_new_sub := s.substitution;
		
			FOR r IN (
				SELECT dpr.pattern, dpr.replacement
				  FROM dedupe_preproc_rule dpr
				  LEFT JOIN dedupe_pp_field_cntry dpfc ON dpfc.dedupe_preproc_rule_id = dpr.dedupe_preproc_rule_id
				 WHERE dpr.app_sid = security_pkg.getApp
				   AND ((dpfc.dedupe_field_id IS NULL) OR (dpfc.dedupe_field_id = chain_pkg.FLD_COMPANY_CITY)) 
				   AND dpfc.country_code IS NULL
				 ORDER BY dpr.run_order
			) 
			LOOP		
				-- this may look confusing but we are applying a rule with a patter/replacement to a pattern/substitution
				v_new_pattern := PreprocessRule(v_new_pattern, r.pattern, r.replacement);
				v_new_sub := PreprocessRule(v_new_sub, r.pattern, r.replacement);		
			END LOOP;
			
			UPDATE dedupe_sub
			   SET proc_pattern = v_new_pattern,
				   proc_substitution = v_new_sub,
				   updated_dtm = SYSDATE
			 WHERE dedupe_sub_id = s.dedupe_sub_id;
			
		END LOOP;
	END IF;

END;

PROCEDURE RunPreprocessJob
AS
BEGIN
	security.user_pkg.logonadmin;

	FOR r IN (
		SELECT app_sid
		  FROM customer_options
		 WHERE enable_dedupe_preprocess = 1
		 ORDER BY app_sid
	)
	LOOP
		security_pkg.SetApp(r.app_sid);
		BEGIN
			PreprocessAllRulesForCompanies;
			PreprocessAllRulesForSubst;
			commit;
		EXCEPTION
			WHEN OTHERS THEN
				aspen2.error_pkg.LogError('Error running RunPreprocessJob for app_sid: '||r.app_sid||' ERR: '||SQLERRM||chr(10)||dbms_utility.format_error_backtrace);
		END;
	END LOOP;

	security.user_pkg.logoff(security_pkg.getACT);
END;

FUNCTION GetDomainNameFromEmail(
	in_email		IN company.email%TYPE
)RETURN company.email%TYPE
DETERMINISTIC
AS
BEGIN
	RETURN LOWER(TRIM(regexp_replace(regexp_replace(in_email,'^.*@'),'[.].*^*')));
END;

FUNCTION ApplyBlkLstDomain(
	in_domain		IN company.email%TYPE
)RETURN company.email%TYPE
AS
	v_cnt		NUMBER(10);
	v_domain	company.email%TYPE := LOWER(TRIM(in_domain));
BEGIN
	SELECT COUNT(*) 
	  INTO v_cnt
	  FROM dd_customer_blcklst_email
	 WHERE LOWER(TRIM(email_domain)) = v_domain
	   AND v_domain IS NOT NULL;
	 
	IF v_cnt > 0 THEN 
		RETURN NULL;
	ELSE
		RETURN v_domain;
	END IF;
END;

END dedupe_preprocess_pkg;
/
