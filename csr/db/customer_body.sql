CREATE OR REPLACE PACKAGE BODY CSR.customer_pkg AS

PROCEDURE GetDetails(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT c.name, c.host, c.system_mail_address, c.tracker_mail_address, c.alert_mail_address,
			   c.contact_email, c.raise_reminders, c.ind_info_xml_fields, c.region_info_xml_fields,
			   c.user_info_xml_fields, c.account_policy_sid, c.app_sid, c.current_reporting_period_sid,
			   c.region_root_sid, c.ind_root_sid, c.reporting_ind_root_sid,
			   c.helper_assembly, c.use_tracker, c.audit_calc_changes,
			   c.use_user_sheets, c.aggregation_engine_version, c.allow_val_edit, c.calc_sum_zero_fill,
			   c.equality_epsilon, NVL(ws.secure_only, 0) host_secure, c.alert_mail_name, c.editing_url, 
			   c.target_line_col_from_gradient, c.use_carbon_emission, c.create_sheets_at_period_end, c.allow_deleg_plan,
			   c.allow_make_editable, c.merged_scenario_run_sid, c.unmerged_scenario_run_sid, c.issue_editor_url, 
			   c.alert_uri_format, c.ind_selections_enabled, c.check_tolerance_against_zero, c.oracle_schema,
			   c.scenarios_enabled, c.use_var_expl_groups, c.apply_factors_to_child_regions, c.user_directory_type_id,
			   c.bounce_tracking_enabled, c.issue_escalation_enabled, c.property_flow_sid, c.chemical_flow_sid, c.incl_inactive_regions,
			   c.allow_section_in_many_carts, c.check_divisibility, c.lock_prevents_editing, c.lock_end_dtm, c.translation_checkbox,
			   c.trash_sid, c.allow_multiperiod_forms, c.start_month, c.chart_xsl, c.show_region_disposal_date,
			   c.data_explorer_show_markers, c.show_all_sheets_for_rep_prd, c.deleg_browser_show_rag,
			   c.tgtdash_ignore_estimated, c.tgtdash_hide_totals, c.tgtdash_show_chg_from_last_yr,
			   c.tgtdash_show_last_year, c.tgtdash_colour_text, c.tgtdash_show_target_first,
			   c.tgtdash_show_flash, c.use_region_events, c.metering_enabled, c.crc_metering_enabled,
			   c.crc_metering_ind_core, c.crc_metering_auto_core, c.iss_view_src_to_deepest_sheet,
			   c.delegs_always_show_adv_opts, c.default_admin_css, c.default_country, c.data_explorer_show_ranking,
			   c.data_explorer_show_trends, c.data_explorer_show_scatter, c.data_explorer_show_radar, c.data_explorer_show_gauge,
			   c.data_explorer_show_waterfall, c.multiple_audit_surveys, c.legacy_period_formatting,
			   c.include_nulls_in_ta, c.rstrct_multiprd_frm_edit_to_yr, c.copy_forward_allow_na,
			   c.audits_on_users, c.quick_survey_fixed_structure, c.remove_roles_on_account_expir, c.like_for_like_slots,
			   c.show_aggregate_override, c.allow_old_chart_engine, c.tear_off_deleg_header, c.show_map_on_audit_list, c.deleg_dropdown_threshold,
			   c.user_picker_extra_fields, c.forecasting_slots, c.rest_api_guest_access, c.divisibility_bug, c.question_library_enabled, 
			   c.calc_sum_to_dt_cust_yr_start, c.calc_start_dtm, c.calc_end_dtm, c.show_additional_audit_info, c.lazy_load_role_membership,
			   c.calc_future_window, c.require_sa_login_reason, c.allow_cc_on_alerts, c.chart_algorithm_version,
			   c.calc_jobs_disabled, c.batch_jobs_disabled, c.scheduled_tasks_disabled, c.alerts_disabled, c.prevent_logon, 
			   c.mobile_branding_enabled, c.render_charts_as_svg, c.show_data_approve_confirm
		  FROM customer c, security.website ws
		 WHERE c.app_sid = in_app_sid
		   AND c.host = ws.website_name(+);
END;

-- legacy version of the above that avoids fetching XMLTYPE columns
PROCEDURE GetDetailsForASP(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT c.start_month, c.delegs_always_show_adv_opts, c.default_admin_css
		  FROM customer c
		 WHERE c.app_sid = in_app_sid;
END;

PROCEDURE AmendDetails(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_name						IN	customer.name%TYPE,
	in_contact_email			IN	customer.contact_email%TYPE,	
	in_raise_reminders			IN	customer.raise_reminders%TYPE,		
	in_ind_info_xml_fields		IN	customer.ind_info_xml_fields%TYPE,		
	in_region_info_xml_fields	IN	customer.region_info_xml_fields%TYPE,		
	in_user_info_xml_fields 	IN	customer.user_info_xml_fields%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	UPDATE customer
	   SET name = in_name,
	   	   contact_email = in_contact_email,
	   	   raise_reminders = in_raise_reminders,
	   	   ind_info_xml_fields = in_ind_info_xml_fields,
	   	   region_info_xml_fields = in_region_info_xml_fields,
	   	   user_info_xml_fields = in_user_info_xml_fields
	 WHERE app_sid = in_app_sid;
END;

PROCEDURE GetMessage(
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT message
		  FROM customer
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetAppSid(
	in_host							IN	customer.host%TYPE,
	out_app_sid						OUT	customer.app_sid%TYPE
)
AS
BEGIN
	-- No security, use only in batch applications or command line tools
	-- If there isn't an entry in csr.customer then look for an alias in security.website
	SELECT NVL(
		(
			SELECT app_sid
				FROM csr.customer
				WHERE LOWER(host) = LOWER(in_host)
		),
		(
			SELECT application_sid_id
				FROM security.website
				WHERE LOWER(website_name) = LOWER(in_host)
		)
	) app_sid
		INTO out_app_sid
		FROM DUAL;
	IF out_app_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_OBJECT_NOT_FOUND,
			'The application named ' || in_host || ' could not be found');
	END IF;
END;

PROCEDURE EnsureAppLanguageIsValid(
	in_act_id				IN	security_pkg.T_ACT_ID
)
AS
	v_count					NUMBER;
	v_app_sid				security_pkg.T_SID_ID;
	v_app_lang				security.user_table.language%TYPE;
	v_culture				security.user_table.culture%TYPE;
	v_timezone				security.user_table.timezone%TYPE;
BEGIN
	v_app_sid := security.security_pkg.GetApp;
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, v_app_sid, Security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'You do not have write permission on the application with sid '||v_app_sid);
	END IF;

	security.web_pkg.GetLocalisationSettings(in_act_id, v_app_sid, v_app_lang, v_culture, v_timezone);

	SELECT COUNT(*)
	  INTO v_count
	  FROM aspen2.translation_set
	 WHERE application_sid = v_app_sid
	   AND hidden = 0
	   AND lang = v_app_lang;

	IF v_count = 0 THEN
		--set the default language of the app to null.
		security.web_pkg.SetLocalisationSettings(in_act_id, v_app_sid, NULL, v_culture, v_timezone);
	END IF;
END;

PROCEDURE EnsureLanguagesAreValid(
	in_act_id				IN	security_pkg.T_ACT_ID
)
AS
BEGIN
	EnsureAppLanguageIsValid(in_act_id);
	csr_user_pkg.EnsureUserLanguagesAreValid(in_act_id);
END;

PROCEDURE GetFileUploadTypeOptions(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT file_extension, is_allowed
		  FROM customer_file_upload_type_opt
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetFileUploadMimeOptions(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT mime_type, is_allowed
		  FROM customer_file_upload_mime_opt
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetFileUploadOptions(
	out_file_type_cur		OUT	SYS_REFCURSOR,
	out_mime_type_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetFileUploadTypeOptions(out_file_type_cur);
	GetFileUploadMimeOptions(out_mime_type_cur);
END;

PROCEDURE RemoveRolesOnAccountExpiration(
	in_remove_from_roles	IN	customer.remove_roles_on_account_expir%type
)
AS
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'),
		security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Users'), security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting remove roles on account expiration.');
	END IF;

	UPDATE customer 
		SET remove_roles_on_account_expir = in_remove_from_roles
	WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetAggregationPeriods(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT aggregation_period_id, label, no_of_months
		  FROM aggregation_period
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetSchema (
	in_host				IN	VARCHAR2,
	out_schema_name		OUT	VARCHAR2
)
AS
	v_schema		VARCHAR2(1024);
BEGIN

	-- Validate the host name, just in case.
	SELECT oracle_schema
	  INTO v_schema
	  FROM customer c
	 WHERE LOWER(c.HOST) = LOWER(in_host)
	   AND c.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	out_schema_name := v_schema;

END;

PROCEDURE RefreshCalcWindows
AS
BEGIN
	UPDATE customer
	   SET calc_end_dtm = ADD_MONTHS(TRUNC(SYSDATE, 'MONTH'), 2 + (12 * calc_future_window))
	 WHERE calc_end_dtm <= ADD_MONTHS(TRUNC(SYSDATE), (12 * calc_future_window) -2);
END;

PROCEDURE DisableSALoginJustification
AS
BEGIN
	UPDATE customer
	   SET require_sa_login_reason = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetSystemTranslations(
	in_languages			IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_languages		security.T_VARCHAR2_TABLE;
BEGIN
	v_languages := security_pkg.Varchar2ArrayToTable(in_languages);
	
	OPEN out_cur FOR		
		SELECT * FROM
		(
			SELECT n.original, d.lang, d.translated
			FROM aspen2.translation n 
			JOIN aspen2.translated d ON n.application_sid = d.application_sid AND n.original_hash = d.original_hash
			WHERE n.application_sid = v_app_sid
		)
		PIVOT XML
		(
			MIN(translated) AS translation
			FOR lang in (SELECT value FROM TABLE(v_languages))
		)
		ORDER BY original;
END;

PROCEDURE SetSystemTranslation(
	in_original			IN 	VARCHAR2,
	in_lang				IN	aspen2.tr_pkg.T_LANG,
	in_translation		IN	VARCHAR2,
	in_delete			IN	NUMBER
)
AS
	v_app_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_old_translation		aspen2.translated.translated%TYPE;
	v_translated_id			aspen2.translated.translated_id%TYPE;
	v_translation_exists 	NUMBER;
	v_original_exists 		NUMBER;
BEGIN
	IF in_delete = 1 THEN
		DELETE FROM aspen2.translated d
		 WHERE EXISTS 
		(
		 SELECT 1 
		   FROM aspen2.translation n
		  WHERE d.application_sid = n.application_sid 
			AND d.original_hash = n.original_hash
			AND n.original = in_original
			AND d.application_sid = v_app_sid
		)
		 AND d.application_sid = v_app_sid;
		 
		DELETE FROM aspen2.translation
		 WHERE original = in_original
		  AND application_sid = v_app_sid;

		INSERT INTO csr.sys_translations_audit_log
			(sys_translations_audit_log_id, audit_date, app_sid, translated_id, user_sid, description)
		VALUES
			(sys_trans_audit_log_seq.NEXTVAL, SYSDATE, SYS_CONTEXT('SECURITY','APP'), NVL(v_translated_id, 0), SYS_CONTEXT('security','sid'), 
			'Original string and all the translations for it have been deleted.');
		
		INSERT INTO csr.sys_translations_audit_data (sys_translations_audit_log_id, audit_date, app_sid, is_delete, original)
		VALUES (sys_trans_audit_log_seq.CURRVAL, SYSDATE, SYS_CONTEXT('SECURITY','APP'), 1, in_original);
	ELSE  
		--get values for auditing purposes before we create anything
		SELECT COUNT(*)
		  INTO v_original_exists
		  FROM aspen2.translation n
		 WHERE n.original = in_original
		   AND n.application_sid = v_app_sid;

		SELECT COUNT(*)
		  INTO v_translation_exists
		  FROM aspen2.translation n
		  JOIN aspen2.translated d ON n.application_sid = d.application_sid AND n.original_hash = d.original_hash
		 WHERE n.original = in_original
		   AND n.application_sid = v_app_sid
		   AND d.lang = in_lang;

		IF v_translation_exists = 1 THEN
			SELECT translated, translated_id 
			  INTO v_old_translation, v_translated_id
			  FROM aspen2.translated d
			 WHERE EXISTS 
				(
				 SELECT 1 
				   FROM aspen2.translation n
				  WHERE d.application_sid = n.application_sid 
					AND d.original_hash = n.original_hash
					AND n.original = in_original
					AND d.application_sid = v_app_sid
				)
			  AND d.application_sid = v_app_sid
			  AND d.lang = in_lang;
		END IF;

		--this sproc call will take care of new original strings and existing original strings, also only updates if its changed
		aspen2.tr_pkg.SetTranslationInsecure(v_app_sid, in_lang, in_original, in_translation);

		IF v_translation_exists = 1 THEN
			-- log an update of the translation
			IF v_old_translation != in_translation THEN
				INSERT INTO csr.sys_translations_audit_log
					(sys_translations_audit_log_id, audit_date, app_sid, translated_id, user_sid, description)
				VALUES
					(sys_trans_audit_log_seq.NEXTVAL, SYSDATE, SYS_CONTEXT('SECURITY','APP'), v_translated_id, SYS_CONTEXT('security','sid'), 
						'Translation updated for lang ' || in_lang || '.' );

				INSERT INTO csr.sys_translations_audit_data (sys_translations_audit_log_id, audit_date, app_sid, is_delete, original, translation, old_translation)
				VALUES (sys_trans_audit_log_seq.CURRVAL, SYSDATE, SYS_CONTEXT('SECURITY','APP'), 0, in_original, in_translation, v_old_translation);
			END IF;
		ELSE
			-- log an insert of the translation

			--need to get the id of the new translation so we can add it to the audit log
			SELECT translated_id 
			  INTO v_translated_id
			  FROM aspen2.translated d
			 WHERE EXISTS 
				(
				 SELECT 1 
				   FROM aspen2.translation n
				  WHERE d.application_sid = n.application_sid 
					AND d.original_hash = n.original_hash
					AND n.original = in_original
					AND d.application_sid = v_app_sid
				)
			  AND d.application_sid = v_app_sid
			  AND d.lang = in_lang;
		
			INSERT INTO csr.sys_translations_audit_log (sys_translations_audit_log_id, audit_date, app_sid, translated_id, user_sid, description)
			VALUES (sys_trans_audit_log_seq.NEXTVAL, SYSDATE, SYS_CONTEXT('SECURITY','APP'), v_translated_id, SYS_CONTEXT('security','sid'), 
					CASE v_original_exists WHEN 1 --this bool was calculated at the start so it correctly ignores the fact that we've just created it
					THEN 
						'Translation created for lang ' || in_lang || '.' 
					ELSE
						'Original string created and translation created for lang ' || in_lang || '.'
					END
			);
			INSERT INTO csr.sys_translations_audit_data (sys_translations_audit_log_id, audit_date, app_sid, is_delete, original, translation)
			VALUES (sys_trans_audit_log_seq.CURRVAL, SYSDATE, SYS_CONTEXT('SECURITY','APP'), 0, in_original, in_translation);

		END IF;
	END IF;
END;

PROCEDURE GetSysTransAuditLog(
	in_order_by 			IN 	VARCHAR2,
	in_description_filter	IN	sys_translations_audit_log.description%TYPE,
	in_start_row			IN	NUMBER,
	in_page_size			IN	NUMBER,
	out_total_rows			OUT	NUMBER,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_order_by				VARCHAR2(30);
	v_app_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN

	IF in_order_by IS NOT NULL THEN
		utils_pkg.ValidateOrderBy(in_order_by, 'user_name,description,audit_date');
		v_order_by := ' ORDER BY ' || in_order_by;
	END IF;

	EXECUTE IMMEDIATE
	'SELECT COUNT(*) '||
	  'FROM sys_translations_audit_log l '||
	 'WHERE l.app_sid = :v_app_sid ' ||
	   'AND :in_description_filter IS NULL OR LOWER(l.description) LIKE ''%''||:in_description_filter||''%'''
	INTO out_total_rows
	USING v_app_sid, in_description_filter, in_description_filter;
	
	OPEN out_cur FOR
	'SELECT * '||
	  'FROM ( '||
			'SELECT q.*, rownum rn '||
			  'FROM ('||
					'SELECT u.user_name, l.description, l.audit_date '||
					  'FROM sys_translations_audit_log l '||
					  'JOIN csr_user u ON l.app_sid = u.app_sid AND l.user_sid = u.csr_user_sid '||
					 'WHERE l.app_sid = :v_app_sid '||
					   'AND :in_description_filter IS NULL OR LOWER(l.description) LIKE ''%''||:in_description_filter||''%'' ' ||
					 v_order_by||
				   ') q '||
			 'WHERE rownum < :in_start_row + :in_page_size '||
			') ' ||
	 'WHERE rn >= :in_start_row'
	 USING v_app_sid, in_description_filter, in_description_filter, in_start_row, in_page_size, in_start_row;
END;

/* UNSEC as doesn't check app sid. Does this on purpose so that the scheduled task can check is ANY customer
   on this DB has question library enabled */
PROCEDURE UNSEC_IsQuestionLibraryEnabled(
	out_is_enabled			OUT	NUMBER
)
AS
BEGIN

	SELECT CASE SUM(question_library_enabled) WHEN 0 THEN 0 ELSE 1 END 
	  INTO out_is_enabled
	  FROM customer;
	-- No app check on purpose. See SP comment.
	
END;

/* UNSEC because we may not be logged in when calling this SP (from new APIs/Gateways for example */
FUNCTION UNSEC_GetHostFromTenantId(
	in_tenant_id		IN	security.tenant.tenant_id%TYPE
)
RETURN VARCHAR2
AS
	v_app_sid			customer.app_sid%TYPE;
	v_host				customer.host%TYPE;
BEGIN
	v_app_sid := security_pkg.GetAppSidFromTenantId(in_tenant_id);

	SELECT host
	  INTO v_host
	  FROM customer
	 WHERE app_sid = v_app_sid;
	
	RETURN v_host;
END;

PROCEDURE SetBackgroundJobsStatus(
	in_calc_jobs_disabled		IN	csr.customer.calc_jobs_disabled%TYPE,
	in_batch_jobs_disabled		IN	csr.customer.batch_jobs_disabled%TYPE,
	in_scheduled_tasks_disabled	IN	csr.customer.scheduled_tasks_disabled%TYPE
)
AS
BEGIN

	UPDATE customer
	   SET calc_jobs_disabled = in_calc_jobs_disabled,
		   batch_jobs_disabled = in_batch_jobs_disabled,
		   scheduled_tasks_disabled = in_scheduled_tasks_disabled
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetCascadeReject(
	out_cascade_reject			OUT	customer.cascade_reject%TYPE
)
AS
BEGIN
	-- This is ok as public information
	SELECT cascade_reject
	  INTO out_cascade_reject
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;


PROCEDURE SetOracleSchema(
	in_oracle_schema			IN	csr.customer.oracle_schema%TYPE,
	in_overwrite				IN	NUMBER DEFAULT 0
)
AS
	v_existing_schema			csr.customer.oracle_schema%TYPE;
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), Security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'You do not have write permission on the application');
	END IF;

	SELECT oracle_schema
	  INTO v_existing_schema
	  FROM csr.customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF in_overwrite != 1 AND v_existing_schema IS NOT NULL AND UPPER(v_existing_schema) != UPPER(in_oracle_schema) THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_NOT_ALLOWED_WRITE, 'Customer row already has an oracle schema');
	END IF;

	UPDATE csr.customer
	   SET oracle_schema = UPPER(in_oracle_schema)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE ToggleRenderChartsAsSvg
AS
	v_new_value				csr.customer.render_charts_as_svg%TYPE;
BEGIN

	SELECT CASE render_charts_as_svg WHEN 1 THEN 0 ELSE 1 END
	  INTO v_new_value
	  FROM csr.customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	UPDATE csr.customer
	   SET render_charts_as_svg = v_new_value
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	csr_data_pkg.WriteAuditLogEntry(
		in_act_id					=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_audit_type_id			=> csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, 
		in_app_sid					=> SYS_CONTEXT('SECURITY', 'APP'),
		in_object_sid				=> SYS_CONTEXT('SECURITY', 'APP'),
		in_description				=> 'Render charts as SVG set to {0}',
		in_param_1					=> v_new_value
	);

END;

FUNCTION ScheduledTasksDisabled
RETURN NUMBER
AS
	v_disabled				NUMBER(1);
BEGIN
	SELECT scheduled_tasks_disabled
	  INTO v_disabled
	  FROM csr.customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	RETURN v_disabled;
END;

FUNCTION ScheduledTasksDisabled(
	in_app_sid					IN	security_pkg.T_SID_ID
)
RETURN NUMBER
AS
	v_disabled				NUMBER(1);
BEGIN
	SELECT scheduled_tasks_disabled
	  INTO v_disabled
	  FROM csr.customer
	 WHERE app_sid = in_app_sid;
	
	RETURN v_disabled;
END;

END;
/
