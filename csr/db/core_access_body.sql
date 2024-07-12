CREATE OR REPLACE PACKAGE BODY csr.core_access_pkg AS

PROCEDURE GetUserRecordBySid(
	in_csr_user_sid			IN	csr.csr_user.csr_user_sid%TYPE,
	out_user				OUT	CSR.T_USER
)
AS
BEGIN

	csr.csr_user_pkg.GetUserRecordBySid(
		in_csr_user_sid		=> in_csr_user_sid,
		out_user			=> out_user
	);

END;

PROCEDURE GetUserRecordByRef(
	in_user_ref				IN	csr.csr_user.user_ref%TYPE,
	out_user				OUT	CSR.T_USER
)
AS
BEGIN

	csr.csr_user_pkg.GetUserRecordByRef(
		in_user_ref			=> in_user_ref,
		out_user			=> out_user
	);

END;

PROCEDURE GetUserRecordByUserName(
	in_user_name			IN  csr.csr_user.user_name%TYPE,
	out_user				OUT CSR.T_USER
)
AS
BEGIN

	csr.csr_user_pkg.GetUserRecordByUserName(
		in_user_name => in_user_name,
		out_user => out_user
	);

END;

FUNCTION GetFlowSidFromTable(
	in_oracle_schema		IN	cms.tab.oracle_schema%TYPE,
	in_oracle_table			IN	cms.tab.oracle_table%TYPE
) 
RETURN security_pkg.T_SID_ID
AS
BEGIN

	RETURN cms.tab_pkg.GetFlowSid(
		in_oracle_schema	=> in_oracle_schema,
		in_oracle_table		=> in_oracle_table
	);

END;

PROCEDURE RegionHasTag(
	in_region_sid			IN	region.region_sid%TYPE,
	in_tag_id				IN	tag.tag_id%type,
	out_has_tag				OUT NUMBER
)
AS
BEGIN

	csr.region_pkg.RegionHasTag(
		in_region_sid		=> in_region_sid,
		in_tag_id			=> in_tag_id,
		out_has_tag			=> out_has_tag
	);

END;

PROCEDURE GetTagFromLookup(
	in_lookup_key			IN	csr.tag.lookup_key%TYPE,
	out_tag_id				OUT	csr.tag.tag_id%TYPE
)
AS
BEGIN

	csr.tag_pkg.GetTagFromLookup(
		in_lookup_key		=> in_lookup_key,
		out_tag_id			=> out_tag_id
	);

END;

PROCEDURE GetTagFromName(
	in_tag_name			IN	csr.tag_description.tag%TYPE,
	in_lang				IN	csr.tag_description.lang%TYPE := 'en',
	out_tag_id			OUT	csr.tag.tag_id%TYPE
)
AS
BEGIN

	csr.tag_pkg.GetTagFromName(
		in_tag_name			=> in_tag_name,
		in_lang				=> in_lang,
		out_tag_id			=> out_tag_id
	);

END;

PROCEDURE GetUserProfile(
	in_csr_user_sid		IN	csr.user_profile.csr_user_sid%TYPE,
	out_user_profile	OUT	csr.T_USER_PROFILE
)
AS
BEGIN

	csr.user_profile_pkg.GetUserProfile(
		in_csr_user_sid		=> in_csr_user_sid,
		out_user_profile	=> out_user_profile
	);

END;

PROCEDURE GetUserRecordAndProfile(
	in_csr_user_sid		IN	csr.user_profile.csr_user_sid%TYPE,
	out_user			OUT	csr.T_USER,
	out_user_profile	OUT	csr.T_USER_PROFILE
)
AS
BEGIN

	GetUserRecordBySid(
		in_csr_user_sid		=> in_csr_user_sid,
		out_user			=> out_user
	);

	-- We can call UNSEC here because the previous call does a sec check
	-- in csr_user_pkg
	csr.user_profile_pkg.UNSEC_GetUserProfile(
		in_csr_user_sid		=> in_csr_user_sid,
		out_user_profile	=> out_user_profile
	);

END;

PROCEDURE GetRegionRecord(
	in_region_sid		IN	region.region_sid%TYPE,
	out_region			OUT	csr.T_REGION
)
AS
BEGIN

	csr.region_pkg.GetRegionRecord(
		in_region_sid		=> in_region_sid,
		out_region			=> out_region
	);

END;

