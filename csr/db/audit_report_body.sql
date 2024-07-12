CREATE OR REPLACE PACKAGE BODY CSR.audit_report_pkg
IS

PARENT_TYPE_PROPERTY				CONSTANT NUMBER := 1;
PARENT_TYPE_SUPPLIER				CONSTANT NUMBER := 2;
PARENT_TYPE_PERMIT					CONSTANT NUMBER := 3;

-- private field filter units
PROCEDURE FilterRegionSid			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER,in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAuditDtm			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterNextAuditDueDtm		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterMyAudits			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAuditsOpenNCs		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAuditsMostRecent		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAuditsMostRecentAnyType	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_audit_type_group_key IN internal_audit_type_group.lookup_key%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAuditsMostRecentByFilter(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_audit_type_group_key IN internal_audit_type_group.lookup_key%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSurveyNotCompleted	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSurveyCompletedDtm	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAuditTypeId			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_audit_type_group_key IN internal_audit_type_group.lookup_key%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterFlowStateId			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_audit_type_group_key IN internal_audit_type_group.lookup_key%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterClosureResultId		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_audit_type_group_key IN internal_audit_type_group.lookup_key%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAuditScore			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterNcScore				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSurveyScore			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSurveyGroupScore	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAuditeeUserSid		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAuditorCoordinatorSid (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAuditor				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAuditorOrganisation (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterNonCompliances		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_audit_type_group_key IN internal_audit_type_group.lookup_key%TYPE, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSavedFilter			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_audit_type_group_key IN internal_audit_type_group.lookup_key%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_comparator IN chain.filter_field.comparator%TYPE, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCmsEnumField		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSurveyGroupNotCompleted	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSurveyGroupCompletedDtm	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterInvolvementType		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterTagGroup			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCompanies			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCompaniesBreakdown	(in_name IN	chain.filter_field.name%TYPE, in_comparator IN	chain.filter_field.comparator%TYPE, in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAuditorCompanies	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAuditorCompaniesBrkdwn	(in_name IN	chain.filter_field.name%TYPE, in_comparator IN	chain.filter_field.comparator%TYPE, in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterByContextCompany	(in_filter_id IN  chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN  chain.filter_field.name%TYPE, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);

PROCEDURE FilterIds (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_audit_type_group_key			IN  internal_audit_type_group.lookup_key%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE
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

	v_log_id := chain.filter_pkg.StartDebugLog('csr.audit_report_pkg.FilterIds', in_filter_id);
	
	FOR r IN (
		SELECT name, filter_field_id, NVL(show_all, 0) show_all, group_by_index, comparator
		  FROM chain.v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := chain.filter_pkg.StartDebugLog('csr.audit_report_pkg.FilterIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);		

		IF r.name = 'RegionSid' THEN
			FilterRegionSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);			
		ELSIF r.name = 'AuditDtm' THEN
			FilterAuditDtm(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);			
		ELSIF r.name = 'NextAuditDueDtm' THEN
			FilterNextAuditDueDtm(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);			
		ELSIF r.name = 'MyAudits' THEN
			FilterMyAudits(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);			
		ELSIF r.name = 'OpenNCs' THEN
			FilterAuditsOpenNCs(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);			
		ELSIF r.name = 'MostRecent' THEN
			FilterAuditsMostRecent(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'MostRecentAnyType' THEN
			FilterAuditsMostRecentAnyType(in_filter_id, r.filter_field_id, in_audit_type_group_key, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'MostRecentByFilter' THEN
			FilterAuditsMostRecentByFilter(in_filter_id, r.filter_field_id, in_audit_type_group_key, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'SurveyNotCompleted' THEN
			FilterSurveyNotCompleted(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);			
		ELSIF r.name = 'SurveyCompletedDtm' THEN
			FilterSurveyCompletedDtm(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);			
		ELSIF r.name = 'AuditTypeId' THEN
			FilterAuditTypeId(in_filter_id, r.filter_field_id, in_audit_type_group_key, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);			
		ELSIF r.name = 'FlowStateId' THEN
			FilterFlowStateId(in_filter_id, r.filter_field_id, in_audit_type_group_key, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);			
		ELSIF r.name = 'ClosureResultId' THEN
			FilterClosureResultId(in_filter_id, r.filter_field_id, in_audit_type_group_key, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);			
		ELSIF r.name LIKE 'auditScore.%' THEN
			FilterAuditScore(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);				
		ELSIF r.name = 'NcScore' THEN
			FilterNcScore(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);			
		ELSIF r.name = 'SurveyScore' THEN
			FilterSurveyScore(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);	
		ELSIF r.name LIKE 'surveyGroupScore.%' THEN
			FilterSurveyGroupScore(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);				
		ELSIF r.name = 'AuditeeUserSid' THEN
			FilterAuditeeUserSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);			
		ELSIF r.name = 'AuditCoordinatorSid' THEN
			FilterAuditorCoordinatorSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);			
		ELSIF r.name = 'Auditor' THEN
			FilterAuditor(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'AuditorOrganisation' THEN
			FilterAuditorOrganisation(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'NonComplianceFilter' THEN
			FilterNonCompliances(in_filter_id, r.filter_field_id, in_audit_type_group_key, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'savedfilter' THEN
			FilterSavedFilter(in_filter_id, r.filter_field_id, in_audit_type_group_key, r.group_by_index, r.show_all, r.comparator, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'EnumField.%' THEN
			FilterCmsEnumField(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) LIKE 'surveygroupnotcompleted.%' THEN
			FilterSurveyGroupNotCompleted(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) LIKE 'surveygroupcompleteddtm.%' THEN
			FilterSurveyGroupCompletedDtm(in_filter_id, r.filter_field_id, r.name, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'InvolvementType.%' THEN
			FilterInvolvementType(in_filter_id, r.filter_field_id, r.name, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'TagGroup.%' THEN
			FilterTagGroup(in_filter_id, r.filter_field_id, r.name, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'CompanyFilter' THEN
			FilterCompanies(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'companyFilter_%' THEN
			v_name := substr(r.name, 15);
			FilterCompaniesBreakdown(v_name, r.comparator, in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'AuditorCompanyFilter' THEN
			FilterAuditorCompanies(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'auditorCompanyFilter_%' THEN
			v_name := substr(r.name, 22);
			FilterAuditorCompaniesBrkdwn(v_name, r.comparator, in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
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
	in_id_list				IN	chain.T_FILTERED_OBJECT_TABLE,
	out_id_list				OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS	
	v_starting_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_result_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.audit_report_pkg.RunCompoundFilter');
	
	v_starting_ids := in_id_list;

	IF in_parallel = 0 THEN
		out_id_list := in_id_list;
	ELSE
		out_id_list := chain.T_FILTERED_OBJECT_TABLE();
	END IF;

	chain.filter_pkg.CheckCompoundFilterAccess(in_compound_filter_id, security_pkg.PERMISSION_READ);	
	chain.filter_pkg.CheckCompoundFilterForCycles(in_compound_filter_id);
		
	FOR r IN (
		SELECT f.filter_id, ft.helper_pkg
		  FROM chain.filter f
		  JOIN chain.filter_type ft ON f.filter_type_id = ft.filter_type_id
		 WHERE f.compound_filter_id = in_compound_filter_id
	) LOOP
		EXECUTE IMMEDIATE ('BEGIN ' || r.helper_pkg || '.FilterIds(:filter_id, :audit_type_group_key, :parallel, :max_group_by, :input, :output);END;') 
		USING r.filter_id, in_audit_type_group_key, in_parallel, in_max_group_by, v_starting_ids, OUT v_result_ids;
		
		IF in_parallel = 0 THEN
			v_starting_ids := v_result_ids;
			out_id_list := v_result_ids;
		ELSE
			out_id_list := out_id_list MULTISET UNION v_result_ids;
		END IF;
	END LOOP;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetFilterObjectData (
	in_aggregation_types	IN	security.T_SID_TABLE,
	in_id_list				IN	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_score_cap						security.T_SID_TABLE;
	v_audit_id_list					security.T_ORDERED_SID_TABLE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.audit_report_pkg.GetFilterObjectData');
	
	-- just in case
	DELETE FROM chain.tt_filter_object_data;
	
	IF AGG_TYPE_COUNT MEMBER OF in_aggregation_types THEN
		INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
		SELECT DISTINCT AGG_TYPE_COUNT, l.object_id, chain.filter_pkg.AFUNC_COUNT, l.object_id
		  FROM TABLE(in_id_list) l;
	END IF;
	
	-- Run core aggregate types but only if requested
	FOR chk IN (
		SELECT *
		  FROM dual
		 WHERE EXISTS(SELECT * FROM TABLE(in_aggregation_types) WHERE column_value BETWEEN 2 AND 9999)
	) LOOP
		INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
		SELECT agg.column_value, l.object_id, 
			   CASE agg.column_value
					WHEN AGG_TYPE_COUNT_NON_COMP THEN chain.filter_pkg.AFUNC_SUM
					WHEN AGG_TYPE_COUNT_OPEN_NON_COMP THEN chain.filter_pkg.AFUNC_SUM
					WHEN AGG_TYPE_COUNT_ISSUES THEN chain.filter_pkg.AFUNC_SUM
					WHEN AGG_TYPE_COUNT_OPEN_ISSUES THEN chain.filter_pkg.AFUNC_SUM
					WHEN AGG_TYPE_COUNT_OVRD_ISSUES THEN chain.filter_pkg.AFUNC_SUM
					WHEN AGG_TYPE_COUNT_CLOSED_ISSUES THEN chain.filter_pkg.AFUNC_SUM
					WHEN AGG_TYPE_COUNT_IS_CLSD_ON_TIME THEN chain.filter_pkg.AFUNC_SUM
					WHEN AGG_TYPE_COUNT_IS_CLSD_OVRD THEN chain.filter_pkg.AFUNC_SUM
				END,
				CASE agg.column_value
					WHEN AGG_TYPE_COUNT_NON_COMP THEN COUNT(DISTINCT anc.non_compliance_id)
					WHEN AGG_TYPE_COUNT_OPEN_NON_COMP THEN COUNT(DISTINCT CASE WHEN nc.is_closed = 0 OR (nc.is_closed IS NULL AND i.issue_id IS NOT NULL AND i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL) THEN nc.non_compliance_id END)
					WHEN AGG_TYPE_COUNT_ISSUES THEN COUNT(DISTINCT i.issue_id)
					WHEN AGG_TYPE_COUNT_OPEN_ISSUES THEN COUNT(DISTINCT CASE WHEN i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id END)
					WHEN AGG_TYPE_COUNT_OVRD_ISSUES THEN COUNT(DISTINCT CASE WHEN i.due_dtm < TRUNC(SYSDATE) AND i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id END)
					WHEN AGG_TYPE_COUNT_CLOSED_ISSUES THEN COUNT(DISTINCT CASE WHEN i.resolved_dtm IS NOT NULL THEN i.issue_id END)
					WHEN AGG_TYPE_COUNT_IS_CLSD_ON_TIME THEN COUNT(DISTINCT CASE WHEN i.resolved_dtm IS NOT NULL AND TRUNC(i.resolved_dtm) <= i.due_dtm THEN i.issue_id END)
					WHEN AGG_TYPE_COUNT_IS_CLSD_OVRD THEN COUNT(DISTINCT CASE WHEN i.resolved_dtm IS NOT NULL AND TRUNC(i.resolved_dtm) > i.due_dtm THEN i.issue_id END)
				END
		  FROM internal_audit ia
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) l ON ia.internal_audit_sid = l.object_id
		  CROSS JOIN TABLE(in_aggregation_types) agg
		  LEFT JOIN audit_non_compliance anc ON ia.internal_audit_sid = anc.internal_audit_sid
		  LEFT JOIN non_compliance nc ON anc.non_compliance_id = nc.non_compliance_id
		  LEFT JOIN issue_non_compliance inc ON anc.non_compliance_id = inc.non_compliance_id
		  LEFT JOIN issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id AND i.deleted = 0
		 WHERE agg.column_value > AGG_TYPE_COUNT -- count is worked out above
		   AND agg.column_value < 10000 -- custom agg types start at 10000
		 GROUP BY agg.column_value, l.object_id
		;
	END LOOP;
	
	-- Get non-compliance score aggregates only if we know some have been requested (otherwise it's a large query that
	-- would return no results)
	FOR chk IN (
		SELECT * FROM dual WHERE EXISTS (
			SELECT cat.customer_aggregate_type_id, stat.analytic_function, stat.score_type_id
			  FROM chain.customer_aggregate_type cat
			  JOIN TABLE(in_aggregation_types) a ON cat.customer_aggregate_type_id = a.column_value
			  JOIN score_type_agg_type stat ON cat.app_sid = stat.app_sid AND cat.score_type_agg_type_id = stat.score_type_agg_type_id
			 WHERE cat.card_group_id = chain.filter_pkg.FILTER_TYPE_AUDITS
			   AND stat.applies_to_nc_score = 1
		)
	) LOOP
		SELECT security.T_ORDERED_SID_ROW(object_id, rownum)
		  BULK COLLECT INTO v_audit_id_list
		  FROM (
			SELECT DISTINCT object_id
			  FROM TABLE(in_id_list)
		);
		v_score_cap := audit_pkg.GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_SCORE, security.security_pkg.PERMISSION_READ, v_audit_id_list);
	
		INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
		SELECT cat.customer_aggregate_type_id, l.object_id, stat.analytic_function, ia.nc_score
		  FROM (chain.customer_aggregate_type cat
		  JOIN TABLE(in_aggregation_types) a ON cat.customer_aggregate_type_id = a.column_value
		  JOIN score_type_agg_type stat ON cat.app_sid = stat.app_sid AND cat.score_type_agg_type_id = stat.score_type_agg_type_id
		  )
		 CROSS JOIN internal_audit ia
		  JOIN internal_audit_type iat ON ia.app_sid = iat.app_sid AND ia.internal_audit_type_id = iat.internal_audit_type_id
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) l ON ia.internal_audit_sid = l.object_id
		  LEFT JOIN TABLE(v_score_cap) score_cap ON ia.internal_audit_sid = score_cap.column_value
		 WHERE iat.nc_score_type_id = stat.score_type_id
		   AND cat.card_group_id = chain.filter_pkg.FILTER_TYPE_AUDITS
		   AND stat.applies_to_nc_score = 1
		   AND (ia.flow_item_id IS NULL OR score_cap.column_value IS NOT NULL);
	END LOOP;
	
	-- Get audit survey score aggregates only if we know some have been requested (to prevent running a large query
	-- that would return no results).
	FOR chk IN (
		SELECT * FROM dual WHERE EXISTS (
			SELECT cat.customer_aggregate_type_id, stat.analytic_function, stat.score_type_id, stat.ia_type_survey_group_id,
				   stat.applies_to_primary_audit_survy
			  FROM chain.customer_aggregate_type cat
			  JOIN TABLE(in_aggregation_types) a ON cat.customer_aggregate_type_id = a.column_value
			  JOIN score_type_agg_type stat ON cat.app_sid = stat.app_sid AND cat.score_type_agg_type_id = stat.score_type_agg_type_id
			 WHERE cat.card_group_id = chain.filter_pkg.FILTER_TYPE_AUDITS
			   AND (stat.ia_type_survey_group_id IS NOT NULL OR stat.applies_to_primary_audit_survy = 1)
		)
	) LOOP
		IF v_score_cap IS NULL THEN
			SELECT security.T_ORDERED_SID_ROW(object_id, rownum)
			  BULK COLLECT INTO v_audit_id_list
			  FROM (
				SELECT DISTINCT object_id
				  FROM TABLE(in_id_list)
			);
			
			v_score_cap := audit_pkg.GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_SCORE, security.security_pkg.PERMISSION_READ, v_audit_id_list);
		END IF;
		
		INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
		SELECT cat.customer_aggregate_type_id, l.object_id, stat.analytic_function, qss.overall_score
		  FROM (chain.customer_aggregate_type cat
		  JOIN TABLE(in_aggregation_types) a ON cat.customer_aggregate_type_id = a.column_value
		  JOIN score_type_agg_type stat ON cat.app_sid = stat.app_sid AND cat.score_type_agg_type_id = stat.score_type_agg_type_id
		  )
		 CROSS JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) l
		  JOIN internal_audit ia ON l.object_id = ia.internal_audit_sid
		  LEFT JOIN TABLE(v_score_cap) score_cap ON ia.internal_audit_sid = score_cap.column_value
		  LEFT JOIN (internal_audit_survey ias
		  JOIN internal_audit_type_survey iats
		    ON ias.app_sid = iats.app_sid
		   AND ias.internal_audit_type_survey_id = iats.internal_audit_type_survey_id
		  ) ON ia.app_sid = ias.app_sid
		   AND ia.internal_audit_sid = ias.internal_audit_sid
		   AND iats.ia_type_survey_group_id = stat.ia_type_survey_group_id
		  JOIN quick_survey_response qsr
		    ON qsr.survey_response_id = CASE WHEN stat.applies_to_primary_audit_survy = 1 THEN ia.survey_response_id ELSE ias.survey_response_id END
		  JOIN quick_survey_submission qss
		    ON qsr.app_sid = qss.app_sid
		   AND qsr.survey_response_id = qss.survey_response_id
		   AND qsr.last_submission_id = qss.submission_id
		  JOIN quick_survey qs
		    ON qsr.app_sid = qs.app_sid
		   AND qsr.survey_sid = qs.survey_sid
		 WHERE qs.score_type_id = stat.score_type_id
		   AND cat.card_group_id = chain.filter_pkg.FILTER_TYPE_AUDITS
		   AND (stat.ia_type_survey_group_id IS NOT NULL OR stat.applies_to_primary_audit_survy = 1)
		   AND (ia.flow_item_id IS NULL OR score_cap.column_value IS NOT NULL);
	END LOOP;
	
	-- Internal audit scores
	FOR chk IN (
		SELECT * FROM dual WHERE EXISTS (
			SELECT cat.customer_aggregate_type_id, stat.analytic_function, stat.score_type_id
			  FROM chain.customer_aggregate_type cat
			  JOIN TABLE(in_aggregation_types) a ON cat.customer_aggregate_type_id = a.column_value
			  JOIN score_type_agg_type stat ON cat.app_sid = stat.app_sid AND cat.score_type_agg_type_id = stat.score_type_agg_type_id
			 WHERE cat.card_group_id = chain.filter_pkg.FILTER_TYPE_AUDITS
			   AND stat.applies_to_audits = 1
		)
	) LOOP
		IF v_score_cap IS NULL THEN
			SELECT security.T_ORDERED_SID_ROW(object_id, rownum)
			  BULK COLLECT INTO v_audit_id_list
			  FROM (
				SELECT DISTINCT object_id
				  FROM TABLE(in_id_list)
			);
			
			v_score_cap := audit_pkg.GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_SCORE, security.security_pkg.PERMISSION_READ, v_audit_id_list);
		END IF;
		
		INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
		SELECT cat.customer_aggregate_type_id, l.object_id, stat.analytic_function, ias.score
		  FROM (chain.customer_aggregate_type cat
		  JOIN TABLE(in_aggregation_types) a ON cat.customer_aggregate_type_id = a.column_value
		  JOIN score_type_agg_type stat ON cat.app_sid = stat.app_sid AND cat.score_type_agg_type_id = stat.score_type_agg_type_id
		  )
		 CROSS JOIN internal_audit ia
		  JOIN internal_audit_score ias ON ia.app_sid = ias.app_sid AND ia.internal_audit_sid = ias.internal_audit_sid
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) l ON ia.internal_audit_sid = l.object_id
		  LEFT JOIN TABLE(v_score_cap) score_cap ON ia.internal_audit_sid = score_cap.column_value
		 WHERE ias.score_type_id = stat.score_type_id
		   AND cat.card_group_id = chain.filter_pkg.FILTER_TYPE_AUDITS
		   AND stat.applies_to_audits = 1
		   AND (ia.flow_item_id IS NULL OR score_cap.column_value IS NOT NULL);
	END LOOP;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetPermissibleIds (
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_table							security.T_SID_TABLE;
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.audit_report_pkg.GetPermissibleIds');
	
	v_table := audit_pkg.GetAuditsForUserAsTable;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(column_value, NULL, NULL)
	  BULK COLLECT INTO out_id_list
	  FROM TABLE(v_table);
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetInitialIds(
	in_search						IN	VARCHAR2 DEFAULT NULL,
	in_group_key					IN	chain.saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
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
	v_permissible_ids				chain.T_FILTERED_OBJECT_TABLE;
	v_temp_ids						chain.T_FILTERED_OBJECT_TABLE;
	v_has_regions					NUMBER;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.audit_report_pkg.GetInitialIds');
	
	chain.filter_pkg.GetFilteredObjectsFromCache(
		in_card_group_id => chain.filter_pkg.FILTER_TYPE_AUDITS,
		out_filtered_objects => v_permissible_ids
	);
	
	IF v_permissible_ids IS NULL THEN
		GetPermissibleIds(v_permissible_ids);
		
		chain.filter_pkg.SetFilteredObjectsInCache(
			in_card_group_id => chain.filter_pkg.FILTER_TYPE_AUDITS,
			in_filtered_objects => v_permissible_ids
		);
	END IF;

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
		out_id_list := v_permissible_ids;
		chain.filter_pkg.EndDebugLog(v_log_id);
		RETURN;
	END IF;
	
	chain.filter_pkg.PopulateTempRegionSid(in_region_sids, in_region_col_type, v_has_regions);

	-- start with the list they have access to limited by group
	SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, NULL, NULL)
	  BULK COLLECT INTO out_id_list
	  FROM TABLE(v_permissible_ids) t
	  JOIN internal_audit ia ON t.object_id = ia.internal_audit_sid
	  JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id
	  LEFT JOIN internal_audit_type_group atg ON iat.internal_audit_type_group_id = atg.internal_audit_type_group_id
	  LEFT JOIN temp_region_sid tr ON CASE in_region_col_type WHEN COL_TYPE_REGION_SID THEN ia.region_sid END = tr.region_sid
	  LEFT JOIN v$region r ON r.region_sid = ia.region_sid
	  LEFT JOIN (
			/* hierarchical query might be an overkill for a large input of regions sids */
			SELECT DISTINCT app_sid, NVL(link_to_region_sid, region_sid) region_sid
			  FROM region /* we want the child regions of all input region sids*/
			 START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') AND region_sid = in_parent_id
		   CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
		) ppr ON in_parent_type = PARENT_TYPE_PROPERTY AND ia.region_sid = ppr.region_sid AND ia.app_sid = ppr.app_sid
	 WHERE (in_parent_type IS NULL OR 
			(in_parent_type = PARENT_TYPE_PROPERTY AND ppr.region_sid IS NOT NULL) OR
			(in_parent_type = PARENT_TYPE_SUPPLIER AND ia.region_sid = in_parent_id) OR
			(in_parent_type = PARENT_TYPE_PERMIT AND ia.permit_id = in_parent_id))
	   AND (in_group_key IS NULL OR LOWER(atg.lookup_key) = LOWER(in_group_key))
	   AND (v_has_regions = 0 OR tr.region_sid IS NOT NULL)
	   AND (in_date_col_type IS NULL OR (
			(in_start_dtm IS NULL OR in_start_dtm <= CASE in_date_col_type WHEN COL_TYPE_AUDIT_DTM THEN ia.audit_dtm END) AND
			(in_end_dtm IS NULL OR in_end_dtm > CASE in_date_col_type WHEN COL_TYPE_AUDIT_DTM THEN ia.audit_dtm END) 
	   ))
	   AND ((LENGTH(TRIM(v_sanitised_search)) > 0 AND INSTR(v_sanitised_search, '%') > 0 AND (CONTAINS(ia.label, v_sanitised_search) > 0 OR CONTAINS(ia.notes, v_sanitised_search) > 0))
		   OR (INSTR(v_sanitised_search, '%') = 0 AND (UPPER(ia.label) LIKE '%' || UPPER(in_search) || '%') OR UPPER(ia.notes) LIKE '%' || UPPER(in_search) || '%')
		   OR UPPER(atg.internal_audit_ref_prefix||NVL(ia.internal_audit_ref, ia.internal_audit_sid)) = UPPER(in_search)
		   OR UPPER(r.description) LIKE '%' || UPPER(in_search) || '%' -- column not indexed so we can't do a CONTAINS.
		   OR EXISTS (
				SELECT *
				  FROM non_compliance nc
				  JOIN non_compliance_type nct ON nc.non_compliance_type_id = nct.non_compliance_type_id
				  JOIN audit_non_compliance anc ON nc.non_compliance_id = anc.non_compliance_id
				  LEFT JOIN issue_non_compliance ict ON nc.non_compliance_id = ict.non_compliance_id
				  LEFT JOIN issue i ON ict.issue_non_compliance_id = i.issue_non_compliance_id
				  LEFT JOIN issue_type it ON i.issue_type_id = it.issue_type_id
				 WHERE anc.internal_audit_sid = ia.internal_audit_sid
				   -- match on [prefix][ID] on non-compliances
				   AND (UPPER(nct.inter_non_comp_ref_prefix||NVL(nc.non_compliance_ref, nc.non_compliance_id)) = UPPER(in_search)
				   -- match on [prefix][ID] on issues
					OR UPPER(it.internal_issue_ref_prefix||NVL(i.issue_ref, i.issue_id)) = UPPER(in_search)))
			);

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
	chain.filter_pkg.GetLargestDateWindow(in_compound_filter_id, 'AuditDtm', 'csr.audit_report_pkg',
		in_start_dtm, in_end_dtm, v_start_dtm, v_end_dtm);
	
	-- Step 1, get initial set of ids
	GetInitialIds(in_search, in_group_key, in_pre_filter_sid, in_parent_type, in_parent_id, in_region_sids,
		v_start_dtm, v_end_dtm, in_region_col_type, in_date_col_type, in_id_list, out_id_list);

	-- Step 2, If there's a filter, restrict the list of issue ids
	IF NVL(in_compound_filter_id, 0) > 0 THEN -- XPJ passes round zero for some reason?
		RunCompoundFilter(in_compound_filter_id, in_group_key, 0, NULL, out_id_list, out_id_list);
	END IF;
END;

PROCEDURE ApplyBreadcrumb(
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE,
	in_audit_type_group_key			IN  internal_audit_type_group.lookup_key%TYPE,
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.audit_report_pkg.ApplyBreadcrumb');
	
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
	in_id_list						IN  security.T_ORDERED_SID_TABLE,
	out_cur							OUT SYS_REFCURSOR,
	out_surveys_cur					OUT SYS_REFCURSOR,
	out_inv_users_cur				OUT SYS_REFCURSOR,
	out_tags_cur					OUT SYS_REFCURSOR,
	out_scores_cur					OUT SYS_REFCURSOR
)
AS
	v_audits_sid					security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
	v_add_contents					NUMBER := security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), v_audits_sid, security_pkg.PERMISSION_ADD_CONTENTS);
	v_survey_cap					security.T_SID_TABLE := audit_pkg.GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_SURVEY, security.security_pkg.PERMISSION_READ, in_id_list);
	v_closure_cap					security.T_SID_TABLE := audit_pkg.GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_CLOSURE, security.security_pkg.PERMISSION_READ, in_id_list);
	v_score_cap						security.T_SID_TABLE := audit_pkg.GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_SCORE, security.security_pkg.PERMISSION_READ, in_id_list);
	v_copy_cap						security.T_SID_TABLE := audit_pkg.GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_COPY, security.security_pkg.PERMISSION_WRITE, in_id_list);
	v_count							NUMBER;
	v_auditee_cap					security.T_SID_TABLE := security.T_SID_TABLE();
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.audit_report_pkg.CollectSearchResults');
	
	SELECT count(*) INTO v_count
	  FROM internal_audit_type iat
	  JOIN internal_audit_type_group iatg ON iatg.internal_audit_type_group_id = iat.internal_audit_type_group_id
	 WHERE iatg.applies_to_users = 1;

	IF v_count > 0 THEN
		v_auditee_cap := audit_pkg.GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_AUDITEE, security.security_pkg.PERMISSION_READ, in_id_list);
	END IF;
	
	-- Calling SQL_HasCapabilityAccess isn't ideal, but we're likely to only call this for each audit in the page
	-- in in_audit_id_list. Alternatively we could left join to v$audit_capability.
	-- Sometimes we get all audits at once (e.g. excel export)

	-- N.B. SYS_CONNECT_BY_PATH that's a literal 0x1 character in there, not a space
	OPEN out_cur FOR
		WITH paths AS (
			SELECT /*+ MATERIALIZE */ t.root_region_sid, t.region_path, ROW_NUMBER() over (PARTITION BY t.root_region_sid ORDER BY t.lvl DESC) rn
			  FROM (
				SELECT CONNECT_BY_ROOT region_sid root_region_sid, RTRIM(REVERSE(REPLACE(LTRIM(SYS_CONNECT_BY_PATH(REVERSE(description), ''),''),'',' > '))) region_path, level lvl
				  FROM v$region
				 WHERE region_sid IN (
					SELECT region_sid 
					  FROM region_start_point
					 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')
					 OR SYS_CONTEXT('SECURITY', 'SID') = security_pkg.SID_BUILTIN_ADMINISTRATOR
					)
				 START WITH region_sid IN (
					SELECT DISTINCT a.region_sid 
					  FROM internal_audit a
					  JOIN TABLE(in_id_list) audit_ids ON audit_ids.sid_id = a.internal_audit_sid)
			   CONNECT BY PRIOR parent_sid = region_sid
			  ) t
		)
		SELECT /*+ALL_ROWS*/ a.internal_audit_sid, a.region_sid, a.region_description, a.audit_dtm, a.label,
			   a.auditor_user_sid, a.auditor_full_name, a.custom_audit_id,
			   a.open_non_compliances, a.auditor_name, a.auditor_organisation, ac.name auditor_company,
			   a.region_type, a.region_type_class_name, a.short_notes, a.full_notes notes, a.full_notes,
			   a.internal_audit_type_id, a.audit_type_label internal_audit_type_label, a.audit_type_label,
			   CASE WHEN a.flow_item_id IS NULL OR survey_cap.column_value IS NOT NULL THEN a.survey_completed ELSE null END survey_completed, 
			   CASE WHEN a.flow_item_id IS NULL OR auditee_cap.column_value IS NOT NULL THEN a.auditee_user_sid ELSE null END auditee_user_sid, 
			   CASE WHEN a.flow_item_id IS NULL OR auditee_cap.column_value IS NOT NULL THEN a.auditee_full_name ELSE null END auditee_full_name, 
		       CASE WHEN a.flow_item_id IS NULL OR closure_cap.column_value IS NOT NULL THEN a.icon_image_filename ELSE null END audit_closure_type_filename, 
		       CASE WHEN a.flow_item_id IS NULL OR closure_cap.column_value IS NOT NULL THEN a.icon_image_sha1 ELSE null END audit_closure_type_sha1, 
			   CASE WHEN a.flow_item_id IS NULL OR closure_cap.column_value IS NOT NULL THEN a.audit_closure_type_id ELSE null END audit_closure_type_id, 
		       CASE WHEN a.flow_item_id IS NULL OR closure_cap.column_value IS NOT NULL THEN a.closure_label ELSE null END audit_closure_type_label, 
			   CASE WHEN a.flow_item_id IS NULL OR closure_cap.column_value IS NOT NULL THEN a.next_audit_due_dtm ELSE null END next_audit_due_dtm,
			   CASE WHEN a.flow_item_id IS NULL OR score_cap.column_value IS NOT NULL THEN a.survey_overall_score ELSE null END survey_overall_score, 
			   CASE WHEN a.flow_item_id IS NULL OR score_cap.column_value IS NOT NULL THEN a.nc_score ELSE null END nc_score, 
			   CASE WHEN (a.flow_item_id IS NULL AND v_add_contents = 1) OR (copy_cap.column_value IS NOT NULL) THEN 1 ELSE 0 END can_copy, 
			   a.flow_sid, a.flow_label, a.flow_item_id, a.current_state_id, a.flow_state_label, a.flow_state_colour,
			   a.survey_label, a.survey_sid, a.survey_overall_max_score, a.survey_score_format_mask,
			   a.nc_score_type_id, a.nc_max_score, a.nc_score_label, a.nc_score_format_mask,
			   a.created_dtm, a.survey_score_thrsh_id, a.nc_score_thrsh_id,
			   ssth.description survey_threshold_description, ssth.text_colour survey_text_colour, ssth.background_colour survey_background_colour, cast(ssth.icon_image_sha1 as varchar2(40)) survey_icon_image_sha1,
			   ncsth.description nc_threshold_description, ncsth.text_colour nc_text_colour, ncsth.background_colour nc_background_colour, cast(ncsth.icon_image_sha1 as varchar2(40)) nc_score_icon_image_sha1,
			   a.longitude, a.latitude, p.region_path, a.permit_id
		  FROM v$audit a
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = a.internal_audit_sid
		  LEFT JOIN paths p ON p.root_region_sid = a.region_sid AND p.rn = 1
		  LEFT JOIN score_threshold ssth ON a.app_sid = ssth.app_sid AND a.survey_score_thrsh_id = ssth.score_threshold_id 
		  LEFT JOIN score_threshold ncsth ON a.app_sid = ncsth.app_sid AND a.nc_score_thrsh_id = ncsth.score_threshold_id 
		  LEFT JOIN (SELECT column_value FROM TABLE(v_survey_cap) ORDER BY column_value) survey_cap ON fil_list.sid_id = survey_cap.column_value
		  LEFT JOIN (SELECT column_value FROM TABLE(v_auditee_cap) ORDER BY column_value) auditee_cap ON fil_list.sid_id = auditee_cap.column_value
		  LEFT JOIN (SELECT column_value FROM TABLE(v_closure_cap) ORDER BY column_value) closure_cap ON fil_list.sid_id = closure_cap.column_value
		  LEFT JOIN (SELECT column_value FROM TABLE(v_score_cap) ORDER BY column_value) score_cap ON fil_list.sid_id = score_cap.column_value
		  LEFT JOIN (SELECT column_value FROM TABLE(v_copy_cap) ORDER BY column_value) copy_cap ON fil_list.sid_id = copy_cap.column_value
		  LEFT JOIN chain.company ac ON ac.company_sid = a.auditor_company_sid
		 ORDER BY fil_list.pos;

	OPEN out_surveys_cur FOR
		SELECT ias.internal_audit_sid, ias.internal_audit_type_survey_id, iats.ia_type_survey_group_id,
			   qs.survey_sid, qs.label survey_label, qs.score_type_id, qs.score_format_mask,
			   qsr.survey_response_id, qsr.submitted_dtm, 
			   cu.csr_user_sid submitted_by_user_sid, cu.full_name submitted_by_user_name, cu.email submitted_by_user_email,
			   CASE WHEN a.flow_item_id IS NULL OR survey_cap.column_value IS NOT NULL THEN qsr.overall_score ELSE null END overall_score, 
			   qsr.overall_max_score, qsr.score_threshold_id, st.description threshold_description, st.text_colour, st.background_colour,
			   cast(st.icon_image_sha1 as varchar2(40)) icon_image_sha1
		  FROM v$audit a
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = a.internal_audit_sid
		  JOIN internal_audit_survey ias ON ias.internal_audit_sid = a.internal_audit_sid and ias.app_sid = a.app_sid
		  JOIN internal_audit_type_survey iats ON iats.internal_audit_type_survey_id = ias.internal_audit_type_survey_id AND iats.app_sid = ias.app_sid
		  LEFT JOIN v$quick_survey_response qsr ON qsr.survey_response_id = ias.survey_response_id AND qsr.app_sid = ias.app_sid
		  LEFT JOIN csr_user cu ON cu.csr_user_sid = qsr.user_sid and cu.app_sid = qsr.app_sid
		  LEFT JOIN v$quick_survey qs ON NVL(qsr.survey_sid, ias.survey_sid) = qs.survey_sid AND qs.app_sid = ias.app_sid
		  LEFT JOIN score_threshold st ON qsr.score_threshold_id = st.score_threshold_id AND qsr.app_sid = st.app_sid
		  LEFT JOIN (SELECT column_value FROM TABLE(v_survey_cap) ORDER BY column_value) survey_cap ON fil_list.sid_id = survey_cap.column_value
		 WHERE iats.ia_type_survey_group_id IS NOT NULL
		   AND (a.flow_item_id IS NULL OR survey_cap.column_value IS NOT NULL);
	
	OPEN out_inv_users_cur FOR
		SELECT ia.internal_audit_sid, atfit.audit_type_flow_inv_type_id, atfit.flow_involvement_type_id,
			   fii.user_sid, cu.full_name, cu.user_name, cu.email
		  FROM csr.flow_item_involvement fii
		  JOIN csr.internal_audit ia ON ia.flow_item_id = fii.flow_item_id
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = ia.internal_audit_sid
		  JOIN csr.audit_type_flow_inv_type atfit 
			ON atfit.flow_involvement_type_id = fii.flow_involvement_type_id
		   AND atfit.internal_audit_type_id = ia.internal_audit_type_id
		  JOIN csr.csr_user cu ON cu.csr_user_sid = fii.user_sid
		 ORDER BY ia.internal_audit_sid, cu.full_name;
	
	OPEN out_tags_cur FOR
		SELECT ia.internal_audit_sid, tg.tag_group_id, tg.name tag_group_name,
			   t.tag_id, t.tag
		  FROM csr.v$tag_group tg
		  JOIN csr.tag_group_member tgm ON tgm.tag_group_id = tg.tag_group_id
		  JOIN csr.v$tag t ON t.tag_id = tgm.tag_id
		  JOIN csr.internal_audit_tag iat ON iat.tag_id = tgm.tag_id
		  JOIN csr.internal_audit ia ON ia.internal_audit_sid = iat.internal_audit_sid
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = ia.internal_audit_sid
		 WHERE tg.applies_to_audits = 1;

	OPEN out_scores_cur FOR
		SELECT ias.internal_audit_sid, ias.score_type_id, ias.score, ias.score_threshold_id,
			   st.label score_type_label, st.format_mask score_type_format_mask, st.lookup_key score_type_lookup_key,
			   sth.description score_threshold_description, 
			   sth.text_colour, sth.background_colour, sth.bar_colour, 
			   cast(sth.icon_image_sha1 as varchar2(40)) icon_image_sha1
		  FROM internal_audit_score ias
		  JOIN internal_audit ia ON ias.internal_audit_sid = ia.internal_audit_sid
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = ia.internal_audit_sid
		  JOIN score_type st ON st.score_type_id = ias.score_type_id
		  LEFT JOIN score_threshold sth ON sth.score_threshold_id = ias.score_threshold_id
		  LEFT JOIN (SELECT column_value FROM TABLE(v_score_cap) ORDER BY column_value) score_cap ON fil_list.sid_id = score_cap.column_value
		 WHERE (ia.flow_item_id IS NULL OR score_cap.column_value IS NOT NULL);

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
	v_survey_group_id	 			NUMBER;
	v_has_id_prefix					NUMBER;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_number						NUMBER;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.audit_report_pkg.PageFilteredIds');
	
	v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
	v_survey_group_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);
	
	SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
	  INTO v_has_id_prefix
	  FROM internal_audit_type_group
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND internal_audit_ref_prefix IS NOT NULL;
	
	IF v_order_by = 'internalAuditSid' AND in_order_dir='DESC' AND v_has_id_prefix = 0 THEN
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
	ELSIF INSTR(in_order_by, '~', 1) > 0 THEN
		chain.filter_pkg.SortExtension(
					'audit', 
					in_id_list,
					in_start_row,
					in_end_row,
					in_order_by,
					in_order_dir,
					out_id_list);
	ELSE
		SELECT security.T_ORDERED_SID_ROW(internal_audit_sid, rn)
		  BULK COLLECT INTO out_id_list
			  FROM (
				SELECT x.internal_audit_sid, ROWNUM rn
				  FROM (
					SELECT ia.internal_audit_sid
					  FROM v$audit ia
					  LEFT JOIN ( 
						SELECT ias.app_sid, ias.internal_audit_sid, qs.label, qsr.submitted_dtm, qsr.overall_score, st.description score_threshold_description
						  FROM internal_audit_survey ias
						  JOIN internal_audit_type_survey iats ON iats.internal_audit_type_survey_id = ias.internal_audit_type_survey_id
						  LEFT JOIN v$quick_survey_response qsr ON qsr.survey_response_id = ias.survey_response_id AND qsr.app_sid = ias.app_sid
						  LEFT JOIN v$quick_survey qs ON NVL(qsr.survey_sid, ias.survey_sid) = qs.survey_sid AND qs.app_sid = ias.app_sid
						  LEFT JOIN score_threshold st ON qsr.score_threshold_id = st.score_threshold_id AND qsr.app_sid = st.app_sid
						 WHERE iats.ia_type_survey_group_id = v_survey_group_id
					  ) sg ON sg.internal_audit_sid = ia.internal_audit_sid AND sg.app_sid = ia.app_sid
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = ia.internal_audit_sid
					 ORDER BY
							-- To avoid dyanmic SQL, do many case statements
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (v_order_by)
									WHEN 'internalAuditSid' THEN NVL2(ia.custom_audit_id, ia.internal_audit_ref_prefix|| TO_CHAR(ia.internal_audit_ref, '0000000000'), TO_CHAR(ia.internal_audit_sid, '0000000000'))
									WHEN 'auditDtm' THEN TO_CHAR(ia.audit_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'createdDtm' THEN TO_CHAR(ia.created_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'nextAuditDueDtm' THEN TO_CHAR(ia.next_audit_due_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'label' THEN LOWER(ia.label)
									WHEN 'notes' THEN LOWER(DBMS_LOB.SUBSTR(ia.full_notes, 1000, 1))
									WHEN 'internalAuditTypeLabel' THEN LOWER(ia.audit_type_label)
									WHEN 'regionDescription' THEN LOWER(ia.region_description)
									WHEN 'flowStateLabel' THEN LOWER(ia.flow_state_label)
									WHEN 'auditClosureTypeLabel' THEN LOWER(ia.closure_label)
									WHEN 'auditorFullName' THEN LOWER(ia.auditor_full_name)
									WHEN 'auditorName' THEN LOWER(ia.auditor_name)
									WHEN 'auditorOrganisation' THEN LOWER(ia.auditor_organisation)
									WHEN 'surveyLabel' THEN LOWER(ia.survey_label)
									WHEN 'surveyCompleted' THEN TO_CHAR(ia.survey_completed, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'openNonCompliances' THEN TO_CHAR(ia.open_non_compliances, '0000000000')
									WHEN 'ncScore' THEN CASE WHEN nc_score < 0.0 THEN ' '||TO_CHAR(ROUND(1/ nc_score, 10), '0000000000.000000') ELSE TO_CHAR(nc_score, '0000000000.000000') END
									WHEN 'surveyScore' THEN CASE WHEN survey_overall_score < 0.0 THEN ' '||TO_CHAR(ROUND(1/ survey_overall_score, 10), '0000000000.000000') ELSE TO_CHAR(survey_overall_score, '0000000000.000000') END
									WHEN 'groupSurveyLabel' THEN LOWER(sg.label)
									WHEN 'groupSurveyCompleted' THEN TO_CHAR(sg.submitted_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'groupSurveyScore' THEN NVL(CASE WHEN sg.overall_score < 0.0 THEN ' '||TO_CHAR(ROUND(1/ sg.overall_score, 10), '0000000000.000000') ELSE TO_CHAR(sg.overall_score, '0000000000.000000') END, LOWER(sg.score_threshold_description))
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (v_order_by)
									WHEN 'internalAuditSid' THEN NVL2(ia.custom_audit_id, ia.internal_audit_ref_prefix|| TO_CHAR(ia.internal_audit_ref, '0000000000'), TO_CHAR(ia.internal_audit_sid, '0000000000'))
									WHEN 'auditDtm' THEN TO_CHAR(ia.audit_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'createdDtm' THEN TO_CHAR(ia.created_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'nextAuditDueDtm' THEN TO_CHAR(ia.next_audit_due_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'label' THEN LOWER(ia.label)
									WHEN 'notes' THEN LOWER(DBMS_LOB.SUBSTR(ia.full_notes, 1000, 1))
									WHEN 'internalAuditTypeLabel' THEN LOWER(ia.audit_type_label)
									WHEN 'regionDescription' THEN LOWER(ia.region_description)
									WHEN 'flowStateLabel' THEN LOWER(ia.flow_state_label)
									WHEN 'auditClosureTypeLabel' THEN LOWER(ia.closure_label)
									WHEN 'auditorFullName' THEN LOWER(ia.auditor_full_name)
									WHEN 'auditorName' THEN LOWER(ia.auditor_name)
									WHEN 'auditorOrganisation' THEN LOWER(ia.auditor_organisation)
									WHEN 'surveyLabel' THEN LOWER(ia.survey_label)
									WHEN 'surveyCompleted' THEN TO_CHAR(ia.survey_completed, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'openNonCompliances' THEN TO_CHAR(ia.open_non_compliances, '0000000000')
									WHEN 'ncScore' THEN CASE WHEN nc_score < 0.0 THEN ' '||TO_CHAR(ROUND(1/ nc_score, 10), '0000000000.000000') ELSE TO_CHAR(nc_score, '0000000000.000000') END
									WHEN 'surveyScore' THEN CASE WHEN survey_overall_score < 0.0 THEN ' '||TO_CHAR(ROUND(1/ survey_overall_score, 10), '0000000000.000000') ELSE TO_CHAR(survey_overall_score, '0000000000.000000') END
									WHEN 'groupSurveyLabel' THEN LOWER(sg.label)
									WHEN 'groupSurveyCompleted' THEN TO_CHAR(sg.submitted_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'groupSurveyScore' THEN NVL(CASE WHEN sg.overall_score < 0.0 THEN ' '||TO_CHAR(ROUND(1/ sg.overall_score, 10), '0000000000.000000') ELSE TO_CHAR(sg.overall_score, '0000000000.000000') END, LOWER(sg.score_threshold_description))
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN ia.internal_audit_sid END DESC,
							CASE WHEN in_order_dir='DESC' THEN ia.internal_audit_sid END ASC
					) x
				 WHERE ROWNUM <= in_end_row
				)
			  WHERE rn > in_start_row;
	END IF;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE INTERNAL_AuditSidsToCoSids(
	in_audit_sids				IN security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	INSERT INTO chain.temp_grid_extension_map gem (source_id, linked_type, linked_id)
	SELECT ia.internal_audit_sid, chain.filter_pkg.FILTER_TYPE_COMPANIES, s.company_sid
		FROM TABLE(in_audit_sids) t 
		JOIN csr.internal_audit ia ON ia.internal_audit_sid = t.sid_id
		JOIN csr.supplier s ON s.region_sid = ia.region_sid;
END;

PROCEDURE INTERNAL_AuditSidsToBsciSupIds(
	in_audit_sids				IN security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	INSERT INTO chain.temp_grid_extension_map gem (source_id, linked_type, linked_id)
	SELECT ia.internal_audit_sid, chain.filter_pkg.FILTER_TYPE_BSCI_SUPPLIERS, bs.bsci_supplier_id
		FROM TABLE(in_audit_sids) t 
		JOIN csr.internal_audit ia ON ia.internal_audit_sid = t.sid_id
		JOIN csr.supplier s ON s.region_sid = ia.region_sid
		JOIN chain.v$bsci_supplier bs ON bs.company_sid = s.company_sid;
END;

PROCEDURE INTERNAL_AuSidsToBsci2009AuIds(
	in_audit_sids				IN security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	INSERT INTO chain.temp_grid_extension_map gem (source_id, linked_type, linked_id)
	SELECT ia.internal_audit_sid, chain.filter_pkg.FILTER_TYPE_BSCI_2009_AUDITS, ba.bsci_2009_audit_id
		FROM TABLE(in_audit_sids) t 
		JOIN csr.internal_audit ia ON ia.internal_audit_sid = t.sid_id
		JOIN chain.v$bsci_2009_audit ba ON ba.internal_audit_sid = ia.internal_audit_sid;
END;

PROCEDURE INTERNAL_AuSidsToBsci2014AuIds(
	in_audit_sids				IN security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	INSERT INTO chain.temp_grid_extension_map gem (source_id, linked_type, linked_id)
	SELECT ia.internal_audit_sid, chain.filter_pkg.FILTER_TYPE_BSCI_2014_AUDITS, ba.bsci_2014_audit_id
		FROM TABLE(in_audit_sids) t 
		JOIN csr.internal_audit ia ON ia.internal_audit_sid = t.sid_id
		JOIN chain.v$bsci_2014_audit ba ON ba.internal_audit_sid = ia.internal_audit_sid;
END;

PROCEDURE INTERNAL_AuSidsToBsciExtAuIds(
	in_audit_sids				IN security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	INSERT INTO chain.temp_grid_extension_map gem (source_id, linked_type, linked_id)
	SELECT ia.internal_audit_sid, chain.filter_pkg.FILTER_TYPE_BSCI_EXT_AUDITS, ba.bsci_ext_audit_id
		FROM TABLE(in_audit_sids) t 
		JOIN csr.internal_audit ia ON ia.internal_audit_sid = t.sid_id
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

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_AUDITS, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		IF v_extension_id = chain.filter_pkg.FILTER_TYPE_COMPANIES THEN
			INTERNAL_AuditSidsToCoSids(
				in_audit_sids => in_id_page);
		ELSIF v_extension_id = chain.filter_pkg.FILTER_TYPE_BSCI_SUPPLIERS THEN
			INTERNAL_AuditSidsToBsciSupIds(
				in_audit_sids => in_id_page);
		ELSIF v_extension_id = chain.filter_pkg.FILTER_TYPE_BSCI_2009_AUDITS THEN
			INTERNAL_AuSidsToBsci2009AuIds(
				in_audit_sids => in_id_page);
		ELSIF v_extension_id = chain.filter_pkg.FILTER_TYPE_BSCI_2014_AUDITS THEN
			INTERNAL_AuSidsToBsci2014AuIds(
				in_audit_sids => in_id_page);
		ELSIF v_extension_id = chain.filter_pkg.FILTER_TYPE_BSCI_EXT_AUDITS THEN
			INTERNAL_AuSidsToBsciExtAuIds(
				in_audit_sids => in_id_page);
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Audit -> '||v_name);
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
	out_cur							OUT SYS_REFCURSOR,
	out_surveys_cur					OUT SYS_REFCURSOR,
	out_inv_users_cur				OUT SYS_REFCURSOR,
	out_tags_cur					OUT SYS_REFCURSOR,
	out_scores_cur					OUT SYS_REFCURSOR
)
AS
	v_user_sid						security_pkg.T_SID_ID;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_geo_filtered_list				chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_company_sids					security.T_SID_TABLE;

BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.audit_report_pkg.GetList', in_compound_filter_id);

	v_user_sid := security_pkg.GetSID;
	
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
		in_id_list_populated	=> in_id_list_populated,
		out_id_list				=> v_id_list
	);
	
	ApplyBreadcrumb(v_id_list, in_group_key, in_breadcrumb, in_aggregation_type, v_id_list);

	-- Filter by map bounds if appropriate
	IF in_bounds_north IS NOT NULL AND in_bounds_east IS NOT NULL AND in_bounds_south IS NOT NULL AND in_bounds_west IS NOT NULL THEN
		SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, NULL, NULL)
		  BULK COLLECT INTO v_geo_filtered_list
		  FROM csr.internal_audit ia
		  JOIN csr.region r ON ia.region_sid = r.region_sid
		  JOIN TABLE(v_id_list) t ON ia.internal_audit_sid = t.object_id
		 WHERE r.geo_longitude-in_bounds_west-360*FLOOR((r.geo_longitude-in_bounds_west)/360) BETWEEN 0 AND in_bounds_east-in_bounds_west
		   AND r.geo_latitude BETWEEN in_bounds_south AND in_bounds_north;

		v_id_list := v_geo_filtered_list;
	END IF;
	
	-- Get the total number of rows (to work out number of pages)
	SELECT COUNT(DISTINCT object_id)
	  INTO out_total_rows
	  FROM TABLE(v_id_list);
	
	PageFilteredIds(v_id_list, in_start_row, in_end_row, in_order_by, in_order_dir, v_id_page);

	INTERNAL_PopGridExtTempTable(v_id_page);

	-- Return a page of results
	CollectSearchResults(
		in_id_list			=> v_id_page,
		out_cur				=> out_cur,
		out_surveys_cur		=> out_surveys_cur,
		out_inv_users_cur	=> out_inv_users_cur,
		out_tags_cur		=> out_tags_cur,
		out_scores_cur		=> out_scores_cur
	);

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetAggregateDetails (
	in_aggregation_types			IN  security.T_ORDERED_SID_TABLE,
	in_id_col_sid					IN  security_pkg.T_SID_ID,
	out_agg_types					OUT chain.T_FILTER_AGG_TYPE_TABLE,
	out_aggregate_thresholds		OUT chain.T_FILTER_AGG_TYPE_THRES_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTER_AGG_TYPE_ROW(chain.filter_pkg.FILTER_TYPE_AUDITS, a.aggregate_type_id, a.description, a.format_mask, null, 0, null, null, null)
	  BULK COLLECT INTO out_agg_types
		  FROM TABLE(in_aggregation_types) sat
		  JOIN (
			SELECT at.aggregate_type_id, at.description, null format_mask
			  FROM chain.aggregate_type at
			 WHERE card_group_id = chain.filter_pkg.FILTER_TYPE_AUDITS
			 UNION
			SELECT cat.customer_aggregate_type_id, 
				   CASE stat.analytic_function
						WHEN chain.filter_pkg.AFUNC_MIN THEN 'Minimum '
						WHEN chain.filter_pkg.AFUNC_MAX THEN 'Maximum '
						WHEN chain.filter_pkg.AFUNC_AVERAGE THEN 'Average '
						WHEN chain.filter_pkg.AFUNC_SUM THEN 'Total '
					END ||
					CASE
						WHEN stat.applies_to_nc_score = 1 THEN 'finding '
						WHEN stat.applies_to_primary_audit_survy = 1 THEN 'survey '
						ELSE LOWER(g.label)||' '
					END ||
					LOWER(st.label), st.format_mask
			  FROM chain.customer_aggregate_type cat
			  JOIN score_type_agg_type stat ON cat.app_sid = stat.app_sid AND cat.score_type_agg_type_id = stat.score_type_agg_type_id
			  JOIN score_type st ON stat.app_sid = st.app_sid AND stat.score_type_id = st.score_type_id
			  LEFT JOIN ia_type_survey_group g ON stat.app_sid = g.app_sid AND stat.ia_type_survey_group_id = g.ia_type_survey_group_id
			 WHERE cat.card_group_id = chain.filter_pkg.FILTER_TYPE_AUDITS 
			) a ON sat.sid_id = a.aggregate_type_id
		 ORDER BY sat.pos;
	
	SELECT chain.T_FILTER_AGG_TYPE_THRES_ROW(cat.customer_aggregate_type_id, sth.max_value, sth.description,
		   CASE WHEN icon_image IS NOT NULL THEN '/csr/site/quickSurvey/public/thresholdImage.aspx?type=icon&'||'scorethresholdid='||sth.score_threshold_id END,
		   sth.icon_image, sth.text_colour, sth.background_colour, sth.bar_colour)
	  BULK COLLECT INTO out_aggregate_thresholds
	  FROM TABLE(in_aggregation_types) sat
	  JOIN chain.customer_aggregate_type cat ON sat.sid_id = cat.customer_aggregate_type_id
	  JOIN score_type_agg_type stat ON cat.app_sid = stat.app_sid AND cat.score_type_agg_type_id = stat.score_type_agg_type_id
	  JOIN csr.score_threshold sth ON stat.score_type_id = sth.score_type_id
	 WHERE stat.analytic_function IN (chain.filter_pkg.AFUNC_MIN, chain.filter_pkg.AFUNC_MAX, chain.filter_pkg.AFUNC_AVERAGE)
	 ORDER BY sth.max_value;
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.audit_report_pkg.GetReportData', in_compound_filter_id);

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
		RunCompoundFilter(in_grp_by_compound_filter_id, in_group_key, 1, in_max_group_by, v_id_list, v_id_list);
	END IF;
	
	GetFilterObjectData(in_aggregation_types, v_id_list);
	
	IF in_aggregation_types.COUNT > 0 THEN
		v_aggregation_type := in_aggregation_types(1);
	END IF;
	
	v_top_n_values := chain.filter_pkg.FindTopN(in_grp_by_compound_filter_id, v_aggregation_type, v_id_list, in_breadcrumb, in_max_group_by);

	chain.filter_pkg.GetAggregateData(chain.filter_pkg.FILTER_TYPE_AUDITS, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);
	
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
		SELECT t.object_id, ia.internal_audit_sid, r.description region_description,
			   ia.audit_dtm, ia.label, iat.label audit_type_label, fs.label flow_state_label,
			   '/csr/site/audit/auditDetail.acds?sid='||ia.internal_audit_sid audit_url,
			   NVL2(ia.internal_audit_ref, atg.internal_audit_ref_prefix || ia.internal_audit_ref, null) custom_audit_id
		  FROM internal_audit ia 
		  JOIN TABLE(in_id_list) t ON ia.internal_audit_sid = t.object_id
		  JOIN v$region r ON ia.region_sid = r.region_sid
		  JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id
		  LEFT JOIN flow_item fi ON ia.flow_item_id = fi.flow_item_id
		  LEFT JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
		  LEFT JOIN internal_audit_type_group atg ON iat.internal_audit_type_group_id = atg.internal_audit_type_group_id;
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
	out_cur							OUT SYS_REFCURSOR,
	out_surveys_cur					OUT SYS_REFCURSOR,
	out_inv_users_cur				OUT SYS_REFCURSOR,
	out_tags_cur					OUT SYS_REFCURSOR,
	out_scores_cur					OUT SYS_REFCURSOR
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

	ApplyBreadcrumb(v_id_list, in_group_key, in_breadcrumb, in_aggregation_type, v_id_list);
	
	SELECT security.T_ORDERED_SID_ROW(object_id, rownum)
	  BULK COLLECT INTO v_id_page
	  FROM (
		SELECT DISTINCT object_id
		  FROM TABLE(v_id_list)
	);

	INTERNAL_PopGridExtTempTable(v_id_page);

	CollectSearchResults(
		in_id_list			=> v_id_page,
		out_cur				=> out_cur,
		out_surveys_cur		=> out_surveys_cur, 
		out_inv_users_cur	=> out_inv_users_cur, 
		out_tags_cur		=> out_tags_cur, 
		out_scores_cur		=> out_scores_cur
	);
	
END;


PROCEDURE GetListAsExtension(
	in_compound_filter_id			IN chain.compound_filter.compound_filter_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_surveys_cur					OUT SYS_REFCURSOR,
	out_inv_users_cur				OUT SYS_REFCURSOR,
	out_tags_cur					OUT SYS_REFCURSOR,
	out_scores_cur					OUT SYS_REFCURSOR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.audit_report_pkg.GetListAsExtension', in_compound_filter_id);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
			SELECT linked_id
			  FROM chain.temp_grid_extension_map
			 WHERE linked_type = chain.filter_pkg.FILTER_TYPE_AUDITS
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
		out_cur 					=> out_cur,
		out_surveys_cur				=> out_surveys_cur, 
		out_inv_users_cur			=> out_inv_users_cur, 
		out_tags_cur				=> out_tags_cur, 
		out_scores_cur				=> out_scores_cur
	);
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE SortNonCompIds (
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	out_id_list						OUT	security.T_ORDERED_SID_TABLE
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_ordered_id_list				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN	
	-- TODO: This should security trim to allowable company sids, but left for now. 
	-- Sorting does not reveal the values only the order of them.
	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM csr.audit_non_compliance anc
	  JOIN csr.internal_audit ia ON anc.internal_audit_sid = ia.internal_audit_sid
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) t ON t.object_id = anc.audit_non_compliance_id;
	  
	  
	-- filter audits
	PageFilteredIds(
		in_id_list				=> v_id_list,
		in_start_row			=> 0,
		in_end_row				=> in_end_row,
		in_order_by 			=> in_order_by,
		in_order_dir			=> in_order_dir,
		out_id_list				=> v_ordered_id_list
	);
	
	SELECT security.T_ORDERED_SID_ROW(audit_non_compliance_id, rn)
	  BULK COLLECT INTO out_id_list
	  FROM (
			SELECT audit_non_compliance_id, ROWNUM rn
			FROM (
				SELECT anc.audit_non_compliance_id
				  FROM csr.audit_non_compliance anc
				  JOIN csr.non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
				  JOIN csr.internal_audit ia ON anc.internal_audit_sid = ia.internal_audit_sid
				  JOIN TABLE(in_id_list) inc ON anc.audit_non_compliance_id = inc.object_id
				  LEFT JOIN TABLE(v_ordered_id_list) x ON ia.internal_audit_sid = x.sid_id
				  ORDER BY x.pos NULLS LAST
			 ) y
			 WHERE ROWNUM <= in_end_row
		)
	  WHERE rn > in_start_row;
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
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, region_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, n.region_sid
		  FROM (
			SELECT ia.region_sid
			  FROM internal_audit ia
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
			 GROUP BY ia.region_sid
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.region_sid = n.region_sid
		 );
		
		-- if show_all is on, we don't want to aggregate (otherwise the data is a mess)
		SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, in_group_by_index, ia.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT ia.internal_audit_sid, fv.filter_value_id
			  FROM internal_audit ia
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
			  JOIN chain.filter_value fv ON ia.region_sid= fv.region_sid 
			 WHERE fv.filter_field_id = in_filter_field_id
		) ia;
	ELSE
		
		-- if show_all is off, users have specified the regions they want, they'll
		-- expect to get region aggregation
		SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, in_group_by_index, r.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM internal_audit ia
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
		  JOIN (
				SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid, connect_by_root ff.filter_value_id filter_value_id
				  FROM region r
				  JOIN chain.filter_value ff ON ff.filter_field_id = in_filter_field_id
				 START WITH r.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND r.region_sid = ff.region_sid
			   CONNECT BY PRIOR r.app_sid = r.app_sid
				   AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
				   AND PRIOR ff.filter_value_id = ff.filter_value_id
			 ) r ON ia.region_sid = r.region_sid;
	END IF;	
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
		  FROM internal_audit ia
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
		 WHERE ia.audit_dtm IS NOT NULL;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
		
	END IF;

	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 0
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM internal_audit ia
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid= t.object_id
	  JOIN chain.tt_filter_date_range dr 
	    ON ia.audit_dtm >= NVL(dr.start_dtm, ia.audit_dtm) 
	   AND (dr.end_dtm IS NULL OR ia.audit_dtm < dr.end_dtm)
	 WHERE ia.audit_dtm IS NOT NULL;
END;

PROCEDURE FilterNextAuditDueDtm (
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
		SELECT MIN(ia.next_audit_due_dtm), MAX(ia.next_audit_due_dtm)
		  INTO v_min_date, v_max_date
		  FROM v$audit_validity ia
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
		 WHERE ia.next_audit_due_dtm IS NOT NULL;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
		
	END IF;

	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$audit_validity ia
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid= t.object_id
	  JOIN chain.tt_filter_date_range dr 
	    ON ia.next_audit_due_dtm >= NVL(dr.start_dtm, ia.next_audit_due_dtm) 
	   AND (dr.end_dtm IS NULL OR ia.next_audit_due_dtm < dr.end_dtm)
	 WHERE ia.next_audit_due_dtm IS NOT NULL;
END;

PROCEDURE FilterMyAudits (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		-- not used in reports, doesn't make sense to add (unless a customer starts asking for it)
		NULL;		
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM internal_audit ia
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid= t.object_id
	  JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id
	  LEFT JOIN region_role_member rrm ON ia.region_sid = rrm.region_sid AND iat.auditor_role_sid = rrm.role_sid AND ia.app_sid = rrm.app_sid AND rrm.user_sid = security_pkg.GetSid		   
	  JOIN chain.filter_value fv ON (fv.num_value = 0 OR (fv.num_value = 1 AND (ia.auditor_user_sid = security_pkg.GetSid OR rrm.user_sid = security_pkg.GetSid)))
	 WHERE fv.filter_field_id = in_filter_field_id;
	
END;

PROCEDURE FilterAuditsOpenNCs (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN	NUMBER,
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
			SELECT 1 open_ncs, 'Open findings' description FROM dual
			UNION ALL SELECT 0, 'No open findings' FROM dual
		  ) o
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = o.open_ncs
		 );
		
	END IF;
	
	UPDATE chain.filter_value
	   SET pos = 1
	 WHERE num_value = 1
	   AND (pos IS NULL OR pos != 1)
	   AND filter_field_id = in_filter_field_id;
	   
	UPDATE chain.filter_value
	   SET pos = 2
	 WHERE num_value = 0
	   AND (pos IS NULL OR pos != 2)
	   AND filter_field_id = in_filter_field_id;

	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$audit ia
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid= t.object_id
	  JOIN chain.filter_value fv ON ((fv.num_value = 0 AND ia.open_non_compliances = 0) OR (fv.num_value = 1 AND ia.open_non_compliances > 0))
	 WHERE fv.filter_field_id = in_filter_field_id;
	
END;

PROCEDURE FilterAuditsMostRecent (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTERED_OBJECT_ROW(iar.internal_audit_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
		FROM (
		SELECT ia.internal_audit_sid,
			   ROW_NUMBER() OVER (PARTITION BY ia.auditee_user_sid, ia.region_sid, ia.internal_audit_type_id ORDER BY ia.audit_dtm DESC, ia.internal_audit_sid DESC) AS RowNumber
		  FROM csr.internal_audit ia
		 WHERE ia.deleted = 0
		) iar
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON iar.internal_audit_sid = t.object_id
	  JOIN chain.filter_value fv ON (fv.num_value = 0 OR (fv.num_value = 1 AND iar.RowNumber = 1))
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterAuditsMostRecentAnyType (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_audit_type_group_key			IN	internal_audit_type_group.lookup_key%TYPE,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTERED_OBJECT_ROW(iar.internal_audit_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
		FROM (
		SELECT ia.internal_audit_sid,
			   ROW_NUMBER() OVER (PARTITION BY ia.auditee_user_sid, ia.region_sid ORDER BY ia.audit_dtm DESC, ia.internal_audit_sid DESC) AS RowNumber
		  FROM csr.internal_audit ia
		  JOIN csr.internal_audit_type iat ON iat.internal_audit_type_id = ia.internal_audit_type_id
		  LEFT JOIN csr.internal_audit_type_group iatg ON iatg.internal_audit_type_group_id = iat.internal_audit_type_group_id
		 WHERE deleted = 0
		   AND (in_audit_type_group_key IS NULL OR (LOWER(iatg.lookup_key) = LOWER(in_audit_type_group_key)))
		) iar
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON iar.internal_audit_sid = t.object_id
	  JOIN chain.filter_value fv ON (fv.num_value = 0 OR (fv.num_value = 1 AND iar.RowNumber = 1))
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterAuditsMostRecentByFilter (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_audit_type_group_key			IN	internal_audit_type_group.lookup_key%TYPE,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_result_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_temp_ids						chain.T_FILTERED_OBJECT_TABLE;
BEGIN
	out_ids := chain.T_FILTERED_OBJECT_TABLE();

	FOR r IN (
		SELECT sf.compound_filter_id, sf.search_text, fv.filter_value_id
		  FROM chain.v$filter_value fv
		  JOIN chain.saved_filter sf ON fv.saved_filter_sid_value = sf.saved_filter_sid
		 WHERE fv.filter_id = in_filter_id
		   AND fv.filter_field_id = in_filter_field_id
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
		  FROM (
				SELECT ia.internal_audit_sid,
					   ROW_NUMBER() OVER (PARTITION BY ia.auditee_user_sid, ia.region_sid ORDER BY ia.audit_dtm DESC, ia.internal_audit_sid DESC) AS RowNumber
				  FROM csr.internal_audit ia
				  JOIN TABLE(v_result_ids) t ON t.object_id = ia.internal_audit_sid
				 WHERE deleted = 0
		  ) iar
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON iar.internal_audit_sid = t.object_id
		 WHERE iar.RowNumber = 1;
		  
	  	out_ids := out_ids MULTISET UNION v_temp_ids;
 	END LOOP;
END;

PROCEDURE FilterSurveyNotCompleted (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, o.survey_completed, o.description
		  FROM (
			SELECT 1 survey_completed, 'Survey not submitted' description FROM dual
			UNION ALL SELECT 0, 'Survey submitted' FROM dual
		  ) o
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = o.survey_completed
		 );
		
	END IF;
	
	UPDATE chain.filter_value
	   SET pos = 1
	 WHERE num_value = 1
	   AND (pos IS NULL OR pos != 1)
	   AND filter_field_id = in_filter_field_id;
	   
	UPDATE chain.filter_value
	   SET pos = 2
	 WHERE num_value = 0
	   AND (pos IS NULL OR pos != 2)
	   AND filter_field_id = in_filter_field_id;

	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$audit ia
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid= t.object_id
	  JOIN chain.filter_value fv ON ((fv.num_value = 0 AND ia.survey_completed IS NOT NULL) OR (fv.num_value = 1 AND ia.survey_completed IS NULL))
	 WHERE fv.filter_field_id = in_filter_field_id
	   AND ia.survey_sid IS NOT NULL;
	
END;

PROCEDURE FilterSurveyCompletedDtm (
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
		SELECT MIN(ia.survey_completed), MAX(ia.survey_completed)
		  INTO v_min_date, v_max_date
		  FROM v$audit ia
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
		 WHERE ia.survey_completed IS NOT NULL;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
		
	END IF;

	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
		  FROM v$audit  ia
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid= t.object_id
		  JOIN chain.tt_filter_date_range dr 
			ON ia.survey_completed >= NVL(dr.start_dtm, ia.survey_completed) 
		   AND (dr.end_dtm IS NULL OR ia.survey_completed < dr.end_dtm)
		 WHERE ia.survey_completed IS NOT NULL;
END;

PROCEDURE FilterSurveyGroupNotCompleted (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name			IN chain.filter_field.name%TYPE,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_survey_group_id	 				NUMBER;
BEGIN
	v_survey_group_id := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);

	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, o.survey_completed, o.description
		  FROM (
			SELECT 1 survey_completed, label || ' not submitted' description FROM ia_type_survey_group WHERE ia_type_survey_group_id = v_survey_group_id
			UNION ALL SELECT 0, label || ' submitted' FROM ia_type_survey_group WHERE ia_type_survey_group_id = v_survey_group_id
		  ) o
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = o.survey_completed
		 );
		
	END IF;
	
	UPDATE chain.filter_value
	   SET pos = 1
	 WHERE num_value = 1
	   AND (pos IS NULL OR pos != 1)
	   AND filter_field_id = in_filter_field_id;
	   
	UPDATE chain.filter_value
	   SET pos = 2
	 WHERE num_value = 0
	   AND (pos IS NULL OR pos != 2)
	   AND filter_field_id = in_filter_field_id;

	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$audit ia
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid= t.object_id
	  LEFT JOIN internal_audit_survey ias ON ias.internal_audit_sid = ia.internal_audit_sid AND ias.app_sid = ia.app_sid
	  LEFT JOIN v$quick_survey_response qsr ON qsr.survey_response_id = ias.survey_response_id AND qsr.app_sid = ias.app_sid
	  JOIN chain.filter_value fv ON ((fv.num_value = 0 AND qsr.submitted_dtm IS NOT NULL) OR (fv.num_value = 1 AND qsr.submitted_dtm IS NULL))
	 WHERE fv.filter_field_id = in_filter_field_id
	   AND ia.survey_sid IS NOT NULL;
	
END;

PROCEDURE FilterSurveyGroupCompletedDtm (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name			IN chain.filter_field.name%TYPE,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;

	v_survey_group_id	 				NUMBER;
BEGIN
	v_survey_group_id := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);

	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(qsr.submitted_dtm), MAX(qsr.submitted_dtm)
		  INTO v_min_date, v_max_date
		  FROM internal_audit_survey ias
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ias.internal_audit_sid = t.object_id
		  JOIN v$quick_survey_response qsr ON qsr.survey_response_id = ias.survey_response_id AND qsr.app_sid = ias.app_sid
		 WHERE qsr.submitted_dtm IS NOT NULL;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
		
	END IF;

	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(ias.internal_audit_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
		  FROM internal_audit_survey ias
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ias.internal_audit_sid= t.object_id
		  JOIN v$quick_survey_response qsr ON qsr.survey_response_id = ias.survey_response_id AND qsr.app_sid = ias.app_sid
		  JOIN chain.tt_filter_date_range dr 
		    ON qsr.submitted_dtm >= NVL(dr.start_dtm, qsr.submitted_dtm)
		   AND (dr.end_dtm IS NULL OR qsr.submitted_dtm < dr.end_dtm)
		 WHERE qsr.submitted_dtm IS NOT NULL;
END;

PROCEDURE FilterAuditTypeId (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_audit_type_group_key			IN  internal_audit_type_group.lookup_key%TYPE,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, iat.internal_audit_type_id, iat.label
		  FROM internal_audit_type iat
		  LEFT JOIN internal_audit_type_group atg ON iat.internal_audit_type_group_id = atg.internal_audit_type_group_id
		 WHERE iat.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND (in_audit_type_group_key IS NULL OR (LOWER(atg.lookup_key) = LOWER(in_audit_type_group_key)))
		   AND NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = iat.internal_audit_type_id
		 );		
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM internal_audit ia
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
	  JOIN chain.filter_value fv ON ia.internal_audit_type_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;	
END;

PROCEDURE FilterFlowStateId (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_audit_type_group_key			IN  internal_audit_type_group.lookup_key%TYPE,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_flow_count					NUMBER;
BEGIN
	IF in_show_all = 1 THEN
		SELECT COUNT(DISTINCT flow_sid)
		  INTO v_flow_count
		  FROM internal_audit_type;
	
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, flow_state_id, label
		  FROM (
			SELECT DISTINCT fs.flow_state_id, CASE WHEN v_flow_count = 1 THEN fs.label ELSE f.label||' - '||fs.label END label
			  FROM internal_audit_type iat
			  JOIN flow_state fs ON iat.flow_sid = fs.flow_sid
			  JOIN flow f ON iat.flow_sid = f.flow_sid
			  LEFT JOIN internal_audit_type_group atg ON iat.internal_audit_type_group_id = atg.internal_audit_type_group_id
			 WHERE iat.app_sid = SYS_CONTEXT('SECURITY','APP')
			   AND (in_audit_type_group_key IS NULL OR (LOWER(atg.lookup_key) = LOWER(in_audit_type_group_key)))
			   AND fs.is_deleted = 0
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

	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM internal_audit ia
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
	  JOIN flow_item fi ON ia.flow_item_id = fi.flow_item_id
	  JOIN chain.filter_value fv ON fi.current_state_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;		
END;

PROCEDURE FilterClosureResultId (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_audit_type_group_key			IN  internal_audit_type_group.lookup_key%TYPE,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, act.audit_closure_type_id, act.label
		  FROM audit_closure_type act
		 WHERE act.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND (in_audit_type_group_key IS NULL OR EXISTS (
			SELECT 1
			  FROM audit_type_closure_type atct
			  JOIN internal_audit_type iat ON atct.app_sid = iat.app_sid AND atct.internal_audit_type_id = iat.internal_audit_type_id
			  LEFT JOIN internal_audit_type_group atg ON iat.internal_audit_type_group_id = atg.internal_audit_type_group_id
			 WHERE act.app_sid = atct.app_sid
			   AND act.audit_closure_type_id = atct.audit_closure_type_id
			   AND LOWER(atg.lookup_key) = LOWER(in_audit_type_group_key)
		   ))
		   AND NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = act.audit_closure_type_id
		 );
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM internal_audit ia
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
	  JOIN chain.filter_value fv ON ia.audit_closure_type_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterAuditScore(
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name			IN chain.filter_field.name%TYPE,
	in_group_by_index 				IN NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_score_type_id					NUMBER;
BEGIN
	SELECT score_type_id
	  INTO v_score_type_id
	  FROM score_type st
	 WHERE 'auditScore.' || score_type_id = in_filter_field_name;

	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, st.score_threshold_id, st.description
		  FROM score_threshold st
		 WHERE st.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND st.score_type_id = v_score_type_id
		   AND NOT EXISTS ( -- exclude any we may have already
			SELECT 1
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = st.score_threshold_id
		 );
	END IF;

	chain.filter_pkg.SortScoreThresholdValues(in_filter_field_id);
	chain.filter_pkg.SetThresholdColours(in_filter_field_id);

	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM internal_audit ia
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
	  JOIN internal_audit_score ias ON ias.internal_audit_sid = ia.internal_audit_sid
	  JOIN chain.filter_value fv ON ias.score_threshold_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterNcScore(
	in_filter_id					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id				IN	NUMBER,
	in_group_by_index 				IN	NUMBER,
	in_show_all						IN	NUMBER,
	in_ids							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_st_id_t	security.T_SID_TABLE;
	v_st_count	NUMBER;
BEGIN
	
	IF in_show_all = 1 THEN
		SELECT score_type_id
		  BULK COLLECT INTO v_st_id_t
		  FROM score_type st
		 WHERE EXISTS(
			SELECT 1 
			  FROM internal_audit_type iat
			 WHERE iat.nc_score_type_id = st.score_type_id
		 );

		SELECT COUNT(*)
		  INTO v_st_count
		  FROM TABLE(v_st_id_t);
	
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, st.score_threshold_id, 
			CASE WHEN v_st_count > 1 THEN st.description || ' (' || s.label || ')' ELSE st.description END description
		  FROM score_type s
		  JOIN score_threshold st ON st.app_sid = s.app_sid AND st.score_type_id = s.score_type_id 
		  JOIN TABLE (v_st_id_t) T ON T.column_value = st.score_type_id
		 WHERE st.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND NOT EXISTS ( -- exclude any we may have already
			SELECT 1
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = st.score_threshold_id
		 );
	END IF;
	
	chain.filter_pkg.SetThresholdColours(in_filter_field_id);

	chain.filter_pkg.SortScoreThresholdValues(in_filter_field_id);

	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM internal_audit ia
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
	  JOIN chain.filter_value fv ON NVL(ia.ovw_nc_score_thrsh_id, ia.nc_score_thrsh_id) = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;	 
END;

PROCEDURE FilterSurveyScore(
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index 				IN NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_st_id_t	security.T_SID_TABLE;
	v_st_count	NUMBER;
BEGIN
	IF in_show_all = 1 THEN
		v_st_id_t := audit_pkg.GetPrimarySurveyScoreTypeIds;
		
		SELECT COUNT(*)
		  INTO v_st_count
		  FROM TABLE(v_st_id_t);

		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, st.score_threshold_id, 
			CASE WHEN v_st_count > 1 THEN st.description || ' (' || s.label || ')' ELSE st.description END description
		  FROM score_type s
		  JOIN score_threshold st ON st.app_sid = s.app_sid AND st.score_type_id = s.score_type_id 
		  JOIN TABLE(v_st_id_t) T ON T.column_value = st.score_type_id
		 WHERE st.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND NOT EXISTS ( -- exclude any we may have already
			SELECT 1
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = st.score_threshold_id
		 );
	END IF;

	chain.filter_pkg.SortScoreThresholdValues(in_filter_field_id);
	chain.filter_pkg.SetThresholdColours(in_filter_field_id);

	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM internal_audit ia
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
	  JOIN v$quick_survey_response qsr ON qsr.survey_response_id = ia.survey_response_id
	  JOIN chain.filter_value fv ON qsr.score_threshold_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterSurveyGroupScore(
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name			IN chain.filter_field.name%TYPE,
	in_group_by_index 				IN NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_st_id_t	security.T_SID_TABLE;
	v_st_count	NUMBER;
BEGIN
	
	IF in_show_all = 1 THEN
		SELECT score_type_id
		  BULK COLLECT INTO v_st_id_t
		  FROM score_type st
		 WHERE EXISTS(
			SELECT 1 
			  FROM internal_audit_type_survey iats
			  JOIN quick_survey qs ON qs.survey_sid = iats.default_survey_sid
			 WHERE qs.score_type_id = st.score_type_id
			   AND 'surveyGroupScore.' || iats.ia_type_survey_group_id = in_filter_field_name
		 );
		 
		SELECT COUNT(*)
		  INTO v_st_count
		  FROM TABLE(v_st_id_t);

		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, st.score_threshold_id, 
			CASE WHEN v_st_count > 1 THEN st.description || ' (' || s.label || ')' ELSE st.description END description
		  FROM score_type s
		  JOIN score_threshold st ON st.app_sid = s.app_sid AND st.score_type_id = s.score_type_id 
		  JOIN TABLE(v_st_id_t) T ON T.column_value = st.score_type_id
		 WHERE st.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND NOT EXISTS ( -- exclude any we may have already
			SELECT 1
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = st.score_threshold_id
		 );
	END IF;

	chain.filter_pkg.SortScoreThresholdValues(in_filter_field_id);
	chain.filter_pkg.SetThresholdColours(in_filter_field_id);

	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM internal_audit ia
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
	  JOIN internal_audit_survey ias ON t.object_id = ias.internal_audit_sid
	  JOIN internal_audit_type_survey iats ON ias.internal_audit_type_survey_id = iats.internal_audit_type_survey_id
	  JOIN v$quick_survey_response qsr ON qsr.survey_response_id = ias.survey_response_id
	  JOIN chain.filter_value fv ON qsr.score_threshold_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterAuditeeUserSid (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		-- ensure the filter_value rows include all assigned to users for the current filter
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, user_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, ia.auditee_user_sid
		  FROM (
			SELECT DISTINCT auditee_user_sid
			  FROM internal_audit ia
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
			  ) ia
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.user_sid = ia.auditee_user_sid
		 );
		
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM internal_audit ia
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
	  JOIN chain.filter_value fv
		ON fv.user_sid = ia.auditee_user_sid
		OR (in_show_all = 0 AND fv.user_sid = chain.filter_pkg.USER_ME AND ia.auditee_user_sid = SYS_CONTEXT('SECURITY', 'SID'))
	 WHERE fv.filter_field_id = in_filter_field_id;	
END;

PROCEDURE FilterAuditorCoordinatorSid (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		-- ensure the filter_value rows include all assigned to users for the current filter
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, user_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, ia.auditor_user_sid
		  FROM (
			SELECT DISTINCT auditor_user_sid
			  FROM internal_audit ia
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
			  ) ia
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.user_sid = ia.auditor_user_sid
		 );
	END IF;
	
	SELECT /*+ALL_ROWS CARDINALITY(ia, 10000) CARDINALITY(t, 10000) CARDINALITY(fv, 1000)*/
		   chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM internal_audit ia
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
	  JOIN chain.filter_value fv
		ON fv.user_sid = ia.auditor_user_sid
		OR (in_show_all = 0 AND fv.user_sid = chain.filter_pkg.USER_ME AND ia.auditor_user_sid = SYS_CONTEXT('SECURITY', 'SID'))
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterAuditor (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM internal_audit ia
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
	  JOIN chain.filter_value fv ON LOWER(ia.auditor_name) like '%'||LOWER(fv.str_value)||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id;	
END;

PROCEDURE FilterAuditorOrganisation (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM internal_audit ia
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
	  JOIN chain.filter_value fv ON LOWER(ia.auditor_organisation) like '%'||LOWER(fv.str_value)||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id;	
END;

PROCEDURE FilterNonCompliances (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_audit_type_group_key			IN  internal_audit_type_group.lookup_key%TYPE,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			chain.filter.compound_filter_id%TYPE;	
	v_non_compliance_ids			chain.T_FILTERED_OBJECT_TABLE;	
BEGIN
	v_compound_filter_id := chain.filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);
	
	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		-- convert audit ids to audit-non-compliance ids
		SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, NULL, NULL)
		  BULK COLLECT INTO v_non_compliance_ids
		  FROM audit_non_compliance anc
		  JOIN TABLE(in_ids) t ON anc.internal_audit_sid = t.object_id;
		  
		-- filter non-compliances
		non_compliance_report_pkg.GetFilteredIds(
			in_group_key					=> in_audit_type_group_key,
			in_compound_filter_id			=> v_compound_filter_id,
			in_id_list						=> v_non_compliance_ids,
			out_id_list						=> v_non_compliance_ids
		);
		
		-- convert audit-non-compliance ids to audit ids
		SELECT chain.T_FILTERED_OBJECT_ROW(internal_audit_sid, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT anc.internal_audit_sid
			  FROM audit_non_compliance anc
			  JOIN TABLE(v_non_compliance_ids) t ON anc.audit_non_compliance_id = t.object_id
			  JOIN TABLE(in_ids) iia ON anc.internal_audit_sid = iia.object_id
		  );
	END IF;
END;

PROCEDURE FilterCompanies (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			chain.filter.compound_filter_id%TYPE;	
	v_company_ids					chain.T_FILTERED_OBJECT_TABLE;	
BEGIN
	v_compound_filter_id := chain.filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);
	
	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		-- get company sids from audit sids
		SELECT chain.T_FILTERED_OBJECT_ROW(s.company_sid, NULL, NULL)
		  BULK COLLECT INTO v_company_ids
		  FROM csr.internal_audit ia
		  JOIN csr.supplier s ON s.region_sid = ia.region_sid
		  JOIN TABLE(in_ids) t ON ia.internal_audit_sid = t.object_id;
		  
		-- filter companies
		chain.company_filter_pkg.GetFilteredIds(
			in_search						=> NULL,
			in_group_key					=> NULL,
			in_compound_filter_id			=> v_compound_filter_id,
			in_id_list						=> v_company_ids,
			out_id_list						=> v_company_ids
		);
		
		-- convert audit sids from company sids
		SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM csr.internal_audit ia
		  JOIN csr.supplier s ON s.region_sid = ia.region_sid
		  JOIN TABLE(v_company_ids) t ON s.company_sid = t.object_id
		  JOIN TABLE(in_ids) iia ON ia.internal_audit_sid = iia.object_id;
	END IF;
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
	  FROM csr.internal_audit ia
	  JOIN csr.supplier s ON s.region_sid = ia.region_sid
	  JOIN TABLE(in_ids) t ON ia.internal_audit_sid = t.object_id;
		  
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
		
	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, in_group_by_index, t.group_by_value)
	  BULK COLLECT INTO out_ids
	  FROM csr.internal_audit ia
	  JOIN csr.supplier s ON s.region_sid = ia.region_sid
	  JOIN TABLE(v_company_sids) t ON s.company_sid = t.object_id
	  JOIN TABLE(in_ids) iia ON ia.internal_audit_sid = iia.object_id;
END;

PROCEDURE FilterAuditorCompanies (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			chain.filter.compound_filter_id%TYPE;	
	v_company_ids					chain.T_FILTERED_OBJECT_TABLE;	
BEGIN
	v_compound_filter_id := chain.filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);
	
	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		-- get company sids from audit sids
		SELECT chain.T_FILTERED_OBJECT_ROW(s.company_sid, NULL, NULL)
		  BULK COLLECT INTO v_company_ids
		  FROM csr.internal_audit ia
		  JOIN csr.supplier s ON s.company_sid = ia.auditor_company_sid
		  JOIN TABLE(in_ids) t ON ia.internal_audit_sid = t.object_id;
		  
		-- filter companies
		chain.company_filter_pkg.GetFilteredIds(
			in_search						=> NULL,
			in_group_key					=> NULL,
			in_compound_filter_id			=> v_compound_filter_id,
			in_id_list						=> v_company_ids,
			out_id_list						=> v_company_ids
		);
		
		-- convert audit sids from company sids
		SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM csr.internal_audit ia
		  JOIN csr.supplier s ON s.company_sid = ia.auditor_company_sid
		  JOIN TABLE(v_company_ids) t ON s.company_sid = t.object_id
		  JOIN TABLE(in_ids) iia ON ia.internal_audit_sid = iia.object_id;
	END IF;
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
	SELECT chain.T_FILTERED_OBJECT_ROW(s.company_sid, NULL, NULL)
	  BULK COLLECT INTO v_company_ids
	  FROM csr.internal_audit ia
	  JOIN csr.supplier s ON s.company_sid = ia.auditor_company_sid
	  JOIN TABLE(in_ids) t ON ia.internal_audit_sid = t.object_id;
		  
	-- filter companies
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
		
	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM csr.internal_audit ia
	  JOIN csr.supplier s ON s.company_sid = ia.auditor_company_sid
	  JOIN TABLE(v_company_ids) t ON s.company_sid = t.object_id
	  JOIN TABLE(in_ids) iia ON ia.internal_audit_sid = iia.object_id;
END;

PROCEDURE FilterSavedFilter (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_audit_type_group_key			IN  internal_audit_type_group.lookup_key%TYPE,
	in_group_by_index				IN	NUMBER,
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
			  FROM chain.v$filter_value fv
			  JOIN chain.saved_filter sf ON fv.saved_filter_sid_value = sf.saved_filter_sid
			 WHERE fv.filter_id = in_filter_id
			   AND fv.filter_field_id = in_filter_field_id
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
			  FROM chain.v$filter_value fv
			  JOIN chain.saved_filter sf ON fv.saved_filter_sid_value = sf.saved_filter_sid
			 WHERE fv.filter_id = in_filter_id
			   AND fv.filter_field_id = in_filter_field_id
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

FUNCTION GetPrimaryAuditColumnSid (
	in_col_sid						IN  security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	v_audit_oracle_column_sid		security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT atc.column_sid
		  INTO v_audit_oracle_column_sid
		  FROM cms.tab_column atc
		  JOIN cms.tab_column tc ON atc.tab_sid = tc.tab_sid
		 WHERE tc.column_sid = in_col_sid
		   AND atc.col_type = cms.tab_pkg.CT_INTERNAL_AUDIT;
	EXCEPTION
		WHEN no_data_found THEN
			BEGIN
				SELECT atc.column_sid
				  INTO v_audit_oracle_column_sid
				  FROM cms.tab_column atc
				  JOIN cms.tab_column tc ON atc.tab_sid = tc.tab_sid
				 WHERE tc.column_sid = in_col_sid
				   AND atc.oracle_column = 'INTERNAL_AUDIT_SID';
			EXCEPTION
				WHEN no_data_found THEN
					SELECT atc.column_sid
					  INTO v_audit_oracle_column_sid
					  FROM cms.tab_column atc
					  JOIN cms.tab_column tc ON atc.tab_sid = tc.tab_sid
					 WHERE tc.column_sid = in_col_sid
					   AND atc.oracle_column = 'AUDIT_SID';
			END;
	END;
	
	RETURN v_audit_oracle_column_sid;
END;

PROCEDURE FilterCmsEnumField (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name 			IN  chain.filter_field.name%TYPE,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_col_sid	 					security_pkg.T_SID_ID;
	v_audit_oracle_column_sid		security_pkg.T_SID_ID;
BEGIN
	v_col_sid := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);	
	v_audit_oracle_column_sid := GetPrimaryAuditColumnSid(v_col_sid);
	
	cms.filter_pkg.FilterCmsEnumField (
		in_enum_col_sid			=> v_col_sid,
		in_id_col_sid			=> v_audit_oracle_column_sid,
		in_filter_id			=> in_filter_id,
		in_filter_field_id		=> in_filter_field_id,
		in_group_by_index		=> in_group_by_index,
		in_show_all				=> in_show_all,
		in_ids					=> in_ids,
		in_filter_value_type	=> chain.filter_pkg.FILTER_VALUE_TYPE_NUMBER,
		out_ids					=> out_ids
	);
END;

PROCEDURE FilterTagGroup (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name			IN  chain.filter_field.name%TYPE,
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

	WITH group_tags AS (
		SELECT iat.app_sid, iat.internal_audit_sid, iat.tag_id
		  FROM internal_audit_tag iat
		  JOIN tag_group_member tgm ON tgm.app_sid = iat.app_sid AND tgm.tag_id = iat.tag_id
		 WHERE tgm.tag_group_id = v_tag_group_id)
	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, ff.group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM internal_audit ia
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
	  JOIN chain.filter_value fv ON fv.filter_field_id = in_filter_field_id
	  JOIN chain.filter_field ff ON ff.filter_field_id = fv.filter_field_id AND ff.app_sid = fv.app_sid
	 WHERE (fv.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			(ia.app_sid, ia.internal_audit_sid) NOT IN (SELECT app_sid, internal_audit_sid FROM group_tags))
		OR (fv.null_filter != chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			(ia.app_sid, ia.internal_audit_sid) IN (
				SELECT app_sid, internal_audit_sid
				  FROM group_tags gt
				 WHERE fv.null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL
					OR gt.tag_id = fv.num_value));
END;

PROCEDURE FilterInvolvementType (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name			IN  chain.filter_field.name%TYPE,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_involvement_type_id			NUMBER;
BEGIN
	v_involvement_type_id := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);

	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM internal_audit ia
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
	  JOIN flow_item_involvement fii ON fii.flow_item_id = ia.flow_item_id AND fii.app_sid = ia.app_sid
	  JOIN chain.filter_value fv ON (fii.user_sid = fv.user_sid OR (fv.user_sid = chain.filter_pkg.USER_ME AND fii.user_sid = SYS_CONTEXT('SECURITY', 'SID')))
	   AND fii.app_sid = fv.app_sid
	  JOIN chain.filter_field ff ON ff.filter_field_id = fv.filter_field_id AND fii.app_sid = fv.app_sid
	 WHERE ff.filter_id = in_filter_id
	   AND ff.filter_field_id = in_filter_field_id
	   AND fii.flow_involvement_type_id = v_involvement_type_id;
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
	SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM internal_audit ia
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ia.internal_audit_sid = t.object_id
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
		 WHERE tg.applies_to_audits = 1
		 ORDER BY tg.name;
	
	OPEN out_tag_group_members FOR
		SELECT t.tag_id id, t.tag label, tgm.tag_group_id
		  FROM csr.tag_group tg
		  JOIN csr.tag_group_member tgm ON tg.app_sid = tgm.app_sid AND tg.tag_group_id = tgm.tag_group_id
		  JOIN csr.v$tag t ON tgm.app_sid = t.app_sid AND tgm.tag_id = t.tag_id
		 WHERE tg.applies_to_audits = 1
		 ORDER BY tgm.pos;
END;

END audit_report_pkg;
/
