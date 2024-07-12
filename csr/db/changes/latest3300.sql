define version=3300
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;

GRANT CREATE TABLE TO csr;
BEGIN
	FOR r IN (
		SELECT 1
		  FROM sys.all_indexes
		 WHERE owner = 'CSR' AND index_name = 'IX_CP_DETAILS_SEARCH'
		)
	LOOP
		EXECUTE IMMEDIATE 'DROP INDEX csr.IX_CP_DETAILS_SEARCH';
	END LOOP;
END;
/

ALTER TABLE csr.COMPLIANCE_PERMIT
DROP COLUMN DETAILS;
CREATE INDEX csr.IX_CP_ACTIVITY_DETAILS_SEARCH ON csr.COMPLIANCE_PERMIT(ACTIVITY_DETAILS) indextype is ctxsys.context;
REVOKE CREATE TABLE FROM csr;

DECLARE
BEGIN
	DBMS_SCHEDULER.SET_ATTRIBUTE (
			name			=> 'csr.compliance_permit_item_text',
			attribute		=> 'job_action',
			value			=> 'ctx_ddl.sync_index(''ix_cp_title_search'');
								ctx_ddl.sync_index(''ix_cp_reference_search'');
								ctx_ddl.sync_index(''ix_cp_activity_details_search'');'
			);
	DBMS_SCHEDULER.SET_ATTRIBUTE (
			name			=> 'csr.optimize_all_indexes',
			attribute		=> 'job_action',
			value			=> 'ctx_ddl.optimize_index(''ix_doc_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_doc_desc_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_file_upload_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_sh_val_note_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_help_body_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_qs_response_file_srch'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_qs_ans_ans_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_issue_log_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_issue_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_issue_desc_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_audit_label_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_audit_notes_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_non_comp_label_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_non_comp_detail_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_non_comp_rt_cse_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_section_body_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_section_title_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_ci_title_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_ci_summary_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_ci_details_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_ci_ref_code_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_ci_usr_comment_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_ci_citation_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_cp_title_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_cp_reference_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_cp_activity_details_search'', ctx_ddl.OPTLEVEL_FULL);'
			);
END;
/
GRANT CREATE TABLE TO csr;
DROP INDEX csr.IX_CP_ACTIVITY_DETAILS_SEARCH;
CREATE INDEX csr.IX_CP_ACTIVITY_DETAILS_SEARCH ON csr.COMPLIANCE_PERMIT(ACTIVITY_DETAILS) indextype is ctxsys.context 
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');
REVOKE CREATE TABLE FROM csr;
ALTER TABLE csr.batch_job_structure_import
ADD create_users_with_blank_pwd NUMBER(1, 0) DEFAULT 0;