PROCEDURE GetChildRegionRecords(
	in_region_sid			IN	region.region_sid%TYPE,
	in_include_inactive 	IN	NUMBER DEFAULT 0,
	out_regions				OUT	csr.T_REGIONS
)
AS
	v_region	csr.T_REGION;
BEGIN

    out_regions := csr.T_REGIONS();

	FOR r IN (
		SELECT region_sid
		  FROM region
		 WHERE app_sid = security.security_pkg.getapp
		   AND parent_sid = in_region_sid
		   AND (in_include_inactive = 1 OR active = 1) 
	)
	LOOP
		csr.region_pkg.GetRegionRecord(
			in_region_sid	=> r.region_sid,
			out_region		=> v_region
		);

		out_regions.extend;
		out_regions(out_regions.count) := v_region;
	END LOOP;

END;

PROCEDURE FilterIssuesBy(
	in_issue_ids			IN	security.security_pkg.T_SID_IDS,
	in_filter_deleted		IN	NUMBER DEFAULT 0,
	in_filter_closed		IN	NUMBER DEFAULT 0,
	in_filter_resolved		IN	NUMBER DEFAULT 0,
	out_filtered_ids		OUT	security.security_pkg.T_SID_IDS
)
AS
BEGIN

	csr.issue_pkg.FilterIssuesBy(
		in_issue_ids			=> in_issue_ids,
		in_filter_deleted		=> in_filter_deleted,
		in_filter_closed		=> in_filter_closed,
		in_filter_resolved		=> in_filter_resolved,
		out_filtered_ids		=> out_filtered_ids
	);

END;

PROCEDURE GetFormSidFromLookup(
	in_lookup_key		IN	cms.form.lookup_key%TYPE,
	out_form_sid		OUT	cms.form.form_sid%TYPE
)
AS
BEGIN

	cms.form_pkg.GetFormSidFromLookup(
		in_lookup_key		=> in_lookup_key,
		out_form_sid		=> out_form_sid
	);

END;

PROCEDURE GetDelegationGridIndSidFromPath(
	in_path				IN	csr.delegation_grid.path%TYPE,
	out_ind_sid			OUT	csr.delegation_grid.ind_sid%TYPE
)
AS
BEGIN

	csr.delegation_pkg.GetGridIndSidFromPath(
		in_path				=> in_path,
		out_ind_sid			=> out_ind_sid
	);

END;

PROCEDURE SetOracleSchema(
	in_oracle_schema			IN	csr.customer.oracle_schema%TYPE,
	in_overwrite				IN	NUMBER DEFAULT 0
)
AS
BEGIN

	csr.customer_pkg.SetOracleSchema(
		in_oracle_schema			=> in_oracle_schema,
		in_overwrite				=> in_overwrite
	);

END;

PROCEDURE UpdateAuditRegion(
	in_audit_sid			IN csr.internal_audit.internal_audit_sid%TYPE,
	in_new_region_sid		IN csr.region.region_sid%TYPE
)
AS
	v_issue_type_id					csr.issue_type.issue_type_id%TYPE;
	v_orig_create_raw				csr.issue_type.create_raw%TYPE;
	v_orig_is_region_editable		csr.issue_type.is_region_editable%TYPE;
	v_log_cur						SYS_REFCURSOR;
	v_action_cur					SYS_REFCURSOR;
