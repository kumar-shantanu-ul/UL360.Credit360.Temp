CREATE OR REPLACE PACKAGE BODY csr.integration_api_pkg AS

PROCEDURE INTERNAL_TranslateException
AS
BEGIN
	CASE SQLCODE
		WHEN ERR_DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(
				security_pkg.ERR_DUPLICATE_OBJECT_NAME, 
				'Intercepted '||SQLERRM||chr(10)||dbms_utility.format_error_backtrace
			);
		WHEN ERR_NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(
				security_pkg.ERR_OBJECT_NOT_FOUND, 
				'Intercepted '||SQLERRM||chr(10)||dbms_utility.format_error_backtrace
			);
		WHEN ERR_INTEGRITY_CONSTRAINT THEN
			RAISE_APPLICATION_ERROR(
				ERR_FAILED_VALIDATION, 
				'Intercepted '||SQLERRM||chr(10)||dbms_utility.format_error_backtrace
			);
		ELSE
			RAISE_APPLICATION_ERROR(
				-20001,
				'Intercepted '||SQLERRM||chr(10)||dbms_utility.format_error_backtrace
			);
	END CASE;
END;

-- LANGUAGE CONTROLLER

PROCEDURE GetApplicationLanguages(
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN

	-- aspen2.tr_pkg.GetApplicationLanguages
	OPEN out_cur FOR
		SELECT l.lang, l.description, l.lang_id
		  FROM aspen2.translation_set ts, aspen2.lang l
		 WHERE l.lang = ts.lang 
		   AND ts.application_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND ts.hidden = 0
	  ORDER BY l.lang;

END;

-- END LANGUAGE CONTROLLER

-- COMPANY USER CONTROLLER

PROCEDURE GetCompanyUsers(
	in_company_sid				IN	NUMBER,
	in_skip						IN	NUMBER,
	in_take						IN	NUMBER,
	out_user_cur				OUT	SYS_REFCURSOR,
	out_user_companies_cur		OUT	SYS_REFCURSOR,
	out_role_cur				OUT	SYS_REFCURSOR,
	out_total_rows_cur			OUT	SYS_REFCURSOR
)
AS
	v_user_sids						security.T_SID_TABLE;
BEGIN

	SELECT csr_user_sid
	  BULK COLLECT INTO v_user_sids
	  FROM (
		SELECT csr_user_sid, rownum rn
		  FROM (
			SELECT csr_user_sid
			  FROM csr_user cu
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND hidden = 0
			   AND NOT EXISTS(SELECT 1 FROM trash WHERE trash_sid = csr_user_sid)
			   AND NOT EXISTS(SELECT 1 FROM superadmin sa WHERE sa.csr_user_sid = cu.csr_user_sid)
			   AND (in_company_sid IS NULL OR EXISTS(SELECT 1 FROM chain.v$company_user comusr WHERE cu.csr_user_sid = comusr.user_sid AND comusr.company_sid = in_company_sid))
			 ORDER BY LOWER(user_name)
		  )
	  )
	 WHERE rn > in_skip
	   AND rn < in_skip + in_take + 1;
	
	OPEN out_total_rows_cur FOR
		SELECT count(csr_user_sid) total_rows
		  FROM csr_user cu
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND hidden = 0
		   AND NOT EXISTS(SELECT 1 FROM trash WHERE trash_sid = csr_user_sid)
		   AND NOT EXISTS(SELECT 1 FROM superadmin sa WHERE sa.csr_user_sid = cu.csr_user_sid)
		   AND (in_company_sid IS NULL OR EXISTS(SELECT 1 FROM chain.v$company_user comusr WHERE cu.csr_user_sid = comusr.user_sid AND comusr.company_sid = in_company_sid));
	
	GetCompanyUsers(
		in_company_sid			=> in_company_sid,
		in_user_sids			=> v_user_sids,
		out_user_cur			=> out_user_cur,
		out_user_companies_cur	=> out_user_companies_cur,
		out_role_cur			=> out_role_cur
	);
	
END;

PROCEDURE GetCompanyUsers(
	in_company_sid				IN	NUMBER,
	in_user_sids				IN	security.T_SID_TABLE,
	out_user_cur				OUT	SYS_REFCURSOR,
	out_user_companies_cur		OUT	SYS_REFCURSOR,
	out_role_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_user_cur FOR
		SELECT csr_user_sid user_id, user_name, full_name, friendly_name, email email_address, phone_number, active, 
			   language, culture, timezone time_zone, send_alerts, job_title
		  FROM v$csr_user
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND csr_user_sid IN (SELECT column_value FROM TABLE(in_user_sids));
	
	OPEN out_user_companies_cur FOR
		SELECT user_sid user_id, cu.company_sid company_id, c.name company_name, chain.company_user_pkg.IsCompanyAdmin(in_company_sid => cu.company_sid, in_user_sid => cu.user_sid) is_company_admin
		  FROM chain.v$company_user cu
		  JOIN chain.v$company c ON cu.company_sid = c.company_sid
		 WHERE cu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND user_sid IN (SELECT column_value FROM TABLE(in_user_sids));
	
	OPEN out_role_cur FOR
		SELECT rrm.user_sid user_id, r.role_sid role_id, r.name role_name, c.company_sid company_id
		  FROM csr.region_role_member rrm
		  JOIN csr.role r 					ON r.role_sid = rrm.role_sid
		  JOIN chain.company_type_role ctr 	ON rrm.role_sid = ctr.role_sid
		  JOIN chain.v$company c			ON c.region_sid = rrm.region_sid
		 WHERE rrm.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND rrm.user_sid IN (SELECT column_value FROM TABLE(in_user_sids));

END;

PROCEDURE GetCompanyUser(
	in_user_sid					IN	NUMBER,
	out_user_cur				OUT	SYS_REFCURSOR,
	out_user_companies_cur		OUT	SYS_REFCURSOR,
	out_role_cur				OUT	SYS_REFCURSOR
)
AS
	v_user_sids						security.T_SID_TABLE;
BEGIN

	SELECT in_user_sid
	  BULK COLLECT INTO v_user_sids
	  FROM DUAL;
	
	GetCompanyUsers(
		in_company_sid			=> NULL,
		in_user_sids			=> v_user_sids,
		out_user_cur			=> out_user_cur,
		out_user_companies_cur	=> out_user_companies_cur,
		out_role_cur			=> out_role_cur
	);

END;

PROCEDURE SetUserActiveStatus(
	in_user_sid				IN	NUMBER,
	in_is_active			IN	NUMBER
)
AS
BEGIN
	IF in_is_active = 1 THEN
		chain.company_user_pkg.ActivateUser(
			in_user_sid			=> in_user_sid
		);
	ELSE
		chain.company_user_pkg.DeactivateUser(
			in_user_sid			=> in_user_sid
		);
	END IF;
END;

PROCEDURE AddUserToDefaultGroups(
	in_user_sid				IN	NUMBER
)
AS
BEGIN
	FOR r IN (SELECT group_sid_id FROM intapi_company_user_group)
	LOOP
		security.group_pkg.AddMember(SYS_CONTEXT('SECURITY', 'ACT'), in_user_sid, r.group_sid_id);
	END LOOP;
END;

PROCEDURE CreateCompanyUser(
	in_company_sid			IN	NUMBER,
	in_is_company_admin		IN	NUMBER,
	in_company_type_roles	IN	security_pkg.T_SID_IDS,
	in_full_name			IN	csr.csr_user.full_name%TYPE,
	in_friendly_name		IN	csr.csr_user.friendly_name%TYPE,
	in_email				IN	csr.csr_user.email%TYPE,
	in_user_name			IN	csr.csr_user.user_name%TYPE,
	in_phone_number			IN	csr.csr_user.phone_number%TYPE, 
	in_job_title			IN	csr.csr_user.job_title%TYPE,
	in_is_active			IN	NUMBER,
	in_send_alerts			IN	NUMBER,
	out_new_user_sid		OUT	NUMBER
)
AS
	v_api_user_company		NUMBER;
BEGIN

	SELECT default_company_sid 
	  INTO v_api_user_company
	  FROM chain.v$chain_user 
	 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID');

	chain.company_pkg.SetCompany(v_api_user_company);

	out_new_user_sid := chain.company_user_pkg.CreateUserFromApi (
		in_company_sid			=> in_company_sid,
		in_full_name			=> in_full_name,
		in_friendly_name		=> in_friendly_name,
		in_email				=> in_email,
		in_user_name			=> in_user_name,
		in_phone_number			=> in_phone_number,
		in_job_title			=> in_job_title,
		in_send_alerts			=> in_send_alerts
	);
	
	SetUserActiveStatus(
		in_user_sid				=> out_new_user_sid,
		in_is_active			=> in_is_active
	);
	
	chain.company_user_pkg.SetRegistrationStatus(
		in_user_sid				=> out_new_user_sid,
		in_status				=> chain.chain_pkg.REGISTERED
	);
	
	AddUserToCompany(
		in_user_sid				=>	out_new_user_sid,
		in_company_sid			=>	in_company_sid,
		in_is_company_admin		=>	in_is_company_admin,
		in_company_type_roles	=>	in_company_type_roles
	);
	
	AddUserToDefaultGroups(
		in_user_sid				=> out_new_user_sid
	);
END;

PROCEDURE CreateCompanyUser(
	in_company_sid			IN	NUMBER,
	in_is_company_admin		IN	NUMBER,
	in_company_type_roles	IN	security_pkg.T_SID_IDS,
	in_full_name			IN	csr.csr_user.full_name%TYPE,
	in_friendly_name		IN	csr.csr_user.friendly_name%TYPE,
	in_email				IN	csr.csr_user.email%TYPE,
	in_user_name			IN	csr.csr_user.user_name%TYPE,
	in_phone_number			IN	csr.csr_user.phone_number%TYPE, 
	in_job_title			IN	csr.csr_user.job_title%TYPE,
	in_is_active			IN	NUMBER,
	in_send_alerts			IN	NUMBER,
	in_language				IN	security.user_table.language%TYPE,
	in_culture				IN	security.user_table.culture%TYPE,
	in_timezone				IN	security.user_table.timezone%TYPE,
	out_new_user_sid		OUT	NUMBER
)
AS
	v_api_user_company		NUMBER;
	v_language				security.user_table.language%TYPE;
	v_culture				security.user_table.culture%TYPE;
	v_timezone				security.user_table.timezone%TYPE;
BEGIN

	csr.integration_api_pkg.CreateCompanyUser(
		in_company_sid			=> in_company_sid,
		in_is_company_admin		=> in_is_company_admin,
		in_company_type_roles	=> in_company_type_roles,
		in_full_name			=> in_full_name,
		in_friendly_name		=> in_friendly_name,
		in_email				=> in_email,
		in_user_name			=> in_user_name,
		in_phone_number			=> in_phone_number,
		in_job_title			=> in_job_title,
		in_is_active			=> in_is_active,
		in_send_alerts			=> in_send_alerts,
		out_new_user_sid		=> out_new_user_sid
	);

	SELECT language, culture, timezone
	  INTO v_language, v_culture, v_timezone
	  FROM csr.v$csr_user
	 WHERE csr_user_sid = out_new_user_sid;

	
	csr.csr_user_pkg.SetLocalisationSettings(
		in_act_id				=>	SYS_CONTEXT('SECURITY', 'ACT'),
		in_user_sid				=>	out_new_user_sid,
		in_language				=>	NVL(in_language, v_language),
		in_culture				=>	NVL(in_culture, v_culture), 
		in_timezone				=>	NVL(in_timezone, v_timezone)
	);
END;

PROCEDURE AddUserToCompany(
	in_user_sid				IN	NUMBER,
	in_company_sid			IN	NUMBER,
	in_is_company_admin		IN	NUMBER,
	in_company_type_roles	IN	security_pkg.T_SID_IDS
)
AS
	v_api_user_company		NUMBER;
BEGIN

	SELECT default_company_sid 
	  INTO v_api_user_company
	  FROM chain.v$chain_user 
	 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID');

	chain.company_pkg.SetCompany(v_api_user_company);
	
	chain.company_user_pkg.AddUserToCompany_UNSEC (
		in_company_sid		=> in_company_sid,
		in_user_sid			=> in_user_sid
	);
	chain.company_user_pkg.ApproveUser(
		in_company_sid		=> in_company_sid,
		in_user_sid			=> in_user_sid
	);

	IF in_is_company_admin = 1 THEN
		MakeUserCompanyAdmin(
			in_company_sid		=> in_company_sid,
			in_user_sid			=> in_user_sid
		);
	END IF;
	
	AddUserToCompanyTypeRoles(
		in_user_sid				=> in_user_sid,
		in_company_sid			=> in_company_sid,
		in_company_type_roles	=> in_company_type_roles
	);

END;

PROCEDURE MakeUserCompanyAdmin(
	in_user_sid				IN	NUMBER,
	in_company_sid			IN	NUMBER
)
AS
	v_api_user_company		NUMBER;
BEGIN

	SELECT default_company_sid 
	  INTO v_api_user_company
	  FROM chain.v$chain_user 
	 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID');

	chain.company_pkg.SetCompany(v_api_user_company);

	chain.company_user_pkg.MakeAdmin(
		in_company_sid		=> in_company_sid,
		in_user_sid			=> in_user_sid
	);

END;

FUNCTION TryRemoveUserFromCompanyAdmin(
	in_user_sid				IN	NUMBER,
	in_company_sid			IN	NUMBER
)RETURN NUMBER
AS
	v_api_user_company		NUMBER;
	v_result 				NUMBER;
BEGIN
	-- I don't fully understand what the point of this is. Is there a chance the default company for an api user to be something other than null or top company? Still, shouldn't we set it back?
	SELECT default_company_sid 
	  INTO v_api_user_company
	  FROM chain.v$chain_user 
	 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID');

	chain.company_pkg.SetCompany(v_api_user_company);
	
	v_result := chain.company_user_pkg.RemoveAdmin(in_company_sid => in_company_sid, in_user_sid => in_user_sid, in_force_remove_last_admin => 0);
	
	RETURN v_result;
END;

/* Leaving it for compatibilty reasons/ until the api.integrations stops using it */
PROCEDURE RemoveUserFromCompanyAdmin(
	in_user_sid				IN	NUMBER,
	in_company_sid			IN	NUMBER
)
AS
	v_api_user_company		NUMBER;
	v_result 				NUMBER;
BEGIN
	
	SELECT default_company_sid 
	  INTO v_api_user_company
	  FROM chain.v$chain_user 
	 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID');

	chain.company_pkg.SetCompany(v_api_user_company);
	
	v_result := chain.company_user_pkg.RemoveAdmin(in_company_sid => in_company_sid, in_user_sid => in_user_sid, in_force_remove_last_admin => 0);
END;
	
PROCEDURE AddUserToCompanyTypeRoles(
	in_user_sid				IN	NUMBER,
	in_company_sid			IN	NUMBER,
	in_company_type_roles	IN	security_pkg.T_SID_IDS
)
AS
BEGIN

	FOR i IN 1 .. in_company_type_roles.COUNT LOOP
		chain.company_user_pkg.UNSEC_AddCompanyTypeRoleToUser(
			in_company_sid		=> in_company_sid,
			in_user_sid			=> in_user_sid,
			in_role_sid			=> in_company_type_roles(i)
		);
	END LOOP;

END;

PROCEDURE RemoveUserFromCompanyTypeRoles(
	in_user_sid				IN	NUMBER,
	in_company_sid			IN	NUMBER,
	in_company_type_roles	IN	security_pkg.T_SID_IDS
)
AS
BEGIN

	FOR i IN 1 .. in_company_type_roles.COUNT LOOP
		chain.company_user_pkg.UNSEC_RemoveComTypeRoleFromUsr(
			in_company_sid		=> in_company_sid,
			in_user_sid			=> in_user_sid,
			in_role_sid			=> in_company_type_roles(i)
		);
	END LOOP;

END;

PROCEDURE UpdateCompanyUser(
	in_user_sid				IN	NUMBER,
	in_full_name			IN	csr.csr_user.full_name%TYPE,
	in_friendly_name		IN	csr.csr_user.friendly_name%TYPE,
	in_email				IN	csr.csr_user.email%TYPE,
	in_user_name			IN	csr.csr_user.user_name%TYPE,
	in_phone_number			IN	csr.csr_user.phone_number%TYPE, 
	in_job_title			IN	csr.csr_user.job_title%TYPE,
	in_is_active			IN	NUMBER,
	in_send_alerts			IN	NUMBER
)
AS
	v_api_user_company		NUMBER;
BEGIN

	SELECT default_company_sid 
	  INTO v_api_user_company
	  FROM chain.v$chain_user 
	 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID');

	chain.company_pkg.SetCompany(v_api_user_company);

	chain.company_user_pkg.UNSEC_UpdateUser (
		in_user_sid				=> in_user_sid,
		in_full_name			=> in_full_name,
		in_friendly_name		=> in_friendly_name,
		in_phone_number			=> in_phone_number,
		in_job_title			=> in_job_title,
		in_email				=> in_email,
		in_send_alerts 			=> in_send_alerts,
		in_user_name			=> in_user_name
	);

	SetUserActiveStatus(
		in_user_sid				=> in_user_sid,
		in_is_active			=> in_is_active
	);
	
END;

PROCEDURE UpdateCompanyUser(
	in_user_sid				IN	NUMBER,
	in_full_name			IN	csr.csr_user.full_name%TYPE,
	in_friendly_name		IN	csr.csr_user.friendly_name%TYPE,
	in_email				IN	csr.csr_user.email%TYPE,
	in_user_name			IN	csr.csr_user.user_name%TYPE,
	in_phone_number			IN	csr.csr_user.phone_number%TYPE, 
	in_job_title			IN	csr.csr_user.job_title%TYPE,
	in_is_active			IN	NUMBER,
	in_send_alerts			IN	NUMBER,
	in_language				IN	security.user_table.language%TYPE,
	in_culture				IN	security.user_table.culture%TYPE,
	in_timezone				IN	security.user_table.timezone%TYPE
)
AS
	v_language					security.user_table.language%TYPE;
	v_culture					security.user_table.culture%TYPE;
	v_timezone					security.user_table.timezone%TYPE;
	v_api_user_company			NUMBER;
BEGIN

	SELECT default_company_sid 
	  INTO v_api_user_company
	  FROM chain.v$chain_user 
	 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID');

	chain.company_pkg.SetCompany(v_api_user_company);

	csr.integration_api_pkg.UpdateCompanyUser(
		in_user_sid			=> in_user_sid,
		in_full_name		=> in_full_name,
		in_friendly_name	=> in_friendly_name,
		in_email			=> in_email,
		in_user_name		=> in_user_name,
		in_phone_number		=> in_phone_number,
		in_job_title		=> in_job_title,
		in_is_active		=> in_is_active,
		in_send_alerts		=> in_send_alerts
	);
	
	SELECT language, culture, timezone
	  INTO v_language, v_culture, v_timezone
	  FROM csr.v$csr_user
	 WHERE csr_user_sid = in_user_sid;
	
	csr.csr_user_pkg.SetLocalisationSettings(
		in_act_id				=>	SYS_CONTEXT('SECURITY', 'ACT'),
		in_user_sid				=>	in_user_sid,
		in_language				=>	NVL(in_language, v_language),
		in_culture				=>	NVL(in_culture, v_culture), 
		in_timezone				=>	NVL(in_timezone, v_timezone)
	);
	
END;

PROCEDURE RemoveUserFromCompanies(
	in_user_sid				IN	NUMBER,
	in_company_sids			IN	security_pkg.T_SID_IDS
)
AS
BEGIN

	FOR i IN 1 .. in_company_sids.COUNT LOOP
		chain.company_user_pkg.UNSEC_RemoveUserFromCompany (
			in_user_sid				=> in_user_sid,
			in_company_sid			=> in_company_sids(i)
		);
	END LOOP;

END;

PROCEDURE DeleteCompanyUser(
	in_user_sid				IN	NUMBER
)
AS
BEGIN

	chain.company_user_pkg.DeleteUser(
		in_user_sid		=> in_user_sid
	);

END;

-- END COMPANY USER CONTROLLER


-- COMPANY

PROCEDURE INTERNAL_GetCompanyCore(
	in_company_sids			IN	security.T_SID_TABLE,
	in_total				IN	NUMBER	DEFAULT NULL,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT in_total total_count, c.company_sid, c.created_dtm, c.name, c.active, c.activated_dtm, c.deactivated_dtm,
		   c.address_1, c.address_2, c.address_3, c.address_4, c.state, c.city, c.postcode, c.country_code,
		   c.phone, c.fax, c.website, c.email, c.details_confirmed, 
		   cou.name country_name, c.sector_id, s.description sector_description, c.company_type_id,
		   ct.lookup_key company_type_lookup, ct.singular company_type_description,
		   c.parent_sid, 
		   r.geo_longitude longitude, r.geo_latitude latitude
		  FROM chain.company c
		  JOIN TABLE(in_company_sids) filter ON filter.column_value = c.company_sid
		  LEFT JOIN postcode.country cou ON c.country_code = cou.country
		  LEFT JOIN chain.sector s ON c.sector_id = s.sector_id AND c.app_sid = s.app_sid
		  LEFT JOIN chain.company_type ct ON c.company_type_id = ct.company_type_id
		  LEFT JOIN chain.company p ON c.parent_sid = p.company_sid AND c.app_sid = p.app_sid
		  LEFT JOIN postcode.country pcou ON p.country_code = pcou.country
		  LEFT JOIN csr.supplier cs ON cs.company_sid = c.company_sid AND cs.app_sid = c.app_sid
		  LEFT JOIN csr.region r ON cs.app_sid = r.app_sid AND cs.region_sid = r.region_sid
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY c.company_sid;
END;

PROCEDURE INTERNAL_GetCompanyTags(
	in_company_sids			IN	security.T_SID_TABLE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT s.company_sid, t.tag_id, t.tag, t.lookup_key, tg.tag_group_id, tg.name tag_group_name, tg.mandatory, t.explanation
		  FROM v$tag t
		  JOIN tag_group_member tgm ON t.tag_id = tgm.tag_id
		  JOIN v$tag_group tg ON tgm.tag_group_id = tg.tag_group_id
		  JOIN region_tag rt ON rt.tag_id = t.tag_id
		  JOIN supplier s ON s.region_sid = rt.region_sid
		  JOIN TABLE(in_company_sids) filter ON filter.column_value = s.company_sid
		 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND tg.applies_to_suppliers = 1;
END;

PROCEDURE INTERNAL_GetCompanyRefs(
	in_company_sids			IN	security.T_SID_TABLE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT company_sid, reference_id, lookup_key, company_reference_id, value
		  FROM chain.v$company_reference cr
		  JOIN TABLE(in_company_sids) filter ON filter.column_value = cr.company_sid
		 WHERE cr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND value IS NOT NULL; -- Treat references with null values as non-existent
END;

PROCEDURE INTERNAL_GetCompanyScores(
	in_company_sids			IN	security.T_SID_TABLE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT cs.company_sid, sl.score_type_id, sl.score_threshold_id,
				-- Score type information
				st.label score_type_label, st.pos score_type_pos, st.hidden score_type_hidden, st.allow_manual_set score_type_allow_manual_set,
				st.lookup_key score_type_lookup_key, st.applies_to_supplier score_type_applies_to_supplier, st.reportable_months score_type_reportable_months,
				st.format_mask score_type_format_mask, st.ask_for_comment score_type_ask_for_comment, 
				st.min_score score_type_min_score, st.max_score score_type_max_score, st.start_score score_type_start_score, st.normalise_to_max_score score_type_norm_to_max_score,
				-- Score threshold information
				sth.description score_threshold_label, sth.max_value score_threshold_max_value,
				sth.text_colour score_threshold_text_colour, sth.background_colour score_threshold_backgr_colour, sth.bar_colour score_threshold_bar_colour,
				sth.score_type_id score_threshold_score_type_id, sth.lookup_key score_threshold_lookup_key
		  FROM current_supplier_score cs
		  JOIN TABLE(in_company_sids) filter ON filter.column_value = cs.company_sid
		  JOIN supplier_score_log sl ON sl.app_sid = cs.app_sid AND sl.supplier_sid = cs.company_sid 
		   AND sl.score_type_id = cs.score_type_id AND sl.supplier_score_id = cs.last_supplier_score_id
		  JOIN score_type st ON st.app_sid = cs.app_sid AND st.score_type_id = sl.score_type_id
		  JOIN score_threshold sth ON sth.app_sid = cs.app_sid AND sth.score_threshold_id = sl.score_threshold_id
		 WHERE cs.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetCompany(
	in_company_sid			IN	security_pkg.T_SID_ID,
	out_company_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_tags_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_refs_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_scth_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sids			security.T_SID_TABLE;
BEGIN

	SELECT company_sid
	  BULK COLLECT INTO v_company_sids
	  FROM chain.company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid
	   AND deleted = 0;

	INTERNAL_GetCompanyCore(
		in_company_sids	=> v_company_sids,
		out_cur			=> out_company_cur
	);

	INTERNAL_GetCompanyTags(
		in_company_sids	=> v_company_sids,
		out_cur			=> out_tags_cur
	);

	INTERNAL_GetCompanyRefs(
		in_company_sids	=> v_company_sids,
		out_cur			=> out_refs_cur
	);

	INTERNAL_GetCompanyScores(
		in_company_sids	=> v_company_sids,
		out_cur			=> out_scth_cur
	);

END;

PROCEDURE GetCompanies(
	in_skip					IN	NUMBER	DEFAULT 0,
	in_take					IN	NUMBER	DEFAULT 20,
	out_company_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_tags_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_refs_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_scth_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sids			security.T_SID_TABLE;
	v_total_count			NUMBER;
BEGIN
	SELECT company_sid
	  BULK COLLECT INTO v_company_sids
	  FROM (
		SELECT company_sid, ROWNUM rn
		  FROM (
			SELECT c.company_sid
			  FROM chain.company c
			 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND c.deleted = 0
			 ORDER BY c.company_sid
		  )
	  )
	 WHERE rn > in_skip
	   AND rn <= in_skip + in_take;

	SELECT COUNT(*)
	  INTO v_total_count
	  FROM chain.company c
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND c.deleted = 0;

	INTERNAL_GetCompanyCore(
		in_company_sids	=> v_company_sids,
		in_total		=> v_total_count,
		out_cur			=> out_company_cur
	);

	INTERNAL_GetCompanyTags(
		in_company_sids	=> v_company_sids,
		out_cur			=> out_tags_cur
	);

	INTERNAL_GetCompanyRefs(
		in_company_sids	=> v_company_sids,
		out_cur			=> out_refs_cur
	);

	INTERNAL_GetCompanyScores(
		in_company_sids	=> v_company_sids,
		out_cur			=> out_scth_cur
	);

END;

PROCEDURE CreateSubCompany(
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_name					IN	chain.company.name%TYPE,
	in_country_code			IN	chain.company.country_code%TYPE,
	in_company_type_id		IN	chain.company_type.company_type_id%TYPE,
	in_sector_id			IN  chain.company.sector_id%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
)
AS
BEGIN
	chain.company_pkg.CreateSubCompany(
		in_parent_sid		=> in_parent_sid,
		in_name				=> in_name,
		in_country_code		=> in_country_code,
		in_company_type_id	=> in_company_type_id,
		in_sector_id		=> in_sector_id,
		in_lookup_keys		=> chain.chain_pkg.NullStringArray,
		in_values			=> chain.chain_pkg.NullStringArray,
		out_company_sid		=> out_company_sid
	);
END;

PROCEDURE CreateUniqueCompany(
	in_name					IN  chain.company.name%TYPE,
	in_country_code			IN  chain.company.country_code%TYPE,
	in_company_type_id		IN  chain.company_type.company_type_id%TYPE,
	in_sector_id			IN  chain.company.sector_id%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
)
AS
BEGIN
	BEGIN
		chain.helper_pkg.LogonUCD;
		chain.company_pkg.CreateUniqueCompany(
			in_name				=> in_name,
			in_country_code		=> in_country_code,
			in_company_type_id	=> in_company_type_id,
			in_sector_id		=> in_sector_id,
			in_lookup_keys		=> chain.chain_pkg.NullStringArray,
			in_values			=> chain.chain_pkg.NullStringArray,
			out_company_sid		=> out_company_sid
		);
		chain.helper_pkg.RevertLogonUCD;
	EXCEPTION
		WHEN OTHERS THEN
			chain.helper_pkg.RevertLogonUCD;
			INTERNAL_TranslateException;
			RAISE;
	END;
END;

PROCEDURE UpdateCompany (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_name					IN  chain.company.name%TYPE,
	in_country_code			IN  chain.company.country_code%TYPE,
	in_address_1			IN  chain.company.address_1%TYPE,
	in_address_2			IN  chain.company.address_2%TYPE,
	in_address_3			IN  chain.company.address_3%TYPE,
	in_address_4			IN  chain.company.address_4%TYPE,
	in_city					IN  chain.company.city%TYPE,
	in_state				IN  chain.company.state%TYPE,
	in_postcode				IN  chain.company.postcode%TYPE,
	in_latitude				IN  region.geo_latitude%TYPE,
	in_longitude			IN  region.geo_longitude%TYPE,
	in_phone				IN  chain.company.phone%TYPE,
	in_fax					IN  chain.company.fax%TYPE,
	in_website				IN  chain.company.website%TYPE,
	in_email				IN  chain.company.email%TYPE,
	in_sector_id			IN  chain.company.sector_id%TYPE,
	in_reference_ids		IN	security_pkg.T_SID_IDS,
	in_values				IN	chain.chain_pkg.T_STRINGS
)
AS
	v_reference_ids			security.T_SID_TABLE;
	v_lookup_keys			chain.chain_pkg.T_STRINGS;
	v_values				chain.chain_pkg.T_STRINGS := in_values;
	v_code					NUMBER;
BEGIN

	-- Convert reference ids to lookup keys
	v_reference_ids := security_pkg.SidArrayToTable(in_reference_ids);

	SELECT r.lookup_key
	  BULK COLLECT INTO v_lookup_keys
	  FROM chain.reference r
	  JOIN TABLE(v_reference_ids) id ON r.reference_id = id.column_value
	 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	-- Add in null values for references that were 
	-- not proivided but which currently exist.
	-- Null value is treated the same as deleted.
	FOR r IN (
		SELECT r.lookup_key
		  FROM chain.company_reference cr
		  JOIN chain.reference r ON r.app_sid = cr.app_sid AND r.reference_id = cr.reference_id
		 WHERE cr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cr.company_sid = in_company_sid
		   AND cr.value IS NOT NULL
		   AND cr.reference_id NOT IN (
		   	SELECT column_value
		   	  FROM TABLE(v_reference_ids)
		)
	) LOOP
		v_lookup_keys(v_lookup_keys.COUNT) := r.lookup_key;
		v_values(v_values.COUNT) := NULL;
	END LOOP;

	BEGIN
		chain.helper_pkg.LogonUCD;
		chain.company_pkg.UpdateCompany (
			in_company_sid		=> in_company_sid,
			in_name				=> in_name,
			in_country_code		=> LOWER(in_country_code),
			in_address_1		=> in_address_1,
			in_address_2		=> in_address_2,
			in_address_3		=> in_address_3,
			in_address_4		=> in_address_4,
			in_city				=> in_city,
			in_state			=> in_state,
			in_postcode			=> in_postcode,
			in_latitude			=> NVL(in_latitude, chain.chain_pkg.PRESERVE_NUMBER),
			in_longitude		=> NVL(in_longitude, chain.chain_pkg.PRESERVE_NUMBER),
			in_phone			=> in_phone,
			in_fax				=> in_fax,
			in_website			=> in_website,
			in_email			=> in_email,
			in_sector_id		=> NVL(in_sector_id, chain.chain_pkg.PRESERVE_NUMBER),
			in_lookup_keys		=> v_lookup_keys,
			in_values			=> v_values
		);
		chain.helper_pkg.RevertLogonUCD;
	EXCEPTION
		WHEN OTHERS THEN
			chain.helper_pkg.RevertLogonUCD;
			INTERNAL_TranslateException;
			RAISE;
	END;
END;

PROCEDURE ActivateCompany (
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
	v_deactivated_dtm		chain.company.deactivated_dtm%TYPE;
BEGIN
	BEGIN
		chain.helper_pkg.LogonUCD;

		SELECT deactivated_dtm
		  INTO v_deactivated_dtm
		  FROM chain.company
		 WHERE company_sid = in_company_sid;

		IF v_deactivated_dtm IS NULL THEN
			chain.company_pkg.UNSEC_ActivateCompany(
				in_company_sid => in_company_sid
			);
		ELSE
			chain.company_pkg.UNSEC_ReactivateCompany(
				in_company_sid => in_company_sid
			);
		END IF;
		chain.helper_pkg.RevertLogonUCD;
	EXCEPTION
		WHEN OTHERS THEN
			chain.helper_pkg.RevertLogonUCD;
			INTERNAL_TranslateException;
			RAISE;
	END;
END;

PROCEDURE DeactivateCompany (
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
BEGIN
	BEGIN
		chain.helper_pkg.LogonUCD;
		chain.company_pkg.UNSEC_DeactivateCompany(
			in_company_sid => in_company_sid
		);
		chain.helper_pkg.RevertLogonUCD;
	EXCEPTION
		WHEN OTHERS THEN
			chain.helper_pkg.RevertLogonUCD;
			INTERNAL_TranslateException;
			RAISE;
	END;
END;

PROCEDURE SetCompanyTags(
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_tag_ids				IN	security_pkg.T_SID_IDS
)
AS
BEGIN
	BEGIN
		chain.helper_pkg.LogonUCD;
		
		supplier_pkg.SetTags(
			in_company_sid		=> in_company_sid,
			in_tag_ids			=> in_tag_ids
		);
		
		chain.helper_pkg.RevertLogonUCD;
	EXCEPTION
		WHEN OTHERS THEN
			chain.helper_pkg.RevertLogonUCD;
			INTERNAL_TranslateException;
			RAISE;
	END;
END;

PROCEDURE SetCompanyScoreThreshold(
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	in_threshold_id				IN	quick_survey_submission.score_threshold_id%TYPE
)
As
BEGIN
	-- XXX: Not sure it's a good idea to simply remove items from current_supplier_score 
	-- XXX: and can't see anything in chain for removing score thresholds ??

	supplier_pkg.UNSEC_SetSupplierScoreThold(
		in_company_sid		=> in_company_sid,
		in_score_type_id	=> in_score_type_id,
		in_threshold_id		=> in_threshold_id,
		in_comment_text		=> NULL
	);
END;

PROCEDURE DeleteCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	chain.company_pkg.UNSEC_DeleteCompany(
		in_company_sid		=> in_company_sid
	);
END;

PROCEDURE GetRelationship(
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT supplier_company_sid, purchaser_company_sid, active
		  FROM chain.supplier_relationship
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND supplier_company_sid = in_supplier_company_sid
		   AND purchaser_company_sid = in_purchaser_company_sid
		   AND deleted = 0;
END;

PROCEDURE StartRelationship(
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID
)
AS
BEGIN
	chain.company_pkg.StartRelationship(
		in_supplier_company_sid		=> in_supplier_company_sid,
		in_purchaser_company_sid	=> in_purchaser_company_sid
	);
END;

PROCEDURE ActivateRelationship(
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID
)
AS
BEGIN
	chain.company_pkg.ActivateRelationship(
		in_supplier_company_sid		=> in_supplier_company_sid,
		in_purchaser_company_sid	=> in_purchaser_company_sid
	);
END;

PROCEDURE TerminateRelationship(
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID
)
AS
BEGIN
	chain.company_pkg.TerminateRelationship (
		in_supplier_company_sid		=> in_supplier_company_sid,
		in_purchaser_company_sid	=> in_purchaser_company_sid,
		in_force					=> TRUE -- Do we want to force?
	);
END;

FUNCTION GetTopCompanySid
RETURN security_pkg.T_SID_ID
AS
BEGIN
	RETURN chain.helper_pkg.GetTopCompanySid();
END;

-- END COMPANY

-- TAG GROUP

PROCEDURE INTERNAL_GetTagGroups(
	in_tag_group_ids		IN	security.T_SID_TABLE,
	in_total				IN	NUMBER	DEFAULT NULL,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT in_total total_count, tag_group_id, name, lookup_key, mandatory, multi_select,
				applies_to_inds, applies_to_regions,  
				applies_to_non_compliances, applies_to_suppliers, 
				applies_to_chain, applies_to_chain_activities, applies_to_initiatives,
				applies_to_chain_product_types,
				applies_to_chain_products,
				applies_to_chain_product_supps,
				applies_to_quick_survey, applies_to_audits, applies_to_compliances,
				is_hierarchical
		  FROM v$tag_group tg
		  JOIN TABLE(in_tag_group_ids) filter ON filter.column_value = tg.tag_group_id
		 WHERE tg.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY tag_group_id;
END;

PROCEDURE INTERNAL_GetTagGroupDescrptns(
	in_tag_group_ids		IN	security.T_SID_TABLE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT tag_group_id, name, lang, last_changed_dtm
		  FROM tag_group_description tgd
		  JOIN TABLE(in_tag_group_ids) filter ON filter.column_value = tgd.tag_group_id
		 WHERE tgd.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY tag_group_id;
END;

PROCEDURE INTERNAL_GetTagGroupTags(
	in_tag_group_ids		IN	security.T_SID_TABLE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT tgm.tag_id, t.tag, t.explanation, t.lookup_key, tgm.tag_group_id, tgm.pos, tgm.active, t.exclude_from_dataview_grouping
		  FROM tag_group_member tgm
		  JOIN TABLE(in_tag_group_ids) filter ON filter.column_value = tgm.tag_group_id
		  JOIN v$tag t ON t.tag_id = tgm.tag_id
		 WHERE tgm.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY tag_id;
END;

PROCEDURE INTERNAL_GetTagDescrptns(
	in_tag_group_ids		IN	security.T_SID_TABLE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT tgm.tag_id, td.tag, td.explanation, td.lang, td.last_changed_dtm
		  FROM tag_group_member tgm
		  JOIN TABLE(in_tag_group_ids) filter ON filter.column_value = tgm.tag_group_id
		  JOIN tag_description td ON td.tag_id = tgm.tag_id
		 WHERE tgm.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY tag_id;
END;


PROCEDURE GetTagGroups(
	in_skip					IN	NUMBER	DEFAULT 0,
	in_take					IN	NUMBER	DEFAULT 20,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_descriptions_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_tags_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_tag_descriptions_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid				security_pkg.T_SID_ID := security.security_pkg.GetApp;
	v_tag_group_ids			security.T_SID_TABLE;
	v_total_count			NUMBER;
BEGIN
	SELECT tag_group_id
	  BULK COLLECT INTO v_tag_group_ids
	  FROM (
		SELECT tag_group_id, ROWNUM rn
		  FROM (
			SELECT tg.tag_group_id
			  FROM tag_group tg
			 WHERE tg.app_sid = v_app_sid
			 ORDER BY tg.tag_group_id
		  )
	  )
	 WHERE rn > in_skip
	   AND rn <= in_skip + in_take;

	SELECT COUNT(*)
	  INTO v_total_count
	  FROM tag_group tg
	 WHERE tg.app_sid = v_app_sid;

	INTERNAL_GetTagGroups(
		in_tag_group_ids	=> v_tag_group_ids,
		in_total			=> v_total_count,
		out_cur				=> out_cur
	);
	INTERNAL_GetTagGroupDescrptns(
		in_tag_group_ids	=> v_tag_group_ids,
		out_cur				=> out_descriptions_cur
	);
	INTERNAL_GetTagGroupTags(
		in_tag_group_ids	=> v_tag_group_ids,
		out_cur				=> out_tags_cur
	);
	INTERNAL_GetTagDescrptns(
		in_tag_group_ids	=> v_tag_group_ids,
		out_cur				=> out_tag_descriptions_cur
	);
END;

PROCEDURE GetTagGroup(
	in_tag_group_id				IN	tag_group.tag_group_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR,
	out_descriptions_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_tags_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_tag_descriptions_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_act	security_pkg.T_ACT_ID := security.security_pkg.GetACT;
BEGIN
	tag_pkg.GetTagGroup(
		in_act_id		=> v_act,
		in_tag_group_id	=> in_tag_group_id,
		out_cur			=> out_cur);

	tag_pkg.GetTagGroupDescriptions(
		in_act_id		=> v_act,
		in_tag_group_id	=> in_tag_group_id,
		out_cur			=> out_descriptions_cur);
	
	tag_pkg.GetTagGroupMembers(
		in_act_id		=> v_act,
		in_tag_group_id	=> in_tag_group_id,
		out_cur			=> out_tags_cur);

	tag_pkg.GetTagGroupMemberDescriptions(
		in_act_id		=> v_act,
		in_tag_group_id	=> in_tag_group_id,
		out_cur			=> out_tag_descriptions_cur);
	
END;

PROCEDURE UpsertTagGroup(
	in_tag_group_id					IN	tag_group.tag_group_id%TYPE DEFAULT NULL,
	in_name							IN	tag_group_description.name%TYPE,
	in_mandatory					IN	tag_group.mandatory%TYPE DEFAULT 0,
	in_multi_select					IN	tag_group.multi_select%TYPE DEFAULT 0,
	in_applies_to_inds				IN	tag_group.applies_to_inds%TYPE DEFAULT 0,
	in_applies_to_regions			IN	tag_group.applies_to_regions%TYPE DEFAULT 0,
	in_applies_to_non_comp			IN	tag_group.applies_to_non_compliances%TYPE DEFAULT 0,
	in_applies_to_suppliers			IN	tag_group.applies_to_suppliers%TYPE DEFAULT 0,
	in_applies_to_chain				IN	tag_group.applies_to_chain%TYPE DEFAULT 0,
	in_applies_to_chain_activities	IN	tag_group.applies_to_chain_activities%TYPE DEFAULT 0,
	in_applies_to_initiatives		IN	tag_group.applies_to_initiatives%TYPE DEFAULT 0,
	in_applies_to_chain_prod_types	IN	tag_group.applies_to_chain_product_types%TYPE DEFAULT 0,
	in_applies_to_chain_products	IN	tag_group.applies_to_chain_products%TYPE DEFAULT 0,
	in_applies_to_chain_prod_supps	IN	tag_group.applies_to_chain_product_supps%TYPE DEFAULT 0,
	in_applies_to_quick_survey		IN	tag_group.applies_to_quick_survey%TYPE DEFAULT 0,
	in_applies_to_audits			IN	tag_group.applies_to_audits%TYPE DEFAULT 0,
	in_applies_to_compliances		IN	tag_group.applies_to_compliances%TYPE DEFAULT 0,
	in_lookup_key					IN	tag_group.lookup_key%TYPE DEFAULT NULL,
	out_tag_group_id				OUT	tag_group.tag_group_id%TYPE
)
AS
BEGIN
	IF in_tag_group_id IS NULL THEN
		tag_pkg.CreateTagGroup(
			in_name							=>	in_name,
			in_mandatory					=>	in_mandatory,
			in_multi_select					=>	in_multi_select,
			in_applies_to_inds				=>	in_applies_to_inds,
			in_applies_to_regions			=>	in_applies_to_regions,
			in_applies_to_non_comp			=>	in_applies_to_non_comp,
			in_applies_to_suppliers			=>	in_applies_to_suppliers,
			in_applies_to_chain				=>	in_applies_to_chain,
			in_applies_to_chain_activities	=>	in_applies_to_chain_activities,
			in_applies_to_initiatives		=>	in_applies_to_initiatives,
			in_applies_to_chain_prod_types	=>	in_applies_to_chain_prod_types,
			in_applies_to_chain_products	=>	in_applies_to_chain_products,
			in_applies_to_chain_prod_supps	=>	in_applies_to_chain_prod_supps,
			in_applies_to_quick_survey		=>	in_applies_to_quick_survey,
			in_applies_to_audits			=>	in_applies_to_audits,
			in_applies_to_compliances		=>	in_applies_to_compliances,
			in_lookup_key					=>	in_lookup_key,
			out_tag_group_id				=>	out_tag_group_id
		);
	ELSE
		tag_pkg.SetTagGroup(
			in_tag_group_id					=>	in_tag_group_id,
			in_name							=>	in_name,
			in_mandatory					=>	in_mandatory,
			in_multi_select					=>	in_multi_select,
			in_applies_to_inds				=>	in_applies_to_inds,
			in_applies_to_regions			=>	in_applies_to_regions,
			in_applies_to_non_comp			=>	in_applies_to_non_comp,
			in_applies_to_suppliers			=>	in_applies_to_suppliers,
			in_applies_to_chain				=>	in_applies_to_chain,
			in_applies_to_chain_activities	=>	in_applies_to_chain_activities,
			in_applies_to_initiatives		=>	in_applies_to_initiatives,
			in_applies_to_chain_prod_types	=>	in_applies_to_chain_prod_types,
			in_applies_to_chain_products	=>	in_applies_to_chain_products,
			in_applies_to_chain_prod_supps	=>	in_applies_to_chain_prod_supps,
			in_applies_to_quick_survey		=>	in_applies_to_quick_survey,
			in_applies_to_audits			=>	in_applies_to_audits,
			in_applies_to_compliances		=>	in_applies_to_compliances,
			in_lookup_key					=>	in_lookup_key,
			out_tag_group_id				=>	out_tag_group_id
		);
	END IF;
	
	-- Preemptive delete from tgm. Any required tgms will be (re)created by a following UpsertTag call.
	DELETE FROM tag_group_member
	 WHERE app_sid = security.security_pkg.GetApp
	   AND tag_group_id = out_tag_group_id;
END;

PROCEDURE UpsertTagGroupDescription(
	in_tag_group_id					IN	tag_group.tag_group_id%TYPE,
	in_name							IN	tag_group_description.name%TYPE,
	in_lang							IN	tag_group_description.lang%TYPE
)
AS
BEGIN
	tag_pkg.SetTagGroupDescription(
		in_tag_group_id		=>	in_tag_group_id,
		in_lang				=>	in_lang,
		in_description		=>	in_name
	);
END;

PROCEDURE UpsertTag(
	in_tag_group_id				IN	tag_group_member.tag_group_id%TYPE,
	in_tag_id					IN	tag.tag_id%TYPE DEFAULT NULL,
	in_tag						IN	tag_description.tag%TYPE,
	in_explanation				IN	tag_description.explanation%TYPE DEFAULT NULL,
	in_lookup_key				IN	tag.lookup_key%TYPE DEFAULT NULL,
	in_pos						IN	tag_group_member.pos%TYPE,
	in_active					IN	tag_group_member.active%TYPE DEFAULT 0,
	out_tag_id					OUT	tag.tag_id%TYPE
)
AS
BEGIN
	tag_pkg.SetTag(
		in_tag_group_id		=>	in_tag_group_id,
		in_tag_id			=>	in_tag_id,
		in_tag				=>	in_tag,
		in_explanation		=>	in_explanation,
		in_pos				=>	CASE WHEN in_active = 0 THEN NULL ELSE in_pos END,
		in_lookup_key		=>	in_lookup_key,
		in_active			=>	in_active,
		out_tag_id			=>	out_tag_id
	);
END;

PROCEDURE UpsertTagDescription(
	in_tag_id					IN	tag.tag_id%TYPE,
	in_tag						IN	tag_description.tag%TYPE,
	in_explanation				IN	tag_description.explanation%TYPE DEFAULT NULL,
	in_lang						IN	tag_description.lang%TYPE
)
AS
BEGIN
	tag_pkg.SetTagDescription(
		in_tag_id			=>	in_tag_id,
		in_lang				=>	in_lang,
		in_description		=>	in_tag,
		in_explanation		=>	in_explanation
	);
END;


-- END TAG GROUP

END;
/
