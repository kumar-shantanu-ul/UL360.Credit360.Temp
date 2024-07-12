CREATE OR REPLACE PACKAGE BODY csr.quick_survey_report_pkg
IS

PARENT_TYPE_AUDIT					CONSTANT NUMBER := 1;
PARENT_TYPE_CAMPAIGN				CONSTANT NUMBER := 2;
PARENT_TYPE_COMPANY					CONSTANT NUMBER := 3;
PARENT_TYPE_REGION					CONSTANT NUMBER := 4;
PARENT_TYPE_SURVEY					CONSTANT NUMBER := 5;

-- private field filter units
PROCEDURE FilterSurveySid			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSurveyVersion		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterIsCurrentVersion	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterPublishedDtm		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRegionSid			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAudits				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCampaignSid			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterFlowStateId			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterIsSubmitted			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSubmittedDtm		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSubmittedByUserSid	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterLatestSubmission	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterScore				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterScoreThresholdId	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterNoteQuestion		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterNumberQuestion		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterDateQuestion		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCheckboxQuestion	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCheckboxGrpQuestion	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRadioQuestion		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRegionQuestion		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterQuestionComment		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterQuestionFileUpload	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterQuestionScore		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSavedFilter			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_comparator IN chain.filter_field.comparator%TYPE, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);

PROCEDURE INTERNAL_ResponseSidsToCoSids (
	in_response_ids					IN security.T_ORDERED_SID_TABLE
);

FUNCTION GetResponseAudits (
	in_response_id_list						IN	chain.T_FILTERED_OBJECT_TABLE DEFAULT NULL,
	in_check_score_perm						IN	NUMBER DEFAULT 0
) RETURN T_QS_RESPONSE_PERM_TABLE
AS
	v_audits_sid							security_pkg.T_SID_ID;
	v_so_table								security.T_SO_DESCENDANTS_TABLE;
	v_audit_sid_list						security.T_ORDERED_SID_TABLE;
	v_audit_sids							security.T_SID_TABLE;
	v_response_audits						T_QS_RESPONSE_PERM_TABLE;
	v_all_response_audits					T_QS_RESPONSE_PERM_TABLE;
BEGIN

	BEGIN
		v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
	EXCEPTION WHEN security_pkg.OBJECT_NOT_FOUND THEN
		-- audits not enabled, no survey responses will relate to audits so return empty array so that only
		-- standard permissions are applied
		RETURN v_all_response_audits;
	END;
	
	v_so_table := securableobject_pkg.GetDescendantsWithPermAsTable(SYS_CONTEXT('SECURITY','ACT'), v_audits_sid, security_pkg.PERMISSION_READ);
	
	-- Primary survey uses FLOW_CAP_AUDIT_SURVEY
	
	SELECT security.T_ORDERED_SID_ROW(ia.internal_audit_sid, rownum)
	  BULK COLLECT INTO v_audit_sid_list
	  FROM quick_survey_response qsr
	  JOIN internal_audit ia ON ia.survey_response_id = qsr.survey_response_id
	  LEFT JOIN (SELECT DISTINCT object_id FROM TABLE (in_response_id_list)) t ON t.object_id = qsr.survey_response_id
	 WHERE (in_response_id_list IS NULL OR t.object_id IS NOT NULL);

	v_audit_sids := audit_pkg.GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_SURVEY, security.security_pkg.PERMISSION_READ, v_audit_sid_list);
	
	SELECT T_QS_RESPONSE_PERM_ROW(qsr.survey_response_id, ia.internal_audit_sid, CASE WHEN trash.trash_sid IS NULL AND ((ia.flow_item_id IS NULL AND so.sid_id IS NOT NULL) OR fc.column_value IS NOT NULL) THEN 1 ELSE 0 END, 0)
      BULK COLLECT INTO v_all_response_audits
	  FROM quick_survey_response qsr
	  JOIN internal_audit ia ON ia.survey_response_id = qsr.survey_response_id
	  LEFT JOIN trash ON trash.trash_sid = ia.internal_audit_sid
	  LEFT JOIN (SELECT DISTINCT object_id FROM TABLE (in_response_id_list)) t ON t.object_id = qsr.survey_response_id
	  LEFT JOIN (SELECT DISTINCT column_value FROM TABLE (v_audit_sids)) fc ON fc.column_value = ia.internal_audit_sid
	  LEFT JOIN (SELECT DISTINCT sid_id FROM TABLE (v_so_table)) so ON so.sid_id = ia.internal_audit_sid
	 WHERE (in_response_id_list IS NULL OR t.object_id IS NOT NULL);

	-- Executive summary uses FLOW_CAP_AUDIT_EXEC_SUMMARY
	
	SELECT security.T_ORDERED_SID_ROW(ia.internal_audit_sid, rownum)
	  BULK COLLECT INTO v_audit_sid_list
	  FROM quick_survey_response qsr
	  JOIN internal_audit ia ON ia.summary_response_id = qsr.survey_response_id
	  LEFT JOIN (SELECT DISTINCT object_id FROM TABLE (in_response_id_list)) t ON t.object_id = qsr.survey_response_id
	 WHERE (in_response_id_list IS NULL OR t.object_id IS NOT NULL);

	v_audit_sids := audit_pkg.GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_EXEC_SUMMARY, security.security_pkg.PERMISSION_READ, v_audit_sid_list);
	
	SELECT T_QS_RESPONSE_PERM_ROW(qsr.survey_response_id, ia.internal_audit_sid, CASE WHEN trash.trash_sid IS NULL AND ((ia.flow_item_id IS NULL AND so.sid_id IS NOT NULL) OR fc.column_value IS NOT NULL) THEN 1 ELSE 0 END, 0)
      BULK COLLECT INTO v_response_audits
	  FROM quick_survey_response qsr
	  JOIN internal_audit ia ON ia.summary_response_id = qsr.survey_response_id
	  LEFT JOIN trash ON trash.trash_sid = ia.internal_audit_sid
	  LEFT JOIN (SELECT DISTINCT object_id FROM TABLE (in_response_id_list)) t ON t.object_id = qsr.survey_response_id
	  LEFT JOIN (SELECT DISTINCT column_value FROM TABLE (v_audit_sids)) fc ON fc.column_value = ia.internal_audit_sid
	  LEFT JOIN (SELECT DISTINCT sid_id FROM TABLE (v_so_table)) so ON so.sid_id = ia.internal_audit_sid
	 WHERE (in_response_id_list IS NULL OR t.object_id IS NOT NULL);
 
	v_all_response_audits := v_all_response_audits MULTISET UNION ALL v_response_audits;

	-- Secondary surveys use FLOW_CAP_AUDIT_SURVEY or their own capability

	FOR r IN (
		SELECT iats.internal_audit_type_survey_id, NVL(iatsg.survey_capability_id, csr_data_pkg.FLOW_CAP_AUDIT_SURVEY) survey_capability_id
		  FROM internal_audit_type_survey iats
		  LEFT JOIN ia_type_survey_group iatsg ON iatsg.ia_type_survey_group_id = iats.ia_type_survey_group_id
	) LOOP
		SELECT security.T_ORDERED_SID_ROW(ias.internal_audit_sid, rownum)
		  BULK COLLECT INTO v_audit_sid_list
		  FROM quick_survey_response qsr
		  JOIN internal_audit_survey ias ON ias.survey_response_id = qsr.survey_response_id
		  LEFT JOIN (SELECT DISTINCT object_id FROM TABLE (in_response_id_list)) t ON t.object_id = qsr.survey_response_id
		 WHERE (in_response_id_list IS NULL OR t.object_id IS NOT NULL)
		   AND ias.internal_audit_type_survey_id = r.internal_audit_type_survey_id;

		v_audit_sids := audit_pkg.GetAuditsWithCapabilityAsTable(r.survey_capability_id, security.security_pkg.PERMISSION_READ, v_audit_sid_list);
		
		SELECT T_QS_RESPONSE_PERM_ROW(qsr.survey_response_id, ia.internal_audit_sid, CASE WHEN trash.trash_sid IS NULL AND ((ia.flow_item_id IS NULL AND so.sid_id IS NOT NULL) OR fc.column_value IS NOT NULL) THEN 1 ELSE 0 END, 0)
		  BULK COLLECT INTO v_response_audits
		  FROM quick_survey_response qsr
		  JOIN internal_audit_survey ias ON ias.survey_response_id = qsr.survey_response_id
		  JOIN internal_audit ia ON ia.internal_audit_sid = ias.internal_audit_sid
		  LEFT JOIN trash ON trash.trash_sid = ia.internal_audit_sid
		  LEFT JOIN (SELECT DISTINCT object_id FROM TABLE (in_response_id_list)) t ON t.object_id = qsr.survey_response_id
		  LEFT JOIN (SELECT DISTINCT column_value FROM TABLE (v_audit_sids)) fc ON fc.column_value = ia.internal_audit_sid
		  LEFT JOIN (SELECT DISTINCT sid_id FROM TABLE (v_so_table)) so ON so.sid_id = ia.internal_audit_sid
		 WHERE (in_response_id_list IS NULL OR t.object_id IS NOT NULL)
		   AND ias.internal_audit_type_survey_id = r.internal_audit_type_survey_id;
		   
		v_all_response_audits := v_all_response_audits MULTISET UNION ALL v_response_audits;
	END LOOP;

	IF in_check_score_perm != 0 THEN
		SELECT security.T_ORDERED_SID_ROW(t.object_id, rownum)
		  BULK COLLECT INTO v_audit_sid_list
		  FROM TABLE(v_all_response_audits) t;
		
		v_audit_sids := audit_pkg.GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_SCORE, security.security_pkg.PERMISSION_READ, v_audit_sid_list);
		
		SELECT T_QS_RESPONSE_PERM_ROW(t.survey_response_id, t.object_id, t.can_see_response, CASE WHEN ia.flow_item_id IS NOT NULL AND sc.column_value IS NULL THEN 0 ELSE t.can_see_response END)
		  BULK COLLECT INTO v_response_audits
		  FROM TABLE(v_all_response_audits) t
		  JOIN internal_audit ia ON ia.internal_audit_sid = t.object_id
		  LEFT JOIN (SELECT DISTINCT column_value FROM TABLE (v_audit_sids)) sc ON sc.column_value = ia.internal_audit_sid;

		v_all_response_audits := v_response_audits;
	END IF;

	RETURN v_all_response_audits;
END;

FUNCTION GetResponseCompanies (
	in_response_id_list						IN	chain.T_FILTERED_OBJECT_TABLE DEFAULT NULL,
	in_check_score_perm						IN	NUMBER DEFAULT 0
) RETURN T_QS_RESPONSE_PERM_TABLE
AS
	v_company_sid							security_pkg.T_SID_ID;
	v_company_sids							security.T_SID_TABLE;
	v_view_scores							security.T_SID_TABLE;
	v_response_companies					T_QS_RESPONSE_PERM_TABLE;
	v_all_response_companies				T_QS_RESPONSE_PERM_TABLE;
BEGIN
	IF NOT chain.setup_pkg.IsChainEnabled THEN
		RETURN T_QS_RESPONSE_PERM_TABLE();
	END IF;

	v_company_sid := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	IF v_company_sid IS NULL THEN
		SELECT T_QS_RESPONSE_PERM_ROW(qsr.survey_response_id, NULL, 0, 0)
		  BULK COLLECT INTO v_all_response_companies
		  FROM v$quick_survey_response qsr
		  LEFT JOIN TABLE(in_response_id_list) t ON t.object_id = qsr.survey_response_id
		 WHERE (in_response_id_list IS NULL OR t.object_id IS NOT NULL);
	ELSE	
		v_company_sids := chain.company_pkg.GetVisibleCompanySids;

		SELECT T_QS_RESPONSE_PERM_ROW(qsr.survey_response_id, s.company_sid, CASE WHEN trash.trash_sid IS NULL AND vis.column_value IS NOT NULL THEN 1 ELSE 0 END, 0)
		  BULK COLLECT INTO v_all_response_companies
		  FROM v$quick_survey_response qsr
		  JOIN supplier_survey_response ssr ON ssr.survey_response_id = qsr.survey_response_id
		  JOIN supplier s ON s.company_sid = ssr.supplier_sid
		  LEFT JOIN trash ON trash.trash_sid = s.company_sid
		  LEFT JOIN TABLE(v_company_sids) vis ON vis.column_value = s.company_sid
		  LEFT JOIN TABLE(in_response_id_list) t ON t.object_id = qsr.survey_response_id
		 WHERE (in_response_id_list IS NULL OR t.object_id IS NOT NULL);

		IF in_check_score_perm != 0 THEN
			SELECT object_id
			  BULK COLLECT INTO v_company_sids
			  FROM TABLE(v_all_response_companies)
			 WHERE can_see_response = 1;

			v_view_scores := chain.type_capability_pkg.FilterPermissibleCompanySids(v_company_sids, chain.chain_pkg.COMPANY_SCORES, security.security_pkg.PERMISSION_READ);
			IF v_company_sid MEMBER OF v_company_sids AND chain.type_capability_pkg.CheckCapability(v_company_sid, chain.chain_pkg.COMPANY_SCORES, security.security_pkg.PERMISSION_READ) THEN
				v_view_scores.EXTEND;
				v_view_scores(v_view_scores.COUNT) := v_company_sid;
			END IF;
		
			SELECT T_QS_RESPONSE_PERM_ROW(t.survey_response_id, t.object_id, t.can_see_response, CASE WHEN vs.column_value IS NULL THEN 0 ELSE t.can_see_response END)
			  BULK COLLECT INTO v_response_companies
			  FROM TABLE(v_all_response_companies) t
			  LEFT JOIN TABLE(v_view_scores) vs ON vs.column_value = t.object_id;

			v_all_response_companies := v_response_companies;
		END IF;
	END IF;

	return v_all_response_companies;
END;

FUNCTION GetResponseFlowItems(
	in_response_ids					IN  chain.T_FILTERED_OBJECT_TABLE
) RETURN T_QS_RESPONSE_PERM_TABLE
AS
	v_response_flow_items			T_QS_RESPONSE_PERM_TABLE;
BEGIN
	SELECT T_QS_RESPONSE_PERM_ROW(survey_response_id, flow_item_id, can_see_response, can_see_response)
	  BULK COLLECT INTO v_response_flow_items
	  FROM (
		SELECT qsr.survey_response_id, fi.flow_item_id, 1 can_see_response
		  FROM v$quick_survey_response qsr
		  LEFT JOIN (SELECT DISTINCT object_id FROM TABLE(in_response_ids)) t ON qsr.survey_response_id = t.object_id
		  JOIN flow_item fi ON fi.survey_response_id = qsr.survey_response_id
		  JOIN flow_state_role_capability fsrc ON fi.current_state_id = fsrc.flow_state_id 
		   AND fsrc.flow_capability_id = csr_data_pkg.FLOW_CAP_CAMPAIGN_RESPONSE
		   AND fsrc.permission_set > 0
		  JOIN region_survey_response rsr ON rsr.survey_response_id = qsr.survey_response_id
		  LEFT JOIN region_role_member rrm ON rsr.region_sid = rrm.region_sid AND rrm.role_sid = fsrc.role_sid AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		  LEFT JOIN supplier s ON rsr.region_sid = s.region_sid
		  LEFT JOIN chain.v$purchaser_involvement pi ON fsrc.flow_involvement_type_id = pi.flow_involvement_type_id AND s.company_sid = pi.supplier_company_sid
		 WHERE (in_response_ids IS NULL OR t.object_id IS NOT NULL)
		   AND (rrm.user_sid IS NOT NULL OR pi.flow_involvement_type_id IS NOT NULL)
		 GROUP BY qsr.survey_response_id, fi.flow_item_id
	  );

	return v_response_flow_items;