BEGIN
	--make the action type editable
	FOR r IN (SELECT * FROM csr.issue_type WHERE app_sid = security.security_pkg.getapp AND issue_type_id = csr.csr_data_pkg.ISSUE_NON_COMPLIANCE)
	LOOP
		v_orig_create_raw := r.create_raw;
		v_orig_is_region_editable := r.is_region_editable;

		csr.issue_pkg.SaveIssueType(
			in_issue_type_id					=> r.issue_type_id,
			in_label							=> r.label,
			in_lookup_key						=> r.lookup_key,
			in_allow_children					=> r.allow_children,
			in_require_priority					=> r.REQUIRE_PRIORITY,
			in_require_due_dtm_comment			=> r.REQUIRE_DUE_DTM_COMMENT,
			in_can_set_public					=> r.CAN_SET_PUBLIC,
			in_public_by_default				=> r.PUBLIC_BY_DEFAULT,
			in_email_involved_roles				=> r.EMAIL_INVOLVED_ROLES,
			in_email_involved_users				=> r.EMAIL_INVOLVED_USERS,
			in_restrict_users_to_region			=> r.RESTRICT_USERS_TO_REGION,
			in_default_priority_id				=> r.DEFAULT_ISSUE_PRIORITY_ID,
			in_alert_pending_due_days			=> r.ALERT_PENDING_DUE_DAYS,
			in_alert_overdue_days				=> r.ALERT_OVERDUE_DAYS,
			in_auto_close_days					=> r.AUTO_CLOSE_AFTER_RESOLVE_DAYS,
			in_deletable_by_owner				=> r.DELETABLE_BY_OWNER,
			in_deletable_by_raiser				=> r.DELETABLE_BY_RAISER,
			in_deletable_by_administrator		=> r.DELETABLE_BY_ADMINISTRATOR,
			in_owner_can_be_changed				=> r.OWNER_CAN_BE_CHANGED,
			in_show_forecast_dtm				=> r.SHOW_FORECAST_DTM,
			in_require_var_expl					=> r.REQUIRE_VAR_EXPL,
			in_enable_reject_action				=> r.ENABLE_REJECT_ACTION,
			in_snd_alrt_on_issue_raised			=> r.SEND_ALERT_ON_ISSUE_RAISED,
			in_show_one_issue_popup				=> r.SHOW_ONE_ISSUE_POPUP,
			in_allow_owner_resolve_close		=> r.ALLOW_OWNER_RESOLVE_AND_CLOSE,
			in_is_region_editable				=> 1,
			in_enable_manual_comp_date			=> r.ENABLE_MANUAL_COMP_DATE,
			in_comment_is_optional				=> r.COMMENT_IS_OPTIONAL,
			in_due_date_is_mandatory			=> r.DUE_DATE_IS_MANDATORY,
			in_allow_critical					=> r.ALLOW_CRITICAL,
			in_allow_urgent_alert				=> r.ALLOW_URGENT_ALERT,
			in_region_is_mandatory				=> r.REGION_IS_MANDATORY,
			out_issue_type_id					=> v_issue_type_id
		);

		UPDATE csr.issue_type
		   SET create_raw = 1
		 WHERE issue_type_id = v_issue_type_id;
	END LOOP;

	--set the region_sids
	FOR r IN (
		SELECT i.issue_id
		  FROM csr.internal_audit ia
		  JOIN csr.non_compliance nc on nc.created_in_audit_sid = ia.internal_audit_sid
		  JOIN csr.issue_non_compliance inc on inc.non_compliance_id = nc.non_compliance_id
		  JOIN csr.issue i on i.issue_non_compliance_id = inc.issue_non_compliance_id
		 WHERE ia.internal_audit_sid = in_audit_sid)
	LOOP
		csr.issue_pkg.ChangeRegion(
			in_issue_id			=>  r.issue_id,
			in_region_sid		=>	in_new_region_sid,
			out_log_cur			=>	v_log_cur,
			out_action_cur		=>  v_action_cur
		);
	END LOOP;

	--make the action type non-editable
	FOR r IN (SELECT * FROM csr.issue_type WHERE app_sid = security.security_pkg.getapp AND issue_type_id = csr.csr_data_pkg.ISSUE_NON_COMPLIANCE)
	LOOP
		csr.issue_pkg.SaveIssueType(
			in_issue_type_id					=> r.issue_type_id,
			in_label							=> r.label,
			in_lookup_key						=> r.lookup_key,
			in_allow_children					=> r.allow_children,
			in_require_priority					=> r.REQUIRE_PRIORITY,
			in_require_due_dtm_comment			=> r.REQUIRE_DUE_DTM_COMMENT,
			in_can_set_public					=> r.CAN_SET_PUBLIC,
			in_public_by_default				=> r.PUBLIC_BY_DEFAULT,
			in_email_involved_roles				=> r.EMAIL_INVOLVED_ROLES,
			in_email_involved_users				=> r.EMAIL_INVOLVED_USERS,
			in_restrict_users_to_region			=> r.RESTRICT_USERS_TO_REGION,
			in_default_priority_id				=> r.DEFAULT_ISSUE_PRIORITY_ID,
			in_alert_pending_due_days			=> r.ALERT_PENDING_DUE_DAYS,
			in_alert_overdue_days				=> r.ALERT_OVERDUE_DAYS,
			in_auto_close_days					=> r.AUTO_CLOSE_AFTER_RESOLVE_DAYS,
			in_deletable_by_owner				=> r.DELETABLE_BY_OWNER,
			in_deletable_by_raiser				=> r.DELETABLE_BY_RAISER,
			in_deletable_by_administrator		=> r.DELETABLE_BY_ADMINISTRATOR,
			in_owner_can_be_changed				=> r.OWNER_CAN_BE_CHANGED,
			in_show_forecast_dtm				=> r.SHOW_FORECAST_DTM,
			in_require_var_expl					=> r.REQUIRE_VAR_EXPL,
			in_enable_reject_action				=> r.ENABLE_REJECT_ACTION,
			in_snd_alrt_on_issue_raised			=> r.SEND_ALERT_ON_ISSUE_RAISED,
			in_show_one_issue_popup				=> r.SHOW_ONE_ISSUE_POPUP,
			in_allow_owner_resolve_close		=> r.ALLOW_OWNER_RESOLVE_AND_CLOSE,
			in_is_region_editable				=> v_orig_is_region_editable,
			in_enable_manual_comp_date			=> r.ENABLE_MANUAL_COMP_DATE,
			in_comment_is_optional				=> r.COMMENT_IS_OPTIONAL,
			in_due_date_is_mandatory			=> r.DUE_DATE_IS_MANDATORY,
			in_allow_critical					=> r.ALLOW_CRITICAL,
			in_allow_urgent_alert				=> r.ALLOW_URGENT_ALERT,
			in_region_is_mandatory				=> r.REGION_IS_MANDATORY,
			out_issue_type_id					=> v_issue_type_id
		);

		UPDATE csr.issue_type
		   SET create_raw = v_orig_create_raw
		 WHERE issue_type_id = v_issue_type_id;
	END LOOP;

	--update audit region_sid
	UPDATE csr.internal_audit
	   SET region_sid = in_new_region_sid
	 WHERE internal_audit_sid = in_audit_sid;

	--update finding region_sid
	UPDATE csr.non_compliance
	   SET region_sid = in_new_region_sid
	 WHERE created_in_audit_sid = in_audit_sid;
