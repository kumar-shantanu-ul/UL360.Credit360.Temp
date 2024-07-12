CREATE OR REPLACE PACKAGE BODY CSR.issue_Pkg
IS

PROC_NOT_FOUND				EXCEPTION;
PRAGMA EXCEPTION_INIT(PROC_NOT_FOUND, -06550);

PROCEDURE INTERNAL_CallHelperPkg(
	in_procedure_name	IN	VARCHAR2,
	in_issue_id			IN	issue.issue_id%TYPE
)
AS
	v_helper_pkg		issue_type.helper_pkg%TYPE;
BEGIN
	-- call helper proc if there is one, to setup custom forms
	BEGIN
		SELECT it.helper_pkg
		  INTO v_helper_pkg
		  FROM issue i
		  JOIN issue_type it
		    ON i.issue_type_id = it.issue_type_id
		 WHERE i.issue_id = in_issue_id
		   AND i.app_sid = security_pkg.GetApp;
	EXCEPTION
		WHEN no_data_found THEN
			null;
	END;
	
	IF v_helper_pkg IS NOT NULL THEN
		BEGIN
			EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.'||in_procedure_name||'(:1);end;'
				USING in_issue_id;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
END;

PROCEDURE INTERNAL_CreateRefID_Issue(
	in_issue_id		IN	security_pkg.T_SID_ID
)
AS
	v_issue_ref_helper_func		csr.issue_type.internal_issue_ref_helper_func%TYPE;
	v_generated_number			NUMBER;
BEGIN
	-- Get the helper function to generate id
	SELECT it.internal_issue_ref_helper_func
	  INTO v_issue_ref_helper_func
	  FROM issue i
	  JOIN issue_type it
		ON it.issue_type_id = i.issue_type_id AND it.app_sid = i.app_sid
	 WHERE i.app_sid = security.security_pkg.GetApp
	   AND i.issue_id = in_issue_id;
	
	IF v_issue_ref_helper_func IS NOT NULL THEN	
		--todo: use PROC_NOT_FOUND (-06550) instead
		IF aspen2.utils_pkg.INTERNAL_FunctionExists(v_issue_ref_helper_func) THEN
			
			EXECUTE IMMEDIATE 'BEGIN :1 := ' || v_issue_ref_helper_func || '; END;' USING IN OUT v_generated_number; 	

			UPDATE csr.issue
			   SET issue_ref = v_generated_number
			 WHERE app_sid = security.security_pkg.GetApp
			   AND issue_id = in_issue_id;	
		ELSE 
			RAISE_APPLICATION_ERROR(-20001, 'Defined helper function could not be found: ' ||v_issue_ref_helper_func || ' (see csr.issue_type.internal_issue_ref_helper_func)' );
		END IF;
	END IF;
	
END;

PROCEDURE INTERNAL_CrazyJoin (
	in_issue_id					IN  issue.issue_id%TYPE,
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_is_read_only				IN	NUMBER,
	out_issue_cur				OUT SYS_REFCURSOR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_has_issue_management	NUMBER(1);
BEGIN
	v_user_sid := security_pkg.GetSID;
	
	v_has_issue_management := csr_data_pkg.SQL_CheckCapability('Issue management');

	-- consider passing through the indSid/regionSid in the url anchor? Then auto select the value and scroll into view?
	OPEN out_issue_cur FOR
		WITH i AS (
			SELECT vi.*, CASE 
				   WHEN ((deletable_by_owner = 1 AND owner_user_sid = v_user_sid) OR (deletable_by_administrator = 1 AND v_has_issue_management  = 1)
							OR (deletable_by_raiser = 1 AND raised_by_user_sid = v_user_sid)) THEN 1 ELSE 0 END can_be_deleted,
				   v_has_issue_management has_issue_mgt_capability,
				   CASE WHEN vi.assigned_to_user_sid = v_user_sid 
					 OR EXISTS (
						SELECT *
						  FROM issue_involvement ii
						  LEFT JOIN region_role_member rrm
							ON ii.role_sid = rrm.role_sid
						   AND v_user_sid = rrm.user_sid
						 WHERE vi.app_sid = ii.app_sid
						   AND vi.issue_id = ii.issue_id
						   AND NVL(ii.user_sid, rrm.user_sid) = v_user_sid
						   AND (rrm.region_sid IS NULL OR vi.region_sid = rrm.region_sid)
					) THEN 1 ELSE 0 END is_involved
			  FROM v$issue vi
			 WHERE issue_id = in_issue_id
		)
		SELECT crazy.*,
			CASE WHEN is_issue_type_region_editable = 1 AND create_raw = 1 AND (owner_user_sid = v_user_sid OR has_issue_mgt_capability = 1) THEN 1 ELSE 0 END is_region_editable
		  FROM (
			-- DELEGATIONS
			SELECT i.*, GetSheetUrl(c.editing_url, isv.ind_sid, isv.region_sid, isv.start_dtm, isv.end_dtm, in_user_sid) url,
				   null url_label,
				   null pending_val_id, isv.region_sid object_region_sid,
				   null non_compliance_id, in_is_read_only is_read_only
			  FROM i, customer c, issue_sheet_value isv
			 WHERE i.issue_id = in_issue_id
			   AND i.app_sid = c.app_sid
			   AND i.issue_sheet_value_id = isv.issue_sheet_value_id
			 UNION ALL
			-- Internal audit non-compliances
			SELECT i.*,
				   audit_pkg.GetIssueAuditUrlWithNonCompId(nc.created_in_audit_sid, nc.non_compliance_id) url,
				   'View audit' url_label,
				   null pending_val_id, ia.region_sid object_region_sid, inc.non_compliance_id, in_is_read_only is_read_only
			  FROM i 
			  LEFT JOIN issue_non_compliance inc ON i.issue_non_compliance_id = inc.issue_non_compliance_id AND i.app_sid = inc.app_sid
			  LEFT JOIN non_compliance nc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
			  LEFT JOIN internal_audit ia ON nc.created_in_audit_sid = ia.internal_audit_sid AND nc.app_sid = ia.app_sid
			  LEFT JOIN issue_type it ON i.issue_type_id = it.issue_type_id AND i.app_sid = it.app_sid
			 WHERE i.issue_id = in_issue_id
			   AND it.applies_to_audit = csr_data_pkg.IT_APPLIES_TO_AUDIT
			UNION ALL
			-- ACTIONS
			SELECT i.*,
				   i.source_url url,
				   'View action' url_label,
				   null pending_val_id, null object_region_sid, null  non_compliance_id, in_is_read_only is_read_only
			  FROM i, issue_action ia
			 WHERE i.issue_id = in_issue_id
			   AND i.app_sid = ia.app_sid
			   AND i.issue_action_id = ia.issue_action_id
			UNION ALL
			-- SCHEDULED TASK / CMS issue
			SELECT i.*,
				   i.source_url url,
				   'View form' url_label,
				   null pending_val_id, null object_region_sid, null non_compliance_id,  in_is_read_only is_read_only
			  FROM i
			 WHERE i.issue_id = in_issue_id
			   AND i.issue_type_id IN (csr_data_pkg.ISSUE_SCHEDULED_TASK, csr_data_pkg.ISSUE_CMS)
			UNION ALL
			-- METER
			SELECT i.*,
				   meter_pkg.GetIssueMeterUrl(im.issue_meter_id) url,
				   'View meter data' url_label,
				   null pending_val_id, im.region_sid object_region_sid, null non_compliance_id, in_is_read_only is_read_only
			  FROM i, issue_meter im
			 WHERE i.issue_id = in_issue_id
			   AND i.app_sid = im.app_sid
			   AND i.issue_meter_id = im.issue_meter_id
			UNION ALL
			-- METER ALARM
			SELECT i.*,
				   meter_alarm_pkg.GetAlarmUrl(ima.issue_meter_alarm_id) url,
				   'View meter data' url_label,
				   null pending_val_id, ima.region_sid object_region_sid, null non_compliance_id, in_is_read_only is_read_only
			  FROM i, issue_meter_alarm ima
			 WHERE i.issue_id = in_issue_id
			   AND i.app_sid = ima.app_sid
			   AND i.issue_meter_alarm_id = ima.issue_meter_alarm_id
			UNION ALL
			-- METER RAW DATA
			SELECT i.*,
				   meter_monitor_pkg.GetRawDataUrl(rd.issue_meter_raw_data_id) url,
				   'View raw data' url_label,
				   null pending_val_id, rd.region_sid object_region_sid, null non_compliance_id, in_is_read_only is_read_only
			  FROM i, issue_meter_raw_data rd
			 WHERE i.issue_id = in_issue_id
			   AND i.app_sid = rd.app_sid
			   AND i.issue_meter_raw_data_id = rd.issue_meter_raw_data_id
			UNION ALL
			-- METER DATA SOURCE
			SELECT i.*,
				   meter_monitor_pkg.GetDataSourceUrl(ds.issue_meter_data_source_id) url,
				   'View data source' url_label,
				   null pending_val_id, null object_region_sid, null non_compliance_id,  in_is_read_only is_read_only
			  FROM i, issue_meter_data_source ds
			 WHERE i.issue_id = in_issue_id
			   AND i.app_sid = ds.app_sid
			   AND i.issue_meter_data_source_id = ds.issue_meter_data_source_id
			UNION ALL
			-- METER MISSING DATA
			SELECT i.*,
				   meter_monitor_pkg.GetMissingDataUrl(md.issue_meter_missing_data_id) url,
				   'View missing data' url_label,
				   null pending_val_id, md.region_sid object_region_sid, null non_compliance_id, in_is_read_only is_read_only
			  FROM i, issue_meter_missing_data md
			 WHERE i.issue_id = in_issue_id
			   AND i.issue_meter_missing_data_id = md.issue_meter_missing_data_id
			   AND i.app_sid = md.app_sid
			UNION ALL
			-- BASIC ISSUE, ISSUE_ENQUIRY, INITIATIVE, PROPERTY, TEAMROOM, SURVEY
			SELECT i.*,
				   i.source_url url,
				   CASE
						WHEN i.issue_type_id = csr_data_pkg.ISSUE_INITIATIVE THEN 'Initiative'
						WHEN i.issue_type_id = csr_data_pkg.ISSUE_PROPERTY THEN 'Property'
						WHEN i.issue_type_id = csr_data_pkg.ISSUE_TEAMROOM THEN 'Teamroom'
						WHEN i.issue_type_id = csr_data_pkg.ISSUE_SURVEY_ANSWER THEN 'Survey answer'
						ELSE null
					END url_label,
				   null pending_val_id, null object_region_sid, null non_compliance_id,  in_is_read_only is_read_only
			  FROM i
			 WHERE i.issue_id = in_issue_id
			   AND i.issue_type_id IN (
					csr_data_pkg.ISSUE_BASIC, csr_data_pkg.ISSUE_ENQUIRY, csr_data_pkg.ISSUE_INITIATIVE, 
					csr_data_pkg.ISSUE_PROPERTY, csr_data_pkg.ISSUE_TEAMROOM, csr_data_pkg.ISSUE_SURVEY_ANSWER)
			 UNION ALL
			-- Supplier issues
			SELECT i.*,
				   '/csr/site/chain/manageCompany/manageCompany.acds?companySid='||isup.company_sid url,
				   'View supplier' url_label,
				   null pending_val_id, sup.region_sid object_region_sid, null non_compliance_id, in_is_read_only is_read_only
			  FROM i 
			  LEFT JOIN issue_supplier isup ON i.issue_supplier_id = isup.issue_supplier_id AND i.app_sid = isup.app_sid
			  LEFT JOIN supplier sup ON isup.company_sid = sup.company_sid AND isup.app_sid = sup.app_sid
			 WHERE i.issue_id = in_issue_id
			   AND i.issue_type_id IN (csr_data_pkg.ISSUE_SUPPLIER)
			UNION ALL
			-- Compliance issues
			SELECT i.*,
				   compliance_pkg.GetComplianceItemUrl(icr.flow_item_id) url,
				   'View compliance item' url_label,
				   null pending_val_id, null object_region_sid, null non_compliance_id, in_is_read_only is_read_only
			  FROM i
			  JOIN issue_compliance_region icr ON i.app_sid = icr.app_sid AND i.issue_compliance_region_id = icr.issue_compliance_region_id
			 WHERE i.issue_id = in_issue_id
			   AND i.issue_type_id = csr_data_pkg.ISSUE_COMPLIANCE
			UNION ALL
			-- Permits
			SELECT i.*,
				   permit_pkg.GetPermitUrl(i.permit_id) url,
				   'View permit' url_label,
				   null pending_val_id, null object_region_sid, null non_compliance_id, in_is_read_only is_read_only
			  FROM i
			  JOIN compliance_permit cp ON cp.app_sid = i.app_sid AND cp.compliance_permit_id = i.permit_id
			 WHERE i.issue_id = in_issue_id
			   AND i.issue_type_id = csr_data_pkg.ISSUE_PERMIT
			UNION ALL
			-- CUSTOMER ISSUE TYPES
			SELECT i.*,
				   i.source_url url,
				   null url_label,
				   null pending_val_id, null object_region_sid, null non_compliance_id,  in_is_read_only is_read_only
			  FROM i
			 WHERE i.issue_id = in_issue_id
			   AND i.issue_type_id >= 10000
		) crazy;
END;

PROCEDURE INTERNAL_StatusChanged (
	in_issue_id					IN	issue.issue_id%TYPE,
	in_issue_action_type_id		IN  NUMBER
)
AS
	v_issue_type_id				issue.issue_type_id%TYPE;
	v_raised_dtm				issue.raised_dtm%TYPE;
	v_resolved_dtm				issue.resolved_dtm%TYPE;
	v_manual_completion_dtm		issue.manual_completion_dtm%TYPE;
	v_rejected_dtm				issue.rejected_dtm%TYPE;
	v_min_audit_dtm				internal_audit.audit_dtm%TYPE;
	v_max_audit_dtm				internal_audit.audit_dtm%TYPE;
	v_issue_non_compliance_id	issue.issue_non_compliance_id%TYPE;
	v_applies_to_audit			issue_type.applies_to_audit%TYPE;
BEGIN
	SELECT i.issue_type_id, i.raised_dtm, i.resolved_dtm, i.manual_completion_dtm, i.rejected_dtm, i.issue_non_compliance_id, it.applies_to_audit
	  INTO v_issue_type_id, v_raised_dtm, v_resolved_dtm, v_manual_completion_dtm, v_rejected_dtm, v_issue_non_compliance_id, v_applies_to_audit
	  FROM issue i
	  JOIN issue_type it ON i.issue_type_id = it.issue_type_id
	 WHERE issue_id = in_issue_id;
	
	IF v_manual_completion_dtm IS NOT NULL THEN
		-- Manual completion date takes precedence over resolved date.
		v_resolved_dtm := v_manual_completion_dtm;
	END IF;

	IF v_applies_to_audit = csr_data_pkg.IT_APPLIES_TO_AUDIT THEN
		FOR r IN (
			SELECT non_compliance_id
			  FROM issue_non_compliance
			 WHERE issue_non_compliance_id = v_issue_non_compliance_id
		) LOOP
			audit_pkg.UpdateNonCompClosureStatus(r.non_compliance_id);
		END LOOP;
	END IF;
	
	FOR r IN (
		SELECT aggregate_ind_group_id
		  FROM issue_type_aggregate_ind_grp
		 WHERE issue_type_id = v_issue_type_id
	) LOOP
		IF v_applies_to_audit = csr_data_pkg.IT_APPLIES_TO_AUDIT THEN
			BEGIN
				SELECT MIN(ia.audit_dtm), MAX(ia.audit_dtm)
				  INTO v_min_audit_dtm, v_max_audit_dtm
				  FROM internal_audit ia
				  JOIN audit_non_compliance anc ON ia.internal_audit_sid = anc.internal_audit_sid
				  JOIN issue_non_compliance inc ON anc.non_compliance_id = inc.non_compliance_id
				  JOIN issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id
				 WHERE i.issue_id = in_issue_id;
				
				-- Issue might not have a non_compliance_id yet
				IF v_min_audit_dtm IS NOT NULL THEN
					calc_pkg.AddJobsForAggregateIndGroup(r.aggregate_ind_group_id,
						TRUNC(LEAST(v_raised_dtm, v_min_audit_dtm), 'MONTH'),
						ADD_MONTHS(TRUNC(GREATEST(NVL(v_resolved_dtm, v_raised_dtm), v_max_audit_dtm), 'MONTH'), 1));
				END IF;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					NULL;
			END;
		ELSE
			calc_pkg.AddJobsForAggregateIndGroup(r.aggregate_ind_group_id,
				TRUNC(NVL(LEAST(v_rejected_dtm, v_resolved_dtm, v_raised_dtm), v_raised_dtm), 'MONTH'),
				ADD_MONTHS(TRUNC(NVL(LEAST(v_rejected_dtm, v_resolved_dtm, v_raised_dtm), v_raised_dtm), 'MONTH'), 1));
		END IF;
	END LOOP;
	
	-- call helper procedures on certain events
	IF in_issue_action_type_id = csr_data_pkg.IAT_OPENED THEN	
		INTERNAL_CallHelperPkg('IssueOpened', in_issue_id);
		INTERNAL_CreateRefID_Issue(in_issue_id);
	ELSIF in_issue_action_type_id = csr_data_pkg.IAT_CLOSED THEN
		INTERNAL_CallHelperPkg('IssueClosed', in_issue_id);
	ELSIF in_issue_action_type_id = csr_data_pkg.IAT_RESOLVED THEN
		INTERNAL_CallHelperPkg('IssueResolved', in_issue_id);
	ELSIF in_issue_action_type_id = csr_data_pkg.IAT_REJECTED THEN
		INTERNAL_CallHelperPkg('IssueRejected', in_issue_id);
	END IF;		
END;

PROCEDURE INTERNAL_GetIssueActionLogs(
	in_issue_id				IN	issue.issue_id%TYPE,
	in_issue_log_id			IN	issue_log.issue_log_id%TYPE,
	in_issue_action_log_id	IN  issue_action_log.issue_action_log_id%TYPE,
	in_for_correspondent	IN  BOOLEAN,
	out_action_log_cur		OUT SYS_REFCURSOR
)
AS
	v_for_correspondent		NUMBER(1) DEFAULT CASE WHEN in_for_correspondent THEN 1 ELSE 0 END;
BEGIN
	OPEN out_action_log_cur FOR
		SELECT ial.issue_action_log_id, ial.issue_action_type_id, ial.issue_id, ial.issue_log_id, 
				ial.logged_by_user_sid, ial.logged_by_correspondent_id,
				lcu.user_name logged_by_user_name, NVL(lcu.full_name, c.full_name) logged_by_full_name, NVL(lcu.email, c.email) logged_by_email, 
				ial.logged_dtm, SYSDATE now_dtm, ial.assigned_to_role_sid, ar.name assigned_to_role_name,
				ial.assigned_to_user_sid, acu.user_name assigned_to_user_name, acu.full_name assigned_to_full_name, acu.email assigned_to_email,
				ial.owner_user_sid, ocu.user_name owner_user_name, ocu.full_name owner_full_name, ocu.email owner_email,
				ial.re_user_sid, reu.user_name re_user_name, reu.full_name re_full_name, reu.email re_email,
				ial.re_role_sid, rer.name re_role_name,
				ial.old_due_dtm, ial.new_due_dtm, ial.old_forecast_dtm, ial.new_forecast_dtm, ial.old_priority_id, ial.new_priority_id, ial.old_label, ial.new_label,
				ial.old_description, ial.new_description, ial.new_manual_comp_dtm_set_dtm, ial.new_manual_comp_dtm,
				ial.is_public, ial.involved_user_sid, ial.involved_user_sid_removed
		  FROM issue_action_log ial, csr_user lcu, role ar, csr_user acu, csr_user ocu, correspondent c, csr_user reu, role rer
		 WHERE ial.issue_id = in_issue_id
		   AND NVL(ial.issue_log_id, -1) = NVL(in_issue_log_id, NVL(ial.issue_log_id, -1))
		   AND ial.issue_action_log_id = NVL(in_issue_action_log_id, ial.issue_action_log_id)
		   AND ial.logged_by_user_sid = lcu.csr_user_sid(+)
		   AND ial.assigned_to_user_sid = acu.csr_user_sid(+)
		   AND ial.owner_user_sid = ocu.csr_user_sid(+)
		   AND ial.re_user_sid = reu.csr_user_sid(+)
		   AND ial.re_role_sid = rer.role_sid(+)
		   AND ial.assigned_to_role_sid = ar.role_sid(+)
		   AND ial.logged_by_correspondent_id = c.correspondent_id(+)
		   AND (
				   v_for_correspondent = 0
				OR ial.logged_by_correspondent_id IS NOT NULL 
				OR (
						ial.issue_action_type_id IN (csr_data_pkg.IAT_EMAILED_CORRESPONDENT, csr_data_pkg.IAT_RESOLVED, csr_data_pkg.IAT_REJECTED)
					AND ial.issue_log_id IN (
						SELECT issue_log_id 
						  FROM issue_action_log 
						 WHERE issue_id = in_issue_id
						   AND issue_action_type_id = csr_data_pkg.IAT_EMAILED_CORRESPONDENT
						)
					)
				)
 		 ORDER BY ial.logged_dtm, ial.issue_action_log_id DESC;
END;

PROCEDURE INTERNAL_GetIssueLogEntries(
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_issue_id				IN	issue.issue_id%TYPE,
	in_issue_log_id			IN	issue_log.issue_log_id%TYPE,
	in_for_correspondent	IN  BOOLEAN,
	out_cur_entries			OUT	SYS_REFCURSOR,
	out_cur_files			OUT	SYS_REFCURSOR,
	out_action_log_cur		OUT SYS_REFCURSOR
)
AS
	v_for_correspondent		NUMBER(1) DEFAULT CASE WHEN in_for_correspondent THEN 1 ELSE 0 END;
BEGIN
	OPEN out_cur_entries FOR
		SELECT il.issue_log_id, cu.csr_user_sid logged_by_user_sid, cu.user_name logged_by_user_name, il.logged_by_correspondent_id,
			  NVL(cu.full_name, c.full_name) logged_by_full_name, NVL(cu.email, c.email) logged_by_email, logged_dtm, message, 
			  param_1, param_2, param_3, is_system_generated, sysdate now_dtm,
		 	  CASE WHEN v_for_correspondent = 1 OR in_user_sid = il.logged_by_user_sid OR ilr.read_dtm IS NOT NULL THEN 1 ELSE 0 END is_read,
			  CASE WHEN cu.csr_user_sid = in_user_sid AND is_system_generated = 0 THEN 1 ELSE 0 END is_you
		  FROM issue_log il, csr_user cu, issue_log_read ilr, correspondent c
		 WHERE il.logged_by_user_sid = cu.csr_user_sid(+)
  		   AND il.issue_id = in_issue_id
  		   AND il.issue_log_id = NVL(in_issue_log_id, il.issue_log_id)
		   AND il.issue_log_id = ilr.issue_log_id(+) 
  		   AND ilr.csr_user_sid(+) = in_user_sid
  		   AND il.logged_by_correspondent_id = c.correspondent_id(+)
		   AND (
		   		   v_for_correspondent = 0
				OR il.logged_by_correspondent_id IS NOT NULL
				OR il.issue_log_id IN (
					SELECT issue_log_id 
					  FROM issue_action_log 
					 WHERE issue_id = in_issue_id
		  			   AND issue_action_type_id = csr_data_pkg.IAT_EMAILED_CORRESPONDENT
				))  		   
	     ORDER BY logged_dtm;
	
	OPEN out_cur_files FOR
		SELECT  ilf.filename, ilf.mime_type, ilf.sha1, ilf.uploaded_dtm, ilf.issue_log_id, ilf.issue_log_file_id, 
				LENGTH(ilf.data) file_size, ilf.archive_file_id, ilf.archive_file_size
		  FROM issue_log il, issue_log_file ilf
		 WHERE il.issue_id = in_issue_id
		   AND il.issue_log_id = NVL(in_issue_log_id, il.issue_log_id)
		   AND il.issue_log_id = ilf.issue_log_id
		   AND (
				   v_for_correspondent = 0
				OR il.logged_by_correspondent_id IS NOT NULL
				OR il.issue_log_id IN (
					SELECT issue_log_id 
					  FROM issue_action_log 
					 WHERE issue_id = in_issue_id
					   AND issue_action_type_id = csr_data_pkg.IAT_EMAILED_CORRESPONDENT
			)) 
		ORDER BY ilf.uploaded_dtm;
		 
	INTERNAL_GetIssueActionLogs(in_issue_id, in_issue_log_id, NULL, in_for_correspondent, out_action_log_cur);
END;

PROCEDURE INTERNAL_GetIssueCustomValues(
	in_issue_id				IN	issue.issue_id%TYPE,
	in_issue_type_id		IN	issue.issue_type_id%TYPE,
	out_custom_fields		OUT	SYS_REFCURSOR,
	out_custom_field_opts	OUT	SYS_REFCURSOR,
	out_custom_field_vals	OUT	SYS_REFCURSOR
)
AS
	v_permissible_cust_fields	security.T_SID_TABLE;
BEGIN
	v_permissible_cust_fields := GetPermissibleCustomFields(in_issue_type_id);

	OPEN out_custom_fields FOR
		SELECT i.issue_id, icf.issue_custom_field_id, icf.field_type, icf.label, icf.issue_type_id, icf.is_mandatory, icf.field_reference_name
		  FROM issue_custom_field icf
		  JOIN TABLE(v_permissible_cust_fields) pcf ON icf.issue_custom_field_id = pcf.column_value
		  JOIN issue i ON i.issue_type_id = icf.issue_type_id AND i.app_sid = icf.app_sid
		 WHERE i.issue_id = in_issue_id
		 ORDER BY icf.issue_type_id, icf.pos, lower(icf.label);

	OPEN out_custom_field_opts FOR
		SELECT icfo.issue_custom_field_id, icfo.issue_custom_field_opt_id, icfo.label
		  FROM issue_custom_field_option icfo
		  JOIN issue_custom_field icf ON icfo.issue_custom_field_id = icf.issue_custom_field_id AND icfo.app_sid = icf.app_sid
		  JOIN TABLE(v_permissible_cust_fields) pcf ON icf.issue_custom_field_id = pcf.column_value
		  JOIN issue i ON i.issue_type_id = icf.issue_type_id AND i.app_sid = icf.app_sid
		 WHERE i.issue_id = in_issue_id
		 ORDER BY icf.issue_type_id, icf.pos, lower(icfo.label);

	OPEN out_custom_field_vals FOR
		SELECT sv.issue_id, sv.issue_custom_field_id, sv.string_value, NULL issue_custom_field_opt_id, null date_value
		  FROM issue_custom_field_str_val sv
		  JOIN TABLE(v_permissible_cust_fields) pcf ON sv.issue_custom_field_id = pcf.column_value
		 WHERE sv.issue_id = in_issue_id
		 UNION
		SELECT sel.issue_id, sel.issue_custom_field_id, null, sel.issue_custom_field_opt_id, null date_value
		  FROM issue_custom_field_opt_sel sel
		  JOIN issue_custom_field icf ON sel.issue_custom_field_id = icf.issue_custom_field_id AND sel.app_sid = icf.app_sid
		  JOIN TABLE(v_permissible_cust_fields) pcf ON icf.issue_custom_field_id = pcf.column_value
		  JOIN issue i ON i.issue_id = sel.issue_id AND i.issue_type_id = icf.issue_type_id AND i.app_sid = icf.app_sid
		 WHERE sel.issue_id = in_issue_id
		 UNION
		SELECT dv.issue_id, dv.issue_custom_field_id, null string_value, null issue_custom_field_opt_id, dv.date_value
		  FROM issue_custom_field_date_val dv
		  JOIN TABLE(v_permissible_cust_fields) pcf ON dv.issue_custom_field_id = pcf.column_value
		 WHERE dv.issue_id = in_issue_id;
END;

PROCEDURE INTERNAL_GetIssueChildIssues (
	in_issue_id				IN	security_pkg.T_SID_ID,
	out_child_issues		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_child_issues FOR
		SELECT vi.issue_id, vi.label, vi.raised_dtm, vi.issue_type_id, vi.issue_type_label, 
		       vi.assigned_to_user_sid, vi.assigned_to_user_name, vi.assigned_to_full_name,  
			   vi.assigned_to_email, vi.assigned_to_role_sid, vi.assigned_to_role_name, 
			   vi.is_closed, vi.is_resolved, vi.is_rejected
		  FROM v$issue vi
		  JOIN issue i
		    ON vi.issue_id = i.issue_id
		 WHERE i.app_sid = security_pkg.GetApp
		   AND i.parent_id = in_issue_id;
END;

PROCEDURE INTERNAL_GetIssueParentIssue(
	in_issue_id				IN	security_pkg.T_SID_ID,
	out_parent_issue		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_parent_issue FOR
		SELECT vi.issue_id, vi.label, vi.raised_dtm, vi.issue_type_id, vi.issue_type_label, 
		       vi.assigned_to_user_sid, vi.assigned_to_user_name, vi.assigned_to_full_name,  
			   vi.assigned_to_email, vi.assigned_to_role_sid, vi.assigned_to_role_name, 
			   vi.is_closed, vi.is_resolved, vi.is_rejected
		  FROM v$issue vi
		  JOIN issue i
		    ON vi.issue_id = i.parent_id
		 WHERE i.app_sid = security_pkg.GetApp
		   AND i.issue_id = in_issue_id;
END;

PROCEDURE INTERNAL_GetIssueDueDetails(
	in_issue_id						IN	security_pkg.T_SID_ID,
	in_issue_log_id					IN	issue_log.issue_log_id%TYPE,
	out_due_cur						OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_due_cur FOR
		SELECT issue_id, in_issue_log_id issue_log_id, now_dtm, due_dtm, forecast_dtm, is_overdue, 
			   issue_priority_id, priority_overridden, issue_due_source_id, issue_due_offset_days, 
			   issue_due_offset_months, issue_due_offset_years, due_dtm_source_description
		  FROM v$issue
		 WHERE issue_id = in_issue_id;
END;


PROCEDURE LogAction (
	in_issue_action_type_id			IN  NUMBER,
	in_issue_id						IN  issue.issue_id%TYPE,
	in_issue_log_id					IN  issue_log.issue_log_id%TYPE DEFAULT NULL,
	in_user_sid						IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_re_user_sid					IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_re_role_sid					IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_correspondent_id				IN  correspondent.correspondent_id%TYPE DEFAULT NULL,
	out_issue_action_log_id			OUT issue_action_log.issue_action_log_id%TYPE
)
AS
	v_assigned_to_user_sid			security_pkg.T_SID_ID;
	v_assigned_to_role_sid			security_pkg.T_SID_ID;
	v_owned_by_sid					security_pkg.T_SID_ID;
	v_user_sid						security_pkg.T_SID_ID DEFAULT in_user_sid;
	v_old_due_dtm					issue_action_log.old_due_dtm%TYPE;
	v_new_due_dtm					issue_action_log.new_due_dtm%TYPE;
	v_old_forecast_dtm				issue_action_log.old_due_dtm%TYPE;
	v_new_forecast_dtm				issue_action_log.new_due_dtm%TYPE;
	v_old_priority_id				issue_action_log.old_priority_id%TYPE;
	v_new_priority_id				issue_action_log.new_priority_id%TYPE;
	v_old_label						issue_action_log.old_label%TYPE;
	v_new_label						issue_action_log.new_label%TYPE;
	v_old_description				issue_action_log.old_description%TYPE;
	v_new_description				issue_action_log.new_description%TYPE;
	v_old_region_sid				issue_action_log.old_region_sid%TYPE;
	v_new_region_sid				issue_action_log.new_region_sid%TYPE;
	v_new_man_comp_dtm_set_dtm		issue_action_log.new_manual_comp_dtm_set_dtm%TYPE;
	v_new_manual_comp_dtm			issue_action_log.new_manual_comp_dtm%TYPE;
	v_is_public						issue_action_log.is_public%TYPE;
	v_involved_user_sid				issue_action_log.involved_user_sid%TYPE;
	v_involved_user_sid_removed		issue_action_log.involved_user_sid_removed%TYPE;
	
BEGIN
	IF v_user_sid IS NULL AND in_correspondent_id IS NULL THEN
		v_user_sid := SYS_CONTEXT('SECURITY', 'SID');
	END IF;
	
	-- if it's an assignment action, look at who the issue is assigned to
	IF in_issue_action_type_id = csr_data_pkg.IAT_ASSIGNED OR
	   in_issue_action_type_id = csr_data_pkg.IAT_PENDING_ASSIGN_CONF THEN
	
		SELECT assigned_to_user_sid, assigned_to_role_sid
		  INTO v_assigned_to_user_sid, v_assigned_to_role_sid
		  FROM issue
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND issue_id = in_issue_id;
		
		INTERNAL_CallHelperPkg('IssueAssigned', in_issue_id);
		   
	-- if it's an owner changing action, look at who the issue is owned by
	ELSIF in_issue_action_type_id = csr_data_pkg.IAT_OWNER_CHANGED THEN
	
		SELECT owner_user_sid
		  INTO v_owned_by_sid
		  FROM issue
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND issue_id = in_issue_id;
	-- if we're changing the due date, grab the change
	ELSIF in_issue_action_type_id = csr_data_pkg.IAT_DUE_DATE_CHANGED THEN
	
		SELECT last_due_dtm, due_dtm
		  INTO v_old_due_dtm, v_new_due_dtm
		  FROM issue
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND issue_id = in_issue_id;
	-- if we're changing the forecast date, grab the change
	ELSIF in_issue_action_type_id = csr_data_pkg.IAT_FORECAST_DATE_CHANGED THEN
	
		SELECT last_forecast_dtm, forecast_dtm
		  INTO v_old_forecast_dtm, v_new_forecast_dtm
		  FROM issue
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND issue_id = in_issue_id;
	-- if we're changing the priority, grab the change
	ELSIF in_issue_action_type_id = csr_data_pkg.IAT_PRIORITY_CHANGED THEN
	
		SELECT last_issue_priority_id, issue_priority_id
		  INTO v_old_priority_id, v_new_priority_id
		  FROM issue
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND issue_id = in_issue_id;
	-- if we're changing the label, grab the change
	ELSIF in_issue_action_type_id = csr_data_pkg.IAT_LABEL_CHANGED THEN
	
		SELECT last_label, label
		  INTO v_old_label, v_new_label
		  FROM issue
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND issue_id = in_issue_id;
	-- if we're changing the description, grab the change
	ELSIF in_issue_action_type_id = csr_data_pkg.IAT_DESCRIPTION_CHANGED THEN
	
		SELECT last_description, description
		  INTO v_old_description, v_new_description
		  FROM issue
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND issue_id = in_issue_id;
	-- if we're changing the region, grab the change
	ELSIF in_issue_action_type_id = csr_data_pkg.IAT_REGION_CHANGED THEN
	
		SELECT i.last_region_sid, i.region_sid
		  INTO v_old_region_sid, v_new_region_sid
		  FROM issue i
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.issue_id = in_issue_id;
	-- We're resolving the issue. Grab the manually completed date.
	ELSIF in_issue_action_type_id = csr_data_pkg.IAT_RESOLVED THEN
		SELECT manual_comp_dtm_set_dtm, manual_completion_dtm
		  INTO v_new_man_comp_dtm_set_dtm, v_new_manual_comp_dtm
		  FROM issue
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND issue_id = in_issue_id;
	-- Public status is changing.
	ELSIF in_issue_action_type_id = csr_data_pkg.IAT_IS_PUBLIC_CHANGED THEN		   
		SELECT is_public
		  INTO v_is_public
		  FROM issue
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND issue_id = in_issue_id;
	-- Involved user added.
	ELSIF in_issue_action_type_id = csr_data_pkg.IAT_INVOLVED_USER_ASSIGNED THEN	
		v_involved_user_sid := in_re_user_sid;
	-- Involved user removed.
	ELSIF in_issue_action_type_id = csr_data_pkg.IAT_INVOLVED_USER_REMOVED THEN	
		v_involved_user_sid_removed := in_re_user_sid;
	END IF;
	
	INSERT INTO issue_action_log(
		issue_action_log_id, issue_action_type_id, issue_id, 
		issue_log_id, logged_by_user_sid, logged_by_correspondent_id, 
		assigned_to_role_sid, assigned_to_user_sid, re_user_sid, re_role_sid,
		owner_user_sid,
		old_due_dtm, new_due_dtm,
		old_forecast_dtm, new_forecast_dtm,
		old_priority_id, new_priority_id,
		old_label, new_label,
		old_description, new_description,
		old_region_sid, new_region_sid,
		new_manual_comp_dtm_set_dtm, new_manual_comp_dtm,
		is_public, involved_user_sid, involved_user_sid_removed
	)
	VALUES(
		issue_action_log_id_seq.NEXTVAL, in_issue_action_type_id, in_issue_id, 
		in_issue_log_id, v_user_sid, in_correspondent_id, 
		v_assigned_to_role_sid, v_assigned_to_user_sid, in_re_user_sid, in_re_role_sid,
		v_owned_by_sid,
		v_old_due_dtm, v_new_due_dtm,
		v_old_forecast_dtm, v_new_forecast_dtm,
		v_old_priority_id, v_new_priority_id,
		v_old_label, v_new_label,
		v_old_description, v_new_description,
		v_old_region_sid, v_new_region_sid,
		v_new_man_comp_dtm_set_dtm, v_new_manual_comp_dtm,
		v_is_public, v_involved_user_sid, v_involved_user_sid_removed
	) RETURNING issue_action_log_id INTO out_issue_action_log_id;	
END;

PROCEDURE LogAction (
	in_issue_action_type_id			IN  NUMBER,
	in_issue_id						IN  issue.issue_id%TYPE,
	in_issue_log_id					IN  issue_log.issue_log_id%TYPE DEFAULT NULL,
	in_user_sid						IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_re_user_sid					IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_re_role_sid					IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_correspondent_id				IN  correspondent.correspondent_id%TYPE DEFAULT NULL
)
AS
	v_action_log_id					issue_action_log.issue_action_log_id%TYPE;
BEGIN
	LogAction(in_issue_action_type_id, in_issue_id, in_issue_log_id, in_user_sid, in_re_user_sid, in_re_role_sid, in_correspondent_id, v_action_log_id);
END;

PROCEDURE INTERNAL_AddUserLogEntry(
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_is_system_generated		IN  issue_log.is_system_generated%TYPE,
	in_message					IN  issue_log.message%TYPE,
	in_param_1					IN	issue_log.param_1%TYPE,
	in_param_2					IN	issue_log.param_2%TYPE,
	in_param_3					IN	issue_log.param_3%TYPE,
	in_prevent_reassign			IN  BOOLEAN,
	in_prevent_reopen			IN  BOOLEAN,
	out_issue_log_id			OUT issue_log.issue_log_id%TYPE
)
AS	
	v_issue_log_count			NUMBER;
	v_dummy_cur					SYS_REFCURSOR;
BEGIN
	-- if this isn't system generated, then mark all previous entries as read
	IF in_is_system_generated = 0 THEN
		INSERT INTO issue_log_read
			(issue_log_id, csr_user_sid)
			SELECT issue_log_id, in_user_sid
			  FROM issue_log
			 WHERE issue_id = in_issue_id
			 MINUS -- subtract stuff they've read to avoid constraint violations
			SELECT issue_log_id, in_user_sid -- bit overkill since it subtracts all things a user has read
			  FROM issue_log_read
			 WHERE csr_user_sid = in_user_sid;
	END IF;
	
	INSERT INTO issue_log
		(issue_log_id, issue_id, message, logged_by_user_sid, logged_dtm, is_system_generated,
			param_1, param_2, param_3)
	VALUES
		(issue_log_id_seq.nextval, in_issue_id, in_message, in_user_sid, SYSDATE, in_is_system_generated,
			in_param_1, in_param_2, in_param_3)
	RETURNING issue_log_id
	     INTO out_issue_log_id;
		 
	SELECT COUNT(*)
	  INTO v_issue_log_count
	  FROM issue_log
	 WHERE issue_id = in_issue_id;
		 
	UPDATE issue
	   SET first_issue_log_id = CASE WHEN v_issue_log_count = 1 THEN out_issue_log_id ELSE first_issue_log_id END,
	       last_issue_log_id = out_issue_log_id
	 WHERE issue_id = in_issue_id
	   AND app_sid = security_pkg.GetApp;
	     
	IF NOT in_prevent_reopen THEN
		UPDATE issue 
		   SET resolved_by_user_sid = null, 
				resolved_dtm = null,
				closed_by_user_sid = null,
				closed_dtm = null,
				rejected_by_user_sid = null,
				rejected_dtm = null,
				correspondent_notified = 0,
				manual_completion_dtm = null,
				manual_comp_dtm_set_dtm = null
		 WHERE issue_id = in_issue_id
		   AND (resolved_by_user_sid IS NOT NULL OR closed_by_user_sid IS NOT NULL OR rejected_by_user_sid IS NOT NULL);

		IF SQL%ROWCOUNT > 0 THEN
			LogAction(csr_data_pkg.IAT_REOPENED, in_issue_id, out_issue_log_id);
			INTERNAL_StatusChanged(in_issue_id, csr_data_pkg.IAT_REOPENED);
		END IF;
	END IF;
	
	IF NOT in_prevent_reassign THEN

		AddUser(security_pkg.GetAct, in_issue_id, in_user_sid, v_dummy_cur);

		UPDATE issue
		   SET assigned_to_user_sid = in_user_sid,
			   assigned_to_role_sid = NULL
		 WHERE issue_id = in_issue_id
		   AND assigned_to_role_sid IS NOT NULL;

		IF SQL%ROWCOUNT > 0 THEN
			LogAction(csr_data_pkg.IAT_ASSIGNED, in_issue_id, out_issue_log_id);
		END IF;
	END IF;
END;

-- XXX: Change the issue_log to have a hierarchical structure
PROCEDURE INTERNAL_AddCorrespLogEntry (
	in_correspondent_id			IN  correspondent.correspondent_id%TYPE,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_message					IN  issue_log.message%TYPE,
	in_parent_dtm				IN  issue_action_log.logged_dtm%TYPE,
	out_issue_log_id			OUT issue_log.issue_log_id%TYPE
)
AS
	v_issue_log_count			NUMBER;
BEGIN
	INSERT INTO issue_log
		(issue_log_id, issue_id, message, logged_by_correspondent_id, logged_dtm, is_system_generated)
	VALUES
		(issue_log_id_seq.nextval, in_issue_id, in_message, in_correspondent_id, in_parent_dtm, 0)
	RETURNING issue_log_id
	     INTO out_issue_log_id;
		 
	SELECT COUNT(*)
	  INTO v_issue_log_count
	  FROM issue_log
	 WHERE issue_id = in_issue_id;
		 
	UPDATE issue
	   SET first_issue_log_id = CASE WHEN v_issue_log_count = 1 THEN out_issue_log_id ELSE first_issue_log_id END,
	       last_issue_log_id = out_issue_log_id
	 WHERE issue_id = in_issue_id
	   AND app_sid = security_pkg.GetApp;
	
	UPDATE issue 
	   SET resolved_by_user_sid = null, 
			resolved_dtm = null,
			closed_by_user_sid = null,
			closed_dtm = null,
			rejected_by_user_sid = null,
			rejected_dtm = null,
			correspondent_notified = 0,
			manual_completion_dtm = null,
			manual_comp_dtm_set_dtm = null
	 WHERE issue_id = in_issue_id
	   AND (resolved_by_user_sid IS NOT NULL OR closed_by_user_sid IS NOT NULL OR rejected_by_user_sid IS NOT NULL);

	IF SQL%ROWCOUNT > 0 THEN
		--LogAction(csr_data_pkg.IAT_REOPENED, in_issue_id, out_issue_log_id, NULL, NULL, NULL, in_correspondent_id);
		INTERNAL_StatusChanged(in_issue_id, csr_data_pkg.IAT_REOPENED);
	END IF;
END;

PROCEDURE INTERNAL_AddCorrespLogEntry (
	in_correspondent_id			IN  correspondent.correspondent_id%TYPE,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_message					IN  issue_log.message%TYPE,
	out_issue_log_id			OUT issue_log.issue_log_id%TYPE
)
AS
BEGIN
	INTERNAL_AddCorrespLogEntry(in_correspondent_id, in_issue_id, in_message, SYSDATE, out_issue_log_id);
END;

PROCEDURE INTERNAL_AddLogEntry(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_is_system_generated		IN  issue_log.is_system_generated%TYPE,
	in_message					IN  issue_log.message%TYPE,
	in_param_1					IN	issue_log.param_1%TYPE,
	in_param_2					IN	issue_log.param_2%TYPE,
	in_param_3					IN	issue_log.param_3%TYPE,
	in_prevent_reassign			IN  BOOLEAN,
	in_prevent_reopen			IN  BOOLEAN,
	out_issue_log_id			OUT issue_log.issue_log_id%TYPE
)
AS
	v_user_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(in_act_id, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied writing the issue with id '||in_issue_id);
	END IF;

	user_pkg.GetSid(in_act_id, v_user_sid);	
	
	INTERNAL_AddUserLogEntry(v_user_sid, in_issue_id, in_is_system_generated, in_message, in_param_1, in_param_2, in_param_3, in_prevent_reassign, in_prevent_reopen, out_issue_log_id);
END;

PROCEDURE AddLogEntry(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_is_system_generated		IN  issue_log.is_system_generated%TYPE,
	in_message					IN  issue_log.message%TYPE,
	in_param_1					IN	issue_log.param_1%TYPE,
	in_param_2					IN	issue_log.param_2%TYPE,
	in_param_3					IN	issue_log.param_3%TYPE,
	in_prevent_reassign			IN  BOOLEAN,
	out_issue_log_id			OUT issue_log.issue_log_id%TYPE
)
AS
	v_user_sid			security_pkg.T_SID_ID;
BEGIN
	INTERNAL_AddLogEntry(in_act_id, in_issue_id, in_is_system_generated, in_message, in_param_1, in_param_2, in_param_3, in_prevent_reassign, FALSE, out_issue_log_id);
END;

PROCEDURE AddLogEntry(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_is_system_generated		IN  issue_log.is_system_generated%TYPE,
	in_message					IN  issue_log.message%TYPE,
	in_param_1					IN	issue_log.param_1%TYPE,
	in_param_2					IN	issue_log.param_2%TYPE,
	in_param_3					IN	issue_log.param_3%TYPE,
	in_prevent_reassign			IN  NUMBER,
	out_issue_log_id			OUT issue_log.issue_log_id%TYPE
)
AS
BEGIN
	AddLogEntry(in_act_id, in_issue_id, in_is_system_generated, in_message, in_param_1, in_param_2, in_param_3, in_prevent_reassign = 1, out_issue_log_id);
END;

PROCEDURE AddCorrespondentLogEntry (
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_message					IN  issue_log.message%TYPE,
	out_issue_log_id			OUT issue_log.issue_log_id%TYPE
)
AS
	v_corr_id					correspondent.correspondent_id%TYPE;
	v_parent_dtm				issue_action_log.logged_dtm%TYPE;
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(in_act_id, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied writing the issue with id '||in_issue_id);
	END IF;
	
	SELECT correspondent_id
	  INTO v_corr_id
	  FROM issue
	 WHERE issue_id = in_issue_id;

	BEGIN
		SELECT logged_dtm
		  INTO v_parent_dtm
		  FROM issue_action_log
		 WHERE issue_id = in_issue_id
		   AND rownum <= 1
		 ORDER BY issue_action_log_id ASC;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_parent_dtm := SYSDATE;
	END;
	
	INTERNAL_AddCorrespLogEntry(v_corr_id, in_issue_id, in_message, v_parent_dtm, out_issue_log_id);
END;

PROCEDURE AddCorrespondentLogEntry (
	in_guid						IN  issue.guid%TYPE,
	in_message					IN  issue_log.message%TYPE,
	out_issue_log_id			OUT issue_log.issue_log_id%TYPE
)
AS
	v_issue_id					issue.issue_id%TYPE;
	v_corr_id 					correspondent.correspondent_id%TYPE;
BEGIN
	SELECT issue_id, correspondent_id
	  INTO v_issue_id, v_corr_id
	  FROM issue
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND guid = in_guid;
	
	INTERNAL_AddCorrespLogEntry(v_corr_id, v_issue_id, in_message, out_issue_log_id);  
END;

FUNCTION IsOwner(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_issue_id			IN	issue.issue_id%TYPE
) RETURN BOOLEAN
AS
	v_user_sid	security_pkg.T_SID_ID;
	v_cnt		NUMBER(10);
BEGIN
	-- okay -- if they're involved then they can do stuff to an issue (apart from delete it)
	user_pkg.GetSID(in_act_id, v_user_sid);
	
	-- are they the issue owner (by user)?
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM issue
	 WHERE issue_id = in_issue_id
	   AND owner_user_sid = v_user_sid;
	
	IF v_cnt > 0 THEN
		RETURN TRUE;
	END IF;

	-- are they the issue owner (by role)?
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM issue i, region_role_member rrm
	 WHERE i.issue_id = in_issue_id
	   AND i.region_sid = rrm.region_sid
	   AND i.owner_role_sid = rrm.role_sid
	   AND rrm.user_sid = v_user_sid;

	RETURN v_cnt > 0;
END;

FUNCTION IsRaiser(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_issue_id			IN	issue.issue_id%TYPE
) RETURN BOOLEAN
AS
	v_user_sid	security_pkg.T_SID_ID;
	v_cnt		NUMBER(10);
BEGIN
	user_pkg.GetSID(in_act_id, v_user_sid);

	SELECT COUNT(*)
	  INTO v_cnt
	  FROM issue
	 WHERE issue_id = in_issue_id
	   AND raised_by_user_sid = v_user_sid;
	
	RETURN v_cnt > 0;
END;

FUNCTION IsOwnerOfIssueCanBeChanged(
	in_issue_id			IN	issue.issue_id%TYPE
) RETURN BOOLEAN
AS
	v_owner_can_be_changed	NUMBER(10);
BEGIN
	SELECT it.owner_can_be_changed
	  INTO v_owner_can_be_changed
	  FROM issue i
	  JOIN issue_type it
	    ON it.issue_type_id = i.issue_type_id
	 WHERE i.issue_id = in_issue_id;
	
	RETURN NVL(v_owner_can_be_changed > 0, FALSE);
END;

FUNCTION ArePrioritiesEnabled  RETURN NUMBER
AS
	v_cnt		NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM issue_priority
	 WHERE app_sid = security_pkg.GetApp;

	IF v_cnt > 0 THEN
		RETURN 1;
	END IF;
	
	RETURN 0;
END;

FUNCTION HasRegionRootStartPoint  RETURN NUMBER
AS
	v_cnt		NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM customer c 
	  JOIN region_start_point rsp ON rsp.app_sid = c.app_sid AND c.region_root_sid = rsp.region_sid
	 WHERE user_sid = security.security_pkg.GetSid;

	IF v_cnt > 0 THEN
		RETURN 1;
	END IF;
	
	RETURN 0;
END;

/**
 * Checks to see if a user can access an issue (i.e. are they invovled or do they
 * have the capabiltiy).
 *
 * @param	in_act_id		Access token
 * @param	in_issue_id 	The issue ID
 */
FUNCTION IsAccessAllowed(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_issue_id			IN	issue.issue_id%TYPE
) RETURN BOOLEAN
AS
	v_user_sid	security_pkg.T_SID_ID;
	v_cnt		NUMBER(10);
BEGIN
	-- check if user is owner of issue or Built-in admin (for batch processes)
	IF IsOwner(in_act_id, in_issue_id) OR security_pkg.IsAdmin(in_act_id) THEN
		RETURN TRUE;
	END IF;
	
	-- now check capability (i.e. useful for Admins etc)
	IF csr_data_pkg.CheckCapability(in_act_id, 'Issue management') THEN
		RETURN TRUE;
	END IF;

	-- okay -- if they're involved or they line manage someone who
	-- is involved then they can do stuff to an issue (apart from delete it)
	user_pkg.GetSID(in_act_id, v_user_sid);
	
	SELECT COUNT(*) 
	  INTO v_cnt
	  FROM issue i
	  JOIN csr_user cu ON i.assigned_to_user_sid = cu.csr_user_sid
	 WHERE i.issue_id = in_issue_id
	   AND (i.assigned_to_user_sid = v_user_sid
	    OR cu.line_manager_sid = v_user_sid);
	   
	IF v_cnt > 0 THEN
		RETURN TRUE;
	END IF;

	-- This view includes involved roles
	SELECT COUNT(*) 
	  INTO v_cnt
	  FROM v$issue_involved_user iiu
	  JOIN csr_user cu ON iiu.user_sid = cu.csr_user_sid
	 WHERE iiu.issue_id = in_issue_id
	   AND (iiu.user_sid = v_user_sid
	    OR cu.line_manager_sid = v_user_sid);
	   
	IF v_cnt > 0 THEN
		RETURN TRUE;
	END IF;
	
	-- Check involved companies
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM issue_involvement
	 WHERE issue_id = in_issue_id
	   AND company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY');
	
	IF v_cnt > 0 THEN
		RETURN TRUE;
	END IF;
	
	-- If we have any involved users/roles then this is an issue with the new behaviour
	-- Someone with better knowledge of the system should update old issues with involved users based on action log
	-- so we can get rid of that last piece of query (I think).
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM v$issue_involved_user iiu
	 WHERE iiu.issue_id = in_issue_id;
	 
	IF v_cnt > 0 THEN
		RETURN FALSE;
	END IF;
	
	-- Old behaviour on previously assigned to roles (new behaviour keeps these
	-- as involved roles)
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM issue i, issue_action_log ial, region_role_member rrm
	 WHERE i.issue_id = in_issue_id
	   AND i.issue_id = ial.issue_id
	   AND i.region_sid = rrm.region_sid
	   AND ial.assigned_to_role_sid = rrm.role_sid
	   AND rrm.user_sid = v_user_sid;
	
	RETURN v_cnt > 0;
END;

PROCEDURE CreateIssue(
	in_label					IN  issue.label%TYPE,
	in_description				IN  issue_log.message%TYPE 					DEFAULT NULL,
	in_source_label				IN	issue.source_label%TYPE 				DEFAULT NULL,
	in_issue_type_id			IN	issue.issue_type_id%TYPE,
	in_correspondent_id			IN  issue.correspondent_id%TYPE 			DEFAULT NULL,
	in_raised_by_user_sid		IN	issue.raised_by_user_sid%TYPE 			DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	in_assigned_to_user_sid		IN	issue.assigned_to_user_sid%TYPE			DEFAULT NULL,
	in_assigned_to_role_sid		IN	issue.assigned_to_role_sid%TYPE			DEFAULT NULL,
	in_priority_id				IN	issue.issue_priority_id%TYPE 			DEFAULT NULL,
	in_due_dtm					IN	issue.due_dtm%TYPE						DEFAULT NULL,
	in_source_url				IN  issue.source_url%TYPE					DEFAULT NULL,
	in_region_sid				IN	security_pkg.T_SID_ID					DEFAULT NULL,
	in_is_urgent				IN	NUMBER									DEFAULT NULL,
	in_issue_due_source_id		IN	issue.issue_due_source_id%TYPE			DEFAULT NULL,
	in_issue_due_offset_days	IN	issue.issue_due_offset_days%TYPE		DEFAULT NULL,
	in_issue_due_offset_months	IN	issue.issue_due_offset_months%TYPE		DEFAULT NULL,
	in_issue_due_offset_years	IN	issue.issue_due_offset_years%TYPE		DEFAULT NULL,
	in_is_critical				IN	issue.is_critical%TYPE					DEFAULT 0,
	in_default_comment			IN	issue_raise_alert.issue_comment%TYPE 	DEFAULT NULL,
	out_issue_id				OUT issue.issue_id%TYPE
)
AS
	v_region_sid				security_pkg.T_SID_ID;
	v_issue_priority_id			issue_priority.issue_priority_id%TYPE;
	v_due_dtm_offset			issue_priority.due_date_offset%TYPE;
	-- we use v_now instead of sysdate since our view says that we must have date-time offset in order to be considered 'set'
	v_now						issue.raised_dtm%TYPE DEFAULT SYSDATE;
	v_issue_log_id				issue_log.issue_log_id%TYPE;
	v_is_public					issue.is_public%TYPE;
	v_send_alert_on_raise		issue_type.send_alert_on_issue_raised%TYPE;
	v_allow_critical			issue_type.allow_critical%TYPE;
	v_allow_urgent_alert		issue_type.allow_urgent_alert%TYPE;
BEGIN
	SELECT NVL(in_region_sid, default_region_sid)
	  INTO v_region_sid
	  FROM issue_type
	 WHERE issue_type_id = in_issue_type_id;

	IF in_due_dtm IS NULL THEN
		BEGIN
			SELECT ip.issue_priority_id, ip.due_date_offset
			  INTO v_issue_priority_id, v_due_dtm_offset
			  FROM issue_type it, issue_priority ip
			 WHERE it.issue_type_id = in_issue_type_id
			   AND it.default_issue_priority_id = ip.issue_priority_id;
		EXCEPTION 
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
	END IF;

	IF in_priority_id IS NOT NULL THEN
		BEGIN
			SELECT ip.issue_priority_id, ip.due_date_offset
			  INTO v_issue_priority_id, v_due_dtm_offset
			  FROM issue_priority ip
			 WHERE ip.issue_priority_id = in_priority_id;
		EXCEPTION 
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
	END IF;
	
	-- issue is not public by default.
	v_is_public := 0;
	
	-- but it can be public if public_by_default is set to 1 (for the issue type to be created)
	SELECT public_by_default, send_alert_on_issue_raised, allow_urgent_alert, allow_critical
	  INTO v_is_public, v_send_alert_on_raise, v_allow_urgent_alert, v_allow_critical
	  FROM issue_type
	 WHERE issue_type_id = in_issue_type_id;

	INSERT INTO issue
	(issue_id, label, description, source_label, raised_dtm, raised_by_user_sid, 
	owner_user_sid, owner_role_sid,
	issue_type_id, assigned_to_user_sid, due_dtm, 
	region_sid, correspondent_id, issue_priority_id, first_priority_set_dtm, source_url, is_public,
	issue_due_source_id, issue_due_offset_days, issue_due_offset_months, issue_due_offset_years, is_critical)
	VALUES
	(issue_id_seq.NEXTVAL, in_label, in_description, in_source_label, v_now, in_raised_by_user_sid, 
	NVL(in_raised_by_user_sid, in_assigned_to_user_sid), CASE WHEN in_raised_by_user_sid IS NULL THEN in_assigned_to_role_sid ELSE NULL END,
	in_issue_type_id, NVL(in_assigned_to_user_sid, in_raised_by_user_sid), NVL(in_due_dtm, v_now + v_due_dtm_offset),
	v_region_sid, in_correspondent_id, v_issue_priority_id, CASE WHEN v_issue_priority_id IS NULL THEN NULL ELSE SYSDATE END, in_source_url, v_is_public,
	in_issue_due_source_id, in_issue_due_offset_days, in_issue_due_offset_months, in_issue_due_offset_years, DECODE(v_allow_critical + in_is_critical, 2, 1, 0))
	RETURNING issue_id INTO out_issue_id;
	
	-- Send an alert if required
	IF (v_allow_urgent_alert = 1 AND in_is_urgent = 1) OR (in_is_urgent IS NULL and v_send_alert_on_raise = 1) THEN
		INSERT INTO issue_raise_alert (issue_id, raised_by_user_sid, issue_comment)
		VALUES (out_issue_id, in_raised_by_user_sid, NVL(in_default_comment, in_label));
	END IF;

	-- Add raised user as an involved user.
	IF in_raised_by_user_sid IS NOT NULL THEN
		INSERT INTO issue_involvement
		(issue_id, is_an_owner, user_sid)
		VALUES
		(out_issue_id, 1, in_raised_by_user_sid);
	END IF;
	
	IF in_assigned_to_user_sid IS NOT NULL THEN
		BEGIN
			INSERT INTO issue_involvement
			(issue_id, is_an_owner, user_sid)
			VALUES
			(out_issue_id, 1, in_assigned_to_user_sid);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END IF;
	
	IF in_assigned_to_role_sid IS NOT NULL THEN
		INSERT INTO issue_involvement
		(issue_id, is_an_owner, role_sid)
		VALUES
		(out_issue_id, 0, in_assigned_to_role_sid);
	END IF;

	LogAction(csr_data_pkg.IAT_OPENED, out_issue_id, NULL, in_raised_by_user_sid);
	
	IF in_assigned_to_role_sid IS NOT NULL OR in_assigned_to_user_sid IS NOT NULL THEN
		-- this will blow up if they're both set
		UPDATE issue
		   SET assigned_to_user_sid = in_assigned_to_user_sid,
		       assigned_to_role_sid = in_assigned_to_role_sid
		 WHERE issue_id = out_issue_id;
				
		LogAction(csr_data_pkg.IAT_ASSIGNED, out_issue_id, NULL, in_raised_by_user_sid);
	END IF;
	
	INTERNAL_StatusChanged(out_issue_id, csr_data_pkg.IAT_OPENED);
	
	chain.filter_pkg.ClearCacheForAllUsers (
		in_card_group_id => chain.filter_pkg.FILTER_TYPE_ISSUES
	);
END;

FUNCTION CreateCorrespondent (
	in_full_name				IN  correspondent.full_name%TYPE,
	in_email					IN  correspondent.email%TYPE,
	in_phone					IN  correspondent.phone%TYPE,
	in_more_info_1				IN  correspondent.more_info_1%TYPE
) RETURN correspondent.correspondent_id%TYPE
AS
	v_correspondent_id			correspondent.correspondent_id%TYPE;
BEGIN
	-- not sure what security to put on here as it needs to be publicly accessible
	BEGIN
		INSERT INTO correspondent
		(correspondent_id, full_name, email, phone, guid, more_info_1)
		VALUES
		(correspondent_id_seq.NEXTVAL, in_full_name, TRIM(in_email), in_phone, user_pkg.RawAct, in_more_info_1)
		RETURNING correspondent_id INTO v_correspondent_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE correspondent
			   SET full_name = in_full_name,
				   phone = NVL(in_phone, phone),
				   more_info_1 = NVL(in_more_info_1, more_info_1)
			 WHERE LOWER(email) = LOWER(TRIM(in_email))
			RETURNING correspondent_id INTO v_correspondent_id;
	END;
	
	RETURN v_correspondent_id;
END;

PROCEDURE EmailCorrespondent (
	in_issue_id					IN  issue.issue_id%TYPE,
	in_issue_log_id				IN  issue_log.issue_log_id%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_count						NUMBER(10);
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(SYS_CONTEXT('SECURITY', 'ACT'), in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied reading the issue with id '||in_issue_id);
	END IF;
		
	UPDATE issue
	   SET guid = user_pkg.RawAct
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND issue_id = in_issue_id
	   AND guid IS NULL
	   AND correspondent_id IS NOT NULL;
	
	-- erg - duplicate statements - make sure that you update both!
	SELECT COUNT(*) 
	  INTO v_count
	  FROM issue i, correspondent c, issue_priority ip
	 WHERE i.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND i.app_sid = c.app_sid
	   AND i.app_sid = ip.app_sid(+)
	   AND i.issue_id = in_issue_id
	   AND i.issue_priority_id = ip.issue_priority_id(+)
	   AND i.correspondent_id = c.correspondent_id
	   AND c.email IS NOT NULL; 
	
	-- erg - duplicate statements - make sure that you update both!
	OPEN out_cur FOR
		SELECT i.issue_id, i.guid, c.full_name, c.email, i.issue_priority_id, ip.due_date_offset priority_due_date_offset, ip.description priority_description, i.due_dtm
		  FROM issue i, correspondent c, issue_priority ip
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND i.app_sid = c.app_sid
		   AND i.app_sid = ip.app_sid(+)
		   AND i.issue_id = in_issue_id
		   AND i.issue_priority_id = ip.issue_priority_id(+)
		   AND i.correspondent_id = c.correspondent_id
		   AND c.email IS NOT NULL;

	IF v_count > 0 THEN
		LogAction(csr_data_pkg.IAT_EMAILED_CORRESPONDENT, in_issue_id, in_issue_log_id);
	END IF;
END;

PROCEDURE EmailUser (
	in_issue_id					IN  issue.issue_id%TYPE,
	in_issue_log_id				IN  issue_log.issue_log_id%TYPE,
	in_user_sid					IN  security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(SYS_CONTEXT('SECURITY', 'ACT'), in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied reading the issue with id '||in_issue_id);
	END IF;
	
	LogAction(csr_data_pkg.IAT_EMAILED_USER, in_issue_id, in_issue_log_id, NULL, in_user_sid);
	
	UPDATE issue
	   SET guid = user_pkg.RawAct
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND issue_id = in_issue_id
	   AND guid IS NULL;
	
	OPEN out_cur FOR
		SELECT i.issue_id, i.guid, u.full_name, u.email, i.issue_priority_id, ip.due_date_offset priority_due_date_offset, ip.description priority_description, i.due_dtm
		  FROM issue i, csr_user u, issue_priority ip
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND i.app_sid = u.app_sid
		   AND i.app_sid = ip.app_sid(+)
		   AND i.issue_id = in_issue_id
		   AND i.issue_priority_id = ip.issue_priority_id(+)
		   AND u.csr_user_sid = in_user_sid;
END;

PROCEDURE EmailRole (
	in_issue_id					IN  issue.issue_id%TYPE,
	in_issue_log_id				IN  issue_log.issue_log_id%TYPE,
	in_role_sid					IN  security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(SYS_CONTEXT('SECURITY', 'ACT'), in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied reading the issue with id '||in_issue_id);
	END IF;
	
	LogAction(csr_data_pkg.IAT_EMAILED_ROLE, in_issue_id, in_issue_log_id, NULL, NULL, in_role_sid);
	
	UPDATE issue
	   SET guid = user_pkg.RawAct
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND issue_id = in_issue_id
	   AND guid IS NULL;
	
	OPEN out_cur FOR
		SELECT i.issue_id, i.guid, u.full_name, u.email, i.issue_priority_id, ip.due_date_offset priority_due_date_offset, ip.description priority_description, i.due_dtm
		  FROM issue i, csr_user u, region_role_member rrm, issue_priority ip
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND i.app_sid = u.app_sid
		   AND i.app_sid = rrm.app_sid
		   AND i.app_sid = ip.app_sid(+)
		   AND i.issue_id = in_issue_id
		   AND i.issue_priority_id = ip.issue_priority_id(+)
		   AND i.region_sid = rrm.region_sid
		   AND rrm.role_sid = in_role_sid
		   AND rrm.user_sid = u.csr_user_sid;
END;

PROCEDURE INTERNAL_GetIssueType(
	in_issue_type_id		IN	issue_custom_field.issue_type_id%TYPE,
	in_lookup_key			IN	issue_type.lookup_key%TYPE,
	out_issue_type_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_issue_type_cur FOR
		SELECT issue_type_id, label, default_region_sid, default_issue_priority_id, 
		       allow_children, require_priority, can_set_public, public_by_default, alert_pending_due_days, alert_overdue_days, auto_close_after_resolve_days,
			   allow_pending_assignment, show_forecast_dtm, require_var_expl, enable_reject_action, restrict_users_to_region,
			   deletable_by_owner , deletable_by_administrator, send_alert_on_issue_raised, show_one_issue_popup, lookup_key, get_assignables_sp, is_region_editable,
			   enable_manual_comp_date, comment_is_optional, due_date_is_mandatory, allow_critical, allow_urgent_alert,
			   email_involved_roles, email_involved_users, region_is_mandatory
		  FROM issue_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		 -- If no issue type id is passed, use lookup key (vice versa).
		   AND (
				(
					in_issue_type_id IS NOT NULL
					AND in_issue_type_id = issue_type_id
				)
				OR (
					in_issue_type_id IS NULL
					AND (
							(
								in_lookup_key IS NOT NULL
								AND in_lookup_key = lookup_key
							)
							OR (
								in_lookup_key IS NULL
								AND lookup_key IS NULL
							)
						)
					)
				)
		   AND deleted = 0;
END;

PROCEDURE GetIssueType(
	in_issue_type_id		IN	issue_custom_field.issue_type_id%TYPE,
	out_issue_type_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	INTERNAL_GetIssueType(in_issue_type_id, NULL, out_issue_type_cur);
END;

PROCEDURE GetIssueType(
	in_lookup_key			IN	issue_type.lookup_key%TYPE,
	out_issue_type_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	INTERNAL_GetIssueType(NULL, in_lookup_key, out_issue_type_cur);
END;

PROCEDURE GetIssueType(
	in_issue_type_id		IN	issue_custom_field.issue_type_id%TYPE,
	out_issue_type_cur		OUT	SYS_REFCURSOR,
	out_custom_fields		OUT SYS_REFCURSOR,
	out_custom_field_opts	OUT	SYS_REFCURSOR
)
AS
	v_permissible_cust_fields	security.T_SID_TABLE;
BEGIN
	GetIssueType(in_issue_type_id, out_issue_type_cur);
	v_permissible_cust_fields := GetPermissibleCustomFields(in_issue_type_id);

	OPEN out_custom_fields FOR
		SELECT icf.issue_custom_field_id, icf.field_type, icf.label, icf.is_mandatory, icf.field_reference_name
		  FROM issue_custom_field icf
		  JOIN TABLE(v_permissible_cust_fields) pcf ON icf.issue_custom_field_id = pcf.column_value
		 WHERE icf.issue_type_id = in_issue_type_id
		 ORDER BY icf.issue_type_id, icf.pos, lower(icf.label);

	OPEN out_custom_field_opts FOR
		SELECT icfo.issue_custom_field_id, icfo.issue_custom_field_opt_id, icfo.label
		  FROM issue_custom_field_option icfo
		  JOIN issue_custom_field icf ON icfo.issue_custom_field_id = icf.issue_custom_field_id AND icfo.app_sid = icf.app_sid
		  JOIN TABLE(v_permissible_cust_fields) pcf ON icf.issue_custom_field_id = pcf.column_value
		 WHERE icf.issue_type_id = in_issue_type_id
		 ORDER BY icf.issue_type_id, icf.pos, lower(icf.label);
END;

PROCEDURE GetIssueType(
	in_issue_type_id		IN	issue_custom_field.issue_type_id%TYPE,
	out_issue_type_cur		OUT	SYS_REFCURSOR,
	out_custom_fields		OUT SYS_REFCURSOR,
	out_custom_field_opts	OUT	SYS_REFCURSOR,
	out_due_dtm_sources		OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetIssueType(
		in_issue_type_id, 
		out_issue_type_cur, 
		out_custom_fields, 
		out_custom_field_opts
	);

	OPEN out_due_dtm_sources FOR
		SELECT issue_due_source_id, issue_type_id, source_description
		  FROM issue_due_source
		 WHERE issue_type_id = in_issue_type_id;
END;

PROCEDURE GetIssueTypes (
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetIssueTypes(0, out_cur);
END;

PROCEDURE GetIssueTypes (
	in_only_creatable			IN  NUMBER,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no sec checks

	OPEN out_cur FOR
		SELECT issue_type_id, label, lookup_key, default_region_sid, default_issue_priority_id, 
			   allow_children, require_priority, require_due_dtm_comment, can_set_public, public_by_default,
			   email_involved_roles, email_involved_users, restrict_users_to_region,
			   alert_pending_due_days, alert_overdue_days, auto_close_after_resolve_days, owner_can_be_changed, 
			   allow_pending_assignment, deletable_by_owner, deletable_by_raiser, deletable_by_administrator, show_forecast_dtm,
			   require_var_expl, enable_reject_action, send_alert_on_issue_raised, show_one_issue_popup, allow_owner_resolve_and_close, 
			   get_assignables_sp, is_region_editable, create_raw, enable_manual_comp_date, comment_is_optional, due_date_is_mandatory,
			   allow_critical, allow_urgent_alert, region_is_mandatory
		  FROM issue_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND (in_only_creatable = 0 OR create_raw = 1)
		   AND deleted = 0
		 ORDER BY position, LOWER(label);
END;

PROCEDURE GetRagOptions (
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no sec checks
	
	OPEN out_cur FOR
		SELECT rag_status_id, colour, label, lookup_key 
		  FROM rag_status
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')		   
		 ORDER BY LOWER(label);
END;

PROCEDURE AllowCustomIssueTypes (
	out_allow_custom_issue_types		OUT customer.allow_custom_issue_types%TYPE
) 
AS
BEGIN
	SELECT allow_custom_issue_types
	  INTO out_allow_custom_issue_types
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
END;

FUNCTION AllowCustomIssueTypes
RETURN BOOLEAN
AS
	v_result							customer.allow_custom_issue_types%TYPE;
BEGIN
	AllowCustomIssueTypes(v_result);
	RETURN v_result = 1;
END;

PROCEDURE SaveIssueType (
	in_issue_type_id				IN  issue_type.issue_type_id%TYPE,
	in_label						IN  issue_type.label%TYPE,
	in_lookup_key					IN	issue_type.lookup_key%TYPE,
	in_allow_children				IN  issue_type.allow_children%TYPE,
	in_require_priority				IN  issue_type.require_priority%TYPE,
	in_require_due_dtm_comment		IN	issue_type.require_due_dtm_comment%TYPE,
	in_can_set_public				IN	issue_type.can_set_public%TYPE,
	in_public_by_default			IN	issue_type.public_by_default%TYPE,
	in_email_involved_roles			IN	issue_type.email_involved_roles%TYPE,
	in_email_involved_users			IN	issue_type.email_involved_users%TYPE,
	in_restrict_users_to_region		IN	issue_type.restrict_users_to_region%TYPE,
	in_default_priority_id			IN  issue_type.default_issue_priority_id%TYPE,
	in_alert_pending_due_days		IN  issue_type.alert_pending_due_days%TYPE,
	in_alert_overdue_days			IN  issue_type.alert_overdue_days%TYPE,
	in_auto_close_days				IN  issue_type.auto_close_after_resolve_days%TYPE,
	in_deletable_by_owner   		IN  issue_type.deletable_by_owner%TYPE,
	in_deletable_by_raiser   		IN  issue_type.deletable_by_raiser%TYPE,
	in_deletable_by_administrator   IN  issue_type.deletable_by_administrator%TYPE,
	in_owner_can_be_changed			IN  issue_type.owner_can_be_changed%TYPE,
	in_show_forecast_dtm			IN  issue_type.show_forecast_dtm%TYPE,
	in_require_var_expl				IN  issue_type.require_var_expl%TYPE,
	in_enable_reject_action			IN  issue_type.enable_reject_action%TYPE,
	in_snd_alrt_on_issue_raised		IN  issue_type.send_alert_on_issue_raised%TYPE,
	in_show_one_issue_popup			IN  issue_type.show_one_issue_popup%TYPE,
	in_allow_owner_resolve_close	IN  issue_type.allow_owner_resolve_and_close%TYPE,
	in_is_region_editable			IN  issue_type.is_region_editable%TYPE,
	in_enable_manual_comp_date		IN  issue_type.enable_manual_comp_date%TYPE,
	in_comment_is_optional			IN	issue_type.comment_is_optional%TYPE,
	in_due_date_is_mandatory		IN	issue_type.due_date_is_mandatory%TYPE,
	in_allow_critical				IN	issue_type.allow_critical%TYPE,
	in_allow_urgent_alert			IN	issue_type.allow_urgent_alert%TYPE,
	in_region_is_mandatory			IN	issue_type.region_is_mandatory%TYPE,
	out_issue_type_id				OUT issue_type.issue_type_id%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Issue management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied managing issues');
	END IF;

	IF NVL(in_issue_type_id, 0) = 0 THEN
		IF NOT AllowCustomIssueTypes THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied creating customer issue types');
		END IF;

		INSERT INTO issue_type 
		(issue_type_id, label, allow_children, require_priority, require_due_dtm_comment, can_set_public, public_by_default, email_involved_roles, email_involved_users,
		 restrict_users_to_region, default_issue_priority_id, alert_pending_due_days, alert_overdue_days, auto_close_after_resolve_days, create_raw, deletable_by_owner,
		 deletable_by_raiser, deletable_by_administrator, show_forecast_dtm, owner_can_be_changed, send_alert_on_issue_raised, show_one_issue_popup, lookup_key,
		 allow_owner_resolve_and_close, is_region_editable, enable_manual_comp_date, comment_is_optional, due_date_is_mandatory, allow_critical, allow_urgent_alert,
		 region_is_mandatory)
		VALUES
		(issue_type_id_seq.nextval, in_label, in_allow_children, in_require_priority, in_require_due_dtm_comment, in_can_set_public, in_public_by_default,
		in_email_involved_roles, in_email_involved_users, in_restrict_users_to_region,
		in_default_priority_id, in_alert_pending_due_days, in_alert_overdue_days, in_auto_close_days, 1, in_deletable_by_owner, in_deletable_by_raiser, in_deletable_by_administrator, in_show_forecast_dtm, in_owner_can_be_changed, 
		in_snd_alrt_on_issue_raised, in_show_one_issue_popup, in_lookup_key, in_allow_owner_resolve_close, in_is_region_editable, in_enable_manual_comp_date, in_comment_is_optional, in_due_date_is_mandatory, in_allow_critical,
		in_allow_urgent_alert, in_region_is_mandatory)
		RETURNING issue_type_id INTO out_issue_type_id;
	ELSE
		UPDATE issue_type
		   SET label = in_label,
			   allow_children = in_allow_children,
			   require_priority = in_require_priority,
			   require_due_dtm_comment = in_require_due_dtm_comment,
			   can_set_public = in_can_set_public,
			   public_by_default = in_public_by_default,
			   email_involved_roles = in_email_involved_roles,
			   email_involved_users = in_email_involved_users,
			   restrict_users_to_region = in_restrict_users_to_region,
			   default_issue_priority_id = in_default_priority_id,
			   alert_pending_due_days = in_alert_pending_due_days,
			   alert_overdue_days = in_alert_overdue_days,
			   auto_close_after_resolve_days = in_auto_close_days,
			   deletable_by_owner = in_deletable_by_owner,
			   deletable_by_raiser = in_deletable_by_raiser,
			   deletable_by_administrator = in_deletable_by_administrator,
			   owner_can_be_changed = in_owner_can_be_changed,
			   show_forecast_dtm = in_show_forecast_dtm,
			   require_var_expl = in_require_var_expl,
			   enable_reject_action = in_enable_reject_action,
			   send_alert_on_issue_raised = in_snd_alrt_on_issue_raised,
			   show_one_issue_popup = in_show_one_issue_popup,
			   lookup_key = in_lookup_key,
			   allow_owner_resolve_and_close = in_allow_owner_resolve_close,
			   is_region_editable = in_is_region_editable,
			   enable_manual_comp_date = in_enable_manual_comp_date,
			   comment_is_optional = in_comment_is_optional,
			   due_date_is_mandatory = in_due_date_is_mandatory,
			   allow_critical = in_allow_critical,
			   allow_urgent_alert = in_allow_urgent_alert,
			   region_is_mandatory = in_region_is_mandatory
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND issue_type_id = in_issue_type_id;

		out_issue_type_id := in_issue_type_id;  
	END IF;

	chain.filter_pkg.ClearCacheForAllUsers (
		in_card_group_id => chain.filter_pkg.FILTER_TYPE_ISSUES
	);

	IF in_enable_manual_comp_date = 1 THEN
		-- Set manual completion date for all existing issues for type.
		UPDATE issue
		   SET manual_completion_dtm = resolved_dtm
		 WHERE resolved_dtm IS NOT NULL
		   AND manual_completion_dtm IS NULL
		   AND issue_type_id = out_issue_type_id;
	END IF;

	csr_data_pkg.WriteAppAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_ISSUES, SYS_CONTEXT('SECURITY', 'APP'), 
		SYS_CONTEXT('SECURITY', 'APP'), 'Issue type id {0} public_by_default set to {1}', out_issue_type_id, in_public_by_default);
	
END;

PROCEDURE DeleteIssueType (
	in_issue_type_id			IN  issue_type.issue_type_id%TYPE
)
AS
BEGIN
	
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Issue management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied managing issues');
	END IF;

	IF in_issue_type_id < 10000 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Core issue types cannot be deleted');
	END IF;
	
	UPDATE issue_type
	   SET deleted = 1
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND issue_type_id = in_issue_type_id;
END;

PROCEDURE SearchIssues(
	in_search_term					IN  VARCHAR2,
	in_all							IN	NUMBER,
	in_mine							IN	NUMBER,
	in_my_roles						IN	NUMBER,
	in_my_staff						IN	NUMBER,
	in_issue_type_id				IN	issue.issue_type_id%TYPE,
	in_last_issue_id				IN  issue.issue_id%TYPE,
	in_page_size					IN  NUMBER,
	in_overdue						IN  NUMBER,
	in_unresolved					IN  NUMBER,
	in_resolved						IN  NUMBER,
	in_closed						IN  NUMBER,
	in_rejected						IN  NUMBER,
	in_supplier_sid					IN  security_pkg.T_SID_ID,
	in_children_for_issue_id		IN  security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_first							NUMBER(10);
	v_search						VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_restrict_issue_visibility		NUMBER(1) := 0;
	v_has_region_root_start_point	NUMBER(1) := issue_pkg.HasRegionRootStartPoint;
BEGIN	
	SELECT restrict_issue_visibility
	  INTO v_restrict_issue_visibility
	  FROM customer;
	
	-- first, we get all of the data that we're interested in as a whole
	INSERT INTO temp_issue_search
	  	  (
	  	   issue_id, label, source_label, is_visible, source_url, region_sid, raised_by_user_sid, raised_dtm, raised_user_name, raised_full_name, 
		   raised_email, resolved_by_user_sid, resolved_dtm, manual_completion_dtm, resolved_user_name, resolved_full_name, resolved_email, 
		   closed_by_user_sid, closed_dtm, closed_user_name, closed_full_name, closed_email, rejected_by_user_sid, rejected_dtm, rejected_user_name, 
		   rejected_full_name, rejected_email, assigned_to_user_sid, assigned_to_user_name, assigned_to_full_name, assigned_to_email, assigned_to_role_sid, 
		   assigned_to_role_name, correspondent_id, correspondent_full_name, correspondent_email, correspondent_phone, correspondent_more_info_1, 
		   now_dtm, due_dtm, issue_type_id, issue_type_label, require_priority, issue_priority_id, due_date_offset, priority_overridden, 
		   first_priority_set_dtm, issue_pending_val_id, issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_id, issue_action_id, 
		   issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id, issue_supplier_id, issue_compliance_region_id,
		   is_overdue, is_owner, is_resolved, is_closed, is_rejected, status, first_issue_log_id, last_issue_log_id, is_critical, allow_critical,
		   allow_urgent_alert, position
	  	  )
	SELECT i.issue_id, i.label, i.source_label, i.is_visible, i.source_url, i.region_sid, i.raised_by_user_sid, i.raised_dtm, i.raised_user_name, 
		i.raised_full_name, i.raised_email, i.resolved_by_user_sid, i.resolved_dtm, i.manual_completion_dtm, i.resolved_user_name, i.resolved_full_name, 
		i.resolved_email, i.closed_by_user_sid, i.closed_dtm, i.closed_user_name, i.closed_full_name, i.closed_email, i.rejected_by_user_sid, i.rejected_dtm, 
		i.rejected_user_name, i.rejected_full_name, i.rejected_email, i.assigned_to_user_sid, i.assigned_to_user_name, i.assigned_to_full_name, 
		i.assigned_to_email, i.assigned_to_role_sid, i.assigned_to_role_name, i.correspondent_id, i.correspondent_full_name, i.correspondent_email, 
		i.correspondent_phone, i.correspondent_more_info_1, i.now_dtm, i.due_dtm, i.issue_type_id, i.issue_type_label, i.require_priority, i.issue_priority_id, 
		i.due_date_offset, i.priority_overridden, i.first_priority_set_dtm, i.issue_pending_val_id, i.issue_sheet_value_id, i.issue_survey_answer_id, 
		i.issue_non_compliance_id, i.issue_action_id, i.issue_meter_id, i.issue_meter_alarm_id, i.issue_meter_raw_data_id, i.issue_meter_data_source_id, 
		i.issue_supplier_id, i.issue_compliance_region_id, i.is_overdue, i.is_owner, i.is_resolved, i.is_closed, i.is_rejected, i.status, i.first_issue_log_id, 
		i.last_issue_log_id, i.is_critical, i.allow_critical, i.allow_urgent_alert, ROWNUM position
	  FROM (
		SELECT i.*
		  FROM v$issue i
		  JOIN customer c ON i.app_sid = c.app_sid
		  JOIN issue_type it ON i.issue_type_id = it.issue_type_id
		  LEFT JOIN issue_supplier isup ON i.issue_supplier_id = isup.issue_supplier_id AND i.app_sid = isup.app_sid
		  LEFT JOIN (
			SELECT DISTINCT r2.app_sid, r2.region_sid
			  FROM region r2
			 START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') 
			   AND region_sid IN (SELECT region_sid FROM region_start_point WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID'))
		   CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
		  ) r ON i.region_sid = r.region_sid AND i.app_sid = r.app_sid 
		   LEFT JOIN v$issue_involved_user ii ON i.app_sid = ii.app_sid AND i.issue_id = ii.issue_id AND ii.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		 WHERE (  -- filter to issues within the users region start point, or that they are involved in personally,
				  -- or that they are involved in by way of auto company involvement ( + public issues)
				   r.region_sid IS NOT NULL
				OR v_has_region_root_start_point = 1
				OR i.assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID')
				OR i.raised_by_user_sid = SYS_CONTEXT('SECURITY', 'SID')
				OR (i.is_public = 1 AND v_restrict_issue_visibility = 0)
				OR ii.issue_id IS NOT NULL
				OR EXISTS (SELECT NULL 
						   FROM issue_involvement ii 
						  WHERE ii.issue_id = i.issue_id
						    AND ii.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')))
		   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.issue_type_id = NVL(in_issue_type_id, i.issue_type_id)
		   -- filter supplier_sids
		   AND (in_supplier_sid IS NULL OR isup.company_sid = in_supplier_sid)
		   -- filter by status
		   AND (
				  (in_overdue = 1    AND i.is_overdue = 1)
			   OR (in_resolved = 1   AND i.is_resolved = 1 AND i.is_closed = 0)
			   OR (in_closed = 1     AND i.is_closed = 1)
			   OR (in_rejected = 1   AND i.is_rejected = 1)
			   OR (in_unresolved = 1 AND i.is_overdue = 0 AND i.is_resolved = 0 AND i.is_closed = 0 AND i.is_rejected = 0) 
		   )
		   -- filter by assignment
		   AND (
					in_all = 1 
				OR (in_mine = 1 AND (
						i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') 
					 OR i.assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID')
					 OR ii.from_role = 0
				   ))
				OR (in_my_roles = 1 AND (ii.from_role = 1 OR EXISTS (SELECT NULL 
																	   FROM issue_involvement ii 
																	  WHERE ii.issue_id = i.issue_id
																		AND ii.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))))
				OR (in_my_staff = 1 AND (
						i.assigned_to_user_sid IN (
							SELECT csr_user_sid
							  FROM csr_user
							 WHERE line_manager_sid = SYS_CONTEXT('SECURITY', 'SID')
						)
					))
			)
			-- filter out ones that can't be used as child cases
			AND (
				   in_children_for_issue_id IS NULL 
				OR (i.issue_id <> in_children_for_issue_id AND DECODE(i.parent_id, in_children_for_issue_id, 1) IS NULL)				
			)
			
			-- filter by search term
			AND (
				   in_search_term IS NULL
				OR TO_CHAR(i.issue_id) LIKE v_search
				OR LOWER(i.label) LIKE v_search
				OR LOWER(it.label || ' #' || TO_CHAR(i.issue_id)) LIKE v_search
			)
			
		 ORDER BY i.rejected_dtm DESC, 
			  i.closed_dtm DESC, 
			  i.resolved_dtm DESC, 
			  CASE WHEN i.is_overdue = 1 THEN i.due_dtm - i.now_dtm ELSE NULL END,
			  CASE WHEN i.is_overdue = 1 THEN i.due_dtm ELSE NULL END,
			  i.raised_dtm DESC,
			  i.issue_id DESC
	) i;

	-- find the next page given the last issue_id from the previous page
	SELECT NVL(MIN(position), 0) + 1
	  INTO v_first
	  FROM temp_issue_search
	 WHERE issue_id = in_last_issue_id;
	
	-- Remove data outside of our page before join
	DELETE FROM temp_issue_search
	 WHERE position < v_first
	    OR position >= v_first + in_page_size;

	OPEN out_cur FOR
		SELECT i.*, il.message last_log_message, il.logged_dtm last_message_logged_dtm, 
		       CASE WHEN il.logged_by_user_sid IS NULL THEN ilc.full_name ELSE ilu.full_name END last_logged_by_full_name, 
			   CASE WHEN il.logged_by_user_sid IS NULL THEN 0 ELSE 1 END last_logged_by_is_user
		  FROM temp_issue_search i
		  LEFT JOIN issue_log il
		    ON i.last_issue_log_id = il.issue_log_id
		   AND i.issue_id = il.issue_id
		  LEFT JOIN csr_user ilu
		    ON il.app_sid = ilu.app_sid
		   AND il.logged_by_user_sid = ilu.csr_user_sid
		  LEFT JOIN correspondent ilc
		    ON il.app_sid = ilc.app_sid
		   AND il.logged_by_correspondent_id = ilc.correspondent_id
		 ORDER BY i.position;
END;

PROCEDURE GetIssuesByDueDtm (
	in_start_dtm				IN	issue.due_dtm%TYPE,
	in_end_dtm					IN	issue.due_dtm%TYPE,
	in_issue_type_id			IN	issue.issue_type_id%TYPE,
	in_my_issues				IN	NUMBER,
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_restrict_issue_visibility	NUMBER(1) := 0;
BEGIN
	SELECT restrict_issue_visibility
	  INTO v_restrict_issue_visibility
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	OPEN out_cur FOR
		SELECT i.issue_id, i.status, i.issue_type_label, is_overdue, is_closed,
			   i.is_rejected, i.is_resolved, i.label, i.source_label, r.region_type,
			   rt.class_name region_type_class_name, raised_full_name,
			   assigned_to_full_name, assigned_to_role_name, due_dtm, raised_dtm,
			   i.region_name
		  FROM v$issue i
		  JOIN customer c ON i.app_sid = c.app_sid
		  LEFT JOIN region r ON i.region_sid = r.region_sid
		  LEFT JOIN region_type rt ON r.region_type = rt.region_type
		 WHERE i.due_dtm >= in_start_dtm
		   AND i.due_dtm < in_end_dtm
		   AND ((i.is_public = 1 AND v_restrict_issue_visibility = 0) OR NVL(i.region_sid, c.region_root_sid) IN (
				SELECT region_sid
				  FROM region
				 START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND region_sid IN (SELECT region_sid FROM region_start_point WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID'))
			   CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
			 ))
		   AND NVL(in_issue_type_id, i.issue_type_id) = i.issue_type_id
		   AND (in_my_issues = 0 OR (
				-- TODO: Include roles in my issues? Or add a My roles option to calendar?
				i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') 
				OR i.assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID')
				OR i.issue_id IN (
					SELECT issue_id 
					  FROM issue_involvement 
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND user_sid = SYS_CONTEXT('SECURITY', 'SID')
				))
		   )
		 ORDER BY i.due_dtm;
END;

PROCEDURE GetPriorities (
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT issue_priority_id, due_date_offset, description
		  FROM issue_priority
		 ORDER BY due_date_offset, description;
END;

-- Get assignable Roles restricted by region.
PROCEDURE GetAssignableRoles (
	in_region_sid		IN	region.region_sid%TYPE,
	in_filter			IN  VARCHAR2,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT 1 is_role, 0 is_user, role_sid unique_id, name
		  FROM role
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND role_sid IN (
				SELECT rrm.role_sid
				  FROM region_role_member rrm
				 WHERE rrm.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND rrm.region_sid = in_region_sid
				)
		   AND LOWER(' '||name) LIKE '% '||LOWER(in_filter)||'%'
		 ORDER BY LOWER(name); 
END;

-- Gets all assignable users, restricted by region.
PROCEDURE GetAssignableUsers (
	in_region_sid		IN	region.region_sid%TYPE,
	in_restrict_users	IN	issue_type.restrict_users_to_region%TYPE,
	in_filter			IN	VARCHAR2,
	out_cur				OUT SYS_REFCURSOR,
	out_total_num_users	OUT SYS_REFCURSOR
)
AS
	v_table				T_USER_FILTER_TABLE;
	v_app_sid			security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_show_email		NUMBER;
	v_show_user_name	NUMBER;
	v_show_user_ref		NUMBER;
BEGIN
	csr_user_pkg.FilterUsersToTable(in_filter, 0, v_table);

	SELECT CASE WHEN INSTR(user_picker_extra_fields, 'email', 1) != 0 THEN 1 ELSE 0 END show_email,
		   CASE WHEN INSTR(user_picker_extra_fields, 'user_name', 1) != 0 THEN 1 ELSE 0 END show_user_name,
		   CASE WHEN INSTR(user_picker_extra_fields, 'user_ref', 1) != 0 THEN 1 ELSE 0 END show_user_ref
	  INTO v_show_email, v_show_user_name, v_show_user_ref
	  FROM customer
	 WHERE app_sid = v_app_sid;
	
	OPEN out_total_num_users FOR
		SELECT COUNT(*) total_num_users, csr_user_pkg.MAX_USERS max_size
		  FROM (
			SELECT DISTINCT cu.csr_user_sid
			  FROM csr_user cu
			  JOIN TABLE(v_table) t ON cu.csr_user_sid = t.csr_user_sid
			  LEFT JOIN (
				SELECT DISTINCT rrm.user_sid, rrm.app_sid, rrm.inherited_from_sid, rrm.region_sid
				  FROM region_role_member rrm
				 WHERE region_sid = in_region_sid
			  ) x ON x.user_sid = cu.csr_user_sid AND x.app_sid = cu.app_sid AND in_restrict_users = 2 -- RegionRoleMembership
				  JOIN region_start_point rsp ON cu.app_sid = rsp.app_sid AND cu.csr_user_sid = rsp.user_sid
				  JOIN (SELECT app_sid, region_sid
						  FROM region
						  WHERE app_sid = v_app_sid
								START WITH region_sid = in_region_sid
								CONNECT BY PRIOR parent_sid = region_sid) r
				ON rsp.app_sid = r.app_sid AND rsp.region_sid = r.region_sid
			 WHERE cu.app_sid = v_app_sid
			   AND (in_restrict_users = 1 OR (in_restrict_users = 2 AND x.region_sid = in_region_sid
				  AND x.inherited_from_sid NOT IN (
					SELECT region_sid
					  FROM region
					 START WITH parent_sid = (SELECT trash_sid FROM customer WHERE app_sid = v_app_sid)
				   CONNECT BY PRIOR region_sid = parent_sid AND PRIOR app_sid = app_sid
				  )
				))
		  );

	OPEN out_cur FOR
		SELECT is_role, is_user,  csr_user_sid, full_name, email, user_name, user_ref, account_enabled, user_sid, sid,
			   v_show_email show_email, v_show_user_name show_user_name, v_show_user_ref show_user_ref
		  FROM (
			SELECT is_role, is_user, csr_user_sid, full_name, email, user_name, user_ref, account_enabled, user_sid, sid
			  FROM (
				SELECT DISTINCT x.is_role, x.is_user, x.csr_user_sid, x.full_name, x.email, x.user_name, x.user_ref, x.account_enabled,
					   user_sid, sid
				  FROM (
					SELECT 0 is_role, 1 is_user, cu.csr_user_sid, cu.full_name, cu.email, cu.user_name, cu.user_ref, t.account_enabled,
						   cu.csr_user_sid user_sid, cu.csr_user_sid sid
					  FROM csr_user cu
					  JOIN TABLE(v_table) t ON cu.csr_user_sid = t.csr_user_sid
					  LEFT JOIN (
						SELECT DISTINCT rrm.user_sid, rrm.app_sid, rrm.inherited_from_sid, rrm.region_sid
						  FROM region_role_member rrm
						 WHERE region_sid = in_region_sid
					  ) x ON x.user_sid = cu.csr_user_sid AND x.app_sid = cu.app_sid AND in_restrict_users = 2 -- RegionRoleMembership
					  JOIN region_start_point rsp ON cu.app_sid = rsp.app_sid AND cu.csr_user_sid = rsp.user_sid
					  JOIN (SELECT app_sid, region_sid
							  FROM region
							 WHERE app_sid = v_app_sid
								   START WITH region_sid = in_region_sid
								   CONNECT BY PRIOR parent_sid = region_sid) r
						ON rsp.app_sid = r.app_sid AND rsp.region_sid = r.region_sid
					 WHERE cu.csr_user_sid = t.csr_user_sid
					   AND cu.app_sid = v_app_sid
					   AND (in_restrict_users = 1 OR (in_restrict_users = 2 AND x.region_sid = in_region_sid
						  AND x.inherited_from_sid NOT IN (
							SELECT region_sid
							  FROM region
							 START WITH parent_sid = (SELECT trash_sid FROM customer WHERE app_sid = v_app_sid)
						   CONNECT BY PRIOR region_sid = parent_sid AND PRIOR app_sid = app_sid
						  )
						))
				  ) x
			  )
			 ORDER BY account_enabled DESC,
				      CASE WHEN '' IS NULL OR LOWER(TRIM(full_name)) LIKE LOWER('') || '%' THEN 0 ELSE 1 END, -- Favour names that start with the provided filter.
				      CASE WHEN '' IS NULL OR LOWER(TRIM(full_name)) || ' ' LIKE '% ' || LOWER('') || ' %' THEN 0 ELSE 1 END, -- Favour whole words over prefixes.
				      CASE WHEN in_filter IS NULL OR LOWER(TRIM(email)) LIKE LOWER(in_filter) || '%' THEN 0 ELSE 1 END,
				      CASE WHEN in_filter IS NULL OR LOWER(TRIM(user_name)) LIKE LOWER(in_filter) || '%' THEN 0 ELSE 1 END,
				      CASE WHEN in_filter IS NULL OR LOWER(TRIM(user_ref)) LIKE LOWER(in_filter) || '%' THEN 0 ELSE 1 END,
				      LOWER(TRIM(full_name))
		  )
		 WHERE ROWNUM <= csr_user_pkg.MAX_USERS;
END;

/**
 * Returns all issues that the user is involved in where there are unread messages
 */
PROCEDURE GetUnreadIssues(
	in_act_id			IN	security_pkg.T_ACT_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_user_sid 	security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);
	
	-- doesn't check security, instead it checks whether the user is involved in the issue (issue_user table)
	OPEN out_cur FOR
		SELECT i.issue_id, i.label, 
			i.raised_by_user_sid, i.raised_dtm, i.raised_user_name, i.raised_full_name, i.raised_email,
			i.resolved_by_user_sid, i.resolved_dtm, i.manual_completion_dtm, i.manual_comp_dtm_set_dtm,
			i.resolved_user_name, i.resolved_full_name, i.resolved_email,
			i.closed_by_user_sid, i.closed_dtm, i.closed_user_name, i.closed_full_name, i.closed_email,
			i.rejected_by_user_sid, i.rejected_dtm, i.rejected_full_name, i.rejected_email,
			SUM(CASE WHEN ilr.read_dtm IS NOT NULL OR logged_by_user_sid = v_user_sid THEN 0 ELSE 1 END) unread
		  FROM v$issue i, issue_log il, issue_log_read ilr, (
		  		SELECT DISTINCT issue_id, user_sid
		  		  FROM (
					SELECT issue_id, user_sid
					  FROM v$issue_involved_user
					 WHERE user_sid = v_user_sid
					 UNION ALL
					SELECT i.issue_id, rrm.user_sid
					  FROM issue i, region_role_member rrm
					 WHERE i.app_sid = rrm.app_sid
					   AND i.assigned_to_role_sid = rrm.role_sid
					   AND i.region_sid = rrm.region_sid
					   AND rrm.user_sid = v_user_sid
					 )
		  		) iu
		 WHERE i.issue_id = il.issue_id
		   AND il.issue_log_id = ilr.issue_log_id(+)
		   AND ilr.csr_user_sid(+) = v_user_sid
		   AND i.issue_id = iu.issue_id
		 GROUP BY i.issue_id, i.label, 
			i.raised_by_user_sid, i.raised_dtm, i.raised_user_name, i.raised_full_name, i.raised_email,
			i.resolved_by_user_sid, i.resolved_dtm, i.resolved_user_name, i.resolved_full_name, i.resolved_email,
			i.closed_by_user_sid, i.closed_dtm, i.closed_user_name, i.closed_full_name, i.closed_email,
			i.rejected_by_user_sid, i.rejected_dtm, i.rejected_user_name, i.rejected_full_name, i.rejected_email;         
END;

FUNCTION GetSheetUrl (
	in_editing_url					customer.editing_url%TYPE,
	in_ind_sid						ind.ind_sid%TYPE,
	in_region_sid					region.region_sid%TYPE,
	in_start_dtm					sheet.start_dtm%TYPE,
	in_end_dtm						sheet.end_dtm%TYPE,
	in_user_sid						csr_user.csr_user_sid%TYPE
) RETURN VARCHAR2
AS
	v_sheet_query					VARCHAR2(4000);
	v_get_deepest_sheet_url			NUMBER(1);
BEGIN
	-- should we go to the deepest delegation sheet, or be smart about it and work out what's best for the user?
	-- (in the case of Nestle they want to get only the deepest sheet level (provider sheet)...)
	SELECT iss_view_src_to_deepest_sheet
	  INTO v_get_deepest_sheet_url 
	  FROM csr.customer;
	
	IF v_get_deepest_sheet_url = 1 THEN
		v_sheet_query := sheet_pkg.GetBottomSheetQueryString(in_ind_sid, in_region_sid, in_start_dtm, in_end_dtm, in_user_sid);
	ELSE
		v_sheet_query := sheet_pkg.GetSheetQueryString(in_ind_sid, in_region_sid, in_start_dtm, in_end_dtm, in_user_sid);
	END IF;
	
	IF v_sheet_query IS NULL THEN
		RETURN NULL;
	END IF;
	RETURN in_editing_url || v_sheet_query || '#indSid=' || in_ind_Sid || ',regionSid=' || in_region_sid;
END;

PROCEDURE GetIssueDetails(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_issue_id				IN	security_pkg.T_SID_ID,
	out_issue_cur			OUT	SYS_REFCURSOR,
	out_users_cur			OUT	SYS_REFCURSOR,
	out_log_cur				OUT	SYS_REFCURSOR,
	out_files_cur			OUT	SYS_REFCURSOR,
	out_action_log_cur		OUT SYS_REFCURSOR,
	out_custom_fields		OUT SYS_REFCURSOR,
	out_custom_field_opts	OUT	SYS_REFCURSOR,
	out_custom_field_vals	OUT SYS_REFCURSOR,
	out_child_issues		OUT SYS_REFCURSOR,
	out_parent_issue		OUT SYS_REFCURSOR,
	out_roles_cur			OUT SYS_REFCURSOR,
	out_rag_options_cur		OUT SYS_REFCURSOR,
	out_companies_cur		OUT SYS_REFCURSOR
)
AS
	v_user_sid					security_pkg.T_SID_ID;
	v_is_public					NUMBER(1);
	v_restrict_issue_visibility	NUMBER(1) := 0;
	v_cnt						NUMBER;
	v_is_read_only				NUMBER(1) := 0;
	v_issue_id					security.security_pkg.T_SID_ID;
	v_issue_type_id				issue.issue_type_id%TYPE;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);

	BEGIN
		SELECT issue_id, issue_type_id
		  INTO v_issue_id, v_issue_type_id
		  FROM issue
		 WHERE issue_id = in_issue_id
			OR issue_ref = in_issue_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
				'Cannot find the issue with id '||in_issue_id);
	END;

	SELECT is_public
	  INTO v_is_public
	  FROM issue
	 WHERE issue_id = v_issue_id;

	IF NOT issue_pkg.IsAccessAllowed(in_act_id, v_issue_id) THEN
		-- If the user isn't a guest and the issue is public, then check whether 
		-- they need region access.  If they have it or don't need it, let them
		-- see the issue, but in read-only mode
		IF security_pkg.getSid != security_pkg.SID_BUILTIN_GUEST AND v_is_public = 1 THEN
			SELECT restrict_issue_visibility
			  INTO v_restrict_issue_visibility
			  FROM customer c;

			IF v_restrict_issue_visibility != 0 THEN
				SELECT count(*)
				  INTO v_cnt
				  FROM (
						SELECT region_sid
						  FROM region
						 START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP')
						   AND region_sid IN (SELECT region_sid FROM region_start_point WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID'))
					   CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
				  ) r
				  JOIN issue i
				    ON i.region_sid = r.region_sid
				 WHERE i.issue_id = v_issue_id;

				IF v_cnt = 0 THEN
					RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
						'Permission denied reading the issue with id '||v_issue_id);
				END IF;
			END IF;

			-- Set the readonly flag.
			v_is_read_only := 1;
		ELSE
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
				'Permission denied reading the issue with id '||v_issue_id);
		END IF;
	END IF;

	INTERNAL_CrazyJoin(v_issue_id, v_user_sid, v_is_read_only, out_issue_cur);

	OPEN out_users_cur FOR
		SELECT ii.app_sid, ii.issue_id, ii.is_an_owner, ii.user_sid, cu.user_name, cu.full_name, cu.email
		  FROM issue_involvement ii
		  JOIN csr_user cu ON ii.app_sid = cu.app_sid AND ii.user_sid = cu.csr_user_sid
		 WHERE ii.issue_id = v_issue_id
		   AND ii.app_sid = security_pkg.GetApp
	 	   AND cu.csr_user_sid != security.security_pkg.SID_BUILTIN_ADMINISTRATOR;

	OPEN out_roles_cur FOR
		SELECT r.role_sid, r.name, ii.is_an_owner
		  FROM issue_involvement ii
		  JOIN role r
		    ON ii.app_sid = r.app_sid
		   AND ii.role_sid = r.role_sid
		 WHERE ii.issue_id = v_issue_id
		   AND ii.app_sid = security_pkg.GetApp;

	OPEN out_companies_cur FOR
		SELECT ii.company_sid, ii.is_an_owner, c.name
		  FROM issue_involvement ii
		  JOIN chain.company c
		    ON ii.app_sid = c.app_sid
		   AND ii.company_sid = c.company_sid
		 WHERE ii.issue_id = v_issue_id
		   AND ii.app_sid = security_pkg.GetApp;

	INTERNAL_GetIssueLogEntries(v_user_sid, v_issue_id, NULL, FALSE, out_log_cur, out_files_cur, out_action_log_cur);

	INTERNAL_GetIssueCustomValues(v_issue_id, v_issue_type_id, out_custom_fields, out_custom_field_opts, out_custom_field_vals);

	INTERNAL_GetIssueChildIssues(v_issue_id, out_child_issues);

	INTERNAL_GetIssueParentIssue(v_issue_id, out_parent_issue);

	-- all rag options for the current issue (based on its issue type)
	OPEN out_rag_options_cur FOR
		SELECT itrs.rag_status_id, itrs.pos, irs.colour, irs.label, irs.lookup_key
		  FROM issue i 
		  JOIN issue_type_rag_status itrs ON i.issue_type_id = itrs.issue_type_id AND i.app_sid = itrs.app_sid 
		  JOIN rag_status irs ON itrs.rag_status_id = irs.rag_status_id AND itrs.app_sid = irs.app_sid 
		 WHERE i.issue_id = v_issue_id
		 ORDER BY itrs.pos;
END;

PROCEDURE GetIssueDetailsByGuid(
	in_guid					IN  issue.guid%TYPE,
	out_issue_cur			OUT	SYS_REFCURSOR,
	out_users_cur			OUT	SYS_REFCURSOR,
	out_log_cur				OUT	SYS_REFCURSOR,
	out_files_cur			OUT	SYS_REFCURSOR,
	out_action_log_cur		OUT SYS_REFCURSOR,
	out_custom_fields		OUT SYS_REFCURSOR,
	out_custom_field_opts	OUT	SYS_REFCURSOR,
	out_custom_field_vals	OUT SYS_REFCURSOR,
	out_child_issues		OUT SYS_REFCURSOR,
	out_parent_issue		OUT SYS_REFCURSOR,
	out_roles_cur			OUT SYS_REFCURSOR,
	out_rag_options_cur		OUT SYS_REFCURSOR,
	out_companies_cur		OUT SYS_REFCURSOR
)
AS
	v_issue_id				issue.issue_id%TYPE;
	v_issue_type_id			issue.issue_type_id%TYPE;
	v_for_correspondent		BOOLEAN;
BEGIN
	BEGIN
		SELECT issue_id, issue_type_id
		  INTO v_issue_id, v_issue_type_id
		  FROM issue
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND guid = in_guid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN;
	END;

	v_for_correspondent	:= NOT issue_pkg.IsAccessAllowed(security_pkg.GetAct, v_issue_id);

	INTERNAL_CrazyJoin(v_issue_id, SYS_CONTEXT('SECURITY', 'SID'), 0, out_issue_cur);

	IF v_for_correspondent THEN
		OPEN out_users_cur FOR SELECT 0 FROM dual WHERE 1 = 0;
		OPEN out_roles_cur FOR SELECT 0 FROM dual WHERE 1 = 0;
		OPEN out_companies_cur FOR SELECT 0 FROM dual WHERE 1 = 0;
	ELSE
		OPEN out_users_cur FOR
			SELECT ii.app_sid, ii.issue_id, ii.is_an_owner, ii.user_sid, cu.user_name, cu.full_name, cu.email
			  FROM issue_involvement ii
			  JOIN csr_user cu ON ii.app_sid = cu.app_sid AND ii.user_sid = cu.csr_user_sid
			 WHERE ii.issue_id = v_issue_id
			   AND ii.app_sid = security_pkg.GetApp
			   AND cu.csr_user_sid != security.security_pkg.SID_BUILTIN_ADMINISTRATOR;

		OPEN out_roles_cur FOR
			SELECT r.role_sid, r.name, ii.is_an_owner
			  FROM issue_involvement ii
			  JOIN role r
				ON ii.app_sid = r.app_sid
			   AND ii.role_sid = r.role_sid
			 WHERE ii.issue_id = v_issue_id
			   AND ii.app_sid = security_pkg.GetApp;

		OPEN out_companies_cur FOR
			SELECT ii.company_sid, ii.is_an_owner, c.name
			  FROM issue_involvement ii
			  JOIN chain.company c
				ON ii.app_sid = c.app_sid
			   AND ii.company_sid = c.company_sid
			 WHERE ii.issue_id = v_issue_id
			   AND ii.app_sid = security_pkg.GetApp;
	END IF;

	INTERNAL_GetIssueLogEntries(NULL, v_issue_id, NULL, v_for_correspondent, out_log_cur, out_files_cur, out_action_log_cur);

	INTERNAL_GetIssueCustomValues(v_issue_id, v_issue_type_id, out_custom_fields, out_custom_field_opts, out_custom_field_vals);

	INTERNAL_GetIssueChildIssues(v_issue_id, out_child_issues);

	INTERNAL_GetIssueParentIssue(v_issue_id, out_parent_issue);

	-- all rag options for the current issue (based on its issue type)
	OPEN out_rag_options_cur FOR
		SELECT itrs.rag_status_id, itrs.pos, irs.colour, irs.label, irs.lookup_key
		  FROM issue i 
		  JOIN issue_type_rag_status itrs ON i.issue_type_id = itrs.issue_type_id AND i.app_sid = itrs.app_sid 
		  JOIN rag_status irs ON itrs.rag_status_id = irs.rag_status_id AND itrs.app_sid = irs.app_sid 
		 WHERE i.issue_id = v_issue_id
		 ORDER BY itrs.pos;
END;

PROCEDURE SetRagStatus(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_rag_status_id			IN  issue.rag_status_id%TYPE,
	in_message					IN  issue_log.message%TYPE,
	out_issue_cur				OUT	SYS_REFCURSOR,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT SYS_REFCURSOR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_issue_log_id			issue_log.issue_log_id%TYPE;
	v_log_files_cur			SYS_REFCURSOR;
BEGIN
	User_Pkg.GetSID(in_act_id, v_user_sid);
	
	IF NOT issue_pkg.IsAccessAllowed(in_act_id, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied writing the issue with id '||in_issue_id);
	END IF;
	
	UPDATE issue 
	   SET last_rag_status_id = rag_status_id,
	       rag_status_id = in_rag_status_id
	 WHERE issue_id = in_issue_id;

	AddLogEntry(in_act_id, in_issue_id, 0, in_message, null, null, null, TRUE, v_issue_log_id);
	LogAction(csr_data_pkg.IAT_RAG_STARUS_CHANGED, in_issue_id, v_issue_log_id);
	
	OPEN out_issue_cur FOR
		SELECT rag_status_id
		  FROM issue
		 WHERE issue_id = in_issue_id;
		 
	INTERNAL_GetIssueLogEntries(v_user_sid, in_issue_id, v_issue_log_id, FALSE, out_log_cur, v_log_files_cur, out_action_cur);
END;

PROCEDURE SetRelativeDueDtm(
	in_act_id						IN  security_pkg.T_ACT_ID,
	in_issue_id						IN  issue.issue_id%TYPE,
	in_issue_due_source_id			IN	issue.issue_due_source_id%TYPE,
	in_issue_due_offset_days		IN	issue.issue_due_offset_days%TYPE,
	in_issue_due_offset_months		IN	issue.issue_due_offset_months%TYPE,
	in_issue_due_offset_years		IN	issue.issue_due_offset_years%TYPE,
	in_message						IN  issue_log.message%TYPE,
	out_due_cur						OUT	SYS_REFCURSOR,
	out_log_cur						OUT	SYS_REFCURSOR,
	out_action_cur					OUT SYS_REFCURSOR
)
AS
	v_user_sid						security_pkg.T_SID_ID;
	v_issue_log_id					issue_log.issue_log_id%TYPE;
	v_log_files_cur					SYS_REFCURSOR;
BEGIN
	User_Pkg.GetSID(in_act_id, v_user_sid);

	-- user must be the issue owner or have Issue Management capability to do this
	IF NOT IsOwner(in_act_id, in_issue_id) AND 
	   NOT csr_data_pkg.CheckCapability(in_act_id, 'Issue management') 
	THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
			'You must own the issue, or have Issue management capabilities to set the due date on issue with ' ||
			'id ' || in_issue_id
		);
	END IF;

	UPDATE issue 
	   SET issue_due_source_id = in_issue_due_source_id,
		   issue_due_offset_days = in_issue_due_offset_days,
		   issue_due_offset_months = in_issue_due_offset_months,
		   issue_due_offset_years = in_issue_due_offset_years
	 WHERE issue_id = in_issue_id;

	IF in_message IS NOT NULL THEN
		AddLogEntry(in_act_id, in_issue_id, 0, in_message, null, null, null, TRUE, v_issue_log_id);
	END IF;

	RefreshRelativeDueDtm(in_issue_id, v_issue_log_id);

	IF in_message IS NOT NULL THEN
		INTERNAL_GetIssueLogEntries(
			v_user_sid, in_issue_id, v_issue_log_id, FALSE, out_log_cur, v_log_files_cur, out_action_cur);
	ELSE
		OPEN out_log_cur FOR SELECT 1 FROM DUAL WHERE 1 = 0;
	END IF;

	INTERNAL_GetIssueDueDetails(
		in_issue_id					=> in_issue_id,
		in_issue_log_id				=> v_issue_log_id,
		out_due_cur					=> out_due_cur
	);
END;

PROCEDURE SetDueDtm(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_due_dtm					IN  issue.due_dtm%TYPE,
	in_message					IN  issue_log.message%TYPE,
	out_due_cur					OUT	SYS_REFCURSOR,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT SYS_REFCURSOR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_issue_log_id			issue_log.issue_log_id%TYPE;
	v_log_files_cur			SYS_REFCURSOR;
BEGIN
	User_Pkg.GetSID(in_act_id, v_user_sid);
	
	-- user must be the issue owner or have Issue Management capability to do this
	IF NOT IsOwner(in_act_id, in_issue_id) AND NOT csr_data_pkg.CheckCapability(in_act_id, 'Issue management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'You must own the issue, or have Issue management capabilities to set the due date on issue with id '||in_issue_id);
	END IF;
	
	UPDATE issue
	   SET last_due_dtm = due_dtm,
	       due_dtm = in_due_dtm,
		   issue_due_source_id = NULL,
		   issue_due_offset_days = NULL,
		   issue_due_offset_months = NULL,
		   issue_due_offset_years = NULL 
	 WHERE issue_id = in_issue_id;
	 
	-- allow the overdue alerts to be resent if the new due date is in the future
	IF in_due_dtm >= SYSDATE THEN
		UPDATE issue_alert
		   SET overdue_sent_dtm = NULL,
			   reminder_sent_dtm = NULL
		 WHERE issue_id = in_issue_id;

		UPDATE issue
		   SET notified_overdue = 0
		 WHERE issue_id = in_issue_id;
	END IF;

	IF in_message IS NOT NULL THEN
		AddLogEntry(in_act_id, in_issue_id, 0, in_message, null, null, null, TRUE, v_issue_log_id);
		INTERNAL_GetIssueLogEntries(v_user_sid, in_issue_id, v_issue_log_id, FALSE, out_log_cur, v_log_files_cur, out_action_cur);
	ELSE
		OPEN out_log_cur FOR SELECT 1 FROM DUAL WHERE 1 = 0;
	END IF;
	LogAction(csr_data_pkg.IAT_DUE_DATE_CHANGED, in_issue_id, v_issue_log_id);
	INTERNAL_StatusChanged(in_issue_id, csr_data_pkg.IAT_DUE_DATE_CHANGED);
	
	INTERNAL_GetIssueDueDetails(
		in_issue_id					=> in_issue_id,
		in_issue_log_id				=> v_issue_log_id,
		out_due_cur					=> out_due_cur
	);
END;

PROCEDURE SetForecastDtm(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_forecast_dtm					IN  issue.due_dtm%TYPE,
	in_message					IN  issue_log.message%TYPE,
	out_due_cur					OUT	SYS_REFCURSOR,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT	SYS_REFCURSOR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_issue_log_id			issue_log.issue_log_id%TYPE;
	v_log_files_cur		SYS_REFCURSOR;
BEGIN
	User_Pkg.GetSID(in_act_id, v_user_sid);
	
	-- user must be the issue owner or have Issue Management capability to do this
	IF NOT IsOwner(in_act_id, in_issue_id) AND NOT csr_data_pkg.CheckCapability(in_act_id, 'Issue management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'You must own the issue, or have Issue management capabilities to set the due date on issue with id '||in_issue_id);
	END IF;
	
	UPDATE ISSUE 
	   SET last_forecast_dtm = forecast_dtm,
	       forecast_dtm = in_forecast_dtm
	 WHERE issue_id = in_issue_id;

	IF in_message IS NOT NULL THEN
		AddLogEntry(in_act_id, in_issue_id, 0, in_message, null, null, null, TRUE, v_issue_log_id);
		INTERNAL_GetIssueLogEntries(v_user_sid, in_issue_id, v_issue_log_id, FALSE, out_log_cur, v_log_files_cur, out_action_cur);
	ELSE
		OPEN out_log_cur FOR SELECT 1 FROM DUAL WHERE 1 = 0;
	END IF;
	LogAction(csr_data_pkg.IAT_FORECAST_DATE_CHANGED, in_issue_id, v_issue_log_id);
	INTERNAL_StatusChanged(in_issue_id, csr_data_pkg.IAT_FORECAST_DATE_CHANGED);
	
	INTERNAL_GetIssueDueDetails(
		in_issue_id					=> in_issue_id,
		in_issue_log_id				=> v_issue_log_id,
		out_due_cur					=> out_due_cur
	);
END;

PROCEDURE SetPriority(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_issue_log_id				IN  issue_log.issue_log_id%TYPE, -- this is only used if in_message is null
	in_priority_id				IN  issue.issue_priority_id%TYPE,
	in_message					IN  issue_log.message%TYPE,
	out_due_cur					OUT	SYS_REFCURSOR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_issue_log_id			issue_log.issue_log_id%TYPE DEFAULT in_issue_log_id;
	v_due_dtm				issue.due_dtm%TYPE;
	v_priority_set			NUMBER(1);
	v_log_cur				SYS_REFCURSOR;
	v_log_files_cur			SYS_REFCURSOR;
	v_action_cur			SYS_REFCURSOR;
BEGIN
	User_Pkg.GetSID(in_act_id, v_user_sid);
	
	-- user must be the issue owner or have Issue Management capability to do this
	IF NOT IsOwner(in_act_id, in_issue_id) AND NOT csr_data_pkg.CheckCapability(in_act_id, 'Issue management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'You must own the issue, or have Issue management capabilities to set the priority on issue with id '||in_issue_id);
	END IF;
	
	SELECT i.raised_dtm + ip.due_date_offset, CASE WHEN i.first_priority_set_dtm IS NULL THEN 0 ELSE 1 END CASE
	  INTO v_due_dtm, v_priority_set
	  FROM issue_priority ip, issue i
	 WHERE ip.issue_priority_id = in_priority_id
	   AND i.issue_id = in_issue_id;

	UPDATE ISSUE 
	   SET last_due_dtm = due_dtm,
	   	   due_dtm = v_due_dtm,
	   	   first_priority_set_dtm = NVL(first_priority_set_dtm, CASE WHEN in_priority_id IS NULL THEN NULL ELSE SYSDATE END),
	   	   last_issue_priority_id = issue_priority_id,
	       issue_priority_id = in_priority_id
	 WHERE issue_id = in_issue_id;
	
	IF in_message IS NOT NULL THEN
		AddLogEntry(in_act_id, in_issue_id, 0, in_message, null, null, null, TRUE, v_issue_log_id);
		INTERNAL_GetIssueLogEntries(v_user_sid, in_issue_id, v_issue_log_id, FALSE, v_log_cur, v_log_files_cur, v_action_cur);
	ELSE
		OPEN v_log_cur FOR SELECT 1 FROM DUAL WHERE 1 = 0;
	END IF;
	
	LogAction(csr_data_pkg.IAT_DUE_DATE_CHANGED, in_issue_id, v_issue_log_id);
	LogAction(csr_data_pkg.IAT_PRIORITY_CHANGED, in_issue_id, v_issue_log_id);
	INTERNAL_StatusChanged(in_issue_id, csr_data_pkg.IAT_PRIORITY_CHANGED);
	
	OPEN out_due_cur FOR
		SELECT issue_id, v_issue_log_id issue_log_id, now_dtm, due_dtm, forecast_dtm, is_overdue, issue_priority_id, priority_overridden, 
			   CASE WHEN v_priority_set = 0 AND in_priority_id IS NOT NULL THEN 1 ELSE 0 END is_first_set,
			   issue_due_source_id, issue_due_offset_days, issue_due_offset_months, 
			   issue_due_offset_years, due_dtm_source_description
		  FROM v$issue
		 WHERE issue_id = in_issue_id;
		 
END;

PROCEDURE SetLabel(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_label					IN  issue.label%TYPE,
	out_issue_cur				OUT	SYS_REFCURSOR,
	out_action_log_cur			OUT	SYS_REFCURSOR
)
AS
	v_issue_action_log_id		issue_action_log.issue_action_log_id%TYPE;
	v_user_sid				security_pkg.T_SID_ID;
	v_issue_log_id			issue_log.issue_log_id%TYPE;
	v_due_dtm				issue.due_dtm%TYPE;
BEGIN
	User_Pkg.GetSID(in_act_id, v_user_sid);

	-- user must be the issue owner or have Issue Management capability to do this
	IF NOT IsOwner(in_act_id, in_issue_id) AND NOT csr_data_pkg.CheckCapability(in_act_id, 'Issue management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'You must own the issue, or have Issue management capabilities to set the label on issue with id '||in_issue_id);
	END IF;

	UPDATE ISSUE 
	   SET last_label = label,
	   	   label = TRIM(in_label)
	 WHERE issue_id = in_issue_id
	   AND (label IS NULL OR in_label IS NULL OR TRIM(label) != TRIM(in_label));

	IF SQL%ROWCOUNT > 0 THEN
		LogAction(
			in_issue_action_type_id => csr_data_pkg.IAT_LABEL_CHANGED, 
			in_issue_id => in_issue_id,
			out_issue_action_log_id => v_issue_action_log_id);
	END IF;
	
	INTERNAL_GetIssueActionLogs(in_issue_id, NULL, v_issue_action_log_id, NULL, out_action_log_cur);	

	OPEN out_issue_cur FOR
		SELECT label
		  FROM v$issue
		 WHERE issue_id = in_issue_id;
			 
END;


PROCEDURE SetDescription(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_description				IN  issue.description%TYPE,
	out_issue_cur				OUT	SYS_REFCURSOR,
	out_action_log_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	setDescription(in_act_id, in_issue_id, in_description, TRUE, out_issue_cur, out_action_log_cur);
END;

-- in_log_action - checks if description change is recorded, usually false for imports
PROCEDURE SetDescription(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_description				IN  issue.description%TYPE,
	in_log_action				IN	BOOLEAN,
	out_issue_cur				OUT	SYS_REFCURSOR,
	out_action_log_cur			OUT	SYS_REFCURSOR
)
AS
	v_issue_action_log_id		issue_action_log.issue_action_log_id%TYPE;
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(in_act_id, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied writing the issue with id '||in_issue_id);
	END IF;

	UPDATE issue 
	   SET last_description = description,
	       description = TRIM(in_description)
	 WHERE issue_id = in_issue_id;
	 
	IF in_log_action THEN
		LogAction(
			in_issue_action_type_id => csr_data_pkg.IAT_DESCRIPTION_CHANGED, 
			in_issue_id => in_issue_id,
			out_issue_action_log_id => v_issue_action_log_id);
	END IF;

	OPEN out_issue_cur FOR
		SELECT description
		  FROM v$issue
		 WHERE issue_id = in_issue_id;
		 
	INTERNAL_GetIssueActionLogs(in_issue_id, NULL, v_issue_action_log_id, NULL, out_action_log_cur);		 
END;

PROCEDURE SetCritical(
	in_act_id						IN  security_pkg.T_ACT_ID,
	in_issue_id						IN  issue.issue_id%TYPE,
	in_value						IN  issue.is_critical%TYPE,
	out_refresh_issue				OUT	NUMBER,
	out_issue_cur					OUT	SYS_REFCURSOR,
	out_action_log_cur				OUT	SYS_REFCURSOR
)
AS
	v_issue_action_log_id			issue_action_log.issue_action_log_id%TYPE;
	v_helper_pkg					issue_type.helper_pkg%TYPE;
BEGIN
	-- user must be the issue owner or have Issue Management capability to do this
	IF NOT IsOwner(in_act_id, in_issue_id) AND NOT csr_data_pkg.CheckCapability(in_act_id, 'Issue management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'You must own the issue, or have Issue management capabilities to set critical on issue with id '||in_issue_id);
	END IF;

	UPDATE ISSUE 
	   SET is_critical = in_value
	 WHERE issue_id = in_issue_id
	   AND in_value IS NOT NULL 
	   AND is_critical != in_value;

	IF SQL%ROWCOUNT > 0 THEN
		LogAction(
			in_issue_action_type_id => csr_data_pkg.IAT_CRIT_CHANGED, 
			in_issue_id => in_issue_id,
			out_issue_action_log_id => v_issue_action_log_id);
	END IF;
	
	INTERNAL_GetIssueActionLogs(in_issue_id, NULL, v_issue_action_log_id, NULL, out_action_log_cur);	

	-- Send notification to helper package
	SELECT helper_pkg
	  INTO v_helper_pkg
	  FROM issue i 
	  JOIN issue_type it ON i.app_sid = it.app_sid AND i.issue_type_id = it.issue_type_id
	 WHERE i.issue_id = in_issue_id;

	IF v_helper_pkg IS NOT NULL THEN
		BEGIN
			EXECUTE IMMEDIATE 'BEGIN '||v_helper_pkg||'.OnSetIssueCritical(:1, :2, :3);END;' 
			  USING in_issue_id, in_value, OUT out_refresh_issue;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN NULL; 
		END;
	END IF;

	OPEN out_issue_cur FOR
		SELECT is_critical
		  FROM issue
		 WHERE issue_id = in_issue_id;
END;

PROCEDURE AssignToUser(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_message					IN  issue_log.message%TYPE,
	out_user_cur				OUT	SYS_REFCURSOR,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT	SYS_REFCURSOR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_issue_log_id			issue_log.issue_log_id%TYPE;
	v_allow_assign_confirm	security_pkg.T_SID_ID;		-- Don't like this...
	v_dummy_cur				SYS_REFCURSOR;
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(in_act_id, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied writing the issue with id '||in_issue_id);
	END IF;

	-- Check if we're supposed to be asking for an assignment confirmation.
	SELECT allow_pending_assignment
	  INTO v_allow_assign_confirm
	  FROM issue_type it
	  JOIN issue i
	    ON it.issue_type_id = i.issue_type_id AND i.issue_id = in_issue_id;
	
	AddUser(in_act_id, in_issue_id, in_user_sid, v_dummy_cur);
	
	UPDATE ISSUE 
	   SET assigned_to_user_sid = in_user_sid,
		   assigned_to_role_sid = NULL
	 WHERE issue_id = in_issue_id;
	 
	AddLogEntry(in_act_id, in_issue_id, 0, in_message, null, null, null, TRUE, v_issue_log_id);
	
	-- If assignment confirmation is enabled, only set when assigning to
	-- other users (excluding builtin admin).
	IF v_allow_assign_confirm = 1 AND in_user_sid != security_pkg.GetSid AND in_user_sid != security_pkg.SID_BUILTIN_ADMINISTRATOR THEN
		LogAction(csr_data_pkg.IAT_PENDING_ASSIGN_CONF, in_issue_id, v_issue_log_id);
		
		-- Update pending assignment flag.
		UPDATE csr.issue
		   SET is_pending_assignment = 1
		 WHERE issue_id = in_issue_id;
	ELSE
		LogAction(csr_data_pkg.IAT_ASSIGNED, in_issue_id, v_issue_log_id);
	END IF;

	OPEN out_user_cur FOR
		SELECT assigned_to_user_sid, assigned_to_user_name, assigned_to_full_name, assigned_to_email
		  FROM v$issue
		 WHERE issue_id = in_issue_id;

	INTERNAL_GetIssueLogEntries(v_user_sid, in_issue_id, v_issue_log_id, FALSE, out_log_cur, v_dummy_cur, out_action_cur);
END;

PROCEDURE AssignToRole(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_role_sid					IN  security_pkg.T_SID_ID,
	in_message					IN  issue_log.message%TYPE,
	out_role_cur				OUT	SYS_REFCURSOR,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT	SYS_REFCURSOR
)
AS
	v_count					security_pkg.T_SID_ID;
	v_user_sid				security_pkg.T_SID_ID;
	v_issue_log_id			issue_log.issue_log_id%TYPE;
	v_dummy_cur				SYS_REFCURSOR;
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(in_act_id, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied writing the issue with id '||in_issue_id);
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM issue i, region_role_member rrm
	 WHERE i.issue_id = in_issue_id
	   AND i.region_sid = rrm.region_sid
	   AND rrm.role_sid = in_role_sid;
	
	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Cannot assign role with sid '||in_role_sid||' to issue with id '||in_issue_id);
	END IF;
	
	-- Keep the role involved (replicates behaviour of assigning to users or creating
	-- an issue with an assigned role)
	AddRole(in_act_id, in_issue_id, in_role_sid, v_dummy_cur);
	
	UPDATE ISSUE 
	   SET assigned_to_role_sid = in_role_sid,
	       assigned_to_user_sid = NULL
	 WHERE issue_id = in_issue_id;
	 
	AddLogEntry(in_act_id, in_issue_id, 0, in_message, null, null, null, TRUE, v_issue_log_id);
	LogAction(csr_data_pkg.IAT_ASSIGNED, in_issue_id, v_issue_log_id);

	OPEN out_role_cur FOR
		SELECT role_sid, name 
		  FROM role
		 WHERE role_sid = in_role_sid;

	INTERNAL_GetIssueLogEntries(v_user_sid, in_issue_id, v_issue_log_id, FALSE, out_log_cur, v_dummy_cur, out_action_cur);
END;

PROCEDURE ReturnToUser(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_reason					IN  issue_log.message%TYPE,
	out_user_cur				OUT	SYS_REFCURSOR,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_log_cur			OUT SYS_REFCURSOR
)
AS
	v_issue_log_id			issue_log.issue_log_id%TYPE;	
	v_dummy_cur				SYS_REFCURSOR;
	v_user_name				csr.csr_user.full_name%TYPE;
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(in_act_id, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied returning the issue with id '||in_issue_id);
	END IF;
	
	SELECT full_name
	  INTO v_user_name
	  FROM csr.csr_user
	 WHERE csr_user_sid = in_user_sid;
	
	AddUser(in_act_id, in_issue_id, in_user_sid, v_dummy_cur);
	
	UPDATE ISSUE 
	   SET assigned_to_user_sid = in_user_sid,
	   	   assigned_to_role_sid = NULL
	 WHERE issue_id = in_issue_id;
	 
	OPEN out_user_cur FOR
		SELECT assigned_to_user_sid, assigned_to_user_name, assigned_to_full_name, assigned_to_email
		  FROM v$issue
		 WHERE issue_id = in_issue_id;
	 
	AddLogEntry(in_act_id, in_issue_id, 0, in_reason, null, null, null, TRUE, v_issue_log_id);
	INTERNAL_GetIssueLogEntries(in_user_sid, in_issue_id, v_issue_log_id, FALSE, out_log_cur, v_dummy_cur, out_action_log_cur);
	
	LogAction(csr_data_pkg.IAT_RETURNED, in_issue_id, v_issue_log_id);
END;

PROCEDURE MarkAsResolved(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_message					IN  issue_log.message%TYPE,
	in_var_expl					IN  issue.var_expl%TYPE,
	in_manual_completion_dtm	IN	issue.manual_completion_dtm%TYPE,
	in_manual_comp_dtm_set_dtm	IN	issue.manual_comp_dtm_set_dtm%TYPE,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT	SYS_REFCURSOR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_issue_log_id			issue_log.issue_log_id%TYPE;
	v_issue_action_log_id	issue_action_log.issue_action_log_id%TYPE;
	v_log_files_cur			SYS_REFCURSOR;
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(in_act_id, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied writing the issue with id '||in_issue_id);
	END IF;

	IF in_var_expl IS NOT NULL THEN
		AddLogEntry(in_act_id, in_issue_id, 0, in_var_expl, null, null, null, FALSE, v_issue_log_id);
		LogAction(
			in_issue_action_type_id	=>	csr_data_pkg.IAT_EXPLAINED_VARIANCE,
			in_issue_id				=>	in_issue_id,
			in_issue_log_id			=>	v_issue_log_id,
			out_issue_action_log_id	=>	v_issue_action_log_id
		);
	END IF;

	AddLogEntry(in_act_id, in_issue_id, 0, in_message, null, null, null, FALSE, v_issue_log_id);
	LogAction(
		in_issue_action_type_id	=>	csr_data_pkg.IAT_RESOLVED,
		in_issue_id				=>	in_issue_id,
		in_issue_log_id			=>	v_issue_log_id,
		out_issue_action_log_id	=>	v_issue_action_log_id
	);
	
	IF in_manual_completion_dtm IS NOT NULL THEN
		-- Set the completion date for the action log.
		UPDATE issue_action_log
		   SET new_manual_comp_dtm = in_manual_completion_dtm,
			   new_manual_comp_dtm_set_dtm = in_manual_comp_dtm_set_dtm
		 WHERE issue_action_log_id = v_issue_action_log_id
		   AND issue_id = in_issue_id;
	END IF;
	
	User_Pkg.GetSID(in_act_id, v_user_sid);

	UPDATE ISSUE 
       SET resolved_by_user_sid = v_user_sid, 
           resolved_dtm = SYSDATE,
           var_expl = in_var_expl,
           assigned_to_user_sid = owner_user_sid, -- assign back to the owner
           assigned_to_role_sid = owner_role_sid,
		   manual_completion_dtm = in_manual_completion_dtm,
		   manual_comp_dtm_set_dtm = SYSDATE
     WHERE issue_id = in_issue_id;
	
	LogAction(csr_data_pkg.IAT_ASSIGNED, in_issue_id, v_issue_log_id);
	INTERNAL_StatusChanged(in_issue_id, csr_data_pkg.IAT_RESOLVED);
	
    INTERNAL_GetIssueLogEntries(v_user_sid, in_issue_id, v_issue_log_id, FALSE, out_log_cur, v_log_files_cur, out_action_cur);
END;

PROCEDURE MarkAsRejected(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_message					IN  issue_log.message%TYPE,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT	SYS_REFCURSOR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_issue_log_id			issue_log.issue_log_id%TYPE;
	v_log_files_cur			SYS_REFCURSOR;
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(in_act_id, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied writing the issue with id '||in_issue_id);
	END IF;

	AddLogEntry(in_act_id, in_issue_id, 0, in_message, null, null, null, FALSE, v_issue_log_id);
	LogAction(csr_data_pkg.IAT_REJECTED, in_issue_id, v_issue_log_id);

	User_Pkg.GetSID(in_act_id, v_user_sid);

	UPDATE ISSUE 
	   SET rejected_by_user_sid = v_user_sid, 
			rejected_dtm = SYSDATE,
			assigned_to_user_sid = owner_user_sid, -- assign back to person who raised it
			assigned_to_role_sid = owner_role_sid
	WHERE issue_id = in_issue_id;

	LogAction(csr_data_pkg.IAT_ASSIGNED, in_issue_id, v_issue_log_id);
	INTERNAL_StatusChanged(in_issue_id, csr_data_pkg.IAT_REJECTED);

	INTERNAL_GetIssueLogEntries(v_user_sid, in_issue_id, v_issue_log_id, FALSE, out_log_cur, v_log_files_cur, out_action_cur);
END;

PROCEDURE SetOwnerUser (
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_to_user_sid				IN  security_pkg.T_SID_ID
)
AS
	v_dummy_cur				SYS_REFCURSOR;
BEGIN
	IF NOT IsOwner(in_act_id, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'You cannot change the owner of the issue with id '||in_issue_id||' because you are not the current owner');
	END IF;
	
	AddUser(in_act_id, in_issue_id, in_to_user_sid, 1, v_dummy_cur);

	UPDATE issue
	   SET owner_user_sid = in_to_user_sid,
	       owner_role_sid = NULL
	 WHERE issue_id = in_issue_id;
END;

PROCEDURE SetOwnerUserWithLogging (
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_message					IN  issue_log.message%TYPE,
	out_user_cur				OUT	SYS_REFCURSOR,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT SYS_REFCURSOR
)
AS
	v_dummy_cur				SYS_REFCURSOR;
	v_issue_log_id			issue_log.issue_log_id%TYPE;
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Issue management') AND NOT IsRaiser(in_act_id, in_issue_id) AND NOT IsOwner(in_act_id, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_INVALID_OWNER,
			'You cannot change the owner of the issue with id '||in_issue_id||' because you are not the raiser nor the owner nor you have Issue Management capability. in_to_user_sid: ' || in_to_user_sid || ', in_issue_id: ' || in_issue_id);
	END IF;
	
	IF NOT IsOwnerOfIssueCanBeChanged(in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_INVALID_OWNER,
			'Owner of the issue with id '||in_issue_id||' is not allowed to be changed. To allow it modify the setting (Owner can be changed) of the issue type');
	END IF;

	AddUser(in_act_id, in_issue_id, in_to_user_sid, 1, v_dummy_cur);

	UPDATE issue
	   SET owner_user_sid = in_to_user_sid,
	       owner_role_sid = NULL
	 WHERE issue_id = in_issue_id;
	 
 	INTERNAL_AddLogEntry(in_act_id, in_issue_id, 0, in_message, null, null, null, TRUE, TRUE, v_issue_log_id);
	
	LogAction(csr_data_pkg.IAT_OWNER_CHANGED, in_issue_id, v_issue_log_id);
	INTERNAL_GetIssueLogEntries(in_to_user_sid, in_issue_id, v_issue_log_id, FALSE, out_log_cur, v_dummy_cur, out_action_cur);
	
	OPEN out_user_cur FOR
	SELECT owner_user_sid, owner_user_name, owner_full_name, owner_email
	  FROM v$issue
	 WHERE issue_id = in_issue_id;
END;

PROCEDURE SetOwnerRole (
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_to_role_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT IsOwner(in_act_id, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'You cannot change the owner of the issue with id '||in_issue_id||' because you are not the current owner');
	END IF;
	
	UPDATE issue
	   SET owner_user_sid = NULL,
	       owner_role_sid = in_to_role_sid
	 WHERE issue_id = in_issue_id;
END;

PROCEDURE MarkAsClosed(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_message					IN  issue_log.message%TYPE,
	in_manual_completion_dtm	IN	issue.manual_completion_dtm%TYPE,
	in_manual_comp_dtm_set_dtm	IN	issue.manual_comp_dtm_set_dtm%TYPE,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT	SYS_REFCURSOR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_issue_log_id			issue_log.issue_log_id%TYPE;
	v_cur_files				SYS_REFCURSOR;
	v_issue_action_log_id	issue_action_log.issue_action_log_id%TYPE;
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(in_act_id, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied writing the issue with id '||in_issue_id);
	END IF;

	User_Pkg.GetSID(in_act_id, v_user_sid);
	
	IF NOT (IsOwner(in_act_id, in_issue_id) OR
	   security.security_pkg.IsAdmin(security.security_pkg.GetAct) OR
	   csr_data_pkg.CheckCapability('Issue management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'You cannot close issue with id '||in_issue_id||' because you are not the owner of it, or a built in administrator and you don''t have issue management capability');
	END IF;

	INTERNAL_AddLogEntry(in_act_id, in_issue_id, 0, in_message, null, null, null, FALSE, TRUE, v_issue_log_id);
	
	UPDATE issue 
	   SET closed_by_user_sid = v_user_sid, 
		   closed_dtm = SYSDATE
	 WHERE issue_id = in_issue_id;
	
	LogAction(
		in_issue_action_type_id	=>	csr_data_pkg.IAT_CLOSED,
		in_issue_id				=>	in_issue_id,
		in_issue_log_id			=>	v_issue_log_id,
		out_issue_action_log_id	=>	v_issue_action_log_id
	);
	
	-- also mark as resolved if it's not resolved already (the order feels backwards, but it works for the ui)
	UPDATE issue 
	   SET resolved_by_user_sid = v_user_sid, 
		   resolved_dtm = SYSDATE
	 WHERE issue_id = in_issue_id
	   AND resolved_dtm IS NULL;

	IF SQL%ROWCOUNT > 0 THEN
		LogAction(
			in_issue_action_type_id	=>	csr_data_pkg.IAT_RESOLVED,
			in_issue_id				=>	in_issue_id,
			in_issue_log_id			=>	v_issue_log_id,
			out_issue_action_log_id	=>	v_issue_action_log_id
			);			
	END IF;
	
	IF in_manual_completion_dtm IS NOT NULL THEN
		-- Set the completion date for the action log.
		UPDATE issue_action_log
		   SET new_manual_comp_dtm = in_manual_completion_dtm,
			   new_manual_comp_dtm_set_dtm = in_manual_comp_dtm_set_dtm
		 WHERE issue_action_log_id = v_issue_action_log_id
		   AND issue_id = in_issue_id;
		
		UPDATE issue 
		   SET manual_completion_dtm = in_manual_completion_dtm,
			   manual_comp_dtm_set_dtm = SYSDATE
		 WHERE issue_id = in_issue_id;
	END IF;

	
	INTERNAL_StatusChanged(in_issue_id, csr_data_pkg.IAT_RESOLVED);

	INTERNAL_GetIssueLogEntries(v_user_sid, in_issue_id, v_issue_log_id, FALSE, out_log_cur, v_cur_files, out_action_cur);
END;


PROCEDURE MarkAsUnresolved(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_message					IN  issue_log.message%TYPE,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT	SYS_REFCURSOR
)
AS
	v_issue_log_id			issue_log.issue_log_id%TYPE;	
	v_user_sid				security_pkg.T_SID_ID;
	v_log_files_cur			SYS_REFCURSOR;
BEGIN
	
	User_Pkg.GetSID(in_act_id, v_user_sid);
	
	AddLogEntry(in_act_id, in_issue_id, 0, in_message, null, null, null, FALSE, v_issue_log_id);
	
	INTERNAL_GetIssueLogEntries(v_user_sid, in_issue_id, v_issue_log_id, FALSE, out_log_cur, v_log_files_cur, out_action_cur);
END;

PROCEDURE NewEmailReceived (
	in_mail_address				IN  VARCHAR2,
	in_mail_name				IN  VARCHAR2,
	in_subject					IN	VARCHAR2,
	in_message					IN  issue_log.message%TYPE,
	out_issue_id				OUT issue.issue_id%TYPE,
	out_log_id					OUT issue_log.issue_log_id%TYPE
)
AS
	v_correspondent_id			correspondent.correspondent_id%TYPE;
	v_role_sid					security.security_pkg.T_SID_ID;
BEGIN
	-- create a new issue
	v_correspondent_id := CreateCorrespondent(in_mail_name, in_mail_address, NULL, NULL);
	v_role_sid := role_pkg.GetRoleIdByKey('enquiry_manager');
	
	CreateIssue(
		in_label				=> in_subject,
		in_source_label			=> 'In-bound mail',
		in_issue_type_id		=> csr_data_pkg.ISSUE_ENQUIRY,
		in_correspondent_id		=> v_correspondent_id,
		in_raised_by_user_sid	=> security_pkg.getSID, -- hmmm... is this ok?
		in_assigned_to_user_sid	=> null,
		in_assigned_to_role_sid	=> v_role_sid,
		in_due_dtm				=> null,
		out_issue_id			=> out_issue_id
	);
			
	-- this checks security for us
	EmailReceived(out_issue_id, in_mail_address, in_mail_name, in_message, out_log_id);
END;


PROCEDURE EmailReceived (
	in_issue_id					IN  issue.issue_id%TYPE,
	in_mail_address				IN  VARCHAR2,
	in_mail_name				IN  VARCHAR2,
	in_message					IN  issue_log.message%TYPE,
	out_log_id					OUT issue_log.issue_log_id%TYPE
)
AS
	v_found						BOOLEAN DEFAULT FALSE;
	v_correspondent_id			correspondent.correspondent_id%TYPE;
	v_user_sid					csr_user.csr_user_sid%TYPE;
BEGIN

	-- our security check here will be to ensure that this is coming from the BuiltIn Administrator
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'EmailReceived can only be run as BuiltIn/Administrator');
	END IF;

	-- first, see if the email is coming from the primary issue correspondent
	BEGIN
		SELECT c.correspondent_id
		  INTO v_correspondent_id
		  FROM issue i, correspondent c
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.app_sid = c.app_sid
		   AND i.issue_id = in_issue_id
		   AND i.correspondent_id = c.correspondent_id
		   AND LOWER(c.email) = LOWER(TRIM(in_mail_address));
		
		v_found := TRUE;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	-- if we didn't find it, see if it's from an active user
	IF NOT v_found THEN
		v_user_sid := csr_user_pkg.GetUserSidFromEmail(in_mail_address);
		v_found := v_user_sid IS NOT NULL;
	END IF;
	
	IF NOT v_found THEN
		v_correspondent_id := CreateCorrespondent(NVL(in_mail_name, in_mail_address), in_mail_address, NULL, NULL);
	END IF;
	
	IF v_correspondent_id IS NOT NULL THEN
		INTERNAL_AddCorrespLogEntry(v_correspondent_id, in_issue_id, NVL(in_message, ' '), out_log_id);
	ELSE
		INTERNAL_AddUserLogEntry(v_user_sid, in_issue_id, 0, NVL(in_message, ' '), NULL, NULL, NULL, TRUE, FALSE, out_log_id);
	END IF;

	LogAction(csr_data_pkg.IAT_EMAIL_RECEIVED, in_issue_id, out_log_id, v_user_sid, NULL, NULL, v_correspondent_id);		
END;

/*********************/
/*  Issue User stuff */
/*********************/

PROCEDURE AddUser(
	in_act_id				IN  SECURITY_PKG.T_ACT_ID,
	in_issue_id				IN  issue.issue_id%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_dummy_cur				SYS_REFCURSOR;
BEGIN
	AddUser(in_act_id, in_issue_id, in_user_sid, 0, out_cur, v_dummy_cur);
END;

PROCEDURE AddUser(
	in_act_id				IN  SECURITY_PKG.T_ACT_ID,
	in_issue_id				IN  issue.issue_id%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_is_an_owner			IN	NUMBER,	
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_dummy_cur				SYS_REFCURSOR;
BEGIN
	AddUser(in_act_id, in_issue_id, in_user_sid, in_is_an_owner, out_cur, v_dummy_cur);
END;

PROCEDURE AddUser(
	in_act_id				IN  SECURITY_PKG.T_ACT_ID,
	in_issue_id				IN  issue.issue_id%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR,
	out_action_log_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	AddUser(in_act_id, in_issue_id, in_user_sid, 0, out_cur, out_action_log_cur);
END;

/**
 * Links an Issue to Users in an array
 *
 * @param	in_act_id			Access token
 * @param	in_issue_id			The issue to link
 * @param	in_user_sid			User to link to
 */
PROCEDURE AddUser(
	in_act_id				IN  SECURITY_PKG.T_ACT_ID,
	in_issue_id				IN  issue.issue_id%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_is_an_owner			IN	NUMBER,
	out_cur					OUT	SYS_REFCURSOR,
	out_action_log_cur		OUT	SYS_REFCURSOR
)
AS
	v_issue_action_log_id	issue_action_log.issue_action_log_id%TYPE;
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(in_act_id, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied writing the issue with id '||in_issue_id);
	END IF;
	
	
	BEGIN
		INSERT INTO issue_involvement
			(issue_id, is_an_owner, user_sid)
		VALUES
			(in_issue_id, in_is_an_owner, in_user_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore if the user is alreaday assigned
	END;

	IF SQL%ROWCOUNT > 0 THEN
		LogAction(
			in_issue_action_type_id => csr_data_pkg.IAT_INVOLVED_USER_ASSIGNED, 
			in_issue_id => in_issue_id,
			in_re_user_sid => in_user_sid,
			out_issue_action_log_id => v_issue_action_log_id);
	END IF;
		
	chain.filter_pkg.ClearCacheForUser (
		in_card_group_id => chain.filter_pkg.FILTER_TYPE_ISSUES,
		in_user_sid => in_user_sid
	);
	
	INTERNAL_GetIssueActionLogs(in_issue_id, NULL, v_issue_action_log_id, NULL, out_action_log_cur);	
	
	OPEN out_cur FOR
		SELECT ii.user_sid, ii.is_an_owner, cu.user_name, cu.full_name, cu.friendly_name, cu.email,
			CASE WHEN it.owner_can_be_changed = 1 AND (i.raised_by_user_sid = cu.csr_user_sid OR csr_data_pkg.SQL_CheckCapability('Issue management') = 1) THEN 1 ELSE 0 END can_change_owner_of_issue
		  FROM csr_user cu
		  JOIN issue_involvement ii
		    ON ii.issue_id = in_issue_id 
		   AND ii.user_sid = in_user_sid
		   AND ii.user_sid = cu.csr_user_sid
		  JOIN issue i
		    ON i.app_sid = ii.app_sid 
		   AND i.issue_id = ii.issue_id
		  JOIN issue_type it
		    ON it.app_sid = ii.app_sid 
		   AND it.issue_type_id = i.issue_type_id
		 WHERE cu.csr_user_sid != security.security_pkg.SID_BUILTIN_ADMINISTRATOR;
END;

PROCEDURE RemoveUser(
	in_act_id				IN  SECURITY_PKG.T_ACT_ID,
	in_issue_id				IN  issue.issue_id%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID
)
AS
	v_dummy_log_cur			SYS_REFCURSOR;
BEGIN
	RemoveUser(in_act_id, in_issue_id, in_user_sid, v_dummy_log_cur);
END;

PROCEDURE RemoveUser(
	in_act_id				IN  SECURITY_PKG.T_ACT_ID,
	in_issue_id				IN  issue.issue_id%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID,
	out_action_log_cur		OUT	SYS_REFCURSOR	
)
AS
	v_issue_action_log_id	issue_action_log.issue_action_log_id%TYPE;
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(in_act_id, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied removing users for the issue with id '||in_issue_id);
	END IF;

	DELETE FROM issue_involvement
	 WHERE user_sid = in_user_sid
	   AND issue_id = in_issue_id;
	
	chain.filter_pkg.ClearCacheForUser (
		in_card_group_id => chain.filter_pkg.FILTER_TYPE_ISSUES,
		in_user_sid => in_user_sid
	);
	
	LogAction(
		in_issue_action_type_id => csr_data_pkg.IAT_INVOLVED_USER_REMOVED, 
		in_issue_id => in_issue_id,
		in_re_user_sid => in_user_sid,
		out_issue_action_log_id => v_issue_action_log_id);
	
	INTERNAL_GetIssueActionLogs(in_issue_id, NULL, v_issue_action_log_id, NULL, out_action_log_cur);	
END;

PROCEDURE GetIssueComments(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_issue_id				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(in_act_id, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied reading the issue with id '||in_issue_id);
	END IF;
	
	UNSEC_GetIssueComments(in_issue_id, out_cur);
END;

PROCEDURE UNSEC_GetIssueComments(
	in_issue_id				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT 	app_sid, issue_id, message, logged_dtm, logged_by_full_name, logged_by_email, 
				logged_by_user_name, param_1, param_2, param_3, is_system_generated, is_user logged_by_is_user
		  FROM v$issue_log 
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND issue_id = in_issue_id
		 ORDER BY logged_dtm;
END;

PROCEDURE GetIssueUsers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_issue_id				IN	security_pkg.T_SID_ID,
	out_users_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(in_act_id, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied reading the issue with id '||in_issue_id);
	END IF;
	
	UNSEC_GetIssueUsers(in_issue_id, out_users_cur);
END;


PROCEDURE UNSEC_GetIssueUsers(
	in_issue_id				IN	security_pkg.T_SID_ID,
	out_users_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Needed when triggering automated issue alerts
	OPEN out_users_cur FOR
		WITH issue_users AS (
			SELECT i.app_sid, i.issue_id, i.issue_pending_val_id, i.issue_sheet_value_id, i.issue_meter_id, 
					i.issue_meter_alarm_id, i.issue_meter_raw_data_id, i.issue_meter_data_source_id,
					i.issue_supplier_id, i.issue_compliance_region_id, 
					iiu.user_sid, iiu.is_an_owner, iiu.user_name, iiu.full_name, 
					iiu.full_name friendly_name, -- need to change the component but I can't release by binaries atm
					iiu.email, r.description region_description, i.label, i.source_label,
					i.issue_non_compliance_id, GetIssueUrl(in_issue_id) issue_url, i.source_url,
				    i.raised_dtm, i.due_dtm, i.issue_ref, au.full_name assigned_to, i.assigned_to_user_sid, i.is_critical, 
					it.label issue_type_label, i.guid, 
					CASE
						WHEN i.closed_dtm IS NOT NULL THEN 'Closed'
						WHEN i.resolved_dtm IS NOT NULL THEN 'Resolved'
						WHEN i.rejected_dtm IS NOT NULL THEN 'Rejected'
						ELSE 'Ongoing'
					 END issue_status, ip.due_date_offset priority_due_date_offset, ip.description priority_description
			  FROM issue i
			  JOIN v$issue_involved_user iiu ON i.app_sid = iiu.app_sid AND iiu.issue_id = i.issue_id
			  JOIN issue_type it ON i.app_sid = it.app_sid AND i.issue_type_id = it.issue_type_id
			  LEFT JOIN v$region r ON i.region_sid = r.region_sid AND i.app_sid = r.app_sid
			  LEFT JOIN csr_user au ON i.app_sid = au.app_sid AND i.assigned_to_user_sid = au.csr_user_sid
			  LEFT JOIN csr.issue_priority ip ON i.app_sid = ip.app_sid AND i.issue_priority_id = ip.issue_priority_id
			 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND i.issue_id = in_issue_id
			   AND (it.email_involved_roles = 1 OR iiu.from_role = 0)
			   AND (it.email_involved_users= 1 OR iiu.from_role = 1)
		)
		SELECT *
		  FROM (
				-- DELEGATIONS
				SELECT iu.app_sid, iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
						c.editing_url || sheet_pkg.GetSheetQueryString(isv.app_sid, isv.ind_sid, isv.region_sid, isv.start_dtm, isv.end_dtm, iu.user_sid)
					   || '#indSid='||isv.ind_Sid||',regionSid='||isv.region_sid url, null url_label,
					   c.editing_url || sheet_pkg.GetSheetQueryString(isv.app_sid, isv.ind_sid, isv.region_sid, isv.start_dtm, isv.end_dtm, iu.user_sid)
					   || '#indSid='||isv.ind_Sid||',regionSid='||isv.region_sid parent_url, 'View sheet' parent_url_label,
					    iu.region_description, iu.label, iu.source_label, iu.issue_url,
					    iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.guid, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu, customer c, issue_sheet_value isv
				 WHERE iu.app_sid = c.app_sid
				   AND iu.app_sid = isv.app_sid AND iu.issue_sheet_value_id = isv.issue_sheet_value_id
				UNION ALL
				-- METER
				SELECT iu.app_sid, iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   meter_pkg.GetIssueMeterUrl(im.issue_meter_id) url, 'View meter data' url_label, 
					   meter_pkg.GetIssueMeterUrl(im.issue_meter_id) parent_url, 'View meter data' parent_url_label, 
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.guid, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu, issue_meter im
				 WHERE iu.app_sid = im.app_sid AND iu.issue_meter_id = im.issue_meter_id
				UNION ALL
				-- METER ALARM
				SELECT iu.app_sid, iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   meter_alarm_pkg.GetAlarmUrl(ima.issue_meter_alarm_id) url, 'View meter data' url_label, 
					   meter_alarm_pkg.GetAlarmUrl(ima.issue_meter_alarm_id) parent_url, 'View meter data' parent_url_label, 
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.guid, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu, issue_meter_alarm ima
				 WHERE iu.app_sid = ima.app_sid AND iu.issue_meter_alarm_id = ima.issue_meter_alarm_id
				UNION ALL
				-- METER RAW DATA
				SELECT iu.app_sid, iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   meter_monitor_pkg.GetRawDataUrl(rd.issue_meter_raw_data_id) url, 'View raw data' url_label, 
					   meter_monitor_pkg.GetRawDataUrl(rd.issue_meter_raw_data_id) parent_url, 'View raw data' parent_url_label, 
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.guid, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu, issue_meter_raw_data rd
				 WHERE iu.app_sid = rd.app_sid AND iu.issue_meter_raw_data_id = rd.issue_meter_raw_data_id
				UNION ALL
				-- METER DATA SOURCE
				SELECT iu.app_sid, iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   meter_monitor_pkg.GetDataSourceUrl(ds.issue_meter_data_source_id) url, 'View raw data' url_label, 
					   meter_monitor_pkg.GetDataSourceUrl(ds.issue_meter_data_source_id) parent_url, 'View raw data' parent_url_label, 
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.guid, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu, issue_meter_data_source ds
				 WHERE iu.app_sid = ds.app_sid AND iu.issue_meter_data_source_id = ds.issue_meter_data_source_id
				UNION ALL
				-- SUPPLIER
				SELECT iu.app_sid, iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   '/csr/site/chain/manageCompany/manageCompany.acds?companySid='||isup.company_sid url, 'View supplier' url_label, 
					   '/csr/site/chain/manageCompany/manageCompany.acds?companySid='||isup.company_sid parent_url, 'View supplier' parent_url_label, 
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.guid, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu, issue_supplier isup
				 WHERE iu.app_sid = isup.app_sid AND iu.issue_supplier_id = isup.issue_supplier_id
				UNION ALL
				-- COMPLIANCE
				SELECT iu.app_sid, iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   compliance_pkg.GetComplianceItemUrl(icr.flow_item_id) url, 'View compliance item' url_label, 
					   compliance_pkg.GetComplianceItemUrl(icr.flow_item_id) parent_url, 'View compliance item' parent_url_label, 
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.guid, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu, issue_compliance_region icr
				 WHERE iu.app_sid = icr.app_sid AND iu.issue_compliance_region_id = icr.issue_compliance_region_id
				UNION ALL
				-- AUDITS
				SELECT iu.app_sid, iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   audit_pkg.GetIssueAuditUrl(nc.created_in_audit_sid) url, 'View audit' url_label, 
					   audit_pkg.GetIssueAuditUrl(nc.created_in_audit_sid) parent_url, 'View audit' parent_url_label, 
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.guid, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu
				  JOIN issue_non_compliance inc ON iu.issue_non_compliance_id = inc.issue_non_compliance_id AND iu.app_sid = inc.app_sid
				  JOIN non_compliance nc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
				UNION ALL
				-- Everything else
				SELECT iu.app_sid, iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   source_url url, CASE WHEN source_url IS NOT NULL THEN 'View form' END url_label,
					   source_url parent_url, CASE WHEN source_url IS NOT NULL THEN 'View form' END parent_url_label,
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.guid, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu
				 WHERE iu.issue_pending_val_id IS NULL
				   AND iu.issue_sheet_value_id IS NULL
				   AND iu.issue_meter_id IS NULL
				   AND iu.issue_meter_alarm_id IS NULL
				   AND iu.issue_meter_raw_data_id IS NULL
				   AND iu.issue_meter_data_source_id IS NULL
				   AND iu.issue_supplier_id IS NULL
				   AND iu.issue_non_compliance_id IS NULL
				   AND iu.issue_compliance_region_id IS NULL
			);
END;

/**
 * Links an Issue to Roles in an array
 *
 * @param	in_act_id			Access token
 * @param	in_issue_id			The issue to link
 * @param	in_role_sid			Role to link to
 */
PROCEDURE AddRole(
	in_act_id				IN  SECURITY_PKG.T_ACT_ID,
	in_issue_id				IN  issue.issue_id%TYPE,
	in_role_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(in_act_id, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied writing the issue with id '||in_issue_id);
	END IF;
	
	
	BEGIN
		INSERT INTO issue_involvement
			(issue_id, is_an_owner, role_sid)
		VALUES
			(in_issue_id, 0, in_role_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore if the user is alreaday assigned
	END;
	
	chain.filter_pkg.ClearCacheForAllUsers (
		in_card_group_id => chain.filter_pkg.FILTER_TYPE_ISSUES
	);
	
	OPEN out_cur FOR
		SELECT ii.role_sid, ii.is_an_owner, r.name
		  FROM issue_involvement ii
		  JOIN role r
		    ON ii.app_sid = r.app_sid
		   AND ii.role_sid = r.role_sid
		 WHERE ii.issue_id = in_issue_id 
		   AND ii.role_sid = in_role_sid;
END;

PROCEDURE RemoveRole(
	in_act_id				IN  SECURITY_PKG.T_ACT_ID,
	in_issue_id				IN  issue.issue_id%TYPE,
	in_role_sid				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(in_act_id, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied removing users for the issue with id '||in_issue_id);
	END IF;

	DELETE FROM issue_involvement
	 WHERE role_sid = in_role_sid
	   AND issue_id = in_issue_id;
	
	chain.filter_pkg.ClearCacheForAllUsers (
		in_card_group_id => chain.filter_pkg.FILTER_TYPE_ISSUES
	);
END;

/**************************/
/* Company stuff          */
/**************************/

PROCEDURE AddCompany(
	in_issue_id				IN  issue.issue_id%TYPE,
	in_company_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(security_pkg.GetAct, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied writing the issue with id '||in_issue_id);
	END IF;
	
	
	BEGIN
		INSERT INTO issue_involvement
			(issue_id, is_an_owner, company_sid)
		VALUES
			(in_issue_id, 0, in_company_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore if the company is already assigned
	END;
	
	chain.filter_pkg.ClearCacheForAllUsers (
		in_card_group_id => chain.filter_pkg.FILTER_TYPE_ISSUES
	);
	
	OPEN out_cur FOR
		SELECT ii.role_sid, ii.is_an_owner, c.name
		  FROM issue_involvement ii
		  JOIN chain.company c
		    ON ii.app_sid = c.app_sid
		   AND ii.company_sid = c.company_sid
		 WHERE ii.issue_id = in_issue_id 
		   AND ii.company_sid = in_company_sid;
END;

PROCEDURE RemoveCompany(
	in_issue_id				IN  issue.issue_id%TYPE,
	in_company_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(security_pkg.GetAct, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied removing users for the issue with id '||in_issue_id);
	END IF;

	DELETE FROM issue_involvement
	 WHERE issue_id = in_issue_id 
	   AND company_sid = in_company_sid;
	
	chain.filter_pkg.ClearCacheForAllUsers (
		in_card_group_id => chain.filter_pkg.FILTER_TYPE_ISSUES
	);
END;


/**************************/
/*  Issue Log table stuff */
/**************************/

PROCEDURE AddLogEntryFileFromCache(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_issue_log_id		IN	issue_log.issue_log_id%TYPE,
    in_cache_key		IN	aspen2.filecache.cache_key%TYPE
)
AS
	v_act_id			security_pkg.T_ACT_ID DEFAULT NVL(in_act_id, security_pkg.GetAct);
	v_issue_id			issue.issue_id%TYPE;
BEGIN
		
	SELECT issue_id
	  INTO v_issue_id
	  FROM issue_log
	 WHERE issue_log_id = in_issue_log_id;
	
	IF NOT issue_pkg.IsAccessAllowed(v_act_id, v_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied writing the issue with id '||v_issue_id);
	END IF;
	
	INSERT INTO issue_log_file
	(issue_log_file_id, issue_log_id, filename, mime_type, data, sha1) 
	SELECT issue_log_file_id_seq.nextval, in_issue_log_id, filename, mime_type, object, 
		   dbms_crypto.hash(object, dbms_crypto.hash_sh1)
	  FROM aspen2.filecache 
	 WHERE cache_key = in_cache_key;
    
    IF SQL%ROWCOUNT = 0 THEN
    	-- pah! not found
        RAISE_APPLICATION_ERROR(-20001, 'Cache Key "'||in_cache_key||'" not found');
    END IF; 
END;	

PROCEDURE AddLogEntryFileFromCacheByGuid(
	in_guid				IN  issue.guid%TYPE,
	in_issue_log_id		IN	issue_log.issue_log_id%TYPE,
    in_cache_key		IN	aspen2.filecache.cache_key%TYPE
)
AS
	v_issue_id		issue.issue_id%TYPE;
BEGIN
	-- we need to be able to match an issue guid to a corresponding log entry id for 
	SELECT i.issue_id
	  INTO v_issue_id
	  FROM issue i, issue_log il
	 WHERE i.guid = in_guid
	   AND i.issue_id = il.issue_id
	   AND il.issue_log_id = in_issue_log_id;
	
	INSERT INTO issue_log_file
	(issue_log_file_id, issue_log_id, filename, mime_type, data, sha1) 
	SELECT issue_log_file_id_seq.nextval, in_issue_log_id, filename, mime_type, object, 
		   dbms_crypto.hash(object, dbms_crypto.hash_sh1)
	  FROM aspen2.filecache 
	 WHERE cache_key = in_cache_key;
    
    IF SQL%ROWCOUNT = 0 THEN
    	-- pah! not found
        RAISE_APPLICATION_ERROR(-20001, 'Cache Key "'||in_cache_key||'" not found');
    END IF; 
END;	



-- TODO: I don't think we'll need this...
PROCEDURE GetLogEntryFiles(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_issue_log_id			IN	issue_log_file.issue_log_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_issue_id	issue.issue_id%TYPE;
BEGIN
	SELECT issue_id
	  INTO v_issue_id
	  FROM issue_log 
	 WHERE issue_log_id = in_issue_log_id;
	
	IF NOT issue_pkg.IsAccessAllowed(in_act_id, v_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied reading the issue with id '||v_issue_id);
	END IF;

	OPEN out_cur FOR
		SELECT filename, mime_type, sha1, uploaded_dtm, issue_log_id, issue_log_file_id, LENGTH(data) file_size
		  FROM issue_log_file
		 WHERE issue_log_id = in_issue_log_id;
END;

PROCEDURE GetLogEntryFile(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_issue_log_file_id	IN	issue_log_file.issue_log_file_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_issue_id				issue.issue_id%TYPE;
	v_allow_access 			BOOLEAN;
	v_user_sid				security_pkg.T_SID_ID;
BEGIN
	SELECT il.issue_id
	  INTO v_issue_id
	  FROM issue_log_file ilf	
	  JOIN issue_log il ON ilf.issue_log_id = il.issue_log_id
	 WHERE ilf.issue_log_file_id = in_issue_log_file_id;
	
	v_allow_access := IsAccessAllowed(in_act_id, v_issue_id);
	IF NOT v_allow_access AND IssueIsPublic(v_issue_id) THEN
		user_pkg.GetSid(in_act_id, v_user_sid);
		IF v_user_sid != security_pkg.SID_BUILTIN_GUEST THEN
			v_allow_access := TRUE;
		END IF;
	END IF;
	
	IF NOT v_allow_access THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied reading the issue with id '||v_issue_id);
	END IF;

	OPEN out_cur FOR
		SELECT filename, mime_type, data, sha1, uploaded_dtm, issue_log_id, issue_log_file_id
		  FROM issue_log_file
		 WHERE issue_log_file_id = in_issue_log_file_id;	
END;

PROCEDURE GetLogEntryFileByGuid(
	in_guid					IN  issue.guid%TYPE,
	in_issue_log_file_id	IN	issue_log_file.issue_log_file_Id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_dummy					issue.issue_id%TYPE;
BEGIN
	-- they need to know both the issue guid and the file id in order to download this file
	-- TODO: we could use additional security to make sure that they either have read permission on the issue, 
	-- or that the log_file corresponds to a log entry that is either assigned to the correspondent, or from the correspondent
	-- but that seems like overkill atm
	BEGIN
		SELECT i.issue_id
		  INTO v_dummy
		  FROM issue i, issue_log il, issue_log_file ilf
		 WHERE i.guid = in_guid
		   AND i.issue_id = il.issue_id
		   AND il.issue_log_id = ilf.issue_log_id
		   AND ilf.issue_log_file_id = in_issue_log_file_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Could not find issue with guid '||in_guid||' corresponding to file with id' || in_issue_log_file_id);
	END;
	
	OPEN out_cur FOR
		SELECT filename, mime_type, data, sha1, uploaded_dtm, issue_log_id, issue_log_file_id
		  FROM issue_log_file
		 WHERE issue_log_file_id = in_issue_log_file_id;	
END;

/**
 * Writes a log entry to the Issue Log
 *
 * @param	in_act_id				Access token
 * @param	in_issue_id				The issue to write the entry for
 * @param	in_is_system_generated	Indicates that the log entry has been generated by the system
 * @param	in_message				The message to write to the log
 */
PROCEDURE AddLogEntry(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_is_system_generated		IN  issue_log.is_system_generated%TYPE,
	in_message					IN  issue_log.message%TYPE,
	in_param_1					IN	issue_log.param_1%TYPE,
	in_param_2					IN	issue_log.param_2%TYPE,
	in_param_3					IN	issue_log.param_3%TYPE,
	out_issue_log_id			OUT issue_log.issue_log_id%TYPE
)
AS
BEGIN
	AddLogEntry(in_act_id, in_issue_id, in_is_system_generated, in_message, in_param_1, in_param_2, in_param_3, in_is_system_generated = 1, out_issue_log_id);
END;

PROCEDURE AddLogEntryReturnRow(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_message					IN  issue_log.message%TYPE,
	in_param_1					IN	issue_log.param_1%TYPE,
	in_param_2					IN	issue_log.param_2%TYPE,
	in_param_3					IN	issue_log.param_3%TYPE,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT	SYS_REFCURSOR
)
AS
	v_issue_log_id			issue_log.issue_log_id%TYPE;
	v_user_sid				security_pkg.T_SID_ID;
	v_log_files_cur			SYS_REFCURSOR;
BEGIN

	user_pkg.GetSid(in_act_id, v_user_sid);	
	
	AddLogEntry(in_act_id, in_issue_id, 0, in_message, null, null, null, FALSE, v_issue_log_id);

	INTERNAL_GetIssueLogEntries(v_user_sid, in_issue_id, v_issue_log_id, FALSE, out_log_cur, v_log_files_cur, out_action_cur);
END;

PROCEDURE DeleteIssue(
  in_issue_id   IN  issue.issue_id%TYPE
)
AS
	v_deletable_by_owner	issue_type.deletable_by_owner%TYPE;
	v_deletable_by_raiser	issue_type.deletable_by_raiser%TYPE;
	v_deletable_by_admin	issue_type.deletable_by_administrator%TYPE;
	v_owner_user_sid		security_pkg.T_SID_ID;
	v_raiser_user_sid		security_pkg.T_SID_ID;
	v_owner_role_sid		security_pkg.T_SID_ID;
	v_region_sid			security_pkg.T_SID_ID;
	v_is_resolved			NUMBER;
	v_is_closed				NUMBER;
	v_is_rejected			NUMBER;
	v_issue_log_id			NUMBER;
	v_issue_survey_answer_id issue.issue_survey_answer_id%TYPE;
	v_issue_action_log_id	issue_action_log.issue_action_log_id%TYPE;
BEGIN
	-- make sure user has delete permission (handled by view)
	SELECT deletable_by_owner, deletable_by_raiser, deletable_by_administrator, is_resolved,
		   is_closed, is_rejected, owner_user_sid, owner_role_sid, raised_by_user_sid, region_sid
	  INTO v_deletable_by_owner, v_deletable_by_raiser, v_deletable_by_admin, v_is_resolved,
		   v_is_closed, v_is_rejected, v_owner_user_sid, v_owner_role_sid,
		   v_raiser_user_sid, v_region_sid
	  FROM v$issue
	 WHERE issue_id = in_issue_id;

	-- make sure the issue isn't closed/rejected/resolved (usually handled in JS...)
	IF v_is_resolved = 1 OR v_is_closed = 1 OR v_is_rejected = 1 THEN
		RAISE_APPLICATION_ERROR(-20001,'Issue with ID: '||in_issue_id||' is not in a state to be deleted.');
	END IF;
	
	IF (v_deletable_by_owner = 1 AND (v_owner_user_sid = security_pkg.GetSid OR role_pkg.IsUserInRole(v_owner_role_sid, v_region_sid)))
	    OR (v_deletable_by_raiser = 1 AND (v_raiser_user_sid = security_pkg.GetSid))
		OR (v_deletable_by_admin = 1 AND csr_data_pkg.CheckCapability('Issue management')) THEN
		--UNSEC_DeleteIssue(in_issue_id);
		
		-- unhook and delete any issue_survey_answer as these have a unique constraint preventing
		-- more than one issue for the same question/response.
		SELECT issue_survey_answer_id
		  INTO v_issue_survey_answer_id
		  FROM issue
		 WHERE issue_id = in_issue_id;
		
		UPDATE issue
		   SET issue_survey_answer_id = NULL
		 WHERE issue_id = in_issue_id;
		
		DELETE FROM issue_survey_answer
		 WHERE issue_survey_answer_id = v_issue_survey_answer_id;

		DELETE FROM issue_log_file
		 WHERE issue_log_id IN (
			SELECT issue_log_id
			  FROM issue_log
			 WHERE issue_id = in_issue_id
		);

		UPDATE issue
		   SET deleted=1
		 WHERE issue_id = in_issue_id;
		 
		LogAction(csr_data_pkg.IAT_DELETED, in_issue_id, v_issue_action_log_id);
		INTERNAL_StatusChanged(in_issue_id, csr_data_pkg.IAT_DELETED);
		
		chain.filter_pkg.ClearCacheForAllUsers (
			in_card_group_id => chain.filter_pkg.FILTER_TYPE_ISSUES
		);
	ELSE
		RAISE_APPLICATION_ERROR(-20001,'You do not have permission to delete this record.');
	END IF;
END;

PROCEDURE UNSEC_DeleteIssue(
	in_issue_id		IN	issue.issue_id%TYPE
)
AS
	v_issue_pending_val_id			issue.issue_pending_val_id%TYPE;
	v_issue_sheet_value_id			issue.issue_sheet_value_id%TYPE;
	v_issue_non_compliance_id		issue.issue_non_compliance_id%TYPE;
	v_issue_survey_answer_id		issue.issue_survey_answer_id%TYPE;
	v_issue_action_id				issue.issue_action_id%TYPE;
	v_issue_meter_id				issue.issue_meter_id%TYPE;
	v_issue_meter_alarm_id			issue.issue_meter_alarm_id%TYPE;
	v_issue_meter_raw_data_id		issue.issue_meter_raw_data_id%TYPE;
	v_issue_meter_data_source_id	issue.issue_meter_data_source_id%TYPE;
	v_issue_supplier_id				issue.issue_supplier_id%TYPE;
	v_issue_compliance_region_id	issue.issue_compliance_region_id%TYPE;
BEGIN
	-- recurse down cleaning out children
	FOR r IN (
		SELECT issue_id
		  FROM issue 
		 WHERE parent_id = in_issue_id
	)
	LOOP
		UNSEC_deleteIssue(r.issue_id);
	END LOOP;
	
	-- get parents
	SELECT issue_pending_val_id, issue_sheet_value_id, issue_non_compliance_id, issue_survey_answer_id, 
		issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id,
		issue_supplier_id, issue_compliance_region_id
	  INTO v_issue_pending_val_id, v_issue_sheet_value_id, v_issue_non_compliance_id, v_issue_survey_answer_id,
	  	v_issue_action_id, v_issue_meter_id, v_issue_meter_alarm_id, v_issue_meter_raw_data_id, v_issue_meter_data_source_id,
	  	v_issue_supplier_id, v_issue_compliance_region_id
	  FROM issue
	 WHERE issue_id = in_issue_id;
	 
	-- disconnect from parents
	UPDATE issue
	   SET issue_pending_val_id = null, 
	   	   issue_sheet_value_id = null,
	   	   issue_non_compliance_id = null, 
	   	   issue_survey_answer_id = null,
	   	   issue_action_id = null,
	   	   issue_meter_id = null,
	   	   issue_meter_alarm_id = null,
	   	   issue_meter_raw_data_id = null,
	   	   issue_meter_data_source_id = null,
	   	   issue_supplier_id = null,
		   issue_compliance_region_id = null
	 WHERE issue_id = in_issue_id;

	-- now clean up the parents
	DELETE FROM issue_pending_val
	 WHERE issue_pending_val_id = v_issue_pending_val_id;

	DELETE FROM issue_sheet_value
	 WHERE issue_sheet_value_id = v_issue_sheet_value_id;
	 
	DELETE FROM issue_non_compliance
	 WHERE issue_non_compliance_id = v_issue_non_compliance_id;

	DELETE FROM issue_survey_answer
	 WHERE issue_survey_answer_id = v_issue_survey_answer_id;
	
	DELETE FROM issue_user_cover
	 WHERE issue_id = in_issue_id;
	
	DELETE FROM issue_action
	 WHERE issue_action_id = v_issue_action_id;
	
	DELETE FROM issue_meter
	 WHERE issue_meter_id = v_issue_meter_id;
	
	DELETE FROM issue_meter_alarm
	 WHERE issue_meter_alarm_id = v_issue_meter_alarm_id;
	
	DELETE FROM issue_meter_raw_data
	 WHERE issue_meter_raw_data_id = v_issue_meter_raw_data_id;
	
	DELETE FROM issue_meter_data_source
	 WHERE issue_meter_data_source_id = v_issue_meter_data_source_id;
	
	DELETE FROM issue_supplier
	 WHERE issue_supplier_id = v_issue_supplier_id;
	 
	DELETE FROM issue_compliance_region
	 WHERE issue_compliance_region_id = v_issue_compliance_region_id;
	
	DELETE FROM issue_log_file
	 WHERE issue_log_id IN (
		SELECT issue_log_id
		  FROM issue_log
		 WHERE issue_id = in_issue_id
	 );

	DELETE FROM issue_log_read
	 WHERE issue_log_id IN (
		 SELECT issue_log_id
		   FROM issue_log
		  WHERE issue_id = in_issue_id
	 );

	DELETE FROM issue_action_log
	 WHERE issue_id = in_issue_id;

	DELETE FROM issue_log
	 WHERE issue_id = in_issue_id;
	
	DELETE FROM issue_involvement
	 WHERE issue_id = in_issue_id;
	 
	DELETE FROM issue_custom_field_str_val
	 WHERE issue_id = in_issue_id;
	 
	DELETE FROM issue_custom_field_opt_sel 
	 WHERE issue_id = in_issue_id;
	 
	DELETE FROM issue_custom_field_date_val
	 WHERE issue_id = in_issue_id;
	
	DELETE FROM issue_alert
	 WHERE issue_id = in_issue_id;
	
	INTERNAL_StatusChanged(in_issue_id, NULL);
	
	BEGIN
		DELETE FROM issue
		 WHERE issue_id = in_issue_id;
	EXCEPTION
		WHEN security_pkg.ACCESS_DENIED THEN
			-- Access denied thrown by before delete trigger on all logging forms that have issues
			-- For now, just hide the issue from views by marking it as deleted. 
			-- Also need to null out the log IDs because we've deleted them above with
			-- deferrable FKs, so the commit fails if we don't do this.
			UPDATE issue
			   SET deleted = 1,
				   first_issue_log_id = null, 
				   last_issue_log_id = null
			 WHERE issue_id = in_issue_id;
	END;
END;


PROCEDURE DeleteLogEntry(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_log_id				IN	issue_log.issue_log_id%TYPE
)
AS
    v_set_by_user_sid 	security_pkg.T_SID_ID;
    v_user_sid  		security_pkg.T_SID_ID;
    v_issue_id			issue.issue_id%TYPE;
    v_cnt				NUMBER(10);
BEGIN
    user_pkg.GetSid(in_act_id, v_user_sid);
    
    BEGIN   
	    SELECT logged_by_user_sid, issue_id
	      INTO v_set_by_user_sid, v_issue_id
	      FROM issue_log
	     WHERE issue_log_id = in_issue_log_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- Somebody got here first, don't worry about it
			RETURN;
	END;
	
    -- you can only delete your own comments
    IF v_set_by_user_sid != v_user_sid THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering comment');
    END IF;
	
    DELETE FROM issue_log_read
     WHERE issue_log_id = in_issue_log_id;
     
    DELETE FROM issue_log_file
     WHERE issue_log_id = in_issue_log_id;

    DELETE FROM issue_action_Log
     WHERE issue_log_id = in_issue_log_id;

    DELETE FROM issue_log
     WHERE issue_log_id = in_issue_log_id;
	 
	-- update last_issue_log_id to be next in the list
	UPDATE issue
	   SET last_issue_log_id = (
			SELECT MAX(issue_log_id)
			  FROM issue_log
			 WHERE issue_id = v_issue_id
		)
	 WHERE issue_id = v_issue_id
	   AND last_issue_log_id = in_issue_log_id;
	   
	-- update first_issue_log_id to be next in the list
	UPDATE issue
	   SET first_issue_log_id = (
			SELECT MIN(issue_log_id)
			  FROM issue_log
			 WHERE issue_id = v_issue_id
		)
	 WHERE issue_id = v_issue_id
	   AND first_issue_log_id = in_issue_log_id;
	    
     
    -- mark as unresolved
    UPDATE issue 
       SET resolved_by_user_sid = null,
		resolved_dtm = null, 
		closed_by_user_sid = null,
		closed_dtm = null,
		rejected_by_user_sid = null,
		rejected_dtm = null,
		correspondent_notified = 0,
		manual_completion_dtm = null,
		manual_comp_dtm_set_dtm = null
	 WHERE issue_id = v_issue_id
	   AND (resolved_by_user_sid IS NOT NULL OR closed_by_user_sid IS NOT NULL OR rejected_by_user_sid IS NOT NULL);
	 
	IF SQL%ROWCOUNT > 0 THEN
 		LogAction(csr_data_pkg.IAT_REOPENED, v_issue_id);
 		INTERNAL_StatusChanged(v_issue_id, csr_data_pkg.IAT_REOPENED);
	END IF;

	-- check if this is the last one
	SELECT COUNT(*) 
	  INTO v_cnt
	  FROM issue_Log
	 WHERE issue_id = v_issue_id;
	 
	IF v_cnt = 0 THEN
		UNSEC_DeleteIssue(v_issue_id);
	END IF;
END;

PROCEDURE MarkLogEntryAsRead(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_log_id				IN	issue_log.issue_log_id%TYPE
)
AS
    v_user_sid  security_pkg.T_SID_ID;
BEGIN    
    user_pkg.GetSid(in_act_id, v_user_sid);
    BEGIN
        INSERT INTO issue_log_read
            (issue_log_id, csr_user_sid)
        VALUES
            (in_issue_log_id, v_user_sid);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            -- ignore pk violation
            NULL;
    END;
END;

PROCEDURE ChangeRegion(
	in_issue_id					IN  issue.issue_id%TYPE,
	in_region_sid				IN	issue.region_sid%TYPE,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT SYS_REFCURSOR
)
AS
	v_is_region_editable	NUMBER;
	v_region_description	region.name%TYPE;
	v_issue_log_id			issue_log.issue_log_id%TYPE;
	v_log_files_cur			SYS_REFCURSOR;
BEGIN

	SELECT CASE WHEN it.is_region_editable = 1 AND it.create_raw = 1 AND (i.owner_user_sid = security.security_pkg.GetSID OR csr_data_pkg.SQL_CheckCapability('Issue management') = 1) THEN 1 ELSE 0 END is_region_editable
	  INTO v_is_region_editable
	  FROM csr.issue i
	  JOIN csr.issue_type it ON i.app_sid = it.app_sid AND i.issue_type_id = it.issue_type_id
	 WHERE i.app_sid = security.security_pkg.GetApp
	   AND i.issue_id = in_issue_id;
	
	IF v_is_region_editable = 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied editing region on issue with sid: '||in_issue_id);
	END IF;
	  
	UPDATE issue
	   SET last_region_sid = region_sid,
	   region_sid = in_region_sid
	 WHERE issue_id = in_issue_id;
	
	SELECT description
	  INTO v_region_description
	  FROM v$region
	 WHERE app_sid = security.security_pkg.GetApp
	   AND region_sid = in_region_sid;
	
	AddLogEntry(security.security_pkg.GetAct, in_issue_id, 1, 'Changed region to {0}', v_region_description, null, null, TRUE, v_issue_log_id);
	INTERNAL_GetIssueLogEntries(security.security_pkg.GetSID, in_issue_id, v_issue_log_id, FALSE, out_log_cur, v_log_files_cur, out_action_cur);
	LogAction(csr_data_pkg.IAT_REGION_CHANGED, in_issue_id);
	
	chain.filter_pkg.ClearCacheForAllUsers (
		in_card_group_id => chain.filter_pkg.FILTER_TYPE_ISSUES
	);
END;

/****************************/
/*  Report/overview queries */
/****************************/

PROCEDURE GetFilteredIssueCount(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_saved_filter_sid		IN	security_pkg.T_SID_ID,
	out_count				OUT	NUMBER
)
AS
	v_issue_id_list			chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_saved_filter_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on saved filter with sid: '||in_saved_filter_sid);
	END IF;
	
	IF in_region_sid IS NOT NULL THEN
		-- Start with all issues that are under the input region sid
		SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, NULL, NULL)
		  BULK COLLECT INTO v_issue_id_list
		  FROM v$issue i
		  JOIN (
			SELECT region_sid
			  FROM region
			 START WITH region_sid = in_region_sid
			CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
		  ) r ON i.region_sid = r.region_sid;
	ELSE 
		-- Start with all issue ids. This is different to lists as it doesn't factor in region_start_point.
		SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, NULL, NULL)
		  BULK COLLECT INTO v_issue_id_list
		  FROM v$issue i;
	END IF;
	
	-- Filter by all filters attached to in_saved_filter_sid
	FOR r IN (
		SELECT f.filter_id, ft.helper_pkg
		  FROM chain.saved_filter sf
		  JOIN chain.filter f ON sf.compound_filter_id = f.compound_filter_id
		  JOIN chain.filter_type ft ON f.filter_type_id = ft.filter_type_id
		 WHERE sf.saved_filter_sid = in_saved_filter_sid
	) LOOP
		EXECUTE IMMEDIATE ('BEGIN ' || r.helper_pkg || '.FilterIds(:filter_id, 0, NULL, :input, :output);END;') USING r.filter_id, v_issue_id_list, OUT v_issue_id_list;
	END LOOP;
	
	SELECT COUNT(DISTINCT object_id)
	  INTO out_count
	  FROM TABLE(v_issue_id_list);
	
END;

PROCEDURE GetIssuesByNonComplianceId(
	in_non_compliance_id	IN	non_compliance.non_compliance_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
BEGIN
	v_user_sid := security_pkg.GetSID;

	audit_pkg.CheckNonComplianceAccess(in_non_compliance_id, security_pkg.PERMISSION_READ, 'Permission denied reading the issues under non-compliance id '||in_non_compliance_id);

	OPEN out_cur FOR
		SELECT i.*, inc.non_compliance_id,
			   CASE WHEN i.assigned_to_user_sid = v_user_sid 
					OR EXISTS (
						SELECT *
						  FROM issue_involvement ii
						  LEFT JOIN region_role_member rrm
							ON ii.role_sid = rrm.role_sid
						   AND v_user_sid = rrm.user_sid
						 WHERE i.app_sid = ii.app_sid
						   AND i.issue_id = ii.issue_id
						   AND NVL(ii.user_sid, rrm.user_sid) = v_user_sid
						   AND (rrm.region_sid IS NULL OR i.region_sid = rrm.region_sid)
					)
				THEN 1 ELSE 0 END is_involved
		  FROM v$issue i, issue_non_compliance inc
		 WHERE i.app_sid = inc.app_sid
		   AND i.issue_non_compliance_id = inc.issue_non_compliance_id
		   AND inc.non_compliance_id = in_non_compliance_id;
END;

PROCEDURE GetAllIssues(
	in_skip_count			IN NUMBER,
	in_take_count			IN NUMBER,
	out_cur					OUT SYS_REFCURSOR
)
AS
	v_user_sid					security_pkg.T_SID_ID 		:= 	security_pkg.GetSID;
	v_nc_sids					security.T_SID_TABLE	 	:= 	audit_pkg.PopulatePermissibleNCs;
BEGIN

	OPEN out_cur FOR
		SELECT *
		  FROM ( SELECT issues.*, rownum rn
		  		   FROM (	SELECT i.*, inc.non_compliance_id,
			   				  CASE WHEN i.assigned_to_user_sid = v_user_sid 
									OR EXISTS (
										SELECT *
										  FROM issue_involvement ii
										  LEFT JOIN region_role_member rrm
											ON ii.role_sid = rrm.role_sid
										   AND v_user_sid = rrm.user_sid
										 WHERE i.app_sid = ii.app_sid
										   AND i.issue_id = ii.issue_id
										   AND NVL(ii.user_sid, rrm.user_sid) = v_user_sid
										   AND (rrm.region_sid IS NULL OR i.region_sid = rrm.region_sid)
									)
							   THEN 1 ELSE 0 END is_involved
		  					   FROM v$issue i, issue_non_compliance inc
							   JOIN Table(v_nc_sids) ncs
							     ON inc.non_compliance_id = ncs.column_value
		 					  WHERE i.app_sid = inc.app_sid
		   						AND i.issue_non_compliance_id = inc.issue_non_compliance_id
							  ORDER BY i.issue_id ASC) issues
		  		  WHERE rownum <= in_skip_count + in_take_count)
		 WHERE rn > in_skip_count;
END;

PROCEDURE GetIssuesByRegionSid(
	in_parent_region_sid	IN	issue.region_sid%TYPE,
	out_cur					OUT SYS_REFCURSOR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_region_sids			security.T_SID_TABLE;
	v_issue_id_list			chain.T_FILTERED_OBJECT_TABLE;
BEGIN
	v_user_sid := security_pkg.GetSID;

	IF in_parent_region_sid IS NULL THEN
		v_region_sids := NULL;
	ELSE
		v_region_sids := security.T_SID_TABLE(in_parent_region_sid);
	END IF;

	issue_report_pkg.GetInitialIds(
		in_search => NULL, 
		in_region_sids => v_region_sids, 
		in_region_col_type => issue_report_pkg.COL_TYPE_REGION_SID,
		in_id_list => NULL,
		out_id_list => v_issue_id_list
	);
	
	OPEN out_cur FOR
		SELECT i.*, inc.non_compliance_id,
			   CASE WHEN i.assigned_to_user_sid = v_user_sid 
					OR EXISTS (
						SELECT *
						  FROM issue_involvement ii
						  LEFT JOIN region_role_member rrm
							ON ii.role_sid = rrm.role_sid
						   AND v_user_sid = rrm.user_sid
						 WHERE i.app_sid = ii.app_sid
						   AND i.issue_id = ii.issue_id
						   AND NVL(ii.user_sid, rrm.user_sid) = v_user_sid
						   AND (rrm.region_sid IS NULL OR i.region_sid = rrm.region_sid)
					)
				THEN 1 ELSE 0 END is_involved
		  FROM v$issue i, issue_non_compliance inc
		 WHERE i.app_sid = inc.app_sid(+)
		   AND i.issue_non_compliance_id = inc.issue_non_compliance_id(+)
		   AND EXISTS (
				SELECT * FROM table(v_issue_id_list) t
				WHERE t.object_id = i.issue_id
		   );
END;

PROCEDURE GetIssuesByUserInvolved(
	out_cur					OUT SYS_REFCURSOR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
BEGIN
	v_user_sid := security_pkg.GetSID;
	-- no explicity security checks because it's tied to issues this user is involved with
	
	OPEN out_cur FOR
		SELECT i.*, inc.non_compliance_id,
			   1 is_involved
		  FROM v$issue i, issue_non_compliance inc
		 WHERE i.app_sid = inc.app_sid(+)
		   AND i.issue_non_compliance_id = inc.issue_non_compliance_id(+)
		   AND (
				i.assigned_to_user_sid = v_user_sid 
				OR EXISTS (
					SELECT *
					  FROM issue_involvement ii
					  LEFT JOIN region_role_member rrm
						ON ii.role_sid = rrm.role_sid
					   AND v_user_sid = rrm.user_sid
					 WHERE i.app_sid = ii.app_sid
					   AND i.issue_id = ii.issue_id
					   AND NVL(ii.user_sid, rrm.user_sid) = v_user_sid
					   AND (rrm.region_sid IS NULL OR i.region_sid = rrm.region_sid)
				)
			);
END;

PROCEDURE GetReportInactiveUsers(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT sqlreport_pkg.CheckAccess('csr.issue_pkg.GetReportInactiveUsers') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT cu.full_name, cu.user_name, cu.email, i.issue_id, i.label title, i.status,
		       lmcu.full_name line_manager, lmcu.user_name line_manager_user_name
		  FROM v$csr_user cu
		  JOIN v$issue i
		    ON cu.app_sid = i.app_sid
		   AND cu.csr_user_sid = i.assigned_to_user_sid
		  LEFT JOIN csr_user lmcu
		    ON cu.app_sid = lmcu.app_sid
		   AND cu.line_manager_sid = lmcu.csr_user_sid
		 WHERE cu.app_sid = security_pkg.GetApp
		   AND cu.active = 0
		   AND i.is_closed = 0;	
END;

PROCEDURE GetReportInactiveUsersSummary(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT sqlreport_pkg.CheckAccess('csr.issue_pkg.GetReportInactiveUsersSummary') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT MIN(cu.full_name) full_name, MIN(cu.user_name) user_name, MIN(cu.email) email, COUNT(*) open_issue_count, 
		       MIN(lmcu.full_name) line_manager, MIN(lmcu.user_name) line_manager_user_name
		  FROM v$csr_user cu
		  JOIN issue i
		    ON cu.app_sid = i.app_sid
		   AND cu.csr_user_sid = i.assigned_to_user_sid
		  LEFT JOIN csr_user lmcu
		    ON cu.app_sid = lmcu.app_sid
		   AND cu.line_manager_sid = lmcu.csr_user_sid
		 WHERE cu.app_sid = security_pkg.GetApp
		   AND cu.active = 0
		   AND i.closed_dtm IS NULL
		   AND i.deleted = 0
		 GROUP BY cu.csr_user_sid;	
END;

PROCEDURE GetReportAuditIssues(
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
	in_parent_region_sid	IN  security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
)
AS
	v_audits_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT sqlreport_pkg.CheckAccess('csr.issue_pkg.GetReportAuditIssues') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
		
	BEGIN
		v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			OPEN out_cur FOR
				SELECT null audit_id, null region, null audit_date, null audit_label, 
			           null auditor_full_name, null survey_completed_date, null open_non_compliances, null notes,
			           null non_compliance_id, null non_compliance, null details, null created_on,
			           null created_by, null non_compliance_tags, null issue_id, null status, null issue_type_label,
					   null overdue, null issue_label, null source, null raised_by, null assigned_to, null date_raised,
					   null due_date, null resolved_date, null manual_completion_dtm, null closed_date, null priority, null custom_fields
				  FROM DUAL
				 WHERE 1 = 0;
			RETURN;
	END;
	
	OPEN out_cur FOR
		SELECT a.internal_audit_sid audit_id, a.region_description region, a.audit_dtm audit_date, a.label audit_label, 
			   a.auditor_full_name, a.survey_completed survey_completed_date, a.open_non_compliances, a.full_notes notes,
			   nc.non_compliance_id, nc.label non_compliance, nc.detail details, nc.created_dtm created_on,
			   ncu.full_name created_by, tags.tags non_compliance_tags, i.issue_id,
		        CASE
					WHEN i.closed_dtm IS NOT NULL THEN 'Closed'
					WHEN i.resolved_dtm IS NOT NULL THEN 'Resolved'
					WHEN i.rejected_dtm IS NOT NULL THEN 'Rejected'
					WHEN i.issue_id IS NULL THEN NULL
					ELSE 'Ongoing'
				END status, i.issue_type_label type,
				CASE
					WHEN i.is_overdue = 1 THEN 'Overdue'
					ELSE null
				END overdue, i.label issue_label, i.source_label source, i.raised_full_name raised_by, 
				i.assigned_to_full_name assigned_to, i.raised_dtm date_raised, i.due_dtm due_date, i.is_critical,
				i.resolved_dtm resolved_date, i.manual_completion_dtm, i.closed_dtm closed_date, ip.description priority, cf.custom_fields,
				CASE
					WHEN a.survey_completed IS NOT NULL THEN 'http://'||c.host||'/csr/site/audit/viewSurvey.acds?auditsid='||a.internal_audit_sid
					ELSE null
				END survey_response
		  FROM v$audit a
		  JOIN (
				SELECT DISTINCT app_sid, region_sid
				  FROM region
				 START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') AND region_sid = in_parent_region_sid
				CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
			) r ON a.region_sid = r.region_sid AND a.app_sid = r.app_sid
		  LEFT JOIN region_role_member rrm ON a.region_sid = rrm.region_sid
		   AND a.auditor_role_sid = rrm.role_sid AND a.app_sid = rrm.app_sid AND rrm.user_sid = security_pkg.GetSid
		  LEFT JOIN non_compliance nc
		    ON a.internal_audit_sid = nc.created_in_audit_sid AND a.app_sid = nc.app_sid
		  LEFT JOIN csr_user ncu ON nc.created_by_user_sid = ncu.csr_user_sid AND nc.app_sid = ncu.app_sid
		  LEFT JOIN (
				SELECT non_compliance_id, stragg2(tg.name||': '||t.tag) tags, tgm.app_sid
				  FROM non_compliance_tag nct
				  JOIN tag_group_member tgm ON tgm.tag_id = nct.tag_id AND tgm.app_sid = nct.app_sid
				  JOIN v$tag t ON tgm.tag_id = t.tag_id AND tgm.app_sid = t.app_sid
				  JOIN v$tag_group tg ON tgm.tag_group_id = tg.tag_group_id AND tgm.app_sid = tg.app_sid
				 GROUP BY non_compliance_id, tgm.app_sid
			) tags ON tags.non_compliance_id = nc.non_compliance_id AND tags.app_sid = nc.app_sid
		  LEFT JOIN issue_non_compliance inc ON nc.non_compliance_id = inc.non_compliance_id AND nc.app_sid = inc.app_sid
		  LEFT JOIN v$issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id AND inc.app_sid = i.app_sid
		  LEFT JOIN issue_priority ip on i.issue_priority_id = ip.issue_priority_id
		  LEFT JOIN (
			SELECT issue_id, stragg2(label||': '||string_value) custom_fields, app_sid FROM (
				SELECT sv.issue_id, icf.label, sv.string_value, sv.app_sid
				  FROM issue_custom_field_str_val sv
				  JOIN issue_custom_field icf ON sv.issue_custom_field_id = icf.issue_custom_field_id AND sv.app_sid = icf.app_sid
				 UNION ALL
				SELECT * FROM (
					SELECT os.issue_id, icf.label, stragg(fo.label) string_value, icf.app_sid
					  FROM issue_custom_field_option fo
					  JOIN issue_custom_field_opt_sel os ON fo.issue_custom_field_opt_id = os.issue_custom_field_opt_id AND fo.issue_custom_field_id = os.issue_custom_field_id AND fo.app_sid = os.app_sid
					  JOIN issue_custom_field icf ON os.issue_custom_field_id = icf.issue_custom_field_id AND os.app_sid = icf.app_sid
					 GROUP BY os.issue_id, icf.label, icf.app_sid
				)
				 UNION ALL
				SELECT dv.issue_id, icf.label, TO_CHAR(dv.date_value, 'DD/MM/YYYY') string_value, icf.app_sid
				  FROM issue_custom_field_date_val dv
				  JOIN issue_custom_field icf ON dv.issue_custom_field_id = icf.issue_custom_field_id AND dv.app_sid = icf.app_sid
				) GROUP BY issue_id, app_sid
			) cf ON i.issue_id = cf.issue_id AND i.app_sid = cf.app_sid
		  JOIN customer c ON c.app_sid = a.app_sid
		 WHERE (in_start_dtm IS NULL OR a.audit_dtm >= in_start_dtm)
		   AND (in_end_dtm IS NULL OR a.audit_dtm < in_end_dtm)
		   AND a.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY a.internal_audit_sid, nc.non_compliance_id, i.issue_id;
END;

/*************************************************/
/*  Specific delegation sheet value stored procs */
/*************************************************/

PROCEDURE CreateIssueDeleg(
	in_act_id					IN  security.security_pkg.T_ACT_ID,
	in_sheet_id					IN	sheet.sheet_id%TYPE,
	in_sheet_period_fmt			IN	VARCHAR2,
	in_ind_sid					IN	security.security_pkg.T_SID_ID,
	in_region_sid				IN	security.security_pkg.T_SID_ID,
	in_label					IN  issue.label%TYPE,
	in_description				IN  issue.description%TYPE,
	in_assign_to				IN	issue.assigned_to_user_sid%TYPE,
	in_due_date					IN	issue.due_dtm%TYPE,
	in_is_urgent				IN	NUMBER,
	in_is_critical				IN	issue.is_critical%TYPE DEFAULT 0,
	out_issue_id				OUT issue.issue_id%TYPE
)
AS
    v_issue_sheet_value_id	issue_sheet_value.issue_sheet_value_id%TYPE;
	v_user_sid				security.security_pkg.T_SID_ID;
	v_source_Label			issue.source_label%TYPE;
	v_start_dtm				sheet.start_dtm%TYPE;
	v_end_dtm				sheet.end_dtm%TYPE;
	out_cur					SYS_REFCURSOR;
	v_involve_min_users		NUMBER(1);
BEGIN
	security.user_pkg.GetSid(in_act_id, v_user_sid);
	
	SELECT start_dtm, end_dtm
	  INTO v_start_dtm, v_end_dtm
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;
		
        INSERT INTO issue_sheet_value
            (issue_sheet_value_id, ind_sid, region_sid, start_dtm, end_dtm)
        VALUES
            (issue_sheet_value_id_seq.nextval, in_ind_sid, in_region_sid, v_start_dtm, v_end_dtm)
        RETURNING issue_sheet_value_id INTO v_issue_sheet_value_id;

    -- create a 'source_label'
    SELECT TruncateString(i.description,600)||' / '||TruncateString(r.description,300)||' / '||in_sheet_period_fmt
      INTO v_source_label
      FROM v$ind i, v$region r
     WHERE i.ind_sid = in_ind_sid
       AND r.region_sid = in_region_sid;
    
	CreateIssue(
		in_label				=> in_label,
		in_description			=> in_description,
		in_source_label			=> v_source_label,
		in_issue_type_id		=> csr_data_pkg.ISSUE_DATA_ENTRY,
		in_region_sid			=> in_region_sid,
		in_assigned_to_user_sid => in_assign_to,
		in_due_dtm				=> in_due_date,
		in_is_urgent			=> in_is_urgent,
		in_is_critical			=> in_is_critical,
		out_issue_id			=> out_issue_id
	);
	
    UPDATE issue
       SET issue_sheet_value_id = v_issue_sheet_value_id
     WHERE issue_id = out_issue_id;
     
	SELECT involve_min_users_in_issue
	  INTO v_involve_min_users
	  FROM issue_type
	 WHERE issue_type_id = csr_data_pkg.ISSUE_DATA_ENTRY;
	
	IF v_involve_min_users = 0 THEN
	-- link to users below this sheet -- doesn't include users where the sheet has split
		INSERT INTO issue_involvement
			(issue_id, is_an_owner, user_sid)
			SELECT issue_id, MAX(is_an_owner), user_sid
			  FROM (
				SELECT out_issue_id issue_Id, CASE WHEN LVL = 1 THEN 1 ELSE 0 END is_an_owner, du.user_sid
				  FROM (
					SELECT delegation_sid, level lvl
					  FROM delegation
					 START WITH delegation_sid = (
						SELECT delegation_sid FROM sheet WHERE sheet_id = in_sheet_id
					 )
					CONNECT BY PRIOR delegation_sid = parent_sid -- down the tree
					UNION			
					SELECT delegation_sid, level lvl
					  FROM delegation
					 START WITH delegation_sid = (
						SELECT delegation_sid FROM sheet WHERE sheet_id = in_sheet_id
					 )
					CONNECT BY PRIOR parent_sid = delegation_sid -- up the tree
				 )d, delegation_ind di, delegation_region dr, v$delegation_user du -- include roles
				 WHERE d.delegation_sid = di.delegation_sid
				   AND di.ind_sid = in_ind_sid
				   AND d.delegation_sid = dr.delegation_sid
				   AND dr.region_sid = in_region_sid
				   AND d.delegation_sid = du.delegation_sid
				   AND du.user_sid NOT IN (
						-- exclude users already in there (i.e. the user calling this most likely)
						SELECT user_sid FROM issue_involvement WHERE issue_id = out_issue_id
				   )
			)
			GROUP BY issue_id, user_sid;
	ELSE
		-- add only the user who has entered data on the sheet.
		FOR r IN (
			SELECT set_by_user_sid 
			  FROM sheet_value
			 WHERE sheet_id = in_sheet_id
			   AND set_by_user_sid NOT IN (
				-- exclude users already in there (i.e. the user calling this most likely)
				SELECT user_sid FROM issue_involvement WHERE issue_id = out_issue_id)
			GROUP BY set_by_user_sid
		) LOOP
			AddUser(in_act_id, out_issue_id, r.set_by_user_sid, out_cur);
		END LOOP;
	END IF;
END;


PROCEDURE AddIssueDeleg(
	in_act_id					IN  security.security_pkg.T_ACT_ID,
	in_sheet_id					IN	sheet.sheet_id%TYPE,
	in_sheet_period_fmt			IN	VARCHAR2,
	in_ind_sid					IN	security.security_pkg.T_SID_ID,
	in_region_sid				IN	security.security_pkg.T_SID_ID,
	in_message					IN	issue_log.message%TYPE,
	in_description				IN	issue.description%TYPE,
	in_assign_to				IN	issue.assigned_to_user_sid%TYPE,
	in_due_date					IN	issue.due_dtm%TYPE,
	in_is_urgent				IN	NUMBER,
	in_is_critical				IN	issue.is_critical%TYPE DEFAULT 0,
	out_issue_id				OUT issue.issue_id%TYPE
)
AS
	v_issue_id			issue.issue_id%TYPE;
	v_label				issue.label%TYPE;
	v_issue_log_id		issue_log.issue_log_id%TYPE;
BEGIN
	-- XXX: Restriction on LENGTHB The LENGTHB function is supported for single-byte LOBs.
	-- It cannot be used with CLOB and NCLOB data in a multibyte character set. Hence converting
	-- to char...
	IF LENGTHB(TO_CHAR(SUBSTR(in_message, 1, 256))) > 255 THEN
        v_label := TruncateString(in_message, 252) || '...';
    ELSE
        v_label := in_message;
    END IF;
    
    CreateIssueDeleg(in_act_id, in_sheet_id, in_sheet_period_fmt, in_ind_sid,
    	in_region_sid, v_label, in_description, in_assign_to, in_due_date,
		in_is_urgent, in_is_critical, out_issue_id);

	AddLogEntry(in_act_id, out_issue_id, 0, in_message, null, null, null, FALSE, v_issue_log_id);
END;


PROCEDURE GetIssuesDeleg(
	in_act_id					IN  security.security_pkg.T_ACT_ID,
	in_sheet_id					IN	sheet.sheet_id%TYPE,
	in_ind_sid					IN	security.security_pkg.T_SID_ID,
	in_region_sid				IN	security.security_pkg.T_SID_ID,
	out_cur_issue				OUT	SYS_REFCURSOR
)
AS
	v_delegation_sid		security_pkg.T_SID_ID;
BEGIN
	SELECT delegation_sid
	  INTO v_delegation_sid
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;
		
	IF NOT delegation_pkg.CheckDelegationPermission(in_act_id, v_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Permission denied reading the issues for delegation '||v_delegation_sid);
	END IF;

	OPEN out_cur_issue FOR
		SELECT issue_id, label, description, resolved_dtm, manual_completion_dtm, rejected_dtm, due_dtm,
			is_resolved, is_rejected, is_closed, assigned_to_user_sid, assigned_to_full_name,
			raised_by_user_sid, raised_full_name raised_by_full_name
		  FROM issue_sheet_value iv
		  JOIN sheet s ON iv.app_sid = s.app_sid AND iv.start_dtm < s.end_dtm AND iv.end_dtm > s.start_dtm
		  JOIN v$issue i ON iv.app_sid = i.app_sid AND iv.issue_sheet_value_id = i.issue_sheet_value_id
		 WHERE iv.ind_sid = in_ind_sid
		   AND iv.region_sid = in_region_sid -- doesn't factor in child regions - maybe it should
		   AND s.sheet_id = in_sheet_id
		 ORDER BY CASE WHEN is_resolved = 0 AND is_rejected = 0 AND is_closed = 0 THEN 1 WHEN is_resolved = 1 AND is_rejected = 0 AND is_closed = 0 THEN 2 ELSE 3 END,
			raised_dtm, manual_completion_dtm;
END;

/****************************************/
/*  Specific pending value stored procs */
/****************************************/

PROCEDURE CreateIssuePV(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_approval_step_id			IN	security_pkg.T_SID_ID,
	in_pending_ind_id			IN	pending_ind.pending_ind_id%TYPE,
	in_pending_region_id		IN	pending_region.pending_region_id%TYPE,
	in_pending_period_id		IN	pending_period.pending_period_id%TYPE,
	in_label					IN  issue.label%TYPE,
	out_issue_id				OUT issue.issue_id%TYPE
)
AS
    v_issue_pending_val_id	issue_pending_val.issue_pending_val_id%TYPE;
	v_user_sid				security_pkg.T_SID_ID;
	v_source_Label			issue.source_label%TYPE;
	v_region_sid			security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);
		
	-- only one issue per pending_val ATM
	BEGIN
        INSERT INTO issue_pending_val
            (issue_pending_val_id, pending_ind_id, pending_region_id, pending_period_id)
        VALUES
            (issue_pending_val_id_seq.nextval, in_pending_ind_id, in_pending_region_id, in_pending_period_id)
        RETURNING issue_pending_val_id INTO v_issue_pending_val_id;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            SELECT i.issue_id
              INTO out_issue_id
              FROM issue_pending_val ipv, issue i
             WHERE pending_ind_id = in_pending_ind_id
               AND pending_region_id = in_pending_region_id
               AND pending_period_id = in_pending_period_id
               AND ipv.issue_pending_val_id = i.issue_pending_val_id;
            RETURN;
    END;
    
    -- create a 'source_label'
    SELECT TruncateString(pi.description,600)||' / '||TruncateString(pr.description,300)||' / '||pp.label
      INTO v_source_label
      FROM pending_ind pi, pending_region pr, pending_period pp
     WHERE pi.pending_ind_id = in_pending_ind_id 
       AND pr.pending_region_id = in_pending_region_id
       AND pp.pending_period_id = in_pending_period_id;

	SELECT pr.maps_to_region_sid
	  INTO v_region_sid
	  FROM pending_region pr
	 WHERE pr.pending_region_id = in_pending_region_id;
	
	CreateIssue(
		in_label => in_label,
		in_source_label => v_source_Label,
		in_issue_type_id => csr_data_pkg.ISSUE_DATA_ENTRY,
		in_region_sid => v_region_sid,
		out_issue_id => out_issue_id
	);
	
    UPDATE issue
       SET issue_pending_val_id = v_issue_pending_val_id
     WHERE issue_id = out_issue_id;
    
	-- link to users below this approvalstep
	INSERT INTO issue_involvement
		(issue_id, is_an_owner, user_sid)
		SELECT out_issue_id, is_an_owner, apsu.user_sid
          FROM (
            SELECT approval_step_id, CASE WHEN LEVEL = 1 THEN 1 ELSE 0 END is_an_owner
              FROM approval_step
             START WITH approval_step_id = in_approval_step_id
            CONNECT BY PRIOR approval_step_id = parent_step_id 
         )x, APPROVAL_STEP ap, APPROVAL_STEP_IND apsi, APPROVAL_STEP_REGION apsr, APPROVAL_STEP_USER apsu, CSR_USER cu
         WHERE x.approval_step_id = ap.approval_step_id
           AND ap.approval_step_id = apsu.approval_step_id
           AND apsu.user_sid = cu.csr_user_sid
 		   AND ap.approval_Step_id = apsi.approval_step_id 
 		   AND ap.approval_Step_id = apsr.approval_step_id 
		   AND apsi.pending_ind_id = in_pending_ind_id
  		   AND apsr.pending_region_id = in_pending_region_id
  		   AND cu.csr_user_sid != v_user_sid ;
	

	-- associate the issue with the last person to enter a number who wasn't this user
/*    INSERT INTO issue_involvement
		(issue_id, user_sid, is_an_owner)
	SELECT out_issue_id, set_by_user_sid, 0 
	  FROM (
		SELECT row_number() OVER (PARTITION BY pvl.pending_val_id ORDER BY pending_val_log_id DESC) rn, set_by_user_sid
		  FROM pending_val_log pvl, pending_val pv
		 WHERE pv.pending_val_id = pvl.pending_val_id
		   AND pv.pending_ind_id = in_pending_ind_id
		   AND pv.pending_region_id = in_pending_region_id
		   AND pv.pending_period_id = in_pending_period_id
	   	   AND set_by_user_sid != v_user_sid 
	  )
	 WHERE rn = 1;
*/
END;


-- creates an issue if required and then writes an entry to the issue log
PROCEDURE LogIssuePV(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_approval_step_id			IN	approval_step.approval_step_id%TYPE,
	in_pending_ind_id			IN	pending_ind.pending_ind_id%TYPE,
	in_pending_region_id		IN	pending_region.pending_region_id%TYPE,
	in_pending_period_id		IN	pending_period.pending_period_id%TYPE,
	in_message					IN	issue_log.message%TYPE,
	out_issue_id				OUT issue.issue_id%TYPE
)
AS
	v_issue_id		issue.issue_id%TYPE;
	v_label			issue.label%TYPE;
	v_issue_log_id	issue_log.issue_log_id%TYPE;
BEGIN
	-- XXX: Restriction on LENGTHB The LENGTHB function is supported for single-byte LOBs.
	-- It cannot be used with CLOB and NCLOB data in a multibyte character set. Hence converting
	-- to char...
	IF LENGTHB(TO_CHAR(SUBSTR(in_message, 1, 256))) > 255 THEN
        v_label := TruncateString(in_message, 252) || '...';
    ELSE
        v_label := in_message;
    END IF;
    -- won't create if we have an issue already but handles locks properly
    CreateIssuePV(in_act_id, in_approval_step_id, in_pending_ind_id, 
        in_pending_region_id, in_pending_period_id, v_label, v_issue_id);

	AddLogEntry(in_act_id, v_issue_id, 0, in_message, null, null, null, FALSE, v_issue_log_id);
	out_issue_id := v_issue_id;
END;


PROCEDURE GetIssueLogPV(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_pending_ind_id			IN	pending_ind.pending_ind_id%TYPE,
	in_pending_region_id		IN	pending_region.pending_region_id%TYPE,
	in_pending_period_id		IN	pending_period.pending_period_id%TYPE,
	out_cur_issue				OUT	SYS_REFCURSOR,
	out_cur_log					OUT	SYS_REFCURSOR,
	out_cur_log_files			OUT	SYS_REFCURSOR
)
AS
	v_issue_id				issue.issue_id%TYPE;
	v_user_sid				SECURITY_PKG.T_SID_ID;
	v_pending_dataset_sid  	security_pkg.T_SID_ID;
	v_action_log_cur		SYS_REFCURSOR;
BEGIN
	BEGIN
		SELECT i.issue_id
		  INTO v_issue_id
		  FROM issue_pending_val iv, issue i
		 WHERE iv.pending_ind_id = in_pending_ind_id AND 
		 	   iv.pending_region_id = in_pending_region_id AND
		 	   iv.pending_period_id = in_pending_period_id AND 
		 	   iv.issue_pending_val_id = i.issue_pending_val_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			OPEN out_cur_issue FOR
				SELECT null issue_id, null label, null raised_dtm, null manual_completion_dtm,
					null raised_full_name, null resolved_dtm, null resolved_full_name,
					null closed_dtm, null closed_full_name
				  FROM dual
				 WHERE 1 = 0;
				 
			OPEN out_cur_log FOR
				SELECT null issue_log_id, null logged_by_user_sid, null logged_by_user_name,
				 null logged_by_full_name, null logged_by_email, null logged_dtm, null message,
				  null param_1, null param_2, null param_3, null is_system_generated, null now_dtm,
				  null is_read, null is_you
				  FROM dual
				 WHERE 1 = 0;
			
			OPEN out_cur_log_files FOR
				SELECT null filename, null mimetype, null sha1
				  FROM dual
				 WHERE 1 = 0;
			RETURN;
	END;
	
	-- not quite sure what permissions to check. Just use reporting_period for now.
	-- I guess we ought to figure out the root_approval_Step? Or pending_dataset? 
	SELECT pending_dataset_id
	  INTO v_pending_dataset_sid
	  FROM pending_ind
	 WHERE pending_ind_id = in_pending_ind_id;
		 	   
		
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_pending_dataset_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied reading the issues for pending_dataset '||v_pending_dataset_sid);
	END IF;

	user_pkg.GetSid(in_act_id, v_user_sid);
	
	INTERNAL_GetIssueLogEntries(v_user_sid, v_issue_id, NULL, FALSE, out_cur_log, out_cur_log_files, v_action_log_cur);
	
	OPEN out_cur_issue FOR
		SELECT issue_id, label, raised_dtm, raised_full_name, resolved_dtm, manual_completion_dtm, resolved_full_name, closed_dtm, closed_full_name
		  FROM v$issue i 
		 WHERE issue_id = v_issue_id;
END;

PROCEDURE GetMyOpenedIssueList(
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_user_sid			security_pkg.T_SID_ID;
	v_now				DATE := SYSDATE;
BEGIN
	v_user_sid := security_pkg.GetSID;
	-- no explicity security checks because it's tied to issues this user has opened
	
	OPEN out_cur FOR
		SELECT i.issue_id, i.label, i.source_Label, 
			i.raised_dtm, lil.logged_dtm last_issue_logged_dtm, i.resolved_dtm, i.manual_completion_dtm, i.closed_dtm, v_now now,
			i.resolved_full_name, 
			CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1 END is_resolved,
			i.closed_full_name,
			CASE WHEN i.closed_dtm IS NULL THEN 0 ELSE 1 END is_closed,
			CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1 END is_rejected,
			is_overdue,
			due_dtm,	
			assigned_to_user_sid, assigned_to_user_name, assigned_to_full_name, assigned_to_email, assigned_to_role_name,
			i.last_issue_log_id, 
			CASE WHEN i.first_issue_log_id = i.last_issue_log_id THEN NULL ELSE lil.logged_by_full_name END last_issue_log_full_name, -- if 1 log then it's the opener == no real last entry
			CASE WHEN ilr.read_dtm IS NULL AND lil.logged_by_user_sid != v_user_sid THEN 0 ELSE 1 END last_issue_log_is_read, -- check it's not us and nothing in the 'read' table
			CASE WHEN lil.logged_by_user_sid = v_user_sid THEN 1 ELSE 0 END last_is_you,
			CASE WHEN i.first_issue_log_id = i.last_issue_log_id THEN 1 ELSE 0 END is_first_issue_log, 
			lil.message last_message, lil.param_1 last_param_1, lil.param_2 last_param_2, lil.param_3 last_param_3,
			lil.is_system_generated,
			i.region_name, i.ind_sid, i.ind_name, i.start_dtm, i.end_dtm
		  FROM v$issue i
		  LEFT JOIN v$issue_log lil ON i.last_issue_log_id = lil.issue_log_id AND i.issue_id = lil.issue_id
		  LEFT JOIN issue_log_read ilr ON lil.issue_log_id = ilr.issue_log_id AND ilr.csr_user_sid = v_user_sid
		 WHERE i.raised_by_user_sid = v_user_sid
		   AND i.is_visible = 1
		 ORDER BY is_closed, last_issue_logged_dtm desc;
END;

PROCEDURE GetMyInvolvedIssueList(
	in_assigned_only	IN	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_user_sid	security_pkg.T_SID_ID;
	v_now		DATE := SYSDATE;
BEGIN
	v_user_sid := security_pkg.GetSID;
	-- no explicity security checks because it's tied to issues this user is involved with
	
	-- we can't factor these two queries out easily because of the inline view
	OPEN out_cur FOR
		SELECT i.issue_id, i.label, i.source_Label, 
			i.raised_dtm, lil.logged_dtm last_issue_logged_dtm, i.resolved_dtm, i.manual_completion_dtm, i.closed_dtm, v_now now,
			i.resolved_full_name, i.raised_full_name, i.raised_email,
			CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1 END is_resolved,
			i.closed_full_name,
			CASE WHEN i.closed_dtm IS NULL THEN 0 ELSE 1 END is_closed,
			CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1 END is_rejected,
			is_overdue,
			due_dtm,	
			assigned_to_user_sid, assigned_to_user_name, assigned_to_full_name, assigned_to_email, assigned_to_role_name,
			i.last_issue_log_id, 
			CASE WHEN i.first_issue_log_id = i.last_issue_log_id THEN NULL ELSE lil.logged_by_full_name END last_issue_log_full_name, -- if 1 log then it's the opener == no real last entry
			CASE WHEN ilr.read_dtm IS NULL AND lil.logged_by_user_sid != v_user_sid THEN 0 ELSE 1 END last_issue_log_is_read, -- check it's not us and nothing in the 'read' table
			CASE WHEN lil.logged_by_user_sid = v_user_sid THEN 1 ELSE 0 END last_is_you,
			CASE WHEN i.first_issue_log_id = i.last_issue_log_id THEN 1 ELSE 0 END is_first_issue_log, 
			lil.message last_message, lil.param_1 last_param_1, lil.param_2 last_param_2, lil.param_3 last_param_3,
			lil.is_system_generated,
			i.region_name, i.ind_sid, i.ind_name, i.start_dtm, i.end_dtm
		  FROM v$issue i
		  LEFT JOIN v$issue_log lil ON i.last_issue_log_id = lil.issue_log_id AND i.issue_id = lil.issue_id
		  LEFT JOIN issue_log_read ilr ON lil.issue_log_id = ilr.issue_log_id AND ilr.csr_user_sid = v_user_sid
		  LEFT JOIN v$issue_involved_user iiu ON i.issue_id = iiu.issue_id AND iiu.user_sid = v_user_sid
		 WHERE (
				(iiu.issue_id IS NOT NULL)
				OR
				(i.assigned_to_user_sid = v_user_sid)
				OR
				(EXISTS (SELECT NULL 
						   FROM issue_involvement ii 
						  WHERE ii.issue_id = i.issue_id
						    AND ii.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')))
			)
		   AND (
				(in_assigned_only = 1 AND assigned_to_user_sid = v_user_sid)
				OR 
				(in_assigned_only = 0) -- AND i.raised_by_user_sid != v_user_sid) -- exclude things we opened
			)
		   AND i.is_visible = 1
		 ORDER BY is_closed, last_issue_logged_dtm desc;
END;

PROCEDURE GetScheduledTasks(
	out_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- TODO: secure, but based on what? these just hang off customer...
	OPEN out_cur FOR
		SELECT ist.issue_scheduled_task_id, ist.label, ist.schedule_xml, ist.period_xml,
			   ist.assign_to_user_sid, au.full_name assign_to_full_name,
			   ist.raised_by_user_sid, ru.full_name raised_by_full_name,
			   ist.last_created, ist.due_dtm_relative, ist.due_dtm_relative_unit,
			   ist.scheduled_on_due_date, ist.issue_type_id, 
			   ist.next_run_dtm, ist.app_sid, ist.create_critical, c.host, ist.region_sid
		  FROM issue_scheduled_task ist
		  JOIN csr_user au ON ist.app_sid = au.app_sid AND ist.assign_to_user_sid = au.csr_user_sid
		  JOIN csr_user ru ON ist.app_sid = ru.app_sid AND ist.raised_by_user_sid = ru.csr_user_sid
		  JOIN csr.customer c ON ist.app_sid = c.app_sid AND au.app_sid = c.app_sid AND ru.app_sid = c.app_sid
		 WHERE issue_type_id IS NULL OR issue_type_id = csr_data_pkg.ISSUE_SCHEDULED_TASK;
END;

PROCEDURE SaveScheduledTask(
	in_issue_scheduled_task_id		IN	issue_scheduled_task.issue_scheduled_task_id%TYPE,
	in_label						IN	issue_scheduled_task.label%TYPE,
	in_schedule_xml					IN	issue_scheduled_task.schedule_xml%TYPE,
	in_period_xml					IN	issue_scheduled_task.period_xml%TYPE,
	in_raised_by_user_sid			IN	issue_scheduled_task.raised_by_user_sid%TYPE,
	in_assign_to_user_sid			IN	issue_scheduled_task.assign_to_user_sid%TYPE,
	in_next_run_dtm					IN	issue_scheduled_task.next_run_dtm%TYPE,
	in_due_dtm_relative				IN	issue_scheduled_task.due_dtm_relative%TYPE,
	in_due_dtm_relative_unit		IN	issue_scheduled_task.due_dtm_relative_unit%TYPE,
	in_scheduled_on_due_date		IN  issue_scheduled_task.scheduled_on_due_date%TYPE,
	in_parent_id					IN  NUMBER DEFAULT NULL,
	in_issue_type_id				IN  issue_type.issue_type_id%TYPE DEFAULT NULL,
	in_create_critical				IN	issue_scheduled_task.create_critical%TYPE DEFAULT 0,
	in_region_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	out_issue_scheduled_task_id		OUT	issue_scheduled_task.issue_scheduled_task_id%TYPE
)
AS
	v_helper_pkg					issue_type.helper_pkg%TYPE;
BEGIN
	-- TODO: secure, but based on what?
	IF in_issue_scheduled_task_id IS NULL THEN
		INSERT INTO issue_scheduled_task (
			issue_scheduled_task_id, label, schedule_xml, period_xml, raised_by_user_sid,
			assign_to_user_sid, next_run_dtm, due_dtm_relative, due_dtm_relative_unit, 
			scheduled_on_due_date, issue_type_id, create_critical, region_sid)
		VALUES (
			issue_scheduled_task_id_seq.NEXTVAL, in_label, in_schedule_xml, in_period_xml,
			in_raised_by_user_sid, in_assign_to_user_sid, in_next_run_dtm,
			in_due_dtm_relative, in_due_dtm_relative_unit, 
			in_scheduled_on_due_date, in_issue_type_id, in_create_critical, in_region_sid)
		RETURNING issue_scheduled_task_id INTO out_issue_scheduled_task_id;
	ELSE
		UPDATE issue_scheduled_task
		   SET label 					= in_label,
		  	   schedule_xml 			= in_schedule_xml,
		  	   period_xml				= in_period_xml,
		  	   raised_by_user_sid		= in_raised_by_user_sid,
		  	   assign_to_user_sid 		= in_assign_to_user_sid,
		  	   next_run_dtm 			= in_next_run_dtm, -- the app has to work this out
		  	   due_dtm_relative			= in_due_dtm_relative,
		  	   due_dtm_relative_unit	= in_due_dtm_relative_unit,
			   scheduled_on_due_date	= in_scheduled_on_due_date,
			   issue_type_id			= in_issue_type_id,
			   create_critical			= in_create_critical,
			   region_sid				= in_region_sid
		 WHERE issue_scheduled_task_id 	= in_issue_scheduled_task_id;
		out_issue_scheduled_task_id    := in_issue_scheduled_task_id;
	END IF;

	IF in_issue_type_id IS NOT NULL THEN
		BEGIN
			SELECT helper_pkg
			  INTO v_helper_pkg
			  FROM issue_type
			 WHERE issue_type_id = in_issue_type_id;
		EXCEPTION
			WHEN no_data_found THEN
				NULL;
		END;

		IF v_helper_pkg IS NOT NULL THEN
			BEGIN
				EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.OnScheduledTaskCreated(:1, :2);end;'
					USING out_issue_scheduled_task_id, in_parent_id;
			EXCEPTION
				WHEN PROC_NOT_FOUND THEN
					NULL; -- it is acceptable that it is not supported
			END;
		END IF;
	END IF;
END;

PROCEDURE DeleteScheduledTask(
	in_issue_scheduled_task_id		IN	issue_scheduled_task.issue_scheduled_task_id%TYPE
)
AS
	v_helper_pkg					issue_type.helper_pkg%TYPE;
BEGIN
	-- TODO: secure, but based on what?
	BEGIN
		SELECT it.helper_pkg
		  INTO v_helper_pkg
		  FROM issue_type it
		  JOIN issue_scheduled_task ist ON it.issue_type_id = ist.issue_type_id
		 WHERE ist.issue_scheduled_task_id = in_issue_scheduled_task_id;
	EXCEPTION
		WHEN no_data_found THEN
			NULL;
	END;

	IF v_helper_pkg IS NOT NULL THEN
		BEGIN
			EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.OnScheduledTaskDeleted(:1);end;'
				USING in_issue_scheduled_task_id;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
	
	UPDATE issue_scheduled_task 
	   SET copied_from_id = NULL 
	 WHERE copied_from_id = in_issue_scheduled_task_id;

	DELETE FROM issue_scheduled_task
	 WHERE issue_scheduled_task_id = in_issue_scheduled_task_id;
END;

PROCEDURE GetIssuesByAction(
	in_task_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_task_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied reading task sid ' || in_task_sid);
	END IF;

	OPEN out_cur FOR
		SELECT i.issue_id, i.label, i.resolved_dtm, manual_completion_dtm,
			   CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1 END is_resolved,
			   CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1 END is_rejected
		  FROM issue i, issue_action ia
		 WHERE i.app_sid = ia.app_sid
		   AND i.issue_action_id = ia.issue_action_id
		   AND ia.task_sid = in_task_sid
		   AND i.deleted = 0;
END;

PROCEDURE GetIssuesByMeter(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied reading region sid ' || in_region_sid);
	END IF;

	OPEN out_cur FOR
		SELECT i.issue_id, i.label, i.resolved_dtm, manual_completion_dtm, im.issue_dtm,
			   CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1 END is_resolved,
			   CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1 END is_rejected
		  FROM issue i, issue_meter im
		 WHERE i.app_sid = im.app_sid
		   AND i.issue_meter_id = im.issue_meter_id
		   AND im.region_sid = in_region_sid
		   AND i.deleted = 0;
END;

PROCEDURE GetIssuesByMeterAlarm(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied reading region sid ' || in_region_sid);
	END IF;

	OPEN out_cur FOR
		SELECT i.issue_id, i.label, i.resolved_dtm, i.manual_completion_dtm, ima.meter_alarm_id, ima.issue_dtm,
			   CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1 END is_resolved,
			   CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1 END is_rejected
		  FROM issue i, issue_meter_alarm ima
		 WHERE i.app_sid = ima.app_sid
		   AND i.issue_meter_alarm_id = ima.issue_meter_alarm_id
		   AND ima.region_sid = in_region_sid;
END;

PROCEDURE GetIssuesByMeterRawData(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied reading region sid ' || in_region_sid);
	END IF;
	
	-- Hmm, a raw data file typically spans several days, put the issue dtm in the middle of the period
	OPEN out_cur FOR
		SELECT i.issue_id, i.label, i.resolved_dtm, i.manual_completion_dtm,
		ird.issue_meter_raw_data_id, ird.region_sid, mrd.start_dtm + (mrd.end_dtm - mrd.start_dtm) / 2 issue_dtm,
			   CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1 END is_resolved,
			   CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1 END is_rejected
		  FROM issue i, issue_meter_raw_data ird, meter_raw_data mrd
		 WHERE i.app_sid = ird.app_sid
		   AND i.issue_meter_raw_data_id = ird.issue_meter_raw_data_id
		   AND ird.region_sid = in_region_sid
		   AND mrd.meter_raw_data_id = ird.meter_raw_data_id
		   AND i.deleted = 0;
END;

PROCEDURE GetIssueAlertSummaryApps(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	t_app_sids						security.T_SID_TABLE;
BEGIN
	t_app_sids := alert_pkg.GetAppSidsForAlert(csr_data_pkg.ALERT_ISSUE_SUMMARY);

	alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_ISSUE_SUMMARY);

	OPEN out_cur FOR
		SELECT DISTINCT il.app_sid
		  FROM issue_log il
		  JOIN issue i ON il.app_sid = i.app_sid AND il.issue_id = i.issue_id
		  LEFT JOIN v$issue_user iiu ON il.app_sid = iiu.app_sid AND il.issue_id = iiu.issue_id 
		  JOIN csr_user cu ON 
				(cu.app_sid = iiu.app_sid AND cu.csr_user_sid = iiu.user_sid) OR
				(cu.app_sid = i.app_sid AND cu.csr_user_sid = i.assigned_to_user_sid)
		  LEFT JOIN issue_log_read ilr ON ilr.app_sid = il.app_sid AND ilr.issue_log_id = il.issue_log_id AND ilr.app_sid = cu.app_sid AND ilr.csr_user_sid = cu.csr_user_sid
		  JOIN temp_alert_batch_run tabr ON cu.app_sid = tabr.app_sid AND cu.csr_user_sid = tabr.csr_user_sid 
		   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_SUMMARY
		 WHERE il.app_sid IN (SELECT /*+CARDINALITY(100)*/ column_value FROM TABLE (t_app_sids))
		   AND (tabr.prev_fire_time_gmt IS NULL OR il.logged_dtm >= tabr.prev_fire_time_gmt)
		   AND ilr.issue_log_id IS NULL;
END;

PROCEDURE GetIssueAlertSummary(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	t_app_sids						security.T_SID_TABLE;
	v_alert_batch_issues			T_ALERT_BATCH_ISSUES_TABLE;
BEGIN
	IF SYS_CONTEXT('SECURITY', 'APP') IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'GetIssueAlertSummary cannot be run already logged on as an application');
	END IF;

	t_app_sids := alert_pkg.GetAppSidsForAlert(csr_data_pkg.ALERT_ISSUE_SUMMARY);

	alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_ISSUE_SUMMARY);

	INSERT INTO temp_alert_batch_issues (app_sid, issue_log_id, csr_user_sid, friendly_name, full_name, email)
		SELECT /*+ALL_ROWS CARDINALITY(tabr, 50000)*/ il.app_sid, il.issue_log_id, cu.csr_user_sid, 
			   cu.friendly_name, cu.full_name, cu.email
		  FROM issue_log il
		  JOIN issue i ON il.app_sid = i.app_sid AND il.issue_id = i.issue_id
		  LEFT JOIN v$issue_user iiu ON il.app_sid = iiu.app_sid AND il.issue_id = iiu.issue_id 
		  JOIN csr_user cu ON 
				(cu.app_sid = iiu.app_sid AND cu.csr_user_sid = iiu.user_sid) OR
				(cu.app_sid = i.app_sid AND cu.csr_user_sid = i.assigned_to_user_sid)
		  LEFT JOIN issue_log_read ilr 
		    ON ilr.app_sid = il.app_sid AND ilr.issue_log_id = il.issue_log_id 
		   AND ilr.app_sid = cu.app_sid AND ilr.csr_user_sid = cu.csr_user_sid
		  JOIN temp_alert_batch_run tabr ON cu.app_sid = tabr.app_sid AND cu.csr_user_sid = tabr.csr_user_sid 
		   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_SUMMARY
		  JOIN issue_type it ON i.app_sid = it.app_sid AND i.issue_type_id = it.issue_type_id
		  JOIN security.user_table ut ON ut.sid_id = cu.csr_user_sid
		WHERE (tabr.prev_fire_time_gmt IS NULL OR il.logged_dtm >= tabr.prev_fire_time_gmt) -- get stuff logged after our last run
		  AND il.logged_dtm <= tabr.this_fire_time_gmt -- and before this run started
		  AND ilr.issue_log_id IS NULL
		  AND i.deleted = 0 -- don't send summaries on deleted issues
		  AND il.logged_by_user_sid != cu.csr_user_sid
		  AND (it.email_involved_roles = 1 OR NVL(iiu.from_role, 0) = 0)
		  AND (it.email_involved_users = 1 OR iiu.from_role = 1)
		  AND cu.send_alerts = 1
		  AND ut.account_enabled = 1
		  AND cu.email IS NOT NULL
		  AND cu.csr_user_sid != security.security_pkg.SID_BUILTIN_ADMINISTRATOR
		  AND il.app_sid IN (SELECT /*+CARDINALITY(100)*/ column_value FROM TABLE (t_app_sids))
		GROUP BY il.app_sid, il.issue_log_id, cu.csr_user_sid, cu.friendly_name, cu.full_name, cu.email;

	SELECT T_ALERT_BATCH_ISSUES(tabi.app_sid, tabi.issue_log_id, tabi.csr_user_sid, tabi.friendly_name, tabi.full_name, tabi.email)
	  BULK COLLECT INTO v_alert_batch_issues
	  FROM temp_alert_batch_issues tabi
	 WHERE tabi.app_sid IN (SELECT /*+CARDINALITY(100)*/ column_value FROM TABLE (t_app_sids));

	OPEN out_cur FOR
		WITH issues AS (
	  		SELECT /*+ALL_ROWS*/ 
	  			   tabi.app_sid, tabi.csr_user_sid, tabi.friendly_name, tabi.full_name, tabi.email, i.label,
				   i.issue_id, il.issue_log_id, il.logged_dtm, il.message, i.source_url,
				   il.logged_by_user_sid, il.logged_by_user_name, il.logged_by_full_name, il.logged_by_email, 
				   i.source_label, i.issue_pending_val_id, i.issue_sheet_value_id, 
				   i.issue_non_compliance_id, nc.label non_compliance_label, i.issue_action_id, 
				   i.issue_meter_id, i.issue_meter_alarm_id, i.issue_meter_raw_data_id, i.issue_compliance_region_id,
			       i.issue_meter_data_source_id, i.issue_supplier_id, il.param_1, il.param_2, il.param_3, il.is_system_generated, 
				   it.label issue_type_label, i.issue_type_id, il.is_user logged_by_is_user, GetIssueUrl(i.issue_id) issue_url,
                   r.region_sid, r.description region_description, i.issue_ref, i.guid,
				   i.raised_dtm, i.due_dtm, au.full_name assigned_to, au.csr_user_sid assigned_to_user_sid, i.is_critical, 
					CASE
						WHEN i.closed_dtm IS NOT NULL THEN 'Closed'
						WHEN i.resolved_dtm IS NOT NULL THEN 'Resolved'
						WHEN i.rejected_dtm IS NOT NULL THEN 'Rejected'
						ELSE 'Ongoing'
					END issue_status, ip.due_date_offset priority_due_date_offset, ip.description priority_description
			  FROM issue i
			  JOIN v$issue_log il ON il.app_sid = i.app_sid AND il.issue_id = i.issue_id
			  JOIN TABLE(v_alert_batch_issues) tabi ON il.app_sid = tabi.app_sid AND il.issue_log_id = tabi.issue_log_id
			  JOIN issue_type it ON it.app_sid = i.app_sid AND it.issue_type_id = i.issue_type_id
			  LEFT JOIN issue_non_compliance inc ON inc.app_sid = i.app_sid AND inc.issue_non_compliance_id = i.issue_non_compliance_id
			  LEFT JOIN non_compliance nc ON nc.app_sid = i.app_sid AND nc.non_compliance_id = inc.non_compliance_id
              LEFT JOIN v$region r ON r.app_sid = i.app_sid AND r.region_sid = i.region_sid
			  LEFT JOIN csr_user au ON au.app_sid = i.app_sid AND au.csr_user_sid = i.assigned_to_user_sid
			  LEFT JOIN csr.issue_priority ip ON i.app_sid = ip.app_sid AND i.issue_priority_id = ip.issue_priority_id
		)
		SELECT *
		  FROM (
				-- DELEGATIONS
				SELECT i.*, 
					   c.editing_url || sheet_pkg.GetSheetQueryString(isv.app_sid, isv.ind_sid, isv.region_sid, isv.start_dtm, isv.end_dtm, i.csr_user_sid)
					   || '#indSid='||isv.ind_Sid||',regionSid='||isv.region_sid url, null url_label,
					    c.editing_url || sheet_pkg.GetSheetQueryString(isv.app_sid, isv.ind_sid, isv.region_sid, isv.start_dtm, isv.end_dtm, i.csr_user_sid)
					   || '#indSid='||isv.ind_Sid||',regionSid='||isv.region_sid parent_url, 'View sheet' parent_url_label,
					   null pending_val_id
				  FROM issues i, customer c, issue_sheet_value isv
				 WHERE i.app_sid = c.app_sid
				   AND i.app_sid = isv.app_sid AND i.issue_sheet_value_id = isv.issue_sheet_value_id
				 UNION ALL
				-- Audit non-compliances
				SELECT i.*,
					   audit_pkg.GetIssueAuditUrl(nc.created_in_audit_sid) url, 'View audit' url_label,
					   audit_pkg.GetIssueAuditUrl(nc.created_in_audit_sid) parent_url, 'View audit' parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_non_compliance inc, non_compliance nc, Audit_Non_Compliance anc, Internal_Audit ia
				 WHERE i.app_sid = inc.app_sid 
				   AND i.issue_non_compliance_id = inc.issue_non_compliance_id
				   AND Anc.Non_Compliance_Id = inc.non_compliance_id 
				   AND Ia.Internal_Audit_Sid = Anc.Internal_Audit_Sid
				   AND inc.non_compliance_id = nc.non_compliance_id
				   AND Ia.Deleted = 0
				UNION ALL
				-- ACTIONS
				SELECT i.*,
					   null url, null url_label,
					   null parent_url, null parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_action ia
				 WHERE i.app_sid = ia.app_sid AND i.issue_action_id = ia.issue_action_id
				UNION ALL
				-- METER
				SELECT i.*,
					   meter_pkg.GetIssueMeterUrl(im.issue_meter_id) url, 'View meter data' url_label,
					   meter_pkg.GetIssueMeterUrl(im.issue_meter_id) parent_url, 'View meter data' parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_meter im
				 WHERE i.app_sid = im.app_sid AND i.issue_meter_id = im.issue_meter_id
				UNION ALL
				-- METER ALARM
				SELECT i.*,
					   meter_alarm_pkg.GetAlarmUrl(ima.issue_meter_alarm_id) url, 'View meter data' url_label,
					   meter_alarm_pkg.GetAlarmUrl(ima.issue_meter_alarm_id) parent_url, 'View meter data' parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_meter_alarm ima
				 WHERE i.app_sid = ima.app_sid AND i.issue_meter_alarm_id = ima.issue_meter_alarm_id
				UNION ALL
				-- METER RAW DATA
				SELECT i.*,
					   meter_monitor_pkg.GetRawDataUrl(rd.issue_meter_raw_data_id) url, 'View raw data' url_label,
					   meter_monitor_pkg.GetRawDataUrl(rd.issue_meter_raw_data_id) parent_url, 'View raw data' parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_meter_raw_data rd
				 WHERE i.app_sid = rd.app_sid AND i.issue_meter_raw_data_id = rd.issue_meter_raw_data_id
				UNION ALL 
				-- METER DATA SOURCE
				SELECT i.*,
					   meter_monitor_pkg.GetDataSourceUrl(ds.issue_meter_data_source_id) url, 'View data source' url_label,
					   meter_monitor_pkg.GetDataSourceUrl(ds.issue_meter_data_source_id) parent_url, 'View data source' parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_meter_data_source ds
				 WHERE i.app_sid = ds.app_sid AND i.issue_meter_data_source_id = ds.issue_meter_data_source_id
		 		 UNION ALL
				-- Supplier
				SELECT i.*,
					   '/csr/site/chain/manageCompany/manageCompany.acds?companySid='||isup.company_sid url, 'View supplier' url_label,
					   '/csr/site/chain/manageCompany/manageCompany.acds?companySid='||isup.company_sid parent_url, 'View supplier' parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_supplier isup
				 WHERE i.app_sid = isup.app_sid AND i.issue_supplier_id = isup.issue_supplier_id
				   AND i.issue_type_id = csr_data_pkg.ISSUE_SUPPLIER
				 UNION ALL
				-- COMPLIANCE
				SELECT i.*,
					  compliance_pkg.GetComplianceItemUrl(icr.flow_item_id) url, 'View compliance item' url_label,
					  compliance_pkg.GetComplianceItemUrl(icr.flow_item_id) parent_url, 'View compliance item' parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_compliance_region icr
				 WHERE i.app_sid = icr.app_sid AND i.issue_compliance_region_id = icr.issue_compliance_region_id
				 UNION ALL
				-- SCHEDULED TASK + CMS ISSUE
				SELECT i.*,
					   i.source_url url, CASE WHEN i.source_url IS NULL THEN NULL ELSE 'View form' END url_label,
					   i.source_url parent_url, CASE WHEN i.source_url IS NULL THEN NULL ELSE 'View form' END parent_url_label,
					   null pending_val_id
				  FROM issues i
				 WHERE i.issue_type_id IN (csr_data_pkg.ISSUE_SCHEDULED_TASK, csr_data_pkg.ISSUE_CMS)
				 UNION ALL
				-- BASIC ISSUE, ISSUE_ENQUIRY
				SELECT i.*,
					   null url, null url_label,
					   null parent_url, null parent_url_label,
					   null pending_val_id
				  FROM issues i
				 WHERE i.issue_type_id IN (csr_data_pkg.ISSUE_BASIC, csr_data_pkg.ISSUE_ENQUIRY)
				 UNION ALL
				-- CUSTOMER ISSUE TYPES
				SELECT i.*,
					   i.source_url url, null url_label,
					   i.source_url parent_url, null parent_url_label,
					   null pending_val_id
				  FROM issues i
				 WHERE i.issue_type_id >= 10000
				)
		 ORDER BY app_sid, csr_user_sid, issue_id, label, logged_dtm;
END;

PROCEDURE GetIssueAlertSummaryLoggedOn(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_alert_batch_issues			T_ALERT_BATCH_ISSUES_TABLE;
BEGIN
	INSERT INTO temp_alert_batch_issues (app_sid, issue_log_id, csr_user_sid, friendly_name, full_name, email)
		SELECT /*+ALL_ROWS CARDINALITY(tabr, 50000)*/ il.app_sid, il.issue_log_id, cu.csr_user_sid, 
			   cu.friendly_name, cu.full_name, cu.email
		  FROM issue_log il
		  JOIN issue i ON il.app_sid = i.app_sid AND il.issue_id = i.issue_id
		  LEFT JOIN v$issue_user iiu ON il.app_sid = iiu.app_sid AND il.issue_id = iiu.issue_id 
		  JOIN csr_user cu ON 
				(cu.app_sid = iiu.app_sid AND cu.csr_user_sid = iiu.user_sid) OR
				(cu.app_sid = i.app_sid AND cu.csr_user_sid = i.assigned_to_user_sid)
		  LEFT JOIN issue_log_read ilr 
		    ON ilr.app_sid = il.app_sid AND ilr.issue_log_id = il.issue_log_id 
		   AND ilr.app_sid = cu.app_sid AND ilr.csr_user_sid = cu.csr_user_sid
		  JOIN temp_alert_batch_run tabr ON cu.app_sid = tabr.app_sid AND cu.csr_user_sid = tabr.csr_user_sid 
		   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_SUMMARY
		  JOIN issue_type it ON i.app_sid = it.app_sid AND i.issue_type_id = it.issue_type_id
		  JOIN security.user_table ut ON ut.sid_id = cu.csr_user_sid
		WHERE (tabr.prev_fire_time_gmt IS NULL OR il.logged_dtm >= tabr.prev_fire_time_gmt) -- get stuff logged after our last run
		  AND il.logged_dtm <= tabr.this_fire_time_gmt -- and before this run started
		  AND ilr.issue_log_id IS NULL
		  AND i.deleted = 0 -- don't send summaries on deleted issues
		  AND il.logged_by_user_sid != cu.csr_user_sid
		  AND (it.email_involved_roles = 1 OR NVL(iiu.from_role, 0) = 0)
		  AND (it.email_involved_users = 1 OR iiu.from_role = 1)
		  AND cu.send_alerts = 1
		  AND ut.account_enabled = 1
		  AND cu.email IS NOT NULL
		  AND cu.csr_user_sid != security.security_pkg.SID_BUILTIN_ADMINISTRATOR
		  AND il.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		GROUP BY il.app_sid, il.issue_log_id, cu.csr_user_sid, cu.friendly_name, cu.full_name, cu.email;

	SELECT T_ALERT_BATCH_ISSUES(tabi.app_sid, tabi.issue_log_id, tabi.csr_user_sid, tabi.friendly_name, tabi.full_name, tabi.email)
	  BULK COLLECT INTO v_alert_batch_issues
	  FROM temp_alert_batch_issues tabi;

	OPEN out_cur FOR
		WITH issues AS (
	  		SELECT /*+ALL_ROWS*/ 
	  			   tabi.app_sid, tabi.csr_user_sid, tabi.friendly_name, tabi.full_name, tabi.email, i.label,
				   i.issue_id, il.issue_log_id, il.logged_dtm, il.message, i.source_url,
				   il.logged_by_user_sid, il.logged_by_user_name, il.logged_by_full_name, il.logged_by_email, 
				   i.source_label, i.issue_pending_val_id, i.issue_sheet_value_id, 
				   i.issue_non_compliance_id, nc.label non_compliance_label, i.issue_action_id, 
				   i.issue_meter_id, i.issue_meter_alarm_id, i.issue_meter_raw_data_id, i.issue_compliance_region_id,
			       i.issue_meter_data_source_id, i.issue_supplier_id, il.param_1, il.param_2, il.param_3, il.is_system_generated, 
				   it.label issue_type_label, i.issue_type_id, il.is_user logged_by_is_user, GetIssueUrl(i.issue_id) issue_url,
                   r.region_sid, r.description region_description, i.issue_ref, i.guid,
				   i.raised_dtm, i.due_dtm, au.full_name assigned_to, au.csr_user_sid assigned_to_user_sid, i.is_critical, 
					CASE
						WHEN i.closed_dtm IS NOT NULL THEN 'Closed'
						WHEN i.resolved_dtm IS NOT NULL THEN 'Resolved'
						WHEN i.rejected_dtm IS NOT NULL THEN 'Rejected'
						ELSE 'Ongoing'
					END issue_status, ip.due_date_offset priority_due_date_offset, ip.description priority_description
			  FROM issue i
			  JOIN v$issue_log il ON il.app_sid = i.app_sid AND il.issue_id = i.issue_id
			  JOIN TABLE(v_alert_batch_issues) tabi ON il.app_sid = tabi.app_sid AND il.issue_log_id = tabi.issue_log_id
			  JOIN issue_type it ON it.app_sid = i.app_sid AND it.issue_type_id = i.issue_type_id
			  LEFT JOIN issue_non_compliance inc ON inc.app_sid = i.app_sid AND inc.issue_non_compliance_id = i.issue_non_compliance_id
			  LEFT JOIN non_compliance nc ON nc.app_sid = i.app_sid AND nc.non_compliance_id = inc.non_compliance_id
              LEFT JOIN v$region r ON r.app_sid = i.app_sid AND r.region_sid = i.region_sid
			  LEFT JOIN csr_user au ON au.app_sid = i.app_sid AND au.csr_user_sid = i.assigned_to_user_sid
			  LEFT JOIN csr.issue_priority ip ON i.app_sid = ip.app_sid AND i.issue_priority_id = ip.issue_priority_id
		)
		SELECT *
		  FROM (
				-- DELEGATIONS
				SELECT i.*, 
					   c.editing_url || sheet_pkg.GetSheetQueryString(isv.app_sid, isv.ind_sid, isv.region_sid, isv.start_dtm, isv.end_dtm, i.csr_user_sid)
					   || '#indSid='||isv.ind_Sid||',regionSid='||isv.region_sid url, null url_label,
					    c.editing_url || sheet_pkg.GetSheetQueryString(isv.app_sid, isv.ind_sid, isv.region_sid, isv.start_dtm, isv.end_dtm, i.csr_user_sid)
					   || '#indSid='||isv.ind_Sid||',regionSid='||isv.region_sid parent_url, 'View sheet' parent_url_label,
					   null pending_val_id
				  FROM issues i, customer c, issue_sheet_value isv
				 WHERE i.app_sid = c.app_sid
				   AND i.app_sid = isv.app_sid AND i.issue_sheet_value_id = isv.issue_sheet_value_id
				   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 UNION ALL
				-- Audit non-compliances
				SELECT i.*,
					   audit_pkg.GetIssueAuditUrl(nc.created_in_audit_sid) url, 'View audit' url_label,
					   audit_pkg.GetIssueAuditUrl(nc.created_in_audit_sid) parent_url, 'View audit' parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_non_compliance inc, non_compliance nc, Audit_Non_Compliance anc, Internal_Audit ia
				 WHERE i.app_sid = inc.app_sid 
				   AND i.issue_non_compliance_id = inc.issue_non_compliance_id
				   AND Anc.Non_Compliance_Id = inc.non_compliance_id 
				   AND ia.Internal_Audit_Sid = Anc.Internal_Audit_Sid
				   AND inc.non_compliance_id = nc.non_compliance_id
				   AND ia.Deleted = 0
				   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				UNION ALL
				-- ACTIONS
				SELECT i.*,
					   null url, null url_label,
					   null parent_url, null parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_action ia
				 WHERE i.app_sid = ia.app_sid AND i.issue_action_id = ia.issue_action_id
				   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				UNION ALL
				-- METER
				SELECT i.*,
					   meter_pkg.GetIssueMeterUrl(im.issue_meter_id) url, 'View meter data' url_label,
					   meter_pkg.GetIssueMeterUrl(im.issue_meter_id) parent_url, 'View meter data' parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_meter im
				 WHERE i.app_sid = im.app_sid AND i.issue_meter_id = im.issue_meter_id
				   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				UNION ALL
				-- METER ALARM
				SELECT i.*,
					   meter_alarm_pkg.GetAlarmUrl(ima.issue_meter_alarm_id) url, 'View meter data' url_label,
					   meter_alarm_pkg.GetAlarmUrl(ima.issue_meter_alarm_id) parent_url, 'View meter data' parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_meter_alarm ima
				 WHERE i.app_sid = ima.app_sid AND i.issue_meter_alarm_id = ima.issue_meter_alarm_id
				   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				UNION ALL
				-- METER RAW DATA
				SELECT i.*,
					   meter_monitor_pkg.GetRawDataUrl(rd.issue_meter_raw_data_id) url, 'View raw data' url_label,
					   meter_monitor_pkg.GetRawDataUrl(rd.issue_meter_raw_data_id) parent_url, 'View raw data' parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_meter_raw_data rd
				 WHERE i.app_sid = rd.app_sid AND i.issue_meter_raw_data_id = rd.issue_meter_raw_data_id
				   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				UNION ALL 
				-- METER DATA SOURCE
				SELECT i.*,
					   meter_monitor_pkg.GetDataSourceUrl(ds.issue_meter_data_source_id) url, 'View data source' url_label,
					   meter_monitor_pkg.GetDataSourceUrl(ds.issue_meter_data_source_id) parent_url, 'View data source' parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_meter_data_source ds
				 WHERE i.app_sid = ds.app_sid AND i.issue_meter_data_source_id = ds.issue_meter_data_source_id
				   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 		 UNION ALL
				-- Supplier
				SELECT i.*,
					   '/csr/site/chain/manageCompany/manageCompany.acds?companySid='||isup.company_sid url, 'View supplier' url_label,
					   '/csr/site/chain/manageCompany/manageCompany.acds?companySid='||isup.company_sid parent_url, 'View supplier' parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_supplier isup
				 WHERE i.app_sid = isup.app_sid AND i.issue_supplier_id = isup.issue_supplier_id
				   AND i.issue_type_id = csr_data_pkg.ISSUE_SUPPLIER
				   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 UNION ALL
				-- COMPLIANCE
				SELECT i.*,
					  compliance_pkg.GetComplianceItemUrl(icr.flow_item_id) url, 'View compliance item' url_label,
					  compliance_pkg.GetComplianceItemUrl(icr.flow_item_id) parent_url, 'View compliance item' parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_compliance_region icr
				 WHERE i.app_sid = icr.app_sid AND i.issue_compliance_region_id = icr.issue_compliance_region_id
				   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 UNION ALL
				-- SCHEDULED TASK + CMS ISSUE
				SELECT i.*,
					   i.source_url url, CASE WHEN i.source_url IS NULL THEN NULL ELSE 'View form' END url_label,
					   i.source_url parent_url, CASE WHEN i.source_url IS NULL THEN NULL ELSE 'View form' END parent_url_label,
					   null pending_val_id
				  FROM issues i
				 WHERE i.issue_type_id IN (csr_data_pkg.ISSUE_SCHEDULED_TASK, csr_data_pkg.ISSUE_CMS)
				   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 UNION ALL
				-- BASIC ISSUE, ISSUE_ENQUIRY
				SELECT i.*,
					   null url, null url_label,
					   null parent_url, null parent_url_label,
					   null pending_val_id
				  FROM issues i
				 WHERE i.issue_type_id IN (csr_data_pkg.ISSUE_BASIC, csr_data_pkg.ISSUE_ENQUIRY)
				   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 UNION ALL
				-- CUSTOMER ISSUE TYPES
				SELECT i.*,
					   i.source_url url, null url_label,
					   i.source_url parent_url, null parent_url_label,
					   null pending_val_id
				  FROM issues i
				 WHERE i.issue_type_id >= 10000
				   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				)
		 ORDER BY csr_user_sid, issue_id, label, logged_dtm;
END;

PROCEDURE GetIssuesComingDue(
	in_days_backward				IN	NUMBER,
	in_days_forward					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN 

	OPEN out_cur FOR
		WITH issues AS (
	  		SELECT DISTINCT /*+ALL_ROWS*/ -- Distinct as user may be assigned to plus involved via different roles
	  			   i.app_sid, cu.csr_user_sid, cu.friendly_name, cu.full_name, cu.email, i.label,
				   i.issue_id, i.source_label, i.issue_pending_val_id, i.issue_sheet_value_id, i.source_url,
				   i.issue_non_compliance_id, i.issue_action_id, i.issue_meter_id, i.issue_meter_alarm_id,
				   i.issue_meter_raw_data_id, i.issue_meter_data_source_id, i.issue_supplier_id,
				   i.issue_compliance_region_id,
				   it.label issue_type_label, i.issue_type_id, i.due_dtm, GetIssueUrl(i.issue_id) issue_url
			  FROM issue i
			  JOIN issue_type it ON it.app_sid = i.app_sid AND it.issue_type_id = i.issue_type_id
			  LEFT JOIN region_role_member rrm ON rrm.app_sid = i.app_sid AND rrm.region_sid = i.region_sid AND rrm.role_sid = i.assigned_to_role_sid
			  LEFT JOIN v$issue_involved_user iiu ON i.app_sid = iiu.app_sid AND i.issue_id = iiu.issue_id 
			  JOIN csr_user cu ON 
					(cu.app_sid = rrm.app_sid AND cu.csr_user_sid = rrm.user_sid) OR
					(cu.app_sid = iiu.app_sid AND cu.csr_user_sid = iiu.user_sid) OR
					(cu.app_sid = i.app_sid AND cu.csr_user_sid = i.assigned_to_user_sid)
			 WHERE i.due_dtm > SYSDATE - in_days_backward
			   AND i.due_dtm < SYSDATE + in_days_forward
			   AND i.closed_dtm IS NULL
			   AND i.deleted = 0
			   AND (it.email_involved_roles = 1 OR iiu.from_role = 0)
			   AND (it.email_involved_users = 1 OR iiu.from_role = 1)
		)
		SELECT *
		  FROM (
				-- DELEGATIONS
				SELECT i.*, 
					   c.editing_url || sheet_pkg.GetSheetQueryString(isv.app_sid, isv.ind_sid, isv.region_sid, isv.start_dtm, isv.end_dtm, i.csr_user_sid)
					   || '#indSid='||isv.ind_Sid||',regionSid='||isv.region_sid url, null url_label,
					   c.editing_url || sheet_pkg.GetSheetQueryString(isv.app_sid, isv.ind_sid, isv.region_sid, isv.start_dtm, isv.end_dtm, i.csr_user_sid)
					   || '#indSid='||isv.ind_Sid||',regionSid='||isv.region_sid parent_url, 'View sheet' parent_url_label,
					   null pending_val_id
				  FROM issues i, customer c, issue_sheet_value isv
				 WHERE i.app_sid = c.app_sid
				   AND i.app_sid = isv.app_sid AND i.issue_sheet_value_id = isv.issue_sheet_value_id
				 UNION ALL
				-- Audit non-compliances
				SELECT i.*,
					   audit_pkg.GetIssueAuditUrl(nc.created_in_audit_sid) url, 'View audit' url_label,
					   audit_pkg.GetIssueAuditUrl(nc.created_in_audit_sid) parent_url, 'View audit' parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_non_compliance inc, non_compliance nc
				 WHERE i.app_sid = inc.app_sid AND i.issue_non_compliance_id = inc.issue_non_compliance_id
				   AND inc.non_compliance_id = nc.non_compliance_id
				UNION ALL
				-- ACTIONS
				SELECT i.*,
					   null url, null url_label,
					   null parent_url, null parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_action ia
				 WHERE i.app_sid = ia.app_sid AND i.issue_action_id = ia.issue_action_id
				UNION ALL
				-- METER
				SELECT i.*,
					   meter_pkg.GetIssueMeterUrl(im.issue_meter_id) url, 'View meter data' url_label,
					   meter_pkg.GetIssueMeterUrl(im.issue_meter_id) parent_url, 'View meter data' parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_meter im
				 WHERE i.app_sid = im.app_sid AND i.issue_meter_id = im.issue_meter_id
				UNION ALL
				-- METER ALARM
				SELECT i.*,
					   meter_alarm_pkg.GetAlarmUrl(ima.issue_meter_alarm_id) url, 'View meter data' url_label,
					   meter_alarm_pkg.GetAlarmUrl(ima.issue_meter_alarm_id) parent_url, 'View meter data' parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_meter_alarm ima
				 WHERE i.app_sid = ima.app_sid AND i.issue_meter_alarm_id = ima.issue_meter_alarm_id
				UNION ALL
				-- METER RAW DATA
				SELECT i.*,
					   meter_monitor_pkg.GetRawDataUrl(rd.issue_meter_raw_data_id) url, 'View raw data' url_label,
					   meter_monitor_pkg.GetRawDataUrl(rd.issue_meter_raw_data_id) parent_url, 'View raw data' parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_meter_raw_data rd
				 WHERE i.app_sid = rd.app_sid AND i.issue_meter_raw_data_id = rd.issue_meter_raw_data_id
				UNION ALL
				-- METER DATA SOURCE
				SELECT i.*,
					   meter_monitor_pkg.GetDataSourceUrl(ds.issue_meter_data_source_id) url, 'View data source' url_label,
					   meter_monitor_pkg.GetDataSourceUrl(ds.issue_meter_data_source_id) parent_url, 'View data source' parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_meter_data_source ds
				 WHERE i.app_sid = ds.app_sid AND i.issue_meter_data_source_id = ds.issue_meter_data_source_id
		 		 UNION ALL
				-- Supplier
				SELECT i.*,
					   '/csr/site/chain/manageCompany/manageCompany.acds?companySid='||isup.company_sid url, 'View supplier' url_label,
					   '/csr/site/chain/manageCompany/manageCompany.acds?companySid='||isup.company_sid parent_url, 'View supplier' parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_supplier isup
				 WHERE i.app_sid = isup.app_sid AND i.issue_supplier_id = isup.issue_supplier_id
				   AND i.issue_type_id = csr_data_pkg.ISSUE_SUPPLIER
		 		 UNION ALL
				-- COMPLIANCE
				SELECT i.*,
					  compliance_pkg.GetComplianceItemUrl(icr.flow_item_id) url, 'View compliance item' url_label,
					  compliance_pkg.GetComplianceItemUrl(icr.flow_item_id) parent_url, 'View compliance item' parent_url_label,
					   null pending_val_id
				  FROM issues i, issue_compliance_region icr
				 WHERE i.app_sid = icr.app_sid AND i.issue_compliance_region_id = icr.issue_compliance_region_id
				 UNION ALL
				-- SCHEDULED TASK + CMS ISSUE
				SELECT i.*,
					   i.source_url url, 'View form' url_label,
					   i.source_url parent_url, 'View form' parent_url_label,
					   null pending_val_id
				  FROM issues i
				 WHERE i.issue_type_id IN (csr_data_pkg.ISSUE_SCHEDULED_TASK, csr_data_pkg.ISSUE_CMS)
				 UNION ALL
				-- BASIC ISSUE, ISSUE_ENQUIRY
				SELECT i.*,
					   null url, null url_label,
					   null parent_url, null parent_url_label,
					   null pending_val_id
				  FROM issues i
				 WHERE i.issue_type_id IN (csr_data_pkg.ISSUE_BASIC, csr_data_pkg.ISSUE_ENQUIRY)
				)
		 ORDER BY app_sid, csr_user_sid, due_dtm, issue_id;
END;

PROCEDURE GetTasksToRun(
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT c.host, ist.app_sid, ist.issue_scheduled_task_id, ist.label,
			   ist.raised_by_user_sid, ist.assign_to_user_sid,
			   ist.schedule_xml, ist.period_xml, ist.next_run_dtm,
			   ist.due_dtm_relative, ist.due_dtm_relative_unit,
			   ist.scheduled_on_due_date, ist.issue_type_id, ist.create_critical,
			   ist.region_sid
		  FROM issue_scheduled_task ist
		  JOIN customer c ON ist.app_sid = c.app_sid
		  LEFT JOIN region r on ist.region_sid = r.region_sid
		 WHERE ist.next_run_dtm < SYSDATE
		   AND ((r.active = 1 AND ist.region_sid IS NOT NULL)
		    OR ist.region_sid IS NULL)
		 ORDER BY ist.app_sid
		   FOR UPDATE;
END;

PROCEDURE SetNextRunDtm(
	in_issue_scheduled_task_id		IN	issue_scheduled_task.issue_scheduled_task_id%TYPE,
	in_next_run_dtm					IN	issue_scheduled_task.next_run_dtm%TYPE
)
AS
BEGIN
	UPDATE issue_scheduled_task
	   SET next_run_dtm = in_next_run_dtm
	 WHERE issue_scheduled_task_id = in_issue_scheduled_task_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE CreateTaskIssue(
	in_issue_scheduled_task_id		IN  issue_scheduled_task.issue_scheduled_task_id%TYPE,
	in_issue_type_id				IN  issue.issue_type_id%TYPE DEFAULT NULL,
	in_label						IN	issue.label%TYPE,
	in_raised_by_user_sid			IN	issue.raised_by_user_sid%TYPE,
	in_assign_to_user_sid			IN	security_pkg.T_SID_ID,
	in_due_dtm						IN	issue.due_dtm%TYPE,
	in_is_critical					IN	issue.is_critical%TYPE DEFAULT 0,
	in_region_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	out_issue_id					OUT issue.issue_id%TYPE
)
AS
	v_helper_pkg					issue_type.helper_pkg%TYPE;
BEGIN
	CreateIssue(
		in_label				=> in_label,
		in_source_label			=> 'Scheduled task',
		in_issue_type_id		=> NVL(in_issue_type_id, csr_data_pkg.ISSUE_SCHEDULED_TASK),
		in_raised_by_user_sid	=> in_raised_by_user_sid,
		in_assigned_to_user_sid => in_assign_to_user_sid,
		in_due_dtm				=> in_due_dtm,
		in_is_critical			=> in_is_critical,
		in_region_sid			=> in_region_sid,
		out_issue_id			=> out_issue_id
	);
	
	UPDATE issue_scheduled_task
	   SET last_created = SYSDATE
	 WHERE issue_scheduled_task_id = in_issue_scheduled_task_id;
	
	IF in_issue_type_id IS NOT NULL THEN
		BEGIN
			SELECT helper_pkg
			  INTO v_helper_pkg
			  FROM issue_type
			 WHERE issue_type_id = in_issue_type_id;
		EXCEPTION
			WHEN no_data_found THEN
				NULL;
		END;

		IF v_helper_pkg IS NOT NULL THEN
			BEGIN
				EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.OnScheduledIssueCreated(:1, :2);end;'
					USING in_issue_scheduled_task_id, out_issue_id;
			EXCEPTION
				WHEN PROC_NOT_FOUND THEN
					NULL; -- it is acceptable that it is not supported
			END;
		END IF;
	END IF;
END;
	
PROCEDURE GetAlertDetails (
	in_issue_id						IN  issue.issue_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT 	NVL(it.alert_mail_address, c.alert_mail_address) alert_mail_address, 
				NVL(it.alert_mail_name, c.alert_mail_name) alert_mail_name
		  FROM issue i, issue_type it, customer c
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND c.app_sid = it.app_sid
		   AND c.app_sid = i.app_sid
		   AND i.issue_type_id = it.issue_type_id
		   AND i.issue_id = in_issue_id;
END;

FUNCTION CanChangeCustomFields
RETURN BOOLEAN
AS
BEGIN
	-- TODO Permissions
	RETURN csr_data_pkg.CheckCapability('System management') OR csr_data_pkg.CheckCapability('Issue type management');
END;

PROCEDURE SaveCustomField (
	in_field_id					IN	issue_custom_field.issue_custom_field_id%TYPE,
	in_issue_type_id			IN	issue_custom_field.issue_type_id%TYPE,
	in_field_type				IN	issue_custom_field.field_type%TYPE,
	in_label					IN	issue_custom_field.label%TYPE,
	in_pos						IN	issue_custom_field.pos%TYPE,
	in_is_mandatory				IN	issue_custom_field.is_mandatory%TYPE,
	in_restrict_to_group_sid	IN	issue_custom_field.restrict_to_group_sid%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_field_id					issue_custom_field.issue_custom_field_id%TYPE := in_field_id;
BEGIN
	IF NOT CanChangeCustomFields THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on Custom Field');
	END IF;

	IF in_field_id IS NULL THEN
		INSERT INTO issue_custom_field (issue_custom_field_id, issue_type_id, field_type, label, is_mandatory, restrict_to_group_sid)
		VALUES (issue_custom_field_id_seq.NEXTVAL, in_issue_type_id, in_field_type, in_label, in_is_mandatory, in_restrict_to_group_sid)
		RETURNING issue_custom_field_id INTO v_field_id;
	ELSE
		-- TODO: Field type changes
		UPDATE issue_custom_field
		   SET label = in_label,
			   issue_type_id = in_issue_type_id,
			   field_type = in_field_type,
			   is_mandatory = in_is_mandatory,
			   restrict_to_group_sid = in_restrict_to_group_sid
		 WHERE issue_custom_field_id = in_field_id;
	END IF;

	UpdateCustomFieldPosition(v_field_id, in_issue_type_id, in_pos);

	OPEN out_cur FOR
		SELECT icf.issue_custom_field_id, icf.issue_type_id, icf.field_type, icf.label, 
			   icf.pos, it.label || ' ' || icf.pos sort_data, icf.restrict_to_group_sid
		  FROM issue_custom_field icf
		  JOIN issue_type it
		    ON icf.issue_type_id = it.issue_type_id
		 WHERE icf.issue_custom_field_id = v_field_id;
END;

PROCEDURE UpdateCustomFieldPosition (
	in_field_id					IN	issue_custom_field.issue_custom_field_id%TYPE,
	in_issue_type_id			IN	issue_custom_field.issue_type_id%TYPE,
	in_pos						IN	issue_custom_field.pos%TYPE
)
AS
	v_conflicting_field_id		issue_custom_field.issue_custom_field_id%TYPE;
BEGIN
	BEGIN
		SELECT issue_custom_field_id
		  INTO v_conflicting_field_id
		  FROM issue_custom_field
		 WHERE issue_type_id = in_issue_type_id
		   AND pos = in_pos
		   AND app_sid = security_pkg.GetApp;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	   
	IF v_conflicting_field_id IS NOT NULL THEN
		-- move conflicting field out of the way
		UpdateCustomFieldPosition(v_conflicting_field_id, in_issue_type_id, in_pos + 1);
	END IF;
	
	UPDATE issue_custom_field
	   SET pos = in_pos
	 WHERE issue_custom_field_id = in_field_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE DeleteCustomField (
	in_field_id					IN	issue_custom_field.issue_custom_field_id%TYPE
)
AS
BEGIN
	IF NOT CanChangeCustomFields THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on Custom Field');
	END IF;
	
	DELETE FROM issue_custom_field
	 WHERE issue_custom_field_id = in_field_id;
END;

PROCEDURE GetCustomFields (
	in_issue_type_id			IN	issue_custom_field.issue_type_id%TYPE,
	in_only_creatable			IN	NUMBER,
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_permissible_cust_fields	security.T_SID_TABLE;
BEGIN
	v_permissible_cust_fields := GetPermissibleCustomFields(in_issue_type_id);

	-- No restriction on who can see custom fields
	OPEN out_cur FOR
		SELECT icf.issue_custom_field_id, icf.issue_type_id, icf.field_type, icf.label, 
			   icf.pos, it.label || ' ' || icf.pos sort_data, icf.is_mandatory
		  FROM issue_custom_field icf
		  JOIN TABLE(v_permissible_cust_fields) pcf ON icf.issue_custom_field_id = pcf.column_value
		  JOIN issue_type it
		    ON icf.issue_type_id = it.issue_type_id
		 WHERE (in_issue_type_id IS NULL OR it.issue_type_id = in_issue_type_id)
		   AND (in_issue_type_id IS NOT NULL OR (it.create_raw = 1 AND it.deleted = 0) OR in_only_creatable = 0)
		 ORDER BY sort_data;
END;

PROCEDURE GetCustomFieldsForIssues (
	in_issue_type_id				IN	issue_type.issue_type_id%TYPE DEFAULT NULL,
	out_custom_fields				OUT	SYS_REFCURSOR,
	out_custom_field_options		OUT	SYS_REFCURSOR
)
AS
	v_permissible_cust_fields	security.T_SID_TABLE;
BEGIN
	v_permissible_cust_fields := GetPermissibleCustomFields(in_issue_type_id);

	OPEN out_custom_fields FOR
		SELECT icf.issue_custom_field_id, icf.issue_type_id, icf.field_type, icf.label, icf.pos, icf.is_mandatory, icf.restrict_to_group_sid
		  FROM issue_custom_field icf
		  JOIN TABLE(v_permissible_cust_fields) pcf ON icf.issue_custom_field_id = pcf.column_value
		 WHERE icf.issue_type_id = NVL(in_issue_type_id, icf.issue_type_id)
	  ORDER BY pos ASC;

	OPEN out_custom_field_options FOR
		SELECT icfo.issue_custom_field_id,icfo.issue_custom_field_opt_id,icfo.label
		  FROM issue_custom_field_option icfo
		  JOIN issue_custom_field icf ON icf.issue_custom_field_id = icfo.issue_custom_field_id
		  JOIN TABLE(v_permissible_cust_fields) pcf ON icf.issue_custom_field_id = pcf.column_value
		 WHERE icf.issue_type_id = NVL(in_issue_type_id, icf.issue_type_id)
		 ORDER BY LOWER(icfo.label);
END;

PROCEDURE SaveCustomFieldOption (
	in_option_id				IN	issue_custom_field_option.issue_custom_field_opt_id%TYPE,
	in_field_id					IN	issue_custom_field_option.issue_custom_field_id%TYPE,
	in_label					IN	issue_custom_field_option.label%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_option_id					issue_custom_field_option.issue_custom_field_opt_id%TYPE := in_option_id;
BEGIN
	IF NOT CanChangeCustomFields THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on Custom Field');
	END IF;

	IF in_option_id IS NULL THEN
		SELECT NVL(MAX(issue_custom_field_opt_id),0) + 1
		  INTO v_option_id
		  FROM issue_custom_field_option
		 WHERE issue_custom_field_id = in_field_id;

		INSERT INTO issue_custom_field_option (issue_custom_field_opt_id, issue_custom_field_id, label)
		VALUES (v_option_id, in_field_id, in_label);
	ELSE
		UPDATE issue_custom_field_option
		   SET label = in_label
		 WHERE issue_custom_field_id = in_field_id
		   AND issue_custom_field_opt_id = in_option_id;
	END IF;

	OPEN out_cur FOR
		SELECT issue_custom_field_opt_id, issue_custom_field_id, label
		  FROM issue_custom_field_option
		 WHERE issue_custom_field_id = in_field_id
		   AND issue_custom_field_opt_id = v_option_id;
END;

PROCEDURE DeleteCustomFieldOption (
	in_option_id				IN	issue_custom_field_option.issue_custom_field_opt_id%TYPE,
	in_field_id					IN	issue_custom_field_option.issue_custom_field_id%TYPE
)
AS
BEGIN
	IF NOT CanChangeCustomFields THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on Custom Field');
	END IF;
	
	DELETE FROM issue_custom_field_option
	 WHERE issue_custom_field_id = in_field_id
	   AND issue_custom_field_opt_id = in_option_id;
END;

PROCEDURE GetCustomFieldOptions (
	in_field_id					IN	issue_custom_field_option.issue_custom_field_id%TYPE,
	in_only_creatable			IN  NUMBER,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- No restriction on who can see custom fields (doesn't reveal user values)
	OPEN out_cur FOR
		SELECT o.issue_custom_field_opt_id, o.issue_custom_field_id, o.label
		  FROM issue_custom_field_option o, issue_custom_field f, issue_type it
		 WHERE o.issue_custom_field_id = NVL(in_field_id, o.issue_custom_field_id)
		   AND o.issue_custom_field_id = f.issue_custom_field_id
		   AND f.issue_type_id = it.issue_type_id
		   AND (in_field_id IS NOT NULL OR it.create_raw = 1 OR in_only_creatable = 0)
		 ORDER BY LOWER(o.label);
END;

PROCEDURE SetCustomFieldTextVal (
	in_issue_id					IN	issue.issue_id%TYPE,
	in_field_id					IN	issue_custom_field.issue_custom_field_id%TYPE,
	in_str_val					IN	issue_custom_field_str_val.string_value%TYPE
)
AS
	v_field_type				issue_custom_field.field_type%TYPE;
	v_field_mandatory 			issue_custom_field.is_mandatory%TYPE;
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(security_pkg.GetAct, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied writing the issue with id '||in_issue_id);
	END IF;

	IF LENGTH(in_str_val) > 255 THEN
		RAISE_APPLICATION_ERROR(-20001, 'The string is too long, it must be less than 256 characters in length');
		RETURN;
	END IF;
	
	SELECT	IS_MANDATORY
	INTO	v_field_mandatory
	FROM	issue_custom_field icf
	WHERE	icf.issue_custom_field_id = in_field_id;

	IF in_str_val IS NULL AND v_field_mandatory = 1 THEN
		RAISE_APPLICATION_ERROR(-20001,'Field is mandatory - value cannot be blank.');
		RETURN;
	END IF;
	
	SELECT field_type
	  INTO v_field_type
	  FROM issue_custom_field
	 WHERE issue_custom_field_id = in_field_id;
	
	IF v_field_type != 'T' THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot set a string value to a non-Text field');
	END IF;
	
	IF in_str_val IS NULL THEN
		DELETE FROM issue_custom_field_str_val
		 WHERE issue_id = in_issue_id
		   AND issue_custom_field_id = in_field_id;
	ELSE
		BEGIN
			INSERT INTO issue_custom_field_str_val (issue_id, issue_custom_field_id, string_value)
			VALUES (in_issue_id, in_field_id, in_str_val);
		EXCEPTION
			WHEN dup_val_on_index THEN
				UPDATE issue_custom_field_str_val
				   SET string_value = in_str_val
				 WHERE issue_id = in_issue_id
				   AND issue_custom_field_id = in_field_id;
		END;
	END IF;
END;

PROCEDURE SetCustomFieldOptionSel (
	in_issue_id					IN	issue.issue_id%TYPE,
	in_field_id					IN	issue_custom_field.issue_custom_field_id%TYPE,
	in_opt_sel					IN	issue_custom_field_opt_sel.issue_custom_field_opt_id%TYPE
)
AS
	v_field_type				issue_custom_field.field_type%TYPE;
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(security_pkg.GetAct, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied writing the issue with id '||in_issue_id);
	END IF;

	SELECT field_type
	  INTO v_field_type
	  FROM issue_custom_field
	 WHERE issue_custom_field_id = in_field_id;

	IF v_field_type != 'O' AND v_field_type != 'M' THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot set an option selection to a non-Option field');
	END IF;

	DELETE FROM issue_custom_field_opt_sel
	 WHERE issue_id = in_issue_id
	   AND issue_custom_field_id = in_field_id;

	IF in_opt_sel IS NOT NULL THEN
		INSERT INTO issue_custom_field_opt_sel (issue_id, issue_custom_field_id, issue_custom_field_opt_id)
		VALUES (in_issue_id, in_field_id, in_opt_sel);
	END IF;
END;

PROCEDURE RemoveCustomFieldOptionSel (
	in_issue_id					IN	issue.issue_id%TYPE,
	in_field_id					IN	issue_custom_field.issue_custom_field_id%TYPE,
	in_opt_sel					IN	issue_custom_field_opt_sel.issue_custom_field_opt_id%TYPE
)
AS
	v_field_type				issue_custom_field.field_type%TYPE;
	v_is_last_option			NUMBER(2,0);
	v_field_mandatory 			issue_custom_field.is_mandatory%TYPE;
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(security_pkg.GetAct, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied writing the issue with id '||in_issue_id);
	END IF;
	
	SELECT	COUNT(*)
	  INTO	v_is_last_option
	  FROM	issue_custom_field_opt_sel
	 WHERE	issue_custom_field_id = in_field_id
	   AND	issue_id = in_issue_id;
	
	SELECT field_type
	  INTO v_field_type
	  FROM issue_custom_field
	 WHERE issue_custom_field_id = in_field_id;
	
	SELECT	IS_MANDATORY
	INTO	v_field_mandatory
	FROM	issue_custom_field icf
	WHERE	icf.issue_custom_field_id = in_field_id;
	
	IF v_is_last_option = 1 AND v_field_mandatory = 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot remove the last value from an option field which is mandatory.');
	END IF;
	
	IF v_field_type != 'O' AND v_field_type != 'M' THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot remove an option selection from a non-options field');
	END IF;
	
	DELETE FROM issue_custom_field_opt_sel
	 WHERE issue_id = in_issue_id
	   AND issue_custom_field_id = in_field_id
	   AND issue_custom_field_opt_id = in_opt_sel;
END;

PROCEDURE SetCustomFieldDateVal (
	in_issue_id					IN	issue.issue_id%TYPE,
	in_field_id					IN	issue_custom_field.issue_custom_field_id%TYPE,
	in_date_val					IN	issue_custom_field_date_val.date_value%TYPE
)
AS
	v_field_type				issue_custom_field.field_type%TYPE;
	v_field_mandatory 			issue_custom_field.is_mandatory%TYPE;
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(security_pkg.GetAct, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied writing the issue with id '||in_issue_id);
	END IF;
	
	SELECT	IS_MANDATORY
	INTO	v_field_mandatory
	FROM	issue_custom_field icf
	WHERE	icf.issue_custom_field_id = in_field_id;

	IF in_date_val IS NULL AND v_field_mandatory = 1 THEN
		RAISE_APPLICATION_ERROR(-20001,'Field is mandatory - value cannot be blank.');
		RETURN;
	END IF;
	
	SELECT field_type
	  INTO v_field_type
	  FROM issue_custom_field
	 WHERE issue_custom_field_id = in_field_id;
	
	IF v_field_type != 'D' THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot set a date value to a non-date field');
	END IF;
	
	IF in_date_val IS NULL THEN
		DELETE FROM issue_custom_field_date_val
		 WHERE issue_id = in_issue_id
		   AND issue_custom_field_id = in_field_id;
	ELSE
		BEGIN
			INSERT INTO issue_custom_field_date_val (issue_id, issue_custom_field_id, date_value)
			VALUES (in_issue_id, in_field_id, in_date_val);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE issue_custom_field_date_val
				   SET date_value = in_date_val
				 WHERE issue_id = in_issue_id
				   AND issue_custom_field_id = in_field_id;
		END;
	END IF;
END;

PROCEDURE AddCustomFieldOptionSel (
	in_issue_id					IN	issue.issue_id%TYPE,
	in_field_id					IN	issue_custom_field.issue_custom_field_id%TYPE,
	in_opt_sel					IN	issue_custom_field_opt_sel.issue_custom_field_opt_id%TYPE
)
AS
	v_field_type				issue_custom_field.field_type%TYPE;
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(security_pkg.GetAct, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied writing the issue with id '||in_issue_id);
	END IF;
	
	SELECT field_type
	  INTO v_field_type
	  FROM issue_custom_field
	 WHERE issue_custom_field_id = in_field_id;
	
	IF v_field_type != 'M' THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot set an option selection to a non-Option field');
	END IF;
	
	BEGIN
		INSERT INTO issue_custom_field_opt_sel (issue_id, issue_custom_field_id, issue_custom_field_opt_id)
		VALUES (in_issue_id, in_field_id, in_opt_sel);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE AddChildIssue (
	in_parent_issue_id			IN  issue.parent_id%TYPE,
	in_child_issue_id			IN  issue.issue_id%TYPE
)
AS
	v_issue_type_id 			issue.issue_type_id%TYPE;
	v_issue_sheet_value_id 		issue.issue_sheet_value_id%TYPE;
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(security_pkg.GetAct, in_child_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied writing the issue with id '||in_child_issue_id);
	END IF;
	
	UPDATE issue
	   SET parent_id = in_parent_issue_id
	 WHERE issue_id = in_child_issue_id
	   AND app_sid = security_pkg.GetApp;

	SELECT issue_type_id
	  INTO v_issue_type_id
	  FROM issue
	 WHERE issue_id = in_child_issue_id;

	IF v_issue_type_id = csr.csr_data_pkg.ISSUE_DATA_ENTRY THEN
		BEGIN
			SELECT issue_sheet_value_id
			  INTO v_issue_sheet_value_id
			  FROM issue
			 WHERE issue_id = in_parent_issue_id
			   AND issue_type_id = csr.csr_data_pkg.ISSUE_DATA_ENTRY;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
	
		IF v_issue_sheet_value_id IS NOT NULL THEN
			UPDATE issue
			   SET issue_sheet_value_id = v_issue_sheet_value_id
			 WHERE issue_id = in_child_issue_id;
		END IF;
	END IF;
END;

PROCEDURE RemoveChildIssue (
	in_parent_issue_id			IN  issue.parent_id%TYPE,
	in_child_issue_id			IN  issue.issue_id%TYPE
)
AS
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(security_pkg.GetAct, in_child_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied writing the issue with id '||in_child_issue_id);
	END IF;
	
	UPDATE issue
	   SET parent_id = null
	 WHERE issue_id = in_child_issue_id
	   AND parent_id = in_parent_issue_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE AutoCloseResolvedIssues
AS
	v_out_cur					SYS_REFCURSOR;
	v_app_sid					security.security_pkg.T_SID_ID := 0;
	v_user_sid					security_pkg.T_SID_ID;
BEGIN
	IF NOT security.security_pkg.IsAdmin(security.security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must be logged in as an administrator to run this task.');
	END IF;
	
	IF SYS_CONTEXT('SECURITY', 'APP') IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'AutoCloseResolvedIssues cannot be run already logged on as an application');
	END IF;

	-- Select resolved but not closed issues where the resolved date plus the auto
	-- close days for the issue type is before the current date.
	FOR r IN (
		SELECT i.issue_id, i.app_sid, i.resolved_dtm, i.manual_completion_dtm, it.auto_close_after_resolve_days
		  FROM issue i
		  JOIN issue_type it
			ON i.issue_type_id = it.issue_type_id
		   AND i.app_sid = it.app_sid
		 WHERE i.resolved_dtm IS NOT NULL
		   AND i.closed_dtm IS NULL
		   AND it.auto_close_after_resolve_days IS NOT NULL
		   AND NVL(i.manual_completion_dtm, i.resolved_dtm) + it.auto_close_after_resolve_days < SYSDATE
		   AND i.allow_auto_close = 1
		   AND i.deleted = 0
		   ORDER BY i.app_sid
	) LOOP
		IF v_app_sid <> r.app_sid THEN
			v_app_sid := r.app_sid;
			security.security_pkg.SetApp(r.app_sid);
		END IF;
		
		MarkAsClosed(
			in_act_id					=> security_pkg.GetAct,
			in_issue_id					=> r.issue_id,
			in_message					=> 'Resolved issue automatically closed',
			in_manual_completion_dtm	=> null,
			in_manual_comp_dtm_set_dtm	=> null,
			out_log_cur					=> v_out_cur,
			out_action_cur				=> v_out_cur
		);
		
		user_pkg.GetSid(security_pkg.GetAct, v_user_sid);
		
		RemoveUser(security_pkg.GetAct, r.issue_id, v_user_sid);
		
		--the MarkAsClosed proc also marks as read all previous messages - now marking this last message as read too
		INSERT INTO issue_log_read
			(issue_log_id, csr_user_sid)
			SELECT il.issue_log_id, v_user_sid
			  FROM issue_log il
			  LEFT JOIN issue_log_read ilr ON il.app_sid = ilr.app_sid AND il.issue_log_id = ilr.issue_log_id AND ilr.csr_user_sid = v_user_sid
			 WHERE il.issue_id = r.issue_id
			   AND il.app_sid = r.app_sid
			   AND ilr.issue_log_id IS NULL;
	END LOOP;
	
	-- this proc is run for all apps so don't leave app context "hanging on"
	security.security_pkg.SetApp(NULL);
END;

PROCEDURE EscalateOverdueIssues
AS
	v_out_cur					SYS_REFCURSOR;
	v_app_sid					security.security_pkg.T_SID_ID := 0;
	v_issue_was_escalated		BOOLEAN := FALSE;
	v_issue_log_id				issue_log.issue_log_id%TYPE;
BEGIN
	IF NOT security.security_pkg.IsAdmin(security.security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must be logged in as an administrator to run this task.');
	END IF;
	
	IF SYS_CONTEXT('SECURITY', 'APP') IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'EscalateOverdueIssues cannot be run already logged on as an application');
	END IF;

	-- select overdue issues for customers that have issue escalation enabled, 
	-- and have not yet been escalated
	FOR r IN (
		SELECT i.app_sid, i.issue_id, i.assigned_to_user_sid
		  FROM v$issue i
		  JOIN customer c
		    ON i.app_sid = c.app_sid
		 WHERE c.issue_escalation_enabled = 1
		   AND i.is_overdue = 1
		   AND i.issue_escalated = 0
		   ORDER BY i.app_sid
	) LOOP
		IF v_app_sid <> r.app_sid THEN
			v_app_sid := r.app_sid;
			security.security_pkg.SetApp(r.app_sid);
		END IF;
		
		v_issue_was_escalated := FALSE;
		
		-- involve users line manager, and their manager
		-- we are just escalating two levels atm, but could make this configurable
		-- if other clients require different depth
		FOR lm IN (
			SELECT csr_user_sid
			  FROM csr.csr_user
			 WHERE app_sid = r.app_sid
			   AND level BETWEEN 2 AND 3 
			  CONNECT BY PRIOR app_sid = app_sid AND PRIOR line_manager_sid = csr_user_sid
			 START WITH csr_user_sid = r.assigned_to_user_sid
		) LOOP
			AddUser(security.security_pkg.GetACT, r.issue_id, lm.csr_user_sid, v_out_cur);
			
			v_issue_was_escalated := TRUE;
		END LOOP;
		
		IF v_issue_was_escalated THEN
			UPDATE issue
			   SET issue_escalated = 1
			 WHERE issue_id = r.issue_id
			   AND app_sid = r.app_sid;
			   
			AddLogEntry(security.security_pkg.GetACT, r.issue_id, 1, 'Overdue issue automatically escalated', NULL, NULL, NULL, FALSE, v_issue_log_id);
			LogAction(csr_data_pkg.IAT_ESCALATED, r.issue_id, v_issue_log_id);
		END IF;
	END LOOP;
	
	-- this proc is run for all apps so don't leave app context "hanging on"
	security.security_pkg.SetApp(NULL);
END;

FUNCTION GetEnquiryMailbox(
	in_mailbox_name					IN	VARCHAR2
)
RETURN NUMBER
AS
	v_email	VARCHAR2(255);
BEGIN
	BEGIN
		SELECT alert_mail_address 
		  INTO v_email
		  FROM issue_type
		 WHERE issue_type_id = csr_Data_pkg.ISSUE_ENQUIRY
		   AND app_sid = security_pkg.GetApp;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'No enquiry issue mailbox configured');
	END;
	
	IF v_email IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'No enquiry issue mailbox configured');
	END IF;
	 
	RETURN mail.mail_pkg.getMailboxSIDFromPath(NULL, v_email||'/'||in_mailbox_name);
END;
	
PROCEDURE GetInboundIssueAccounts(
	out_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security as this is run from a batch job
	OPEN out_cur FOR
		SELECT c.host, a.inbox_sid
		  FROM inbound_issue_account iia
			JOIN csr.customer c ON iia.app_sid = c.app_sid
			JOIN mail.account a ON iia.account_sid = a.account_sid;
END;

PROCEDURE SetPublicIssue(
	in_issue_id			IN  issue.issue_id%TYPE,
	in_is_public		IN  issue.is_public%TYPE,
	out_issue_cur		OUT	SYS_REFCURSOR,
	out_action_log_cur	OUT	SYS_REFCURSOR
)
AS
	v_issue_action_log_id	issue_action_log.issue_action_log_id%TYPE;
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(security_pkg.GetAct, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied updating public Issue status with id: '||in_issue_id);
	END IF;

	UPDATE issue
	   SET is_public = in_is_public
	 WHERE issue_id = in_issue_id;
	
	IF SQL%ROWCOUNT > 0 THEN
		LogAction(
			in_issue_action_type_id => csr_data_pkg.IAT_IS_PUBLIC_CHANGED, 
			in_issue_id => in_issue_id,
			out_issue_action_log_id => v_issue_action_log_id);
	END IF;

	chain.filter_pkg.ClearCacheForAllUsers (
		in_card_group_id => chain.filter_pkg.FILTER_TYPE_ISSUES
	);
	
	INTERNAL_GetIssueActionLogs(in_issue_id, NULL, v_issue_action_log_id, NULL, out_action_log_cur);	

	OPEN out_issue_cur FOR
		SELECT is_public
		  FROM v$issue
		 WHERE issue_id = in_issue_id;

END;

PROCEDURE SetAutoCloseIssue (
	in_issue_id		IN  issue.issue_id%TYPE,
	in_auto_close	IN  issue.allow_auto_close%TYPE
)
AS
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(security_pkg.GetAct, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied updating Issue auto close status with id: '||in_issue_id);
	END IF;
	
	UPDATE issue
	   SET allow_auto_close = in_auto_close
	 WHERE issue_id = in_issue_id;
END;

PROCEDURE RegisterAggregateIndGroup(
	in_issue_type_id			IN  issue_type_aggregate_ind_grp.issue_type_id%TYPE,
	in_aggregate_ind_group_id	IN  issue_type_aggregate_ind_grp.aggregate_ind_group_id%TYPE
)
AS
BEGIN
	IF NOT (security.security_pkg.IsAdmin(security.security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must be logged in as an administrator or have system management capability to run this task.');
	END IF;

	INSERT INTO issue_type_aggregate_ind_grp (issue_type_id, aggregate_ind_group_id)
		VALUES (in_issue_type_id, in_aggregate_ind_group_id);
END;

/*
	WARNING:
	
	Demo spec code!
*/
PROCEDURE AcceptIssueAssignment (
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_issue_id				IN	issue.issue_id%TYPE,
	in_comment				IN	issue.label%TYPE,
	out_log_cur				OUT SYS_REFCURSOR,
	out_action_log_cur		OUT SYS_REFCURSOR
)
AS
	v_issue_log_id		issue_log.issue_log_id%TYPE;
	v_dummy_cur			SYS_REFCURSOR;
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(security_pkg.GetAct, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied accepting Issue assignment for Issue with id: '||in_issue_id);
	END IF;
	
	-- Issue is now not pending Accept/Return of assignment.
	UPDATE csr.issue
	   SET is_pending_assignment = 0
	 WHERE issue_id = in_issue_id;
	
	AddLogEntry(in_act_id, in_issue_id, 0, in_comment, NULL, NULL, NULL, TRUE, v_issue_log_id);
	INTERNAL_GetIssueLogEntries(security_pkg.GetSid, in_issue_id, v_issue_log_id, FALSE, out_log_cur, v_dummy_cur, out_action_log_cur);
	
	LogAction(csr_data_pkg.IAT_ACCEPTED, in_issue_id, v_issue_log_id);
END;

/*
	WARNING:
	
	Demo spec code - doesn't care if the previously assigned thing was a user or a role,it just assigns back to the person who performed the assign action. We probably want it to assign back to a role if a role was assigned.
*/
PROCEDURE ReturnIssueAssignment (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_issue_id			IN	issue.issue_id%TYPE,
	in_reason			IN	issue.label%TYPE,
	out_user_cur		OUT SYS_REFCURSOR,
	out_log_cur			OUT SYS_REFCURSOR,
	out_action_log_cur	OUT SYS_REFCURSOR
)
AS
	v_previous_assigned_sid		security_pkg.T_SID_ID;
	v_dummy_cur					SYS_REFCURSOR;	-- Don't care about results.
BEGIN
	IF NOT issue_pkg.IsAccessAllowed(security_pkg.GetAct, in_issue_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Permission denied accepting Issue assignment for Issue with id: '||in_issue_id);
	END IF;
	
	-- Re-assign the issue back to the previously assigned user.
	-- logged_by_user_sid = a USER, never a role...
	
	-- Get the last assigned user sid.
	-- Get most rescent user who Assigned to user.
	SELECT logged_by_user_sid
	  INTO v_previous_assigned_sid
	  FROM (
			SELECT logged_by_user_sid
			  FROM csr.issue_action_log
			 WHERE issue_id = in_issue_id
			   AND issue_action_type_id IN (1, 16)
			 ORDER BY logged_dtm DESC
		)
	 WHERE rownum = 1;
	 
	 -- Ideally, do some check to work out if previously assigned was a user
	 -- or role, then assign.
	 
	-- We don't want the user to be able to return issues to system users
	-- or themselves!
	 IF v_previous_assigned_sid = security_pkg.GetSid OR v_previous_assigned_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR THEN
		-- TEMPORARY MEASURE!
		raise_application_error(-20001, 'You cannot return to yourself or to the builtin admin.');
	ELSE
		 ReturnToUser (
			in_act_id,
			in_issue_id,
			v_previous_assigned_sid,
			in_reason,  -- returned or rejected? keep consistent?
			out_user_cur,
			out_log_cur,
			out_action_log_cur
		 );
	END IF;
	 
	 -- Update the is_pending_assignment flag
	 UPDATE csr.issue
	    SET is_pending_assignment = 0
	  WHERE issue_id = in_issue_id;
END;

FUNCTION GetIssueUrl(
	in_issue_id			IN  issue.issue_id%TYPE
) RETURN VARCHAR2
AS
BEGIN
	RETURN CASE WHEN in_issue_id IS NULL THEN NULL ELSE '/csr/site/issues2/viewIssue.acds?id='||in_issue_id END;
END;

PROCEDURE GetReminderAlertApps(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	t_app_sids						security.T_SID_TABLE;
BEGIN 
	t_app_sids := alert_pkg.GetAppSidsForAlert(csr_data_pkg.ALERT_ISSUE_REMINDER);

	OPEN out_cur FOR
		SELECT DISTINCT i.app_sid
		  FROM issue i
		  JOIN issue_type it ON it.app_sid = i.app_sid AND it.issue_type_id = i.issue_type_id
		 WHERE i.closed_dtm IS NULL
		   AND i.deleted = 0
		   AND (it.email_involved_roles = 1 OR it.email_involved_users = 1)
		   AND i.due_dtm <= SYSDATE + NVL(it.alert_pending_due_days, -1) + 1 -- 1 day timezone tolerance
		   AND i.due_dtm > SYSDATE - 14
		   AND i.app_sid IN (SELECT /*+CARDINALITY(100)*/ column_value FROM TABLE (t_app_sids));
END;

PROCEDURE GetReminderAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	t_app_sids						security.T_SID_TABLE;
BEGIN 
	t_app_sids := alert_pkg.GetAppSidsForAlert(csr_data_pkg.ALERT_ISSUE_REMINDER);
	alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_ISSUE_REMINDER);

	-- Optimization: 
	-- Instead of trying to work out the issue reminders in one go (by joining issues with temp_alert_batch_run), try
	-- breaking the calculation of the due issues into parts:
	-- First, build a set by using a date tolerance of 1 day on sysdate forward (so it will always include the
	-- earliest possible timezone). Then, this smaller dataset will get filtered by using each recipient's time in their timezone, 
	-- therefore the eventual result will be exactly the same.
	-- Also, don't consider entries that have been overdue for more than 2 weeks
	INSERT INTO TT_ISSUES_DUE (app_sid, issue_id, due_dtm, email_involved_roles, email_involved_users, assigned_to_user_sid,
			   region_sid, region_2_sid, issue_priority_id, alert_pending_due_days,
			   issue_type, issue_label, issue_ref, is_critical, raised_dtm,
			   closed_dtm, resolved_dtm, rejected_dtm, assigned_to_role_sid)
	SELECT /*+ MATERIALIZE */ i.app_sid, i.issue_id, i.due_dtm, it.email_involved_roles, it.email_involved_users, i.assigned_to_user_sid,
			i.region_sid, i.region_2_sid, i.issue_priority_id, it.alert_pending_due_days,
			it.label issue_type, i.label issue_label, i.issue_ref, i.is_critical, i.raised_dtm,
			i.closed_dtm, i.resolved_dtm, i.rejected_dtm, i.assigned_to_role_sid
	  FROM issue i
	  JOIN issue_type it ON it.app_sid = i.app_sid AND it.issue_type_id = i.issue_type_id
		WHERE i.closed_dtm IS NULL
		AND i.deleted = 0
		AND (it.email_involved_roles = 1 OR it.email_involved_users = 1)
		AND i.due_dtm <= SYSDATE + NVL(it.alert_pending_due_days, -1) + 1 -- 1 day timezone tolerance
		AND i.due_dtm > SYSDATE - 14
		AND i.app_sid IN (SELECT /*+CARDINALITY(100)*/ column_value FROM TABLE (t_app_sids));

	-- now, calculate recipients, in steps
	-- inline the v$issue_user 
	INSERT INTO TT_ISSUE_USER(app_sid, issue_id, user_sid)
	SELECT t.app_sid, t.issue_id, rrm.user_sid
	  FROM TT_ISSUES_DUE t
	  JOIN issue_involvement ii
	    ON ii.app_sid = t.app_sid 
	   AND t.issue_id = ii.issue_id 
	  JOIN region_role_member rrm
	    ON rrm.app_sid = ii.app_sid
	   AND rrm.region_sid = t.region_sid
	   AND rrm.role_sid = ii.role_sid
	  JOIN csr.temp_alert_batch_run tabr 
	    ON ii.app_sid = tabr.app_sid 
	   AND rrm.user_sid = tabr.csr_user_sid 
	   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_REMINDER
	   AND t.due_dtm > tabr.this_fire_time -- not overdue in the user's timezone
	   AND t.due_dtm <= tabr.this_fire_time + NVL(t.alert_pending_due_days, -1) -- needs a reminder
	 WHERE t.email_involved_roles = 1;

	-- region_2_sid, ehm...
	INSERT INTO TT_ISSUE_USER(app_sid, issue_id, user_sid)
	SELECT t.app_sid, t.issue_id, rrm.user_sid
	  FROM TT_ISSUES_DUE t
	  JOIN issue_involvement ii 
	    ON ii.app_sid = t.app_sid 
	   AND t.issue_id = ii.issue_id 
	  JOIN region_role_member rrm
	    ON rrm.app_sid = ii.app_sid
	   AND rrm.region_sid = t.region_2_sid
	   AND rrm.role_sid = ii.role_sid
	  JOIN csr.temp_alert_batch_run tabr 
	    ON ii.app_sid = tabr.app_sid 
	   AND rrm.user_sid = tabr.csr_user_sid 
	   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_REMINDER
	   AND t.due_dtm > tabr.this_fire_time -- not overdue in the user's timezone
	   AND t.due_dtm <= tabr.this_fire_time + NVL(t.alert_pending_due_days, -1) -- needs a reminder
	 WHERE t.email_involved_roles = 1;

	--assigned_to_role_sid
	INSERT INTO TT_ISSUE_USER(app_sid, issue_id, user_sid)
	SELECT t.app_sid,t.issue_id, rrm.user_sid
	  FROM TT_ISSUES_DUE t
	  JOIN region_role_member rrm
	    ON rrm.app_sid = t.app_sid
	   AND rrm.region_sid = t.region_sid
	   AND rrm.role_sid = t.assigned_to_role_sid
	  JOIN csr.temp_alert_batch_run tabr 
	    ON rrm.app_sid = tabr.app_sid 
	   AND rrm.user_sid = tabr.csr_user_sid 
	   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_REMINDER
	   AND t.due_dtm > tabr.this_fire_time -- not overdue in the user's timezone
	   AND t.due_dtm <= tabr.this_fire_time + NVL(t.alert_pending_due_days, -1) -- needs a reminder
	 WHERE t.email_involved_roles = 1;

	-- direct user involvements
	INSERT INTO TT_ISSUE_USER(app_sid, issue_id, user_sid)
	SELECT t.app_sid,t.issue_id, ii.user_sid
	  FROM TT_ISSUES_DUE t
	  JOIN issue_involvement ii 
	    ON ii.app_sid = t.app_sid 
	   AND t.issue_id = ii.issue_id 
	  JOIN csr.temp_alert_batch_run tabr 
	    ON ii.app_sid = tabr.app_sid 
	   AND ii.user_sid = tabr.csr_user_sid 
	   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_REMINDER
	   AND t.due_dtm > tabr.this_fire_time -- not overdue in the user's timezone
	   AND t.due_dtm <= tabr.this_fire_time + NVL(t.alert_pending_due_days, -1) -- needs a reminder
	 WHERE t.email_involved_users = 1;

	--assigned_to_user_sid
	INSERT INTO TT_ISSUE_USER(app_sid, issue_id, user_sid)
	SELECT t.app_sid, t.issue_id, t.assigned_to_user_sid
	  FROM TT_ISSUES_DUE t
	  JOIN csr.temp_alert_batch_run tabr 
	    ON t.app_sid = tabr.app_sid 
	   AND t.assigned_to_user_sid = tabr.csr_user_sid 
	   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_REMINDER
	   AND t.due_dtm > tabr.this_fire_time -- not overdue in the user's timezone
	   AND t.due_dtm <= tabr.this_fire_time + NVL(t.alert_pending_due_days, -1); -- needs a reminder;

	OPEN out_cur FOR
		SELECT DISTINCT issues_due.app_sid, cu.csr_user_sid, r.description region_description, issues_due.issue_type, 
			   issues_due.due_dtm, issues_due.issue_id, issues_due.issue_label, issues_due.issue_ref, issues_due.is_critical, 
			   au.full_name assigned_to, au.csr_user_sid assigned_to_user_sid, 
			   issue_pkg.GetIssueUrl(issues_due.issue_id) issue_url, issues_due.raised_dtm, 
			   CASE
					WHEN issues_due.closed_dtm IS NOT NULL THEN 'Closed'
					WHEN issues_due.resolved_dtm IS NOT NULL THEN 'Resolved'
					WHEN issues_due.rejected_dtm IS NOT NULL THEN 'Rejected'
					ELSE 'Ongoing'
				 END issue_status, ip.due_date_offset priority_due_date_offset, ip.description priority_description
		  FROM TT_ISSUES_DUE issues_due
		  JOIN TT_ISSUE_USER t ON issues_due.issue_id = t.issue_id
		  JOIN csr_user cu ON (cu.app_sid = t.app_sid AND cu.csr_user_sid = t.user_sid)
		  JOIN security.user_table ut ON ut.sid_id = cu.csr_user_sid
		  LEFT JOIN csr_user au ON (au.app_sid = t.app_sid AND au.csr_user_sid = issues_due.assigned_to_user_sid) 
		  LEFT JOIN v$region r ON r.region_sid = issues_due.region_sid AND r.app_sid = issues_due.app_sid
		  LEFT JOIN issue_alert ia ON issues_due.issue_id = ia.issue_id AND issues_due.app_sid = ia.app_sid
				AND cu.csr_user_sid = ia.csr_user_sid
		  LEFT JOIN csr.issue_priority ip ON issues_due.app_sid = ip.app_sid AND issues_due.issue_priority_id = ip.issue_priority_id
		 WHERE ia.reminder_sent_dtm IS NULL
		   AND cu.csr_user_sid != security.security_pkg.SID_BUILTIN_ADMINISTRATOR
		   AND cu.send_alerts = 1
		   AND ut.account_enabled = 1
		 ORDER BY issues_due.app_sid, cu.csr_user_sid, issues_due.due_dtm ASC;--order matters for batching alerts in sched task
END;

PROCEDURE GetReminderAlertsLoggedOn(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_ISSUE_REMINDER);

	-- Optimization: 
	-- Instead of trying to work out the issue reminders in one go (by joining issues with temp_alert_batch_run), try
	-- breaking the calculation of the due issues into parts:
	-- First, build a set by using a date tolerance of 1 day on sysdate forward (so it will always include the
	-- earliest possible timezone). Then, this smaller dataset will get filtered by using each recipient's time in their timezone, 
	-- therefore the eventual result will be exactly the same.
	-- Also, don't consider entries that have been overdue for more than 2 weeks
	INSERT INTO TT_ISSUES_DUE (app_sid, issue_id, due_dtm, email_involved_roles, email_involved_users, assigned_to_user_sid,
			   region_sid, region_2_sid, issue_priority_id, alert_pending_due_days,
			   issue_type, issue_label, issue_ref, is_critical, raised_dtm,
			   closed_dtm, resolved_dtm, rejected_dtm, assigned_to_role_sid)
	SELECT /*+ MATERIALIZE */ i.app_sid, i.issue_id, i.due_dtm, it.email_involved_roles, it.email_involved_users, i.assigned_to_user_sid,
			i.region_sid, i.region_2_sid, i.issue_priority_id, it.alert_pending_due_days,
			it.label issue_type, i.label issue_label, i.issue_ref, i.is_critical, i.raised_dtm,
			i.closed_dtm, i.resolved_dtm, i.rejected_dtm, i.assigned_to_role_sid
	  FROM issue i
	  JOIN issue_type it ON it.app_sid = i.app_sid AND it.issue_type_id = i.issue_type_id
		WHERE i.closed_dtm IS NULL
		AND i.deleted = 0
		AND (it.email_involved_roles = 1 OR it.email_involved_users = 1)
		AND i.due_dtm <= SYSDATE + NVL(it.alert_pending_due_days, -1) + 1 -- 1 day timezone tolerance
		AND i.due_dtm > SYSDATE - 14
	    AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	-- now, calculate recipients, in steps
	-- inline the v$issue_user 
	INSERT INTO TT_ISSUE_USER(app_sid, issue_id, user_sid)
	SELECT t.app_sid, t.issue_id, rrm.user_sid
	  FROM TT_ISSUES_DUE t
	  JOIN issue_involvement ii
	    ON ii.app_sid = t.app_sid 
	   AND t.issue_id = ii.issue_id 
	  JOIN region_role_member rrm
	    ON rrm.app_sid = ii.app_sid
	   AND rrm.region_sid = t.region_sid
	   AND rrm.role_sid = ii.role_sid
	  JOIN csr.temp_alert_batch_run tabr 
	    ON ii.app_sid = tabr.app_sid 
	   AND rrm.user_sid = tabr.csr_user_sid 
	   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_REMINDER
	   AND t.due_dtm > tabr.this_fire_time -- not overdue in the user's timezone
	   AND t.due_dtm <= tabr.this_fire_time + NVL(t.alert_pending_due_days, -1) -- needs a reminder
	 WHERE t.email_involved_roles = 1
	   AND ii.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	-- region_2_sid, ehm...
	INSERT INTO TT_ISSUE_USER(app_sid, issue_id, user_sid)
	SELECT t.app_sid, t.issue_id, rrm.user_sid
	  FROM TT_ISSUES_DUE t
	  JOIN issue_involvement ii 
	    ON ii.app_sid = t.app_sid 
	   AND t.issue_id = ii.issue_id 
	  JOIN region_role_member rrm
	    ON rrm.app_sid = ii.app_sid
	   AND rrm.region_sid = t.region_2_sid
	   AND rrm.role_sid = ii.role_sid
	  JOIN csr.temp_alert_batch_run tabr 
	    ON ii.app_sid = tabr.app_sid 
	   AND rrm.user_sid = tabr.csr_user_sid 
	   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_REMINDER
	   AND t.due_dtm > tabr.this_fire_time -- not overdue in the user's timezone
	   AND t.due_dtm <= tabr.this_fire_time + NVL(t.alert_pending_due_days, -1) -- needs a reminder
	 WHERE t.email_involved_roles = 1
	   AND ii.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	--assigned_to_role_sid
	INSERT INTO TT_ISSUE_USER(app_sid, issue_id, user_sid)
	SELECT t.app_sid,t.issue_id, rrm.user_sid
	  FROM TT_ISSUES_DUE t
	  JOIN region_role_member rrm
	    ON rrm.app_sid = t.app_sid
	   AND rrm.region_sid = t.region_sid
	   AND rrm.role_sid = t.assigned_to_role_sid
	  JOIN csr.temp_alert_batch_run tabr 
	    ON rrm.app_sid = tabr.app_sid 
	   AND rrm.user_sid = tabr.csr_user_sid 
	   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_REMINDER
	   AND t.due_dtm > tabr.this_fire_time -- not overdue in the user's timezone
	   AND t.due_dtm <= tabr.this_fire_time + NVL(t.alert_pending_due_days, -1) -- needs a reminder
	 WHERE t.email_involved_roles = 1
	   AND t.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	-- direct user involvements
	INSERT INTO TT_ISSUE_USER(app_sid, issue_id, user_sid)
	SELECT t.app_sid,t.issue_id, ii.user_sid
	  FROM TT_ISSUES_DUE t
	  JOIN issue_involvement ii 
	    ON ii.app_sid = t.app_sid 
	   AND t.issue_id = ii.issue_id 
	  JOIN csr.temp_alert_batch_run tabr 
	    ON ii.app_sid = tabr.app_sid 
	   AND ii.user_sid = tabr.csr_user_sid 
	   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_REMINDER
	   AND t.due_dtm > tabr.this_fire_time -- not overdue in the user's timezone
	   AND t.due_dtm <= tabr.this_fire_time + NVL(t.alert_pending_due_days, -1) -- needs a reminder
	 WHERE t.email_involved_users = 1
	   AND t.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	--assigned_to_user_sid
	INSERT INTO TT_ISSUE_USER(app_sid, issue_id, user_sid)
	SELECT t.app_sid, t.issue_id, t.assigned_to_user_sid
	  FROM TT_ISSUES_DUE t
	  JOIN csr.temp_alert_batch_run tabr
	    ON t.app_sid = tabr.app_sid
	   AND t.assigned_to_user_sid = tabr.csr_user_sid
	   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_REMINDER
	   AND t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND t.due_dtm > tabr.this_fire_time -- not overdue in the user's timezone
	   AND t.due_dtm <= tabr.this_fire_time + NVL(t.alert_pending_due_days, -1); -- needs a reminder;

	OPEN out_cur FOR
		SELECT DISTINCT cu.csr_user_sid, r.description region_description, issues_due.issue_type, 
			   issues_due.due_dtm, issues_due.issue_id, issues_due.issue_label, issues_due.issue_ref, issues_due.is_critical, 
			   au.full_name assigned_to, au.csr_user_sid assigned_to_user_sid, 
			   issue_pkg.GetIssueUrl(issues_due.issue_id) issue_url, issues_due.raised_dtm, 
			   CASE
					WHEN issues_due.closed_dtm IS NOT NULL THEN 'Closed'
					WHEN issues_due.resolved_dtm IS NOT NULL THEN 'Resolved'
					WHEN issues_due.rejected_dtm IS NOT NULL THEN 'Rejected'
					ELSE 'Ongoing'
				 END issue_status, ip.due_date_offset priority_due_date_offset, ip.description priority_description
		  FROM TT_ISSUES_DUE issues_due
		  JOIN TT_ISSUE_USER t ON issues_due.issue_id = t.issue_id
		  JOIN csr_user cu ON (cu.app_sid = t.app_sid AND cu.csr_user_sid = t.user_sid)
		  JOIN security.user_table ut ON ut.sid_id = cu.csr_user_sid
		  LEFT JOIN csr_user au ON (au.app_sid = t.app_sid AND au.csr_user_sid = issues_due.assigned_to_user_sid) 
		  LEFT JOIN v$region r ON r.region_sid = issues_due.region_sid AND r.app_sid = issues_due.app_sid
		  LEFT JOIN issue_alert ia ON issues_due.issue_id = ia.issue_id AND issues_due.app_sid = ia.app_sid
				AND cu.csr_user_sid = ia.csr_user_sid
		  LEFT JOIN csr.issue_priority ip ON issues_due.app_sid = ip.app_sid AND issues_due.issue_priority_id = ip.issue_priority_id
		 WHERE ia.reminder_sent_dtm IS NULL
		   AND cu.csr_user_sid != security.security_pkg.SID_BUILTIN_ADMINISTRATOR
		   AND cu.send_alerts = 1
		   AND ut.account_enabled = 1
		 ORDER BY cu.csr_user_sid, issues_due.due_dtm ASC;--order matters for batching alerts in sched task
END;

PROCEDURE GetOverdueAlertApps(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	t_app_sids						security.T_SID_TABLE;
BEGIN
	t_app_sids := alert_pkg.GetAppSidsForAlert(csr_data_pkg.ALERT_ISSUE_OVERDUE);

	OPEN out_cur FOR
		SELECT DISTINCT i.app_sid
		  FROM issue i
		  JOIN issue_type it ON it.app_sid = i.app_sid AND it.issue_type_id = i.issue_type_id
		 WHERE i.closed_dtm IS NULL
		   AND i.deleted = 0
		   AND (it.email_involved_roles = 1 OR it.email_involved_users = 1)
		   AND i.due_dtm + NVL(it.alert_overdue_days, 0) >= SYSDATE - 1 -- 1 day timezone tolerance
		   AND i.app_sid IN (SELECT /*+CARDINALITY(100)*/ column_value FROM TABLE (t_app_sids));
END;

PROCEDURE GetOverdueAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	t_app_sids						security.T_SID_TABLE;
BEGIN
	t_app_sids := alert_pkg.GetAppSidsForAlert(csr_data_pkg.ALERT_ISSUE_OVERDUE);
	alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_ISSUE_OVERDUE);
	
	-- Optimization: 
	-- Instead of trying to work out the overdue issue in one go (by joining issues with temp_alert_batch_run), try
	-- breaking the calculation into parts:
	-- First, build a materialised set by using a date tolerance of 1 day on sysdate (so it will always include the
	-- earliest possible timezone). Then, this smaller dataset will get filtered by using each recipient's time in their timezone, 
	-- therefore the eventual result will be the exactly same.
	INSERT INTO TT_ISSUES_OVERDUE (app_sid, issue_id, due_dtm, email_involved_roles, email_involved_users, assigned_to_user_sid,
			   region_sid, region_2_sid, issue_priority_id, alert_overdue_days,
			   issue_type, issue_label, issue_ref, is_critical, raised_dtm,
			   closed_dtm, resolved_dtm, rejected_dtm, assigned_to_role_sid)
	SELECT /*+ MATERIALIZE */ i.app_sid, i.issue_id, i.due_dtm, it.email_involved_roles, it.email_involved_users, i.assigned_to_user_sid,
			i.region_sid, i.region_2_sid, i.issue_priority_id, it.alert_overdue_days,
			it.label issue_type, i.label issue_label, i.issue_ref, i.is_critical, i.raised_dtm,
			i.closed_dtm, i.resolved_dtm, i.rejected_dtm, i.assigned_to_role_sid
	  FROM issue i
	  JOIN issue_type it ON it.app_sid = i.app_sid AND it.issue_type_id = i.issue_type_id
	 WHERE i.closed_dtm IS NULL
	   AND i.deleted = 0
	   AND (it.email_involved_roles = 1 OR it.email_involved_users = 1)
	   AND i.due_dtm + NVL(it.alert_overdue_days, 0) >= SYSDATE - 1 -- 1 day timezone tolerance
	   AND i.app_sid IN (SELECT /*+CARDINALITY(100)*/ column_value FROM TABLE (t_app_sids));

	-- now, calculate recipients, in steps
	-- inline the v$issue_user 
	INSERT INTO TT_ISSUE_USER(app_sid, issue_id, user_sid)
	SELECT t.app_sid, t.issue_id, rrm.user_sid
	  FROM TT_ISSUES_OVERDUE t
	  JOIN issue_involvement ii 
	    ON ii.app_sid = t.app_sid 
	   AND t.issue_id = ii.issue_id 
	  JOIN region_role_member rrm
	    ON rrm.app_sid = ii.app_sid
	   AND rrm.region_sid = t.region_sid
	   AND rrm.role_sid = ii.role_sid
	  JOIN csr.temp_alert_batch_run tabr 
	    ON ii.app_sid = tabr.app_sid 
	   AND rrm.user_sid = tabr.csr_user_sid 
	   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_OVERDUE
	   AND t.due_dtm < tabr.this_fire_time -- overdue in user's timezone
	   AND t.due_dtm + NVL(t.alert_overdue_days, 0) >= tabr.this_fire_time
	 WHERE t.email_involved_roles = 1;

	 -- region_2_sid, ehm...
	INSERT INTO TT_ISSUE_USER(app_sid, issue_id, user_sid)
	SELECT t.app_sid, t.issue_id, rrm.user_sid
	  FROM TT_ISSUES_OVERDUE t
	  JOIN issue_involvement ii 
	    ON ii.app_sid = t.app_sid 
	   AND t.issue_id = ii.issue_id 
	  JOIN region_role_member rrm
	    ON rrm.app_sid = ii.app_sid
	   AND rrm.region_sid = t.region_2_sid
	   AND rrm.role_sid = ii.role_sid
	  JOIN csr.temp_alert_batch_run tabr 
	    ON ii.app_sid = tabr.app_sid 
	   AND rrm.user_sid = tabr.csr_user_sid 
	   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_OVERDUE
	   AND t.due_dtm < tabr.this_fire_time -- overdue in user's timezone
	   AND t.due_dtm + NVL(t.alert_overdue_days, 0) >= tabr.this_fire_time
	 WHERE t.email_involved_roles = 1;

	--assigned_to_role_sid
	INSERT INTO TT_ISSUE_USER(app_sid, issue_id, user_sid)
	SELECT t.app_sid,t.issue_id, rrm.user_sid
	  FROM TT_ISSUES_OVERDUE t
	  JOIN region_role_member rrm
	    ON rrm.app_sid = t.app_sid
	   AND rrm.region_sid = t.region_sid
	   AND rrm.role_sid = t.assigned_to_role_sid
	  JOIN csr.temp_alert_batch_run tabr 
	    ON rrm.app_sid = tabr.app_sid 
	   AND rrm.user_sid = tabr.csr_user_sid 
	   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_OVERDUE
	   AND t.due_dtm < tabr.this_fire_time -- overdue in user's timezone
	   AND t.due_dtm + NVL(t.alert_overdue_days, 0) >= tabr.this_fire_time
	 WHERE t.email_involved_roles = 1;

	-- direct user involvements
	INSERT INTO TT_ISSUE_USER(app_sid, issue_id, user_sid)
	SELECT t.app_sid,t.issue_id, ii.user_sid
	  FROM TT_ISSUES_OVERDUE t
	  JOIN issue_involvement ii 
	    ON ii.app_sid = t.app_sid 
	   AND t.issue_id = ii.issue_id 
	  JOIN csr.temp_alert_batch_run tabr 
	    ON ii.app_sid = tabr.app_sid 
	   AND ii.user_sid = tabr.csr_user_sid 
	   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_OVERDUE
	   AND t.due_dtm < tabr.this_fire_time -- overdue in user's timezone
	   AND t.due_dtm + NVL(t.alert_overdue_days, 0) >= tabr.this_fire_time
	 WHERE t.email_involved_users = 1;

	--assigned_to_user_sid
	INSERT INTO TT_ISSUE_USER(app_sid, issue_id, user_sid)
	SELECT t.app_sid, t.issue_id, t.assigned_to_user_sid
	  FROM TT_ISSUES_OVERDUE t
	  JOIN csr.temp_alert_batch_run tabr 
	    ON t.app_sid = tabr.app_sid 
	   AND t.assigned_to_user_sid = tabr.csr_user_sid 
	   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_OVERDUE
	   AND t.due_dtm < tabr.this_fire_time -- overdue in user's timezone
	   AND t.due_dtm + NVL(t.alert_overdue_days, 0) >= tabr.this_fire_time;

	OPEN out_cur FOR
		SELECT DISTINCT issues_overdue.app_sid, cu.csr_user_sid, r.description region_description, issues_overdue.issue_type, 
			   issues_overdue.due_dtm, issues_overdue.issue_id, issues_overdue.issue_label, issues_overdue.issue_ref, issues_overdue.is_critical, 
			   au.full_name assigned_to, au.csr_user_sid assigned_to_user_sid, 
			   issue_pkg.GetIssueUrl(issues_overdue.issue_id) issue_url, issues_overdue.raised_dtm,
			   CASE
					WHEN issues_overdue.closed_dtm IS NOT NULL THEN 'Closed'
					WHEN issues_overdue.resolved_dtm IS NOT NULL THEN 'Resolved'
					WHEN issues_overdue.rejected_dtm IS NOT NULL THEN 'Rejected'
					ELSE 'Ongoing'
				 END issue_status, ip.due_date_offset priority_due_date_offset, ip.description priority_description
		  FROM TT_ISSUES_OVERDUE issues_overdue
		  JOIN TT_ISSUE_USER t ON issues_overdue.issue_id = t.issue_id
		  JOIN csr_user cu ON (cu.app_sid = t.app_sid AND cu.csr_user_sid = t.user_sid)
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		  LEFT JOIN csr_user au ON au.app_sid = issues_overdue.app_sid AND au.csr_user_sid = issues_overdue.assigned_to_user_sid
		  LEFT JOIN v$region r ON issues_overdue.region_sid = r.region_sid AND issues_overdue.app_sid = r.app_sid
		  LEFT JOIN issue_alert ia ON issues_overdue.issue_id = ia.issue_id
		   AND issues_overdue.app_sid = ia.app_sid
		   AND cu.csr_user_sid = ia.csr_user_sid
		  LEFT JOIN csr.issue_priority ip ON issues_overdue.app_sid = ip.app_sid AND issues_overdue.issue_priority_id = ip.issue_priority_id
		 WHERE ia.overdue_sent_dtm IS NULL
		   AND cu.csr_user_sid != security.security_pkg.SID_BUILTIN_ADMINISTRATOR
		   AND cu.send_alerts = 1
		   AND ut.account_enabled = 1
		 ORDER BY issues_overdue.app_sid, cu.csr_user_sid, issues_overdue.due_dtm ASC;--order matters for batching alerts in sched task
END;

PROCEDURE GetOverdueAlertsLoggedOn(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_ISSUE_OVERDUE);
	
	-- Optimization: 
	-- Instead of trying to work out the overdue issue in one go (by joining issues with temp_alert_batch_run), try
	-- breaking the calculation into parts:
	-- First, build a materialised set by using a date tolerance of 1 day on sysdate (so it will always include the
	-- earliest possible timezone). Then, this smaller dataset will get filtered by using each recipient's time in their timezone, 
	-- therefore the eventual result will be the exactly same.
	INSERT INTO TT_ISSUES_OVERDUE (app_sid, issue_id, due_dtm, email_involved_roles, email_involved_users, assigned_to_user_sid,
			   region_sid, region_2_sid, issue_priority_id, alert_overdue_days,
			   issue_type, issue_label, issue_ref, is_critical, raised_dtm,
			   closed_dtm, resolved_dtm, rejected_dtm, assigned_to_role_sid)
	SELECT /*+ MATERIALIZE */ i.app_sid, i.issue_id, i.due_dtm, it.email_involved_roles, it.email_involved_users, i.assigned_to_user_sid,
			i.region_sid, i.region_2_sid, i.issue_priority_id, it.alert_overdue_days,
			it.label issue_type, i.label issue_label, i.issue_ref, i.is_critical, i.raised_dtm,
			i.closed_dtm, i.resolved_dtm, i.rejected_dtm, i.assigned_to_role_sid
	  FROM issue i
	  JOIN issue_type it ON it.app_sid = i.app_sid AND it.issue_type_id = i.issue_type_id
	 WHERE i.closed_dtm IS NULL
	   AND i.deleted = 0
	   AND (it.email_involved_roles = 1 OR it.email_involved_users = 1)
	   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND i.due_dtm + NVL(it.alert_overdue_days, 0) >= SYSDATE - 1; -- 1 day timezone tolerance

	-- now, calculate recipients, in steps
	-- inline the v$issue_user 
	INSERT INTO TT_ISSUE_USER(app_sid, issue_id, user_sid)
	SELECT t.app_sid, t.issue_id, rrm.user_sid
	  FROM TT_ISSUES_OVERDUE t
	  JOIN issue_involvement ii 
	    ON ii.app_sid = t.app_sid 
	   AND t.issue_id = ii.issue_id 
	  JOIN region_role_member rrm
	    ON rrm.app_sid = ii.app_sid
	   AND rrm.region_sid = t.region_sid
	   AND rrm.role_sid = ii.role_sid
	  JOIN csr.temp_alert_batch_run tabr 
	    ON ii.app_sid = tabr.app_sid 
	   AND rrm.user_sid = tabr.csr_user_sid 
	   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_OVERDUE
	   AND t.due_dtm < tabr.this_fire_time -- overdue in user's timezone
	   AND t.due_dtm + NVL(t.alert_overdue_days, 0) >= tabr.this_fire_time
	 WHERE t.email_involved_roles = 1
	   AND ii.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	 -- region_2_sid, ehm...
	INSERT INTO TT_ISSUE_USER(app_sid, issue_id, user_sid)
	SELECT t.app_sid, t.issue_id, rrm.user_sid
	  FROM TT_ISSUES_OVERDUE t
	  JOIN issue_involvement ii 
	    ON ii.app_sid = t.app_sid 
	   AND t.issue_id = ii.issue_id 
	  JOIN region_role_member rrm
	    ON rrm.app_sid = ii.app_sid
	   AND rrm.region_sid = t.region_2_sid
	   AND rrm.role_sid = ii.role_sid
	  JOIN csr.temp_alert_batch_run tabr 
	    ON ii.app_sid = tabr.app_sid 
	   AND rrm.user_sid = tabr.csr_user_sid 
	   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_OVERDUE
	   AND t.due_dtm < tabr.this_fire_time -- overdue in user's timezone
	   AND t.due_dtm + NVL(t.alert_overdue_days, 0) >= tabr.this_fire_time
	 WHERE t.email_involved_roles = 1
	   AND ii.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	--assigned_to_role_sid
	INSERT INTO TT_ISSUE_USER(app_sid, issue_id, user_sid)
	SELECT t.app_sid,t.issue_id, rrm.user_sid
	  FROM TT_ISSUES_OVERDUE t
	  JOIN region_role_member rrm
	    ON rrm.app_sid = t.app_sid
	   AND rrm.region_sid = t.region_sid
	   AND rrm.role_sid = t.assigned_to_role_sid
	  JOIN csr.temp_alert_batch_run tabr 
	    ON rrm.app_sid = tabr.app_sid 
	   AND rrm.user_sid = tabr.csr_user_sid 
	   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_OVERDUE
	   AND t.due_dtm < tabr.this_fire_time -- overdue in user's timezone
	   AND t.due_dtm + NVL(t.alert_overdue_days, 0) >= tabr.this_fire_time
	 WHERE t.email_involved_roles = 1
	   AND t.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	-- direct user involvements
	INSERT INTO TT_ISSUE_USER(app_sid, issue_id, user_sid)
	SELECT t.app_sid,t.issue_id, ii.user_sid
	  FROM TT_ISSUES_OVERDUE t
	  JOIN issue_involvement ii 
	    ON ii.app_sid = t.app_sid 
	   AND t.issue_id = ii.issue_id 
	  JOIN csr.temp_alert_batch_run tabr 
	    ON ii.app_sid = tabr.app_sid 
	   AND ii.user_sid = tabr.csr_user_sid 
	   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_OVERDUE
	   AND t.due_dtm < tabr.this_fire_time -- overdue in user's timezone
	   AND t.due_dtm + NVL(t.alert_overdue_days, 0) >= tabr.this_fire_time
	 WHERE t.email_involved_users = 1
	   AND ii.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	--assigned_to_user_sid
	INSERT INTO TT_ISSUE_USER(app_sid, issue_id, user_sid)
	SELECT t.app_sid, t.issue_id, t.assigned_to_user_sid
	  FROM TT_ISSUES_OVERDUE t
	  JOIN csr.temp_alert_batch_run tabr 
	    ON t.app_sid = tabr.app_sid 
	   AND t.assigned_to_user_sid = tabr.csr_user_sid 
	   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_ISSUE_OVERDUE
	   AND t.due_dtm < tabr.this_fire_time -- overdue in user's timezone
	   AND t.due_dtm + NVL(t.alert_overdue_days, 0) >= tabr.this_fire_time
	   AND t.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_cur FOR
		SELECT DISTINCT cu.csr_user_sid, r.description region_description, issues_overdue.issue_type, 
			   issues_overdue.due_dtm, issues_overdue.issue_id, issues_overdue.issue_label, issues_overdue.issue_ref, issues_overdue.is_critical, 
			   au.full_name assigned_to, au.csr_user_sid assigned_to_user_sid, 
			   issue_pkg.GetIssueUrl(issues_overdue.issue_id) issue_url, issues_overdue.raised_dtm,
			   CASE
					WHEN issues_overdue.closed_dtm IS NOT NULL THEN 'Closed'
					WHEN issues_overdue.resolved_dtm IS NOT NULL THEN 'Resolved'
					WHEN issues_overdue.rejected_dtm IS NOT NULL THEN 'Rejected'
					ELSE 'Ongoing'
				 END issue_status, ip.due_date_offset priority_due_date_offset, ip.description priority_description
		  FROM TT_ISSUES_OVERDUE issues_overdue
		  JOIN TT_ISSUE_USER t ON issues_overdue.issue_id = t.issue_id
		  JOIN csr_user cu ON (cu.app_sid = t.app_sid AND cu.csr_user_sid = t.user_sid)
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		  LEFT JOIN csr_user au ON au.app_sid = issues_overdue.app_sid AND au.csr_user_sid = issues_overdue.assigned_to_user_sid
		  LEFT JOIN v$region r ON issues_overdue.region_sid = r.region_sid AND issues_overdue.app_sid = r.app_sid
		  LEFT JOIN issue_alert ia ON issues_overdue.issue_id = ia.issue_id
		   AND issues_overdue.app_sid = ia.app_sid
		   AND cu.csr_user_sid = ia.csr_user_sid
		  LEFT JOIN csr.issue_priority ip ON issues_overdue.app_sid = ip.app_sid AND issues_overdue.issue_priority_id = ip.issue_priority_id
		 WHERE ia.overdue_sent_dtm IS NULL
		   AND cu.csr_user_sid != security.security_pkg.SID_BUILTIN_ADMINISTRATOR
		   AND cu.send_alerts = 1
		   AND ut.account_enabled = 1
		 ORDER BY cu.csr_user_sid, issues_overdue.due_dtm ASC;--order matters for batching alerts in sched task
END;

PROCEDURE RecordReminderSent(
	in_issue_id		IN	ISSUE.ISSUE_ID%TYPE,
	in_user_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	BEGIN
		INSERT INTO issue_alert (issue_id, csr_user_sid, reminder_sent_dtm)
		VALUES (in_issue_id, in_user_sid, SYSDATE);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE issue_alert
			   SET reminder_sent_dtm = SYSDATE
			 WHERE issue_id = in_issue_id
			   AND csr_user_sid = in_user_sid;
	END;
END;

PROCEDURE RecordOverdueSent(
	in_issue_id		IN	ISSUE.ISSUE_ID%TYPE,
	in_user_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	BEGIN
		INSERT INTO issue_alert (issue_id, csr_user_sid, overdue_sent_dtm)
		VALUES (in_issue_id, in_user_sid, SYSDATE);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE issue_alert
			   SET overdue_sent_dtm = SYSDATE
			 WHERE issue_id = in_issue_id
			   AND csr_user_sid = in_user_sid;
	END;
END;

PROCEDURE GetIssuesByMeterMissingData(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied reading region sid ' || in_region_sid);
	END IF;

	-- put the issue dtm in the middle of the missing period
	OPEN out_cur FOR
		SELECT 
			i.issue_id,
			i.label,
			i.resolved_dtm,
			i.manual_completion_dtm,
			immd.issue_meter_missing_data_id,
			immd.region_sid, 
			immd.start_dtm + (immd.end_dtm - immd.start_dtm) / 2 issue_dtm,
		   CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1 END is_resolved,
		   CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1 END is_rejected
		  FROM issue i
			JOIN issue_meter_missing_data immd on i.issue_meter_missing_data_id = immd.issue_meter_missing_data_id AND i.app_sid = immd.app_sid
		 WHERE immd.region_sid = in_region_sid
		   AND i.deleted = 0;
END;

FUNCTION IssueIsPublic(
	in_issue_id					issue.issue_id%TYPE
) RETURN BOOLEAN
AS
	v_is_public					NUMBER(1);
BEGIN
	SELECT is_public
	  INTO v_is_public
	  FROM issue
	 WHERE app_sid = security_pkg.getapp AND issue_id = in_issue_id;

	RETURN NVL(v_is_public = 1, FALSE);
END;

FUNCTION GetPermissibleCustomFields (
	in_issue_type_id				IN issue_type.issue_type_id%TYPE DEFAULT NULL
) RETURN security.T_SID_TABLE
AS
	v_permissible_cust_fields			security.T_SID_TABLE;
	v_has_issue_management 				NUMBER(1) := csr_data_pkg.SQL_CheckCapability('Issue management');
BEGIN
	SELECT issue_custom_field_id
	  BULK COLLECT INTO v_permissible_cust_fields
	  FROM issue_custom_field
	 WHERE NVL(in_issue_type_id, issue_type_id) = issue_type_id
	   AND (
		v_has_issue_management = 1
		OR (restrict_to_group_sid IS NULL OR security.user_pkg.IsUserInGroup(security.security_pkg.GetAct, restrict_to_group_sid) = 1)
	   );

	RETURN v_permissible_cust_fields;
END;

PROCEDURE LinkIssueToNonCompliance(
	in_issue_id				issue.issue_id%TYPE,
	in_non_compliance_id	non_compliance.non_compliance_id%TYPE,
	in_force				NUMBER DEFAULT 0
)
AS
	v_issue_non_compliance_id	issue.issue_non_compliance_id%TYPE;
BEGIN
	SELECT issue_non_compliance_id
	  INTO v_issue_non_compliance_id
	  FROM issue
	 WHERE issue_id = in_issue_id;

	IF v_issue_non_compliance_id IS NOT NULL THEN
		IF in_force = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Issue with ID:'||in_issue_id||' is already linked to a non_compliance');
		ELSE
			UPDATE csr.issue_non_compliance 
			   SET non_compliance_id = in_non_compliance_id
			 WHERE issue_non_compliance_id = v_issue_non_compliance_id;
		END IF;
	ELSE
		INSERT INTO csr.issue_non_compliance (issue_non_compliance_id, non_compliance_id)
			VALUES (issue_non_compliance_id_seq.NEXTVAL, in_non_compliance_id);

		UPDATE issue
		   SET issue_non_compliance_id = issue_non_compliance_id_seq.CURRVAL
		 WHERE issue_id = in_issue_id;
	END IF;
END;

PROCEDURE RefreshRelativeDueDtm(
	in_issue_id						IN	issue.issue_id%TYPE
)
AS
BEGIN
	RefreshRelativeDueDtm(in_issue_id, NULL);
END;

PROCEDURE RefreshRelativeDueDtm(
	in_issue_id						IN	issue.issue_id%TYPE,
	in_issue_log_id					IN	issue_action_log.issue_action_log_id%TYPE
)
AS 
	v_due_dtm						issue.due_dtm%TYPE;
	v_source_id						issue.issue_due_source_id%TYPE;
	v_offset_days					issue.issue_due_offset_days%TYPE;
	v_offset_months 				issue.issue_due_offset_months%TYPE;
	v_offset_years					issue.issue_due_offset_years%TYPE;
	v_proc							issue_due_source.fetch_proc%TYPE;
BEGIN
	SELECT i.issue_due_source_id,
		   NVL(i.issue_due_offset_days, 0),
		   NVL(i.issue_due_offset_months, 0),
		   NVL(i.issue_due_offset_years, 0),
		   ids.fetch_proc
	  INTO v_source_id,
		   v_offset_days,
		   v_offset_months,
		   v_offset_years,
		   v_proc
	  FROM issue i
	  LEFT JOIN issue_due_source ids
		ON i.app_sid = ids.app_sid
	   AND i.issue_due_source_id = ids.issue_due_source_id
	 WHERE issue_id = in_issue_id;

	IF v_source_id IS NOT NULL AND v_proc IS NOT NULL THEN
		EXECUTE IMMEDIATE 'BEGIN '||v_proc||'(:1,:2,:3);END;' USING in_issue_id, v_source_id, OUT v_due_dtm;

		-- Apply offsets
		v_due_dtm := v_due_dtm + v_offset_days;
		v_due_dtm := ADD_MONTHS(v_due_dtm, v_offset_months + (v_offset_years * 12));

		UPDATE issue 
		   SET last_due_dtm = due_dtm,
			   due_dtm = v_due_dtm
		 WHERE issue_id = in_issue_id;

		-- allow the overdue alerts to be resent if the new due date is in the future
		IF v_due_dtm >= SYSDATE THEN
			UPDATE issue_alert
			   SET overdue_sent_dtm = NULL,
				   reminder_sent_dtm = NULL
			 WHERE issue_id = in_issue_id;

			UPDATE issue
			   SET notified_overdue = 0
			 WHERE issue_id = in_issue_id;
		END IF;

		LogAction(csr_data_pkg.IAT_DUE_DATE_CHANGED, in_issue_id, in_issue_log_id);
		INTERNAL_StatusChanged(in_issue_id, csr_data_pkg.IAT_DUE_DATE_CHANGED);
	END IF;
END;

PROCEDURE UNSEC_GetIssueRaiseAlertAppSids(
	out_apps_cur					OUT	SYS_REFCURSOR
)
AS
	t_app_sids						security.T_SID_TABLE;
BEGIN
	t_app_sids := alert_pkg.GetAppSidsForAlert(csr_data_pkg.ALERT_ISSUE_COMMENT);

	OPEN out_apps_cur FOR
		SELECT DISTINCT app_sid
		  FROM issue_raise_alert
		 WHERE app_sid IN (SELECT /*+CARDINALITY(100)*/ column_value FROM TABLE (t_app_sids));
END;

PROCEDURE UNSEC_GetIssueRaiseAlertsLoggedOn(
	out_alert_cur					OUT	SYS_REFCURSOR,
	out_users_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_alert_cur FOR
		SELECT issue_id, raised_by_user_sid, issue_comment
		  FROM issue_raise_alert
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY issue_id;

	-- Needed when triggering automated issue alerts
	OPEN out_users_cur FOR
		WITH issue_users AS (
			SELECT i.app_sid, i.issue_id, i.issue_pending_val_id, i.issue_sheet_value_id, i.issue_meter_id, 
				   i.issue_meter_alarm_id, i.issue_meter_raw_data_id, i.issue_meter_data_source_id,
				   i.issue_supplier_id, iiu.user_sid, iiu.is_an_owner, iiu.user_name, iiu.full_name, 
				   iiu.full_name friendly_name, -- need to change the component but I can't release by binaries atm
				   iiu.email, r.description region_description, i.label, i.source_label,
				   i.issue_non_compliance_id, issue_pkg.GetIssueUrl(i.issue_id) issue_url,
				   i.source_url, i.raised_dtm, i.due_dtm, i.issue_ref, au.full_name assigned_to, au.csr_user_sid assigned_to_user_sid, 
				   i.is_critical, it.label issue_type_label,
					CASE
						WHEN i.closed_dtm IS NOT NULL THEN 'Closed'
						WHEN i.resolved_dtm IS NOT NULL THEN 'Resolved'
						WHEN i.rejected_dtm IS NOT NULL THEN 'Rejected'
						ELSE 'Ongoing'
					 END issue_status, ip.due_date_offset priority_due_date_offset, ip.description priority_description
		  	  FROM issue i
		  	  JOIN (SELECT ii.app_sid, ii.issue_id, ii.is_an_owner, ii.from_role,
		  	  			   cu.csr_user_sid user_sid, cu.user_name, cu.full_name, cu.email
	  				  FROM (SELECT app_sid, issue_id, MAX(is_an_owner) is_an_owner,
								   MIN(from_role) from_role, user_sid
		  					  FROM (SELECT ii.app_sid, ii.issue_id, is_an_owner,
		  					  			   NVL(ii.user_sid, rrm.user_sid) user_sid,
			   							   CASE WHEN ii.role_sid IS NOT NULL THEN 1 ELSE 0 END from_role,
			   							   ia.raised_by_user_sid
		  							  FROM issue_involvement ii
		  							  JOIN issue i ON i.app_sid = ii.app_sid AND i.issue_id = ii.issue_id
		  							  JOIN issue_raise_alert ia ON i.app_sid = ia.app_sid AND i.issue_id = ia.issue_id
		  							  LEFT JOIN region_role_member rrm ON rrm.app_sid = i.app_sid
		  							   AND rrm.region_sid = i.region_sid AND rrm.role_sid = ii.role_sid
		 							 UNION
									SELECT ii.app_sid, ii.issue_id, ii.is_an_owner, rrm.user_sid, 1 from_role,
										   ia.raised_by_user_sid
		  							  FROM issue_involvement ii
		  							  JOIN issue i ON i.app_sid = ii.app_sid AND i.issue_id = ii.issue_id
		  							  JOIN issue_raise_alert ia ON i.app_sid = ia.app_sid AND i.issue_id = ia.issue_id
		  							  JOIN region_role_member rrm ON rrm.app_sid = i.app_sid
		  							   AND rrm.region_sid = i.region_2_sid AND rrm.role_sid = ii.role_sid)
						 	 WHERE raised_by_user_sid != user_sid		  					 
		  					 GROUP BY app_sid, issue_id, user_sid) ii
	  				  JOIN csr_user cu ON ii.app_sid = cu.app_sid AND ii.user_sid = cu.csr_user_sid AND cu.csr_user_sid != security.security_pkg.SID_BUILTIN_ADMINISTRATOR AND cu.send_alerts = 1
					  JOIN security.user_table ut on ut.sid_id = cu.csr_user_sid AND ut.account_enabled = 1) iiu
				ON i.app_sid = iiu.app_sid AND iiu.issue_id = i.issue_id
		  	  JOIN issue_type it ON i.app_sid = it.app_sid AND i.issue_type_id = it.issue_type_id
		  	  LEFT JOIN v$region r ON i.region_sid = r.region_sid AND i.app_sid = r.app_sid
		  	  LEFT JOIN csr_user au ON i.app_sid = au.app_sid AND i.assigned_to_user_sid = au.csr_user_sid
			  LEFT JOIN csr.issue_priority ip ON i.app_sid = ip.app_sid AND i.issue_priority_id = ip.issue_priority_id
			 WHERE (it.email_involved_roles = 1 OR iiu.from_role = 0)
			   AND (it.email_involved_users = 1 OR iiu.from_role = 1)
		 	   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		)
		SELECT *
		  FROM (
				-- DELEGATIONS
				SELECT iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
						c.editing_url || sheet_pkg.GetSheetQueryString(isv.app_sid, isv.ind_sid, isv.region_sid, isv.start_dtm, isv.end_dtm, iu.user_sid)
					   || '#indSid='||isv.ind_Sid||',regionSid='||isv.region_sid url, null url_label,
					   c.editing_url || sheet_pkg.GetSheetQueryString(isv.app_sid, isv.ind_sid, isv.region_sid, isv.start_dtm, isv.end_dtm, iu.user_sid)
					   || '#indSid='||isv.ind_Sid||',regionSid='||isv.region_sid parent_url, 'View sheet' parent_url_label,
					    iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu, customer c, issue_sheet_value isv
				 WHERE iu.app_sid = c.app_sid
				   AND iu.app_sid = isv.app_sid AND iu.issue_sheet_value_id = isv.issue_sheet_value_id
		 	   	   AND iu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				UNION ALL
				-- METER
				SELECT iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   meter_pkg.GetIssueMeterUrl(im.issue_meter_id) url, 'View meter data' url_label, 
					   meter_pkg.GetIssueMeterUrl(im.issue_meter_id) parent_url, 'View meter data' parent_url_label, 
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu, issue_meter im
				 WHERE iu.app_sid = im.app_sid AND iu.issue_meter_id = im.issue_meter_id
		 	   	   AND iu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				UNION ALL
				-- METER ALARM
				SELECT iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   meter_alarm_pkg.GetAlarmUrl(ima.issue_meter_alarm_id) url, 'View meter data' url_label, 
					   meter_alarm_pkg.GetAlarmUrl(ima.issue_meter_alarm_id) parent_url, 'View meter data' parent_url_label, 
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu, issue_meter_alarm ima
				 WHERE iu.app_sid = ima.app_sid AND iu.issue_meter_alarm_id = ima.issue_meter_alarm_id
		 	   	   AND iu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				UNION ALL
				-- METER RAW DATA
				SELECT iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   meter_monitor_pkg.GetRawDataUrl(rd.issue_meter_raw_data_id) url, 'View raw data' url_label, 
					   meter_monitor_pkg.GetRawDataUrl(rd.issue_meter_raw_data_id) parent_url, 'View raw data' parent_url_label, 
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu, issue_meter_raw_data rd
				 WHERE iu.app_sid = rd.app_sid AND iu.issue_meter_raw_data_id = rd.issue_meter_raw_data_id
		 	   	   AND iu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				UNION ALL
				-- METER DATA SOURCE
				SELECT iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   meter_monitor_pkg.GetDataSourceUrl(ds.issue_meter_data_source_id) url, 'View raw data' url_label, 
					   meter_monitor_pkg.GetDataSourceUrl(ds.issue_meter_data_source_id) parent_url, 'View raw data' parent_url_label, 
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu, issue_meter_data_source ds
				 WHERE iu.app_sid = ds.app_sid AND iu.issue_meter_data_source_id = ds.issue_meter_data_source_id
		 	   	   AND iu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				UNION ALL
				-- SUPPLIER
				SELECT iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   '/csr/site/chain/manageCompany/manageCompany.acds?companySid='||isup.company_sid url, 'View supplier' url_label, 
					   '/csr/site/chain/manageCompany/manageCompany.acds?companySid='||isup.company_sid parent_url, 'View supplier' parent_url_label, 
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu, issue_supplier isup
				 WHERE iu.app_sid = isup.app_sid AND iu.issue_supplier_id = isup.issue_supplier_id
		 	   	   AND iu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				UNION ALL
				-- AUDITS
				SELECT iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   audit_pkg.GetIssueAuditUrl(nc.created_in_audit_sid) url, 'View audit' url_label, 
					   audit_pkg.GetIssueAuditUrl(nc.created_in_audit_sid) parent_url, 'View audit' parent_url_label, 
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu
				  JOIN issue_non_compliance inc ON iu.issue_non_compliance_id = inc.issue_non_compliance_id AND iu.app_sid = inc.app_sid
				  JOIN non_compliance nc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
		 	   	 WHERE iu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				UNION ALL
				-- Everything else
				SELECT iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   source_url url, CASE WHEN source_url IS NOT NULL THEN 'View form' END url_label,
					   source_url parent_url, CASE WHEN source_url IS NOT NULL THEN 'View form' END parent_url_label,
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu
				 WHERE iu.issue_pending_val_id IS NULL
				   AND iu.issue_sheet_value_id IS NULL
				   AND iu.issue_meter_id IS NULL
				   AND iu.issue_meter_alarm_id IS NULL
				   AND iu.issue_meter_raw_data_id IS NULL
				   AND iu.issue_meter_data_source_id IS NULL
				   AND iu.issue_supplier_id IS NULL
				   AND iu.issue_non_compliance_id IS NULL
		 	   	   AND iu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			)
		 ORDER BY issue_id;
END;

PROCEDURE UNSEC_GetIssueRaiseAlerts(
	out_alert_cur					OUT	SYS_REFCURSOR,
	out_users_cur					OUT	SYS_REFCURSOR
)
AS
	t_app_sids						security.T_SID_TABLE;
BEGIN
	t_app_sids := alert_pkg.GetAppSidsForAlert(csr_data_pkg.ALERT_ISSUE_COMMENT);
	
	OPEN out_alert_cur FOR
		SELECT app_sid, issue_id, raised_by_user_sid, issue_comment
		  FROM issue_raise_alert
		 WHERE app_sid IN (SELECT /*+CARDINALITY(100)*/ column_value FROM TABLE (t_app_sids))
		 ORDER BY app_sid, issue_id;

	-- Needed when triggering automated issue alerts
	OPEN out_users_cur FOR	
		WITH issue_users AS (
			SELECT i.app_sid, i.issue_id, i.issue_pending_val_id, i.issue_sheet_value_id, i.issue_meter_id, 
				   i.issue_meter_alarm_id, i.issue_meter_raw_data_id, i.issue_meter_data_source_id,
				   i.issue_supplier_id, iiu.user_sid, iiu.is_an_owner, iiu.user_name, iiu.full_name, 
				   iiu.full_name friendly_name, -- need to change the component but I can't release by binaries atm
				   iiu.email, r.description region_description, i.label, i.source_label,
				   i.issue_non_compliance_id, issue_pkg.GetIssueUrl(i.issue_id) issue_url,
				   i.source_url, i.raised_dtm, i.due_dtm, i.issue_ref, au.full_name assigned_to, au.csr_user_sid assigned_to_user_sid, 
				   i.is_critical, it.label issue_type_label,
					CASE
						WHEN i.closed_dtm IS NOT NULL THEN 'Closed'
						WHEN i.resolved_dtm IS NOT NULL THEN 'Resolved'
						WHEN i.rejected_dtm IS NOT NULL THEN 'Rejected'
						ELSE 'Ongoing'
					 END issue_status, ip.due_date_offset priority_due_date_offset, ip.description priority_description
		  	  FROM issue i
		  	  JOIN (SELECT ii.app_sid, ii.issue_id, ii.is_an_owner, ii.from_role,
		  	  			   cu.csr_user_sid user_sid, cu.user_name, cu.full_name, cu.email
	  				  FROM (SELECT app_sid, issue_id, MAX(is_an_owner) is_an_owner,
								   MIN(from_role) from_role, user_sid
		  					  FROM (SELECT ii.app_sid, ii.issue_id, is_an_owner,
		  					  			   NVL(ii.user_sid, rrm.user_sid) user_sid,
			   							   CASE WHEN ii.role_sid IS NOT NULL THEN 1 ELSE 0 END from_role,
			   							   ia.raised_by_user_sid
		  							  FROM issue_involvement ii
		  							  JOIN issue i ON i.app_sid = ii.app_sid AND i.issue_id = ii.issue_id
		  							  JOIN issue_raise_alert ia ON i.app_sid = ia.app_sid AND i.issue_id = ia.issue_id
		  							  LEFT JOIN region_role_member rrm ON rrm.app_sid = i.app_sid
		  							   AND rrm.region_sid = i.region_sid AND rrm.role_sid = ii.role_sid
		 							 UNION
									SELECT ii.app_sid, ii.issue_id, ii.is_an_owner, rrm.user_sid, 1 from_role,
										   ia.raised_by_user_sid
		  							  FROM issue_involvement ii
		  							  JOIN issue i ON i.app_sid = ii.app_sid AND i.issue_id = ii.issue_id
		  							  JOIN issue_raise_alert ia ON i.app_sid = ia.app_sid AND i.issue_id = ia.issue_id
		  							  JOIN region_role_member rrm ON rrm.app_sid = i.app_sid
		  							   AND rrm.region_sid = i.region_2_sid AND rrm.role_sid = ii.role_sid)
						 	 WHERE raised_by_user_sid != user_sid		  					 
		  					 GROUP BY app_sid, issue_id, user_sid) ii
	  				  JOIN csr_user cu ON ii.app_sid = cu.app_sid AND ii.user_sid = cu.csr_user_sid AND cu.csr_user_sid != security.security_pkg.SID_BUILTIN_ADMINISTRATOR AND cu.send_alerts = 1
					  JOIN security.user_table ut on ut.sid_id = cu.csr_user_sid AND ut.account_enabled = 1) iiu
				ON i.app_sid = iiu.app_sid AND iiu.issue_id = i.issue_id
		  	  JOIN issue_type it ON i.app_sid = it.app_sid AND i.issue_type_id = it.issue_type_id
		  	  LEFT JOIN v$region r ON i.region_sid = r.region_sid AND i.app_sid = r.app_sid
		  	  LEFT JOIN csr_user au ON i.app_sid = au.app_sid AND i.assigned_to_user_sid = au.csr_user_sid
			  LEFT JOIN csr.issue_priority ip ON i.app_sid = ip.app_sid AND i.issue_priority_id = ip.issue_priority_id
			 WHERE (it.email_involved_roles = 1 OR iiu.from_role = 0)
			   AND (it.email_involved_users = 1 OR iiu.from_role = 1)
			   AND i.app_sid IN (SELECT /*+CARDINALITY(100)*/ column_value FROM TABLE (t_app_sids))
		)
		SELECT *
		  FROM (
				-- DELEGATIONS
				SELECT iu.app_sid, iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
						c.editing_url || sheet_pkg.GetSheetQueryString(isv.app_sid, isv.ind_sid, isv.region_sid, isv.start_dtm, isv.end_dtm, iu.user_sid)
					   || '#indSid='||isv.ind_Sid||',regionSid='||isv.region_sid url, null url_label,
					   c.editing_url || sheet_pkg.GetSheetQueryString(isv.app_sid, isv.ind_sid, isv.region_sid, isv.start_dtm, isv.end_dtm, iu.user_sid)
					   || '#indSid='||isv.ind_Sid||',regionSid='||isv.region_sid parent_url, 'View sheet' parent_url_label,
					    iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu, customer c, issue_sheet_value isv
				 WHERE iu.app_sid = c.app_sid
				   AND iu.app_sid = isv.app_sid AND iu.issue_sheet_value_id = isv.issue_sheet_value_id
				UNION ALL
				-- METER
				SELECT iu.app_sid, iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   meter_pkg.GetIssueMeterUrl(im.issue_meter_id) url, 'View meter data' url_label, 
					   meter_pkg.GetIssueMeterUrl(im.issue_meter_id) parent_url, 'View meter data' parent_url_label, 
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu, issue_meter im
				 WHERE iu.app_sid = im.app_sid AND iu.issue_meter_id = im.issue_meter_id
				UNION ALL
				-- METER ALARM
				SELECT iu.app_sid, iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   meter_alarm_pkg.GetAlarmUrl(ima.issue_meter_alarm_id) url, 'View meter data' url_label, 
					   meter_alarm_pkg.GetAlarmUrl(ima.issue_meter_alarm_id) parent_url, 'View meter data' parent_url_label, 
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu, issue_meter_alarm ima
				 WHERE iu.app_sid = ima.app_sid AND iu.issue_meter_alarm_id = ima.issue_meter_alarm_id
				UNION ALL
				-- METER RAW DATA
				SELECT iu.app_sid, iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   meter_monitor_pkg.GetRawDataUrl(rd.issue_meter_raw_data_id) url, 'View raw data' url_label, 
					   meter_monitor_pkg.GetRawDataUrl(rd.issue_meter_raw_data_id) parent_url, 'View raw data' parent_url_label, 
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu, issue_meter_raw_data rd
				 WHERE iu.app_sid = rd.app_sid AND iu.issue_meter_raw_data_id = rd.issue_meter_raw_data_id
				UNION ALL
				-- METER DATA SOURCE
				SELECT iu.app_sid, iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   meter_monitor_pkg.GetDataSourceUrl(ds.issue_meter_data_source_id) url, 'View raw data' url_label, 
					   meter_monitor_pkg.GetDataSourceUrl(ds.issue_meter_data_source_id) parent_url, 'View raw data' parent_url_label, 
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu, issue_meter_data_source ds
				 WHERE iu.app_sid = ds.app_sid AND iu.issue_meter_data_source_id = ds.issue_meter_data_source_id
				UNION ALL
				-- SUPPLIER
				SELECT iu.app_sid, iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   '/csr/site/chain/manageCompany/manageCompany.acds?companySid='||isup.company_sid url, 'View supplier' url_label, 
					   '/csr/site/chain/manageCompany/manageCompany.acds?companySid='||isup.company_sid parent_url, 'View supplier' parent_url_label, 
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu, issue_supplier isup
				 WHERE iu.app_sid = isup.app_sid AND iu.issue_supplier_id = isup.issue_supplier_id
				UNION ALL
				-- AUDITS
				SELECT iu.app_sid, iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   audit_pkg.GetIssueAuditUrl(nc.created_in_audit_sid) url, 'View audit' url_label, 
					   audit_pkg.GetIssueAuditUrl(nc.created_in_audit_sid) parent_url, 'View audit' parent_url_label, 
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu
				  JOIN issue_non_compliance inc ON iu.issue_non_compliance_id = inc.issue_non_compliance_id AND iu.app_sid = inc.app_sid
				  JOIN non_compliance nc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
				UNION ALL
				-- Everything else
				SELECT iu.app_sid, iu.issue_id, iu.user_sid, iu.is_an_owner, iu.user_name, iu.full_name, iu.friendly_name, iu.email,
					   source_url url, CASE WHEN source_url IS NOT NULL THEN 'View form' END url_label,
					   source_url parent_url, CASE WHEN source_url IS NOT NULL THEN 'View form' END parent_url_label,
					   iu.region_description, iu.label, iu.source_label, iu.issue_url,
					   iu.raised_dtm, iu.due_dtm, iu.issue_ref, iu.assigned_to, iu.assigned_to_user_sid, iu.is_critical, iu.issue_type_label, iu.issue_status, 
					   iu.priority_due_date_offset, iu.priority_description
				  FROM issue_users iu
				 WHERE iu.issue_pending_val_id IS NULL
				   AND iu.issue_sheet_value_id IS NULL
				   AND iu.issue_meter_id IS NULL
				   AND iu.issue_meter_alarm_id IS NULL
				   AND iu.issue_meter_raw_data_id IS NULL
				   AND iu.issue_meter_data_source_id IS NULL
				   AND iu.issue_supplier_id IS NULL
				   AND iu.issue_non_compliance_id IS NULL
			)
		 ORDER BY app_sid, issue_id;
END;

PROCEDURE UNSEC_MarkIssueRaiseAlertSent(
	in_app_sid						IN	issue_raise_alert.app_sid%TYPE,
	in_issue_id						IN	issue_raise_alert.issue_id%TYPE
)
AS
BEGIN
	DELETE FROM issue_raise_alert
	 WHERE app_sid = in_app_sid AND issue_id = in_issue_id;
	IF SQL%ROWCOUNT != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Missing issue_raise_alert row with sid '||in_app_sid||' and issue id '||in_issue_id);
	END IF;
	COMMIT;
END;

PROCEDURE UNSEC_SitesWithOverduePending(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT app_sid
		  FROM issue
		 WHERE due_dtm IS NOT NULL 
		   AND due_dtm < SYSDATE
		   AND notified_overdue = 0;
END;

PROCEDURE UNSEC_CallIssueOverdueHelpers
AS
BEGIN
	FOR r IN (
		SELECT i.issue_id, i.is_critical, it.allow_critical
		  FROM issue i
		  JOIN issue_type it 
			ON i.app_sid = it.app_sid 
		   AND i.issue_type_id = it.issue_type_id
		 WHERE due_dtm IS NOT NULL 
		   AND due_dtm < SYSDATE
		   AND notified_overdue = 0
		   FOR UPDATE OF i.notified_overdue
	) LOOP
		INTERNAL_CallHelperPkg('OnIssueOverdue', r.issue_id);

		IF r.allow_critical = 1 AND r.is_critical = 1 THEN
			INTERNAL_CallHelperPkg('OnCriticalIssueOverdue', r.issue_id);
		END IF;

		UPDATE issue 
		   SET notified_overdue = 1
		 WHERE issue_id = r.issue_id;
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
	v_ids				security.T_SID_TABLE := security.security_Pkg.SidArrayToTable(in_issue_ids);
BEGIN

	SELECT i.issue_id
	  BULK COLLECT INTO out_filtered_ids
	  FROM TABLE(v_ids) id
	  JOIN issue i ON i.issue_id = id.column_value
	 WHERE (in_filter_deleted = 0 OR deleted = 0)
	   AND (in_filter_closed = 0 OR closed_dtm IS NULL)
	   AND (in_filter_resolved = 0 OR resolved_dtm IS NULL)
	   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;


FUNCTION Sql_IsAccessAllowed(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_issue_id			IN	issue.issue_id%TYPE)
RETURN BINARY_INTEGER
AS
BEGIN
	IF IsAccessAllowed(in_act_id,in_issue_id) THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;	
END;

PROCEDURE SetupStandaloneIssueType
AS
	v_issue_type_id 			issue_type.issue_type_id%TYPE;
	v_cur						SYS_REFCURSOR;
	v_field_id					issue_custom_field_option.issue_custom_field_id%TYPE;
BEGIN

	SELECT issue_type_id
	  INTO v_issue_type_id
	  FROM issue_type
	 WHERE label = 'Action'
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	issue_pkg.SaveIssueType (
		in_issue_type_id				=> v_issue_type_id,
		in_label						=> 'Standalone Action',
		in_lookup_key					=> NULL,
		in_allow_children				=> 0,
		in_require_priority				=> 0,
		in_require_due_dtm_comment		=> 0,
		in_can_set_public				=> 0,
		in_public_by_default			=> 0,
		in_email_involved_roles			=> 1,
		in_email_involved_users			=> 1,
		in_restrict_users_to_region		=> 0,
		in_default_priority_id			=> NULL,
		in_alert_pending_due_days		=> 1,
		in_alert_overdue_days			=> NULL,
		in_auto_close_days				=> NULL,
		in_deletable_by_owner			=> 0,
		in_deletable_by_raiser			=> 1,
		in_deletable_by_administrator	=> 1,
		in_owner_can_be_changed			=> 1,
		in_show_forecast_dtm			=> 0,
		in_require_var_expl				=> 0,
		in_enable_reject_action			=> 0,
		in_snd_alrt_on_issue_raised		=> 1,
		in_show_one_issue_popup			=> 0,
		in_allow_owner_resolve_close	=> 1,
		in_is_region_editable			=> 1,
		in_enable_manual_comp_date		=> 0,
		in_comment_is_optional			=> 0,
		in_due_date_is_mandatory		=> 0,
		in_allow_critical				=> 0,
		in_allow_urgent_alert			=> 1,
		in_region_is_mandatory			=> 0,
		out_issue_type_id				=> v_issue_type_id
	);

	issue_pkg.SaveCustomField (
		in_field_id					=> NULL,
		in_issue_type_id			=> v_issue_type_id,
		in_field_type				=> 'O',
		in_label					=> 'Action Type',
		in_pos						=> NULL,
		in_is_mandatory				=> 1,
		in_restrict_to_group_sid	=> NULL,
		out_cur						=> v_cur
	);
	
	SELECT MAX(issue_custom_field_id)
	  INTO v_field_id
	  FROM issue_custom_field
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	issue_pkg.SaveCustomFieldOption (
		in_option_id				=> NULL,
		in_field_id					=> v_field_id,
		in_label					=> 'Information Request',
		out_cur						=> v_cur
	);
	issue_pkg.SaveCustomFieldOption (
		in_option_id				=> NULL,
		in_field_id					=> v_field_id,
		in_label					=> 'Corrective Action',
		out_cur						=> v_cur
	);
	issue_pkg.SaveCustomFieldOption (
		in_option_id				=> NULL,
		in_field_id					=> v_field_id,
		in_label					=> 'Preventative Action',
		out_cur						=> v_cur
	);
	issue_pkg.SaveCustomFieldOption (
		in_option_id				=> NULL,
		in_field_id					=> v_field_id,
		in_label					=> 'Sustainability Initiative Action',
		out_cur						=> v_cur
	);
	issue_pkg.SaveCustomFieldOption (
		in_option_id				=> NULL,
		in_field_id					=> v_field_id,
		in_label					=> 'System/Data Change Action',
		out_cur						=> v_cur
	);
END;

PROCEDURE UpdateIssues(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_ids				IN	security.security_pkg.T_SID_IDS,
	in_assigned_to_sid			IN  issue.assigned_to_user_sid%TYPE,
	in_comment					IN  issue.label%TYPE,
	in_involved_users			IN  security.security_pkg.T_SID_IDS,
	in_uninvolved_users			IN  security.security_pkg.T_SID_IDS,
	in_set_due_dtm				IN	NUMBER DEFAULT 0,
	in_due_dtm					IN	issue.due_dtm%TYPE,
	out_error_cur				OUT	SYS_REFCURSOR
)
AS
	out_user_cur				SYS_REFCURSOR;
	out_log_cur					SYS_REFCURSOR;
	out_action_cur				SYS_REFCURSOR;
	out_involve_user_cur 		SYS_REFCURSOR;
	out_due_cur					SYS_REFCURSOR;
	v_error        				VARCHAR2(4000);
	v_issue_id					issue.issue_id%TYPE;
	v_process_id   				VARCHAR2(38);
BEGIN
	IF csr_data_pkg.SQL_CheckCapability('Enable Actions Bulk Update') = 0 THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied actions bulk update');
	END IF;

	v_process_id := sys_guid();

	FOR i IN 1 .. in_issue_ids.COUNT LOOP
	 	BEGIN
			SAVEPOINT update_issue;
			v_error := NULL;
			v_issue_id := in_issue_ids(i);
			IF in_assigned_to_sid IS NOT NULL THEN
				AssignToUser(in_act_id, in_issue_ids(i), in_assigned_to_sid, in_comment, out_user_cur, out_log_cur, out_action_cur);
			END IF;
			
			FOR x IN 1 .. in_uninvolved_users.COUNT LOOP
				IF in_uninvolved_users(x) IS NOT NULL THEN
				RemoveUser(in_act_id, in_issue_ids(i), in_uninvolved_users(x));
				END IF;
			END LOOP;
			
			FOR j IN 1 .. in_involved_users.COUNT LOOP
				IF in_involved_users(j) IS NOT NULL THEN
					AddUser(in_act_id, in_issue_ids(i), in_involved_users(j), out_involve_user_cur);
				END IF;
			END LOOP;

			IF in_set_due_dtm != 0 THEN
				SetDueDtm(in_act_id, in_issue_ids(i), in_due_dtm, in_comment, out_due_cur, out_log_cur, out_action_cur);
			END IF;
		EXCEPTION
			 WHEN OTHERS THEN
			 v_error := SQLERRM;
			 ROLLBACK TO update_issue;
		END;

		IF v_error IS NOT NULL THEN
			INSERT INTO TT_UPDATE_ISSUES_ERROR VALUES (in_issue_ids(i), v_error);
		END IF;
				
	END LOOP;

	OPEN out_error_cur FOR
		SELECT issue_id, message
		  FROM TT_UPDATE_ISSUES_ERROR
		 ORDER BY issue_id;
END;

END issue_Pkg;
/