END;

FUNCTION GetResponseRegions(
	in_response_ids					IN  chain.T_FILTERED_OBJECT_TABLE
) RETURN T_QS_RESPONSE_PERM_TABLE -- only used for first two columns
AS
	v_companies_cap					T_QS_RESPONSE_PERM_TABLE := GetResponseCompanies(in_response_ids);
	v_audits_cap					T_QS_RESPONSE_PERM_TABLE := GetResponseAudits(in_response_ids);
	v_response_regions				T_QS_RESPONSE_PERM_TABLE;
BEGIN
	SELECT T_QS_RESPONSE_PERM_ROW(qsr.survey_response_id, r.region_sid, 1, 0)
	  BULK COLLECT INTO v_response_regions
	  FROM v$quick_survey_response qsr
	  LEFT JOIN (SELECT DISTINCT object_id FROM TABLE(in_response_ids)) t ON qsr.survey_response_id = t.object_id
	  LEFT JOIN region_survey_response rsr ON rsr.survey_response_id = qsr.survey_response_id
	  LEFT JOIN (
			SELECT companies_cap.survey_response_id, companies_cap.can_see_response, s.region_sid
			  FROM chain.v$company c
			  JOIN TABLE(v_companies_cap) companies_cap ON c.company_sid = companies_cap.object_id
			  LEFT JOIN supplier s ON s.company_sid = c.company_sid
	  ) c_t ON c_t.survey_response_id = qsr.survey_response_id
	  LEFT JOIN (
			SELECT audits_cap.survey_response_id, audits_cap.can_see_response, ia.region_sid
			  FROM internal_audit ia
			  JOIN TABLE(v_audits_cap) audits_cap ON ia.internal_audit_sid = audits_cap.object_id
	  ) ia_t ON ia_t.survey_response_id = qsr.survey_response_id
	  JOIN (
			SELECT DISTINCT app_sid, NVL(link_to_region_sid, region_sid) region_sid
			  FROM region
			 START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') 
			   AND region_sid IN (SELECT region_sid FROM region_start_point WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID'))
		   CONNECT BY PRIOR app_sid = app_sid 
			   AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
	  ) rt ON COALESCE(rsr.region_sid, c_t.region_sid, ia_t.region_sid) = rt.region_sid
	  JOIN v$region r ON r.region_sid = rt.region_sid
	 WHERE r.region_sid IS NOT NULL
	   AND (c_t.survey_response_id IS NULL OR c_t.can_see_response = 1)
	   AND (ia_t.survey_response_id IS NULL OR ia_t.can_see_response = 1)
	   AND (in_response_ids IS NULL OR t.object_id IS NOT NULL);

	RETURN v_response_regions;
END;

PROCEDURE FilterSurveyResponseIds (
	in_filter_id					IN	chain.filter.filter_id%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN	NUMBER,
	in_ids							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT	chain.T_FILTERED_OBJECT_TABLE
) AS
	v_starting_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_result_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_inner_log_id					chain.debug_log.debug_log_id%TYPE;
BEGIN
	v_starting_ids := in_ids;

	IF in_parallel = 0 THEN
		out_ids := in_ids;
	ELSE
		out_ids := chain.T_FILTERED_OBJECT_TABLE();
	END IF;
	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.quick_survey_report_pkg.FilterSurveyResponseIds', in_filter_id);
	
	FOR r IN (
		SELECT name, filter_field_id, show_all, group_by_index, column_sid, compound_filter_id, comparator
		  FROM chain.v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := chain.filter_pkg.StartDebugLog('csr.quick_survey_report_pkg.FilterSurveyResponseIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);
		IF LOWER(r.name) = 'surveysid' THEN
			FilterSurveySid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'surveyversion' THEN
			FilterSurveyVersion(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'iscurrentversion' THEN
			FilterIsCurrentVersion(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'publisheddtm' THEN
			FilterPublishedDtm(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'regionsid' THEN
			FilterRegionSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'auditfilter' OR LOWER(r.name) LIKE 'auditfilter.%' THEN
			FilterAudits(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'campaignsid' THEN
			FilterCampaignSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'flowstateid' THEN
			FilterFlowStateId(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'issubmitted' THEN
			FilterIsSubmitted(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'submitteddtm' THEN
			FilterSubmittedDtm(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'submittedbyusersid' THEN
			FilterSubmittedByUserSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'islatestsubmission' THEN
			FilterLatestSubmission(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'score' THEN
			FilterScore(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'scorethresholdid' THEN
			FilterScoreThresholdId(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) LIKE 'notequestion.%' THEN
			FilterNoteQuestion(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) LIKE 'numberquestion.%' OR LOWER(r.name) LIKE 'sliderquestion.%' THEN
			FilterNumberQuestion(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) LIKE 'datequestion.%' THEN
			FilterDateQuestion(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) LIKE 'checkboxquestion.%' THEN
			FilterCheckboxQuestion(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) LIKE 'checkboxgroupquestion.%' THEN
			FilterCheckboxGrpQuestion(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) LIKE 'radioquestion.%' OR LOWER(r.name) LIKE 'radiorowquestion.%' THEN
			FilterRadioQuestion(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) LIKE 'regionpickerquestion.%' THEN
			FilterRegionQuestion(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) LIKE 'questioncomment.%' THEN
			FilterQuestionComment(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) LIKE 'questionfileupload.%' THEN
			FilterQuestionFileUpload(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) LIKE 'questionscore.%' THEN
			FilterQuestionScore(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'savedfilter' THEN
			FilterSavedFilter(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, r.comparator, v_starting_ids, v_result_ids);
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown filter ' || r.name);
		END IF;
		
		chain.filter_pkg.EndDebugLog(v_inner_log_id);
		
		IF r.comparator = chain.filter_pkg.COMPARATOR_EXCLUDE THEN 
			chain.filter_pkg.InvertFilterSet(v_starting_ids, v_result_ids, v_result_ids);
		END IF;
		
		IF in_parallel = 0 THEN
			v_starting_ids := v_result_ids;
			out_ids := v_result_ids;
		ELSE
			out_ids := out_ids MULTISET UNION v_result_ids;
		END IF;
	END LOOP;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE CopyFilter (
	in_from_filter_id				IN	chain.filter.filter_id%TYPE,
	in_to_filter_id					IN	chain.filter.filter_id%TYPE
)
AS
BEGIN
	chain.filter_pkg.CopyFieldsAndValues(in_from_filter_id, in_to_filter_id);
END;

PROCEDURE RunCompoundFilter(
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN	NUMBER,
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE,
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN	
	chain.filter_pkg.RunCompoundFilter('FilterSurveyResponseIds', in_compound_filter_id, in_parallel, in_max_group_by, in_id_list, out_id_list);
END;

PROCEDURE GetFilterObjectData (
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_companies_cap					T_QS_RESPONSE_PERM_TABLE := NULL;
	v_audits_cap					T_QS_RESPONSE_PERM_TABLE := NULL;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.quick_survey_report_pkg.GetFilterObjectData');

	-- just in case
	DELETE FROM chain.tt_filter_object_data;
	
	IF AGG_TYPE_COUNT MEMBER OF in_aggregation_types THEN
		INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
		SELECT DISTINCT AGG_TYPE_COUNT, l.object_id, chain.filter_pkg.AFUNC_COUNT, l.object_id
		  FROM TABLE(in_id_list) l;
	END IF;
 
	-- Run aggregate types for survey scores but only if requested
	FOR chk IN (
		SELECT *
		  FROM dual
		 WHERE EXISTS(SELECT * FROM TABLE(in_aggregation_types) WHERE column_value BETWEEN 2 AND 9999)
	) LOOP
		-- COALESCE not NVL because NVL doesn't short-circuit
		v_companies_cap := COALESCE(v_companies_cap, GetResponseCompanies(in_id_list));
		v_audits_cap := COALESCE(v_companies_cap, GetResponseAudits(in_id_list));

		INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
		SELECT DISTINCT at.column_value, l.object_id,
				CASE at.column_value
					WHEN AGG_TYPE_SUM_SCORES THEN chain.filter_pkg.AFUNC_SUM
					WHEN AGG_TYPE_AVG_SCORE THEN chain.filter_pkg.AFUNC_AVERAGE
					WHEN AGG_TYPE_MIN_SCORE THEN chain.filter_pkg.AFUNC_MIN
					WHEN AGG_TYPE_MAX_SCORE THEN chain.filter_pkg.AFUNC_MAX
				END,
				CASE at.column_value
					WHEN AGG_TYPE_SUM_SCORES THEN qsr.overall_score
					WHEN AGG_TYPE_AVG_SCORE THEN qsr.overall_score
					WHEN AGG_TYPE_MIN_SCORE THEN qsr.overall_score
					WHEN AGG_TYPE_MAX_SCORE THEN qsr.overall_score
				END
		  FROM v$quick_survey_response qsr
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) l ON qsr.survey_response_id = l.object_id
		  LEFT JOIN TABLE(v_companies_cap) c_t ON c_t.survey_response_id = qsr.survey_response_id
		  LEFT JOIN TABLE(v_audits_cap) ia_t ON ia_t.survey_response_id = qsr.survey_response_id
		 CROSS JOIN TABLE(in_aggregation_types) at
		 WHERE at.column_value > AGG_TYPE_COUNT -- count is worked out above
		   AND at.column_value < 10000 -- custom agg types start at 10000
		   AND (c_t.survey_response_id IS NULL OR c_t.can_see_scores = 1)
		   AND (ia_t.survey_response_id IS NULL OR ia_t.can_see_scores = 1);
	END LOOP;

	-- Run aggregate types for answer scores but only if requested
	FOR r IN (
		SELECT cfi.customer_filter_item_id, CAST(regexp_substr(cfi.item_name, '[0-9]+') AS NUMBER) question_id
		  FROM chain.customer_filter_item cfi
		 WHERE cfi.item_name LIKE 'questionScore.%'
		   AND EXISTS (
				SELECT NULL
				  FROM TABLE(in_aggregation_types) at
				  JOIN chain.customer_aggregate_type cat ON cat.customer_aggregate_type_id = at.column_value
				  JOIN chain.cust_filt_item_agg_type cfiat ON cfiat.cust_filt_item_agg_type_id = cat.cust_filt_item_agg_type_id
				 WHERE cfiat.customer_filter_item_id = cfi.customer_filter_item_id
		   )
	) LOOP
		v_companies_cap := COALESCE(v_companies_cap, GetResponseCompanies(in_id_list));
		v_audits_cap := COALESCE(v_companies_cap, GetResponseAudits(in_id_list));

		INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
		SELECT DISTINCT at.column_value, l.object_id, cfiat.analytic_function, qsa.score
		  FROM v$quick_survey_response qsr
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) l ON qsr.survey_response_id = l.object_id
		  LEFT JOIN TABLE(v_companies_cap) c_t ON c_t.survey_response_id = qsr.survey_response_id
		  LEFT JOIN TABLE(v_audits_cap) ia_t ON ia_t.survey_response_id = qsr.survey_response_id
		  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
									  AND qsa.submission_id = qsr.submission_id
									  AND qsa.question_id = r.question_id
		 CROSS JOIN TABLE(in_aggregation_types) at
		  JOIN chain.customer_aggregate_type cat ON cat.customer_aggregate_type_id = at.column_value
		  JOIN chain.cust_filt_item_agg_type cfiat ON cfiat.cust_filt_item_agg_type_id = cat.cust_filt_item_agg_type_id
		 WHERE (c_t.survey_response_id IS NULL OR c_t.can_see_scores = 1)
		   AND (ia_t.survey_response_id IS NULL OR ia_t.can_see_scores = 1)
		   AND cfiat.customer_filter_item_id = r.customer_filter_item_id;
	END LOOP;

	-- Run aggregate types for numeric answers but only if requested
	FOR r IN (
		SELECT cfi.customer_filter_item_id, CAST(regexp_substr(cfi.item_name, '[0-9]+') AS NUMBER) question_id
		  FROM chain.customer_filter_item cfi
		 WHERE ( 
				cfi.item_name LIKE 'numberQuestion.%' OR
				cfi.item_name LIKE 'sliderQuestion.%'
		 ) AND EXISTS (
				SELECT NULL
				  FROM TABLE(in_aggregation_types) at
				  JOIN chain.customer_aggregate_type cat ON cat.customer_aggregate_type_id = at.column_value
				  JOIN chain.cust_filt_item_agg_type cfiat ON cfiat.cust_filt_item_agg_type_id = cat.cust_filt_item_agg_type_id
				 WHERE cfiat.customer_filter_item_id = cfi.customer_filter_item_id
		   )
	) LOOP
		v_companies_cap := COALESCE(v_companies_cap, GetResponseCompanies(in_id_list));
		v_audits_cap := COALESCE(v_companies_cap, GetResponseAudits(in_id_list));

		INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
		SELECT DISTINCT at.column_value, l.object_id, cfiat.analytic_function, qsa.val_number
		  FROM v$quick_survey_response qsr
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) l ON qsr.survey_response_id = l.object_id
		  LEFT JOIN TABLE(v_companies_cap) c_t ON c_t.survey_response_id = qsr.survey_response_id
		  LEFT JOIN TABLE(v_audits_cap) ia_t ON ia_t.survey_response_id = qsr.survey_response_id
		  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
									  AND qsa.submission_id = qsr.submission_id
									  AND qsa.question_id = r.question_id
		 CROSS JOIN TABLE(in_aggregation_types) at
		  JOIN chain.customer_aggregate_type cat ON cat.customer_aggregate_type_id = at.column_value
		  JOIN chain.cust_filt_item_agg_type cfiat ON cfiat.cust_filt_item_agg_type_id = cat.cust_filt_item_agg_type_id
		 WHERE (c_t.survey_response_id IS NULL OR c_t.can_see_scores = 1)
		   AND (ia_t.survey_response_id IS NULL OR ia_t.can_see_scores = 1)
		   AND cfiat.customer_filter_item_id = r.customer_filter_item_id;
	END LOOP;

	-- Run aggregate types for file uploads but only if requested
	FOR r IN (
		SELECT cfi.customer_filter_item_id, CAST(regexp_substr(cfi.item_name, '[0-9]+') AS NUMBER) question_id
		  FROM chain.customer_filter_item cfi
		 WHERE cfi.item_name LIKE 'questionFileUpload.%'
		   AND EXISTS (
				SELECT NULL
				  FROM TABLE(in_aggregation_types) at
				  JOIN chain.customer_aggregate_type cat ON cat.customer_aggregate_type_id = at.column_value
				  JOIN chain.cust_filt_item_agg_type cfiat ON cfiat.cust_filt_item_agg_type_id = cat.cust_filt_item_agg_type_id
				 WHERE cfiat.customer_filter_item_id = cfi.customer_filter_item_id
		   )
	) LOOP
		v_companies_cap := COALESCE(v_companies_cap, GetResponseCompanies(in_id_list));
		v_audits_cap := COALESCE(v_companies_cap, GetResponseAudits(in_id_list));

		INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
		SELECT DISTINCT at.column_value, l.object_id, cfiat.analytic_function, fc.num_files
		  FROM v$quick_survey_response qsr
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) l ON qsr.survey_response_id = l.object_id
		  JOIN (
				SELECT survey_response_id, count(*) num_files
				  FROM qs_answer_file
				 WHERE question_id = r.question_id
				 GROUP BY survey_response_id
		  ) fc ON fc.survey_response_id = qsr.survey_response_id
		 CROSS JOIN TABLE(in_aggregation_types) at
		  JOIN chain.customer_aggregate_type cat ON cat.customer_aggregate_type_id = at.column_value
		  JOIN chain.cust_filt_item_agg_type cfiat ON cfiat.cust_filt_item_agg_type_id = cat.cust_filt_item_agg_type_id
		 WHERE cfiat.customer_filter_item_id = r.customer_filter_item_id;
	END LOOP;

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetFilteredIds(
	in_search						IN	VARCHAR2 DEFAULT NULL,
	in_group_key					IN	chain.saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
	in_parent_id					IN	NUMBER DEFAULT NULL,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_region_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_start_dtm					IN	DATE DEFAULT NULL,
	in_end_dtm						IN	DATE DEFAULT NULL,
	in_region_col_type				IN	NUMBER DEFAULT NULL,
	in_date_col_type				IN	NUMBER DEFAULT NULL,
	in_id_list_populated			IN  NUMBER DEFAULT 0,
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE DEFAULT NULL,
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_sanitised_search				VARCHAR2(4000) := aspen2.utils_pkg.SanitiseOracleContains(in_search);
	v_has_regions					NUMBER;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_surveys_sid					security.security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'wwwroot/surveys');
	v_read_cap						security.T_SO_DESCENDANTS_TABLE := security.securableobject_pkg.GetDescendantsWithPermAsTable(SYS_CONTEXT('SECURITY','ACT'), v_surveys_sid, security_pkg.PERMISSION_READ);
	v_list_cap						security.T_SO_DESCENDANTS_TABLE := security.securableobject_pkg.GetDescendantsWithPermAsTable(SYS_CONTEXT('SECURITY','ACT'), v_surveys_sid, security_pkg.PERMISSION_LIST_CONTENTS);
	v_audits_cap					T_QS_RESPONSE_PERM_TABLE := GetResponseAudits(in_id_list);
	v_companies_cap					T_QS_RESPONSE_PERM_TABLE := GetResponseCompanies(in_id_list);
	v_flow_cap						T_QS_RESPONSE_PERM_TABLE := GetResponseFlowItems(in_id_list);
	v_campaigns_sid					security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Campaigns');
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.quick_survey_report_pkg.GetFilteredIds', in_compound_filter_id);

	chain.filter_pkg.PopulateTempRegionSid(in_region_sids, in_region_col_type, v_has_regions);

	SELECT chain.T_FILTERED_OBJECT_ROW(qsr.survey_response_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
		FROM quick_survey_response qsr
		JOIN quick_survey qs ON qsr.survey_sid = qs.survey_sid
		JOIN quick_survey_version qsv ON qsv.survey_sid = qsr.survey_sid AND qsv.survey_version = qsr.survey_version
		LEFT JOIN (SELECT DISTINCT sid_id FROM TABLE(v_list_cap)) list_cap ON list_cap.sid_id = qsr.survey_sid
		LEFT JOIN region_survey_response rsr ON rsr.survey_response_id = qsr.survey_response_id
		LEFT JOIN (
			SELECT companies_cap.survey_response_id, companies_cap.can_see_response,
				   s.company_sid, s.region_sid
			  FROM TABLE(v_companies_cap) companies_cap
			  LEFT JOIN supplier s ON s.company_sid = companies_cap.object_id
		) c_t ON c_t.survey_response_id = qsr.survey_response_id
		LEFT JOIN (
			SELECT audits_cap.survey_response_id, audits_cap.can_see_response,
				   ia.internal_audit_sid, ia.region_sid
			  FROM internal_audit ia
			  JOIN TABLE(v_audits_cap) audits_cap ON ia.internal_audit_sid = audits_cap.object_id
	    ) ia_t ON ia_t.survey_response_id = qsr.survey_response_id
		LEFT JOIN (
			SELECT flow_cap.survey_response_id, flow_cap.can_see_response,
				   fi.flow_item_id
			  FROM flow_item fi
			  JOIN TABLE(v_flow_cap) flow_cap ON fi.flow_item_id = flow_cap.object_id
		) f_t ON f_t.survey_response_id = qsr.survey_response_id
	    LEFT JOIN temp_region_sid tr ON COALESCE(rsr.region_sid, c_t.region_sid, ia_t.region_sid) = tr.region_sid
	   WHERE qsr.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	     AND qsr.survey_version > 0
	     AND qsr.hidden = 0
	     AND (
			  qsr.user_sid = SYS_CONTEXT('SECURITY', 'SID') OR 
			  list_cap.sid_id IS NOT NULL OR
			  ia_t.internal_audit_sid IS NOT NULL OR
			  c_t.company_sid IS NOT NULL OR
			  f_t.flow_item_id IS NOT NULL
		 )
		 AND (qs.audience not like 'chain%' OR c_t.company_sid IS NOT NULL)
		 AND (qs.audience != 'audit' OR rsr.survey_response_id IS NOT NULL OR ia_t.internal_audit_sid IS NOT NULL)
		 AND (c_t.survey_response_id IS NULL OR c_t.can_see_response = 1)
		 AND (ia_t.survey_response_id IS NULL OR ia_t.can_see_response = 1)
		 AND (f_t.survey_response_id IS NULL OR f_t.can_see_response = 1)
	     AND (v_has_regions = 0 OR tr.region_sid IS NOT NULL)
		 AND (
			  in_parent_type IS NULL OR 
			  (in_parent_type = PARENT_TYPE_AUDIT AND ia_t.internal_audit_sid = in_parent_id) OR
			  (in_parent_type = PARENT_TYPE_CAMPAIGN AND qsr.qs_campaign_sid = in_parent_id) OR
			  (in_parent_type = PARENT_TYPE_COMPANY AND c_t.company_sid = in_parent_id) OR
			  (in_parent_type = PARENT_TYPE_REGION AND tr.region_sid = in_parent_id) OR
			  (in_parent_type = PARENT_TYPE_SURVEY AND qsr.survey_sid = in_parent_id)
		 )
		 AND (
			  UPPER(qsv.label) LIKE '%' || UPPER(in_search) || '%'
			  OR CAST(qs.survey_sid AS VARCHAR2(20)) = TRIM(in_search)
			  OR CAST(qsr.survey_response_id AS VARCHAR2(20)) = TRIM(in_search)
		 )
		 AND (
			  qsr.qs_campaign_sid IS NULL OR (
				  qsr.qs_campaign_sid NOT IN (SELECT trash_sid FROM trash)
				  AND f_t.survey_response_id IS NOT NULL 
			  )
		 );

	chain.filter_pkg.EndDebugLog(v_log_id);
	aspen2.request_queue_pkg.AssertRequestStillActive;
	
	IF NVL(in_pre_filter_sid, 0) > 0 THEN
		FOR r IN (
			SELECT sf.compound_filter_id, sf.search_text
			  FROM chain.saved_filter sf
			 WHERE saved_filter_sid = in_pre_filter_sid
		) LOOP	
			GetFilteredIds(
				in_search						=> r.search_text,
				in_compound_filter_id			=> r.compound_filter_id,
				in_id_list						=> v_id_list,
				out_id_list						=> v_id_list
			);
		END LOOP;
	END IF;

	IF NVL(in_compound_filter_id, 0) > 0 THEN -- XPJ passes round zero for some reason?
		RunCompoundFilter(in_compound_filter_id, 0, NULL, v_id_list, v_id_list);
	END IF;

	out_id_list := v_id_list;
END;

PROCEDURE ApplyBreadcrumb(
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_aggregation_type				IN	NUMBER DEFAULT NULL,
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_breadcrumb_count				NUMBER;
	v_field_compound_filter_id		NUMBER;
	v_top_n_values					security.T_ORDERED_SID_TABLE; -- not sids, but this exists already
	v_aggregation_types				security.T_SID_TABLE;
	v_temp							chain.T_FILTERED_OBJECT_TABLE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.quick_survey_report_pkg.ApplyBreadcrumb');

	out_id_list := in_id_list;

	v_breadcrumb_count := CASE WHEN in_breadcrumb IS NULL THEN 0 WHEN in_breadcrumb.COUNT = 1 AND in_breadcrumb(1) IS NULL THEN 0 ELSE in_breadcrumb.COUNT END;

	IF v_breadcrumb_count > 0 THEN
		v_field_compound_filter_id := chain.filter_pkg.GetCompFilterIdFromBreadcrumb(in_breadcrumb);

		RunCompoundFilter(v_field_compound_filter_id, 1, v_breadcrumb_count, out_id_list, out_id_list);

		-- check if any breadcrumb elements are on "other". If not, we don't need to do a top N	
		IF in_breadcrumb(1) < 0 OR
			(v_breadcrumb_count > 1 AND in_breadcrumb(2) < 0) OR
			(v_breadcrumb_count > 2 AND in_breadcrumb(3) < 0) OR
			(v_breadcrumb_count > 3 AND in_breadcrumb(4) < 0)
		THEN
			-- Use the aggregation type for drilldowns on "other"
			-- If not supplied, use count
			SELECT NVL(in_aggregation_type, 1) BULK COLLECT INTO v_aggregation_types FROM dual;

			GetFilterObjectData (v_aggregation_types, out_id_list);

			-- apply top n
 			v_top_n_values := chain.filter_pkg.FindTopN(v_field_compound_filter_id, NVL(in_aggregation_type, 1), out_id_list, in_breadcrumb);  

			-- update any rows that aren't in top N to -group_by_index, indicating they're "other"
			SELECT chain.T_FILTERED_OBJECT_ROW (l.object_id, l.group_by_index, CASE WHEN t.pos IS NOT NULL THEN l.group_by_value ELSE -ff.filter_field_id END)
			  BULK COLLECT INTO v_temp
			  FROM TABLE(out_id_list) l
			  JOIN chain.v$filter_field ff ON l.group_by_index = ff.group_by_index AND ff.compound_filter_id = v_field_compound_filter_id
			  LEFT JOIN TABLE(v_top_n_values) t ON l.group_by_value = t.pos;
		ELSE
			v_temp := out_id_list;
		END IF;

		-- apply breadcrumb
		chain.filter_pkg.ApplyBreadcrumb(v_temp, in_breadcrumb, out_id_list);
	END IF;

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE CollectSearchResults (
	in_id_list						IN	security.T_ORDERED_SID_TABLE,
	in_session_prefix				IN	chain.customer_filter_column.session_prefix%TYPE DEFAULT NULL,
	out_response_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_answers_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_files_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_campaigns_sid					security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Campaigns');
	v_campaigns_cap					security.T_SO_DESCENDANTS_TABLE := security.securableobject_pkg.GetDescendantsWithPermAsTable(SYS_CONTEXT('SECURITY','ACT'), v_campaigns_sid, security_pkg.PERMISSION_READ);
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := NULL;
	v_question_ids					security.T_SID_TABLE;
	v_companies_cap					T_QS_RESPONSE_PERM_TABLE;
	v_audits_cap					T_QS_RESPONSE_PERM_TABLE;
	v_flow_cap						T_QS_RESPONSE_PERM_TABLE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.quick_survey_report_pkg.CollectSearchResults');
	
	SELECT chain.T_FILTERED_OBJECT_ROW(sid_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM TABLE(in_id_list);
	
	v_companies_cap := GetResponseCompanies(v_id_list, 1);
	v_audits_cap := GetResponseAudits(v_id_list, 1);
	v_flow_cap := GetResponseFlowItems(v_id_list);

	OPEN out_response_cur FOR
		SELECT qsr.survey_response_id, qsr.guid,
			   qs.survey_sid,  wr.path survey_path,
			   qsv.survey_version, qsv.label survey_label, qsv.published_dtm survey_published_dtm,
			   CASE WHEN qsv.survey_version = qs.current_version THEN 1 ELSE 0 END is_current_version,
			   qsr.user_sid, CASE WHEN qsr.user_sid IS NULL THEN qsr.user_name ELSE u.full_name END user_name,
			   CASE WHEN qss.submission_id = 0 THEN 0 ELSE 1 END is_submitted,
			   qss.submission_id, qss.submitted_dtm, qss.submitted_by_user_sid, sbu.full_name submitted_by_user_name,
			   qsc_t.qs_campaign_sid campaign_sid, qsc_t.name campaign_name,
			   ia_t.internal_audit_sid, ia_t.label internal_audit_label,
			   ia_t.ia_type_group_id, ia_t.ia_type_group_lookup_key,
			   f_t.flow_state_id, f_t.flow_state_label,
			   CASE WHEN 
					(c_t.survey_response_id IS NULL AND ia_t.survey_response_id IS NULL) OR 
					(c_t.can_see_scores = 1) OR
					(ia_t.can_see_scores = 1)
			   THEN qss.overall_score END overall_score,
			   CASE WHEN 
					(c_t.survey_response_id IS NULL AND ia_t.survey_response_id IS NULL) OR 
					(c_t.can_see_scores = 1) OR
					(ia_t.can_see_scores = 1)
			   THEN qss.overall_max_score END overall_max_score,
			   st.score_type_id, st.format_mask score_format_mask,
			   sth.score_threshold_id, sth.description score_threshold_description,
			   sth.text_colour, sth.background_colour, cast(sth.icon_image_sha1 as varchar2(40)) icon_image_sha1,
			   r.region_sid, r.region_type, r.description region_description, s.company_sid,
			   -- We won't get a mixture here thanks to CK_QSS_GEOLOCATION
			   NVL(qss.geo_latitude, r.geo_latitude) latitude,
			   NVL(qss.geo_longitude, r.geo_longitude) longitude,
			   qss.geo_h_accuracy accuracy
		  FROM quick_survey_response qsr
		  JOIN quick_survey_submission qss ON qsr.survey_response_id = qss.survey_response_id AND NVL(qsr.last_submission_id, 0) = qss.submission_id
		  JOIN TABLE(in_id_list) l ON l.sid_id = qsr.survey_response_id
		  JOIN quick_survey qs ON qs.survey_sid = qsr.survey_sid
		  JOIN quick_survey_version qsv ON qsv.survey_sid = qsr.survey_sid AND qsv.survey_version = qsr.survey_version
		  JOIN security.web_resource wr ON wr.sid_id = qs.survey_sid
		  LEFT JOIN region_survey_response rsr ON rsr.survey_response_id = qsr.survey_response_id
		  LEFT JOIN (
				SELECT qsc.campaign_sid qs_campaign_sid, qsc.name
				  FROM campaigns.campaign qsc
				  JOIN TABLE(v_campaigns_cap) campaigns_cap ON campaigns_cap.sid_id = qsc.campaign_sid
		  ) qsc_t ON qsc_t.qs_campaign_sid = qsr.qs_campaign_sid
		  LEFT JOIN (
				SELECT DISTINCT companies_cap.survey_response_id, companies_cap.can_see_scores,
					   c.company_sid, c.name company_name, s.region_sid
				  FROM chain.v$company c
				  JOIN TABLE(v_companies_cap) companies_cap ON c.company_sid = companies_cap.object_id AND companies_cap.can_see_response = 1
				  LEFT JOIN supplier s ON s.company_sid = c.company_sid
		  ) c_t ON c_t.survey_response_id = qsr.survey_response_id
		  LEFT JOIN (
				SELECT audits_cap.survey_response_id, audits_cap.can_see_scores,
					   ia.internal_audit_sid, ia.label, ia.region_sid,
					   iatg.internal_audit_type_group_id ia_type_group_id, iatg.lookup_key ia_type_group_lookup_key
				  FROM internal_audit ia
				  JOIN TABLE(v_audits_cap) audits_cap ON audits_cap.object_id = ia.internal_audit_sid AND audits_cap.can_see_response = 1
				  JOIN internal_audit_type iat ON iat.internal_audit_type_id = ia.internal_audit_type_id
				  LEFT JOIN internal_audit_type_group iatg ON iatg.internal_audit_type_group_id = iat.internal_audit_type_group_id
		  ) ia_t ON ia_t.survey_response_id = qsr.survey_response_id
		  LEFT JOIN (
				SELECT flow_cap.survey_response_id, fs.flow_state_id, fs.label flow_state_label
				  FROM flow_item fi
				  JOIN TABLE(v_flow_cap) flow_cap ON flow_cap.object_id = fi.flow_item_id AND flow_cap.can_see_response = 1
				  JOIN flow_state fs ON fs.flow_state_id = fi.current_state_id
		  ) f_t ON f_t.survey_response_id = qsr.survey_response_id
		  LEFT JOIN v$region r ON r.region_sid = COALESCE(rsr.region_sid, c_t.region_sid, ia_t.region_sid)
		  LEFT JOIN csr_user u ON u.csr_user_sid = qsr.user_sid
		  LEFT JOIN csr_user sbu ON sbu.csr_user_sid = qss.submitted_by_user_sid
		  LEFT JOIN score_type st ON st.score_type_id = qs.score_type_id
		  LEFT JOIN score_threshold sth ON sth.score_threshold_id = qss.score_threshold_id
		  LEFT JOIN supplier s ON s.region_sid = r.region_sid
		 ORDER BY l.pos;

	WITH cfc AS (
		SELECT DISTINCT CAST(regexp_substr(column_name,'[0-9]+') AS NUMBER) question_id
			  FROM chain.customer_filter_column cfc
			 WHERE cfc.card_group_id = chain.filter_pkg.FILTER_TYPE_QS_RESPONSE
			   AND (cfc.column_name LIKE 'questionScore.%' OR cfc.column_name LIKE '%Question.%')
			   AND cfc.session_prefix = NVL(in_session_prefix, cfc.session_prefix)
	)
	SELECT question_id
	BULK COLLECT INTO v_question_ids
	FROM (
		SELECT question_id
		  FROM cfc
		UNION
		SELECT cq.question_id
		  FROM question q
		  JOIN cfc ON q.question_id = cfc.question_id
		  JOIN quick_survey_question cq ON q.question_id = cq.parent_id AND cq.question_version = 0
		 WHERE q.question_type = 'checkboxgroup'
	   );

	OPEN out_answers_cur FOR
		SELECT qsa.survey_response_id, qsa.question_id, qv.label question_label,
			   qsq.parent_id parent_question_id, qsa.answer, qsa.val_number, qsq.measure_sid,
			   qsa.measure_conversion_id, m.description measure_description,
			   mc.description measure_conversion_description, qsa.note, qsa.question_option_id,
			   qo.label question_option_label, qsa.region_sid, r.description region_description,
			   CASE WHEN
					(c_t.survey_response_id IS NULL AND ia_t.survey_response_id IS NULL) OR
					(c_t.can_see_scores = 1) OR
					(ia_t.can_see_scores = 1)
			   THEN qsa.score END score,
			   CASE WHEN
					(c_t.survey_response_id IS NULL AND ia_t.survey_response_id IS NULL) OR
					(c_t.can_see_scores = 1) OR
					(ia_t.can_see_scores = 1)
			   THEN qsa.max_score END max_score
		  FROM quick_survey_response qsr
		  JOIN (SELECT DISTINCT sid_id FROM TABLE(in_id_list)) l ON l.sid_id = qsr.survey_response_id
		  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
									  AND qsa.submission_id = NVL(qsr.last_submission_id, 0)
		  JOIN TABLE(v_question_ids) vq ON vq.column_value = qsa.question_id
		  JOIN quick_survey_question qsq ON qsq.question_id = qsa.question_id
									    AND qsq.question_version = qsa.question_version
		  LEFT JOIN measure m ON qsq.measure_sid = m.measure_sid
		  LEFT JOIN measure_conversion mc ON m.measure_sid = mc.measure_sid
										 AND qsa.measure_conversion_id = mc.measure_conversion_id
		  JOIN question_version qv ON qv.question_id = qsa.question_id
								  AND qv.question_version = qsa.question_version
		  LEFT JOIN question_option qo ON qo.question_id = qsa.question_id
									  AND qo.question_option_id = qsa.question_option_id
									  AND qo.question_version = qsa.question_version
		  LEFT JOIN v$region r ON r.region_sid = qsa.region_sid
		  LEFT JOIN TABLE(v_companies_cap) c_t ON c_t.survey_response_id = qsr.survey_response_id AND c_t.can_see_response = 1
		  LEFT JOIN TABLE(v_audits_cap) ia_t ON ia_t.survey_response_id = qsr.survey_response_id AND ia_t.can_see_response = 1
		 ORDER BY qv.label, qo.label;

	SELECT DISTINCT q.question_id
	  BULK COLLECT INTO v_question_ids
	  FROM question q
	  JOIN chain.customer_filter_column cfc
	    ON cfc.card_group_id = chain.filter_pkg.FILTER_TYPE_QS_RESPONSE
	   AND cfc.column_name = 'questionFileUpload.' || q.question_id
	 WHERE cfc.session_prefix = nvl(in_session_prefix, cfc.session_prefix);

	OPEN out_files_cur FOR
		SELECT qsf.survey_response_id, qsf.question_id, 
			   qsf.qs_answer_file_id, qsf.filename
		  FROM quick_survey_response qsr
		  JOIN (SELECT DISTINCT sid_id FROM TABLE(in_id_list)) l ON l.sid_id = qsr.survey_response_id
		  JOIN qs_answer_file qsf ON qsf.survey_response_id = qsr.survey_response_id
		  JOIN (SELECT DISTINCT column_value FROM TABLE(v_question_ids)) vq ON vq.column_value = qsf.question_id
		 ORDER BY qsf.filename;

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE PageFilteredIds (
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	out_id_list						OUT	security.T_ORDERED_SID_TABLE
)
AS
	v_order_by						VARCHAR2(255);
	v_order_by_id	 				NUMBER;
	v_companies_cap					T_QS_RESPONSE_PERM_TABLE;
	v_audits_cap					T_QS_RESPONSE_PERM_TABLE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.quick_survey_report_pkg.PageFilteredIds');

	IF INSTR(in_order_by, '~', 1) > 0 THEN
		chain.filter_pkg.SortExtension(
			'survey_response', 
			in_id_list,
			in_start_row,
			in_end_row,
			in_order_by,
			in_order_dir,
			out_id_list);
	ELSE
		v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
		v_order_by_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);

		IF v_order_by = 'surveyResponseId' AND in_order_dir='DESC' THEN
			SELECT security.T_ORDERED_SID_ROW(object_id, rn)
			  BULK COLLECT INTO out_id_list
				  FROM (
					SELECT x.object_id, ROWNUM rn
					  FROM (
						SELECT object_id
						  FROM (SELECT DISTINCT object_id FROM TABLE(in_id_list))
						 ORDER BY object_id DESC
						) x 
					 WHERE ROWNUM <= in_end_row
					)
				  WHERE rn > in_start_row;
		ELSIF v_order_by = 'questionScore' THEN
			v_companies_cap  := GetResponseCompanies(in_id_list, 1);
			v_audits_cap  := GetResponseAudits(in_id_list, 1);

			SELECT security.T_ORDERED_SID_ROW(survey_response_id, rn)
				BULK COLLECT INTO out_id_list
					FROM (
					SELECT x.survey_response_id, ROWNUM rn
						FROM (
						SELECT qsr.survey_response_id
							FROM v$quick_survey_response qsr
							JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = qsr.survey_response_id
							LEFT JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
														AND qsa.submission_id = qsr.submission_id
														AND qsa.question_id = v_order_by_id
							LEFT JOIN TABLE(v_companies_cap) c_t ON c_t.survey_response_id = qsr.survey_response_id
							LEFT JOIN TABLE(v_audits_cap) ia_t ON ia_t.survey_response_id = qsr.survey_response_id
							ORDER BY
								-- To avoid dyanmic SQL, do many case statements
								CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
									CASE WHEN 
										(c_t.survey_response_id IS NULL AND ia_t.survey_response_id IS NULL) OR
										(c_t.can_see_response = 1 AND c_t.can_see_scores = 1) OR
										(ia_t.can_see_response = 1 AND ia_t.can_see_scores = 1)
									THEN TO_CHAR(qsa.score, '00000000000000000000.0000000000') END
								END ASC,
								CASE WHEN in_order_dir='DESC' THEN
									CASE WHEN 
										(c_t.survey_response_id IS NULL AND ia_t.survey_response_id IS NULL) OR
										(c_t.can_see_response = 1 AND c_t.can_see_scores = 1) OR
										(ia_t.can_see_response = 1 AND ia_t.can_see_scores = 1)
									THEN TO_CHAR(qsa.score, '00000000000000000000.0000000000') END
								END DESC,
								CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN qsr.survey_response_id END ASC,
								CASE WHEN in_order_dir='DESC' THEN qsr.survey_response_id END DESC
						) x
						WHERE ROWNUM <= in_end_row
					)
					WHERE rn > in_start_row;
		ELSIF v_order_by = 'questionFileUpload' THEN
			SELECT security.T_ORDERED_SID_ROW(survey_response_id, rn)
				BULK COLLECT INTO out_id_list
					FROM (
					SELECT x.survey_response_id, ROWNUM rn
						FROM (
						SELECT qsr.survey_response_id
							FROM v$quick_survey_response qsr
							JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = qsr.survey_response_id
							LEFT JOIN (
									SELECT survey_response_id, count(*) num_files, MIN(filename) first_filename
									  FROM qs_answer_file
									 WHERE question_id = v_order_by_id
									 GROUP BY survey_response_id
							) fc ON fc.survey_response_id = qsr.survey_response_id
							ORDER BY
								-- To avoid dyanmic SQL, do many case statements
								CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN fc.num_files END DESC NULLS LAST,
								CASE WHEN in_order_dir='DESC' THEN fc.num_files END ASC NULLS FIRST,
								CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN fc.first_filename END ASC,
								CASE WHEN in_order_dir='DESC' THEN fc.first_filename END DESC,
								CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN qsr.survey_response_id END ASC,
								CASE WHEN in_order_dir='DESC' THEN qsr.survey_response_id END DESC
						) x
						WHERE ROWNUM <= in_end_row
					)
					WHERE rn > in_start_row;
		ELSIF v_order_by = 'questionComment' OR v_order_by LIKE '%Question' THEN
			SELECT security.T_ORDERED_SID_ROW(survey_response_id, rn)
				BULK COLLECT INTO out_id_list
					FROM (
					SELECT x.survey_response_id, ROWNUM rn
						FROM (
						SELECT qsr.survey_response_id
							FROM v$quick_survey_response qsr
							JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = qsr.survey_response_id
							LEFT JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
														AND qsa.submission_id = qsr.submission_id
														AND qsa.question_id = v_order_by_id
							LEFT JOIN question_option qo ON qo.question_id = qsa.question_id
														AND qo.question_option_id = qsa.question_option_id
														AND qo.question_version = qsa.question_version
							LEFT JOIN v$region r ON r.region_sid = qsa.region_sid
							ORDER BY
								-- To avoid dyanmic SQL, do many case statements
								CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
									CASE (v_order_by)
										WHEN 'noteQuestion' THEN LOWER(TO_CHAR(qsa.answer))
										WHEN 'numberQuestion' THEN TO_CHAR(qsa.val_number, '00000000000000000000.0000000000')
										WHEN 'sliderQuestion' THEN TO_CHAR(qsa.val_number, '00000000000000000000.0000000000')
										WHEN 'dateQuestion' THEN TO_CHAR(qsa.val_number, '00000000000000000000.0000000000')
										WHEN 'checkboxQuestion' THEN CASE WHEN qsa.val_number = 1 THEN 'Yes' ELSE NULL END
										WHEN 'radioQuestion' THEN LOWER(qo.label)
										WHEN 'radiorowQuestion' THEN LOWER(qo.label)
										WHEN 'regionpickerQuestion' THEN LOWER(r.description)
										WHEN 'questionComment' THEN LOWER(TO_CHAR(qsa.note))
									END
								END ASC,
								CASE WHEN in_order_dir='DESC' THEN
									CASE (v_order_by)
										WHEN 'noteQuestion' THEN LOWER(TO_CHAR(qsa.answer))
										WHEN 'numberQuestion' THEN TO_CHAR(qsa.val_number, '00000000000000000000.0000000000')
										WHEN 'sliderQuestion' THEN TO_CHAR(qsa.val_number, '00000000000000000000.0000000000')
										WHEN 'dateQuestion' THEN TO_CHAR(qsa.val_number, '00000000000000000000.0000000000')
										WHEN 'checkboxQuestion' THEN CASE WHEN qsa.val_number = 1 THEN 'Yes' ELSE NULL END
										WHEN 'radioQuestion' THEN LOWER(qo.label)
										WHEN 'radiorowQuestion' THEN LOWER(qo.label)
										WHEN 'regionpickerQuestion' THEN LOWER(r.description)
										WHEN 'questionComment' THEN LOWER(TO_CHAR(qsa.note))
									END
								END DESC,
								CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN qsr.survey_response_id END ASC,
								CASE WHEN in_order_dir='DESC' THEN qsr.survey_response_id END DESC
						) x
						WHERE ROWNUM <= in_end_row
					)
					WHERE rn > in_start_row;
		ELSE
			SELECT security.T_ORDERED_SID_ROW(survey_response_id, rn)
				BULK COLLECT INTO out_id_list
					FROM (
					SELECT x.survey_response_id, ROWNUM rn
						FROM (
						SELECT qsr.survey_response_id
							FROM v$quick_survey_response qsr
							JOIN quick_survey qs ON qs.survey_sid = qsr.survey_sid
							JOIN quick_survey_version qsv ON qsv.survey_sid = qsr.survey_sid AND qsv.survey_version = qsr.survey_version
							LEFT JOIN campaigns.campaign qsc ON qsc.campaign_sid = qsr.qs_campaign_sid
							LEFT JOIN internal_audit ia ON ia.survey_response_id = qsr.survey_response_id
							LEFT JOIN internal_audit_type iat ON iat.internal_audit_type_id = ia.internal_audit_type_id
							LEFT JOIN internal_audit_survey ias ON ias.survey_response_id = qsr.survey_response_id
							LEFT JOIN internal_audit ia2 ON ia2.internal_audit_sid = ias.internal_audit_sid
							LEFT JOIN internal_audit_type iat2 ON iat2.internal_audit_type_id = ia2.internal_audit_type_id
							LEFT JOIN region_survey_response rsr ON rsr.survey_response_id = qsr.survey_response_id
							LEFT JOIN supplier_survey_response ssr ON ssr.survey_response_id = qsr.survey_response_id
							LEFT JOIN supplier s ON s.company_sid = ssr.supplier_sid
							LEFT JOIN v$region r ON r.region_sid = COALESCE(ia.region_sid, ia2.region_sid, rsr.region_sid, s.region_sid)
							LEFT JOIN csr_user u ON u.csr_user_sid = qsr.user_sid
							LEFT JOIN csr_user sbu ON sbu.csr_user_sid = qsr.submitted_by_user_sid
							JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = qsr.survey_response_id
							ORDER BY
								-- To avoid dyanmic SQL, do many case statements
								CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
									CASE (v_order_by)
										WHEN 'surveyResponseId' THEN TO_CHAR(qsr.survey_response_id, '0000000000')
										WHEN 'guid' THEN qsr.guid
										WHEN 'surveySid' THEN TO_CHAR(qs.survey_sid, '0000000000')
										WHEN 'surveyVersion' THEN TO_CHAR(qsv.survey_version, '0000000000')
										WHEN 'isCurrentVersion' THEN TO_CHAR(CASE WHEN qsv.survey_version = qs.current_version THEN 1 ELSE 0 END, '0000000000')
										WHEN 'surveyLabel' THEN LOWER(qsv.label)
										WHEN 'regionSid' THEN TO_CHAR(r.region_sid, '0000000000')
										WHEN 'regionDescription' THEN r.description
										WHEN 'internalAuditSid' THEN
											  TO_CHAR(
											  CASE WHEN v_order_by_id IS NULL OR NVL(iat.internal_audit_type_group_id, iat2.internal_audit_type_group_id) = v_order_by_id 
												   THEN NVL(ia.internal_audit_sid, ia2.internal_audit_sid) END
											  , '0000000000') 
										WHEN 'internalAuditLabel' THEN 
											  CASE WHEN v_order_by_id IS NULL OR NVL(iat.internal_audit_type_group_id, iat2.internal_audit_type_group_id) = v_order_by_id 
												   THEN NVL(ia.label, ia2.label) END
										WHEN 'campaignSid' THEN TO_CHAR(qsc.campaign_sid, '0000000000')
										WHEN 'campaignName' THEN LOWER(qsc.name)
										WHEN 'isSubmitted' THEN TO_CHAR(CASE WHEN NVL(qsr.submission_id, 0) = 0 THEN 0 ELSE 1 END, '0000000000')
										WHEN 'submittedDtm' THEN TO_CHAR(qsr.submitted_dtm, 'YYYY-MM-DD HH24:MI:SS')
										WHEN 'submittedByUserSid' THEN TO_CHAR(sbu.csr_user_sid, '0000000000')
										WHEN 'submittedByUserName' THEN sbu.user_name
										WHEN 'overallScore' THEN CASE WHEN overall_score < 0.0 THEN ' '||TO_CHAR(ROUND(1/ overall_score, 10), '0000000000.000000') ELSE TO_CHAR(overall_score, '0000000000.000000') END
									END
								END ASC,
								CASE WHEN in_order_dir='DESC' THEN
									CASE (v_order_by)
										WHEN 'surveyResponseId' THEN TO_CHAR(qsr.survey_response_id, '0000000000')
										WHEN 'guid' THEN qsr.guid
										WHEN 'surveySid' THEN TO_CHAR(qs.survey_sid, '0000000000')
										WHEN 'surveyVersion' THEN TO_CHAR(qsv.survey_version, '0000000000')
										WHEN 'isCurrentVersion' THEN TO_CHAR(CASE WHEN qsv.survey_version = qs.current_version THEN 1 ELSE 0 END, '0000000000')
										WHEN 'surveyLabel' THEN LOWER(qsv.label)
										WHEN 'regionSid' THEN TO_CHAR(r.region_sid, '0000000000')
										WHEN 'regionDescription' THEN r.description
										WHEN 'internalAuditSid' THEN
											  TO_CHAR(
											  CASE WHEN v_order_by_id IS NULL OR NVL(iat.internal_audit_type_group_id, iat2.internal_audit_type_group_id) = v_order_by_id 
												   THEN NVL(ia.internal_audit_sid, ia2.internal_audit_sid) ELSE NULL END
											  , '0000000000') 
										WHEN 'internalAuditLabel' THEN 
											  CASE WHEN v_order_by_id IS NULL OR NVL(iat.internal_audit_type_group_id, iat2.internal_audit_type_group_id) = v_order_by_id 
												   THEN NVL(ia.label, ia2.label) ELSE NULL END
										WHEN 'campaignSid' THEN TO_CHAR(qsc.campaign_sid, '0000000000')
										WHEN 'campaignName' THEN LOWER(qsc.name)
										WHEN 'isSubmitted' THEN TO_CHAR(CASE WHEN NVL(qsr.submission_id, 0) = 0 THEN 0 ELSE 1 END, '0000000000')
										WHEN 'submittedDtm' THEN TO_CHAR(qsr.submitted_dtm, 'YYYY-MM-DD HH24:MI:SS')
										WHEN 'submittedByUserSid' THEN TO_CHAR(sbu.csr_user_sid, '0000000000')
										WHEN 'submittedByUserName' THEN sbu.user_name
										WHEN 'overallScore' THEN CASE WHEN overall_score < 0.0 THEN ' '||TO_CHAR(ROUND(1/ overall_score, 10), '0000000000.000000') ELSE TO_CHAR(overall_score, '0000000000.000000') END
									END
								END DESC,
								CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN qsr.survey_response_id END ASC,
								CASE WHEN in_order_dir='DESC' THEN qsr.survey_response_id END DESC
						) x
						WHERE ROWNUM <= in_end_row
					)
					WHERE rn > in_start_row;
		END IF;
	END IF;

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE INTERNAL_PopGridExtTempTable(
	in_id_page						IN security.T_ORDERED_SID_TABLE
)
AS 
	v_enabled_extensions			SYS_REFCURSOR;
	v_name							chain.grid_extension.record_name%TYPE;
	v_extension_id					chain.grid_extension.extension_card_group_id%TYPE;
BEGIN
	DELETE FROM chain.temp_grid_extension_map;

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_QS_RESPONSE, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		IF v_extension_id = chain.filter_pkg.FILTER_TYPE_COMPANIES THEN
			INTERNAL_ResponseSidsToCoSids(in_id_page);
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Quick Survey Response -> '||v_name);
		END IF;
	END LOOP;
END;

PROCEDURE GetList(
	in_search						IN	VARCHAR2,
	in_group_key					IN	chain.saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
	in_parent_id					IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	in_bounds_north					IN	NUMBER,
	in_bounds_east					IN	NUMBER,
	in_bounds_south					IN	NUMBER,
	in_bounds_west					IN	NUMBER,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_aggregation_type				IN	NUMBER,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_col_type				IN	NUMBER,
	in_date_col_type				IN	NUMBER,
	in_id_list_populated			IN	NUMBER DEFAULT 0,
	in_session_prefix				IN	chain.customer_filter_column.session_prefix%TYPE DEFAULT NULL,
	out_total_rows					OUT	NUMBER,
	out_responses_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_answers_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_files_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_geo_filtered_list				chain.T_FILTERED_OBJECT_TABLE;
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_companies_cap					T_QS_RESPONSE_PERM_TABLE;
	v_audits_cap					T_QS_RESPONSE_PERM_TABLE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.quick_survey_report_pkg.GetList', in_compound_filter_id);

	GetFilteredIds(
		in_search				=> in_search,
		in_group_key			=> in_group_key,
		in_pre_filter_sid		=> in_pre_filter_sid,
		in_parent_type			=> in_parent_type,
		in_parent_id			=> in_parent_id,
		in_compound_filter_id	=> in_compound_filter_id,
		in_region_sids			=> v_region_sids,
		in_start_dtm			=> in_start_dtm,
		in_end_dtm				=> in_end_dtm,
		in_region_col_type		=> in_region_col_type,
		in_date_col_type		=> in_date_col_type,
		out_id_list				=> v_id_list
	);

	ApplyBreadcrumb(v_id_list, in_breadcrumb, in_aggregation_type, v_id_list);

	-- Filter by map bounds if appropriate
	IF in_bounds_north IS NOT NULL AND in_bounds_east IS NOT NULL AND in_bounds_south IS NOT NULL AND in_bounds_west IS NOT NULL THEN
		v_companies_cap := GetResponseCompanies(v_id_list);
		v_audits_cap := GetResponseAudits(v_id_list);

		SELECT chain.T_FILTERED_OBJECT_ROW(survey_response_id, NULL, NULL)
		  BULK COLLECT INTO v_geo_filtered_list
		  FROM (
				SELECT qsr.survey_response_id,
					   -- We won't get a mixture here thanks to CK_QSS_GEOLOCATION
					   NVL(qsr.geo_latitude, r.geo_latitude) latitude, 
					   NVL(qsr.geo_longitude, r.geo_longitude) longitude,
					   qsr.geo_h_accuracy accuracy
				  FROM v$quick_survey_response qsr
				  JOIN (SELECT DISTINCT object_id FROM TABLE(v_id_list)) t ON qsr.survey_response_id = t.object_id
				  LEFT JOIN region_survey_response rsr ON rsr.survey_response_id = qsr.survey_response_id
				  LEFT JOIN (
						SELECT companies_cap.survey_response_id, companies_cap.can_see_response, s.region_sid
						  FROM chain.v$company c
						  JOIN TABLE(v_companies_cap) companies_cap ON c.company_sid = companies_cap.object_id
						  LEFT JOIN supplier s ON s.company_sid = c.company_sid
				  ) c_t ON c_t.survey_response_id = qsr.survey_response_id
				  LEFT JOIN (
						SELECT audits_cap.survey_response_id, ia.region_sid
						  FROM internal_audit ia
						  JOIN TABLE(v_audits_cap) audits_cap ON ia.internal_audit_sid = audits_cap.object_id
				  ) ia_t ON ia_t.survey_response_id = qsr.survey_response_id
				  LEFT JOIN (
						SELECT DISTINCT app_sid, NVL(link_to_region_sid, region_sid) region_sid
							FROM region
							START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') 
							AND region_sid IN (SELECT region_sid FROM region_start_point WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID'))
						CONNECT BY PRIOR app_sid = app_sid 
							AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
				  ) rt ON COALESCE(rsr.region_sid, c_t.region_sid, ia_t.region_sid) = rt.region_sid
				  LEFT JOIN v$region r ON r.region_sid = rt.region_sid
			 )
		 WHERE longitude-in_bounds_west-360*FLOOR((longitude-in_bounds_west)/360) BETWEEN 0 AND in_bounds_east-in_bounds_west
		   AND latitude BETWEEN in_bounds_south AND in_bounds_north;

		v_id_list := v_geo_filtered_list;
	END IF;

	-- Get the total number of rows (to work out number of pages)
	SELECT COUNT(DISTINCT object_id)
	  INTO out_total_rows
	  FROM TABLE(v_id_list);

	PageFilteredIds(v_id_list, in_start_row, in_end_row, in_order_by, in_order_dir, v_id_page);
	
	INTERNAL_PopGridExtTempTable(v_id_page);

	-- Return a page of results
	CollectSearchResults(v_id_page, in_session_prefix, out_responses_cur, out_answers_cur, out_files_cur);

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetAggregateDetails (
	in_aggregation_types			IN	security.T_ORDERED_SID_TABLE,
	in_id_col_sid					IN	security_pkg.T_SID_ID,
	out_agg_types					OUT	chain.T_FILTER_AGG_TYPE_TABLE,
	out_aggregate_thresholds		OUT	chain.T_FILTER_AGG_TYPE_THRES_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTER_AGG_TYPE_ROW(chain.filter_pkg.FILTER_TYPE_QS_RESPONSE, a.aggregate_type_id, a.description, null, null, 0, null, null, null)
	  BULK COLLECT INTO out_agg_types
	  FROM TABLE(in_aggregation_types) sat
	  JOIN (
		SELECT at.aggregate_type_id, at.description
		  FROM chain.aggregate_type at
		 WHERE card_group_id = chain.filter_pkg.FILTER_TYPE_QS_RESPONSE
		 UNION
		SELECT cat.customer_aggregate_type_id, 
			   CASE cfiat.analytic_function
					WHEN chain.filter_pkg.AFUNC_MIN THEN 'Smallest '
					WHEN chain.filter_pkg.AFUNC_MAX THEN 'Largest '
					WHEN chain.filter_pkg.AFUNC_AVERAGE THEN 'Average '
					WHEN chain.filter_pkg.AFUNC_SUM THEN 'Total '
				END || cfi.label
		  FROM chain.customer_aggregate_type cat
		  JOIN chain.cust_filt_item_agg_type cfiat ON cfiat.cust_filt_item_agg_type_id = cat.cust_filt_item_agg_type_id
		  JOIN chain.customer_filter_item cfi ON cfi.customer_filter_item_id = cfiat.customer_filter_item_id
		 WHERE cat.card_group_id = chain.filter_pkg.FILTER_TYPE_QS_RESPONSE 
		) a ON sat.sid_id = a.aggregate_type_id
	 ORDER BY sat.pos;
END;

PROCEDURE GetReportData(
	in_search						IN	VARCHAR2 DEFAULT NULL,
	in_group_key					IN  chain.saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
	in_parent_id					IN	NUMBER DEFAULT NULL,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE DEFAULT NULL,
	in_grp_by_compound_filter_id	IN	chain.compound_filter.compound_filter_id%TYPE DEFAULT NULL,
	in_aggregation_types			IN	security.T_SID_TABLE DEFAULT NULL,
	in_show_totals					IN	NUMBER DEFAULT NULL,
	in_breadcrumb					IN	security.T_SID_TABLE DEFAULT NULL,
	in_max_group_by					IN	NUMBER DEFAULT NULL,
	in_region_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_start_dtm					IN	DATE DEFAULT NULL,
	in_end_dtm						IN	DATE DEFAULT NULL,
	in_region_col_type				IN	NUMBER DEFAULT NULL,
	in_date_col_type				IN	NUMBER DEFAULT NULL,
	in_id_list_populated			IN  NUMBER DEFAULT NULL,
	out_field_cur					OUT	SYS_REFCURSOR,
	out_data_cur					OUT	SYS_REFCURSOR,
	out_extra_series_cur			OUT SYS_REFCURSOR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_top_n_values					security.T_ORDERED_SID_TABLE;
	v_aggregation_type				NUMBER := AGG_TYPE_COUNT;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.quick_survey_report_pkg.GetReportData', in_compound_filter_id);

	GetFilteredIds(
		in_search				=> in_search,
		in_group_key			=> in_group_key,
		in_pre_filter_sid		=> in_pre_filter_sid,
		in_parent_type			=> in_parent_type,
		in_parent_id			=> in_parent_id,
		in_compound_filter_id	=> in_compound_filter_id,
		in_region_sids			=> in_region_sids,
		in_start_dtm			=> in_start_dtm,
		in_end_dtm				=> in_end_dtm,
		in_region_col_type		=> in_region_col_type,
		in_date_col_type		=> in_date_col_type,
		out_id_list				=> v_id_list
	);

	IF in_grp_by_compound_filter_id IS NOT NULL THEN
		RunCompoundFilter(in_grp_by_compound_filter_id, 1, in_max_group_by, v_id_list, v_id_list);
	END IF;

	GetFilterObjectData(in_aggregation_types, v_id_list);

	IF in_aggregation_types.COUNT > 0 THEN
		v_aggregation_type := in_aggregation_types(1);
	END IF;

	v_top_n_values := chain.filter_pkg.FindTopN(in_grp_by_compound_filter_id, v_aggregation_type, v_id_list, in_breadcrumb, in_max_group_by);

	chain.filter_pkg.GetAggregateData(chain.filter_pkg.FILTER_TYPE_QS_RESPONSE, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);

	chain.filter_pkg.GetEmptyExtraSeriesCur(out_extra_series_cur);

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetAlertData (
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_flow_cap						T_QS_RESPONSE_PERM_TABLE := GetResponseFlowItems(in_id_list);
BEGIN
	-- No security - should only be called by filter_pkg with an already security-trimmed list of ids

	OPEN out_cur FOR
		SELECT t.object_id, qsr.survey_response_id,
			   qs.survey_sid, qsv.label survey_label,
			   wr.path || '/' || qsr.survey_response_id survey_response_url,
			   qsr.submitted_dtm, sbu.full_name submitted_by_user_name,
			   qsr.overall_score, sth.description score_threshold_description,
			   fs.label flow_state_label
		  FROM v$quick_survey_response qsr
		  JOIN TABLE(in_id_list) t ON t.object_id = qsr.survey_response_id
		  JOIN quick_survey qs ON qs.survey_sid = qsr.survey_sid
		  JOIN quick_survey_version qsv ON qsv.survey_sid = qsr.survey_sid AND qsv.survey_version = qsr.survey_version
		  JOIN security.web_resource wr ON wr.sid_id = qs.survey_sid
		  LEFT JOIN csr_user sbu ON sbu.csr_user_sid = qsr.submitted_by_user_sid
		  LEFT JOIN score_type st ON st.score_type_id = qs.score_type_id
		  LEFT JOIN score_threshold sth ON sth.score_threshold_id = qsr.score_threshold_id
		  LEFT JOIN TABLE(v_flow_cap) flow_cap ON flow_cap.survey_response_id = qsr.survey_response_id AND flow_cap.can_see_response = 1
		  LEFT JOIN flow_item fi ON fi.survey_response_id = flow_cap.object_id
		  LEFT JOIN flow_state fs ON fs.flow_state_id = fi.current_state_id;
END;

PROCEDURE GetExport(
	in_search						IN	VARCHAR2,
	in_group_key					IN	chain.saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
	in_parent_id					IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_aggregation_type				IN	NUMBER,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_col_type				IN	NUMBER,
	in_date_col_type				IN	NUMBER,
	out_responses_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_answers_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_files_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
BEGIN

	GetFilteredIds(
		in_search				=> in_search,
		in_group_key			=> in_group_key,
		in_pre_filter_sid		=> in_pre_filter_sid,
		in_parent_type			=> in_parent_type,
		in_parent_id			=> in_parent_id,
		in_compound_filter_id	=> in_compound_filter_id,
		in_region_sids			=> v_region_sids,
		in_start_dtm			=> in_start_dtm,
		in_end_dtm				=> in_end_dtm,
		in_region_col_type		=> in_region_col_type,
		in_date_col_type		=> in_date_col_type,
		out_id_list				=> v_id_list
	);

	ApplyBreadcrumb(v_id_list, in_breadcrumb, in_aggregation_type, v_id_list);

	SELECT security.T_ORDERED_SID_ROW(object_id, object_id)
	  BULK COLLECT INTO v_id_page
	  FROM (
		SELECT DISTINCT object_id
		  FROM TABLE(v_id_list)
	  );

	INTERNAL_PopGridExtTempTable(v_id_page);

	CollectSearchResults(
		in_id_list					=> v_id_page,
		out_response_cur 			=> out_responses_cur,
		out_answers_cur				=> out_answers_cur,
		out_files_cur				=> out_files_cur
	);
END;

PROCEDURE GetListAsExtension(
	in_compound_filter_id			IN chain.compound_filter.compound_filter_id%TYPE,
	out_responses_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_answers_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_files_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.quick_survey_report_pkg.GetListAsExtension', in_compound_filter_id);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
			SELECT linked_id
			  FROM chain.temp_grid_extension_map
			 WHERE linked_type = chain.filter_pkg.FILTER_TYPE_QS_RESPONSE
		);
	
	--security trim the list of ids
	GetFilteredIds (
		in_compound_filter_id	=> 0, 
		in_id_list				=> v_id_list,
		out_id_list				=> v_id_list
	);

	SELECT security.T_ORDERED_SID_ROW(object_id, rownum)
	  BULK COLLECT INTO v_id_page
	  FROM (
		SELECT DISTINCT object_id
		  FROM TABLE(v_id_list)
	);

	CollectSearchResults(
		in_id_list					=> v_id_page,
		out_response_cur 			=> out_responses_cur,
		out_answers_cur				=> out_answers_cur,
		out_files_cur				=> out_files_cur
	);

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

/********************************************/
/*		Filter field units					*/
/********************************************/

/*  Each filter unit must:
 *   o  Filter the list of in_ids into the out_ids based on the user's selected values for the given in_filter_field_id
 *   o  Pre-populate all possible values if in_show_all = 1
 *   o  Preserve existing duplicate issue IDs passed in (these are likely to have different group by values caused by overlapping values that need to be represented in charts)
 *  
 *  It's OK to return duplicate issue IDs if filter field values overlap. These duplicates are discounted for issue lists
 *  but required for charts to work correctly. Each filter field unit must preserve existing duplicate issue ids that are
 *  passed in.
 */

PROCEDURE FilterSurveySid (
	in_filter_id 					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id 				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all 					IN	NUMBER,
	in_ids 							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids 						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_surveys_sid					security.security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'wwwroot/surveys');
	v_surveys_cap					security.T_SO_DESCENDANTS_TABLE := security.securableobject_pkg.GetDescendantsWithPermAsTable(SYS_CONTEXT('SECURITY','ACT'), v_surveys_sid, security_pkg.PERMISSION_READ);
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, n.survey_sid, n.label
		  FROM (
			SELECT qs.survey_sid, qsv.label
			  FROM quick_survey qs
			  JOIN quick_survey_version qsv ON qsv.survey_sid = qs.survey_sid AND qsv.survey_version = qs.current_version
			  JOIN TABLE(v_surveys_cap) cap ON cap.sid_id = qs.survey_sid
			  JOIN v$quick_survey_response qsr ON qsr.survey_sid = qs.survey_sid
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON qsr.survey_response_id = t.object_id
			 GROUP BY qs.survey_sid, qsv.label
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = n.survey_sid
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(qsr.survey_response_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$quick_survey_response qsr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON qsr.survey_response_id = t.object_id
	  JOIN chain.filter_value fv ON fv.num_value = qsr.survey_sid
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterSurveyVersion (
	in_filter_id 					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id 				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all 					IN	NUMBER,
	in_ids 							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids 						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, min_num_val, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, chain.filter_pkg.NUMBER_EQUAL, n.survey_version, n.survey_version
		  FROM (
			SELECT qsr.survey_version
			  FROM v$quick_survey_response qsr
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON qsr.survey_response_id = t.object_id
			 GROUP BY qsr.survey_version
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = chain.filter_pkg.NUMBER_EQUAL
			   AND fv.min_num_val = n.survey_version
		 );
	END IF;
	
	chain.filter_pkg.SortNumberValues(in_filter_field_id);	

	SELECT chain.T_FILTERED_OBJECT_ROW(qsr.survey_response_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$quick_survey_response qsr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON qsr.survey_response_id = t.object_id
	  CROSS JOIN chain.filter_value fv
	 WHERE fv.filter_field_id = in_filter_field_id
	   AND chain.filter_pkg.CheckNumberRange(qsr.survey_version, fv.num_value, fv.min_num_val, fv.max_num_val) = 1;
END;

PROCEDURE FilterIsCurrentVersion (
	in_filter_id 					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id 				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all 					IN	NUMBER,
	in_ids 							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids 						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, o.is_current, o.description
		  FROM (
			SELECT 1 is_current, 'Current' description FROM dual
			UNION ALL SELECT 0, 'Not current' FROM dual
		  ) o
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = o.is_current
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(qsr.survey_response_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$quick_survey_response qsr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON qsr.survey_response_id = t.object_id
	  JOIN quick_survey qs ON qs.survey_sid = qsr.survey_sid
	  JOIN chain.filter_value fv ON (
		(fv.num_value = 1 AND qsr.survey_version = qs.current_version) OR
		(fv.num_value = 0 AND qsr.survey_version != qs.current_version)
	 )
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterPublishedDtm (
	in_filter_id 					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id 				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all 					IN	NUMBER,
	in_ids 							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids 						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;
BEGIN
	IF in_show_all = 1 THEN
		SELECT MIN(qsv.published_dtm), MAX(qsv.published_dtm)
		  INTO v_min_date, v_max_date
		  FROM v$quick_survey_response qsr
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON qsr.survey_response_id = t.object_id
		  JOIN quick_survey_version qsv ON qsv.survey_sid = qsr.survey_sid AND qsv.survey_version = qsr.survey_version
		 WHERE qsr.submitted_dtm IS NOT NULL;
		
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
	END IF;

	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(qsr.survey_response_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$quick_survey_response qsr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON qsr.survey_response_id = t.object_id
	  JOIN quick_survey_version qsv ON qsv.survey_sid = qsr.survey_sid AND qsv.survey_version = qsr.survey_version
	  JOIN chain.tt_filter_date_range dr 
	    ON qsv.published_dtm >= NVL(dr.start_dtm, qsv.published_dtm) 
	   AND (dr.end_dtm IS NULL OR qsv.published_dtm < dr.end_dtm)
	 WHERE qsv.published_dtm IS NOT NULL;
END;

PROCEDURE FilterRegionSid (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_response_regions				T_QS_RESPONSE_PERM_TABLE := GetResponseRegions(in_ids);
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, region_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, n.region_sid
		  FROM (
			SELECT rr.object_id region_sid
			  FROM TABLE(v_response_regions) rr
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON rr.survey_response_id = t.object_id
			 GROUP BY rr.object_id
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.region_sid = n.region_sid
		 );
		
		-- if show_all is on, we don't want to aggregate (otherwise the data is a mess)
		SELECT chain.T_FILTERED_OBJECT_ROW(survey_response_id, in_group_by_index, ia.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT rr.survey_response_id, fv.filter_value_id
			  FROM TABLE(v_response_regions) rr
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON rr.survey_response_id = t.object_id
			  JOIN chain.filter_value fv ON rr.object_id = fv.region_sid 
			 WHERE fv.filter_field_id = in_filter_field_id
		) ia;
	ELSE
		-- if show_all is off, users have specified the regions they want, they'll
		-- expect to get region aggregation
		SELECT chain.T_FILTERED_OBJECT_ROW(rr.survey_response_id, in_group_by_index, r.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM TABLE(v_response_regions) rr
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON rr.survey_response_id = t.object_id
		  JOIN (
				SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid, connect_by_root ff.filter_value_id filter_value_id
				  FROM region r
				  JOIN chain.filter_value ff ON ff.filter_field_id = in_filter_field_id
				 START WITH r.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND r.region_sid = ff.region_sid
			   CONNECT BY PRIOR r.app_sid = r.app_sid
				   AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
				   AND PRIOR ff.filter_value_id = ff.filter_value_id
			 ) r ON rr.object_id = r.region_sid;
	END IF;	
END;

PROCEDURE FilterAudits (
	in_filter_id 					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id 				IN	NUMBER,
	in_filter_field_name			IN	chain.filter_field.name%TYPE, 
	in_group_by_index				IN	NUMBER,
	in_show_all 					IN	NUMBER,
	in_ids 							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids 						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			chain.filter.compound_filter_id%TYPE;
	v_group_key						internal_audit_type_group.lookup_key%TYPE;
	v_audits_cap					T_QS_RESPONSE_PERM_TABLE;
	v_audit_sids					chain.T_FILTERED_OBJECT_TABLE;
BEGIN
	v_compound_filter_id := chain.filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);

	IF LOWER(in_filter_field_name) = 'auditfilter' THEN
		v_group_key := NULL;
	ELSE
		SELECT lookup_key
		  INTO v_group_key
		  FROM internal_audit_type_group
		 WHERE 'auditfilter.' || LOWER(lookup_key) = LOWER(in_filter_field_name);
	END IF;
	
	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		v_audits_cap := GetResponseAudits(in_ids);

		SELECT chain.T_FILTERED_OBJECT_ROW(object_id, NULL, NULL)
		  BULK COLLECT INTO v_audit_sids
		  FROM TABLE(v_audits_cap)
		 WHERE can_see_response = 1;
		  
		audit_report_pkg.GetFilteredIds(
			in_search						=> NULL,
			in_group_key					=> v_group_key,
			in_compound_filter_id			=> v_compound_filter_id,
			in_id_list						=> v_audit_sids,
			out_id_list						=> v_audit_sids
		);

		SELECT chain.T_FILTERED_OBJECT_ROW(qsr.survey_response_id, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM v$quick_survey_response qsr
		  JOIN TABLE (in_ids) t ON t.object_id = qsr.survey_response_id
		  JOIN TABLE (v_audits_cap) ac ON ac.survey_response_id = t.object_id
		  JOIN TABLE (v_audit_sids) a ON a.object_id = ac.object_id;
	END IF;
END;

PROCEDURE FilterCampaignSid (
	in_filter_id 					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id 				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all 					IN	NUMBER,
	in_ids 							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids 						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_campaigns_sid					security.security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Campaigns');
	v_campaigns_cap					security.T_SO_DESCENDANTS_TABLE := security.securableobject_pkg.GetDescendantsWithPermAsTable(SYS_CONTEXT('SECURITY','ACT'), v_campaigns_sid, security_pkg.PERMISSION_READ);
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, n.qs_campaign_sid, n.name
		  FROM (
			SELECT qsc.campaign_sid qs_campaign_sid, qsc.name
			  FROM campaigns.campaign qsc
			  JOIN TABLE(v_campaigns_cap) cap ON cap.sid_id = qsc.campaign_sid
			  JOIN v$quick_survey_response qsr ON qsc.campaign_sid = qsr.qs_campaign_sid
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON qsr.survey_response_id = t.object_id
			 GROUP BY qsc.campaign_sid, qsc.name
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = n.qs_campaign_sid
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(qsr.survey_response_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$quick_survey_response qsr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON qsr.survey_response_id = t.object_id
	  JOIN chain.filter_value fv ON fv.num_value = qsr.qs_campaign_sid
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterFlowStateId (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_flow_count					NUMBER;
	v_flow_cap						T_QS_RESPONSE_PERM_TABLE := GetResponseFlowItems(in_ids);
BEGIN
	IF in_show_all = 1 THEN
		SELECT COUNT(DISTINCT flow_sid)
		  INTO v_flow_count
		  FROM campaigns.campaign;
	
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, flow_state_id, label
		  FROM (
			SELECT DISTINCT fs.flow_state_id, CASE WHEN v_flow_count = 1 THEN fs.label ELSE f.label||' - '||fs.label END label
			  FROM campaigns.campaign qsc
			  JOIN flow_state fs ON qsc.flow_sid = fs.flow_sid
			  JOIN flow f ON qsc.flow_sid = f.flow_sid
			 WHERE fs.is_deleted = 0
			   AND f.flow_alert_class = 'campaign'
			   AND NOT EXISTS ( -- exclude any we may have already
				SELECT *
				  FROM chain.filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = fs.flow_state_id
			 )
		);
	END IF;
	
	chain.filter_pkg.SortFlowStateValues(in_filter_field_id);
	chain.filter_pkg.SetFlowStateColours(in_filter_field_id);

	SELECT chain.T_FILTERED_OBJECT_ROW(qsr.survey_response_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$quick_survey_response qsr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON qsr.survey_response_id = t.object_id
	  JOIN TABLE(v_flow_cap) flow_cap ON flow_cap.survey_response_id = qsr.survey_response_id AND flow_cap.can_see_response = 1
	  JOIN flow_item fi ON fi.flow_item_id = flow_cap.object_id
	  JOIN chain.filter_value fv ON fi.current_state_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;		
END;

PROCEDURE FilterIsSubmitted (
	in_filter_id 					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id 				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all 					IN	NUMBER,
	in_ids 							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids 						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, o.is_submitted, o.description
		  FROM (
			SELECT 1 is_submitted, 'Submitted' description FROM dual
			UNION ALL SELECT 0, 'Not submitted' FROM dual
		  ) o
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = o.is_submitted
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(qsr.survey_response_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$quick_survey_response qsr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON qsr.survey_response_id = t.object_id
	  JOIN quick_survey qs ON qs.survey_sid = qsr.survey_sid
	  JOIN chain.filter_value fv ON (
		(fv.num_value = 1 AND NVL(qsr.submission_id, 0) != 0) OR
		(fv.num_value = 0 AND NVL(qsr.submission_id, 0) = 0)
	 )
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterSubmittedDtm (
	in_filter_id 					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id 				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all 					IN	NUMBER,
	in_ids 							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids 						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;
BEGIN
	IF in_show_all = 1 THEN
		SELECT MIN(qsr.submitted_dtm), MAX(qsr.submitted_dtm)
		  INTO v_min_date, v_max_date
		  FROM v$quick_survey_response qsr
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON qsr.survey_response_id = t.object_id
		 WHERE qsr.submitted_dtm IS NOT NULL;
		
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
	END IF;

	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(qsr.survey_response_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$quick_survey_response qsr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON qsr.survey_response_id = t.object_id
	  JOIN chain.tt_filter_date_range dr 
	    ON qsr.submitted_dtm >= NVL(dr.start_dtm, qsr.submitted_dtm) 
	   AND (dr.end_dtm IS NULL OR qsr.submitted_dtm < dr.end_dtm)
	 WHERE qsr.submitted_dtm IS NOT NULL;
END;

PROCEDURE FilterSubmittedByUserSid (
	in_filter_id 					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id 				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all 					IN	NUMBER,
	in_ids 							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids 						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, user_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, n.submitted_by_user_sid
		  FROM (
			SELECT qsr.submitted_by_user_sid
			  FROM v$quick_survey_response qsr
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON qsr.survey_response_id = t.object_id
			 GROUP BY qsr.submitted_by_user_sid
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.user_sid = n.submitted_by_user_sid
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(qsr.survey_response_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$quick_survey_response qsr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON qsr.survey_response_id = t.object_id
	  JOIN chain.filter_value fv 
	    ON fv.user_sid = qsr.submitted_by_user_sid
		OR (in_show_all = 0 AND fv.user_sid = chain.filter_pkg.USER_ME AND qsr.submitted_by_user_sid = SYS_CONTEXT('SECURITY', 'SID'))
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterLatestSubmission (
	in_filter_id 					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id 				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all 					IN	NUMBER,
	in_ids 							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids 						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_response_regions				T_QS_RESPONSE_PERM_TABLE := GetResponseRegions(NULL);
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, o.is_submitted, o.description
		  FROM (
			SELECT 1 is_submitted, 'Latest submission' description FROM dual
			UNION ALL SELECT 0, 'Earlier submissions' FROM dual
			UNION ALL SELECT -1, 'Other' FROM dual
		  ) o
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = o.is_submitted
		 );
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
	  LEFT JOIN (
			SELECT survey_response_id, submitted_dtm,
				   FIRST_VALUE(survey_response_id) OVER (PARTITION BY survey_sid, region_sid ORDER BY submitted_dtm DESC, submission_id DESC NULLS LAST) latest_response_id
			  FROM (
					SELECT qsr.survey_response_id, qsr.survey_sid, qsr.submitted_dtm, qsr.submission_id, rr.object_id region_sid
					  FROM csr.v$quick_survey_response qsr
					  JOIN TABLE(v_response_regions) rr ON rr.survey_response_id = qsr.survey_response_id
					 WHERE qsr.submitted_dtm IS NOT NULL
					   AND rr.object_id IS NOT NULL
			  ) rr
	  ) r ON r.survey_response_id = t.object_id
	  JOIN chain.filter_value fv ON (
		(fv.num_value = 1 AND r.survey_response_id IS NOT NULL AND r.survey_response_id = r.latest_response_id) OR
		(fv.num_value = 0 AND r.survey_response_id IS NOT NULL AND r.survey_response_id != r.latest_response_id) OR
		(fv.num_value = -1 AND r.survey_response_id IS NULL)
	 )
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterScore (
	in_filter_id 					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id 				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all 					IN	NUMBER,
	in_ids 							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids 						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_companies_cap					T_QS_RESPONSE_PERM_TABLE := GetResponseCompanies(in_ids, 1);
	v_audits_cap					T_QS_RESPONSE_PERM_TABLE := GetResponseAudits(in_ids, 1);
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, min_num_val, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, chain.filter_pkg.NUMBER_EQUAL, n.overall_score, n.overall_score
		  FROM (
			SELECT qsr.overall_score
			  FROM v$quick_survey_response qsr
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON qsr.survey_response_id = t.object_id
			  LEFT JOIN TABLE(v_companies_cap) c_t ON c_t.survey_response_id = qsr.survey_response_id
			  LEFT JOIN TABLE(v_audits_cap) ia_t ON ia_t.survey_response_id = qsr.survey_response_id
			 WHERE qsr.overall_score IS NOT NULL
			   AND (c_t.survey_response_id IS NULL OR c_t.can_see_scores = 1)
			   AND (ia_t.survey_response_id IS NULL OR ia_t.can_see_scores = 1)
			 GROUP BY qsr.overall_score
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = chain.filter_pkg.NUMBER_EQUAL
			   AND fv.min_num_val = n.overall_score
		 );
	END IF;
	
	chain.filter_pkg.SortNumberValues(in_filter_field_id);	

	SELECT chain.T_FILTERED_OBJECT_ROW(qsr.survey_response_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$quick_survey_response qsr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON qsr.survey_response_id = t.object_id
	  LEFT JOIN TABLE(v_companies_cap) c_t ON c_t.survey_response_id = qsr.survey_response_id
	  LEFT JOIN TABLE(v_audits_cap) ia_t ON ia_t.survey_response_id = qsr.survey_response_id
	  CROSS JOIN chain.filter_value fv
	 WHERE fv.filter_field_id = in_filter_field_id
	   AND (c_t.survey_response_id IS NULL OR c_t.can_see_scores = 1)
	   AND (ia_t.survey_response_id IS NULL OR ia_t.can_see_scores = 1)
	   AND chain.filter_pkg.CheckNumberRange(qsr.overall_score, fv.num_value, fv.min_num_val, fv.max_num_val) = 1;
END;

PROCEDURE FilterScoreThresholdId (
	in_filter_id 					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id 				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all 					IN	NUMBER,
	in_ids 							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids 						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_companies_cap					T_QS_RESPONSE_PERM_TABLE := GetResponseCompanies(in_ids, 1);
	v_audits_cap					T_QS_RESPONSE_PERM_TABLE := GetResponseAudits(in_ids, 1);
	v_st_id_t	security.T_SID_TABLE;
	v_st_count	NUMBER;
BEGIN
	IF in_show_all = 1 THEN
		SELECT score_type_id
		  BULK COLLECT INTO v_st_id_t
		  FROM score_type st
		 WHERE EXISTS(
			SELECT 1 
			  FROM quick_survey qs
			 WHERE qs.score_type_id = st.score_type_id
		 );

		SELECT COUNT(*)
		  INTO v_st_count
		  FROM TABLE(v_st_id_t);
	
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, st.score_threshold_id, 
			CASE WHEN v_st_count > 1 THEN st.description || ' (' || s.label || ')' ELSE st.description END description
		  FROM score_type s
		  JOIN score_threshold st ON st.app_sid = s.app_sid AND st.score_type_id = s.score_type_id 
		  JOIN TABLE (v_st_id_t) T ON T.column_value = st.score_type_id
		 WHERE st.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND NOT EXISTS (
			SELECT 1
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = st.score_threshold_id
		 );
	END IF;
	
	chain.filter_pkg.SetThresholdColours(in_filter_field_id);

	chain.filter_pkg.SortScoreThresholdValues(in_filter_field_id);

	SELECT chain.T_FILTERED_OBJECT_ROW(qsr.survey_response_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$quick_survey_response qsr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON qsr.survey_response_id = t.object_id
	  LEFT JOIN TABLE(v_companies_cap) c_t ON c_t.survey_response_id = qsr.survey_response_id
	  LEFT JOIN TABLE(v_audits_cap) ia_t ON ia_t.survey_response_id = qsr.survey_response_id
	  JOIN chain.filter_value fv ON qsr.score_threshold_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id
	   AND (c_t.survey_response_id IS NULL OR c_t.can_see_scores = 1)
	   AND (ia_t.survey_response_id IS NULL OR ia_t.can_see_scores = 1);	 
END;

PROCEDURE FilterNoteQuestion (
	in_filter_id				IN chain.filter.filter_id%TYPE,
	in_filter_field_id			IN NUMBER,
	in_filter_field_name		IN chain.filter_field.name%TYPE,
	in_group_by_index			IN NUMBER,
	in_show_all					IN NUMBER,
	in_ids						IN chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_question_id				question.question_id%TYPE := CAST(regexp_substr(in_filter_field_name, '[0-9]+') AS NUMBER);
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, str_value)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, a.answer
		  FROM (
			SELECT SUBSTR(TO_CHAR(qsa.answer), 1, 255) answer
			  FROM v$quick_survey_response qsr
			  JOIN TABLE(in_ids) t ON t.object_id = qsr.survey_response_id
			  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
										  AND qsa.submission_id = qsr.submission_id
										  AND qsa.question_id = v_question_id
			 WHERE qsa.answer IS NOT NULL
			 GROUP BY SUBSTR(TO_CHAR(qsa.answer), 1, 255)
		  ) a
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.str_value = a.answer
		 );
		 
		-- If we're aggregating, don't double-count rows that are substrings
		SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM v$quick_survey_response qsr
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON t.object_id = qsr.survey_response_id
		  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
									  AND qsa.submission_id = qsr.submission_id
									  AND qsa.question_id = v_question_id
		  JOIN chain.filter_value fv ON SUBSTR(TO_CHAR(qsa.answer), 1, 255) = fv.str_value
		 WHERE fv.filter_field_id = in_filter_field_id;
	ELSE
		SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM v$quick_survey_response qsr
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON t.object_id = qsr.survey_response_id
		  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
									  AND qsa.submission_id = qsr.submission_id
									  AND qsa.question_id = v_question_id
		  JOIN chain.filter_value fv ON TO_CHAR(qsa.answer) LIKE '%' || fv.str_value || '%'
		 WHERE fv.filter_field_id = in_filter_field_id;
	END IF;
END;

PROCEDURE FilterNumberQuestion (
	in_filter_id				IN chain.filter.filter_id%TYPE,
	in_filter_field_id			IN NUMBER,
	in_filter_field_name		IN chain.filter_field.name%TYPE,
	in_group_by_index			IN NUMBER,
	in_show_all					IN NUMBER,
	in_ids						IN chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_question_id				question.question_id%TYPE := CAST(regexp_substr(in_filter_field_name, '[0-9]+') AS NUMBER);
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, min_num_val, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, chain.filter_pkg.NUMBER_EQUAL, a.val_number, a.val_number
		  FROM (
			SELECT qsa.val_number
			  FROM v$quick_survey_response qsr
			  JOIN TABLE(in_ids) t ON t.object_id = qsr.survey_response_id
			  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
										  AND qsa.submission_id = qsr.submission_id
										  AND qsa.question_id = v_question_id
			 WHERE qsa.val_number IS NOT NULL
			 GROUP BY qsa.val_number
		  ) a
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.min_num_val = a.val_number
		 );
	END IF;
	
	chain.filter_pkg.SortNumberValues(in_filter_field_id);	

	SELECT chain.T_FILTERED_OBJECT_ROW(qsr.survey_response_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$quick_survey_response qsr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON t.object_id = qsr.survey_response_id
	  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
								  AND qsa.submission_id = qsr.submission_id
								  AND qsa.question_id = v_question_id
	  CROSS JOIN chain.filter_value fv
	 WHERE fv.filter_field_id = in_filter_field_id
	   AND chain.filter_pkg.CheckNumberRange(qsa.val_number, fv.num_value, fv.min_num_val, fv.max_num_val) = 1;
END;

PROCEDURE FilterDateQuestion (
	in_filter_id				IN chain.filter.filter_id%TYPE,
	in_filter_field_id			IN NUMBER,
	in_filter_field_name		IN chain.filter_field.name%TYPE,
	in_group_by_index			IN NUMBER,
	in_show_all					IN NUMBER,
	in_ids						IN chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_question_id				question.question_id%TYPE := CAST(regexp_substr(in_filter_field_name, '[0-9]+') AS NUMBER);
	v_min_date					DATE;
	v_max_date					DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- date is stored as days since 1900 (JS one day behind).
		SELECT MIN(qsa.val_dtm), MAX(qsa.val_dtm)
		  INTO v_min_date, v_max_date
		  FROM v$quick_survey_response qsr
		  JOIN TABLE(in_ids) t ON t.object_id = qsr.survey_response_id
		  JOIN (
				SELECT survey_response_id, submission_id, 
					   CASE WHEN val_number IS NULL THEN NULL ELSE TO_DATE('30-12-1899', 'DD-MM-YYYY') + val_number END val_dtm
				  FROM quick_survey_answer
				 WHERE question_id = v_question_id
				   AND val_number IS NOT NULL
			 ) qsa ON qsa.survey_response_id = qsr.survey_response_id AND qsa.submission_id = qsr.submission_id
		  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
									  AND qsa.submission_id = qsr.submission_id;
		
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
	END IF;

	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(qsr.survey_response_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$quick_survey_response qsr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON t.object_id = qsr.survey_response_id
	  JOIN (
			SELECT survey_response_id, submission_id, 
				   CASE WHEN val_number IS NULL THEN NULL ELSE TO_DATE('30-12-1899', 'DD-MM-YYYY') + val_number END val_dtm
			  FROM quick_survey_answer
			 WHERE question_id = v_question_id
			   AND val_number IS NOT NULL
	     ) qsa ON qsa.survey_response_id = qsr.survey_response_id AND qsa.submission_id = qsr.submission_id
	  JOIN chain.tt_filter_date_range dr 
	    ON qsa.val_dtm >= NVL(dr.start_dtm, qsa.val_dtm) 
	   AND (dr.end_dtm IS NULL OR qsa.val_dtm < dr.end_dtm);
END;

PROCEDURE FilterCheckboxQuestion (
	in_filter_id				IN chain.filter.filter_id%TYPE,
	in_filter_field_id			IN NUMBER,
	in_filter_field_name		IN chain.filter_field.name%TYPE,
	in_group_by_index			IN NUMBER,
	in_show_all					IN NUMBER,
	in_ids						IN chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_question_id				question.question_id%TYPE := CAST(regexp_substr(in_filter_field_name, '[0-9]+') AS NUMBER);
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, o.is_selected, o.description
		  FROM (
			SELECT 1 is_selected, 'Selected' description FROM dual
			UNION ALL SELECT 0, 'Not selected' FROM dual
		  ) o
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = o.is_selected
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(qsr.survey_response_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$quick_survey_response qsr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON t.object_id = qsr.survey_response_id
	  LEFT JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
									   AND qsa.submission_id = qsr.submission_id
									   AND qsa.question_id = v_question_id
	  JOIN chain.filter_value fv ON fv.num_value = CASE WHEN qsa.val_number > 0 THEN 1 ELSE 0 END
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterCheckboxGrpQuestion (
	in_filter_id				IN chain.filter.filter_id%TYPE,
	in_filter_field_id			IN NUMBER,
	in_filter_field_name		IN chain.filter_field.name%TYPE,
	in_group_by_index			IN NUMBER,
	in_show_all					IN NUMBER,
	in_ids						IN chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_question_id				question.question_id%TYPE := CAST(regexp_substr(in_filter_field_name, '[0-9]+') AS NUMBER);
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, a.question_id, a.label
		  FROM (
			SELECT cq.question_id,
				   MAX(cq.label) KEEP (DENSE_RANK LAST ORDER BY cq.question_version) label
			  FROM quick_survey_question q
			  JOIN quick_survey_question cq ON cq.parent_id = q.question_id
			 WHERE q.question_id = v_question_id
			   AND cq.question_type = 'checkbox'
			 GROUP BY cq.question_id
		  ) a
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = a.question_id
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(qsr.survey_response_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$quick_survey_response qsr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON t.object_id = qsr.survey_response_id
	  LEFT JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
									   AND qsa.submission_id = qsr.submission_id
									   AND qsa.val_number > 0
	  LEFT JOIN quick_survey_question qsq ON qsq.question_id = qsa.question_id
										 AND qsq.question_version = qsa.question_version
									     AND qsq.parent_id = v_question_id
	  JOIN chain.filter_value fv ON fv.num_value = qsq.question_id
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterRadioQuestion (
	in_filter_id				IN chain.filter.filter_id%TYPE,
	in_filter_field_id			IN NUMBER,
	in_filter_field_name		IN chain.filter_field.name%TYPE,
	in_group_by_index			IN NUMBER,
	in_show_all					IN NUMBER,
	in_ids						IN chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_question_id				question.question_id%TYPE := CAST(regexp_substr(in_filter_field_name, '[0-9]+') AS NUMBER);
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, a.question_option_id, a.label
		  FROM (
			SELECT qsa.question_option_id, 
				   MAX(qo.label) KEEP (DENSE_RANK LAST ORDER BY qo.question_version) label
			  FROM v$quick_survey_response qsr
			  JOIN TABLE(in_ids) t ON t.object_id = qsr.survey_response_id
			  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
										  AND qsa.submission_id = qsr.submission_id
										  AND qsa.question_id = v_question_id
			  JOIN question_option qo ON qo.question_id = qsa.question_id
									 AND qo.question_version = qsa.question_version
									 AND qo.question_option_id = qsa.question_option_id
			 GROUP BY qsa.question_option_id
		  ) a
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = a.question_option_id
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(qsr.survey_response_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$quick_survey_response qsr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON t.object_id = qsr.survey_response_id
	  LEFT JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
									   AND qsa.submission_id = qsr.submission_id
									   AND qsa.question_id = v_question_id
	  JOIN chain.filter_value fv ON fv.num_value = qsa.question_option_id
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterRegionQuestion (
	in_filter_id				IN chain.filter.filter_id%TYPE,
	in_filter_field_id			IN NUMBER,
	in_filter_field_name		IN chain.filter_field.name%TYPE,
	in_group_by_index			IN NUMBER,
	in_show_all					IN NUMBER,
	in_ids						IN chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_question_id				question.question_id%TYPE := CAST(regexp_substr(in_filter_field_name, '[0-9]+') AS NUMBER);
	v_region_sids				security.T_SID_TABLE;
BEGIN
	-- We want to limit to regions in the user's region tree
	SELECT DISTINCT NVL(link_to_region_sid, region_sid) region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM region
	 START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND region_sid IN (SELECT region_sid FROM region_start_point WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID'))
   CONNECT BY PRIOR app_sid = app_sid 
	   AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid;

	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, region_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, a.region_sid
		  FROM (
			SELECT qsa.region_sid
			  FROM v$quick_survey_response qsr
			  JOIN TABLE(in_ids) t ON t.object_id = qsr.survey_response_id
			  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
										  AND qsa.submission_id = qsr.submission_id
										  AND qsa.question_id = v_question_id
			  JOIN TABLE (v_region_sids) rt ON rt.column_value = qsa.region_sid
			 GROUP BY qsa.region_sid
		  ) a
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.region_sid = a.region_sid
		 );
		
		-- if show_all is on, we don't want to aggregate (otherwise the data is a mess)
		SELECT chain.T_FILTERED_OBJECT_ROW(survey_response_id, in_group_by_index, ia.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT qsa.survey_response_id, fv.filter_value_id
			  FROM v$quick_survey_response qsr
			  JOIN TABLE(in_ids) t ON t.object_id = qsr.survey_response_id
			  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
										  AND qsa.submission_id = qsr.submission_id
										  AND qsa.question_id = v_question_id
			  JOIN TABLE (v_region_sids) rt ON rt.column_value = qsa.region_sid
			  JOIN chain.filter_value fv ON fv.region_sid = qsa.region_sid
			 WHERE fv.filter_field_id = in_filter_field_id
		) ia;
	ELSE
		-- if show_all is off, users have specified the regions they want, they'll
		-- expect to get region aggregation
		SELECT chain.T_FILTERED_OBJECT_ROW(qsr.survey_response_id, in_group_by_index, fr.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM v$quick_survey_response qsr
		  JOIN TABLE(in_ids) t ON t.object_id = qsr.survey_response_id
		  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
									  AND qsa.submission_id = qsr.submission_id
									  AND qsa.question_id = v_question_id
		  JOIN TABLE (v_region_sids) rt ON rt.column_value = qsa.region_sid
		  JOIN (
				SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid, connect_by_root ff.filter_value_id filter_value_id
				  FROM region r
				  JOIN chain.filter_value ff ON ff.filter_field_id = in_filter_field_id
				 START WITH r.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND r.region_sid = ff.region_sid
			   CONNECT BY PRIOR r.app_sid = r.app_sid
				   AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
				   AND PRIOR ff.filter_value_id = ff.filter_value_id
		  ) fr ON qsa.region_sid = fr.region_sid;
	END IF;	
END;

PROCEDURE FilterQuestionComment (
	in_filter_id				IN chain.filter.filter_id%TYPE,
	in_filter_field_id			IN NUMBER,
	in_filter_field_name		IN chain.filter_field.name%TYPE,
	in_group_by_index			IN NUMBER,
	in_show_all					IN NUMBER,
	in_ids						IN chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_question_id				question.question_id%TYPE := CAST(regexp_substr(in_filter_field_name, '[0-9]+') AS NUMBER);
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, str_value)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, a.note
		  FROM (
			SELECT SUBSTR(TO_CHAR(qsa.note), 1, 255) note
			  FROM v$quick_survey_response qsr
			  JOIN TABLE(in_ids) t ON t.object_id = qsr.survey_response_id
			  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
										  AND qsa.submission_id = qsr.submission_id
										  AND qsa.question_id = v_question_id
			 WHERE qsa.note IS NOT NULL
			 GROUP BY SUBSTR(TO_CHAR(qsa.note), 1, 255)
		  ) a
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.str_value = a.note
		 );
		 
		-- If we're aggregating, don't double-count rows that are substrings
		SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM v$quick_survey_response qsr
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON t.object_id = qsr.survey_response_id
		  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
									  AND qsa.submission_id = qsr.submission_id
									  AND qsa.question_id = v_question_id
		  JOIN chain.filter_value fv ON SUBSTR(TO_CHAR(qsa.note), 1, 255) = fv.str_value
		 WHERE fv.filter_field_id = in_filter_field_id;
	ELSE
		SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM v$quick_survey_response qsr
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON t.object_id = qsr.survey_response_id
		  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
									  AND qsa.submission_id = qsr.submission_id
									  AND qsa.question_id = v_question_id
		  JOIN chain.filter_value fv ON TO_CHAR(qsa.note) LIKE '%' || fv.str_value || '%'
		 WHERE fv.filter_field_id = in_filter_field_id;
	END IF;
END;

PROCEDURE FilterQuestionFileUpload (
	in_filter_id				IN chain.filter.filter_id%TYPE,
	in_filter_field_id			IN NUMBER,
	in_filter_field_name		IN chain.filter_field.name%TYPE,
	in_group_by_index			IN NUMBER,
	in_show_all					IN NUMBER,
	in_ids						IN chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_question_id				question.question_id%TYPE := CAST(regexp_substr(in_filter_field_name, '[0-9]+') AS NUMBER);
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, o.has_upload, o.description
		  FROM (
			SELECT 1 has_upload, 'File uploaded' description FROM dual
			UNION ALL SELECT 0, 'No file uploaded' FROM dual
		  ) o
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = o.has_upload
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(qsr.survey_response_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$quick_survey_response qsr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON t.object_id = qsr.survey_response_id
	  LEFT JOIN (
			SELECT survey_response_id, count(*) num_files
			  FROM qs_answer_file
			 WHERE question_id = v_question_id
			 GROUP BY survey_response_id
	  ) fc ON fc.survey_response_id = qsr.survey_response_id
	  JOIN chain.filter_value fv ON fv.num_value = CASE WHEN fc.num_files > 0 THEN 1 ELSE 0 END
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterQuestionScore (
	in_filter_id				IN chain.filter.filter_id%TYPE,
	in_filter_field_id			IN NUMBER,
	in_filter_field_name		IN chain.filter_field.name%TYPE,
	in_group_by_index			IN NUMBER,
	in_show_all					IN NUMBER,
	in_ids						IN chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_companies_cap				T_QS_RESPONSE_PERM_TABLE := GetResponseCompanies(in_ids, 1);
	v_audits_cap				T_QS_RESPONSE_PERM_TABLE := GetResponseAudits(in_ids, 1);
	v_question_id				question.question_id%TYPE := CAST(regexp_substr(in_filter_field_name, '[0-9]+') AS NUMBER);
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, min_num_val, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, chain.filter_pkg.NUMBER_EQUAL, a.score, a.score
		  FROM (
			SELECT qsa.score
			  FROM v$quick_survey_response qsr
			  JOIN TABLE(in_ids) t ON t.object_id = qsr.survey_response_id
			  LEFT JOIN TABLE(v_companies_cap) c_t ON c_t.survey_response_id = qsr.survey_response_id
			  LEFT JOIN TABLE(v_audits_cap) ia_t ON ia_t.survey_response_id = qsr.survey_response_id
			  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
										  AND qsa.submission_id = qsr.submission_id
										  AND qsa.question_id = v_question_id
			 WHERE qsa.score IS NOT NULL
			   AND (c_t.survey_response_id IS NULL OR c_t.can_see_scores = 1)
			   AND (ia_t.survey_response_id IS NULL OR ia_t.can_see_scores = 1)
			 GROUP BY qsa.score
		  ) a
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.min_num_val = a.score
		 );
	END IF;
	
	chain.filter_pkg.SortNumberValues(in_filter_field_id);	

	SELECT chain.T_FILTERED_OBJECT_ROW(qsr.survey_response_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$quick_survey_response qsr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON t.object_id = qsr.survey_response_id
	  LEFT JOIN TABLE(v_companies_cap) c_t ON c_t.survey_response_id = qsr.survey_response_id
	  LEFT JOIN TABLE(v_audits_cap) ia_t ON ia_t.survey_response_id = qsr.survey_response_id
	  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qsr.survey_response_id
								  AND qsa.submission_id = qsr.submission_id
								  AND qsa.question_id = v_question_id
	  CROSS JOIN chain.filter_value fv
	 WHERE fv.filter_field_id = in_filter_field_id
	   AND (c_t.survey_response_id IS NULL OR c_t.can_see_scores = 1)
	   AND (ia_t.survey_response_id IS NULL OR ia_t.can_see_scores = 1)
	   AND chain.filter_pkg.CheckNumberRange(qsa.score, fv.num_value, fv.min_num_val, fv.max_num_val) = 1;
END;

PROCEDURE FilterSavedFilter (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_comparator					IN	chain.filter_field.comparator%TYPE, 
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_result_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_temp_ids						chain.T_FILTERED_OBJECT_TABLE;
BEGIN
	IF in_comparator = chain.filter_pkg.COMPARATOR_INTERSECT THEN
		v_result_ids := in_ids;

		IF in_group_by_index IS NOT NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Cannot group by intersected filters');
		END IF;

		FOR r IN (
			SELECT sf.compound_filter_id, sf.search_text, fv.filter_value_id
			  FROM chain.filter_value fv
			  JOIN chain.saved_filter sf ON fv.saved_filter_sid_value = sf.saved_filter_sid
			 WHERE fv.filter_field_id = in_filter_field_id
		) LOOP	
			GetFilteredIds(
				in_search						=> r.search_text,
				in_compound_filter_id			=> r.compound_filter_id,
				in_id_list						=> v_result_ids,
				out_id_list						=> v_result_ids
			);
		END LOOP;
		
		out_ids := v_result_ids;
	ELSE
		out_ids := chain.T_FILTERED_OBJECT_TABLE();

		FOR r IN (
			SELECT sf.compound_filter_id, sf.search_text, fv.filter_value_id
			  FROM chain.filter_value fv
			  JOIN chain.saved_filter sf ON fv.saved_filter_sid_value = sf.saved_filter_sid
			 WHERE fv.filter_field_id = in_filter_field_id
		) LOOP	
			GetFilteredIds(
				in_search						=> r.search_text,
				in_compound_filter_id			=> r.compound_filter_id,
				in_id_list						=> in_ids,
				out_id_list						=> v_result_ids
			);

			SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, r.filter_value_id)
			  BULK COLLECT INTO v_temp_ids
			  FROM TABLE(v_result_ids) t;

			out_ids := out_ids MULTISET UNION v_temp_ids;
		END LOOP;
	END IF;
END;

PROCEDURE INTERNAL_ResponseSidsToCoSids (
	in_response_ids					IN security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	INSERT INTO chain.temp_grid_extension_map gem (source_id, linked_type, linked_id)
	SELECT DISTINCT reg.response_id, chain.filter_pkg.FILTER_TYPE_COMPANIES, s.company_sid
	  FROM (
		SELECT r.sid_id response_id, ia.region_sid
		  FROM TABLE(in_response_ids) r
		  JOIN csr.internal_audit ia ON (r.sid_id = ia.survey_response_id OR r.sid_id = ia.summary_response_id)
		 UNION
		SELECT r.sid_id response_id, ia.region_sid
		  FROM TABLE(in_response_ids) r
		  JOIN csr.internal_audit_survey ias ON r.sid_id = ias.survey_response_id
		  JOIN csr.internal_audit ia ON ia.internal_audit_sid = ias.internal_audit_sid
		 UNION
		SELECT r.sid_id response_id, rsr.region_sid
		  FROM TABLE(in_response_ids) r
		  JOIN csr.region_survey_response rsr ON rsr.survey_response_id = r.sid_id
	  ) reg
	  JOIN csr.supplier s ON s.region_sid = reg.region_sid;
END;

END quick_survey_report_pkg;
/