END;

PROCEDURE SetCmsTableHelperPackage(
  in_schema				cms.tab.oracle_schema%TYPE,
  in_oracle_table		cms.tab.oracle_table%TYPE,
  in_helper_pkg			cms.tab.helper_pkg%TYPE
)
AS
BEGIN
	UPDATE cms.tab
	   SET helper_pkg = in_helper_pkg
	 WHERE oracle_schema = in_schema
	   AND oracle_table = in_oracle_table
	   AND app_sid = security.security_pkg.GetApp;
END;

PROCEDURE SetCmsTableFlowSid(
	in_workflow_label	csr.flow.label%TYPE,
	in_oracle_table		cms.tab.oracle_table%TYPE
)
AS
	v_workflow_sid		security.security_pkg.T_SID_ID;
BEGIN
	SELECT flow_sid
	  INTO v_workflow_sid
	  FROM csr.flow
	 WHERE label = in_workflow_label;

	SetCmsTableFlowSid(
		in_workflow_sid => v_workflow_sid,
		in_oracle_table => in_oracle_table
	);
END;

PROCEDURE SetCmsTableFlowSid(
	in_workflow_sid		security.security_pkg.T_SID_ID,
	in_oracle_table		cms.tab.oracle_table%TYPE
)
AS
BEGIN
	UPDATE cms.tab
	   SET flow_sid = in_workflow_sid
	 WHERE app_sid = security.security_pkg.GetApp
	   AND oracle_table = in_oracle_table;
END;


PROCEDURE SetCmsTableColumnNullable(
	in_oracle_schema	cms.tab.oracle_schema%TYPE,
	in_oracle_table		cms.tab.oracle_table%TYPE,
	in_oracle_column	cms.tab_column.oracle_column%TYPE,
	in_nullable			cms.tab_column.nullable%TYPE -- (0 or 1)
)
AS
	v_tab_sid			cms.tab.tab_sid%TYPE;
BEGIN
	SELECT tab_sid
	  INTO v_tab_sid
	  FROM cms.tab
	 WHERE app_sid = security.security_pkg.GetApp
	   AND oracle_schema = in_oracle_schema
	   AND oracle_table = in_oracle_table;

	UPDATE cms.tab_column
	   SET nullable = in_nullable
	 WHERE tab_sid = v_tab_sid
	   AND oracle_column = in_oracle_column;
END;

END;
/