CREATE OR REPLACE VIEW csr.v$issue AS
SELECT i.app_sid, NVL2(i.issue_ref, ist.internal_issue_ref_prefix || i.issue_ref, null) custom_issue_id, i.issue_id, i.label, i.description, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
	   i.issue_escalated, i.owner_role_sid, i.owner_user_sid, cuown.user_name owner_user_name, cuown.full_name owner_full_name, cuown.email owner_email,
	   r2.name owner_role_name, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
	   i.is_public, i.is_pending_assignment, i.rag_status_id, i.manual_completion_dtm, i.manual_comp_dtm_set_dtm, itrs.label rag_status_label, itrs.colour rag_status_colour,
	   i.raised_by_user_sid, i.raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
	   i.resolved_by_user_sid, i.resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
	   i.closed_by_user_sid, i.closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
	   i.rejected_by_user_sid, i.rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
	   i.assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
	   i.assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, 
	   c.more_info_1 correspondent_more_info_1, sysdate now_dtm, i.due_dtm, i.forecast_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, 
	   ist.allow_children, ist.can_set_public, ist.show_forecast_dtm, ist.require_var_expl, ist.enable_reject_action, ist.require_due_dtm_comment, 
	   ist.enable_manual_comp_date, ist.comment_is_optional, ist.due_date_is_mandatory, ist.is_region_editable is_issue_type_region_editable, i.issue_priority_id, 
	   ip.due_date_offset, ip.description priority_description,
	   CASE WHEN NVl(pi.issue_priority_id, i.issue_priority_id) IS NULL OR TRUNC(i.due_dtm) = TRUNC(NVL(pi.raised_dtm, i.raised_dtm) + NVL(pip.due_date_offset, ip.due_date_offset)) THEN 0 ELSE 1 END priority_overridden, 
	   i.first_priority_set_dtm, i.issue_pending_val_id, i.issue_sheet_value_id, i.issue_survey_answer_id, i.issue_non_compliance_Id, i.issue_action_id, i.issue_meter_id,
	   i.issue_meter_alarm_id, i.issue_meter_raw_data_id, i.issue_meter_data_source_id, i.issue_meter_missing_data_id, i.issue_supplier_id, i.issue_compliance_region_id,
	   CASE WHEN i.closed_by_user_sid IS NULL AND i.resolved_by_user_sid IS NULL AND i.rejected_by_user_sid IS NULL AND SYSDATE > NVL(i.forecast_dtm, i.due_dtm) THEN 1 ELSE 0
	   END is_overdue,
	   CASE WHEN rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID') OR i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0
	   END is_owner,
	   CASE WHEN i.assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0 --OR #### HOW + WHERE CAN I GET THE ROLES THE USER IS PART OF??
	   END is_assigned_to_you,
	   CASE WHEN i.resolved_dtm IS NULL AND i.manual_completion_dtm IS NULL THEN 0 ELSE 1
	   END is_resolved,
	   CASE WHEN i.closed_dtm IS NULL THEN 0 ELSE 1
	   END is_closed,
	   CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1
	   END is_rejected,
	   CASE
		WHEN i.closed_dtm IS NOT NULL THEN 'Closed'
		WHEN i.resolved_dtm IS NOT NULL THEN 'Resolved'
		WHEN i.rejected_dtm IS NOT NULL THEN 'Rejected'
		ELSE 'Ongoing'
	   END status,
	   CASE WHEN ist.auto_close_after_resolve_days IS NULL THEN NULL ELSE i.allow_auto_close END allow_auto_close, ist.auto_close_after_resolve_days,
	   ist.restrict_users_to_region, ist.deletable_by_administrator, ist.deletable_by_owner, ist.deletable_by_raiser, ist.send_alert_on_issue_raised,
	   ind.ind_sid, ind.description ind_name, isv.start_dtm, isv.end_dtm, ist.owner_can_be_changed, ist.show_one_issue_popup, ist.lookup_key, ist.allow_owner_resolve_and_close,
	   CASE WHEN ist.get_assignables_sp IS NULL THEN 0 ELSE 1 END get_assignables_overridden, ist.create_raw,
	   i.permit_id, i.issue_due_source_id, i.issue_due_offset_days, i.issue_due_offset_months, i.issue_due_offset_years, ids.source_description due_dtm_source_description,
	   CASE WHEN EXISTS(SELECT * 
						  FROM issue_due_source ids
						 WHERE ids.app_sid = i.app_sid 
						   AND ids.issue_type_id = i.issue_type_id)
			THEN 1 ELSE 0
	   END relative_due_dtm_enabled,
	   i.is_critical, ist.allow_critical, ist.allow_urgent_alert
  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, csr_user cuown,  role r, role r2, correspondent c, issue_priority ip,
	   (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm, v$region re, issue_log lil, v$issue_type_rag_status itrs,
	   v$ind ind, issue_sheet_value isv, issue_due_source ids, issue pi, issue_priority pip
 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+)
   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
   AND i.app_sid = curej.app_sid(+) AND i.rejected_by_user_sid = curej.csr_user_sid(+)
   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+)
   AND i.app_sid = cuown.app_sid(+) AND i.owner_user_sid = cuown.csr_user_sid(+)
   AND i.app_sid = r.app_sid(+) AND i.assigned_to_role_sid = r.role_sid(+)
   AND i.app_sid = r2.app_sid(+) AND i.owner_role_sid = r2.role_sid(+)
   AND i.app_sid = re.app_sid(+) AND i.region_sid = re.region_sid(+)
   AND i.app_sid = c.app_sid(+) AND i.correspondent_id = c.correspondent_id(+)
   AND i.app_sid = ip.app_sid(+) AND i.issue_priority_id = ip.issue_priority_id(+)
   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+)
   AND i.app_sid = lil.app_sid(+) AND i.last_issue_log_id = lil.issue_log_id(+)
   AND i.app_sid = itrs.app_sid(+) AND i.rag_status_id = itrs.rag_status_id(+) AND i.issue_type_id = itrs.issue_type_id(+)
   AND i.app_sid = isv.app_sid(+) AND i.issue_sheet_value_id = isv.issue_sheet_value_id(+)
   AND isv.app_sid = ind.app_sid(+) AND isv.ind_sid = ind.ind_sid(+)
   AND i.app_sid = ids.app_sid(+) AND i.issue_due_source_id = ids.issue_due_source_id(+)
   AND i.app_sid = pi.app_sid(+) AND i.parent_id = pi.issue_id(+) 
   AND pi.app_sid = pip.app_sid(+) AND pi.issue_priority_id = pip.issue_priority_id(+)
   AND i.deleted = 0;




DECLARE
	v_act					security.security_pkg.T_ACT_ID;
	v_sid					security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id in (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		-- Somehow some sites don't have this web resource... So try creating it (again) first.
		BEGIN
			security.web_pkg.CreateResource(v_act, r.web_root_sid_id, r.web_root_sid_id, 'api.tenants', v_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_sid := security.securableObject_pkg.GetSIDFromPath(v_act, r.web_root_sid_id, 'api.tenants');
		END;
		security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, security.securableObject_pkg.GetSIDFromPath(v_act, 0, '//BuiltIn/Administrators'), security.security_pkg.PERMISSION_STANDARD_READ);
	END LOOP;
END;
/


 




@..\permit_pkg
@..\permit_data_import_pkg
@..\chain\company_pkg
@..\structure_import_pkg


@..\permit_body
@..\permit_data_import_body
@..\permit_report_body
@..\schema_body
@..\csrimp\imp_body
@..\dataview_body
@..\region_report_body
@..\chain\company_body
@..\integration_api_body
@..\structure_import_body



@update_tail
