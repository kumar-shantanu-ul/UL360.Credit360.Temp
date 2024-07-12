CREATE OR REPLACE PACKAGE BODY CSR.non_compliance_report_pkg
IS

-- private field filter units
PROCEDURE FilterRegionSid			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAuditSid			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAuditDtm			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterClosedStatus		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterNCsOpenActions		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCreatedDtm			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCreatedByUserSid	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterNonComplianceTypeId	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_audit_type_group_key IN internal_audit_type_group.lookup_key%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterDefaultNonCompId	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_audit_type_group_key IN internal_audit_type_group.lookup_key%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterQuestionId			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_audit_type_group_key IN internal_audit_type_group.lookup_key%TYPE, in_group_by_index NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCarryForward		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRepeat				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);

PROCEDURE FilterTag					(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSavedFilter			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_audit_type_group_key IN internal_audit_type_group.lookup_key%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_comparator IN chain.filter_field.comparator%TYPE, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAudits				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_audit_type_group_key IN internal_audit_type_group.lookup_key%TYPE, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterIssues				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterByContextCompany	(in_filter_id IN  chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN  chain.filter_field.name%TYPE, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCompaniesBreakdown	(in_name IN	chain.filter_field.name%TYPE, in_comparator IN	chain.filter_field.comparator%TYPE, in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAuditorCompaniesBrkdwn	(in_name IN	chain.filter_field.name%TYPE, in_comparator IN	chain.filter_field.comparator%TYPE, in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);

PROCEDURE FilterAuditNCIds (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_audit_type_group_key			IN  internal_audit_type_group.lookup_key%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_starting_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_result_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_inner_log_id					chain.debug_log.debug_log_id%TYPE;
	v_name							VARCHAR2(256);
BEGIN
	v_starting_ids := in_ids;

	IF in_parallel = 0 THEN
		out_ids := in_ids;
	ELSE
		out_ids := chain.T_FILTERED_OBJECT_TABLE();
	END IF;
	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.non_compliance_report_pkg.FilterAuditNCIds', in_filter_id);
	
	FOR r IN (
		SELECT name, filter_field_id, show_all, group_by_index, comparator
		  FROM chain.v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := chain.filter_pkg.StartDebugLog('csr.non_compliance_report_pkg.FilterAuditNCIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);
		
		IF r.name = 'RegionSid' THEN
			FilterRegionSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'AuditSid' THEN
			FilterAuditSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'AuditDtm' THEN
			FilterAuditDtm(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);			
		ELSIF r.name = 'IsClosed' THEN
			FilterClosedStatus(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'OpenActions' THEN
			FilterNCsOpenActions(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'CreatedDtm' THEN
			FilterCreatedDtm(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'CreatedByUserSid' THEN
			FilterCreatedByUserSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'IsCarryForward' THEN
			FilterCarryForward(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'IsRepeat' THEN
			FilterRepeat(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'NonComplianceTypeId' THEN
			FilterNonComplianceTypeId(in_filter_id, r.filter_field_id, in_audit_type_group_key, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'DefaultNonComplianceId' THEN
			FilterDefaultNonCompId(in_filter_id, r.filter_field_id, in_audit_type_group_key, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'FromSurvey.%' THEN 
			FilterQuestionId(in_filter_id, r.filter_field_id, r.name, in_audit_type_group_key, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'auditFilter_CompanyFilter_TagGroup%' THEN
			v_name := substr(r.name, 27);
			FilterCompaniesBreakdown(v_name, r.comparator, in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);			
		ELSIF r.name LIKE 'auditFilter_AuditorCompanyFilter_TagGroup%' THEN
			v_name := substr(r.name, 34);
			FilterAuditorCompaniesBrkdwn(v_name, r.comparator, in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE '%TagGroup.%' THEN
			FilterTag(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'savedfilter' THEN
			FilterSavedFilter(in_filter_id, r.filter_field_id, in_audit_type_group_key, r.group_by_index, r.show_all, r.comparator, v_starting_ids, v_result_ids);
		ELSIF r.name = 'AuditFilter' THEN
			FilterAudits(in_filter_id, r.filter_field_id, in_audit_type_group_key, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'IssueFilter' THEN
			FilterIssues(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'MyCompanyAudits' THEN
			FilterByContextCompany(in_filter_id, r.filter_field_id, r.name, r.show_all, v_starting_ids, v_result_ids);
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

PROCEDURE FilterCompaniesBreakdown (
	in_name							IN	chain.filter_field.name%TYPE,
	in_comparator					IN	chain.filter_field.comparator%TYPE,
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_company_sids					chain.T_FILTERED_OBJECT_TABLE;	
BEGIN
	
	SELECT chain.T_FILTERED_OBJECT_ROW(s.company_sid, in_group_by_index, t.group_by_value)
	  BULK COLLECT INTO v_company_sids
	  FROM csr.audit_non_compliance anc
      JOIN csr.non_compliance nc on nc.non_compliance_id = anc.non_compliance_id 
      JOIN csr.supplier s ON s.region_sid = nc.region_sid
	  JOIN TABLE(in_ids) t ON anc.audit_non_compliance_id = t.object_id;
		  
	chain.company_filter_pkg.RunSingleUnit(
		in_name						=> in_name,
		in_comparator				=> in_comparator,
		in_column_sid				=> NULL,
		in_filter_id				=> in_filter_id,
		in_filter_field_id			=> in_filter_field_id,
		in_group_by_index			=> in_group_by_index,
		in_show_all					=> in_show_all,
		in_sids						=> v_company_sids,
		out_sids					=> v_company_sids
	);

	SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, in_group_by_index, cs.group_by_value)
	  BULK COLLECT INTO out_ids
	  FROM csr.audit_non_compliance anc
      JOIN csr.non_compliance nc on nc.non_compliance_id = anc.non_compliance_id 
      JOIN csr.supplier s ON s.region_sid = nc.region_sid
	  JOIN TABLE(v_company_sids) cs ON s.company_sid = cs.object_id
	  JOIN TABLE(in_ids) t ON anc.audit_non_compliance_id = t.object_id;
END;

PROCEDURE FilterAuditorCompaniesBrkdwn (
	in_name							IN	chain.filter_field.name%TYPE,
	in_comparator					IN	chain.filter_field.comparator%TYPE,
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_company_ids					chain.T_FILTERED_OBJECT_TABLE;	
BEGIN
	SELECT chain.T_FILTERED_OBJECT_ROW(s.company_sid, in_group_by_index, t.group_by_value)
	  BULK COLLECT INTO v_company_ids
	  FROM csr.audit_non_compliance anc
	  JOIN csr.internal_audit ia on anc.internal_audit_sid = ia.internal_audit_sid
	  JOIN csr.supplier s ON s.company_sid = ia.auditor_company_sid
	  JOIN TABLE(in_ids) t ON anc.audit_non_compliance_id = t.object_id;
		
	chain.company_filter_pkg.RunSingleUnit(
		in_name						=> in_name,
		in_comparator				=> in_comparator,
		in_column_sid				=> NULL,
		in_filter_id				=> in_filter_id,
		in_filter_field_id			=> in_filter_field_id,
		in_group_by_index			=> in_group_by_index,
		in_show_all					=> in_show_all,
		in_sids						=> v_company_ids,
		out_sids					=> v_company_ids
	);

	SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, in_group_by_index, cs.group_by_value)
	  BULK COLLECT INTO out_ids
	  FROM csr.audit_non_compliance anc
	  JOIN csr.internal_audit ia on anc.internal_audit_sid = ia.internal_audit_sid
	  JOIN csr.supplier s ON s.company_sid = ia.auditor_company_sid
	  JOIN TABLE(v_company_ids) cs ON s.company_sid = cs.object_id
	  JOIN TABLE(in_ids) t ON anc.audit_non_compliance_id = t.object_id;
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
	in_audit_type_group_key			IN  internal_audit_type_group.lookup_key%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN	NUMBER,
	in_audit_nc_id_list				IN	chain.T_FILTERED_OBJECT_TABLE,
	out_audit_nc_id_list			OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_starting_sids					chain.T_FILTERED_OBJECT_TABLE;
	v_result_sids					chain.T_FILTERED_OBJECT_TABLE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.non_compliance_report_pkg.RunCompoundFilter');
	
	v_starting_sids := in_audit_nc_id_list;

	IF in_parallel = 0 THEN
		out_audit_nc_id_list := in_audit_nc_id_list;
	ELSE
		out_audit_nc_id_list := chain.T_FILTERED_OBJECT_TABLE();
	END IF;

	chain.filter_pkg.CheckCompoundFilterAccess(in_compound_filter_id, security_pkg.PERMISSION_READ);
	chain.filter_pkg.CheckCompoundFilterForCycles(in_compound_filter_id);
		
	FOR r IN (
		SELECT f.filter_id, ft.helper_pkg
		  FROM chain.filter f
		  JOIN chain.filter_type ft ON f.filter_type_id = ft.filter_type_id
		 WHERE f.compound_filter_id = in_compound_filter_id
	) LOOP
		BEGIN
			EXECUTE IMMEDIATE ('BEGIN ' || r.helper_pkg || '.FilterAuditNCIds(:filter_id, :audit_type_group, :parallel, :max_group_by, :input, :output);END;') 
			USING r.filter_id, in_audit_type_group_key, in_parallel, in_max_group_by, v_starting_sids, OUT v_result_sids;
		END;
		
		IF in_parallel = 0 THEN
			v_starting_sids := v_result_sids;
			out_audit_nc_id_list := v_result_sids;
		ELSE
			out_audit_nc_id_list := out_audit_nc_id_list MULTISET UNION v_result_sids;
		END IF;
	END LOOP;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetFilterObjectData (
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_audit_nc_id_list				IN	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.non_compliance_report_pkg.GetFilterObjectData');
	
	-- just in case
	DELETE FROM chain.tt_filter_object_data;
	
	IF CARDINALITY(in_aggregation_types) = 1 AND in_aggregation_types(1) = AGG_TYPE_COUNT THEN
		-- single agg type of count - split out of other insert as require fewer joins
		INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
		SELECT chain.filter_pkg.AFUNC_COUNT, l.object_id, chain.filter_pkg.AFUNC_COUNT, l.object_id
		  FROM audit_non_compliance anc
		  JOIN TABLE(in_audit_nc_id_list) l ON anc.audit_non_compliance_id = l.object_id
		 GROUP BY l.object_id
		;
	ELSE
		INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
		SELECT DISTINCT a.column_value, l.object_id, 
			   CASE a.column_value
					WHEN AGG_TYPE_COUNT THEN chain.filter_pkg.AFUNC_COUNT
					WHEN AGG_TYPE_COUNT_ISSUES THEN chain.filter_pkg.AFUNC_SUM
					WHEN AGG_TYPE_COUNT_OPEN_ISSUES THEN chain.filter_pkg.AFUNC_SUM
					WHEN AGG_TYPE_COUNT_OVRD_ISSUES THEN chain.filter_pkg.AFUNC_SUM
					WHEN AGG_TYPE_COUNT_CLOSED_ISSUES THEN chain.filter_pkg.AFUNC_SUM
					WHEN AGG_TYPE_COUNT_IS_CLSD_ON_TIME THEN chain.filter_pkg.AFUNC_SUM
					WHEN AGG_TYPE_COUNT_IS_CLSD_OVRD THEN chain.filter_pkg.AFUNC_SUM
				END,
				CASE a.column_value
					WHEN AGG_TYPE_COUNT THEN l.object_id
					WHEN AGG_TYPE_COUNT_ISSUES THEN COUNT(DISTINCT i.issue_id)
					WHEN AGG_TYPE_COUNT_OPEN_ISSUES THEN COUNT(DISTINCT CASE WHEN i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id END)
					WHEN AGG_TYPE_COUNT_OVRD_ISSUES THEN COUNT(DISTINCT CASE WHEN i.due_dtm < TRUNC(SYSDATE) AND i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id END)
					WHEN AGG_TYPE_COUNT_CLOSED_ISSUES THEN COUNT(DISTINCT CASE WHEN i.resolved_dtm IS NOT NULL THEN i.issue_id END)
					WHEN AGG_TYPE_COUNT_IS_CLSD_ON_TIME THEN COUNT(DISTINCT CASE WHEN i.resolved_dtm IS NOT NULL AND TRUNC(i.resolved_dtm) <= i.due_dtm THEN i.issue_id END)
					WHEN AGG_TYPE_COUNT_IS_CLSD_OVRD THEN COUNT(DISTINCT CASE WHEN i.resolved_dtm IS NOT NULL AND TRUNC(i.resolved_dtm) > i.due_dtm THEN i.issue_id END)
				END
		  FROM audit_non_compliance anc
		  JOIN TABLE(in_audit_nc_id_list) l ON anc.audit_non_compliance_id = l.object_id
		  CROSS JOIN TABLE(in_aggregation_types) a
		  LEFT JOIN issue_non_compliance inc ON anc.app_sid = inc.app_sid AND anc.non_compliance_id = inc.non_compliance_id
		  LEFT JOIN issue i ON inc.app_sid = i.app_sid AND inc.issue_non_compliance_id = i.issue_non_compliance_id AND i.deleted = 0
		 GROUP BY a.column_value, l.object_id
		;
	END IF;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetPermissibleIds (
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_audits_by_acl					security.T_SID_TABLE;
	v_audits_by_cap					security.T_SID_TABLE;
	v_audits_by_custom_cap			csr.T_AUDIT_PERMISSIBLE_NCT_TABLE;
	v_audits_sid					security_pkg.T_SID_ID;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_trash_sid						security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Trash');
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.non_compliance_report_pkg.GetPermissibleIds');
	
	v_audits_by_cap := audit_pkg.GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL, security.security_pkg.PERMISSION_READ, NULL);
	v_audits_by_custom_cap := audit_pkg.GetCustomPermissibleAuditNCTs(security.security_pkg.PERMISSION_READ);
	v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
	
	-- Audits user has read access to via old permission model - copied from audit_body
	-- We should retire the old model and simplify the permissions + speed up these queries
	SELECT DISTINCT audit_id
	  BULK COLLECT INTO v_audits_by_acl
	  FROM(
		SELECT t.sid_id audit_id
		  FROM TABLE(SecurableObject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), v_audits_sid, security_pkg.PERMISSION_READ)) t
		  JOIN csr.internal_audit ia on ia.internal_audit_sid = t.sid_id
		 WHERE ia.flow_item_id IS NULL
		 UNION
		SELECT ia.internal_audit_sid audit_id
		  FROM csr.internal_audit ia
		  JOIN csr.internal_audit_type iat
			ON ia.internal_audit_type_id = iat.internal_audit_type_id
		  JOIN csr.region_role_member rrm
			ON (iat.auditor_role_sid = rrm.role_sid
			OR iat.audit_contact_role_sid = rrm.role_sid)
		   AND rrm.region_sid = ia.region_sid
		  JOIN security.securable_object so ON ia.internal_audit_sid = so.sid_id
		 WHERE rrm.user_sid = security.security_pkg.GetSid
		   AND so.parent_sid_id != v_trash_sid
		   AND ia.flow_item_id IS NULL
		   AND ia.deleted = 0
		);
	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	
	-- Get the audit non-compliances for the audits we have permissions on
	SELECT chain.T_FILTERED_OBJECT_ROW(audit_non_compliance_id, NULL, NULL)
	  BULK COLLECT INTO out_id_list
	  FROM (
		SELECT anc.audit_non_compliance_id
		  FROM audit_non_compliance anc
		  JOIN (SELECT column_value FROM TABLE(v_audits_by_acl) ORDER BY column_value) old ON anc.internal_audit_sid = old.column_value
		 UNION
		 -- via std cap
		SELECT anc.audit_non_compliance_id
		  FROM audit_non_compliance anc
		  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
		  LEFT JOIN non_compliance_type nct ON nct.non_compliance_type_id = nc.non_compliance_type_id
		  JOIN (SELECT column_value FROM TABLE(v_audits_by_cap) ORDER BY column_value) cap ON anc.internal_audit_sid = cap.column_value
		 WHERE NOT EXISTS (SELECT NULL FROM non_compliance_type_flow_cap fc WHERE fc.non_compliance_type_id = nc.non_compliance_type_id AND fc.base_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL)
	  	 UNION
		 -- via custom cap
		SELECT anc.audit_non_compliance_id
		  FROM audit_non_compliance anc
		  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
		  JOIN non_compliance_type_flow_cap nctfc ON nctfc.non_compliance_type_id = nc.non_compliance_type_id AND nctfc.base_flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL
		  JOIN (SELECT audit_sid internal_audit_sid, non_compliance_type_id FROM TABLE(v_audits_by_custom_cap) ORDER BY audit_sid) cap
			ON anc.internal_audit_sid = cap.internal_audit_sid AND nctfc.non_compliance_type_id = cap.non_compliance_type_id
	  );
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetInitialAuditNCIds(
	in_search						IN	VARCHAR2 DEFAULT NULL,
	in_group_key					IN	chain.saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_id					IN	NUMBER DEFAULT NULL,
	in_region_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_start_dtm					IN	DATE DEFAULT NULL,
	in_end_dtm						IN	DATE DEFAULT NULL,
	in_region_col_type				IN	NUMBER DEFAULT NULL,
	in_date_col_type				IN	NUMBER DEFAULT NULL,
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_sanitised_search				VARCHAR2(4000) := aspen2.utils_pkg.SanitiseOracleContains(in_search);
	v_has_regions					NUMBER;
	v_permissible_ids				chain.T_FILTERED_OBJECT_TABLE;
	v_temp_ids						chain.T_FILTERED_OBJECT_TABLE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.non_compliance_report_pkg.GetInitialAuditNCIds');
	
	chain.filter_pkg.GetFilteredObjectsFromCache(
		in_card_group_id => chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES,
		out_filtered_objects => v_permissible_ids
	);
	
	IF v_permissible_ids IS NULL THEN
		GetPermissibleIds(v_permissible_ids);
		
		chain.filter_pkg.SetFilteredObjectsInCache(
			in_card_group_id => chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES,
			in_filtered_objects => v_permissible_ids
		);
	END IF;
	
	-- Filter our permissable audit non-compliances to those passed in
	IF in_id_list IS NOT NULL THEN
		SELECT chain.T_FILTERED_OBJECT_ROW(t1.object_id, NULL, NULL)
		  BULK COLLECT INTO v_temp_ids
		  FROM TABLE(in_id_list) t1 
		  JOIN TABLE(v_permissible_ids) t2 on t1.object_id = t2.object_id;

		v_permissible_ids := v_temp_ids;
	END IF;
	
	IF NVL(in_pre_filter_sid, 0) > 0 THEN
		FOR r IN (
			SELECT sf.compound_filter_id, sf.search_text
			  FROM chain.saved_filter sf
			 WHERE saved_filter_sid = in_pre_filter_sid
		) LOOP	
			GetFilteredIds(
				in_search						=> r.search_text,
				in_compound_filter_id			=> r.compound_filter_id,
				in_id_list						=> v_permissible_ids,
				out_id_list						=> v_permissible_ids
			);
		END LOOP;
	END IF;
	
	IF in_search IS NULL AND in_start_dtm IS NULL AND in_end_dtm IS NULL AND in_group_key IS NULL
	   AND (in_region_sids IS NULL OR CARDINALITY(in_region_sids) = 0) 
	   AND in_parent_id IS NULL THEN
		-- Nothing else to filter, return permissible IDs
		chain.filter_pkg.EndDebugLog(v_log_id);
		out_id_list := v_permissible_ids;
		RETURN;
	END IF;
	chain.filter_pkg.PopulateTempRegionSid(in_region_sids, in_region_col_type, v_has_regions);

	-- do a different join if they are text searching, as by default this will be null, and adds significant
	-- time to the query (even though it shouldn't need to do the contains bit as v_sanitised_search is null)
	IF in_search IS NULL THEN
		SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, NULL, NULL)
		  BULK COLLECT INTO out_id_list
		  FROM TABLE (v_permissible_ids) list
		  JOIN audit_non_compliance anc ON list.object_id = anc.audit_non_compliance_id
		  JOIN non_compliance nc ON nc.app_sid = anc.app_sid AND nc.non_compliance_id = anc.non_compliance_id
		  JOIN internal_audit ia ON anc.internal_audit_sid = ia.internal_audit_sid AND anc.app_sid = ia.app_sid
		  JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
		  LEFT JOIN internal_audit_type_group atg ON iat.internal_audit_type_group_id = atg.internal_audit_type_group_id AND iat.app_sid = atg.app_sid
		  LEFT JOIN temp_region_sid tr ON nc.region_sid = tr.region_sid
		 WHERE (in_group_key IS NULL OR LOWER(atg.lookup_key) = LOWER(in_group_key))
		   AND (in_parent_id IS NULL OR in_parent_id = anc.internal_audit_sid)
		   AND (v_has_regions = 0 OR tr.region_sid IS NOT NULL)
		   AND (in_start_dtm IS NULL OR in_start_dtm <= ia.audit_dtm)
		   AND (in_end_dtm IS NULL OR in_end_dtm > ia.audit_dtm) 
		 GROUP BY anc.audit_non_compliance_id;
	ELSE
		SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, NULL, NULL)
		  BULK COLLECT INTO out_id_list
		  FROM TABLE (v_permissible_ids) list
		  JOIN audit_non_compliance anc ON list.object_id = anc.audit_non_compliance_id
		  JOIN non_compliance nc ON nc.app_sid = anc.app_sid AND nc.non_compliance_id = anc.non_compliance_id
		  LEFT JOIN non_compliance_type nct ON nc.app_sid = nct.app_sid AND nc.non_compliance_type_id = nct.non_compliance_type_id
		  JOIN internal_audit ia ON anc.internal_audit_sid = ia.internal_audit_sid AND anc.app_sid = ia.app_sid
		  JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
		  LEFT JOIN internal_audit_type_group atg ON iat.internal_audit_type_group_id = atg.internal_audit_type_group_id AND iat.app_sid = atg.app_sid
		  LEFT JOIN temp_region_sid tr ON nc.region_sid = tr.region_sid
		  LEFT JOIN v$region r ON r.region_sid = nc.region_sid
		 WHERE (in_group_key IS NULL OR LOWER(atg.lookup_key) = LOWER(in_group_key))
		   AND (in_parent_id IS NULL OR in_parent_id = anc.internal_audit_sid)
		   AND (v_has_regions = 0 OR tr.region_sid IS NOT NULL)
		   AND (in_start_dtm IS NULL OR in_start_dtm <= ia.audit_dtm)
		   AND (in_end_dtm IS NULL OR in_end_dtm > ia.audit_dtm)
		   AND (LENGTH(TRIM(v_sanitised_search)) > 0 AND INSTR(v_sanitised_search, '%') > 0 AND (CONTAINS (nc.label, v_sanitised_search) > 0 
													   OR CONTAINS (nc.detail, v_sanitised_search) > 0 
													   OR CONTAINS(nc.root_cause, v_sanitised_search) > 0 
													   OR CONTAINS(nc.suggested_action, v_sanitised_search) > 0)
			   OR (INSTR(v_sanitised_search, '%') = 0 AND (UPPER(nc.label) LIKE '%' || UPPER(in_search) || '%') 
													   OR UPPER(nc.detail) LIKE '%' || UPPER(in_search) || '%'
													   OR UPPER(nc.root_cause) LIKE '%' || UPPER(in_search) || '%'
													   OR UPPER(nc.suggested_action) LIKE '%' || UPPER(in_search) || '%')
			   OR UPPER(atg.internal_audit_ref_prefix||NVL(ia.internal_audit_ref, ia.internal_audit_sid)) = UPPER(in_search)
			   OR UPPER(nct.inter_non_comp_ref_prefix||NVL(nc.non_compliance_ref, nc.non_compliance_id)) = UPPER(in_search)
			   OR UPPER(r.description) LIKE '%' || UPPER(in_search) || '%' -- column not indexed so we can't do a CONTAINS here.
			   OR EXISTS (-- match on [prefix][ID] on issues
					SELECT *
					  FROM issue_non_compliance ict
					  JOIN issue i ON ict.issue_non_compliance_id = i.issue_non_compliance_id
					  JOIN issue_type it ON i.issue_type_id = it.issue_type_id
					 WHERE nc.non_compliance_id = ict.non_compliance_id			   
					   AND UPPER(it.internal_issue_ref_prefix||NVL(i.issue_ref, i.issue_id)) = UPPER(in_search)
				)
			)
		 GROUP BY anc.audit_non_compliance_id;
	END IF;

	chain.filter_pkg.EndDebugLog(v_log_id);
	aspen2.request_queue_pkg.AssertRequestStillActive;
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
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE DEFAULT NULL,
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_start_dtm						DATE;
	v_end_dtm						DATE;
BEGIN
	chain.filter_pkg.GetLargestDateWindow(in_compound_filter_id, 'AuditDtm', 'csr.non_compliance_report_pkg',
		in_start_dtm, in_end_dtm, v_start_dtm, v_end_dtm);
	
	-- Step 1, get initial set of ids
	GetInitialAuditNCIds(
		in_search			=> in_search,
		in_group_key		=> in_group_key,
		in_pre_filter_sid	=> in_pre_filter_sid,
		in_parent_id		=> in_parent_id,	
		in_region_sids		=>	in_region_sids,
		in_start_dtm		=> v_start_dtm,
		in_end_dtm			=> v_end_dtm,
		in_region_col_type	=> in_region_col_type,
		in_date_col_type	=> in_date_col_type,
		in_id_list			=> in_id_list,
		out_id_list			=> out_id_list
	);

	-- Step 2, If there's a filter, restrict the list of issue ids
	IF NVL(in_compound_filter_id, 0) > 0 THEN -- XPJ passes round zero for some reason?
		RunCompoundFilter(in_compound_filter_id, in_group_key, 0, NULL, out_id_list, out_id_list);
	END IF;
END;

PROCEDURE ApplyBreadcrumb(
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE,
	in_audit_type_group_key			IN  internal_audit_type_group.lookup_key%TYPE,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_aggregation_type				IN	NUMBER DEFAULT NULL,
	out_id_list					OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_breadcrumb_count				NUMBER;
	v_field_compound_filter_id		NUMBER;
	v_top_n_values					security.T_ORDERED_SID_TABLE; -- not sids, but this exists already
	v_aggregation_types				security.T_SID_TABLE;
	v_temp							chain.T_FILTERED_OBJECT_TABLE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.non_compliance_report_pkg.ApplyBreadcrumb');
	
	out_id_list := in_id_list;
	
	v_breadcrumb_count := CASE WHEN in_breadcrumb IS NULL THEN 0 WHEN in_breadcrumb.COUNT = 1 AND in_breadcrumb(1) IS NULL THEN 0 ELSE in_breadcrumb.COUNT END;
	
	IF v_breadcrumb_count > 0 THEN
		v_field_compound_filter_id := chain.filter_pkg.GetCompFilterIdFromBreadcrumb(in_breadcrumb);
	
		RunCompoundFilter(v_field_compound_filter_id, in_audit_type_group_key, 1, v_breadcrumb_count, out_id_list, out_id_list);
		-- check if any breadcrumb elements are on "other". If not, we don't need to do a top N	
		IF in_breadcrumb(1) < 0 OR
			(v_breadcrumb_count > 1 AND in_breadcrumb(2) < 0) OR
			(v_breadcrumb_count > 2 AND in_breadcrumb(3) < 0) OR
			(v_breadcrumb_count > 3 AND in_breadcrumb(4) < 0)
		THEN
			-- Use the aggregation type for drilldowns on "other"
			-- If not supplied, use count
			SELECT NVL(in_aggregation_type, 1) BULK COLLECT INTO v_aggregation_types FROM dual;

			GetFilterObjectData(v_aggregation_types, out_id_list);
			
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
	in_audit_nc_id_list				IN  security.T_ORDERED_SID_TABLE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR,
	out_tags_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS	
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.non_compliance_report_pkg.CollectSearchResults');
	
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ anc.audit_non_compliance_id, nc.non_compliance_id, nc.label, nc.detail, nc.from_non_comp_default_id,
			   nc.created_dtm, nc.created_by_user_sid, nc.created_in_audit_sid, cc.full_name created_by_full_name, 
			   nc.created_in_audit_sid sid_id, ia.internal_audit_sid, ia.label audit_label, ia.audit_dtm, iat.label audit_type_label, ia.auditor_organisation,
			   qsq.question_id, qsq.label question_label, nc.non_compliance_type_id, nct.label non_compliance_type_label, 
			   CASE WHEN nc.is_closed IS NOT NULL THEN nc.is_closed ELSE CASE WHEN NVL(i.open_issues, 0) > 0 THEN 0 ELSE 1 END END is_closed,
			   NVL(i.closed_issues, 0) closed_issues, nc.root_cause, nc.suggested_action,
			   NVL(i.open_issues, 0) open_issues, NVL(i.total_issues, 0) total_issues,
			   r.region_sid, r.description region_description,
			   NVL2(nc.non_compliance_ref, nct.inter_non_comp_ref_prefix || nc.non_compliance_ref, null) custom_non_compliance_id,
			   ncd.unique_reference def_non_comp_unique_ref, ia.custom_audit_id,
			   CASE WHEN anc.repeat_of_audit_nc_id IS NULL THEN 0 ELSE 1 END is_repeat,
			   ria.internal_audit_sid repeat_of_audit_sid, ria.label repeat_of_audit_label, ria.audit_dtm repeat_of_audit_dtm,
			   rnc.non_compliance_id repeat_of_non_compliance_id, rnc.label repeat_of_non_compliance_label,
			   CASE WHEN anc.internal_audit_sid = nc.created_in_audit_sid THEN 0 ELSE 1 END is_carry_forward,
			   CASE WHEN anc.internal_audit_sid = nc.created_in_audit_sid THEN NULL ELSE nc.label END carried_from_non_comp_label,
			   cfia.label carried_from_audit_label, cfia.internal_audit_sid carried_from_audit_sid, cfia.audit_dtm carried_from_audit_dtm
		  FROM TABLE(in_audit_nc_id_list) fil_list
		  JOIN audit_non_compliance anc ON fil_list.sid_id = anc.audit_non_compliance_id
		  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id AND nc.app_sid = anc.app_sid
		  JOIN v$audit ia ON anc.internal_audit_sid = ia.internal_audit_sid AND ia.app_sid = anc.app_sid
		  JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
		  LEFT JOIN v$region r ON NVL(nc.region_sid, ia.region_sid) = r.region_sid AND nc.app_sid = r.app_sid
		  JOIN (
			SELECT internal_audit_sid, survey_sid, survey_response_id, null internal_audit_type_survey_id 
			  FROM internal_audit
			 UNION
			SELECT internal_audit_sid, survey_sid, survey_response_id, internal_audit_type_survey_id 
			  FROM csr.internal_audit_survey
			) ias ON ias.internal_audit_sid = anc.internal_audit_sid
		   AND ((anc.internal_audit_type_survey_id IS NULL AND ias.internal_audit_type_survey_id IS NULL)
			OR (anc.internal_audit_type_survey_id = ias.internal_audit_type_survey_id))
		  LEFT JOIN quick_survey_response qsr ON ias.survey_sid = qsr.survey_sid AND ias.survey_response_id=qsr.survey_response_id
		  LEFT JOIN quick_survey_question qsq ON qsq.question_id = nc.question_id AND qsq.survey_version = qsr.survey_version
		  JOIN csr_user cc ON nc.created_by_user_sid = cc.csr_user_sid AND nc.app_sid = cc.app_sid
		  LEFT JOIN non_compliance_type nct ON nc.non_compliance_type_id = nct.non_compliance_type_id AND nc.app_sid = nct.app_sid
		  LEFT JOIN non_comp_default ncd ON nc.from_non_comp_default_id = ncd.non_comp_default_id AND nc.app_sid = ncd.app_sid
		  LEFT JOIN (
				SELECT inc.app_sid, inc.non_compliance_id,
					   COUNT(i.resolved_dtm) closed_issues, COUNT(*) total_issues,
					   COUNT(CASE WHEN i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id ELSE NULL END) open_issues
				  FROM issue_non_compliance inc, issue i
				 WHERE inc.app_sid = i.app_sid
				   AND inc.issue_non_compliance_id = i.issue_non_compliance_id
				   AND i.deleted = 0
				 GROUP BY inc.app_sid, inc.non_compliance_id
				) i ON nc.non_compliance_id = i.non_compliance_id AND nc.app_sid = i.app_sid
		  LEFT JOIN audit_non_compliance ranc ON ranc.audit_non_compliance_id = anc.repeat_of_audit_nc_id AND ranc.app_sid = anc.app_sid
		  LEFT JOIN non_compliance rnc ON rnc.non_compliance_id = ranc.non_compliance_id AND rnc.app_sid = ranc.app_sid
		  LEFT JOIN internal_audit ria ON ria.internal_audit_sid = ranc.internal_audit_sid AND ria.app_sid = ranc.app_sid
		  LEFT JOIN internal_audit cfia ON cfia.internal_audit_sid = nc.created_in_audit_sid AND cfia.internal_audit_sid != anc.internal_audit_sid AND cfia.app_sid = nc.app_sid
		 ORDER BY fil_list.pos;
		 
	OPEN out_tags_cur FOR
		SELECT nct.non_compliance_id, tg.tag_group_id, tg.name tag_group_name, t.tag_id, t.tag, tgm.pos
		  FROM TABLE(in_audit_nc_id_list) fil_list
		  JOIN audit_non_compliance anc ON fil_list.sid_id = anc.audit_non_compliance_id
		  JOIN non_compliance_tag nct ON anc.non_compliance_id = nct.non_compliance_id
		  JOIN tag_group_member tgm ON nct.tag_id = tgm.tag_id AND nct.app_sid = tgm.app_sid
		  JOIN v$tag t ON tgm.tag_id = t.tag_id AND tgm.app_sid = t.app_sid
		  JOIN v$tag_group tg ON tgm.tag_group_id = tg.tag_group_id AND tgm.app_sid = tg.app_sid
		 WHERE tg.applies_to_non_compliances = 1
		 ORDER BY tgm.tag_group_id, tgm.pos;
		 
	chain.filter_pkg.EndDebugLog(v_log_id);
END;


PROCEDURE PageFilteredAuditNCIds (
	in_audit_nc_id_list				IN	chain.T_FILTERED_OBJECT_TABLE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	out_audit_nc_id_list			OUT	security.T_ORDERED_SID_TABLE
)
AS	
	v_order_by						VARCHAR2(255);
	v_tag_group_id	 				NUMBER;
	v_has_id_prefix					NUMBER;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.non_compliance_report_pkg.PageFilteredAuditNCIds');
	
	v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
	v_tag_group_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);
	
	SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
	  INTO v_has_id_prefix
	  FROM non_compliance_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND inter_non_comp_ref_prefix IS NOT NULL;
	
	-- run the page fasted if sorting by the default, then split out any expensive joins, then sort by the rest
	IF in_order_by = 'nonComplianceId' AND in_order_dir='DESC' AND v_has_id_prefix = 0 THEN
		SELECT security.T_ORDERED_SID_ROW(object_id, rn)
		  BULK COLLECT INTO out_audit_nc_id_list
			  FROM (
				SELECT x.object_id, ROWNUM rn
				  FROM (
					SELECT object_id
					  FROM audit_non_compliance anc
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_audit_nc_id_list)) fil_list ON fil_list.object_id = anc.audit_non_compliance_id
					 ORDER BY non_compliance_id DESC, internal_audit_sid DESC
					) x 
				 WHERE ROWNUM <= in_end_row
				)
			  WHERE rn > in_start_row;
	ELSIF INSTR(in_order_by, '~', 1) > 0 THEN
		chain.filter_pkg.SortExtension(
					'noncompliance', 
					in_audit_nc_id_list,
					in_start_row,
					in_end_row,
					in_order_by,
					in_order_dir,
					out_audit_nc_id_list);
	ELSIF in_order_by = 'regionDescription' THEN
		SELECT security.T_ORDERED_SID_ROW(audit_non_compliance_id, rn)
		  BULK COLLECT INTO out_audit_nc_id_list
			  FROM (
				SELECT x.audit_non_compliance_id, ROWNUM rn
				  FROM (
					SELECT anc.audit_non_compliance_id
					  FROM audit_non_compliance anc
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_audit_nc_id_list)) fil_list ON fil_list.object_id = anc.audit_non_compliance_id
					  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id AND nc.app_sid = anc.app_sid
					  JOIN v$region r ON nc.region_sid = r.region_sid AND nc.app_sid = r.app_sid
					 ORDER BY
							-- To avoid dyanmic SQL, do many case statements
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								LOWER(r.description)
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								LOWER(r.description)
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN anc.non_compliance_id END DESC,
							CASE WHEN in_order_dir='DESC' THEN anc.non_compliance_id END ASC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN anc.internal_audit_sid END DESC,
							CASE WHEN in_order_dir='DESC' THEN anc.internal_audit_sid END ASC
					) x
				 WHERE ROWNUM <= in_end_row
				)
			  WHERE rn > in_start_row;
	ELSIF in_order_by IN ('isClosed','openIssues','closedIssues','totalIssues') THEN
		SELECT security.T_ORDERED_SID_ROW(audit_non_compliance_id, rn)
		  BULK COLLECT INTO out_audit_nc_id_list
			  FROM (
				SELECT x.audit_non_compliance_id, ROWNUM rn
				  FROM (
					SELECT anc.audit_non_compliance_id
					  FROM audit_non_compliance anc
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_audit_nc_id_list)) fil_list ON fil_list.object_id = anc.audit_non_compliance_id
					  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id AND nc.app_sid = anc.app_sid
					  LEFT JOIN (
						SELECT inc.app_sid, inc.non_compliance_id,
							   COUNT(i.resolved_dtm) closed_issues, COUNT(*) total_issues,
							   COUNT(CASE WHEN i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id ELSE NULL END) open_issues
						  FROM issue_non_compliance inc, issue i
						 WHERE inc.app_sid = i.app_sid
						   AND inc.issue_non_compliance_id = i.issue_non_compliance_id
						 GROUP BY inc.app_sid, inc.non_compliance_id
						) i ON nc.non_compliance_id = i.non_compliance_id AND nc.app_sid = i.app_sid
					 ORDER BY
							-- To avoid dyanmic SQL, do many case statements
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (v_order_by)
									WHEN 'isClosed' THEN TO_CHAR(CASE WHEN nc.is_closed IS NOT NULL THEN nc.is_closed ELSE CASE WHEN NVL(i.open_issues, 0) > 0 THEN 0 ELSE 1 END END)
									WHEN 'openIssues' THEN TO_CHAR(NVL(i.open_issues, 0), '0000000000')
									WHEN 'closedIssues' THEN TO_CHAR(NVL(i.closed_issues, 0), '0000000000')
									WHEN 'totalIssues' THEN TO_CHAR(NVL(i.total_issues, 0), '0000000000')
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (v_order_by)
									WHEN 'isClosed' THEN TO_CHAR(CASE WHEN nc.is_closed IS NOT NULL THEN nc.is_closed ELSE CASE WHEN NVL(i.open_issues, 0) > 0 THEN 0 ELSE 1 END END)
									WHEN 'openIssues' THEN TO_CHAR(NVL(i.open_issues, 0), '0000000000')
									WHEN 'closedIssues' THEN TO_CHAR(NVL(i.closed_issues, 0), '0000000000')
									WHEN 'totalIssues' THEN TO_CHAR(NVL(i.total_issues, 0), '0000000000')
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN anc.non_compliance_id END DESC,
							CASE WHEN in_order_dir='DESC' THEN anc.non_compliance_id END ASC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN anc.internal_audit_sid END DESC,
							CASE WHEN in_order_dir='DESC' THEN anc.internal_audit_sid END ASC
					) x
				 WHERE ROWNUM <= in_end_row
				)
			  WHERE rn > in_start_row;
	ELSIF in_order_by IN ('isRepeat', 'repeatOfNonComplianceLabel') THEN
		SELECT security.T_ORDERED_SID_ROW(audit_non_compliance_id, rn)
		  BULK COLLECT INTO out_audit_nc_id_list
			  FROM (
				SELECT x.audit_non_compliance_id, ROWNUM rn
				  FROM (
					SELECT anc.audit_non_compliance_id
					  FROM audit_non_compliance anc
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_audit_nc_id_list)) fil_list ON fil_list.object_id = anc.audit_non_compliance_id
					  LEFT JOIN audit_non_compliance ranc ON ranc.audit_non_compliance_id = anc.repeat_of_audit_nc_id
					  LEFT JOIN non_compliance rnc ON rnc.non_compliance_id = ranc.non_compliance_id
					 ORDER BY
							-- To avoid dyanmic SQL, do many case statements
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (v_order_by)
									WHEN 'isRepeat' THEN TO_CHAR(ranc.non_compliance_id)
									WHEN 'repeatOfNonComplianceLabel' THEN rnc.label
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (v_order_by)
									WHEN 'isRepeat' THEN TO_CHAR(ranc.non_compliance_id)
									WHEN 'repeatOfNonComplianceLabel' THEN rnc.label
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN anc.non_compliance_id END DESC,
							CASE WHEN in_order_dir='DESC' THEN anc.non_compliance_id END ASC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN anc.internal_audit_sid END DESC,
							CASE WHEN in_order_dir='DESC' THEN anc.internal_audit_sid END ASC
					) x
				 WHERE ROWNUM <= in_end_row
				)
			  WHERE rn > in_start_row;
	ELSE
		SELECT security.T_ORDERED_SID_ROW(audit_non_compliance_id, rn)
		  BULK COLLECT INTO out_audit_nc_id_list
			  FROM (
				SELECT x.audit_non_compliance_id, ROWNUM rn
				  FROM (
					SELECT anc.audit_non_compliance_id
					  FROM audit_non_compliance anc
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_audit_nc_id_list)) fil_list ON fil_list.object_id = anc.audit_non_compliance_id
					  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id AND nc.app_sid = anc.app_sid
					  JOIN internal_audit ia ON ia.internal_audit_sid = anc.internal_audit_sid AND ia.app_sid = anc.app_sid
					  JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
					  LEFT JOIN quick_survey_response qsr ON ia.survey_sid = qsr.survey_sid AND ia.survey_response_id=qsr.survey_response_id
					  LEFT JOIN quick_survey_question qsq ON qsq.question_id = nc.question_id AND qsq.survey_version = qsr.survey_version
					  JOIN csr_user cc ON nc.created_by_user_sid = cc.csr_user_sid AND nc.app_sid = cc.app_sid
					  LEFT JOIN non_compliance_type nct ON nc.non_compliance_type_id = nct.non_compliance_type_id
					  LEFT JOIN (
						SELECT onct.non_compliance_id, onct.tag_group_id, stragg(onct.tag) tags
						  FROM (
							SELECT nct.non_compliance_id, tgm.tag_group_id, t.tag
							  FROM non_compliance_tag nct
							  JOIN tag_group_member tgm ON nct.tag_id = tgm.tag_id AND nct.app_sid = tgm.app_sid
							  JOIN v$tag t ON tgm.tag_id = t.tag_id AND tgm.app_sid = t.app_sid
							 WHERE tgm.tag_group_id = v_tag_group_id
							 ORDER BY tgm.tag_group_id, tgm.pos
						  ) onct
						 GROUP BY onct.non_compliance_id, onct.tag_group_id
						) nt ON nc.non_compliance_id = nt.non_compliance_id
					 ORDER BY
							-- To avoid dyanmic SQL, do many case statements
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (v_order_by)
									WHEN 'nonComplianceId' THEN NVL2(nc.non_compliance_ref, nct.inter_non_comp_ref_prefix || nc.non_compliance_ref, TO_CHAR(nc.non_compliance_id, '0000000000'))								
									WHEN 'label' THEN LOWER(nc.label)
									WHEN 'nonComplianceTypeLabel' THEN LOWER(nct.label)
									WHEN 'detail' THEN LOWER(DBMS_LOB.SUBSTR(nc.detail, 1000, 1))
									WHEN 'rootCause' THEN LOWER(DBMS_LOB.SUBSTR(nc.root_cause, 1000, 1))
									WHEN 'suggestedAction' THEN LOWER(DBMS_LOB.SUBSTR(nc.suggested_action, 1000, 1))
									WHEN 'auditLabel' THEN LOWER(ia.label)
									WHEN 'auditTypeLabel' THEN LOWER(iat.label)
									WHEN 'auditDtm' THEN TO_CHAR(ia.audit_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'questionLabel' THEN LOWER(qsq.label)
									WHEN 'createdByFullName' THEN LOWER(cc.full_name)
									WHEN 'createdDtm' THEN TO_CHAR(nc.created_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'tagGroup' THEN LOWER(nt.tags)
									WHEN 'isCarryForward' THEN CASE WHEN anc.internal_audit_sid = nc.created_in_audit_sid THEN '0' ELSE '1' END
									WHEN 'carriedFromNonComplianceLabel' THEN CASE WHEN anc.internal_audit_sid != nc.created_in_audit_sid THEN LOWER(nc.label) END
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (v_order_by)
									WHEN 'nonComplianceId' THEN NVL2(nc.non_compliance_ref, nct.inter_non_comp_ref_prefix || nc.non_compliance_ref, TO_CHAR(nc.non_compliance_id, '0000000000'))
									WHEN 'label' THEN LOWER(nc.label)
									WHEN 'nonComplianceTypeLabel' THEN LOWER(nct.label)
									WHEN 'detail' THEN LOWER(DBMS_LOB.SUBSTR(nc.detail, 1000, 1))
									WHEN 'rootCause' THEN LOWER(DBMS_LOB.SUBSTR(nc.root_cause, 1000, 1))
									WHEN 'suggestedAction' THEN LOWER(DBMS_LOB.SUBSTR(nc.suggested_action, 1000, 1))
									WHEN 'auditLabel' THEN LOWER(ia.label)
									WHEN 'auditTypeLabel' THEN LOWER(iat.label)
									WHEN 'auditDtm' THEN TO_CHAR(ia.audit_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'questionLabel' THEN LOWER(qsq.label)
									WHEN 'createdByFullName' THEN LOWER(cc.full_name)
									WHEN 'createdDtm' THEN TO_CHAR(nc.created_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'tagGroup' THEN LOWER(nt.tags)
									WHEN 'isCarryForward' THEN CASE WHEN anc.internal_audit_sid = nc.created_in_audit_sid THEN '0' ELSE '1' END
									WHEN 'carriedFromNonComplianceLabel' THEN CASE WHEN anc.internal_audit_sid != nc.created_in_audit_sid THEN LOWER(nc.label) END
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN anc.non_compliance_id END DESC,
							CASE WHEN in_order_dir='DESC' THEN anc.non_compliance_id END ASC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN anc.internal_audit_sid END DESC,
							CASE WHEN in_order_dir='DESC' THEN anc.internal_audit_sid END ASC
					) x
				 WHERE ROWNUM <= in_end_row
				)
			  WHERE rn > in_start_row;
	END IF;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE INTERNAL_NonCompSidsToCoSids(
	in_non_comp_sids				IN security.T_ORDERED_SID_TABLE
)
AS
BEGIN

	INSERT INTO chain.temp_grid_extension_map gem (source_id, linked_type, linked_id)
			SELECT DISTINCT  sids.sid_id, chain.filter_pkg.FILTER_TYPE_COMPANIES, s.company_sid
				  FROM TABLE(in_non_comp_sids) sids
				  JOIN csr.audit_non_compliance anc ON sids.sid_id = anc.audit_non_compliance_id
				  JOIN csr.internal_audit ia ON anc.internal_audit_sid = ia.internal_audit_sid
				  JOIN csr.supplier s ON s.region_sid = ia.region_sid;

END;

PROCEDURE INTERNAL_NonCompSidsToAudSids(
	in_non_comp_sids				IN security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	INSERT INTO chain.temp_grid_extension_map gem (source_id, linked_type, linked_id)
		SELECT DISTINCT sids.sid_id, chain.filter_pkg.FILTER_TYPE_AUDITS, anc.internal_audit_sid
		  FROM TABLE(in_non_comp_sids) sids
		  JOIN audit_non_compliance anc ON sids.sid_id = anc.audit_non_compliance_id;

END;

PROCEDURE INT_NonCompSidsToBsciSupIds(
	in_non_comp_sids				IN security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	INSERT INTO chain.temp_grid_extension_map gem (source_id, linked_type, linked_id)
	SELECT anc.audit_non_compliance_id, chain.filter_pkg.FILTER_TYPE_BSCI_SUPPLIERS, bs.bsci_supplier_id
		FROM TABLE(in_non_comp_sids) sids 
		JOIN csr.audit_non_compliance anc ON sids.sid_id = anc.audit_non_compliance_id
		JOIN csr.internal_audit ia ON anc.internal_audit_sid = ia.internal_audit_sid
		JOIN csr.supplier s ON s.region_sid = ia.region_sid
		JOIN chain.v$bsci_supplier bs ON bs.company_sid = s.company_sid;
END;

PROCEDURE INTERNAL_NCSidsToBsci2009AuIds(
	in_non_comp_sids				IN security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	INSERT INTO chain.temp_grid_extension_map gem (source_id, linked_type, linked_id)
	SELECT anc.audit_non_compliance_id, chain.filter_pkg.FILTER_TYPE_BSCI_2009_AUDITS, ba.bsci_2009_audit_id
		FROM TABLE(in_non_comp_sids) sids 
		JOIN csr.audit_non_compliance anc ON sids.sid_id = anc.audit_non_compliance_id
		JOIN csr.internal_audit ia ON ia.internal_audit_sid = anc.internal_audit_sid
		JOIN chain.v$bsci_2009_audit ba ON ba.internal_audit_sid = ia.internal_audit_sid;
END;

PROCEDURE INTERNAL_NCSidsToBsci2014AuIds(
	in_non_comp_sids				IN security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	INSERT INTO chain.temp_grid_extension_map gem (source_id, linked_type, linked_id)
	SELECT anc.audit_non_compliance_id, chain.filter_pkg.FILTER_TYPE_BSCI_2014_AUDITS, ba.bsci_2014_audit_id
		FROM TABLE(in_non_comp_sids) sids 
		JOIN csr.audit_non_compliance anc ON sids.sid_id = anc.audit_non_compliance_id
		JOIN csr.internal_audit ia ON ia.internal_audit_sid = anc.internal_audit_sid
		JOIN chain.v$bsci_2014_audit ba ON ba.internal_audit_sid = ia.internal_audit_sid;
END;

PROCEDURE INTERNAL_NCSidsToBsciExtAuIds(
	in_non_comp_sids				IN security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	INSERT INTO chain.temp_grid_extension_map gem (source_id, linked_type, linked_id)
	SELECT anc.audit_non_compliance_id, chain.filter_pkg.FILTER_TYPE_BSCI_EXT_AUDITS, ba.bsci_ext_audit_id
		FROM TABLE(in_non_comp_sids) sids 
		JOIN csr.audit_non_compliance anc ON sids.sid_id = anc.audit_non_compliance_id
		JOIN csr.internal_audit ia ON ia.internal_audit_sid = anc.internal_audit_sid
		JOIN chain.v$bsci_ext_audit ba ON ba.internal_audit_sid = ia.internal_audit_sid;
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

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		IF v_extension_id = chain.filter_pkg.FILTER_TYPE_COMPANIES THEN
			INTERNAL_NonCompSidsToCoSids(in_id_page);
		ELSIF v_extension_id = chain.filter_pkg.FILTER_TYPE_BSCI_SUPPLIERS THEN
			INT_NonCompSidsToBsciSupIds(in_id_page);
		ELSIF v_extension_id = chain.filter_pkg.FILTER_TYPE_AUDITS THEN
			INTERNAL_NonCompSidsToAudSids(in_id_page);
		ELSIF v_extension_id = chain.filter_pkg.FILTER_TYPE_BSCI_2009_AUDITS THEN
			INTERNAL_NCSidsToBsci2009AuIds(in_id_page);
		ELSIF v_extension_id = chain.filter_pkg.FILTER_TYPE_BSCI_2014_AUDITS THEN
			INTERNAL_NCSidsToBsci2014AuIds(in_id_page);
		ELSIF v_extension_id = chain.filter_pkg.FILTER_TYPE_BSCI_EXT_AUDITS THEN
			INTERNAL_NCSidsToBsciExtAuIds(in_id_page);
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Audit Finding -> '||v_name);
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
	in_id_list_populated			IN  NUMBER DEFAULT 0,
	in_session_prefix				IN	VARCHAR2 DEFAULT NULL,
	out_total_rows					OUT	NUMBER,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_tags_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.non_compliance_report_pkg.GetList', in_compound_filter_id);
	
	GetFilteredIds(
		in_search				=> in_search,
		in_group_key			=> in_group_key,
		in_pre_filter_sid		=> in_pre_filter_sid,
		in_compound_filter_id	=> in_compound_filter_id,
		in_region_sids			=> v_region_sids,
		in_start_dtm			=> in_start_dtm,
		in_end_dtm				=> in_end_dtm,
		in_region_col_type		=> in_region_col_type,
		in_date_col_type		=> in_date_col_type,
		in_parent_id			=> in_parent_id,
		out_id_list				=> v_id_list
	);
	
	ApplyBreadcrumb(v_id_list, in_group_key, in_breadcrumb, in_aggregation_type, v_id_list);
	
	-- Get the total number of rows (to work out number of pages)
	SELECT COUNT(DISTINCT object_id)
	  INTO out_total_rows
	  FROM TABLE(v_id_list);
	
	PageFilteredAuditNCIds(v_id_list, in_start_row, in_end_row, in_order_by, in_order_dir, v_id_page);
	
	INTERNAL_PopGridExtTempTable(v_id_page);

	-- Return a page of results
	CollectSearchResults(v_id_page, out_cur, out_tags_cur);
	
	chain.filter_pkg.EndDebugLog(v_log_id);
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.non_compliance_report_pkg.GetReportData', in_compound_filter_id);
	
	GetFilteredIds(
		in_search				=> in_search,
		in_group_key			=> in_group_key,
		in_pre_filter_sid		=> in_pre_filter_sid,
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
		RunCompoundFilter(in_grp_by_compound_filter_id, in_group_key, 1, in_max_group_by, v_id_list, v_id_list);
	END IF;
	
	GetFilterObjectData(in_aggregation_types, v_id_list);
	
	IF in_aggregation_types.COUNT > 0 THEN
		v_aggregation_type := in_aggregation_types(1);
	END IF;
	
	v_top_n_values := chain.filter_pkg.FindTopN(in_grp_by_compound_filter_id, v_aggregation_type, v_id_list, in_breadcrumb, in_max_group_by);
	
	chain.filter_pkg.GetAggregateData(chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);
	
	chain.filter_pkg.GetEmptyExtraSeriesCur(out_extra_series_cur);
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetAlertData (
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- No security - should only be called by filter_pkg with an already security-trimmed
	OPEN out_cur FOR
		SELECT t.object_id, nc.non_compliance_id, nc.label, nc.detail,
			   nc.root_cause, r.description region_description,
			   NVL2(nc.non_compliance_ref, nct.inter_non_comp_ref_prefix || nc.non_compliance_ref, null) custom_non_compliance_id,
			   ia.audit_dtm, ia.label audit_label,
			   '/csr/site/audit/auditDetail.acds?sid='||ia.internal_audit_sid audit_url,
			   nct.label non_compliance_type_label,
			   iat.label audit_type_label
		  FROM audit_non_compliance anc
		  JOIN TABLE(in_id_list) t ON anc.audit_non_compliance_id = t.object_id
		  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
		  JOIN v$region r ON nc.region_sid = r.region_sid
		  JOIN internal_audit ia ON anc.internal_audit_sid = ia.internal_audit_sid
		  JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id
		  LEFT JOIN non_compliance_type nct ON nc.non_compliance_type_id = nct.non_compliance_type_id;
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
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_tags_cur					OUT	security_pkg.T_OUTPUT_CUR
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
		in_compound_filter_id	=> in_compound_filter_id,
		in_region_sids			=> v_region_sids,
		in_start_dtm			=> in_start_dtm,
		in_end_dtm				=> in_end_dtm,
		in_region_col_type		=> in_region_col_type,
		in_date_col_type		=> in_date_col_type,
		in_parent_id			=> in_parent_id,
		out_id_list				=> v_id_list
	);
	
	ApplyBreadcrumb(v_id_list, in_group_key, in_breadcrumb, in_aggregation_type, v_id_list);
	
	SELECT security.T_ORDERED_SID_ROW(object_id, rownum)
	  BULK COLLECT INTO v_id_page
	  FROM (
		SELECT DISTINCT object_id
		  FROM TABLE(v_id_list)
	);
	
	INTERNAL_PopGridExtTempTable(v_id_page);

	CollectSearchResults(v_id_page, out_cur, out_tags_cur);	
END;

PROCEDURE GetListAsExtension(
	in_compound_filter_id			IN chain.compound_filter.compound_filter_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_tags_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.non_compliance_report_pkg.GetListAsExtension', in_compound_filter_id);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
			SELECT linked_id
			  FROM chain.temp_grid_extension_map
			 WHERE linked_type = chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES
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
		in_audit_nc_id_list			=> v_id_page,
		out_cur 					=> out_cur,
		out_tags_cur				=> out_tags_cur
	);
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

/********************************************/
/*		Filter field units					*/
/********************************************/

/*  Each filter unit must:
 *   o  Filter the list of in_ids into the out_ids based on the user's selected values for the given in_filter_field_id
 *   o  Pre-populate all possible values if in_show_all = 1
 *   o  Preserve existing duplicate IDs passed in (these are likely to have different group by values caused by overlapping values that need to be represented in charts)
 *  
 *  It's OK to return duplicate IDs if filter field values overlap. These duplicates are discounted for issue lists
 *  but required for charts to work correctly. Each filter field unit must preserve existing duplicate issue ids that are
 *  passed in.
 */

PROCEDURE FilterRegionSid (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_region_root_sid				security_pkg.T_SID_ID;
	v_region_count					NUMBER;
BEGIN
	
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, region_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, n.region_sid
		  FROM (
			SELECT nc.region_sid
			  FROM audit_non_compliance anc
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
			  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
			 WHERE nc.region_sid IS NOT NULL
			 GROUP BY nc.region_sid
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.region_sid = n.region_sid
		 );
		 		
		-- if show_all is on, we don't want to aggregate (otherwise the data is a mess)
		SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, in_group_by_index, anc.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT anc.audit_non_compliance_id, fv.filter_value_id
			  FROM audit_non_compliance anc
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
			  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
			  JOIN chain.filter_value fv ON nc.region_sid= fv.region_sid 
			 WHERE fv.filter_field_id = in_filter_field_id
		) anc;
	ELSE		
		-- check to see if the root region is in the filter, if so there's no point in running the unit
		SELECT region_root_sid
		  INTO v_region_root_sid
		  FROM customer;
		
		SELECT COUNT(*)
		  INTO v_region_count
		  FROM chain.filter_value
		 WHERE filter_field_id = in_filter_field_id
		   AND region_sid = v_region_root_sid;
		
		IF v_region_count > 0 THEN
			-- filter contains the root region sid so pass through without looking
			out_ids := in_ids;
			RETURN;
		END IF;
		
		-- if show_all is off, users have specified the regions they want, they'll
		-- expect to get region aggregation
		SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, in_group_by_index, r.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM audit_non_compliance anc
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
		  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
		  JOIN (
				SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid, connect_by_root ff.filter_value_id filter_value_id
				  FROM region r
				  JOIN chain.filter_value ff ON ff.filter_field_id = in_filter_field_id
				 START WITH r.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND r.region_sid = ff.region_sid
			   CONNECT BY PRIOR r.app_sid = r.app_sid
				   AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
				   AND PRIOR ff.filter_value_id = ff.filter_value_id
			 ) r ON nc.region_sid = r.region_sid;
	END IF;	
END;


PROCEDURE FilterAuditSid (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, n.internal_audit_sid, SUBSTR(n.label, 0, 255)
		  FROM (
			SELECT anc.internal_audit_sid, ia.label
			  FROM audit_non_compliance anc
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
			  JOIN internal_audit ia ON ia.internal_audit_sid = anc.internal_audit_sid
			 GROUP BY anc.internal_audit_sid, ia.label
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = n.internal_audit_sid
		 );
	END IF;
		
	SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, in_group_by_index, anc.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (
		SELECT DISTINCT anc.audit_non_compliance_id, fv.filter_value_id
		  FROM audit_non_compliance anc
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
		  JOIN chain.filter_value fv ON anc.internal_audit_sid = fv.num_value 
		 WHERE fv.filter_field_id = in_filter_field_id
	) anc;
END;

PROCEDURE FilterAuditDtm (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(ia.audit_dtm), MAX(ia.audit_dtm)
		  INTO v_min_date, v_max_date
		  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t 
		  JOIN audit_non_compliance anc ON anc.audit_non_compliance_id = t.object_id
		  JOIN internal_audit ia ON anc.internal_audit_sid = ia.internal_audit_sid
		 WHERE ia.audit_dtm IS NOT NULL;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
	END IF;
	
	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 0
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM audit_non_compliance anc
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
	  JOIN internal_audit ia ON anc.internal_audit_sid = ia.internal_audit_sid
	  JOIN chain.tt_filter_date_range dr 
		ON ia.audit_dtm >= NVL(dr.start_dtm, ia.audit_dtm)
	   AND (dr.end_dtm IS NULL OR ia.audit_dtm < dr.end_dtm)
	 WHERE ia.audit_dtm IS NOT NULL;
END;

PROCEDURE FilterClosedStatus (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_colour_when_open				non_compliance_type.colour_when_open%TYPE;
	v_colour_when_closed			non_compliance_type.colour_when_closed%TYPE;
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, o.is_closed, o.description
		  FROM (
			SELECT 1 is_closed, 'Closed' description FROM dual
			UNION ALL SELECT 0, 'Open' FROM dual
		  ) o
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = o.is_closed
		 );		
	END IF;
	
	UPDATE chain.filter_value
	   SET pos = 1
	 WHERE num_value = 0
	   AND (pos IS NULL OR pos != 1)
	   AND filter_field_id = in_filter_field_id;
	   
	UPDATE chain.filter_value
	   SET pos = 2
	 WHERE num_value = 1
	   AND (pos IS NULL OR pos != 2)
	   AND filter_field_id = in_filter_field_id;
	
	-- set the colours if all non-compliace types in use have the same colours for open/closed
	SELECT CASE WHEN COUNT(*) = 1 THEN MIN(colour_when_open) ELSE NULL END, 
	       CASE WHEN COUNT(*) = 1 THEN MIN(colour_when_closed) ELSE NULL END
	  INTO v_colour_when_open, v_colour_when_closed
	  FROM (
		SELECT nct.colour_when_open, nct.colour_when_closed
		  FROM audit_non_compliance anc
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
		  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
		  JOIN non_compliance_type nct ON nc.non_compliance_type_id = nct.non_compliance_type_id
		 GROUP BY nct.colour_when_open, nct.colour_when_closed
	  );

	UPDATE chain.filter_value
	   SET colour = v_colour_when_open
	 WHERE num_value = 0
	   AND DECODE(colour, v_colour_when_open, 1, 0) = 0
	   AND filter_field_id = in_filter_field_id;
	   
	UPDATE chain.filter_value
	   SET colour = v_colour_when_closed
	 WHERE num_value = 1
	   AND DECODE(colour, v_colour_when_closed, 1, 0) = 0
	   AND filter_field_id = in_filter_field_id;

	SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM audit_non_compliance anc
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
	  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
	  LEFT JOIN (
		SELECT non_compliance_id, COUNT(CASE WHEN i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id ELSE NULL END) open_issues
		  FROM issue_non_compliance inc
		  JOIN issue i ON inc.app_sid = i.app_sid AND inc.issue_non_compliance_id = i.issue_non_compliance_id
		 WHERE i.deleted = 0
		 GROUP BY inc.app_sid, inc.non_compliance_id
		) i ON nc.non_compliance_id = i.non_compliance_id
	  JOIN chain.filter_value fv ON ((nc.is_closed IS NOT NULL AND nc.is_closed = fv.num_value) OR (nc.is_closed IS NULL AND ((fv.num_value = 1 AND NVL(i.open_issues, 0) = 0) OR (fv.num_value = 0 AND NVL(i.open_issues, 0) > 0))))
	 WHERE fv.filter_field_id = in_filter_field_id;
	
END;

PROCEDURE FilterNCsOpenActions (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, o.open_ncs, o.description
		  FROM (
			SELECT 1 open_ncs, 'Findings with open actions' description FROM dual
			UNION ALL SELECT 0, 'Findings with no open actions' FROM dual
		  ) o
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = o.open_ncs
		 );
		
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM audit_non_compliance anc
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
	  LEFT JOIN (
		SELECT non_compliance_id, COUNT(CASE WHEN i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id ELSE NULL END) open_issues
		  FROM issue_non_compliance inc
		  JOIN issue i ON inc.app_sid = i.app_sid AND inc.issue_non_compliance_id = i.issue_non_compliance_id
		 WHERE i.deleted = 0
		 GROUP BY inc.app_sid, inc.non_compliance_id
		) i ON anc.non_compliance_id = i.non_compliance_id
	  JOIN chain.filter_value fv ON ((fv.num_value = 1 AND NVL(i.open_issues, 0) > 0) OR (fv.num_value = NVL(i.open_issues, 0)))
	 WHERE fv.filter_field_id = in_filter_field_id;
	
END;

PROCEDURE FilterCreatedDtm (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(nc.created_dtm), MAX(nc.created_dtm)
		  INTO v_min_date, v_max_date
		  FROM audit_non_compliance anc
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
		  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
		
	END IF;
	
	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM audit_non_compliance anc
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
	  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
	  JOIN chain.tt_filter_date_range dr 
	    ON nc.created_dtm >= NVL(dr.start_dtm, nc.created_dtm) 
	   AND (dr.end_dtm IS NULL OR nc.created_dtm < dr.end_dtm);
END;

PROCEDURE FilterCreatedByUserSid (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, user_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, nc.created_by_user_sid
		  FROM (
			SELECT DISTINCT created_by_user_sid
			  FROM audit_non_compliance anc
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
			  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
			  ) nc
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.user_sid = nc.created_by_user_sid
		 );
		
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM audit_non_compliance anc
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
	  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
	  JOIN chain.filter_value fv
		ON fv.user_sid = nc.created_by_user_sid
		OR (in_show_all = 0 AND fv.user_sid = chain.filter_pkg.USER_ME AND nc.created_by_user_sid = SYS_CONTEXT('SECURITY', 'SID'))
	 WHERE fv.filter_field_id = in_filter_field_id;		
END;

PROCEDURE FilterCarryForward (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, o.is_carry_forward, o.description
		  FROM (
			SELECT 1 is_carry_forward, 'Carried forward' description FROM dual
			UNION ALL SELECT 0, 'Not carried forward' FROM dual
		  ) o
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = o.is_carry_forward
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM audit_non_compliance anc
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
	  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
	  JOIN chain.filter_value fv
		ON ((fv.num_value = 0 AND anc.internal_audit_sid = nc.created_in_audit_sid) OR
			(fv.num_value = 1 AND anc.internal_audit_sid != nc.created_in_audit_sid))
	 WHERE fv.filter_field_id = in_filter_field_id
	 GROUP BY anc.audit_non_compliance_id, fv.filter_value_id;		
END;

PROCEDURE FilterRepeat (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, o.is_repeat, o.description
		  FROM (
			SELECT 1 is_repeat, 'Repeat' description FROM dual
			UNION ALL SELECT 0, 'Not repeat' FROM dual
		  ) o
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = o.is_repeat
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM audit_non_compliance anc
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
	  JOIN chain.filter_value fv
		ON ((fv.num_value = 0 AND anc.repeat_of_audit_nc_id IS NULL) OR
			(fv.num_value = 1 AND anc.repeat_of_audit_nc_id IS NOT NULL))
	 WHERE fv.filter_field_id = in_filter_field_id
	 GROUP BY anc.audit_non_compliance_id, fv.filter_value_id;		
END;

PROCEDURE FilterNonComplianceTypeId (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_audit_type_group_key			IN  internal_audit_type_group.lookup_key%TYPE,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description, pos)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, nct.non_compliance_type_id, nct.label, nct.position
		  FROM (
			SELECT nct.non_compliance_type_id, nct.label, nct.position
			  FROM non_compliance_type nct
			  JOIN non_comp_type_audit_type nctat ON nct.non_compliance_type_id = nctat.non_compliance_type_id
			  JOIN internal_audit_type iat ON nctat.internal_audit_type_id = iat.internal_audit_type_id
			  LEFT JOIN internal_audit_type_group atg ON iat.internal_audit_type_group_id = atg.internal_audit_type_group_id
			 WHERE iat.app_sid = SYS_CONTEXT('SECURITY','APP')
			   AND (in_audit_type_group_key IS NULL OR (LOWER(atg.lookup_key) = LOWER(in_audit_type_group_key)))
			 GROUP BY nct.non_compliance_type_id, nct.label, nct.position
			 UNION
			 SELECT 0, 'Other', 999999
			   FROM dual 
			  WHERE EXISTS (
				SELECT * 
				  FROM non_compliance
				 WHERE non_compliance_type_id IS NULL
				)
			) nct
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = nct.non_compliance_type_id
		 );
	END IF;
	
	FOR r IN (
		SELECT * FROM (
			SELECT filter_value_id, pos, ROWNUM rn
			  FROM (
				SELECT fv.filter_value_id, MIN(fv.pos) pos
				  FROM chain.filter_value fv
				  JOIN non_compliance_type t ON fv.num_value = t.non_compliance_type_id
				 WHERE fv.filter_field_id = in_filter_field_id
				 GROUP BY fv.filter_value_id
				 ORDER BY MIN(t.position)
				)
			)
		 WHERE DECODE(pos, rn, 1, 0) = 0
	) LOOP
		UPDATE chain.filter_value
		   SET pos = r.rn
		 WHERE filter_value_id = r.filter_value_id;
	END LOOP; 

	SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM audit_non_compliance anc
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
	  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
	  JOIN chain.filter_value fv ON ((fv.num_value = 0 AND nc.non_compliance_type_id IS NULL) OR nc.non_compliance_type_id = fv.num_value)
	 WHERE fv.filter_field_id = in_filter_field_id;
	
END;

PROCEDURE FilterQuestionId (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name			IN  chain.filter_field.name%TYPE,
	in_audit_type_group_key			IN  internal_audit_type_group.lookup_key%TYPE,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_survey_sid	 				NUMBER;
	v_survey_version				quick_survey_version.survey_version%TYPE;
BEGIN
	v_survey_sid := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);
	v_survey_version := quick_survey_pkg.GetSurveyVersion(v_survey_sid);
	
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, qsq.question_id, SUBSTR(qsq.label,1,200)
		  FROM (
			SELECT DISTINCT qsq.question_id, qsq.label
			  FROM non_compliance nc
			  JOIN audit_non_compliance anc ON nc.non_compliance_id = anc.non_compliance_id
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
			  JOIN quick_survey_question qsq ON nc.app_sid = qsq.app_sid AND nc.question_id = qsq.question_id AND qsq.survey_version = v_survey_version
			 WHERE qsq.survey_sid = v_survey_sid
			  ) qsq
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = qsq.question_id
		 );

		SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, in_group_by_index, fv.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM audit_non_compliance anc
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
		  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
		  JOIN chain.filter_value fv
			ON fv.num_value = nc.question_id
		 WHERE fv.filter_field_id = in_filter_field_id;	
	
	ELSE
		SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, in_group_by_index, qsq.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM audit_non_compliance anc
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
		  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
		  JOIN (
				SELECT qsq.question_id, connect_by_root ff.filter_value_id filter_value_id
				  FROM quick_survey_question qsq
				  JOIN chain.filter_value ff ON ff.filter_field_id = in_filter_field_id
				 START WITH qsq.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND qsq.question_id = ff.num_value AND qsq.survey_version = v_survey_version
			   CONNECT BY PRIOR qsq.app_sid = qsq.app_sid
				   AND PRIOR qsq.question_id = qsq.parent_id
				   AND PRIOR qsq.survey_version = qsq.survey_version
				   AND PRIOR ff.filter_value_id = ff.filter_value_id
			 ) qsq ON nc.question_id = qsq.question_id;		
	END IF;
END;

PROCEDURE FilterDefaultNonCompId (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_audit_type_group_key			IN  internal_audit_type_group.lookup_key%TYPE,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN	
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, n.non_comp_default_id, SUBSTR(n.label,1,255)
		  FROM (
			SELECT ncd.non_comp_default_id, ncd.label
			  FROM audit_non_compliance anc
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
			  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
			  JOIN non_comp_default ncd ON nc.from_non_comp_default_id = ncd.non_comp_default_id
			  JOIN audit_type_non_comp_default atncd ON ncd.non_comp_default_id = atncd.non_comp_default_id
			  JOIN internal_audit_type iat ON atncd.internal_audit_type_id = iat.internal_audit_type_id
			  LEFT JOIN internal_audit_type_group atg ON iat.internal_audit_type_group_id = atg.internal_audit_type_group_id
			 WHERE (in_audit_type_group_key IS NULL OR (LOWER(atg.lookup_key) = LOWER(in_audit_type_group_key)))
			 GROUP BY ncd.non_comp_default_id, ncd.label
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = n.non_comp_default_id
		 );
		
		-- if show_all is on, we don't want to aggregate to folders
		SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, in_group_by_index, anc.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT anc.audit_non_compliance_id, fv.filter_value_id
			  FROM audit_non_compliance anc
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
			  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
			  JOIN chain.filter_value fv ON nc.from_non_comp_default_id= fv.num_value 
			 WHERE fv.filter_field_id = in_filter_field_id
		) anc;
	ELSE
		
		-- if show_all is off, users have specified either DNCs or DNC folders, so check both
		SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, in_group_by_index, d.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM audit_non_compliance anc
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
		  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
		  JOIN (
				SELECT ff.num_value non_comp_default_id, ff.filter_value_id
				  FROM chain.filter_value ff
				 WHERE ff.filter_field_id = in_filter_field_id
				 UNION
				SELECT ncd.non_comp_default_id, f.filter_value_id
				  FROM non_comp_default ncd
				  JOIN (
					SELECT ncdf.non_comp_default_folder_id, connect_by_root ff.filter_value_id filter_value_id
					  FROM non_comp_default_folder ncdf
					  JOIN chain.filter_value ff ON ff.filter_field_id = in_filter_field_id
					 START WITH ncdf.non_comp_default_folder_id = -ff.num_value
				   CONNECT BY PRIOR ncdf.non_comp_default_folder_id = ncdf.parent_folder_id AND PRIOR ncdf.app_sid = ncdf.app_sid
				   ) f ON ncd.non_comp_default_folder_id = f.non_comp_default_folder_id
				 WHERE rownum > 0 -- materialize sub-query
			 ) d ON nc.from_non_comp_default_id = d.non_comp_default_id;
	END IF;	
END;

PROCEDURE FilterTag (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name			IN  chain.filter_field.name%TYPE,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_tag_group_id	 				NUMBER;
BEGIN
	v_tag_group_id := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);
	
	IF in_show_all = 1 THEN
		chain.filter_pkg.ShowAllTags(in_filter_field_id, v_tag_group_id);
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM audit_non_compliance anc
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
	  LEFT JOIN non_compliance_tag nct ON anc.non_compliance_id = nct.non_compliance_id 
	   AND nct.tag_id IN (SELECT tag_id FROM tag_group_member WHERE tag_group_id = v_tag_group_id)
	  JOIN chain.filter_value fv ON nct.tag_id = fv.num_value
		OR (nct.tag_id IS NULL AND fv.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL)
	 WHERE fv.filter_field_id = in_filter_field_id;
	
END;

PROCEDURE FilterSavedFilter (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_audit_type_group_key			IN  internal_audit_type_group.lookup_key%TYPE,
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
				in_group_key					=> in_audit_type_group_key,
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
				in_group_key					=> in_audit_type_group_key,
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

PROCEDURE FilterAudits (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_audit_type_group_key			IN  internal_audit_type_group.lookup_key%TYPE,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			chain.filter.compound_filter_id%TYPE;	
	v_audit_ids						chain.T_FILTERED_OBJECT_TABLE;	
BEGIN
	v_compound_filter_id := chain.filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);
	
	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		-- convert non-compliance ids to audit ids
		SELECT chain.T_FILTERED_OBJECT_ROW(anc.internal_audit_sid, NULL, NULL)
		  BULK COLLECT INTO v_audit_ids
		  FROM audit_non_compliance anc
		  JOIN TABLE(in_ids) t ON anc.audit_non_compliance_id = t.object_id;
		  
		-- filter audits
		audit_report_pkg.GetFilteredIds(
			in_group_key					=> in_audit_type_group_key,
			in_compound_filter_id			=> v_compound_filter_id,
			in_id_list						=> v_audit_ids,
			out_id_list						=> v_audit_ids
		);
		
		-- convert audit ids to non-compliance ids
		SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM audit_non_compliance anc
		  JOIN TABLE(v_audit_ids) t ON anc.internal_audit_sid = t.object_id
		  JOIN TABLE(in_ids) iid ON anc.audit_non_compliance_id = iid.object_id;
	END IF;
END;

PROCEDURE FilterIssues (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			chain.filter.compound_filter_id%TYPE;	
	v_issue_ids						chain.T_FILTERED_OBJECT_TABLE;	
BEGIN
	v_compound_filter_id := chain.filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);
	
	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		-- convert non-compliance ids to issue ids
		SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, NULL, NULL)
		  BULK COLLECT INTO v_issue_ids
		  FROM audit_non_compliance anc
		  JOIN TABLE(in_ids) t ON anc.audit_non_compliance_id = t.object_id
		  JOIN issue_non_compliance inc ON inc.non_compliance_id = anc.non_compliance_id
		  JOIN issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id;
		  
		-- filter issues
		issue_report_pkg.GetFilteredIds(
			in_compound_filter_id	=> v_compound_filter_id,
			in_id_list				=> v_issue_ids,
			out_id_list				=> v_issue_ids
		);
		
		-- convert issue ids to non-compliance ids
		SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM issue i 
		  JOIN TABLE(v_issue_ids) t ON i.issue_id = t.object_id
		  JOIN issue_non_compliance inc ON i.issue_non_compliance_id = inc.issue_non_compliance_id
		  JOIN audit_non_compliance anc ON anc.non_compliance_id = inc.non_compliance_id
		  JOIN TABLE(in_ids) iid ON anc.audit_non_compliance_id = iid.object_id;
	END IF;
END;

PROCEDURE FilterByContextCompany (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name			IN  chain.filter_field.name%TYPE,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_company_sid					security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
BEGIN
	SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM audit_non_compliance anc
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON anc.audit_non_compliance_id = t.object_id
	  JOIN internal_audit ia ON ia.internal_audit_sid = anc.internal_audit_sid
	  LEFT JOIN supplier s ON s.region_sid = ia.region_sid
	  LEFT JOIN chain.supplier_audit sa ON sa.audit_sid = ia.internal_audit_sid
	  LEFT JOIN chain.audit_request ar ON ar.audit_sid = ia.internal_audit_sid
	  JOIN chain.filter_value fv ON fv.num_value = 0 OR (fv.num_value = 1 AND (
			ia.auditor_company_sid = v_company_sid
			OR s.company_sid = v_company_sid
			OR sa.created_by_company_sid = v_company_sid
			OR sa.auditor_company_sid = v_company_sid
			OR sa.supplier_company_sid = v_company_sid
			OR ar.requested_by_company_sid = v_company_sid
			OR ar.auditor_company_sid = v_company_sid
			OR ar.auditee_company_sid = v_company_sid
	  ))
	  JOIN chain.filter_field ff ON ff.filter_field_id = fv.filter_field_id
	 WHERE ff.filter_id = in_filter_id
	   AND ff.filter_field_id = in_filter_field_id;
END;

PROCEDURE GetTagGroups (
	out_tag_groups					OUT	SYS_REFCURSOR,
	out_tag_group_members			OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Same permissions as csr.tag_pkg.GetTagGroups
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, security_pkg.GetApp, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_tag_groups FOR
		SELECT tg.tag_group_id, tg.name, tg.applies_to_suppliers, tg.applies_to_chain_product_types
		  FROM csr.v$tag_group tg
		 WHERE tg.applies_to_non_compliances = 1
		 ORDER BY tg.name;
	
	OPEN out_tag_group_members FOR
		SELECT t.tag_id id, t.tag label, tgm.tag_group_id
		  FROM csr.tag_group tg
		  JOIN csr.tag_group_member tgm ON tg.app_sid = tgm.app_sid AND tg.tag_group_id = tgm.tag_group_id
		  JOIN csr.v$tag t ON tgm.app_sid = t.app_sid AND tgm.tag_id = t.tag_id
		 WHERE tg.applies_to_non_compliances = 1
		 ORDER BY tgm.pos;
END;

END non_compliance_report_pkg;
/
