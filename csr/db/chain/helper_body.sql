CREATE OR REPLACE PACKAGE BODY CHAIN.helper_pkg
IS

PROCEDURE AddUserToChain (
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	BEGIN
		INSERT INTO chain_user
		(user_sid, registration_status_id)
		VALUES
		(in_user_sid, chain_pkg.REGISTERED);
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
END;


PROCEDURE SetInvitationUserTpl (
	in_lang					IN  invitation_user_tpl.lang%TYPE,
	in_header				IN  invitation_user_tpl.header%TYPE,
	in_footer				IN  invitation_user_tpl.footer%TYPE
)
AS
BEGIN

	IF in_header IS NULL AND in_footer IS NULL THEN
		DELETE FROM invitation_user_tpl
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND user_sid = SYS_CONTEXT('SECURITY', 'SID')
		   AND lang = in_lang;

		RETURN;
	END IF;

	BEGIN
		INSERT INTO invitation_user_tpl
		(lang, header, footer)
		VALUES
		(in_lang, in_header, in_footer);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE invitation_user_tpl
			   SET header = in_header, footer = in_footer
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	 		   AND user_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND lang = in_lang;
	END;
END;

PROCEDURE GetInvitationUserTpl (
	in_lang					IN  invitation_user_tpl.lang%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT header, footer
		  FROM invitation_user_tpl
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND user_sid = SYS_CONTEXT('SECURITY', 'SID')
		   AND lang = in_lang;
END;

PROCEDURE GetChainAppSids (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT app_sid
		  FROM implementation;
END;

FUNCTION HasCustomerOptions
RETURN NUMBER
AS
	v_customerOptionsCount	NUMBER;
BEGIN
	-- No security - needs to be checked before user has been authenticated
	SELECT COUNT(*)
	  INTO v_customerOptionsCount
	  FROM customer_options
	 WHERE app_sid = security.security_pkg.GetApp;

	RETURN CASE WHEN v_customerOptionsCount > 0 THEN 1 ELSE 0 END;
END;

PROCEDURE GetCustomerOptions (
	in_host					IN  url_overrides.host%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT 	co.invitation_expiration_days,
				NVL(uo.site_name, co.site_name) site_name,
				co.admin_has_dev_access,
				NVL(uo.support_email, co.support_email) support_email,
				co.newsflash_summary_sp,
				co.questionnaire_filter_class,
				co.last_generate_alert_dtm,
				co.scheduled_alert_intvl_minutes,
				--co.chain_implementation,
				--co.company_helper_sp,
				co.default_receive_sched_alerts,
				co.override_send_qi_path,
				co.override_manage_co_path,
				co.login_page_message,
				co.invite_from_name_addendum,
				co.sched_alerts_enabled,
				co.link_host,
				NVL(co.top_company_sid, 0) top_company_sid,
				co.product_url,
				co.product_url_read_only,
				NVL(co.default_url, '/') default_url,
				co.allow_new_user_request,
				co.allow_company_self_reg,
				co.registration_terms_url,
				co.registration_terms_version,
				co.chain_is_visible_to_top,
				co.inv_mgr_norm_user_full_access,
				co.task_manager_helper_type,
				co.use_type_capabilities,
				co.landing_url,
				co.allow_cc_on_invite,
				co.default_share_qnr_with_on_bhlf,
				co.allow_add_existing_contacts,
				co.req_qnnaire_invitation_landing,
				uo.key,
				co.use_company_type_user_groups,
				co.enable_qnnaire_reminder_alerts,
				co.add_csr_user_to_top_comp,
				co.company_user_create_alert,
				co.use_company_type_css_class,
				co.restrict_change_email_domains,
				co.send_change_email_alert,
				co.purchased_comp_auto_map,
				co.default_qnr_invitation_wiz,
				co.show_invitation_preview,
				co.flow_helper_class_path,
				co.supplier_Filter_Export_Url,
				co.enable_user_visibility_options,
				co.country_risk_enabled,
				co.show_map_on_supplier_list,
				co.force_login_as_company,
				co.show_extra_details_in_graph,
				co.enable_product_compliance,
				co.enable_dedupe_onboarding,
				co.show_audit_coordinator,
				co.allow_duplicate_emails
		  FROM customer_options co
		  LEFT JOIN url_overrides uo ON (uo.app_sid = co.app_sid AND UPPER(uo.host) = UPPER(in_host))
		 WHERE co.app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

FUNCTION GetCompaniesContainer
RETURN security_pkg.T_SID_ID
AS
	v_sid_id 				security_pkg.T_SID_ID;
BEGIN
	v_sid_id := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Chain/Companies');
	RETURN v_sid_id;
END;

FUNCTION GetOrCreatePendingContainer
RETURN security_pkg.T_SID_ID
AS
	v_sid_id 			security_pkg.T_SID_ID;
	v_companies_sid		security_pkg.T_SID_ID := GetCompaniesContainer;
BEGIN
	BEGIN
		v_sid_id := securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, v_companies_sid, 'Pending');
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(security_pkg.GetACT, v_companies_sid, security_pkg.SO_CONTAINER, 'Pending', v_sid_id);
	END;	

	RETURN v_sid_id;
END;

FUNCTION GetCountriesHelperSP
RETURN VARCHAR2
AS
	v_countries_helper_sp VARCHAR2(100);
BEGIN

	SELECT MIN(countries_helper_sp)
	  INTO v_countries_helper_sp
	  FROM customer_options
	 WHERE app_sid = security_pkg.getApp;

	RETURN v_countries_helper_sp;
END;

PROCEDURE GetCountries (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_countries_helper_sp	VARCHAR2(100) DEFAULT GetCountriesHelperSP;
	c_cursor				security_pkg.T_OUTPUT_CUR;
BEGIN
	--we can populate countries based on the clients specified list
	IF v_countries_helper_sp IS NOT NULL THEN
		EXECUTE IMMEDIATE (
			'BEGIN ' || v_countries_helper_sp || '(:out_cur); END;'
		) USING c_cursor;

		out_cur := c_cursor;
	ELSE
		OPEN out_cur FOR
			SELECT country_code, name
			  FROM v$country
			 ORDER BY LOWER(name);
	END IF;
END;

PROCEDURE GetActiveCountries (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT country_code, name
		  FROM v$country
		 WHERE country_code IN (SELECT DISTINCT country_code FROM company WHERE deleted=0)
		 ORDER BY LOWER(name);
END;

FUNCTION GetChainCountryCode(
	in_country_name		v$country.name%TYPE
) RETURN v$country.country_code%TYPE
AS
	v_country_code v$country.country_code%TYPE;
BEGIN
	BEGIN
		SELECT country_code
		  INTO v_country_code
		  FROM v$country
		 WHERE UPPER(name) = UPPER(in_country_name);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Country name: "' || in_country_name || '" was not found.');
	END;

	RETURN v_country_code;
END;

FUNCTION StringToDate (
	in_str_val				IN  VARCHAR2
) RETURN DATE
AS
BEGIN
	RETURN TO_DATE(in_str_val, 'DD/MM/YY HH24:MI:SS');
END;

FUNCTION NumericArrayEmpty(
	in_numbers				IN T_NUMBER_ARRAY
) RETURN NUMBER
AS
BEGIN
	RETURN CASE WHEN in_numbers.count = 1 AND in_numbers(1) IS NULL THEN 1 ELSE 0 END;
END;

FUNCTION NumericArrayToTable(
	in_numbers				IN T_NUMBER_ARRAY
) RETURN T_NUMERIC_TABLE
AS
	v_table 	T_NUMERIC_TABLE := T_NUMERIC_TABLE();
BEGIN
	IF in_numbers.COUNT = 0 OR (in_numbers.COUNT = 1 AND in_numbers(in_numbers.FIRST) IS NULL) THEN
        -- hack for ODP.NET which doesn't support empty arrays - just return nothing
		RETURN v_table;
    END IF;

	FOR i IN in_numbers.FIRST .. in_numbers.LAST
	LOOP
		BEGIN
			v_table.extend;
			v_table(v_table.COUNT) := T_NUMERIC_ROW( in_numbers(i), v_table.COUNT );
		END;
	END LOOP;
	RETURN v_table;
END;

PROCEDURE IsChainAdmin  (
	out_result				OUT NUMBER
)
AS
BEGIN
	IF IsChainAdmin THEN
		out_result := chain_pkg.ACTIVE;
	ELSE
		out_result := chain_pkg.INACTIVE;
	END IF;
END;


FUNCTION IsChainAdmin
RETURN BOOLEAN
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_count					NUMBER(10) DEFAULT 0;
	v_cag_sid				security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_cag_sid := securableobject_pkg.GetSIDFromPath(v_act_id, SYS_CONTEXT('SECURITY', 'APP'), 'Groups/'||chain_pkg.CHAIN_ADMIN_GROUP);
	EXCEPTION
		WHEN security_pkg.ACCESS_DENIED THEN
			RETURN FALSE;
	END;

	IF v_cag_sid <> 0 THEN
		SELECT COUNT(*)
		  INTO v_count
		  FROM security.act
		 WHERE act_id = v_act_id
		   AND sid_id = v_cag_sid;

		 IF v_count > 0 THEN
			RETURN TRUE;
		 END IF;
	END IF;

	RETURN FALSE;
END;

FUNCTION IsChainAdmin (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_count					NUMBER(10) DEFAULT 0;
	v_cag_sid				security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_cag_sid := securableobject_pkg.GetSIDFromPath(v_act_id, SYS_CONTEXT('SECURITY', 'APP'), 'Groups/'||chain_pkg.CHAIN_ADMIN_GROUP);
	EXCEPTION
		WHEN security_pkg.ACCESS_DENIED THEN
			RETURN FALSE;
	END;

	IF v_cag_sid <> 0 THEN
		SELECT COUNT(*)
		  INTO v_count
		  FROM (
		  		SELECT sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner
				  FROM security.securable_object
				 WHERE sid_id IN (
						SELECT group_sid_id FROM security.group_members START WITH member_sid_id = in_user_sid
			   CONNECT BY NOCYCLE PRIOR group_sid_id = member_sid_id)
		    ) T
		 WHERE T.sid_id = v_cag_sid;

		 IF v_count > 0 THEN
			RETURN TRUE;
		 END IF;
	END IF;

	RETURN FALSE;
END;

PROCEDURE IsChainUser  (
	out_result				OUT NUMBER
)
AS
BEGIN
	IF IsChainUser THEN
		out_result := chain_pkg.ACTIVE;
	ELSE
		out_result := chain_pkg.INACTIVE;
	END IF;
END;


FUNCTION IsChainUser
RETURN BOOLEAN
AS
BEGIN
	RETURN IsChainUser(security_pkg.GetSid);
END;

FUNCTION IsChainUserNum (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN NUMBER
AS
BEGIN
	IF IsChainUser(in_user_sid) = TRUE THEN
		RETURN 1;
	END IF;

	RETURN 0;
END;

FUNCTION IsChainUser (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_count					NUMBER(10) DEFAULT 0;
	v_cug_sid				security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_cug_sid := securableobject_pkg.GetSIDFromPath(v_act_id, SYS_CONTEXT('SECURITY', 'APP'), 'Groups/'||chain_pkg.CHAIN_USER_GROUP);
	EXCEPTION
		WHEN security_pkg.ACCESS_DENIED THEN
			RETURN FALSE;
	END;

	IF v_cug_sid <> 0 THEN
		SELECT COUNT(*)
		  INTO v_count
		  FROM (
		  		SELECT sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner
				  FROM security.securable_object
				 WHERE sid_id IN (
						SELECT group_sid_id FROM security.group_members START WITH member_sid_id = in_user_sid
			   CONNECT BY NOCYCLE PRIOR group_sid_id = member_sid_id)
		    ) T
		 WHERE T.sid_id = v_cug_sid;

		 IF v_count > 0 THEN
			RETURN TRUE;
		 END IF;
	END IF;

	RETURN FALSE;
END;

FUNCTION IsInvitationRespondant (
	in_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN in_sid = securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, SYS_CONTEXT('SECURITY', 'APP'), 'Chain/BuiltIn/Invitation Respondent');
END;

PROCEDURE IsInvitationRespondant (
	in_sid					IN  security_pkg.T_SID_ID,
	out_result				OUT NUMBER
)
AS
BEGIN
	IF IsInvitationRespondant(in_sid) THEN
		out_result := 1;
	ELSE
		out_result := 0;
	END IF;
END;


FUNCTION IsElevatedAccount
RETURN BOOLEAN
AS
BEGIN
	IF security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RETURN TRUE;
	END IF;

	IF IsInvitationRespondant(security_pkg.GetSid) THEN
		RETURN TRUE;
	END IF;

	RETURN security_pkg.GetSid = securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, SYS_CONTEXT('SECURITY', 'APP'), 'Users/UserCreatorDaemon');
END;

PROCEDURE LogonUCD (
	in_company_sid			IN  security_pkg.T_SID_ID DEFAULT NULL
)
AS
	v_act_id				security_pkg.T_ACT_ID;
	v_app_sid				security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP');
	v_prev_act_id			security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT');
	v_prev_user_sid			security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID');
	v_prev_company_sid		security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
BEGIN

	user_pkg.LogonAuthenticatedPath(v_app_sid, 'users/UserCreatorDaemon', 300, v_app_sid, v_act_id);

	IF in_company_sid IS NOT NULL THEN
		company_pkg.SetCompany(in_company_sid);
	ELSE
		company_pkg.SetCompany(v_prev_company_sid);
	END IF;
	
	INSERT INTO ucd_logon
	(app_sid, ucd_act_id, previous_act_id, previous_user_sid, previous_company_sid)
	VALUES
	(v_app_sid, v_act_id, v_prev_act_id, v_prev_user_sid, v_prev_company_sid);
END;

PROCEDURE RevertLogonUCD
AS
	v_row					ucd_logon%ROWTYPE;
BEGIN
	-- let this blow up if nothing's found
	SELECT *
	  INTO v_row
	  FROM ucd_logon
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ucd_act_id = SYS_CONTEXT('SECURITY', 'ACT');

	-- Logoff unsets the app_sid on sys_context
	-- There's no way to log that session out without leaving the user's original
	-- sys_context missing an app_sid (and therefore RLS will not be working)
	-- So now we don't log this off and instead wait for the UCD's ACT to timeout
	-- instead
	-- user_pkg.Logoff(v_row.ucd_act_id);

	Security_pkg.SetACTAndSID(v_row.previous_act_id, v_row.previous_user_sid);

	IF v_row.previous_company_sid IS NOT NULL THEN
		company_pkg.SetCompany(v_row.previous_company_sid);
	END IF;

	DELETE FROM ucd_logon
	 WHERE ucd_act_id = v_row.ucd_act_id;
END;

FUNCTION GetTopCompanySid
RETURN security_pkg.T_SID_ID
AS
	v_company_sid		security_pkg.T_SID_ID;
BEGIN

	SELECT top_company_sid
	  INTO v_company_sid
	  FROM customer_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');

	IF v_company_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Top company sid is not set');
	END IF;

	RETURN v_company_sid;
END;

FUNCTION INTERNAL_IsSidTopCompany (
	in_company_sid			IN  security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_is_top_company	security_pkg.T_SID_ID := -1;
	v_company_sid		security_pkg.T_SID_ID;
BEGIN

	SELECT top_company_sid
	  INTO v_company_sid
	  FROM customer_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');

	IF v_company_sid IS NULL THEN
		RETURN 0;
	END IF;

	IF v_company_sid = in_company_sid THEN
		RETURN 1;
	END IF;

	RETURN 0;
END;

FUNCTION IsTopCompany
RETURN NUMBER
AS
	v_is_top_company	security_pkg.T_SID_ID := -1;
BEGIN
	-- let specific apps override this e.g shared applications with multiple nominal "top" companies
	v_is_top_company := chain_link_pkg.IsTopCompany;
	IF v_is_top_company >= 0 THEN
		-- if we get here the link pkg must have done somethhing
		RETURN v_is_top_company;
	END IF;

	RETURN INTERNAL_IsSidTopCompany(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
END;

FUNCTION IsSidTopCompany (
	in_company_sid			IN  security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_is_top_company	security_pkg.T_SID_ID := -1;
BEGIN
	-- let specific apps override this e.g shared applications with multiple nominal "top" companies
	v_is_top_company := chain_link_pkg.IsSidTopCompany(in_company_sid);
	IF v_is_top_company >= 0 THEN
		-- if we get here the link pkg must have done somethhing
		RETURN v_is_top_company;
	END IF;

	RETURN INTERNAL_IsSidTopCompany(in_company_sid);
END;


-- is the supply chain transparent for the logged on company
-- it will currently only be transparent if the company is a logged on company and chain_is_visible_to_top == 1
FUNCTION IsChainTrnsprntForMyCmpny
RETURN BOOLEAN
AS
	v_transparent_to_top	customer_options.chain_is_visible_to_top%TYPE;
	v_company_sid			security_pkg.T_SID_ID;
BEGIN

	SELECT chain_is_visible_to_top
	  INTO v_transparent_to_top
	  FROM customer_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');

	RETURN ((IsTopCompany=1) AND (v_transparent_to_top=1));

END;


FUNCTION Flag (
	in_flags				IN  chain_pkg.T_FLAG,
	in_flag					IN  chain_pkg.T_FLAG
) RETURN chain_pkg.T_FLAG
AS
BEGIN
	IF security.bitwise_pkg.bitand(in_flags, in_flag) = 0 THEN
		RETURN 0;
	END IF;

	RETURN 1;
END;

FUNCTION NormaliseCompanyName (
	in_company_name			IN  company.name%TYPE
) RETURN security_pkg.T_SO_NAME
DETERMINISTIC
AS
BEGIN
	RETURN REPLACE(TRIM(REGEXP_REPLACE(TRANSLATE(in_company_name, '.,-()/\''', '        '), '  +', ' ')), '/', '\');
END;

FUNCTION GenerateSOName (
	in_company_name			IN  company.name%TYPE,
	in_company_sid			IN  security_pkg.T_SID_ID
) RETURN security_pkg.T_SO_NAME
DETERMINISTIC
AS
BEGIN
	RETURN NormaliseCompanyName(in_company_name) || ' (' || in_company_sid || ')';
END;

PROCEDURE UpdateSector (
	in_sector_id			IN	sector.sector_id%TYPE,
	in_description			IN	sector.description%TYPE,
	in_parent_sector_id		IN	sector.parent_sector_id%TYPE DEFAULT NULL
)
AS
	v_description 	sector.description%TYPE DEFAULT REPLACE(in_description, '/', '\'); --'
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'UpdateSector can only be run as BuiltIn/Administrator');
	END IF;

	BEGIN
		INSERT INTO sector (sector_id, description, parent_sector_id, is_other)
		VALUES (in_sector_id, v_description, in_parent_sector_id, CASE WHEN LOWER(v_description) = 'other' THEN 1 ELSE 0 END);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE sector
			   SET description = v_description,
			       parent_sector_id = in_parent_sector_id,
			       is_other = CASE WHEN LOWER(v_description) = 'other' THEN 1 ELSE 0 END
			 WHERE sector_id = in_sector_id
			   AND app_sid = security_pkg.GetApp;
	END;
END;

PROCEDURE DeleteSector (
	in_sector_id			IN	sector.sector_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DeleteSector can only be run as BuiltIn/Administrator');
	END IF;

	UPDATE sector
	   SET active = chain_pkg.INACTIVE
	 WHERE app_sid = security_pkg.GetApp
	   AND sector_id = in_sector_id;
END;

PROCEDURE GetSectors (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Sector list isn't confidential atm
	
	-- ************* N.B. that's a literal 0x1 character in sys_connect_by_path, not a space **************
	OPEN out_cur FOR
		SELECT sector_id, description, parent_sector_id, LEVEL lvl, is_other,
				SUBSTR(REPLACE(SYS_CONNECT_BY_PATH(description, ''), '', '/'), 2) path
		  FROM sector
		 START WITH app_sid = security_pkg.GetApp
		   AND active = chain_pkg.ACTIVE
		   AND parent_sector_id IS NULL
	   CONNECT BY PRIOR sector_id = parent_sector_id
		   AND PRIOR app_sid = app_sid
		   AND active = chain_pkg.ACTIVE
		 ORDER SIBLINGS BY is_other, LOWER(description);
END;

PROCEDURE GetActiveSectors (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Sector list isn't confidential atm
	
	-- ************* N.B. that's a literal 0x1 character in sys_connect_by_path, not a space **************
	OPEN out_cur FOR
		SELECT sector_id, description, parent_sector_id, path, is_other
		  FROM (
			SELECT sector_id, description, parent_sector_id, active, is_other,
					SUBSTR(REPLACE(SYS_CONNECT_BY_PATH(description, ''), '', '/'), 2) path
			  FROM sector
			 START WITH app_sid = security_pkg.GetApp
				  AND sector_id IN (SELECT c.sector_id FROM company c WHERE deleted = 0)
			CONNECT BY PRIOR parent_sector_id = sector_id AND PRIOR app_sid = app_sid
			)
		 WHERE active = chain_pkg.ACTIVE
		 ORDER BY is_other, LOWER(description);
END;

PROCEDURE UpdateBusinessUnit (
	in_business_unit_id		IN	business_unit.business_unit_id%TYPE,
	in_description			IN	business_unit.description%TYPE,
	in_parent_business_unit_id	IN	business_unit.parent_business_unit_id%TYPE DEFAULT NULL
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'UpdateBusinessUnit can only be run as BuiltIn/Administrator');
	END IF;

	BEGIN
		INSERT INTO business_unit (business_unit_id, description, parent_business_unit_id)
		VALUES (in_business_unit_id, in_description, in_parent_business_unit_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE business_unit
			   SET description = in_description,
			       parent_business_unit_id = in_parent_business_unit_id
			 WHERE business_unit_id = in_business_unit_id
			   AND app_sid = security_pkg.GetApp;
	END;
END;

PROCEDURE DeleteBusinessUnit (
	in_business_unit_id		IN	business_unit.business_unit_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DeleteBusinessUnit can only be run as BuiltIn/Administrator');
	END IF;

	UPDATE business_unit
	   SET active = chain_pkg.INACTIVE
	 WHERE app_sid = security_pkg.GetApp
	   AND business_unit_id = in_business_unit_id;
END;

FUNCTION GetBusinessUnitId (
	in_description			IN  business_unit.description%TYPE
) RETURN NUMBER
AS
	v_id					NUMBER;
BEGIN
	BEGIN
		SELECT business_unit_id
		  INTO v_id
		  FROM business_unit
		 WHERE LOWER(description) = LOWER(in_description);

		RETURN v_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN 0;
	END;
END;

PROCEDURE GetBusinessUnits (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Business Unit list list isn't confidential atm
	
	-- ************* N.B. that's a literal 0x1 character in sys_connect_by_path, not a space **************
	OPEN out_cur FOR
		SELECT business_unit_id, description, parent_business_unit_id, LEVEL lvl,
				SUBSTR(REPLACE(SYS_CONNECT_BY_PATH(description, ''), '', '/'), 2) path
		  FROM business_unit
		 START WITH app_sid = security_pkg.GetApp
		   AND active = chain_pkg.ACTIVE
		   AND parent_business_unit_id IS NULL
		CONNECT BY PRIOR business_unit_id = parent_business_unit_id AND active = chain_pkg.ACTIVE
		 ORDER SIBLINGS BY LOWER(description);
END;

PROCEDURE GetActiveBusinessUnits (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Sector list isn't confidential atm
	
	-- ************* N.B. that's a literal 0x1 character in sys_connect_by_path, not a space **************
	OPEN out_cur FOR
		SELECT business_unit_id, description, parent_business_unit_id, path
		  FROM (
			SELECT business_unit_id, description, parent_business_unit_id, active,
					SUBSTR(REPLACE(SYS_CONNECT_BY_PATH(description, ''), '', '/'), 2) path
			  FROM business_unit
			 START WITH app_sid = security_pkg.GetApp
				  AND business_unit_id IN (SELECT bus.business_unit_id FROM business_unit_supplier bus)
			CONNECT BY PRIOR parent_business_unit_id = business_unit_id AND PRIOR app_sid = app_sid
			)
		 WHERE active = chain_pkg.ACTIVE
		 ORDER BY LOWER(description);
END;

PROCEDURE DeleteReferenceLabel (
	in_reference_id						IN reference.reference_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) AND csr.csr_user_pkg.IsSuperAdmin=0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DeleteReferenceLabel can only be run as a super admin or BuiltIn/Administrator');
	END IF;

	DELETE FROM company_reference
	 WHERE reference_id = in_reference_id;

	DELETE FROM reference_capability
	 WHERE reference_id = in_reference_id;

	DELETE FROM reference_company_type
	 WHERE reference_id = in_reference_id;

	DELETE FROM reference
	 WHERE reference_id = in_reference_id;
END;

PROCEDURE SaveReferenceLabel (
	in_reference_id						IN reference.reference_id%TYPE,
	in_lookup_key						IN reference.lookup_key%TYPE,
	in_label							IN reference.label%TYPE,
	in_mandatory						IN reference.mandatory%TYPE,
	in_reference_uniqueness_id			IN reference.reference_uniqueness_id%TYPE,
	in_reference_location_id			IN reference.reference_location_id%TYPE DEFAULT 0,
	in_show_in_filter					IN reference.show_in_filter%TYPE DEFAULT 1,
	in_reference_validation_id			IN reference.reference_validation_id%TYPE DEFAULT 0,
	in_company_type_ids					IN T_NUMBER_ARRAY,
	out_reference_id					OUT reference.reference_id%TYPE
)
AS
	v_company_type_ids					T_NUMERIC_TABLE := NumericArrayToTable(in_company_type_ids);
BEGIN
	out_reference_id := in_reference_id;
	
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) AND csr.csr_user_pkg.IsSuperAdmin=0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SaveReferenceLabel can only be run as a super admin or BuiltIn/Administrator');
	END IF;

	IF out_reference_id IS NULL THEN
		BEGIN
			INSERT INTO reference (reference_id, lookup_key, label, mandatory, reference_uniqueness_id, reference_location_id, show_in_filter, reference_validation_id)
			VALUES (reference_id_seq.nextval, in_lookup_key, in_label, in_mandatory, in_reference_uniqueness_id, in_reference_location_id, in_show_in_filter, in_reference_validation_id)
			RETURNING reference_id INTO out_reference_id;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				RAISE_APPLICATION_ERROR(csr.csr_data_pkg.ERR_OBJECT_ALREADY_EXISTS,'A reference with lookup key '''|| in_lookup_key ||'''  already exists.');
		END;
	ELSE
		UPDATE reference
		   SET label = in_label,
			   mandatory = in_mandatory,
			   reference_uniqueness_id = in_reference_uniqueness_id,
			   reference_location_id = in_reference_location_id,
			   show_in_filter = in_show_in_filter,
			   reference_validation_id = in_reference_validation_id
		 WHERE reference_id = out_reference_id
		   AND app_sid = security_pkg.GetApp;
	END IF;

	DELETE FROM reference_company_type
	 WHERE reference_id = out_reference_id
	   AND company_type_id NOT IN (
		SELECT item
		  FROM TABLE(v_company_type_ids)
		 WHERE item IS NOT NULL
	   );

	INSERT INTO reference_company_type (reference_id, company_type_id)
	SELECT out_reference_id, item
	  FROM TABLE(v_company_type_ids)
	 WHERE item NOT IN (
		SELECT company_type_id
		  FROM reference_company_type
		 WHERE reference_id = out_reference_id
	 );

END;

FUNCTION GetRefPermsByType (
	in_for_company_type_id				IN reference_company_type.company_type_id%TYPE DEFAULT NULL,
	in_company_sid						IN company.company_sid%TYPE DEFAULT NULL,
	in_reference_id						IN reference.reference_id%TYPE DEFAULT NULL,
	in_reference_location_id			IN reference.reference_location_id%TYPE DEFAULT NULL
)
RETURN T_REF_PERM_TABLE
AS
	v_user_sid							security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'SID');
	v_company_sid						security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_region_sid						security_pkg.T_SID_ID := csr.supplier_pkg.GetRegionSid(v_company_sid);
	v_company_type_id					company.company_type_id%TYPE := company_type_pkg.GetCompanyTypeId;
	v_for_company_type_id				company.company_type_id%TYPE := in_for_company_type_id;
	v_reference_perms					T_REF_PERM_TABLE;
BEGIN
	IF in_company_sid IS NOT NULL THEN
		v_for_company_type_id := company_type_pkg.GetCompanyTypeId(in_company_sid);
	END IF;

	type_capability_pkg.FillUserGroups;

	SELECT T_REF_PERM_ROW(r.reference_id, caps.primary_company_type_id, caps.secondary_company_type_id, NVL(caps.permission_set, 0))
	  BULK COLLECT INTO v_reference_perms
	  FROM reference r
	  LEFT JOIN reference_company_type rct ON r.reference_id = rct.reference_id AND rct.company_type_id = v_for_company_type_id
	  LEFT JOIN (
				SELECT rc.reference_id,
					   rc.primary_company_type_id,
					   rc.secondary_company_type_id,
					   MAX(BITAND(rc.permission_set, 1)) + -- security_pkg.PERMISSION_READ
					   MAX(BITAND(rc.permission_set, 2)) permission_set -- security_pkg.PERMISSION_WRITE
				  FROM reference_capability rc
				 WHERE rc.primary_company_type_id = v_company_type_id 
				   AND (
					(
						(in_company_sid = v_company_sid OR in_company_sid IS NULL)
						AND rc.primary_company_type_id = NVL(v_for_company_type_id, rc.primary_company_type_id)
						AND rc.secondary_company_type_id IS NULL
					) OR (
						(in_company_sid != v_company_sid OR in_company_sid IS NULL)
						AND rc.secondary_company_type_id = NVL(v_for_company_type_id, rc.secondary_company_type_id)
					)
				 ) AND (
					EXISTS (
						SELECT NULL
						  FROM tt_user_groups tug
						  JOIN company_group cg ON tug.company_sid = cg.company_sid AND tug.group_sid = cg.group_sid
						 WHERE cg.company_group_type_id = rc.primary_company_group_type_id
					) OR EXISTS (
						SELECT NULL
						  FROM csr.region_role_member rrm
						 WHERE rrm.role_sid = rc.primary_company_type_role_sid 
						   AND rrm.user_sid = v_user_sid
						   AND rrm.region_sid = v_region_sid
					)
				)
				GROUP BY rc.reference_id,
					     rc.primary_company_type_id,
					     rc.secondary_company_type_id
		  ) caps ON caps.reference_id = r.reference_id
	 WHERE (in_reference_id IS NULL OR r.reference_id = in_reference_id)
	   AND (in_reference_location_id IS NULL OR r.reference_location_id = in_reference_location_id)
	   AND (
			v_for_company_type_id IS NULL
			OR rct.company_type_id = v_for_company_type_id
			OR NOT EXISTS (
				SELECT NULL
				  FROM reference_company_type rct2
				 WHERE r.app_sid = rct2.app_sid
				   AND r.reference_id = rct2.reference_id
		   )
		 );

	RETURN v_reference_perms;
END;

FUNCTION GetBestRefPerms (
	in_for_company_type_id				IN reference_company_type.company_type_id%TYPE DEFAULT NULL,
	in_company_sid						IN company.company_sid%TYPE,
	in_reference_id						IN reference.reference_id%TYPE DEFAULT NULL,
	in_reference_location_id			IN reference.reference_location_id%TYPE DEFAULT NULL
)
RETURN T_REF_PERM_TABLE
AS
	v_ref_perms_by_type					T_REF_PERM_TABLE;
	v_best_ref_perms					T_REF_PERM_TABLE;
BEGIN
	v_ref_perms_by_type := GetRefPermsByType (
		in_for_company_type_id		=> in_for_company_type_id,
		in_company_sid				=> in_company_sid,
		in_reference_id				=> in_reference_id,
		in_reference_location_id	=> in_reference_location_id
	);

	SELECT T_REF_PERM_ROW(
				rp.reference_id,
				NULL, 
				NULL,
				MAX(BITAND(rp.permission_set, 1)) + -- security_pkg.PERMISSION_READ
				MAX(BITAND(rp.permission_set, 2)) -- security_pkg.PERMISSION_WRITE
		   )
	  BULK COLLECT INTO v_best_ref_perms
	  FROM TABLE(v_ref_perms_by_type) rp
	 GROUP BY rp.reference_id;

	RETURN v_best_ref_perms;
END;

PROCEDURE INTERNAL_GetReferenceLabels (
	in_reference_perms					IN T_REF_PERM_TABLE,
	out_cur								OUT security_pkg.T_OUTPUT_CUR,
	out_ct_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT r.reference_id, r.lookup_key, r.label, r.mandatory, 
			   r.reference_uniqueness_id, r.reference_location_id, 
			   r.reference_filter_type_id, r.show_in_filter,
			   r.reference_validation_id, vr.validation_regex, vr.validation_text,
			   perms.permission_set
		  FROM reference r
		  JOIN TABLE (in_reference_perms) perms ON r.reference_id = perms.reference_id
		  JOIN reference_validation vr ON r.reference_validation_id = vr.reference_validation_id
		 ORDER BY r.lookup_key;

	OPEN out_ct_cur FOR
		SELECT rct.reference_id, rct.company_type_id, ct.singular, ct.plural, ct.lookup_key
		  FROM reference_company_type rct
		  JOIN company_type ct ON rct.app_sid = ct.app_sid AND rct.company_type_id = ct.company_type_id
		  JOIN TABLE (in_reference_perms) perms ON rct.reference_id = perms.reference_id;
END;

PROCEDURE GetPermissibleReferences (
	in_for_company_type_id				IN reference_company_type.company_type_id%TYPE DEFAULT NULL,
	in_reference_location_id			IN reference.reference_location_id%TYPE DEFAULT NULL,
	out_cur								OUT security_pkg.T_OUTPUT_CUR,
	out_ct_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_reference_perms					T_REF_PERM_TABLE;
BEGIN
	-- No security, reference labels aren't restricted
		
	v_reference_perms := GetBestRefPerms(
		in_for_company_type_id => in_for_company_type_id,
		in_reference_location_id => in_reference_location_id
	);

	INTERNAL_GetReferenceLabels(
		in_reference_perms => v_reference_perms, 
		out_cur => out_cur,
		out_ct_cur => out_ct_cur
	);
END;

PROCEDURE GetPermissibleReferencesBySid (
	in_company_sid						IN company.company_sid%TYPE,
	in_reference_location_id			IN reference.reference_location_id%TYPE DEFAULT NULL,
	out_cur								OUT security_pkg.T_OUTPUT_CUR,
	out_ct_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_reference_perms					T_REF_PERM_TABLE;
BEGIN
	-- No security, reference labels aren't restricted
		
	v_reference_perms := GetBestRefPerms(
		in_company_sid => in_company_sid,
		in_reference_location_id => in_reference_location_id
	);

	INTERNAL_GetReferenceLabels(
		in_reference_perms => v_reference_perms, 
		out_cur => out_cur,
		out_ct_cur => out_ct_cur
	);
END;

PROCEDURE GetReferences (
	out_cur								OUT security_pkg.T_OUTPUT_CUR,
	out_ct_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT r.reference_id, r.lookup_key, r.label, r.mandatory, 
			   r.reference_uniqueness_id, r.reference_location_id, 
			   r.reference_filter_type_id, r.show_in_filter,
			   r.reference_validation_id, vr.validation_regex, vr.validation_text
		  FROM reference r
		  JOIN reference_validation vr ON r.reference_validation_id = vr.reference_validation_id
		 ORDER BY r.lookup_key;

	OPEN out_ct_cur FOR
		SELECT rct.reference_id, rct.company_type_id, ct.singular, ct.plural, ct.lookup_key
		  FROM reference_company_type rct
		  JOIN company_type ct ON rct.app_sid = ct.app_sid AND rct.company_type_id = ct.company_type_id;
END;

PROCEDURE GetReferenceValidations(
	out_cur 		OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT reference_validation_id, description, validation_regex, validation_text
		  FROM reference_validation;
END;

PROCEDURE GetAllReferenceLabelValues (
	in_lookup_key				IN reference.lookup_key%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- this is bad practice but currently in use by Otto
	-- changed so that this only returns data if the filter type is set to 1
	-- (i.e. you can see all possible values in the filter options).
	-- in all cases other than Otto, this should be handled by tag groups
	OPEN out_cur FOR
		SELECT DISTINCT cr.value
		  FROM company_reference cr
		  JOIN reference r ON cr.app_sid = r.app_sid AND cr.reference_id = r.reference_id
		 WHERE r.lookup_key = in_lookup_key
		   AND cr.value IS NOT NULL
		   AND r.reference_filter_type_id = 1;
END;

PROCEDURE SetReferenceCapability (
	in_reference_id						IN reference_capability.reference_id%TYPE,
	in_primary_company_type_id			IN reference_capability.primary_company_type_id%TYPE,
	in_primary_comp_group_type_id		IN reference_capability.primary_company_group_type_id%TYPE,
	in_primary_comp_type_role_sid		IN reference_capability.primary_company_type_role_sid%TYPE,
	in_secondary_company_type_id		IN reference_capability.secondary_company_type_id%TYPE,
	in_permission_set					IN reference_capability.permission_set%TYPE
)
AS
	v_company_ca_group_type_id 	company_group_type.company_group_type_id%TYPE DEFAULT company_pkg.GetCompanyGroupTypeId(chain_pkg.CHAIN_ADMIN_GROUP);
	v_ca_permission_set			security_pkg.T_PERMISSION DEFAULT 0;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) AND csr.csr_user_pkg.IsSuperAdmin=0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetReferenceCapability can only be run as a super admin or BuiltIn/Administrator');
	END IF;

	IF NVL(in_permission_set, 0) = 0 THEN
		DELETE FROM reference_capability
		 WHERE reference_id = in_reference_id
		   AND primary_company_type_id = in_primary_company_type_id
		   AND NVL(primary_company_group_type_id, 0) = NVL(in_primary_comp_group_type_id, 0)
		   AND NVL(primary_company_type_role_sid, 0) = NVL(in_primary_comp_type_role_sid, 0)
		   AND NVL(secondary_company_type_id, 0) = NVL(in_secondary_company_type_id, 0);
	ELSE
		BEGIN
			INSERT INTO reference_capability (
				reference_id, primary_company_type_id,
				primary_company_group_type_id, primary_company_type_role_sid,
				secondary_company_type_id, permission_set
			) VALUES (
				in_reference_id, in_primary_company_type_id,
				in_primary_comp_group_type_id, in_primary_comp_type_role_sid,
				in_secondary_company_type_id, in_permission_set
			);
		EXCEPTION
			WHEN dup_val_on_index THEN	
				UPDATE reference_capability
				   SET permission_set = in_permission_set
				 WHERE reference_id = in_reference_id
				   AND primary_company_type_id = in_primary_company_type_id
				   AND NVL(primary_company_group_type_id, 0) = NVL(in_primary_comp_group_type_id, 0)
				   AND NVL(primary_company_type_role_sid, 0) = NVL(in_primary_comp_type_role_sid, 0)
				   AND NVL(secondary_company_type_id, 0) = NVL(in_secondary_company_type_id, 0);
		END;
	END IF;

	IF NVL(in_primary_comp_group_type_id, 0) != v_company_ca_group_type_id THEN
		v_ca_permission_set := 0;
		
		FOR p IN (
			SELECT rc.permission_set
			  FROM reference_capability rc
			  LEFT JOIN company_group_type cgt ON rc.primary_company_group_type_id = cgt.company_group_type_id
			 WHERE rc.reference_id = in_reference_id
			   AND rc.primary_company_type_id = in_primary_company_type_id
			   AND NVL(secondary_company_type_id, 0) = NVL(in_secondary_company_type_id, 0)
			   AND (cgt.is_global = 0 OR cgt.company_group_type_id IS NULL)
		) LOOP
			v_ca_permission_set := security.bitwise_pkg.bitor(v_ca_permission_set, p.permission_set);
		END LOOP;

		SetReferenceCapability(
			in_reference_id					=> in_reference_id,
			in_primary_company_type_id		=> in_primary_company_type_id,
			in_primary_comp_group_type_id	=> v_company_ca_group_type_id,
			in_primary_comp_type_role_sid	=> NULL,
			in_secondary_company_type_id	=> in_secondary_company_type_id,
			in_permission_set				=> v_ca_permission_set
		);
	END IF;
END;

PROCEDURE GetReferenceCapabilities (
	in_reference_id						IN reference_capability.reference_id%TYPE,
	in_primary_company_type_id			IN reference_capability.primary_company_type_id%TYPE,
	in_secondary_company_type_id		IN reference_capability.secondary_company_type_id%TYPE,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- no security needed

	OPEN out_cur FOR
		SELECT reference_id, primary_company_type_id,
			   primary_company_group_type_id, primary_company_type_role_sid,
			   secondary_company_type_id, permission_set
		  FROM reference_capability
		 WHERE reference_id = in_reference_id
		   AND primary_company_type_id = in_primary_company_type_id
		   AND NVL(secondary_company_type_id, 0) = NVL(in_secondary_company_type_id, 0);
END;

FUNCTION UseTypeCapabilities
RETURN BOOLEAN
AS
	v_result			customer_options.use_type_capabilities%TYPE;
BEGIN
	BEGIN
		SELECT use_type_capabilities
		  INTO v_result
		  FROM customer_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN FALSE;
	END;

	RETURN v_result = 1;
END;

FUNCTION UseTraditionalCapabilities
RETURN BOOLEAN
AS
BEGIN
	RETURN NOT UseTypeCapabilities;
END;

FUNCTION AddSidLinkLookup (
	in_sids			IN	security.T_SID_TABLE
) RETURN NUMBER
AS
	v_id			tt_sid_link_lookup.id%TYPE;
BEGIN
	SELECT link_lookup_id_seq.nextval INTO v_id FROM dual;

	INSERT INTO tt_sid_link_lookup (id, sid)
	SELECT v_id, column_value
	  FROM TABLE(in_sids);

	RETURN v_id;
END;

FUNCTION AddFilterSidLinkLookup (
	in_sids			IN	T_FILTERED_OBJECT_TABLE
) RETURN NUMBER
AS
	v_id			tt_sid_link_lookup.id%TYPE;
BEGIN
	SELECT link_lookup_id_seq.nextval INTO v_id FROM dual;

	INSERT INTO tt_sid_link_lookup (id, sid)
	SELECT v_id, object_id
	  FROM TABLE(in_sids);

	RETURN v_id;
END;

FUNCTION IsShareQnrWithOnBehalfEnabled
RETURN NUMBER
AS
	v_is_share_with_on_bhf_enabled	NUMBER(1, 0);
BEGIN

	SELECT default_share_qnr_with_on_bhlf
	  INTO v_is_share_with_on_bhf_enabled
	  FROM customer_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');

	RETURN v_is_share_with_on_bhf_enabled;
END;

FUNCTION UseCompanyTypeUserGroups
RETURN NUMBER
AS
	v_use_groups_enabled	NUMBER(1, 0);
BEGIN

	SELECT use_company_type_user_groups
	  INTO v_use_groups_enabled
	  FROM customer_options
	 WHERE app_sid = security_pkg.getApp;

	RETURN v_use_groups_enabled;
END;

-- Adds write/delete deny for registered users on the given tree. Also bumps UCD with full access to the top of the list to ensure everything still works.
-- Use this to lock chain region trees to prevent users from editing/deleting them.
PROCEDURE LockRegionTree(
	in_tree_sid			IN				security.security_pkg.T_SID_ID
) AS
	v_act_id								security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid								security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_reg_users_sid					security.security_pkg.T_SID_ID := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/RegisteredUsers');
	v_ucd_sid								security.security_pkg.T_SID_ID := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Users/UserCreatorDaemon');
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'LockRegionTree can only be run as BuiltIn/Administrator');
	END IF;

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(in_tree_sid), security.security_pkg.ACL_INDEX_FIRST, security.security_pkg.ACE_TYPE_DENY,
				security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_WRITE + security.security_pkg.PERMISSION_DELETE);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(in_tree_sid), security.security_pkg.ACL_INDEX_FIRST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_ucd_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
END;

FUNCTION IsEmailDomainRestricted
RETURN NUMBER
AS
	v_restrict_change_email_domain NUMBER(1, 0);
BEGIN
	SELECT restrict_change_email_domains
	  INTO v_restrict_change_email_domain
	  FROM customer_options
	 WHERE app_sid = security_pkg.getApp;

	RETURN v_restrict_change_email_domain;

END;

FUNCTION IsDedupePreprocessEnabled
RETURN NUMBER
AS
	v_is_enabled NUMBER(1, 0);
BEGIN
	SELECT enable_dedupe_preprocess
	  INTO v_is_enabled
	  FROM customer_options
	 WHERE app_sid = security_pkg.getApp;

	RETURN v_is_enabled;
END;

FUNCTION SendChangeEmailAlert
RETURN NUMBER
AS
	v_send_change_email_alert NUMBER(1, 0);
BEGIN
	SELECT send_change_email_alert
	  INTO v_send_change_email_alert
	  FROM customer_options
	 WHERE app_sid = security_pkg.getApp;

	RETURN v_send_change_email_alert;

END;

FUNCTION ShowAllComponents
RETURN NUMBER
AS
	v_show_all_components NUMBER(1, 0);
BEGIN
	SELECT show_all_components
	  INTO v_show_all_components
	  FROM customer_options
	 WHERE app_sid = security_pkg.getApp;

	RETURN v_show_all_components;

END;


PROCEDURE GetExportMenuItems (
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT report_url url, label
		  FROM chain.filtersupplierreportlinks
		 WHERE app_sid = in_app_sid
		 ORDER BY position;

END;


FUNCTION AreVisibilityOptionsEnabled
RETURN NUMBER
AS
	v_enable_visibility_options NUMBER(1, 0);
BEGIN
	SELECT enable_user_visibility_options
	  INTO v_enable_visibility_options
	  FROM customer_options
	 WHERE app_sid = security_pkg.getApp;

	RETURN v_enable_visibility_options;

END;

FUNCTION CanReinviteSupplier RETURN customer_options.reinvite_supplier%TYPE
AS
	v_can_reinvite_supplier			customer_options.reinvite_supplier%TYPE;
BEGIN
	BEGIN
		SELECT reinvite_supplier
		  INTO v_can_reinvite_supplier
		  FROM customer_options
		 WHERE app_sid = security_pkg.getApp;

		RETURN v_can_reinvite_supplier;
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			RETURN 0;
	END;
END;

PROCEDURE GetRiskLevels (
	out_risk_level_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_view_country_risk_level_cap	NUMBER(1);
	v_system_management_cap			NUMBER(1) := 0;
BEGIN
	IF csr.csr_data_pkg.CheckCapability('System management') THEN
		v_system_management_cap := 1;
	END IF;

	capability_pkg.CheckCapability(chain_pkg.VIEW_COUNTRY_RISK_LEVELS, v_view_country_risk_level_cap);

	OPEN out_risk_level_cur FOR
		SELECT risk_level_id, label, lookup_key
		  FROM risk_level
		 WHERE v_view_country_risk_level_cap = 1
		    OR v_system_management_cap = 1
		    OR security.user_pkg.IsSuperAdmin = 1;
END;

PROCEDURE DeleteRiskLevel(
	in_risk_level_id		IN	risk_level.risk_level_id%TYPE
)
AS
BEGIN
	IF security.user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only super admins can configure risk levels');
	END IF;

	DELETE FROM risk_level
	 WHERE risk_level_id = in_risk_level_id;
END;

PROCEDURE SaveRiskLevel(
	in_risk_level_id			IN	risk_level.risk_level_id%TYPE,
	in_label					IN	risk_level.label%TYPE,
	in_lookup_key				IN	risk_level.lookup_key%TYPE,
	out_risk_level_id			OUT	risk_level.risk_level_id%TYPE
)
AS
BEGIN
	IF security.user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only super admins can configure risk levels');
	END IF;

	IF in_risk_level_id IS NULL THEN
		INSERT INTO risk_level (risk_level_id, label, lookup_key)
		VALUES (risk_level_id_seq.NEXTVAL, in_label, in_lookup_key)
		RETURNING risk_level_id INTO out_risk_level_id;
	ELSE
		UPDATE risk_level
		   SET label = in_label,
			   lookup_key = in_lookup_key
		 WHERE risk_level_id = in_risk_level_id;

		out_risk_level_id := in_risk_level_id;
	END IF;

	chain_link_pkg.RiskLevelUpdated(out_risk_level_id);
END;

PROCEDURE GetCountryRiskLevels (
	out_country_risk_level_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_view_country_risk_level_cap	NUMBER(1);
	v_system_management_cap			NUMBER(1) := 0;
BEGIN
	IF csr.csr_data_pkg.CheckCapability('System management') THEN
		v_system_management_cap := 1;
	END IF;

	capability_pkg.CheckCapability(chain_pkg.VIEW_COUNTRY_RISK_LEVELS, v_view_country_risk_level_cap);

	OPEN out_country_risk_level_cur FOR
		SELECT country, risk_level_id, start_dtm,
		CASE when LEAD (c.name) over (order by c.name) = c.name
            then LEAD(TRUNC(start_dtm)-1, 1) OVER (ORDER BY c.name)
            else NULL END AS end_dtm
		  FROM country_risk_level crl
		  JOIN v$country c ON c.country_code = crl.country
		 WHERE v_view_country_risk_level_cap = 1
		    OR v_system_management_cap = 1
		    OR security.user_pkg.IsSuperAdmin = 1
		 ORDER BY c.name asc, start_dtm asc;
END;

PROCEDURE SaveCountryRiskLevel (
	in_country			IN	country_risk_level.country%TYPE,
	in_risk_level_id	IN	risk_level.risk_level_id%TYPE,
	in_start_dtm		IN	country_risk_level.start_dtm%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability('System management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can save country risk levels');
	END IF;

	INSERT INTO country_risk_level (country, risk_level_id, start_dtm)
	VALUES (in_country, in_risk_level_id, TRUNC(in_start_dtm));

	chain_link_pkg.CountryRiskLevelUpdated(in_risk_level_id, in_country, in_start_dtm);
END;

PROCEDURE DeleteCountryRiskLevel (
	in_country			IN	country_risk_level.country%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability('System management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can delete country risk levels');
	END IF;

	DELETE FROM country_risk_level
	WHERE country = in_country;
END;

PROCEDURE ImportCountryRisk
AS
	v_low_risk_level_id			risk_level.risk_level_id%TYPE;
	v_high_risk_level_id		risk_level.risk_level_id%TYPE;
BEGIN
	IF security.user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only super admins can configure risk levels');
	END IF;

	BEGIN
		SELECT risk_level_id
		  INTO v_low_risk_level_id
		  FROM risk_level
		 WHERE UPPER(lookup_key) = 'LOW';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO risk_level (risk_level_id, label, lookup_key)
			VALUES (risk_level_id_seq.NEXTVAL, 'Low', 'LOW')
			RETURNING risk_level_id INTO v_low_risk_level_id;
	END;

	BEGIN
		SELECT risk_level_id
		  INTO v_high_risk_level_id
		  FROM risk_level
		 WHERE UPPER(lookup_key) = 'HIGH';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO risk_level (risk_level_id, label, lookup_key)
			VALUES (risk_level_id_seq.NEXTVAL, 'High', 'HIGH')
			RETURNING risk_level_id INTO v_high_risk_level_id;
	END;

	DELETE FROM country_risk_level;

	FOR r IN (
		SELECT country FROM postcode.country WHERE country IN ('ad','ai','ag','aw','au','at','bs','bb','be','bm','bw','bn','ca','cv','ky','cr','hr','cy','cz','dk','dm','ee','fi','fr','gf','de','gr','gl','gd','gu','hu','is','ie','il','it','jp','je','lv','li','lt','lu','mt','mq','nl','an','nz','no','pl','pt','pr','qa','re','ws','sg','sk','si','es','kn','lc','vc','se','ch','ae','gb','us','vi')
	) LOOP
		INSERT INTO country_risk_level (risk_level_id, country, start_dtm)
		VALUES (v_low_risk_level_id, r.country, TO_DATE('2011-01-01', 'YYYY-MM-DD'));
	END LOOP;

	FOR r IN (
		SELECT country FROM postcode.country WHERE country IN ('af','al','dz','ao','ar','am','az','bh','bd','by','bz','bj','bt','bo','ba','br','bg','bf','bi','kh','cm','cf','td','cn','co','km','cd','cg','ci','cu','dj','do','ec','eg','sv','gq','er','et','fj','ga','gm','ge','gh','gt','gn','gw','gy','ht','hn','in','id','ir','iq','jm','jo','kz','ke','ki','kp','xk','kw','kg','la','lb','ls','lr','ly','mk','mg','mw','my','mv','ml','mh','mr','mx','fm','md','mn','me','ma','mz','mm','na','nr','np','ni','ne','ng','om','pk','pw','pa','pg','py','pe','ph','ro','ru','rw','st','sa','sn','rs','sc','sl','sb','so','za','ss','lk','sd','sr','sz','sy','tj','tz','th','tl','tg','to','tt','tn','tr','tm','tv','ug','ua','uz','vu','ve','vn','ps','ye','zm','zw','cl','hk','kr','mo','mu','tw','uy')
	) LOOP
		INSERT INTO country_risk_level (risk_level_id, country, start_dtm)
		VALUES (v_high_risk_level_id, r.country, TO_DATE('2011-01-01', 'YYYY-MM-DD'));
	END LOOP;

	FOR r IN (
		SELECT country FROM postcode.country WHERE country IN ('ad','ai','ag','aw','au','at','bs','bb','be','bm','bw','bn','ca','cv','ky','cl','cr','hr','cy','cz','dk','dm','ee','fi','fr','gf','de','gr','gl','gd','gu','hk','hu','is','ie','il','it','jp','je','kr','lv','li','lt','lu','mo','mt','mq','mu','nl','an','nz','no','pl','pt','pr','qa','re','ws','sg','sk','si','es','kn','lc','vc','se','ch','tw','ae','gb','us','uy','vi')
	) LOOP
		INSERT INTO country_risk_level (risk_level_id, country, start_dtm)
		VALUES (v_low_risk_level_id, r.country, TO_DATE('2014-01-01', 'YYYY-MM-DD'));
	END LOOP;

	FOR r IN (
		SELECT country FROM postcode.country WHERE country IN ('af','al','dz','ao','ar','am','az','bh','bd','by','bz','bj','bt','bo','ba','br','bg','bf','bi','kh','cm','cf','td','cn','co','km','cd','cg','ci','cu','dj','do','ec','eg','sv','gq','er','et','fj','ga','gm','ge','gh','gt','gn','gw','gy','ht','hn','in','id','ir','iq','jm','jo','kz','ke','ki','kp','xk','kw','kg','la','lb','ls','lr','ly','mk','mg','mw','my','mv','ml','mh','mr','mx','fm','md','mn','me','ma','mz','mm','na','nr','np','ni','ne','ng','om','pk','pw','pa','pg','py','pe','ph','ro','ru','rw','st','sa','sn','rs','sc','sl','sb','so','za','ss','lk','sd','sr','sz','sy','tj','tz','th','tl','tg','to','tt','tn','tr','tm','tv','ug','ua','uz','vu','ve','vn','ps','ye','zm','zw')
	) LOOP
		INSERT INTO country_risk_level (risk_level_id, country, start_dtm)
		VALUES (v_high_risk_level_id, r.country, TO_DATE('2014-01-01', 'YYYY-MM-DD'));
	END LOOP;

	chain_link_pkg.CountryRiskLevelUpdated();
END;

FUNCTION IsChainSite
RETURN NUMBER
AS
	v_n_ct	NUMBER(10);
BEGIN
-- no security required
	SELECT COUNT(*)
	  INTO v_n_ct
	  FROM chain.company_type
	 WHERE app_sid = security_pkg.getApp;

	IF v_n_ct >= 2 THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;

FUNCTION HasCompanyContext
RETURN security_pkg.T_SID_ID
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
-- no security required
	v_company_sid := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	IF v_company_sid IS NULL THEN
		RETURN 0;
	END IF;
	RETURN 1;
END;

FUNCTION IsProductComplianceEnabled
RETURN NUMBER
AS
	v_is_enabled NUMBER(1, 0) := 0;
BEGIN
	BEGIN
		SELECT enable_product_compliance
		  INTO v_is_enabled
		  FROM customer_options
		 WHERE app_sid = security_pkg.getApp;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;

	RETURN v_is_enabled;
END;

FUNCTION AllowDuplicateEmails
RETURN NUMBER
AS
	v_is_allowed NUMBER(1, 0);
BEGIN
	SELECT allow_duplicate_emails
	  INTO v_is_allowed
	  FROM customer_options
	 WHERE app_sid = security_pkg.getApp;

	RETURN v_is_allowed;
END;

FUNCTION IsCompanyGeotagEnabled
RETURN NUMBER
AS
	v_company_geotag_enabled NUMBER(1, 0);
BEGIN
	SELECT company_geotag_enabled
	  INTO v_company_geotag_enabled
	  FROM customer_options
	 WHERE app_sid = security_pkg.getApp;

	RETURN v_company_geotag_enabled;
END;

FUNCTION GenerateSignaturePrefix(
	in_country				company.country_code%TYPE DEFAULT NULL,
	in_company_type_id		company.company_type_id%TYPE DEFAULT NULL,
	in_city					company.city%TYPE DEFAULT NULL,	
	in_state				company.state%TYPE DEFAULT NULL,
	in_sector_id			company.sector_id%TYPE DEFAULT NULL,
	in_layout				company_type.default_region_layout%TYPE DEFAULT NULL
) RETURN company.signature%TYPE
DETERMINISTIC
AS
	v_signature_prefix			company.signature%TYPE;
BEGIN
	SELECT LISTAGG(
		CASE  
		WHEN val = 'COUNTRY' THEN 'co:' || in_country
		WHEN val = 'COMPANY_TYPE' THEN 'ct:' || in_company_type_id
		WHEN val = 'CITY' AND in_city IS NOT NULL THEN 'ci:' || in_city
		WHEN val = 'STATE' AND in_state IS NOT NULL THEN 'st:' || in_state
		WHEN val = 'SECTOR' AND in_sector_id IS NOT NULL THEN 'sct:' || in_sector_id
		END, '|') 
		WITHIN GROUP (ORDER BY lvl)
	  INTO v_signature_prefix 
	  FROM (
  		SELECT LTRIM(RTRIM(UPPER(REGEXP_SUBSTR(str, '{[^}]+}', 1, level, 'i')), '}'), '{') AS val, level lvl
		  FROM (SELECT in_layout AS str FROM dual)
	   CONNECT BY level <= LENGTH(REGEXP_REPLACE(str, '{[^}]+}'))+1
		);

	RETURN v_signature_prefix;
END;

FUNCTION GenerateCompanySignature(
	in_company_name			company.name%TYPE,
	in_country				company.country_code%TYPE DEFAULT NULL,
	in_company_type_id		company.company_type_id%TYPE DEFAULT NULL,
	in_city					company.city%TYPE DEFAULT NULL,	
	in_state				company.state%TYPE DEFAULT NULL,
	in_sector_id			company.sector_id%TYPE DEFAULT NULL,
	in_layout				company_type.default_region_layout%TYPE DEFAULT NULL,
	in_parent_sid			security_pkg.T_SID_ID DEFAULT NULL
) RETURN company.signature%TYPE
DETERMINISTIC
AS
	v_signature_prefix	company.signature%TYPE;
	v_normalised_name	company.name%TYPE := NormaliseCompanyName(in_company_name);
BEGIN
	IF in_parent_sid IS NOT NULL THEN
		RETURN LOWER('parent:' || in_parent_sid  || '|na:' || v_normalised_name);
	END IF;

	v_signature_prefix := GenerateSignaturePrefix(
		in_country			=> in_country,
		in_company_type_id	=> in_company_type_id,
		in_city				=> in_city,
		in_state			=> in_state,
		in_sector_id		=> in_sector_id,
		in_layout			=> in_layout
	);

	RETURN LOWER(v_signature_prefix || '|na:' || v_normalised_name);
END;

END helper_pkg;
/
