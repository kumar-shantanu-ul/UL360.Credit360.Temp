CREATE OR REPLACE VIEW csr.v$customer_lang AS
	SELECT ts.lang
	  FROM aspen2.translation_set ts
	 WHERE ts.application_sid = SYS_CONTEXT('SECURITY', 'APP')
	 UNION
	SELECT 'en' -- ensure english is present
	  FROM DUAL;

create or replace view csr.v$ind as
	select i.app_sid, i.ind_sid, i.parent_sid, i.name, id.description, i.ind_type, i.tolerance_type,
		   i.pct_upper_tolerance, i.pct_lower_tolerance, 
		   i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
		   i.measure_sid, i.multiplier, i.scale,
		   i.format_mask, i.last_modified_dtm, i.active, i.target_direction, i.pos, i.info_xml,
		   i.start_month, i.divisibility, i.null_means_null, i.aggregate, i.period_set_id, i.period_interval_id,
		   i.calc_start_dtm_adjustment, i.calc_end_dtm_adjustment, i.calc_fixed_start_dtm,
		   i.calc_fixed_end_dtm, i.calc_xml, i.gri, i.lookup_key, i.owner_sid,
		   i.ind_activity_type_id, i.core, i.roll_forward, i.factor_type_id, i.map_to_ind_sid,
		   i.gas_measure_sid, i.gas_type_id, i.calc_description, i.normalize,
		   i.do_temporal_aggregation, i.prop_down_region_tree_sid, i.is_system_managed,
		   i.calc_output_round_dp
	  from ind i, ind_description id
	 where id.app_sid = i.app_sid and i.ind_sid = id.ind_sid
	   and id.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

create or replace view csr.v$delegation_ind as
	select di.app_sid, di.delegation_sid, di.ind_sid, di.mandatory, NVL(did.description, id.description) description,
		   di.pos, di.section_key, di.var_expl_group_id, di.visibility, di.css_class, di.allowed_na
	  from delegation_ind di
	  join ind_description id
	    on di.app_sid = id.app_sid and di.ind_sid = id.ind_sid
	   and id.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  left join delegation_ind_description did
	    on di.app_sid = did.app_sid AND di.delegation_sid = did.delegation_sid
	   and di.ind_sid = did.ind_sid AND did.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

create or replace view csr.v$region as
	select r.app_sid, r.region_sid, r.link_to_region_sid, r.parent_sid, r.name, rd.description, r.active,
		   r.pos, r.info_xml, r.flag, r.acquisition_dtm, r.disposal_dtm, r.region_type,
		   r.lookup_key, r.geo_country, r.geo_region, r.geo_city_id, r.geo_longitude, r.geo_latitude,
		   r.geo_type, r.map_entity, r.egrid_ref, r.egrid_ref_overridden, r.last_modified_dtm, r.region_ref
	  from region r, region_description rd
	 where r.app_sid = rd.app_sid and r.region_sid = rd.region_sid
	   and rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

create or replace view csr.v$delegation_region as
	select dr.app_sid, dr.delegation_sid, dr.region_sid, dr.mandatory, NVL(drd.description, rd.description) description,
		   dr.pos, dr.aggregate_to_region_sid, dr.visibility, dr.allowed_na, dr.hide_after_dtm, dr.hide_inclusive
	  from delegation_region dr
	  join region_description rd
	    on dr.app_sid = rd.app_sid and dr.region_sid = rd.region_sid
	   and rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  left join delegation_region_description drd
	    on dr.app_sid = drd.app_sid AND dr.delegation_sid = drd.delegation_sid
	   and dr.region_sid = drd.region_sid AND drd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

-- View intended to provide delegation and the correct description for the current language.
CREATE OR REPLACE VIEW csr.v$delegation AS
	SELECT d.app_sid, d.delegation_sid, d.parent_sid, d.name, d.master_delegation_sid, d.created_by_sid, d.schedule_xml, d.note, d.group_by, d.allocate_users_to, d.start_dtm, d.end_dtm, d.reminder_offset,
		   d.is_note_mandatory, d.section_xml, d.editing_url, d.fully_delegated, d.grid_xml, d.is_flag_mandatory, d.show_aggregate, d.hide_sheet_period, d.delegation_date_schedule_id, d.layout_id,
		   d.tag_visibility_matrix_group_id, d.period_set_id, d.period_interval_id, d.submission_offset, d.allow_multi_period, nvl(dd.description, d.name) as description, dp.submit_confirmation_text as delegation_policy
	  FROM csr.delegation d
    LEFT JOIN csr.delegation_description dd ON dd.app_sid = d.app_sid
     AND dd.delegation_sid = d.delegation_sid
	 AND dd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
    LEFT JOIN CSR.DELEGATION_POLICY dp ON dp.app_sid = d.app_sid
     AND dp.delegation_sid = d.delegation_sid;

CREATE OR REPLACE VIEW CSR.V$TAG_GROUP AS
	SELECT tg.app_sid, tg.tag_group_id, NVL(tgd.name, tgden.name) name,
		tg.multi_select, tg.mandatory, tg.applies_to_inds,
		tg.applies_to_regions, tg.applies_to_non_compliances, tg.applies_to_suppliers,
		tg.applies_to_initiatives, tg.applies_to_chain, tg.applies_to_chain_activities,
		tg.applies_to_chain_product_types, tg.applies_to_chain_products, tg.applies_to_chain_product_supps,
		tg.applies_to_quick_survey, tg.applies_to_audits,
		tg.applies_to_compliances, tg.lookup_key, tg.is_hierarchical
	  FROM csr.tag_group tg
	LEFT JOIN csr.tag_group_description tgd ON tgd.app_sid = tg.app_sid AND tgd.tag_group_id = tg.tag_group_id AND tgd.lang = SYS_CONTEXT('SECURITY', 'LANGUAGE')
	LEFT JOIN csr.tag_group_description tgden ON tgden.app_sid = tg.app_sid AND tgden.tag_group_id = tg.tag_group_id AND tgden.lang = 'en';

CREATE OR REPLACE VIEW CSR.V$TAG AS
	SELECT t.app_sid, t.tag_id, NVL(td.tag, tden.tag) tag, NVL(td.explanation, tden.explanation) explanation,
		t.lookup_key, t.exclude_from_dataview_grouping, t.parent_id
	  FROM csr.tag t
	LEFT JOIN csr.tag_description td ON td.app_sid = t.app_sid AND td.tag_id = t.tag_id AND td.lang = SYS_CONTEXT('SECURITY', 'LANGUAGE')
	LEFT JOIN csr.tag_description tden ON tden.app_sid = t.app_sid AND tden.tag_id = t.tag_id AND tden.lang = 'en';

CREATE OR REPLACE VIEW csr.tag_group_ir_member AS
  -- get region tags
  SELECT tgm.tag_group_id, tgm.pos, t.tag_id, t.tag, region_sid, null ind_sid, null non_compliance_id
    FROM tag_group_member tgm, v$tag t, region_tag rt
   WHERE tgm.tag_id = t.tag_id
     AND rt.tag_id = t.tag_id
  UNION ALL
  -- get indicator tags
  SELECT tgm.tag_group_id, tgm.pos, t.tag_id,t.tag, null region_sid, it.ind_sid ind_sid, null non_compliance_id
    FROM tag_group_member tgm, v$tag t, ind_tag it
   WHERE tgm.tag_id = t.tag_id
     AND it.tag_id = t.tag_id
  UNION ALL
 -- get non compliance tags
  SELECT tgm.tag_group_id, tgm.pos, t.tag_id, t.tag, null region_sid, null ind_sid, nct.non_compliance_id
    FROM tag_group_member tgm, v$tag t, non_compliance_tag nct
   WHERE tgm.tag_id = t.tag_id
     AND nct.tag_id = t.tag_id;

create or replace view csr.imp_val_mapped
	(ind_description, region_description, ind_sid, region_sid, imp_ind_description, imp_region_description,
	 imp_val_id, imp_ind_id, imp_region_id, unknown, start_dtm, end_dtm, val, file_sid, imp_session_sid,
	 set_val_id, imp_measure_id, tolerance_type, pct_upper_tolerance, pct_lower_tolerance, note, lookup_key, region_ref,
	 map_entity, roll_forward, acquisition_dtm, a, b, c, calc_description, normalize, do_temporal_aggregation) as
	select i.description, r.description, i.ind_sid, r.region_sid, ii.description, ir.description, iv.imp_val_id,
	       iv.imp_ind_id, iv.imp_region_id, iv.unknown, iv.start_dtm, iv.end_dtm, iv.val, iv.file_sid, iv.imp_session_sid,
	       iv.set_val_id, iv.imp_measure_id, i.tolerance_type, i.pct_upper_tolerance, i.pct_lower_tolerance, iv.note,
	       r.lookup_key, r.region_ref, r.map_entity, i.roll_forward, r.acquisition_dtm, iv.a, iv.b, iv.c, i.calc_description,
	       i.normalize, i.do_temporal_aggregation
	  from imp_val iv, imp_ind ii, imp_region ir, v$ind i, v$region r
	 where iv.app_sid = ii.app_sid and iv.imp_ind_id = ii.imp_ind_id
	   and iv.app_sid = ir.app_sid and iv.imp_region_id = ir.imp_region_id
	   and ii.app_sid = i.app_sid and ii.maps_to_ind_sid = i.ind_sid
	   and ir.app_sid = r.app_sid and ir.maps_to_region_sid = r.region_sid;


-- using this view ignores any percentage ownership that was applied when the
-- value was originally saved

CREATE OR REPLACE VIEW csr.val_converted (
	app_sid, val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number,
	error_code, alert, flags, source_id, entry_measure_conversion_id, entry_val_number,
	note, source_type_id, factor_a, factor_b, factor_c, changed_by_sid, changed_dtm
) AS
	SELECT v.app_sid, v.val_id, v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm,
	       -- we derive val_number from entry_val_number in case of pct_ownership
	       -- we round the value to avoid Arithmetic Overflows from converting Oracle Decimals to .NET Decimals
		   ROUND(COALESCE(mc.a, mcp.a, 1) * POWER(v.entry_val_number, COALESCE(mc.b, mcp.b, 1)) + COALESCE(mc.c, mcp.c, 0), 10) val_number,
		   v.error_code,
		   v.alert, v.flags, v.source_id,
		   v.entry_measure_conversion_id, v.entry_val_number,
		   v.note, v.source_type_id,
		   NVL(mc.a, mcp.a) factor_a,
		   NVL(mc.b, mcp.b) factor_b,
		   NVL(mc.c, mcp.c) factor_c,
		   v.changed_by_sid, v.changed_dtm
	  FROM val v, measure_conversion mc, measure_conversion_period mcp
	 WHERE mc.measure_conversion_id = mcp.measure_conversion_id(+)
	   AND v.entry_measure_conversion_id = mc.measure_conversion_id(+)
	   AND (v.period_start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
	   AND (v.period_start_dtm < mcp.end_dtm or mcp.end_dtm is null);

-- using this view ignores any percentage ownership that was applied when the
-- value was originally saved
CREATE OR REPLACE FORCE VIEW csr.sheet_value_converted
	(app_sid, sheet_value_id, sheet_id, ind_sid, region_sid, val_number, set_by_user_sid,
	 set_dtm, note, entry_measure_conversion_id, entry_val_number, is_inherited,
	 status, last_sheet_value_change_id, alert, flag, factor_a, factor_b, factor_c,
	 start_dtm, end_dtm, actual_val_number, var_expl_note, is_na) AS
  SELECT sv.app_sid, sv.sheet_value_id, sv.sheet_id, sv.ind_sid, sv.region_sid,
	       -- we derive val_number from entry_val_number in case of pct_ownership
	       -- we round the value to avoid Arithmetic Overflows from converting Oracle Decimals to .NET Decimals
		 ROUND(COALESCE(mc.a, mcp.a, 1) * POWER(sv.entry_val_number, COALESCE(mc.b, mcp.b, 1)) + COALESCE(mc.c, mcp.c, 0), 10) val_number,
         sv.set_by_user_sid, sv.set_dtm, sv.note,
         sv.entry_measure_conversion_id, sv.entry_val_number,
         sv.is_inherited, sv.status, sv.last_sheet_value_change_id,
         sv.alert, sv.flag,
         NVL(mc.a, mcp.a) factor_a,
         NVL(mc.b, mcp.b) factor_b,
         NVL(mc.c, mcp.c) factor_c,
         s.start_dtm, s.end_dtm, sv.val_number actual_val_number, var_expl_note,
		 sv.is_na
    FROM sheet_value sv, sheet s, measure_conversion mc, measure_conversion_period mcp
   WHERE sv.app_sid = s.app_sid
     AND sv.sheet_id = s.sheet_id
     AND sv.app_sid = mc.app_sid(+)
     AND sv.entry_measure_conversion_id = mc.measure_conversion_id(+)
     AND mc.app_sid = mcp.app_sid(+)
     AND mc.measure_conversion_id = mcp.measure_conversion_id(+)
     AND (s.start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
     AND (s.start_dtm < mcp.end_dtm or mcp.end_dtm is null)
;

CREATE OR REPLACE FORCE VIEW csr.PENDING_VAL_CONVERTED (
	pending_val_id, pending_ind_id, pending_region_id, pending_period_id, approval_step_id,
	 val_number, val_string, from_val_number, from_measure_conversion_id, action,
	 factor_a, factor_b, factor_c, start_dtm, end_dtm, actual_val_number
) AS
  SELECT pending_val_id, pending_ind_id, pending_region_id, pv.pending_period_id, approval_step_id,
	     COALESCE(mc.a, mcp.a, 1) * POWER(pv.from_val_number, COALESCE(mc.b, mcp.b, 1)) + COALESCE(mc.c, mcp.c, 0) val_number,
		val_string,
		from_val_number,
		from_measure_conversion_id,
		action,
	    NVL(mc.a, mcp.a) factor_a,
	    NVL(mc.b, mcp.b) factor_b,
	    NVL(mc.c, mcp.c) factor_c,
	    pp.start_dtm,
	    pp.end_dtm,
	    pv.val_number actual_val_number
    FROM pending_val pv, pending_period pp, measure_conversion mc, measure_conversion_period mcp
   WHERE pp.pending_period_id = pv.pending_period_id
     AND pv.from_measure_conversion_id = mc.measure_conversion_id(+)
     AND mc.measure_conversion_id = mcp.measure_conversion_id(+)
     AND (pp.start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
     AND (pp.start_dtm < mcp.end_dtm or mcp.end_dtm is null);

CREATE OR REPLACE VIEW csr.V$ACTIVE_USER AS
	SELECT cu.csr_user_sid, cu.email, cu.app_sid, cu.full_name,
	  	   cu.user_name, cu.info_xml, cu.send_alerts, cu.guid, cu.friendly_name,
	  	   ut.language, ut.culture, ut.timezone
	  FROM csr_user cu, security.user_table ut
	 WHERE cu.csr_user_sid = ut.sid_id
	   AND ut.account_enabled = 1;

CREATE OR REPLACE VIEW csr.V$MY_USER AS
  SELECT ut.account_enabled, CASE WHEN cu.line_manager_sid = SYS_CONTEXT('SECURITY','SID') THEN 1 ELSE 0 END is_direct_report,
		 cu.app_sid, cu.csr_user_sid, cu.email, cu.guid, cu.full_name, cu.user_name,
		 cu.friendly_name, cu.info_xml, cu.send_alerts, cu.show_portal_help, cu.donations_reports_filter_id,
		 cu.donations_browse_filter_id, cu.hidden, cu.phone_number, cu.job_title, cu.show_save_chart_warning,
		 cu.enable_aria, cu.created_dtm, cu.line_manager_sid, cu.last_modified_dtm, cu.last_logon_type_id, cu.avatar,
		 cu.avatar_last_modified_dtm, cu.avatar_sha1, cu.avatar_mime_type, cu.primary_region_sid
    FROM csr.csr_user cu
    JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
   START WITH cu.line_manager_sid = SYS_CONTEXT('SECURITY','SID')
  CONNECT BY PRIOR cu.csr_user_sid = cu.line_manager_sid;


CREATE OR REPLACE VIEW csr.audit_val_log AS
	SELECT changed_dtm audit_date, r.app_sid, 6 audit_type_id, vc.ind_sid object_sid, changed_by_sid user_sid,
	 	   'Set "{0}" ("{1}") to {2}: '||reason description, i.description param_1, r.description param_2, val_number param_3
	  FROM val_change vc, v$region r, v$ind i
	 WHERE vc.app_sid = r.app_sid AND vc.region_sid = r.region_sid
	   AND vc.app_sid = i.app_sid AND vc.ind_sid = i.ind_sid AND i.app_sid = r.app_sid;


/* ISSUES */
CREATE OR REPLACE VIEW csr.v$issue_pending AS
	SELECT i.app_sid, v.pending_region_id, v.pending_ind_id,
		   p.approval_step_id, i.issue_id, i.resolved_dtm
	  FROM issue_pending_val v,
			(SELECT aps.app_sid, aps.approval_step_id, p.pending_period_id
			   FROM approval_step aps, pending_period p
			  WHERE aps.app_sid = p.app_sid AND aps.pending_dataset_id = p.pending_dataset_id) p,
			issue i
	 WHERE p.app_sid = v.app_sid
	   AND p.pending_period_id = v.pending_period_id
	   AND i.issue_pending_val_id = v.issue_pending_val_id
	   AND i.deleted = 0;

CREATE OR REPLACE VIEW csr.v$issue_involved_user AS
	SELECT ii.app_sid, ii.issue_id, MAX(ii.is_an_owner) is_an_owner, cu.csr_user_sid user_sid, cu.user_name,
		   cu.full_name, cu.email, MIN(ii.from_role) from_role
	  FROM (
		SELECT ii.app_sid, ii.issue_id, is_an_owner, NVL(ii.user_sid, rrm.user_sid) user_sid,
			   CASE WHEN ii.role_sid IS NOT NULL THEN 1 ELSE 0 END from_role
		  FROM issue_involvement ii
		  JOIN issue i
			ON i.app_sid = ii.app_sid
		   AND i.issue_id = ii.issue_id
		  LEFT JOIN region_role_member rrm
			ON rrm.app_sid = i.app_sid
		   AND rrm.region_sid = i.region_sid
		   AND rrm.role_sid = ii.role_sid
		 UNION
		SELECT ii.app_sid, ii.issue_id, ii.is_an_owner, rrm.user_sid, 1 from_role
		  FROM issue_involvement ii
		  JOIN issue i
			ON i.app_sid = ii.app_sid
		   AND i.issue_id = ii.issue_id
		  JOIN region_role_member rrm
			ON rrm.app_sid = i.app_sid
		   AND rrm.region_sid = i.region_2_sid
		   AND rrm.role_sid = ii.role_sid
		) ii
	  JOIN csr_user cu ON ii.app_sid = cu.app_sid AND ii.user_sid = cu.csr_user_sid AND cu.csr_user_sid != 3
	 GROUP BY ii.app_sid, ii.issue_id, cu.csr_user_sid, cu.user_name, cu.full_name, cu.email;

CREATE OR REPLACE VIEW csr.v$issue_user AS
	SELECT ii.app_sid, ii.issue_id, user_sid, MIN(ii.from_role) from_role
	  FROM (
		SELECT ii.app_sid, ii.issue_id, NVL(ii.user_sid, rrm.user_sid) user_sid,
			   CASE WHEN ii.role_sid IS NOT NULL THEN 1 ELSE 0 END from_role
		  FROM issue_involvement ii
		  JOIN issue i
			ON i.app_sid = ii.app_sid
		   AND i.issue_id = ii.issue_id
		  LEFT JOIN region_role_member rrm
			ON rrm.app_sid = i.app_sid
		   AND rrm.region_sid = i.region_sid
		   AND rrm.role_sid = ii.role_sid
		 UNION
		SELECT ii.app_sid, ii.issue_id, rrm.user_sid, 1 from_role
		  FROM issue_involvement ii
		  JOIN issue i ON i.app_sid = ii.app_sid AND i.issue_id = ii.issue_id
		  JOIN region_role_member rrm
			ON rrm.app_sid = i.app_sid
		   AND rrm.region_sid = i.region_2_sid
		   AND rrm.role_sid = ii.role_sid
		 UNION
		SELECT i.app_sid, i.issue_id, rrm.user_sid, 1 from_role
		  FROM issue i
		  JOIN region_role_member rrm ON rrm.app_sid = i.app_sid AND rrm.region_sid = i.region_sid AND rrm.role_sid = i.assigned_to_role_sid
		) ii
	  JOIN csr_user cu ON ii.app_sid = cu.app_sid AND ii.user_sid = cu.csr_user_sid AND cu.csr_user_sid != 3
	 GROUP BY ii.app_sid, ii.issue_id, ii.user_sid;

CREATE OR REPLACE VIEW csr.v$simple_issue AS
	SELECT i.app_sid, i.issue_id, i.label, i.source_label, i.is_visible, i.source_url, i.region_sid, i.parent_id, i.is_critical,
	   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND rejected_by_user_sid IS NULL AND SYSDATE > due_dtm THEN 1 ELSE 0
	   END is_overdue,
	   CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1
	   END is_resolved,
	   CASE WHEN i.closed_dtm IS NULL THEN 0 ELSE 1
	   END is_closed,
	   CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1
	   END is_rejected
  FROM issue i;


CREATE OR REPLACE VIEW csr.V$issue_type_rag_status AS
    SELECT itrs.app_sid, itrs.issue_type_id, itrs.rag_status_id, itrs.pos, irs.colour, irs.label, irs.lookup_key
      FROM issue_type_rag_status itrs
      JOIN rag_status irs ON itrs.rag_status_id = irs.rag_status_id AND itrs.app_sid = irs.app_sid;

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

CREATE OR REPLACE VIEW csr.v$issue_log AS
	SELECT il.app_sid, il.issue_log_id, il.issue_Id, il.message, il.logged_by_user_sid,
		   cu.user_name logged_by_user_name, cu.email logged_by_email, il.logged_dtm,
		   il.is_system_generated, param_1, param_2, param_3, sysdate now_dtm,
		   CASE WHEN il.logged_by_user_sid IS NULL THEN 0 ELSE 1 END is_user,
		   CASE WHEN il.logged_by_user_sid IS NULL THEN ilc.full_name ELSE cu.full_name END logged_by_full_name
	  FROM issue_log il
	  LEFT JOIN csr_user cu ON il.app_sid = cu.app_sid AND il.logged_by_user_sid = cu.csr_user_sid
	  LEFT JOIN correspondent ilc ON il.logged_by_correspondent_id = ilc.correspondent_id
;

CREATE OR REPLACE VIEW csr.v$postit AS
    SELECT p.app_sid, p.postit_id, p.message, p.label, p.secured_via_sid, p.created_dtm, p.created_by_sid,
        pu.user_name created_by_user_name, pu.full_name created_by_full_name, pu.email created_by_email,
		CASE WHEN p.created_by_sid = SYS_CONTEXT('SECURITY','SID') THEN 1
			 WHEN p.created_by_sid = 3 -- 3 == security.security_pkg.SID_BUILTIN_ADMINISTRATOR, but we can't use that here
			 THEN security.security_pkg.SQL_IsAccessAllowedSID(security_pkg.getACT, p.secured_via_sid, 2) -- 2 == security.security_pkg.PERMISSION_WRITE, ditto
			 ELSE 0 END can_edit
      FROM postit p
        JOIN csr_user pu ON p.created_by_sid = pu.csr_user_sid AND p.app_sid = pu.app_sid;

CREATE OR REPLACE VIEW csr.v$doc_current AS
	SELECT dc.parent_sid, dc.doc_id, dc.locked_by_sid, dc.pending_version,
		   df.lifespan,
		   dv.version, dv.filename, dv.description, dv.change_description, dv.changed_by_sid, dv.changed_dtm,
		   dd.doc_data_id, dd.data, dd.sha1, dd.mime_type, dt.doc_type_id, dt.name doc_type_name
	  FROM doc_current dc
		JOIN doc_folder df ON dc.parent_sid = df.doc_folder_sid
		LEFT JOIN doc_version dv ON dc.doc_id = dv.doc_id AND dc.version = dv.version
		LEFT JOIN doc_data dd ON dv.doc_data_id = dd.doc_data_id
		LEFT JOIN doc_type dt ON dt.doc_type_id = dv.doc_type_id;


CREATE OR REPLACE VIEW csr.v$doc_approved AS
	SELECT dc.parent_sid, dc.doc_id, dc.locked_by_sid, dc.pending_version,
		   dc.version,
		   df.lifespan,
		   dv.filename, dv.description, dv.change_description, dv.changed_by_sid, dv.changed_dtm,
		   dd.sha1, dd.mime_type, dd.data, dd.doc_data_id,
		   CASE WHEN dc.locked_by_sid = SYS_CONTEXT('SECURITY','SID') THEN 1 ELSE 0 END locked_by_me,
		   CASE
				WHEN df.lifespan IS NULL THEN 0
				WHEN SYSDATE > ADD_MONTHS(dv.changed_dtm, df.lifespan) THEN 2 -- csr_data_pkg.DOCLIB_EXPIRED
				WHEN SYSDATE > ADD_MONTHS(dv.changed_dtm, df.lifespan - 1) THEN 1 -- csr_data_pkg.DOCLIB_NEARLY_EXPIRED
				ELSE 0
		   END expiry_status,
		   dd.app_sid, dt.doc_type_id, dt.name doc_type_name
	  FROM doc_current dc
		JOIN doc_folder df ON dc.parent_sid = df.doc_folder_sid
		LEFT JOIN doc_version dv ON dc.doc_id = dv.doc_id AND dc.version = dv.version
		LEFT JOIN doc_data dd ON dv.doc_data_id = dd.doc_data_id
		LEFT JOIN doc_type dt ON dt.doc_type_id = dv.doc_type_id
		-- don't return stuff that's added but never approved
	   WHERE dc.version IS NOT NULL;

-- right -> show the user pending stuff IF:
--   * locked_by_sid => is this user
--   * show filename etc of pending file (but null version) if dc.version is null
CREATE OR REPLACE VIEW csr.v$doc_current_status AS
	SELECT parent_sid, doc_id, locked_by_sid, pending_version,
		version, lifespan,
		filename, description, change_description, changed_by_sid, changed_dtm,
		sha1, mime_type, data, doc_data_id,
		locked_by_me, expiry_status, doc_type_id, doc_type_name
	  FROM v$doc_approved
	   WHERE NVL(locked_by_sid,-1) != SYS_CONTEXT('SECURITY','SID') OR pending_version IS NULL
	   UNION ALL
	SELECT dc.parent_sid, dc.doc_id, dc.locked_by_sid, dc.pending_version,
			-- if it's the approver then show them the right version, otherwise pass through null (i.e. dc.version) to other users so they can't fiddle
		   CASE WHEN NVL(dc.locked_by_sid,-1) = SYS_CONTEXT('SECURITY','SID') AND dc.pending_version IS NOT NULL THEN dc.pending_version ELSE dc.version END version,
		   df.lifespan,
		   dvp.filename, dvp.description, dvp.change_description, dvp.changed_by_sid, dvp.changed_dtm,
		   ddp.sha1, ddp.mime_type, ddp.data, ddp.doc_data_id,
		   CASE WHEN dc.locked_by_sid = SYS_CONTEXT('SECURITY','SID') THEN 1 ELSE 0 END locked_by_me,
		   CASE
				WHEN df.lifespan IS NULL THEN 0
				WHEN SYSDATE > ADD_MONTHS(dvp.changed_dtm, df.lifespan) THEN 2 -- csr_data_pkg.DOCLIB_EXPIRED
				WHEN SYSDATE > ADD_MONTHS(dvp.changed_dtm, df.lifespan - 1) THEN 1 -- csr_data_pkg.DOCLIB_NEARLY_EXPIRED
				ELSE 0
		   END expiry_status, 
		   dt.doc_type_id, dt.name doc_type_name
	  FROM doc_current dc
		JOIN doc_folder df ON dc.parent_sid = df.doc_folder_sid
		LEFT JOIN doc_version dvp ON dc.doc_id = dvp.doc_id AND dc.pending_version = dvp.version
		LEFT JOIN doc_data ddp ON dvp.doc_data_id = ddp.doc_data_id
		LEFT JOIN doc_type dt ON dt.doc_type_id = dvp.doc_type_id
	   WHERE (NVL(dc.locked_by_sid,-1) = SYS_CONTEXT('SECURITY','SID') AND dc.pending_version IS NOT NULL) OR dc.version IS null;

create or replace view csr.v$doc_folder_root as
	select dl.doc_library_sid, dl.documents_sid, dl.trash_folder_sid, t.sid_id doc_folder_sid from (
		select connect_by_root sid_id doc_library_sid, so.sid_id
	  	  from security.securable_object so
	           start with sid_id in (select doc_library_sid from doc_library dl)
	       	   connect by prior sid_id = parent_sid_id) t, doc_library dl
     where t.doc_library_sid = dl.doc_library_sid;


-- provides more human readable information about pvc_stored_calc_jobs
create or replace view csr.v$pvc_stored_calc_job as
	select c.host, pi.description ind_description, pr.description region_description, pp.start_dtm, pp.end_dtm, processing, pi.pending_ind_id, pr.pending_region_id, pp.pending_period_id
	  from pvc_stored_calc_job cirj, pending_dataset pd, customer c, pending_ind pi, pending_region pr, pending_period pp
	 where cirj.pending_dataset_Id = pd.pending_dataset_id
	   and pd.app_sid = c.app_sid
	   and cirj.calc_pending_ind_id = pi.pending_ind_id
	   and cirj.pending_region_id = pr.pending_region_id
	   and cirj.pending_period_id = pp.pending_period_id;

CREATE OR REPLACE VIEW csr.v$doc_folder AS
	SELECT df.doc_folder_sid, df.description, df.lifespan_is_override, df.lifespan,
		   df.approver_is_override, df.approver_sid, df.company_sid, df.is_system_managed,
		   df.property_sid, dfnt.lang, dfnt.translated, df.permit_item_id
	  FROM doc_folder df
	  JOIN doc_folder_name_translation dfnt ON df.app_sid = dfnt.app_sid AND df.doc_folder_sid = dfnt.doc_folder_sid
	 WHERE dfnt.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

-- provides more human readable information about pvc_region_recalc_jobs
create or replace view csr.v$pvc_region_recalc_job as
	select c.host, pi.description ind_description, processing, pi.pending_ind_id, pd.pending_dataset_id
	  from pvc_region_recalc_job rrj, pending_dataset pd, customer c, pending_ind pi
	 where rrj.pending_dataset_Id = pd.pending_dataset_id
	   and pd.app_sid = c.app_sid
	   and rrj.pending_ind_id = pi.pending_ind_id;

-- provides more human readable information about pending_val_cache
create or replace view csr.v$pending_val_cache as
	select host, pi.description ind_description, pr.description region_description, pp.start_dtm, pp.end_dtm, val_number,
		pi.pending_ind_id, pr.pending_region_id, pp.pending_period_id, pd.pending_dataset_id
	  from pending_val_cache pvc, pending_ind pi, pending_region pr, pending_period pp, pending_dataset pd, customer c
	 where pvc.pending_ind_Id = pi.pending_ind_id
	   and pvc.pending_region_id = pr.pending_region_id
	   and pvc.pending_period_id = pp.pending_period_id
	   and pi.pending_dataset_Id = pd.pending_dataset_id
	   and pd.app_sid = c.app_sid;

-- provides more human readable information about pending_val
create or replace view csr.v$pending_val as
	select host, pv.pending_val_id, pi.description ind_description, pr.description region_description, pp.start_dtm, pp.end_dtm, val_number,
		val_string, from_val_number, from_measure_conversion_id, action, note, pv.approval_step_id,
		pi.pending_ind_id, pr.pending_region_id, pp.pending_period_id, pd.pending_dataset_id
	  from pending_val pv, pending_ind pi, pending_region pr, pending_period pp, pending_dataset pd, customer c
	 where pv.pending_ind_Id = pi.pending_ind_id
	   and pv.pending_region_id = pr.pending_region_id
	   and pv.pending_period_id = pp.pending_period_id
	   and pi.pending_dataset_Id = pd.pending_dataset_id
	   and pd.app_sid = c.app_sid;

-- provides more human readable information about pending_region (query using pending_dataset_id)
create or replace view csr.v$pending_region as
	select pending_dataset_id, lpad(' ', (level-1)*4)||description description, pending_region_id, maps_to_region_sid
	  from pending_region
	 start with parent_region_id is null
	connect by prior pending_region_id = parent_region_id;

CREATE OR REPLACE VIEW CSR.V$LEGACY_AGGREGATOR AS
	SELECT app_sid, meter_input_id, aggregator, aggr_proc, is_mandatory
	  FROM (
		SELECT app_sid, meter_input_id, aggregator, aggr_proc, is_mandatory,
			ROW_NUMBER() OVER (
				PARTITION BY meter_input_id
				ORDER BY CASE aggregator
					WHEN 'SUM' THEN 1
					WHEN 'AVERAGE' THEN 2
					WHEN 'MAX' THEN 3
					WHEN 'MIN' THEN 4
					ELSE 100
				END
			) rn
		  FROM csr.meter_input_aggregator
	) WHERE rn = 1
;

CREATE OR REPLACE VIEW CSR.V$LEGACY_METER_TYPE AS
	SELECT
		mi.app_sid,
		mi.meter_type_id,
		mi.label,
		iip.ind_sid consumption_ind_sid,
		ciip.ind_sid cost_ind_sid,
		mi.group_key,
		mi.days_ind_sid,
		mi.costdays_ind_sid
	 FROM meter_type mi
	-- Consumption mandatory
	 JOIN csr.meter_input ip ON ip.app_sid = mi.app_sid AND ip.lookup_key = 'CONSUMPTION'
	 JOIN csr.v$legacy_aggregator iag ON iag.app_sid = ip.app_sid AND iag.meter_input_id = ip.meter_input_id
	 JOIN csr.meter_type_input iip ON iip.app_sid = mi.app_sid AND iip.meter_type_id = mi.meter_type_id AND iip.meter_input_id = iag.meter_input_id
	 -- Cost optional
	 LEFT JOIN csr.meter_input cip ON cip.app_sid = mi.app_sid AND cip.lookup_key = 'COST'
	 LEFT JOIN csr.v$legacy_aggregator ciag ON ciag.app_sid = cip.app_sid AND ciag.meter_input_id = cip.meter_input_id
	 LEFT JOIN csr.meter_type_input ciip ON ciip.app_sid = mi.app_sid AND ciip.meter_type_id = mi.meter_type_id AND ciip.meter_input_id = ciag.meter_input_id
;

CREATE OR REPLACE VIEW CSR.V$METER_TYPE AS
	SELECT
		mi.app_sid,
		mi.meter_type_id,
		mi.label,
		iip.ind_sid consumption_ind_sid,
		ciip.ind_sid cost_ind_sid,
		mi.group_key,
		mi.days_ind_sid,
		mi.costdays_ind_sid
	 FROM meter_type mi
	-- Legacy consumption if available
	 LEFT JOIN csr.meter_input ip ON ip.app_sid = mi.app_sid AND ip.lookup_key = 'CONSUMPTION'
	 LEFT JOIN csr.v$legacy_aggregator iag ON iag.app_sid = ip.app_sid AND iag.meter_input_id = ip.meter_input_id
	 LEFT JOIN csr.meter_type_input iip ON iip.app_sid = mi.app_sid AND iip.meter_type_id = mi.meter_type_id AND iip.meter_input_id = iag.meter_input_id
	 -- Legacy cost if available
	 LEFT JOIN csr.meter_input cip ON cip.app_sid = mi.app_sid AND cip.lookup_key = 'COST'
	 LEFT JOIN csr.v$legacy_aggregator ciag ON ciag.app_sid = cip.app_sid AND ciag.meter_input_id = cip.meter_input_id
	 LEFT JOIN csr.meter_type_input ciip ON ciip.app_sid = mi.app_sid AND ciip.meter_type_id = mi.meter_type_id AND ciip.meter_input_id = ciag.meter_input_id
;

CREATE OR REPLACE VIEW CSR.V$LEGACY_METER AS
	SELECT
		am.app_sid,
		am.region_sid,
		am.note,
		iip.ind_sid primary_ind_sid,
		iai.measure_conversion_id primary_measure_conversion_id,
		am.active,
		am.meter_source_type_id,
		am.reference,
		am.crc_meter,
		ciip.ind_sid cost_ind_sid,
		ciai.measure_conversion_id cost_measure_conversion_id,
		am.export_live_data_after_dtm,
		mi.days_ind_sid,
		am.days_measure_conversion_id,
		mi.costdays_ind_sid,
		am.costdays_measure_conversion_id,
		am.approved_by_sid,
		am.approved_dtm,
		am.is_core,
		am.meter_type_id,
		am.lower_threshold_percentage,
		am.upper_threshold_percentage,
		am.metering_version,
		am.urjanet_meter_id,
		am.manual_data_entry
	 FROM all_meter am
	 JOIN meter_type mi ON mi.app_sid = am.app_sid AND mi.meter_type_id = am.meter_type_id
	 -- Consumption mandatory
	 JOIN csr.meter_input ip ON ip.app_sid = am.app_sid AND ip.lookup_key = 'CONSUMPTION'
	 JOIN csr.v$legacy_aggregator iag ON iag.app_sid = ip.app_sid AND iag.meter_input_id = ip.meter_input_id
	 JOIN csr.meter_type_input iip ON iip.app_sid = am.app_sid AND iip.meter_type_id = am.meter_type_id AND iip.meter_input_id = iag.meter_input_id
	 JOIN meter_input_aggr_ind iai ON iai.app_sid = am.app_sid AND iai.region_sid = am.region_sid AND iai.meter_input_id = ip.meter_input_id
	 -- Cost optional
	 LEFT JOIN csr.meter_input cip ON cip.app_sid = am.app_sid AND cip.lookup_key = 'COST'
	 LEFT JOIN csr.v$legacy_aggregator ciag ON ciag.app_sid = cip.app_sid AND ciag.meter_input_id = cip.meter_input_id
	 LEFT JOIN csr.meter_type_input ciip ON ciip.app_sid = am.app_sid AND ciip.meter_type_id = am.meter_type_id AND ciip.meter_input_id = cip.meter_input_id
	 LEFT JOIN meter_input_aggr_ind ciai ON ciai.app_sid = am.app_sid AND ciai.region_sid = am.region_sid AND ciai.meter_input_id = cip.meter_input_id
;

CREATE OR REPLACE VIEW CSR.V$METER AS
  SELECT app_sid,region_sid, meter_type_id, note, primary_ind_sid, primary_measure_conversion_id, meter_source_type_id, reference, crc_meter,
	cost_ind_sid, cost_measure_conversion_id, days_ind_sid, days_measure_conversion_id, costdays_ind_sid, costdays_measure_conversion_id,
	approved_by_sid, approved_dtm, is_core, urjanet_meter_id
    FROM csr.v$legacy_meter
   WHERE active = 1;


CREATE OR REPLACE VIEW csr.v$tab_user AS
SELECT t.tab_id, t.app_sid, t.layout, NVL(td.description, t.name) name , t.is_shared, t.is_hideable, t.override_pos, tu.user_sid, tu.pos, tu.is_owner, tu.is_hidden, t.portal_group
  FROM csr.tab t
  JOIN csr.tab_user tu ON t.app_sid = tu.app_sid AND t.tab_id = tu.tab_id
  LEFT JOIN csr.tab_description td ON td.app_sid = tu.app_sid AND t.tab_id = td.tab_id AND td.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

CREATE OR REPLACE VIEW csr.V$GET_VALUE_RESULT_FILES AS
		SELECT r.source_id, fu.file_upload_sid, fu.filename, fu.mime_type
		  FROM get_value_result r, val_file vf, file_upload fu
		 WHERE r.source = 0 AND vf.val_id = r.source_id AND fu.file_upload_sid = vf.file_upload_sid
	 UNION ALL
		SELECT r.source_id, fu.file_upload_sid, fu.filename, fu.mime_type
		  FROM get_value_result r, sheet_value_file svf, file_upload fu
		 WHERE r.source = 1 AND svf.sheet_value_id = r.source_id AND fu.file_upload_sid = svf.file_upload_sid;

CREATE OR REPLACE VIEW csr.V$AUTOCREATE_USER AS
	SELECT user_name, app_sid, guid, requested_dtm, approved_dtm, approved_by_user_sid, created_user_sid, activated_dtm
	  FROM autocreate_user
	 WHERE rejected_dtm IS NULL;

CREATE OR REPLACE VIEW csr.v$imp_val_mapped AS
	SELECT iv.imp_val_id, iv.imp_session_Sid, iv.file_sid, ii.maps_to_ind_sid, iv.start_dtm, iv.end_dtm,
		   ii.description ind_description,
		   i.description maps_to_ind_description,
		   ir.description region_description,
		   i.aggregate,
		   iv.val,
		   COALESCE(mc.a, mcp.a, 1) factor_a,
		   COALESCE(mc.b, mcp.b, 1) factor_b,
		   COALESCE(mc.c, mcp.c, 0) factor_c,
		   m.description measure_description,
		   im.maps_to_measure_conversion_id,
		   mc.description from_measure_description,
		   NVL(i.format_mask, m.format_mask) format_mask,
		   ir.maps_to_region_sid,
		   iv.rowid rid,
		   ii.app_Sid, iv.note,
		   CASE WHEN m.custom_field LIKE '|%' THEN 1 ELSE 0 END is_text_ind,
		   icv.imp_conflict_id,
		   m.measure_sid,
		   iv.imp_ind_id, iv.imp_region_id,
		   CASE WHEN rm.ind_Sid IS NOT NULL THEN 1 ELSE 0 END is_region_metric
	  FROM imp_val iv
		   JOIN imp_ind ii
		   		 ON iv.imp_ind_id = ii.imp_ind_id
		   		AND iv.app_sid = ii.app_sid
		   		AND ii.maps_to_ind_sid IS NOT NULL
		   JOIN imp_region ir
		  		 ON iv.imp_region_id = ir.imp_region_id
		   		AND iv.app_sid = ir.app_sid
		   		AND ir.maps_to_region_sid IS NOT NULL
	  LEFT JOIN imp_measure im
	      		 ON iv.imp_ind_id = im.imp_ind_id
	      		AND iv.imp_measure_id = im.imp_measure_id
	      		AND iv.app_sid = im.app_sid
	  LEFT JOIN measure_conversion mc
				 ON im.maps_to_measure_conversion_id = mc.measure_conversion_id
				AND im.app_sid = mc.app_sid
      LEFT JOIN measure_conversion_period mcp
				 ON mc.measure_conversion_id = mcp.measure_conversion_id
				AND (iv.start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
				AND (iv.start_dtm < mcp.end_dtm or mcp.end_dtm is null)
	  LEFT JOIN imp_conflict_val icv
				 ON iv.imp_val_id = icv.imp_val_id
				AND iv.app_sid = icv.app_sid
		   JOIN v$ind i
				 ON ii.maps_to_ind_sid = i.ind_sid
				AND ii.app_sid = i.app_sid
				AND i.ind_type = 0
	  LEFT JOIN region_metric rm
				 ON i.ind_sid = rm.ind_sid AND i.app_sid = rm.app_sid
			   JOIN measure m
				 ON i.measure_sid = m.measure_sid
				AND i.app_sid = m.app_sid;

CREATE OR REPLACE VIEW csr.v$imp_merge AS
	SELECT *
	  FROM v$imp_val_mapped
	 WHERE imp_conflict_id is null;

CREATE OR REPLACE VIEW csr.v$calc_dependency (app_sid, calc_ind_sid, calc_ind_type, dep_type, ind_sid, ind_type, calc_start_dtm_adjustment, calc_end_dtm_adjustment) AS
	SELECT cd.app_sid, cd.calc_ind_sid, ci.ind_type, cd.dep_type, NVL(gi.ind_sid, i.ind_sid), NVL(gi.ind_type, i.ind_type), ci.calc_start_dtm_adjustment, ci.calc_end_dtm_adjustment
	  FROM calc_dependency cd
	  JOIN ind i
			ON cd.app_sid = i.app_sid
		   AND cd.ind_sid = i.ind_sid
	  JOIN ind ci
			ON cd.app_sid = ci.app_sid
		   AND cd.calc_ind_sid = ci.ind_sid
	  LEFT JOIN ind gi
			ON i.app_sid = gi.app_sid
		   AND i.ind_sid = gi.map_to_ind_sid
		   AND ci.gas_type_id = gi.gas_type_id
		   AND ci.map_to_ind_sid != gi.map_to_ind_sid
	 WHERE (i.measure_sid IS NOT NULL -- don't fetch things that have no unit of measure
	        OR EXISTS(SELECT * FROM model_map WHERE app_sid = cd.app_sid and model_sid = cd.ind_sid))
	   AND cd.dep_type = 1 -- csr_data_pkg.DEP_ON_INDICATOR
	 UNION
	SELECT cd.app_sid, cd.calc_ind_sid, ci.ind_type, cd.dep_type, NVL(gi.ind_sid, i.ind_sid), NVL(gi.ind_type, i.ind_type), ci.calc_start_dtm_adjustment, ci.calc_end_dtm_adjustment
	  FROM calc_dependency cd
	  JOIN ind i
			ON cd.app_sid = i.app_sid
		   AND cd.ind_sid = i.parent_sid
	  JOIN ind ci
			ON cd.app_sid = ci.app_sid
		   AND cd.calc_ind_sid = ci.ind_sid
	  LEFT JOIN ind gi
			ON i.app_sid = gi.app_sid
		   AND i.ind_sid = gi.map_to_ind_sid
		   AND ci.gas_type_id = gi.gas_type_id
		   AND ci.map_to_ind_sid != gi.map_to_ind_sid
	 WHERE cd.dep_type = 2 -- csr_data_pkg.DEP_ON_CHILDREN
	   AND i.measure_sid IS NOT NULL -- don't fetch things that have no unit of measure
	   AND (
			(i.map_to_ind_sid IS NULL) -- normal indicators or gas indicators depending on something that's not emission tracked
			OR
			(ci.map_to_ind_sid IS NOT NULL AND ci.ind_sid != gi.ind_sid AND ci.gas_type_id = gi.gas_type_id) -- gas
	)
	 UNION
	SELECT cd.app_sid, cd.calc_ind_sid, 1, cd.dep_type, mm.map_to_indicator_sid, 0, mi.calc_start_dtm_adjustment, mi.calc_end_dtm_adjustment
	  FROM calc_dependency cd
	  JOIN model_map mm
		    ON cd.app_sid = mm.app_sid
		   AND cd.calc_ind_sid = mm.model_sid
	  JOIN ind mi
	        ON mm.app_sid = mi.app_sid
	       AND mm.model_sid = mi.ind_sid
	 WHERE cd.dep_type = 3 -- csr_data_pkg.DEP_ON_MODEL
	   AND mm.model_map_type_id = 2
	   AND mm.map_to_indicator_sid IS NOT NULL
;

CREATE OR REPLACE VIEW csr.v$calc_direct_dependency (app_sid, calc_ind_sid, calc_ind_type, dep_type, ind_sid, ind_type, calc_start_dtm_adjustment, calc_end_dtm_adjustment) AS
	SELECT cd.app_sid, cd.calc_ind_sid, ci.ind_type, cd.dep_type, NVL(gi.ind_sid, i.ind_sid), NVL(gi.ind_type, i.ind_type), ci.calc_start_dtm_adjustment, ci.calc_end_dtm_adjustment
	  FROM calc_dependency cd
	  JOIN ind i
			ON cd.app_sid = i.app_sid
		   AND cd.ind_sid = i.ind_sid
	  JOIN ind ci
			ON cd.app_sid = ci.app_sid
		   AND cd.calc_ind_sid = ci.ind_sid
	  LEFT JOIN ind gi
			ON i.app_sid = gi.app_sid
		   AND i.ind_sid = gi.map_to_ind_sid
		   AND ci.gas_type_id = gi.gas_type_id
		   AND ci.map_to_ind_sid != gi.map_to_ind_sid
	 WHERE (i.measure_sid IS NOT NULL -- don't fetch things that have no unit of measure
	        OR EXISTS(SELECT * FROM model_map WHERE app_sid = cd.app_sid and model_sid = cd.ind_sid))
	   AND cd.dep_type IN (1, 2) -- csr_data_pkg.DEP_ON_INDICATOR, csr_data_pkg.DEP_ON_CHILDREN
	 UNION
	SELECT cd.app_sid, cd.calc_ind_sid, 1, cd.dep_type, mm.map_to_indicator_sid, 0, mi.calc_start_dtm_adjustment, mi.calc_end_dtm_adjustment
	  FROM calc_dependency cd
	  JOIN model_map mm
		    ON cd.app_sid = mm.app_sid
		   AND cd.calc_ind_sid = mm.model_sid
	  JOIN ind mi
	        ON mm.app_sid = mi.app_sid
	       AND mm.model_sid = mi.ind_sid
	 WHERE cd.dep_type = 3 -- csr_data_pkg.DEP_ON_MODEL
	   AND mm.model_map_type_id = 2
	   AND mm.map_to_indicator_sid IS NOT NULL
;

-- Well, this gave me a headache.
-- What it does is to first figure out what time it is in the user's timezone.  Then we stick with their timezone and:
-- a. Figure out what time they want the batch to run at, i.e. knock the time part off and set it to the batch run time
-- b. Decide when the next time to fire the trigger is. If the trigger time was in the past we add one day (i.e. do it tomorrow).
-- c. Figure out when the previous time to fire the trigger was (i.e. b - 1 day).
-- Then everything gets converted back to GMT.  Most of the columns in the view aren't necessary, but are left there
-- for ease of figuring out what's going on.
--
-- To run a batch using this, the idea is:
-- a. fill alert_batch_run info out for missing users so we know the next trigger fire time for all users
-- b. join $your_query to alert_batch_run and just do those jobs where systimestamp >= prev_fire_time_gmt
-- c. after running a batch for a user update their next fire time from query a).  You have to save this and NOT
-- requery!  (The next fire time computed above accounts for DST changes, i.e. clocks going forward one day by 1 hour
-- means that the next fire time will be 23 hours after the previous fire time instead of 24)
--
-- This method accounts for missed ticks, e.g. if you set a batch to run at 23:59 we may end up running a bit late, at 00.01
-- the next day.
--
-- Now the annoying bit is if the user changes timezone, the next fire time will be wrong.  To fix that
-- the last fire time should be converted to the new timezone, then the next tick computed based on that (using the
-- if in the past, that time tomorrow; if in the future at that time method as below).  I haven't actually fixed
-- this as I guess alerts going out at the wrong time once isn't a big deal (and I have a headache).
create or replace view csr.v$alert_batch_run_time as
	select app_sid, csr_user_sid, alert_batch_run_time, user_tz,
		   user_run_at, user_run_at at time zone 'Etc/GMT' user_run_at_gmt,
		   user_current_time, user_current_time at time zone 'Etc/GMT' user_current_time_gmt,
		   next_fire_time, next_fire_time at time zone 'Etc/GMT' next_fire_time_gmt,
		   next_fire_time - numtodsinterval(1,'DAY') prev_fire_time,
		   (next_fire_time - numtodsinterval(1,'DAY')) at time zone 'Etc/GMT' prev_fire_time_gmt
	  from (select app_sid, csr_user_sid, alert_batch_run_time, user_run_at, user_current_time,
		   		   case when user_run_at < user_current_time then user_run_at + numtodsinterval(1,'DAY') else user_run_at end next_fire_time,
		   		   user_tz
			  from (select app_sid, csr_user_sid, alert_batch_run_time,
						   from_tz_robust(cast(trunc(user_current_time) + alert_batch_run_time as timestamp), user_tz) user_run_at,
						   user_current_time, user_tz
			  		  from (select cu.app_sid, cu.csr_user_sid, alert_batch_run_time,
								   systimestamp at time zone COALESCE(ut.timezone, a.timezone, 'Etc/GMT') user_current_time,
								   COALESCE(ut.timezone, a.timezone, 'Etc/GMT') user_tz
							  from security.user_table ut, security.application a, csr_user cu, customer c
							 where cu.csr_user_sid = ut.sid_id
							   and c.app_sid = cu.app_sid
							   and a.application_sid_id = c.app_sid)));

CREATE OR REPLACE VIEW csr.sheet_with_last_action AS
	SELECT sh.app_sid, sh.sheet_id, sh.delegation_sid, sh.start_dtm, sh.end_dtm, sh.reminder_dtm, sh.submission_dtm,
		   she.sheet_action_id last_action_id, she.from_user_sid last_action_from_user_sid, she.action_dtm last_action_dtm,
		   she.note last_action_note, she.to_delegation_sid last_action_to_delegation_sid,
		   CASE WHEN SYSTIMESTAMP AT TIME ZONE COALESCE(ut.timezone, a.timezone, 'Etc/GMT') >= from_tz_robust(cast(sh.submission_dtm as timestamp), COALESCE(ut.timezone, a.timezone, 'Etc/GMT'))
                 AND she.sheet_action_id IN (0,10,2)
                    THEN 1
				WHEN SYSTIMESTAMP AT TIME ZONE COALESCE(ut.timezone, a.timezone, 'Etc/GMT') >= from_tz_robust(cast(sh.reminder_dtm as timestamp), COALESCE(ut.timezone, a.timezone, 'Etc/GMT'))
                 AND she.sheet_action_id IN (0,10,2)
                    THEN 2
				ELSE 3
		   END status, sh.is_visible, sh.last_sheet_history_id, sha.colour last_action_colour, sh.is_read_only, sh.percent_complete,
		   sha.description last_action_desc, sha.downstream_description last_action_downstream_desc, sh.automatic_approval_dtm, sh.automatic_approval_status
	 FROM sheet sh
		JOIN sheet_history she ON sh.last_sheet_history_id = she.sheet_history_id AND she.sheet_id = sh.sheet_id AND sh.app_sid = she.app_sid
		JOIN sheet_action sha ON she.sheet_action_id = sha.sheet_action_id
        LEFT JOIN csr.csr_user u ON u.csr_user_sid = SYS_CONTEXT('SECURITY','SID') AND u.app_sid = sh.app_sid
        LEFT JOIN security.user_table ut ON ut.sid_id = u.csr_user_sid
        LEFT JOIN security.application a ON a.application_sid_id = u.app_sid;

CREATE OR REPLACE VIEW csr.v$delegation_user AS
    SELECT app_sid, delegation_sid, user_sid
      FROM csr.delegation_user
      WHERE inherited_from_sid = delegation_sid
     UNION 
    SELECT d.app_sid, d.delegation_sid, rrm.user_sid
      FROM delegation d
        JOIN delegation_role dlr ON d.delegation_sid = dlr.delegation_sid AND d.app_sid = dlr.app_sid AND dlr.inherited_from_sid = d.delegation_sid
        JOIN delegation_region dr ON d.delegation_sid = dr.delegation_sid AND d.app_sid = dr.app_sid
        JOIN region_role_member rrm ON dr.region_sid = rrm.region_sid AND dlr.role_sid = rrm.role_sid AND dr.app_sid = rrm.app_sid AND dlr.app_sid = rrm.app_sid
        ;

CREATE OR REPLACE VIEW csr.delegation_delegator (app_sid, delegation_sid, delegator_sid) AS
	SELECT d.app_sid, d.delegation_sid, du.user_sid
	  FROM delegation d, v$delegation_user du
	 WHERE d.app_sid = du.app_sid AND d.parent_sid = du.delegation_sid;

CREATE OR REPLACE VIEW csr.v$deleg_region_role_user AS
    SELECT d.app_sid, d.delegation_sid, dr.region_sid, dlr.role_sid, rrm.user_sid, dlr.is_read_only
      FROM delegation d
        JOIN delegation_role dlr ON d.delegation_sid = dlr.delegation_sid AND d.app_sid = dlr.app_sid
        JOIN delegation_region dr ON d.delegation_sid = dr.delegation_sid AND d.app_sid = dr.app_sid
        JOIN region_role_member rrm ON dr.region_sid = rrm.region_sid AND dlr.role_sid = rrm.role_sid AND dr.app_sid = rrm.app_sid AND dlr.app_sid = rrm.app_sid
        ;

-- Normal site users, both active and inactive (and including the active flag plus other
-- things from security.user_table), but excluding trashed and hidden users
CREATE OR REPLACE VIEW csr.v$csr_user AS
	SELECT cu.app_sid, cu.csr_user_sid, cu.email, cu.full_name, cu.user_name, cu.send_alerts,
		   cu.guid, cu.friendly_name, cu.info_xml, cu.show_portal_help, cu.donations_browse_filter_id, cu.donations_reports_filter_id,
		   cu.hidden, cu.phone_number, cu.job_title, ut.account_enabled active, ut.last_logon, cu.created_dtm, ut.expiration_dtm,
		   ut.language, ut.culture, ut.timezone, so.parent_sid_id, cu.last_modified_dtm, cu.last_logon_type_Id, cu.line_manager_sid, cu.primary_region_sid,
		   cu.enable_aria, cu.user_ref, cu.anonymised
      FROM csr_user cu, security.securable_object so, security.user_table ut, customer c
     WHERE cu.app_sid = c.app_sid
       AND cu.csr_user_sid = so.sid_id
       AND so.parent_sid_id != c.trash_sid
       AND ut.sid_id = so.sid_id
       AND cu.hidden = 0;

/********************************************* WORKFLOW ***************************************************/
-- View showing current state of items in workflow
CREATE OR REPLACE VIEW csr.V$FLOW_ITEM AS
    SELECT fi.app_sid, fi.flow_sid, fi.flow_item_id, f.label flow_label,
		fs.flow_state_id current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key,
		fs.state_colour current_state_colour,
		fi.last_flow_state_log_id, fi.last_flow_state_transition_id,
        fi.survey_response_id, fi.dashboard_instance_id  -- deprecated
      FROM flow_item fi
	    JOIN flow f ON fi.flow_sid = f.flow_sid
        JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
    ;


-- View showing all items in workflow, all roles where the current user is a member, and all regions for those roles.
-- You never want to just select from this, i.e. you would want to join this view to a workflow item detail table
-- which would also have information about which region the workflow item was applicable to (which reduces the returned
-- rows significantly ;)).
--
-- A typical usage would be:
--
--    SELECT firm.flow_sid, firm.flow_item_id, firm.current_state_id,
--        firm.current_state_label, firm.role_sid, firm.role_name, fsr.is_editable,
--        r.region_sid, r.description region_description,
--        adi.dashboard_instance_id, adi.start_dtm, adi.end_dtm
--      FROM V$FLOW_ITEM_ROLE_MEMBER firm
--        JOIN approval_dashboard_instance adi ON firm.dashboard_instance_id = adi.dashboard_instance_id
--        JOIN region r ON adi.region_sid = r.region_sid AND firm.region_sid = r.region_sid
--     WHERE adi.approval_dashboard_sid = in_dashboard_sid
--	     AND start_dtm = in_start_dtm
--	     AND end_dtm = in_end_dtm
--	   ORDER BY transition_pos;
CREATE OR REPLACE VIEW csr.V$FLOW_ITEM_ROLE_MEMBER AS
    SELECT fi.*, r.role_sid, r.name role_name, rrm.region_sid, fsr.is_editable
      FROM V$FLOW_ITEM fi
        JOIN flow_state_role fsr ON fi.current_state_id = fsr.flow_state_id AND fi.app_sid = fsr.app_sid
        JOIN role r ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
        JOIN region_role_member rrm ON r.role_sid = rrm.role_sid AND r.app_sid = rrm.app_sid AND rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
    ;


-- View showing items in workflow and possible future transitions
CREATE OR REPLACE VIEW csr.v$flow_item_transition AS 
  SELECT fst.app_sid, fi.flow_sid, fi.flow_item_Id, fst.flow_state_transition_id, fst.verb,
		 fs.flow_state_id from_state_id, fs.label from_state_label, fs.state_colour from_state_colour,
		 tfs.flow_state_id to_state_id, tfs.label to_state_label, tfs.state_colour to_state_colour,
		 fst.ask_for_comment, fst.pos transition_pos, fst.button_icon_path, fst.enforce_validation,
		 tfs.flow_state_nature_id,
		 fi.survey_response_id, fi.dashboard_instance_id -- these are deprecated
      FROM flow_item fi
		JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
		JOIN flow_state_transition fst ON fs.flow_state_id = fst.from_state_id AND fs.app_sid = fst.app_sid
		JOIN flow_state tfs ON fst.to_state_id = tfs.flow_state_id AND fst.app_sid = tfs.app_sid AND tfs.is_deleted = 0;

-- View showing all items in workflow where there are transitions where the current user is a member, and all regions for those roles.
-- You never want to just select from this, i.e. you would want to join this view to a workflow item detail table
-- which would also have information about which region the workflow item was applicable to (which reduces the returned
-- rows significantly ;)).
--
-- A typical usage would be:
--
--    SELECT trm.flow_item_id, trm.flow_state_transition_id, trm.verb, trm.to_state_id,
--        trm.to_state_label, trm.ask_for_comment, trm.role_sid, trm.role_name,
--        r.region_sid, r.description region_description,
--        adi.dashboard_instance_id, adi.start_dtm, adi.end_dtm
--      FROM V$FLOW_ITEM_TRANS_ROLE_MEMBER trm
--        JOIN approval_dashboard_instance adi ON trm.dashboard_instance_id = adi.dashboard_instance_id
--        JOIN region r ON adi.region_sid = r.region_sid AND trm.region_sid = r.region_sid
--     WHERE adi.approval_dashboard_sid = in_dashboard_sid
--	     AND start_dtm = in_start_dtm
--	     AND end_dtm = in_end_dtm
--	   ORDER BY transition_pos;
  CREATE OR REPLACE VIEW csr.v$flow_item_trans_role_member AS 
  SELECT fit.app_sid,fit.flow_sid,fit.flow_item_id,fit.flow_state_transition_id,fit.verb,fit.from_state_id,fit.from_state_label,
  		 fit.from_state_colour,fit.to_state_id,fit.to_state_label,fit.to_state_colour,fit.ask_for_comment,fit.transition_pos,
		 fit.button_icon_path,fit.survey_response_id,fit.dashboard_instance_id, r.role_sid, r.name role_name, rrm.region_sid, fit.flow_state_nature_id, fit.enforce_validation
	FROM v$flow_item_transition fit
		 JOIN flow_state_transition_role fstr ON fit.flow_state_transition_id = fstr.flow_state_transition_id AND fit.app_sid = fstr.app_sid
		 JOIN role r ON fstr.role_sid = r.role_sid AND fstr.app_sid = r.app_sid
		 JOIN region_role_member rrm ON r.role_sid = rrm.role_sid AND r.app_sid = rrm.app_sid
   WHERE rrm.user_sid = SYS_CONTEXT('SECURITY','SID');

CREATE OR REPLACE VIEW csr.v$user_flow_item AS
    SELECT fi.app_sid, fi.flow_sid, fi.flow_item_id, fi.current_state_id, fi.current_state_label,
           fi.survey_response_id, fi.dashboard_instance_id
      FROM v$flow_item fi
     WHERE (fi.app_sid, fi.current_state_id) IN (
     		SELECT fsr.app_sid, fsr.flow_state_id
     		  FROM flow_state_role fsr
      		  JOIN (SELECT group_sid_id
					  FROM security.group_members
						   START WITH member_sid_id = SYS_CONTEXT('SECURITY','SID')
						   CONNECT BY NOCYCLE PRIOR group_sid_id = member_sid_id) g
				ON g.group_sid_id = fsr.role_sid);

/* v$open_flow_item_alert is Used for generating alerts. You need to join this to something else, for example:

	SELECT DISTINCT x.app_sid, x.region_sid, x.user_sid, x.flow_state_transition_id, x.flow_item_alert_id,
		customer_alert_type_id, x.flow_state_log_id, x.from_state_label, x.to_state_label,
		x.set_by_user_sid, x.set_by_email, x.set_by_full_name, x.set_by_user_name,
		x.to_user_sid, to_email, to_full_name, to_friendly_name, to_user_name,
		ad.label dashboard_label, adi.start_dtm, adi.end_dtm, adi.approval_dashboard_sid
	  FROM v$open_flow_item_alert x
		JOIN approval_dashboard_instance adi
			ON adi.dashboard_instance_Id = x.dashboard_instance_id
			AND x.region_sid = adi.region_sid
			AND x.app_sid = adi.app_sid
		JOIN approval_dashboard ad
			ON adi.approval_dashboard_sid = ad.approval_dashboard_sid
			AND adi.app_sid = ad.app_sid
*/
CREATE OR REPLACE VIEW csr.v$flow_item_gen_alert AS
SELECT fta.flow_transition_alert_id, fta.customer_alert_type_id, fta.helper_sp,
	flsf.flow_state_id from_state_id, flsf.label from_state_label,
	flst.flow_state_id to_state_id, flst.label to_state_label,
	fsl.flow_state_log_Id, fsl.set_dtm, fsl.set_by_user_sid, fsl.comment_text,
	cusb.full_name set_by_full_name, cusb.email set_by_email, cusb.user_name set_by_user_name,
	cut.csr_user_sid to_user_sid, cut.full_name to_full_name,
	cut.email to_email, cut.user_name to_user_name, cut.friendly_name to_friendly_name,
	fi.app_sid, fi.flow_item_id, fi.flow_sid, fi.current_state_id,
	fi.survey_response_id, fi.dashboard_instance_id, fta.to_initiator, fta.flow_alert_helper,
	figa.to_column_sid, figa.flow_item_generated_alert_id, figa.processed_dtm, figa.created_dtm,
	cat.is_batched, ftacc.alert_manager_flag, fta.flow_state_transition_id,
	figa.subject_override, figa.body_override, fta.can_be_edited_before_sending
  FROM flow_item_generated_alert figa
  JOIN flow_state_log fsl ON figa.flow_state_log_id = fsl.flow_state_log_id AND figa.flow_item_id = fsl.flow_item_id AND figa.app_sid = fsl.app_sid
  JOIN csr_user cusb ON fsl.set_by_user_sid = cusb.csr_user_sid AND fsl.app_sid = cusb.app_sid
  JOIN flow_item fi ON figa.flow_item_id = fi.flow_item_id AND figa.app_sid = fi.app_sid
  JOIN flow_transition_alert fta ON figa.flow_transition_alert_id = fta.flow_transition_alert_id AND figa.app_sid = fta.app_sid
  JOIN flow_state_transition fst ON fta.flow_state_transition_id = fst.flow_state_transition_id AND fta.app_sid = fst.app_sid
  JOIN flow_state flsf ON fst.from_state_id = flsf.flow_state_id AND fst.app_sid = flsf.app_sid
  JOIN flow_state flst ON fst.to_state_id = flst.flow_state_id AND fst.app_sid = flst.app_sid
  LEFT JOIN cms_alert_type cat ON  fta.customer_alert_type_id = cat.customer_alert_type_id
  LEFT JOIN flow_transition_alert_cms_col ftacc ON figa.flow_transition_alert_id = ftacc.flow_transition_alert_id AND figa.to_column_sid = ftacc.column_sid
  LEFT JOIN csr_user cut ON figa.to_user_sid = cut.csr_user_sid AND figa.app_sid = cut.app_sid
 WHERE fta.deleted = 0;

CREATE OR REPLACE VIEW csr.v$open_flow_item_gen_alert AS
SELECT flow_transition_alert_id, customer_alert_type_id, helper_sp,
	from_state_id, from_state_label,
	to_state_id, to_state_label,
	flow_state_log_Id, set_dtm, set_by_user_sid, comment_text,
	set_by_full_name, set_by_email, set_by_user_name,
	to_user_sid, to_full_name,
	to_email, to_user_name, to_friendly_name,
	app_sid, flow_item_id, flow_sid, current_state_id,
	survey_response_id, dashboard_instance_id, to_initiator, flow_alert_helper,
	to_column_sid, flow_item_generated_alert_id,
	is_batched, alert_manager_flag, created_dtm, flow_state_transition_id,
	subject_override, body_override, can_be_edited_before_sending
  FROM csr.v$flow_item_gen_alert
 WHERE processed_dtm IS NULL;

CREATE OR REPLACE VIEW csr.v$flow_involvement_type AS
	SELECT fit.app_sid, fit.flow_involvement_type_id, fit.product_area, fit.label, fit.css_class, fit.lookup_key,
		   fitac.flow_alert_class
	  FROM csr.flow_involvement_type fit
	  JOIN csr.flow_inv_type_alert_class fitac ON fit.flow_involvement_type_id = fitac.flow_involvement_type_id;

-- doclib
CREATE OR REPLACE VIEW csr.v$checked_out_version AS
SELECT s.section_sid, s.parent_sid, sv.version_number, sv.title, sv.body, s.checked_out_to_sid,
	   s.checked_out_dtm, s.app_sid, s.section_position, s.active, s.module_root_sid, s.title_only
  FROM section s, section_version sv
 WHERE s.section_sid = sv.section_sid
   AND s.checked_out_version_number = sv.version_number;

-- sections
CREATE OR REPLACE VIEW csr.v$visible_version AS
	SELECT s.section_sid, s.parent_sid, sv.version_number, sv.title, sv.body, s.checked_out_to_sid, s.checked_out_dtm, s.flow_item_id, s.current_route_step_id, s.is_split,
		   s.app_sid, s.section_position, s.active, s.module_root_sid, s.title_only, s.help_text, REF, plugin, plugin_config, section_status_sid, further_info_url,
		   s.previous_section_sid
	  FROM section s, section_version sv
	 WHERE s.section_sid = sv.section_sid
	   AND s.visible_version_number = sv.version_number;

-- quick surveys
CREATE OR REPLACE VIEW csr.v$quick_survey AS
	SELECT qs.app_sid, qs.survey_sid, d.label draft_survey_label, l.label live_survey_label,
		   NVL(l.label, d.label) label, qs.audience, qs.group_key, qs.created_dtm, qs.auditing_audit_type_id,
		   CASE WHEN l.survey_sid IS NOT NULL THEN 1 ELSE 0 END survey_is_published,
		   CASE WHEN qs.last_modified_dtm > l.published_dtm THEN 1 ELSE 0 END survey_has_unpublished_changes,
		   qs.score_type_id, st.label score_type_label, st.format_mask score_format_mask,
		   qs.quick_survey_type_id, qst.description quick_survey_type_desc, qs.current_version,
		   qs.from_question_library, qs.lookup_key, qst.capture_geo_location
	  FROM csr.quick_survey qs
	  JOIN csr.quick_survey_version d ON qs.app_sid = d.app_sid AND qs.survey_sid = d.survey_sid
	  LEFT JOIN csr.quick_survey_version l ON qs.app_sid = l.app_sid AND qs.survey_sid = l.survey_sid AND qs.current_version = l.survey_version
	  LEFT JOIN csr.score_type st ON st.score_type_id = qs.score_type_id AND st.app_sid = qs.app_sid
	  LEFT JOIN csr.quick_survey_type qst ON qst.quick_survey_type_id = qs.quick_survey_type_id AND qst.app_sid = qs.app_sid
	 WHERE d.survey_version = 0;

CREATE OR REPLACE VIEW csr.v$quick_survey_response AS
	SELECT qsr.app_sid, qsr.survey_response_id, qsr.survey_sid, qsr.user_sid, qsr.user_name,
		   qsr.created_dtm, qsr.guid, qss.submitted_dtm, qsr.qs_campaign_sid, qss.overall_score,
		   qss.overall_max_score, qss.score_threshold_id, qss.submission_id, qss.survey_version, qss.submitted_by_user_sid,
		   qss.geo_latitude, qss.geo_longitude, qss.geo_h_accuracy, qss.geo_altitude, qss.geo_v_accuracy
	  FROM quick_survey_response qsr
	  JOIN quick_survey_submission qss ON qsr.app_sid = qss.app_sid
	   AND qsr.survey_response_id = qss.survey_response_id
	   AND NVL(qsr.last_submission_id, 0) = qss.submission_id
	   AND qsr.survey_version > 0 -- filter out draft submissions
	   AND qsr.hidden = 0 -- filter out hidden responses
;

CREATE OR REPLACE VIEW csr.v$qs_answer_file AS
	SELECT af.app_sid, af.qs_answer_file_id, af.survey_response_id, af.question_id, af.filename,
		   af.mime_type, rf.data, af.sha1, rf.uploaded_dtm, sf.submission_id, af.caption
	  FROM qs_answer_file af
	  JOIN qs_response_file rf ON af.app_sid = rf.app_sid AND af.survey_response_id = rf.survey_response_id AND af.sha1 = rf.sha1 AND af.filename = rf.filename AND af.mime_type = rf.mime_type
	  JOIN qs_submission_file sf ON af.app_sid = sf.app_sid AND af.qs_answer_file_id = sf.qs_answer_file_id;

CREATE OR REPLACE VIEW csr.v$quick_survey_answer AS
	SELECT qsa.app_sid, qsa.survey_response_id, qsa.question_id, qsa.note, qsa.score, qsa.question_option_id,
		   qsa.val_number, qsa.measure_conversion_id, qsa.measure_sid, qsa.region_sid, qsa.answer,
		   qsa.html_display, qsa.max_score, qsa.version_stamp, qsa.submission_id, qsa.survey_version, qsq.lookup_key
	  FROM quick_survey_answer qsa
	  JOIN v$quick_survey_response qsr ON qsa.survey_response_id = qsr.survey_response_id AND qsa.submission_id = qsr.submission_id
	  JOIN quick_survey_question qsq ON qsa.question_id = qsq.question_id AND qsa.survey_version = qsq.survey_version;

CREATE OR REPLACE VIEW csr.v$supplier_score AS
	SELECT css.app_sid, css.company_sid, css.score_type_id, css.last_supplier_score_id,
		   ss.score, ss.set_dtm score_last_changed, ss.score_threshold_id,
		   ss.changed_by_user_sid, cu.full_name changed_by_user_full_name, ss.comment_text,
		   st.description score_threshold_description, t.label score_type_label, t.pos,
		   t.format_mask, ss.valid_until_dtm, CASE WHEN ss.valid_until_dtm IS NULL OR ss.valid_until_dtm >= SYSDATE THEN 1 ELSE 0 END valid,
		   ss.score_source_type, ss.score_source_id
	  FROM csr.current_supplier_score css
	  JOIN csr.supplier_score_log ss ON css.company_sid = ss.supplier_sid AND css.last_supplier_score_id = ss.supplier_score_id
	  LEFT JOIN csr.score_threshold st ON ss.score_threshold_id = st.score_threshold_id
	  JOIN csr.score_type t ON css.score_type_id = t.score_type_id
	  LEFT JOIN csr.csr_user cu ON ss.changed_by_user_sid = cu.csr_user_sid;

-- Flatten the join tables to make it easier to find delegations from a delegation plan
CREATE OR REPLACE VIEW csr.v$deleg_plan_delegs AS
	SELECT dpc.app_sid, dpc.deleg_plan_sid, dpcd.delegation_sid template_deleg_sid,
		   dpdrd.maps_to_root_deleg_sid, d.delegation_sid applied_to_delegation_sid, d.lvl, d.is_leaf
	  FROM deleg_plan_col dpc
	  JOIN deleg_plan_col_deleg dpcd ON dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id AND dpc.app_sid = dpcd.app_sid
	  JOIN deleg_plan_deleg_region_deleg dpdrd ON dpcd.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id AND dpcd.app_sid = dpdrd.app_sid
	  JOIN (
		SELECT CONNECT_BY_ROOT delegation_sid root_delegation_sid, delegation_sid, level lvl, connect_by_isleaf is_leaf
		  FROM delegation
		 START WITH parent_sid = app_sid
		CONNECT BY PRIOR delegation_sid = parent_sid AND PRIOR app_sid = app_sid
	  ) d ON d.root_delegation_sid = dpdrd.maps_to_root_deleg_sid;

-- Previously known as v$delegation, refactored to avoid inappropriate use.
CREATE OR REPLACE VIEW csr.v$delegation_hierarchical AS
	SELECT d.app_sid, d.delegation_sid, d.parent_sid, d.name, d.master_delegation_sid, d.created_by_sid, d.schedule_xml, d.note, d.group_by, d.allocate_users_to, d.start_dtm, d.end_dtm, d.reminder_offset,
		   d.is_note_mandatory, d.section_xml, d.editing_url, d.fully_delegated, d.grid_xml, d.is_flag_mandatory, d.show_aggregate, d.hide_sheet_period, d.delegation_date_schedule_id, d.layout_id,
		   d.tag_visibility_matrix_group_id, d.period_set_id, d.period_interval_id, d.submission_offset, d.allow_multi_period, NVL(dd.description, d.name) as description, dp.submit_confirmation_text,
		   d.lvl
	  FROM (
		SELECT app_sid, delegation_sid, parent_sid, name, master_delegation_sid, created_by_sid, schedule_xml, note, group_by, allocate_users_to, start_dtm, end_dtm, reminder_offset,
			   is_note_mandatory, section_xml, editing_url, fully_delegated, grid_xml, is_flag_mandatory, show_aggregate, hide_sheet_period, delegation_date_schedule_id, layout_id,
			   tag_visibility_matrix_group_id, period_set_id, period_interval_id, submission_offset, allow_multi_period, CONNECT_BY_ROOT(delegation_sid) root_delegation_sid, LEVEL lvl
		  FROM delegation
		 START WITH parent_sid = app_sid
	   CONNECT BY parent_sid = prior delegation_sid) d
	  LEFT JOIN delegation_description dd ON dd.app_sid = d.app_sid
	   AND dd.delegation_sid = d.delegation_sid
	   AND dd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  LEFT JOIN delegation_policy dp ON dp.delegation_sid = root_delegation_sid;

-- deleg plans
CREATE OR REPLACE VIEW csr.V$DELEG_PLAN_DELEG_REGION AS
	SELECT dpc.app_sid, dpc.deleg_plan_sid, dpdr.deleg_plan_col_deleg_id, dpc.deleg_plan_col_id, dpc.is_hidden,
		   dpcd.delegation_sid, dpdr.region_sid, dpdr.pending_deletion, dpdr.region_selection,
		   dpdr.tag_id, dpdr.region_type
	  FROM deleg_plan_deleg_region dpdr
	  JOIN deleg_plan_col_deleg dpcd ON dpdr.app_sid = dpcd.app_sid AND dpdr.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
	  JOIN deleg_plan_col dpc ON dpcd.app_sid = dpc.app_sid AND dpcd.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id;

CREATE OR REPLACE VIEW csr.V$DELEG_PLAN_COL AS
	SELECT deleg_plan_col_id, deleg_plan_sid, d.description label, dpc.is_hidden, 'Delegation' type, dpcd.delegation_sid object_sid
	  FROM deleg_plan_col dpc
		JOIN deleg_plan_col_deleg dpcd ON dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
		JOIN v$delegation d ON dpcd.delegation_sid = d.delegation_sid
	 UNION
	SELECT deleg_plan_col_id, deleg_plan_sid, qs.label, dpc.is_hidden, 'Survey' type, dpcs.survey_sid object_sid
	  FROM deleg_plan_col dpc
		JOIN deleg_plan_col_survey dpcs ON dpc.deleg_plan_col_survey_id = dpcs.deleg_plan_col_survey_id
		JOIN v$quick_survey qs ON dpcs.survey_sid = qs.survey_sid
	;

create or replace view csr.v$ind_selection_group_dep as
	select isg.app_sid, isg.master_ind_sid, isg.master_ind_sid ind_sid
	  from csr.ind_selection_group isg, csr.ind i
	 where i.app_sid = isg.app_sid and i.ind_sid = isg.master_ind_sid
	 union all
	select isgm.app_sid, isgm.master_ind_sid, isgm.ind_sid
	  from csr.ind_selection_group_member isgm;

create or replace view csr.v$calc_job as
	select cj.calc_job_id, c.host, cj.app_sid, cq.name calc_queue_name,
		   sr.description scenario_run_description, cjp.description phase_description,
		   case when cj.total_work = 0 then 0 else round(cj.work_done / cj.total_work * 100,2) end progress,
		   cj.running_on, cj.updated_dtm, cj.processing, cj.work_done, cj.total_work, cj.phase,
		   cj.calc_job_type, cj.scenario_run_sid, cj.start_dtm, cj.end_dtm, cj.created_dtm,
		   cj.last_attempt_dtm, cj.attempts, cq.calc_queue_id, cj.priority, cj.full_recompute,
		   cj.delay_publish_scenario, cj.process_after_dtm
	  from csr.calc_job cj
	  join csr.calc_job_phase cjp on cj.phase = cjp.phase
	  join csr.customer c on cj.app_sid = c.app_sid
	  join csr.calc_queue cq on cj.calc_queue_id = cq.calc_queue_id
	  left join csr.scenario_run sr on cj.app_sid = sr.app_sid and cj.scenario_run_sid = sr.scenario_run_sid;

CREATE OR REPLACE VIEW csr.v$resolved_region AS
	SELECT /*+ALL_ROWS*/ r.app_sid, r.region_sid, r.link_to_region_sid, r.parent_sid,
	  	   -- this pattern is a bit messier than NVL, but it avoids taking properties off the link
	  	   -- in the case that the property is unset on the region -- that's only possible if it's
	  	   -- nullable, but quite a few of the properties are.  They should not be set on the link,
	  	   -- but we don't want to return duff data because we do end up with links with properties.
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.name ELSE r.name END name,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.active ELSE r.active END active,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.pos ELSE r.pos END pos,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.info_xml ELSE r.info_xml END info_xml,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.flag ELSE r.flag END flag,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.acquisition_dtm ELSE r.acquisition_dtm END acquisition_dtm,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.disposal_dtm ELSE r.disposal_dtm END disposal_dtm,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.region_type ELSE r.region_type END region_type,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.region_ref ELSE r.region_ref END region_ref,
		   r.lookup_key,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_country ELSE r.geo_country END geo_country,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_region ELSE r.geo_region END geo_region,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_city_id ELSE r.geo_city_id END geo_city_id,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_longitude ELSE r.geo_longitude END geo_longitude,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_latitude ELSE r.geo_latitude END geo_latitude,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_type ELSE r.geo_type END geo_type,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.map_entity ELSE r.map_entity END map_entity,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.egrid_ref ELSE r.egrid_ref END egrid_ref,
		   CASE WHEN rl.region_sid IS NOT NULL THEN rl.egrid_ref_overridden ELSE r.egrid_ref_overridden END egrid_ref_overridden,
		   -- If either the region or the region link is modified, then the resolved region
		   -- should appear to be modified.  GREATEST returns null if any of its arguments are
		   -- null, so the below ensures that we get the greatest non-null modified date.
		   GREATEST(NVL(r.last_modified_dtm, rl.last_modified_dtm),
				    NVL(rl.last_modified_dtm, r.last_modified_dtm)) last_modified_dtm
	  FROM region r
	  LEFT JOIN region rl ON r.link_to_region_sid = rl.region_sid AND r.app_sid = rl.app_sid;

CREATE OR REPLACE VIEW csr.v$resolved_region_description AS
	SELECT /*+ALL_ROWS*/ r.app_sid, r.region_sid, rd.description, r.link_to_region_sid, r.parent_sid,
		   r.name, r.active, r.pos, r.info_xml, r.flag, r.acquisition_dtm, r.disposal_dtm, r.region_type,
		   r.lookup_key, r.region_ref, r.geo_country, r.geo_region, r.geo_city_id, r.geo_longitude, r.geo_latitude,
		   r.geo_type, r.map_entity, r.egrid_ref, r.egrid_ref_overridden,  r.last_modified_dtm
	  FROM v$resolved_region r
	  JOIN region_description rd ON NVL(r.link_to_region_sid, r.region_sid) = rd.region_sid
	   AND rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

--old temp meter reading structure for non realtime meters.
CREATE OR REPLACE VIEW csr.v$temp_meter_reading_rows AS
       SELECT t.source_row, t.region_sid, t.start_dtm, t.end_dtm, t.reference, t.note, t.reset_val,
              t.priority, v.consumption consumption, c.consumption cost,
			  v.import_conversion_id cons_import_conv_id, c.import_conversion_id cost_import_conv_id,
			  v.meter_conversion_id  cons_meter_conv_id , c.meter_conversion_id cost_meter_conv_id,
			  v.error_msg cons_error_msg, c.error_msg cost_error_msg
	    FROM ( SELECT DISTINCT source_row,
			    region_sid,
			    start_dtm,
			    end_dtm,
			    REFERENCE,
			    priority,
			    note,
			    reset_val
    			FROM csr.temp_meter_reading_rows
			  ) t
	LEFT JOIN csr.temp_meter_reading_rows v
		   ON v.source_row       = t.source_row
		  AND t.region_sid       = v.region_sid
		  AND v.meter_input_id IN (SELECT meter_input_id
									FROM csr.meter_input
									WHERE app_sid  = SYS_CONTEXT('SECURITY', 'APP')
									AND lookup_key = 'CONSUMPTION'
								  )
	LEFT JOIN csr.temp_meter_reading_rows c
		   ON c.source_row       = t.source_row
		  AND t.region_sid       = c.region_sid
		  AND c.meter_input_id IN (SELECT meter_input_id
									FROM csr.meter_input
									WHERE app_sid  = SYS_CONTEXT('SECURITY', 'APP')
									AND lookup_key = 'COST'
								  );

-- The current state of all approved meter readings
CREATE OR REPLACE VIEW csr.v$meter_reading AS
	SELECT mr.app_sid, mr.meter_reading_id, mr.region_sid, mr.start_dtm, mr.end_dtm, mr.val_number, mr.baseline_val,
		mr.entered_by_user_sid, mr.entered_dtm, mr.note, mr.reference, mr.cost, mr.meter_document_id, mr.created_invoice_id,
		mr.approved_dtm, mr.approved_by_sid, mr.is_estimate,
		mr.flow_item_id, mr.pm_reading_id,
		NVL(pi.format_mask,pm.format_mask) as format_mask
	  FROM csr.v$legacy_meter am
		JOIN csr.meter_reading mr ON am.app_sid = mr.app_sid
				AND am.region_sid = mr.region_sid
				AND am.meter_source_type_id = mr.meter_source_type_id
		LEFT JOIN csr.v$ind pi ON am.primary_ind_sid = pi.ind_sid AND am.app_sid = pi.app_sid
		LEFT JOIN csr.measure pm ON pi.measure_sid = pm.measure_sid AND pi.app_sid = pm.app_sid
	 WHERE mr.active = 1 AND req_approval = 0
;

CREATE OR REPLACE VIEW CSR.V$AGGR_METER_SOURCE_DATA AS
	SELECT app_sid, region_sid, meter_input_id, priority, start_dtm, end_dtm, 
		SUM(consumption) consumption, MAX(meter_raw_data_id) meter_raw_data_id
	  FROM csr.meter_source_data
	 GROUP BY app_sid, region_sid, meter_input_id, priority, start_dtm, end_dtm
;

-- If possible, avoid using this view if requiring meter details for a single meter
-- This query can be slow because Oracle can't pass a region_sid into the inner query
-- because of the windowing function mocking a meter_reading_id - which makes all queries
-- (for both legacy and urjanet meters) slow as they need 2 full table scans of meter_source_data
-- to be distincted to then be thrown away by the SQL that uses this view
CREATE OR REPLACE VIEW csr.v$meter_reading_multi_src AS
	WITH m AS (
		SELECT m.app_sid, m.region_sid legacy_region_sid, NULL urjanet_arb_region_sid, 0 auto_source
		  FROM csr.all_meter m
		 WHERE urjanet_meter_id IS NULL
		UNION
		SELECT app_sid, NULL legacy_region_sid, region_sid urjanet_arb_region_sid, 1 auto_source
		  FROM all_meter m
		 WHERE urjanet_meter_id IS NOT NULL
		   AND EXISTS (
			SELECT 1
			  FROM meter_source_data sd
			 WHERE sd.app_sid = m.app_sid
			   AND sd.region_sid = m.region_sid
		)
	)
	--
	-- Legacy meter readings part
	SELECT mr.app_sid, mr.meter_reading_id, mr.region_sid, mr.start_dtm, mr.end_dtm, mr.val_number, mr.cost,
		mr.baseline_val, mr.entered_by_user_sid, mr.entered_dtm, mr.note, mr.reference,
		mr.meter_document_id, mr.created_invoice_id, mr.approved_dtm, mr.approved_by_sid,
		mr.is_estimate, mr.flow_item_id, mr.pm_reading_id, mr.format_mask,
		m.auto_source
	  FROM m
	  JOIN csr.v$meter_reading mr on mr.app_sid = m.app_sid AND mr.region_sid = m.legacy_region_sid
	--
	-- Source data part
	UNION
	SELECT MAX(x.app_sid) app_sid, ROW_NUMBER() OVER (ORDER BY x.start_dtm) meter_reading_id,
		MAX(x.region_sid) region_sid, x.start_dtm, x.end_dtm, MAX(x.val_number) val_number, MAX(x.cost) cost,
		NULL baseline_val, 3 entered_by_user_sid, NULL entered_dtm, 
		REPLACE(STRAGG(x.note), ',', '; ') note,
		NULL reference, NULL meter_document_id, NULL created_invoice_id, NULL approved_dtm, NULL approved_by_sid,
		0 is_estimate, NULL flow_item_id, NULL pm_reading_id, NULL format_mask, x.auto_source
	FROM (
		-- Consumption (value part)
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, sd.consumption val_number, NULL cost, m.auto_source, NULL note
		  FROM m
		  JOIN csr.v$aggr_meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'CONSUMPTION' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
		-- Cost (value part)
		UNION
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, NULL val_number, sd.consumption cost, m.auto_source, NULL note
		  FROM m
		  JOIN csr.v$aggr_meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'COST' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
		-- Consumption (distinct note part)
		UNION
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, NULL val_number, NULL cost, m.auto_source, sd.note
		  FROM m
		  JOIN csr.meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'CONSUMPTION' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
		-- Cost (distinct note part)
		UNION
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, NULL val_number, NULL cost, m.auto_source, sd.note
		  FROM m
		  JOIN csr.meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'COST' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
	) x
	GROUP BY x.app_sid, x.region_sid, x.start_dtm, x.end_dtm, x.auto_source
;

-- A view similar to v$meter_reading_multi_src but just of the urjanet data to 
-- make the query simpler
CREATE OR REPLACE VIEW csr.v$meter_reading_urjanet
AS
SELECT x.app_sid, x.region_sid, x.start_dtm, x.end_dtm, MAX(x.val_number) val_number, MAX(x.cost) cost,
	   LISTAGG(x.note, '; ') WITHIN GROUP (ORDER BY NULL) note
  FROM (
	-- Consumption + Cost (value part)
	SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm,
			CASE WHEN ip.LOOKUP_KEY='CONSUMPTION' THEN sd.consumption END val_number,
			CASE WHEN ip.LOOKUP_KEY='COST' THEN sd.consumption END cost, NULL note
	  FROM all_meter m
	  JOIN v$aggr_meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.region_sid
	  JOIN meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key IN ('CONSUMPTION', 'COST') AND sd.meter_input_id = ip.meter_input_id
	  JOIN meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
	-- Consumption + cost (distinct note part)
	UNION
	SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, NULL val_number, NULL cost, sd.note
	  FROM all_meter m
	  JOIN csr.meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.region_sid
	  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key IN ('CONSUMPTION', 'COST') AND sd.meter_input_id = ip.meter_input_id
	  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
 ) x
 GROUP BY x.app_sid, x.region_sid, x.start_dtm, x.end_dtm
;

-- A view of all meter readings, approved or otherwise.
-- Because a pending reading can replace an existing reading this view may contain overlaps
CREATE OR REPLACE VIEW csr.v$meter_reading_all AS
	SELECT mr.app_sid, mr.meter_reading_id, mr.region_sid, mr.start_dtm, mr.end_dtm, mr.val_number, mr.baseline_val,
		mr.entered_by_user_sid, mr.entered_dtm, mr.note, mr.reference, mr.cost, mr.meter_document_id, mr.created_invoice_id,
		mr.approved_dtm, mr.approved_by_sid, mr.req_approval, mr.is_delete, mr.replaces_reading_id,
		mr.flow_item_id, mr.is_estimate
	  FROM csr.all_meter am, csr.meter_reading mr
	 WHERE am.app_sid = mr.app_sid
	   AND am.region_sid = mr.region_sid
	   AND am.meter_source_type_id = mr.meter_source_type_id
	   AND mr.active = 1
;

-- A view onto the latest version of meter readings (if all had been approved)
CREATE OR REPLACE VIEW csr.v$meter_reading_head AS
	SELECT mr.app_sid, mr.meter_reading_id, mr.region_sid, mr.start_dtm, mr.end_dtm, mr.val_number, mr.baseline_val,
		mr.entered_by_user_sid, mr.entered_dtm, mr.note, mr.reference, mr.cost, mr.meter_document_id, mr.created_invoice_id,
		mr.approved_dtm, mr.approved_by_sid, mr.req_approval, mr.is_delete, mr.replaces_reading_id,
		mr.flow_item_id, mr.is_estimate
	  FROM meter_reading mr, (
	 	SELECT meter_reading_id
	 	  FROM csr.v$meter_reading_all
	 	MINUS
	 	SELECT replaces_reading_id meter_reading_id
	 	  FROM csr.v$meter_reading_all
	 	 WHERE req_approval = 1
	 ) x
	 WHERE mr.meter_reading_id = x.meter_reading_id
	   AND mr.active = 1
;

CREATE OR REPLACE VIEW CSR.v$batch_job AS
	SELECT bj.app_sid, bj.batch_job_id, bj.batch_job_type_id, bj.description,
		   bjt.description batch_job_type_description, bj.requested_by_user_sid, bj.requested_by_company_sid,
	 	   cu.full_name requested_by_full_name, cu.email requested_by_email, bj.requested_dtm,
	 	   bj.email_on_completion, bj.started_dtm, bj.completed_dtm, bj.updated_dtm, bj.retry_dtm,
	 	   bj.work_done, bj.total_work, bj.running_on, bj.result, bj.result_url, bj.aborted_dtm, bj.failed
      FROM batch_job bj, batch_job_type bjt, csr_user cu
     WHERE bj.app_sid = cu.app_sid AND bj.requested_by_user_sid = cu.csr_user_sid
       AND bj.batch_job_type_id = bjt.batch_job_type_id;

/* property */
CREATE OR REPLACE VIEW CSR.PROPERTY
	(APP_SID, REGION_SID, FLOW_ITEM_ID,
	 STREET_ADDR_1, STREET_ADDR_2, CITY, STATE, POSTCODE,
	 COMPANY_SID, PROPERTY_TYPE_ID, PROPERTY_SUB_TYPE_ID,
	 MGMT_COMPANY_ID, MGMT_COMPANY_OTHER,
	 PM_BUILDING_ID, CURRENT_LEASE_ID, MGMT_COMPANY_CONTACT_ID,
	 ENERGY_STAR_SYNC, ENERGY_STAR_PUSH) AS
  SELECT ALP.APP_SID, ALP.REGION_SID, ALP.FLOW_ITEM_ID,
	 ALP.STREET_ADDR_1, ALP.STREET_ADDR_2, ALP.CITY, ALP.STATE, ALP.POSTCODE,
	 ALP.COMPANY_SID, ALP.PROPERTY_TYPE_ID, ALP.PROPERTY_SUB_TYPE_ID,
	 ALP.MGMT_COMPANY_ID, ALP.MGMT_COMPANY_OTHER,
	 ALP.PM_BUILDING_ID, ALP.CURRENT_LEASE_ID, ALP.MGMT_COMPANY_CONTACT_ID,
	 ENERGY_STAR_SYNC, ENERGY_STAR_PUSH
    FROM ALL_PROPERTY ALP JOIN region r ON r.region_sid = alp.region_sid
   WHERE r.region_type = 3;

CREATE OR REPLACE VIEW csr.v$property AS
    SELECT r.app_sid, r.region_sid, r.description, r.parent_sid, r.lookup_key, r.region_ref, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, c.country country_code,
        c.name country_name, c.currency country_currency, r.geo_type,
        pt.property_type_id, pt.label property_type_label,
        pst.property_sub_type_id, pst.label property_sub_type_label,
        p.flow_item_id, fi.current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key, fs.state_colour current_state_colour,
        r.active, r.acquisition_dtm, r.disposal_dtm, geo_longitude lng, geo_latitude lat, pf.fund_id,
        mgmt_company_id, mgmt_company_other, mgmt_company_contact_id, p.company_sid, p.pm_building_id,
        pt.lookup_key property_type_lookup_key,
        p.energy_star_sync, p.energy_star_push
      FROM property p
        JOIN v$region r ON p.region_sid = r.region_sid AND p.app_sid = r.app_sid
        LEFT JOIN postcode.country c ON r.geo_country = c.country
        LEFT JOIN property_type pt ON p.property_type_id = pt.property_type_id AND p.app_sid = pt.app_sid
        LEFT JOIN property_sub_type pst ON p.property_sub_type_id = pst.property_sub_type_id AND p.app_sid = pst.app_sid
        LEFT JOIN flow_item fi ON p.flow_item_id = fi.flow_item_id AND p.app_sid = fi.app_sid
        LEFT JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
		LEFT JOIN (
			-- In the case of multiple fund ownership, the "default" fund is the fund with the highest
			-- current ownership. Where multiple funds have the same ownership, the default is the 
			-- fund that was created first. Fund ID is retained for compatibility with pre-multi 
			-- ownership code.
			SELECT
				app_sid, region_sid, fund_id, ownership,
				ROW_NUMBER() OVER (PARTITION BY app_sid, region_sid
								   ORDER BY start_dtm DESC, ownership DESC, fund_id ASC) priority
			FROM csr.property_fund_ownership
		) pf ON pf.app_sid = r.app_sid AND pf.region_sid = r.region_sid AND pf.priority = 1;

CREATE OR REPLACE VIEW csr.v$property_fund_ownership AS 
	SELECT fo.app_sid, 
		   fo.region_sid, 
		   fo.fund_id, 
		   f.name,
		   pf.container_sid,
		   fo.start_dtm, 
		   LEAD(fo.start_dtm) OVER (PARTITION BY fo.app_sid, fo.region_sid, fo.fund_id 
										ORDER BY fo.start_dtm) end_dtm, 
		   fo.ownership
	  FROM property_fund_ownership fo
	  JOIN property_fund pf ON fo.app_sid = pf.app_sid AND pf.region_sid = fo.region_sid AND fo.fund_id = pf.fund_id
	  JOIN fund f ON fo.app_sid = f.app_sid AND fo.fund_id = f.fund_id
	 ORDER BY fo.region_sid, fo.fund_id, fo.start_dtm;

CREATE OR REPLACE VIEW csr.v$property_meter AS
	SELECT a.app_sid, a.region_sid, a.reference, r.description, r.parent_sid, a.note,
		NVL(mi.label, pi.description) group_label, mi.group_key,
		a.primary_ind_sid, pi.description primary_description,
		NVL(pmc.description, pm.description) primary_measure, pm.measure_sid primary_measure_sid, a.primary_measure_conversion_id,
		a.cost_ind_sid, ci.description cost_description, NVL(cmc.description, cm.description) cost_measure, a.cost_measure_conversion_id,
		ms.meter_source_type_id, ms.name source_type_name, ms.description source_type_description,
		a.manual_data_entry, ms.arbitrary_period, ms.add_invoice_data,
		ms.show_in_meter_list, ms.descending, ms.allow_reset, a.meter_type_id, r.active, r.region_type,
		r.acquisition_dtm, r.disposal_dtm
	  FROM csr.v$legacy_meter a
		JOIN meter_source_type ms ON a.meter_source_type_id = ms.meter_source_type_id AND a.app_sid = ms.app_sid
		JOIN v$region r ON a.region_sid = r.region_sid AND a.app_sid = r.app_sid
		LEFT JOIN meter_type mi ON a.meter_type_id = mi.meter_type_id
		LEFT JOIN v$ind pi ON a.primary_ind_sid = pi.ind_sid AND a.app_sid = pi.app_sid
		LEFT JOIN measure pm ON pi.measure_sid = pm.measure_sid AND pi.app_sid = pm.app_sid
		LEFT JOIN measure_conversion pmc ON a.primary_measure_conversion_id = pmc.measure_conversion_id AND a.app_sid = pmc.app_sid
		LEFT JOIN v$ind ci ON a.cost_ind_sid = ci.ind_sid AND a.app_sid = ci.app_sid
		LEFT JOIN measure cm ON ci.measure_sid = cm.measure_sid AND ci.app_sid = cm.app_sid
		LEFT JOIN measure_conversion cmc ON a.cost_measure_conversion_id = cmc.measure_conversion_id AND a.app_sid = cmc.app_sid;


-- bare-bones view  (can include dupes if you're in multiple matching roles)
-- TODO: check that the role is a property role?
CREATE OR REPLACE VIEW csr.v$my_property AS
    SELECT p.app_sid, p.region_sid, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode,
            p.property_type_id, p.flow_item_id,
            fi.current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key,
            fs.state_colour current_state_colour,
            r.role_sid, r.name role_name, fsr.is_editable, rg.active, p.pm_building_id
      FROM region_role_member rrm
        JOIN role r ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid
        JOIN flow_state_role fsr ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
        JOIN flow_state fs ON fsr.flow_state_id = fs.flow_state_id AND fsr.app_sid = fs.app_sid
        JOIN flow_item fi ON fs.flow_state_id = fi.current_state_id AND fs.app_sid = fi.app_sid
        JOIN property p ON fi.flow_item_id = p.flow_Item_id AND rrm.region_sid = p.region_sid AND rrm.app_sid = p.app_sid
        JOIN region rg ON p.region_sid = rg.region_sid AND p.app_Sid = rg.app_sid
     WHERE rrm.user_sid = SYS_CONTEXT('SECURITY','SID');

-- fuller-fat view (can include dupes if you're in multiple matching roles)
CREATE OR REPLACE VIEW csr.v$my_property_full AS
    SELECT r.app_sid, r.region_sid, r.description, r.parent_sid, r.lookup_key, r.region_ref, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, c.country country_code,
        c.name country_name, pt.property_type_id, pt.label property_type_label,
        p.flow_item_id, p.current_state_id, p.current_state_label, p.current_state_lookup_key,
        p.current_state_colour, p.role_sid, p.role_name, p.is_editable,
        r.active, r.acquisition_dtm, r.disposal_dtm, geo_longitude lng, geo_latitude lat, p.pm_building_id
      FROM csr.v$my_property p
        JOIN v$region r ON p.region_sid = r.region_sid AND p.app_sid = r.app_sid
        LEFT JOIN postcode.country c ON r.geo_country = c.country
        LEFT JOIN property_type pt ON p.property_type_id = pt.property_type_id AND p.app_sid = pt.app_sid;

CREATE OR REPLACE VIEW csr.v$lease AS
	SELECT l.lease_id, l.start_dtm, l.end_dtm, l.next_break_dtm, l.current_rent,
		   l.normalised_rent, l.next_rent_review, l.tenant_id, l.currency_code,
		   t.name tenant_name
	  FROM lease l
		LEFT JOIN tenant t ON t.tenant_id = l.tenant_id;

CREATE OR REPLACE VIEW CSR.SPACE
	(APP_SID, REGION_SID, SPACE_TYPE_ID,
	 PROPERTY_REGION_SID, PROPERTY_TYPE_ID, CURRENT_LEASE_ID) AS
  SELECT ALS.APP_SID, ALS.REGION_SID, ALS.SPACE_TYPE_ID,
	 ALS.PROPERTY_REGION_SID, ALS.PROPERTY_TYPE_ID, ALS.CURRENT_LEASE_ID
    FROM ALL_SPACE ALS JOIN region r ON r.region_sid = ALS.region_sid
   WHERE r.region_type = 9;

CREATE OR REPLACE VIEW csr.v$space AS
	SELECT s.app_sid, s.region_sid, r.description, r.active, r.parent_sid, s.space_type_id, st.label space_type_label, s.current_lease_id, s.property_region_Sid,
		   l.tenant_name current_tenant_name, r.disposal_dtm
	  FROM csr.space s
	  JOIN v$region r on s.region_sid = r.region_sid
	  JOIN space_type st ON s.space_type_Id = st.space_type_id
	  LEFT JOIN v$lease l ON l.lease_id = s.current_lease_id;

/* activities */
CREATE OR REPLACE VIEW CSR.V$ACTIVITY AS
    SELECT a.app_sid, a.activity_id,
        a.region_sid, r.description region_description,
        a.label, a.short_label, a.description,
        a.activity_type_Id, t.label activity_type_label,
        a.activity_sub_type_Id, st.label activity_sub_type_label,
        a.created_by_sid, cu.full_name created_by_name, a.created_dtm,
        a.flow_item_id, fs.flow_state_Id, fs.label flow_state_label, fs.state_colour,
        c.name country_name, c.currency country_currency,
        t.track_time, t.track_money, NVL(st.base_css_class, t.base_css_class) base_css_class,
        CASE WHEN (open_dtm IS NULL OR SYSDATE >= open_dtm) AND (close_dtm IS NULL OR SYSDATE < close_dtm) THEN 1 ELSE 0 END is_running,
        a.start_dtm, a.end_dtm, a.open_dtm, a.close_dtm, a.is_members_only, a.active, t.matched_giving_policy_id,
        a.img_last_modified_dtm, a.img_sha1, a.img_mime_type
      FROM activity a
      JOIN v$region r ON a.region_sid = r.region_sid AND a.app_sid = r.app_sid
      JOIN activity_type t ON a.activity_type_id = t.activity_type_id AND a.app_sid = t.app_sid
      JOIN flow_item fi ON a.flow_item_id = fi.flow_item_id AND a.app_sid = fi.app_sid
      JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
      JOIN csr_user cu ON a.created_by_sid = cu.csr_user_sid AND a.app_sid = cu.app_sid
      LEFT JOIN activity_sub_type st ON a.activity_sub_type_id = st.activity_sub_type_id AND a.activity_type_id = st.activity_type_id AND a.app_sid = t.app_sid
      LEFT JOIN postcode.country c ON r.geo_country = c.country;

CREATE OR REPLACE VIEW CSR.V$MY_ACTIVITY AS
	SELECT a.app_sid, a.activity_id, a.region_sid, a.region_description, a.label, a.short_label, a.description,
		a.activity_type_Id, a.activity_type_label, a.activity_sub_type_Id, a.activity_sub_type_label, a.created_by_sid,
		a.created_by_name, a.created_dtm, a.flow_item_id, a.flow_state_Id, a.flow_state_label, a.state_colour, a.country_name,
		a.country_currency, a.track_time, a.track_money, a.base_css_class, a.is_running, a.start_dtm, a.end_dtm, a.open_dtm,
		a.close_dtm, a.is_members_only, a.active
	  FROM v$activity a
	  JOIN activity_member am ON a.activity_id = am.activity_id AND a.app_sid = am.app_sid
	 WHERE am.user_sid = SYS_CONTEXT('SECURITY','SID')
	   AND a.active = 1
	   AND a.is_running = 1;

CREATE OR REPLACE VIEW CSR.V$USER_FEED AS
    SELECT uf.user_feed_id, uf.action_dtm,
    	uf.acting_user_sid, cua.full_name acting_user_full_name,
        uf.target_user_sid, cut.full_name target_user_full_name,
        uf.target_activity_id, a.label target_activity,
        target_param_1, target_param_2, target_param_3,
        ufa.action_text, ufa.action_url, ufa.label action_label, ufa.action_img_url
      FROM user_feed uf
      JOIN user_feed_action ufa ON uf.user_feed_action_id = ufa.user_feed_action_id
      JOIN csr_user cua ON uf.acting_user_sid = cua.csr_user_sid AND uf.app_sid = cua.app_sid
      LEFT JOIN csr_user cut ON uf.target_user_sid = cut.csr_user_sid AND uf.app_sid = cut.app_sid
      LEFT JOIN activity a ON uf.target_activity_id = a.activity_id AND uf.app_sid = a.app_sid;

/* user messages */
CREATE OR REPLACE VIEW CSR.V$USER_MSG AS
	SELECT um.user_msg_id, um.user_sid, cu.full_name, cu.email, um.msg_dtm, um.msg_text, um.reply_to_msg_id
	  FROM user_msg um
	  JOIN csr_user cu ON um.user_sid = cu.csr_user_sid AND um.app_sid = cu.app_sid;

CREATE OR REPLACE VIEW CSR.V$USER_MSG_FILE AS
	SELECT umf.user_msg_file_id, umf.user_msg_id, cast(umf.sha1 as varchar2(40)) sha1, umf.mime_type,
		um.msg_dtm last_modified_dtm
	  FROM user_msg um
	  JOIN user_msg_file umf ON um.user_msg_id = umf.user_msg_id;

CREATE OR REPLACE VIEW CSR.V$USER_MSG_LIKE AS
	SELECT uml.user_msg_id, uml.liked_by_user_sid, uml.liked_dtm, cu.full_name, cu.email
	  FROM user_msg_like uml
	  JOIN csr_user cu ON uml.liked_by_user_sid = cu.csr_user_sid AND uml.app_sid = cu.app_sid;

/* text */
CREATE OR REPLACE VIEW csr.v$my_section AS
    SELECT s.section_sid, firm.current_state_id, MAX(firm.is_editable) is_editable, 'F' source
      FROM csr.v$flow_item_role_member firm
        JOIN csr.section s ON firm.flow_item_id = s.flow_item_id AND firm.app_sid = s.app_sid
        JOIN csr.section_module sm
            ON s.module_root_sid = sm.module_root_sid AND s.app_sid = sm.app_sid
            AND firm.region_sid = sm.region_sid AND firm.app_sid = sm.app_sid
     WHERE NOT EXISTS (
        -- exclude if sections are currently in a workflow state that is routed
        SELECT null FROM csr.section_routed_flow_state WHERE flow_state_id = firm.current_state_id
     )
     GROUP BY s.section_sid, firm.current_state_id
    UNION ALL
    -- everything where the section is currently in a workflow state that is routed, and the user is in the currently route_step
    SELECT s.section_sid, fi.current_state_id, 1 is_editable, 'R' source
      FROM csr.section s
        JOIN csr.flow_item fi ON s.flow_item_id = fi.flow_item_id AND s.app_sid = fi.app_sid
        JOIN csr.route r ON fi.current_state_id = r.flow_state_id AND fi.app_sid = r.app_sid
        JOIN csr.route_step rs
            ON r.route_id = rs.route_id AND r.app_sid = rs.app_sid
            AND s.current_route_step_id = rs.route_step_id AND s.app_sid = rs.app_sid
        JOIN csr.route_step_user rsu
            ON rs.route_step_id = rsu.route_step_id
            AND rs.app_sid = rsu.app_sid
            AND rsu.csr_user_sid = SYS_CONTEXT('SECURITY','SID')
      WHERE s.current_route_step_id NOT IN (
		SELECT route_step_id FROM route_step_vote WHERE user_sid = SYS_CONTEXT('SECURITY','SID')
      );

CREATE OR REPLACE VIEW csr.v$current_user_cover AS
	SELECT user_being_covered_sid
	  FROM csr.user_cover
	 WHERE user_giving_cover_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND start_dtm < SYSDATE
	   AND (end_dtm IS NULL OR end_dtm > SYSDATE)
	   AND cover_terminated = 0;


CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label,
		   NVL2(ia.internal_audit_ref, atg.internal_audit_ref_prefix || ia.internal_audit_ref, null) custom_audit_id,
		   atg.internal_audit_ref_prefix, ia.internal_audit_ref, ia.ovw_validity_dtm,
		   ia.auditor_user_sid, NVL(cu.full_name, au.full_name) auditor_full_name, sr.submitted_dtm survey_completed,
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, r.geo_longitude longitude, r.geo_latitude latitude, rt.class_name region_type_class_name,
		   ia.auditee_user_sid, u.full_name auditee_full_name, u.email auditee_email,
		   SUBSTR(ia.notes, 1, 50) short_notes, ia.notes full_notes,
		   iat.internal_audit_type_id audit_type_id, iat.label audit_type_label, iat.internal_audit_type_source_id audit_type_source_id,
		   qs.label survey_label, ia.app_sid, ia.internal_audit_type_id, iat.auditor_role_sid,
		   iat.audit_contact_role_sid, ia.audit_closure_type_id, act.label closure_label, act.icon_image_filename, cast(act.icon_image_sha1  as varchar2(40)) icon_image_sha1,
		   ia.created_by_user_sid, ia.survey_response_id, ia.created_dtm, NVL(cu.email, au.email) auditor_email,
		   iat.assign_issues_to_role, iat.add_nc_per_question, cvru.user_giving_cover_sid cover_auditor_sid,
		   fi.flow_sid, f.label flow_label, ia.flow_item_id, fi.current_state_id, fs.label flow_state_label, fs.is_final flow_state_is_final, 
		   fs.state_colour flow_state_colour, act.is_failure,
		   sqs.survey_sid summary_survey_sid, sqs.label summary_survey_label, ssr.survey_version summary_survey_version, ia.summary_response_id,
		   ia.auditor_company_sid, ac.name auditor_company_name, iat.tab_sid, iat.form_path, ia.comparison_response_id, iat.nc_audit_child_region,
		   atg.label ia_type_group_label, atg.lookup_key ia_type_group_lookup_key, atg.internal_audit_type_group_id, iat.form_sid,
		   atg.audit_singular_label, atg.audit_plural_label, atg.auditee_user_label, atg.auditor_user_label, atg.auditor_name_label,
		   sr.overall_score survey_overall_score, sr.overall_max_score survey_overall_max_score, sr.survey_version,
		   sst.score_type_id survey_score_type_id, sr.score_threshold_id survey_score_thrsh_id, sst.label survey_score_label, sst.format_mask survey_score_format_mask,
		   ia.nc_score, iat.nc_score_type_id, NVL(ia.ovw_nc_score_thrsh_id, ia.nc_score_thrsh_id) nc_score_thrsh_id, ncst.max_score nc_max_score, ncst.label nc_score_label,
		   ncst.format_mask nc_score_format_mask, ia.permit_id, ia.external_audit_ref, ia.external_parent_ref, ia.external_url,
		   CASE (atct.re_audit_due_after_type)
				WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
				WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
				WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
				WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
				ELSE ia.ovw_validity_dtm END next_audit_due_dtm,
		   iat.use_legacy_closed_definition
	  FROM csr.internal_audit ia
	  LEFT JOIN (
			SELECT auc.app_sid, auc.internal_audit_sid, auc.user_giving_cover_sid,
				   ROW_NUMBER() OVER (PARTITION BY auc.internal_audit_sid ORDER BY LEVEL DESC, uc.start_dtm DESC,  uc.user_cover_id DESC) rn,
				   CONNECT_BY_ROOT auc.user_being_covered_sid user_being_covered_sid
			  FROM csr.audit_user_cover auc
			  JOIN csr.user_cover uc ON auc.app_sid = uc.app_sid AND auc.user_cover_id = uc.user_cover_id
			 CONNECT BY NOCYCLE PRIOR auc.app_sid = auc.app_sid AND PRIOR auc.user_being_covered_sid = auc.user_giving_cover_sid
		) cvru
	    ON ia.internal_audit_sid = cvru.internal_audit_sid
	   AND ia.app_sid = cvru.app_sid AND ia.auditor_user_sid = cvru.user_being_covered_sid
	   AND cvru.rn = 1
	  LEFT JOIN csr.csr_user u ON ia.auditee_user_sid = u.csr_user_sid AND ia.app_sid = u.app_sid
	  JOIN csr.csr_user au ON ia.auditor_user_sid = au.csr_user_sid AND ia.app_sid = au.app_sid
	  LEFT JOIN csr.csr_user cu ON cvru.user_giving_cover_sid = cu.csr_user_sid AND cvru.app_sid = cu.app_sid
	  LEFT JOIN csr.internal_audit_type iat ON ia.app_sid = iat.app_sid AND ia.internal_audit_type_id = iat.internal_audit_type_id
	  LEFT JOIN csr.internal_audit_type_group atg ON atg.app_sid = iat.app_sid AND atg.internal_audit_type_group_id = iat.internal_audit_type_group_id
	  LEFT JOIN csr.v$quick_survey_response sr ON ia.survey_response_id = sr.survey_response_id AND ia.app_sid = sr.app_sid
	  LEFT JOIN csr.v$quick_survey_response ssr ON ia.summary_response_id = ssr.survey_response_id AND ia.app_sid = ssr.app_sid
	  LEFT JOIN csr.v$quick_survey qs ON ia.survey_sid = qs.survey_sid AND ia.app_sid = qs.app_sid
	  LEFT JOIN csr.v$quick_survey sqs ON NVL(ssr.survey_sid, iat.summary_survey_sid) = sqs.survey_sid AND iat.app_sid = sqs.app_sid
	  LEFT JOIN (
			SELECT anc.app_sid, anc.internal_audit_sid, COUNT(DISTINCT anc.non_compliance_id) cnt
			  FROM csr.audit_non_compliance anc
			  JOIN csr.non_compliance nnc ON anc.non_compliance_id = nnc.non_compliance_id AND anc.app_sid = nnc.app_sid
			  LEFT JOIN csr.issue_non_compliance inc ON nnc.non_compliance_id = inc.non_compliance_id AND nnc.app_sid = inc.app_sid
			  LEFT JOIN csr.issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id AND inc.app_sid = i.app_sid
			 WHERE ((nnc.is_closed IS NULL
			   AND i.resolved_dtm IS NULL
			   AND i.rejected_dtm IS NULL
			   AND i.deleted = 0)
			    OR nnc.is_closed = 0)
			 GROUP BY anc.app_sid, anc.internal_audit_sid
			) nc ON ia.internal_audit_sid = nc.internal_audit_sid AND ia.app_sid = nc.app_sid
	  LEFT JOIN csr.v$region r ON ia.app_sid = r.app_sid AND ia.region_sid = r.region_sid
	  LEFT JOIN csr.region_type rt ON r.region_type = rt.region_type
	  LEFT JOIN csr.audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id AND ia.app_sid = act.app_sid
	  LEFT JOIN csr.audit_type_closure_type atct ON ia.audit_closure_type_id = atct.audit_closure_type_id AND ia.internal_audit_type_id = atct.internal_audit_type_id AND ia.app_sid = atct.app_sid
	  LEFT JOIN csr.flow_item fi
	    ON ia.app_sid = fi.app_sid AND ia.flow_item_id = fi.flow_item_id
	  LEFT JOIN csr.flow_state fs
	    ON fs.app_sid = fi.app_sid AND fs.flow_state_id = fi.current_state_id
	  LEFT JOIN csr.flow f
	    ON f.app_sid = fi.app_sid AND f.flow_sid = fi.flow_sid
	  LEFT JOIN chain.company ac
	    ON ia.auditor_company_sid = ac.company_sid AND ia.app_sid = ac.app_sid
	  LEFT JOIN score_type ncst ON ncst.app_sid = iat.app_sid AND ncst.score_type_id = iat.nc_score_type_id
	  LEFT JOIN score_type sst ON sst.app_sid = qs.app_sid AND sst.score_type_id = qs.score_type_id
	 WHERE ia.deleted = 0;

CREATE OR REPLACE VIEW csr.v$all_audit_validity AS --more basic version of v$audit_next_due that returns all audits carried out and their validity instead of just the most recent of each 	 
	SELECT ia.internal_audit_sid, ia.internal_audit_type_id, ia.region_sid,
	ia.audit_dtm previous_audit_dtm, act.audit_closure_type_id, ia.app_sid,
	CASE (atct.re_audit_due_after_type)
		WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
		WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
		WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
		WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
		ELSE ia.ovw_validity_dtm
	END next_audit_due_dtm, atct.reminder_offset_days, act.label closure_label,
	act.is_failure, ia.label previous_audit_label, act.icon_image_filename,
	ia.auditor_user_sid previous_auditor_user_sid, ia.flow_item_id, ia.ovw_validity_dtm
	  FROM csr.internal_audit ia
	  LEFT JOIN csr.audit_type_closure_type atct
		ON ia.audit_closure_type_id = atct.audit_closure_type_id
	   AND ia.app_sid = atct.app_sid
	   AND ia.internal_audit_type_id = atct.internal_audit_type_id
	  LEFT JOIN csr.audit_closure_type act
		ON atct.audit_closure_type_id = act.audit_closure_type_id
	   AND atct.app_sid = act.app_sid
	 WHERE ia.deleted = 0;	 
	 
CREATE OR REPLACE VIEW csr.v$audit_validity AS --more restrictive version of v$all_audit_validity that only returns audits that have a validity
	SELECT internal_audit_sid, internal_audit_type_id, region_sid,
	previous_audit_dtm, audit_closure_type_id, app_sid,
    next_audit_due_dtm, reminder_offset_days, closure_label,
	is_failure, previous_audit_label, icon_image_filename,
	previous_auditor_user_sid, flow_item_id
	  FROM v$all_audit_validity ia
	   WHERE (ia.audit_closure_type_id IS NOT NULL OR ia.ovw_validity_dtm IS NOT NULL);

CREATE OR REPLACE VIEW csr.v$audit_next_due AS
	SELECT ia.internal_audit_sid, ia.internal_audit_type_id, ia.region_sid,
		   ia.audit_dtm previous_audit_dtm, act.audit_closure_type_id, ia.app_sid,
		   CASE (atct.re_audit_due_after_type)
				WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
				WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
				WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
				WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
				ELSE ia.ovw_validity_dtm
		   END next_audit_due_dtm, atct.reminder_offset_days, act.label closure_label,
		   act.is_failure, ia.label previous_audit_label, act.icon_image_filename,
		   ia.auditor_user_sid previous_auditor_user_sid, ia.flow_item_id,
		   cast(act.icon_image_sha1 as VARCHAR2(40)) icon_image_sha1
	  FROM (
		SELECT internal_audit_sid, internal_audit_type_id, region_sid, audit_dtm,
			   ROW_NUMBER() OVER (
					PARTITION BY internal_audit_type_id, region_sid
					ORDER BY audit_dtm DESC) rn, -- take most recent audit of each type/region
			   audit_closure_type_id, app_sid, label, auditor_user_sid, flow_item_id, deleted, ovw_validity_dtm
		  FROM csr.internal_audit
		 WHERE deleted = 0
		   ) ia
	  LEFT JOIN csr.audit_type_closure_type atct
		ON ia.audit_closure_type_id = atct.audit_closure_type_id
	   AND ia.app_sid = atct.app_sid
	   AND ia.internal_audit_type_id = atct.internal_audit_type_id
	  LEFT JOIN csr.audit_closure_type act
		ON atct.audit_closure_type_id = act.audit_closure_type_id
	   AND atct.app_sid = act.app_sid
	  JOIN csr.region r ON ia.region_sid = r.region_sid AND ia.app_sid = r.app_sid
	 WHERE rn = 1
	   AND r.active=1
	   AND ia.deleted = 0
       AND CASE (atct.re_audit_due_after_type)
				WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
				WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
				WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
				WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
				ELSE ia.ovw_validity_dtm
		   END IS NOT NULL;

CREATE OR REPLACE VIEW CSR.v$flow_state_alert_user AS
    SELECT a.flow_sid, a.flow_state_alert_id, au.user_sid
      FROM flow_state_alert a
      JOIN flow_state_alert_user au ON au.flow_sid = a.flow_sid AND au.flow_state_alert_id = a.flow_state_alert_id
    UNION
    SELECT a.flow_sid, a.flow_state_alert_id, rrm.user_sid
      FROM flow_state_alert a
      JOIN flow_state_alert_role ar ON ar.flow_sid = a.flow_sid AND ar.flow_state_alert_id = a.flow_state_alert_id
      JOIN region_role_member rrm ON rrm.role_sid = ar.role_sid AND rrm.region_sid = rrm.inherited_from_sid
;

-- Selects all initiative/user associations, either by role or initiatvie user gorup
CREATE OR REPLACE VIEW csr.v$initiative_user AS
    SELECT app_sid, user_sid, initiative_sid, region_sid, flow_state_id,
        flow_state_label, flow_state_lookup_key, flow_state_colour, active,
        MAX(is_editable) is_editable, MAX(generate_alerts) generate_alerts
    FROM (
        SELECT rrm.user_sid,
            i.app_sid, i.initiative_sid,
            ir.region_sid,
            fi.current_state_id flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.state_colour flow_state_colour,
            MAX(fsr.is_editable) is_editable,
            1 generate_alerts,
            rg.active
            FROM region_role_member rrm
            JOIN role r ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid
            JOIN flow_state_role fsr ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
            JOIN flow_state fs ON fsr.flow_state_id = fs.flow_state_id AND fsr.app_sid = fs.app_sid
            JOIN flow_item fi ON fs.flow_state_id = fi.current_state_id AND fs.app_sid = fi.app_sid
            JOIN initiative i ON fi.flow_item_id = i.flow_Item_id AND fi.app_sid = i.app_sid
            JOIN initiative_region ir ON i.initiative_sid = ir.initiative_sid AND rrm.region_sid = ir.region_sid AND rrm.app_sid = ir.app_sid
            JOIN region rg ON ir.region_sid = rg.region_sid AND ir.app_Sid = rg.app_sid
         GROUP BY rrm.user_sid,
            i.app_sid, i.initiative_sid,
            ir.region_sid,
            fi.current_state_id, fs.label, fs.lookup_key, fs.state_colour,
            r.role_sid, r.name,
            rg.active
        UNION
        SELECT iu.user_sid,
            i.app_sid, i.initiative_sid,
            ir.region_sid,
            fi.current_state_id flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.state_colour flow_state_colour,
            MAX(igfs.is_editable) is_editable,
            MAX(igfs.generate_alerts) generate_alerts,
            rg.active
            FROM initiative_user iu
            JOIN initiative i ON iu.initiative_sid = i.initiative_sid AND iu.app_sid = i.app_sid
            JOIN flow_item fi ON i.flow_item_id = fi.flow_item_id AND i.app_sid = fi.app_sid
            JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.flow_sid = fs.flow_sid AND fi.app_sid = fs.app_sid
            JOIN initiative_project_user_group ipug
            ON iu.initiative_user_group_id = ipug.initiative_user_group_id
             AND iu.project_sid = ipug.project_sid
            JOIN initiative_group_flow_state igfs
            ON ipug.initiative_user_group_id = igfs.initiative_user_group_id
             AND ipug.project_sid = igfs.project_sid
             AND ipug.app_sid = igfs.app_sid
             AND fs.flow_state_id = igfs.flow_State_id AND fs.flow_sid = igfs.flow_sid AND fs.app_sid = igfs.app_sid
            JOIN initiative_region ir ON ir.initiative_sid = i.initiative_sid AND ir.app_sid = i.app_sid
            JOIN region rg ON ir.region_sid = rg.region_sid AND ir.app_Sid = rg.app_sid
            LEFT JOIN rag_status rs ON i.rag_status_id = rs.rag_status_id AND i.app_sid = rs.app_sid
         GROUP BY iu.user_sid,
            i.app_sid, i.initiative_sid, ir.region_sid,
            fi.current_state_id, fs.label, fs.lookup_key, fs.state_colour,
            rg.active
    ) GROUP BY app_sid, user_sid, initiative_sid, region_sid, flow_state_id,
        flow_state_label, flow_state_lookup_key, flow_state_colour, active;

CREATE OR REPLACE VIEW csr.v$my_initiatives AS
	SELECT  i.app_sid, i.initiative_sid,
		ir.region_sid,
		fi.current_state_id flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.state_colour flow_state_colour, fs.pos flow_state_pos,
		r.role_sid, r.name role_name,
		MAX(fsr.is_editable) is_editable,
		rg.active,
		null owner_sid, i.internal_ref, i.name, i.project_sid
		FROM  region_role_member rrm
		JOIN  role r ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid
		JOIN flow_state_role fsr ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
		JOIN flow_state fs ON fsr.flow_state_id = fs.flow_state_id AND fsr.app_sid = fs.app_sid
		JOIN flow_item fi ON fs.flow_state_id = fi.current_state_id AND fs.app_sid = fi.app_sid
		JOIN initiative i ON fi.flow_item_id = i.flow_Item_id AND fi.app_sid = i.app_sid
		JOIN initiative_region ir ON i.initiative_sid = ir.initiative_sid AND rrm.region_sid = ir.region_sid AND rrm.app_sid = ir.app_sid
		JOIN region rg ON ir.region_sid = rg.region_sid AND ir.app_Sid = rg.app_sid
	 WHERE  rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
	 GROUP BY i.app_sid, i.initiative_sid,
		ir.region_sid,
		fi.current_state_id, fs.label, fs.lookup_key, fs.state_colour, fs.pos,
		r.role_sid, r.name,
		rg.active, i.internal_ref, i.name, i.project_sid
	 UNION ALL
	SELECT  i.app_sid, i.initiative_sid, ir.region_sid,
		fi.current_state_id flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.state_colour flow_state_colour, fs.pos flow_state_pos,
		null role_sid,  null role_name,
		MAX(igfs.is_editable) is_editable,
		rg.active,
		iu.user_sid owner_sid, i.internal_ref, i.name, i.project_sid
		FROM initiative_user iu
		JOIN initiative i ON iu.initiative_sid = i.initiative_sid AND iu.app_sid = i.app_sid
		JOIN flow_item fi ON i.flow_item_id = fi.flow_item_id AND i.app_sid = fi.app_sid
		JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.flow_sid = fs.flow_sid AND fi.app_sid = fs.app_sid
		JOIN initiative_project_user_group ipug
		ON iu.initiative_user_group_id = ipug.initiative_user_group_id
		 AND iu.project_sid = ipug.project_sid
		JOIN initiative_group_flow_state igfs
		ON ipug.initiative_user_group_id = igfs.initiative_user_group_id
		 AND ipug.project_sid = igfs.project_sid
		 AND ipug.app_sid = igfs.app_sid
		 AND fs.flow_state_id = igfs.flow_State_id AND fs.flow_sid = igfs.flow_sid AND fs.app_sid = igfs.app_sid
		JOIN initiative_region ir ON ir.initiative_sid = i.initiative_sid AND ir.app_sid = i.app_sid
		JOIN region rg ON ir.region_sid = rg.region_sid AND ir.app_Sid = rg.app_sid
		LEFT JOIN rag_status rs ON i.rag_status_id = rs.rag_status_id AND i.app_sid = rs.app_sid
	 WHERE iu.user_sid = SYS_CONTEXT('SECURITY','SID')
	 GROUP BY i.app_sid, i.initiative_sid, ir.region_sid,
		fi.current_state_id, fs.label, fs.lookup_key, fs.state_colour, fs.pos,
		rg.active, iu.user_sid, i.internal_ref, i.name, i.project_sid;

-- extracts unanswered questions from quick survey responses
CREATE OR REPLACE VIEW csr.v$quick_survey_unans_quest AS
    SELECT qsr.app_sid, qsr.survey_sid, qsr.survey_response_id, qsq.question_id, qsq.pos AS question_pos, qsq.question_type, qsq.label AS question_label
	  FROM csr.v$quick_survey_response qsr
	  JOIN csr.quick_survey_question qsq ON qsq.app_sid = qsr.app_sid AND qsq.survey_sid = qsr.survey_sid AND qsr.survey_version = qsq.survey_version
	 WHERE qsq.parent_id IS NULL
	   AND qsq.is_visible = 1
	   AND qsq.question_type NOT IN ('section', 'pagebreak', 'files', 'richtext')
	   AND ( -- questions without nested answers
	    (qsq.question_type IN ('note', 'number', 'slider', 'date', 'regionpicker', 'radio', 'rtquestion')
		 AND (qsq.question_id IN (
		   SELECT question_id
		     FROM csr.v$quick_survey_answer
		    WHERE app_sid = qsr.app_sid
		     AND survey_response_id = qsr.survey_response_id
			 AND (answer IS NULL AND question_option_id IS NULL AND val_number IS NULL AND region_sid IS NULL))))
		-- questions with nested answers
		OR (qsq.question_type = 'checkboxgroup'
		 AND NOT EXISTS ( -- consider as unanswered if none of the options are ticked
		   SELECT qsq1.question_id
		     FROM csr.quick_survey_question qsq1, csr.v$quick_survey_answer qsa1
		    WHERE qsa1.app_sid = qsr.app_sid
			  AND qsa1.survey_response_id = qsr.survey_response_id
			  AND qsq1.parent_id = qsq.question_id
			  AND qsq1.question_id = qsa1.question_id
			  AND qsq1.survey_version = qsa1.survey_version
			  AND qsq1.is_visible = 1
			  AND qsa1.val_number = 1))
		OR (qsq.question_type = 'matrix'
		 AND EXISTS ( -- consider as unanswered if any of the options/matrix-rows are not filled
		   SELECT qsq1.question_id
		     FROM csr.quick_survey_question qsq1, csr.quick_survey_answer qsa1
			WHERE qsa1.app_sid = qsr.app_sid
			  AND qsa1.survey_response_id = qsr.survey_response_id
			  AND qsq1.parent_id = qsq.question_id
			  AND qsq1.question_id = qsa1.question_id
			  AND qsq1.survey_version = qsa1.survey_version
			  AND qsq1.is_visible = 1
			  AND qsa1.question_option_id IS NULL))
		);

-- terms and conditions documents
CREATE OR REPLACE VIEW csr.v$term_cond_doc AS
	SELECT tcd.doc_id, dv.filename, tcd.version, tcd.company_type_id, dv.description
	  FROM (
	    SELECT DISTINCT tcd.doc_id, dc.version, tcd.company_type_id
	      FROM csr.term_cond_doc tcd
	      JOIN csr.doc_current dc ON dc.app_sid = tcd.app_sid AND dc.doc_id = tcd.doc_id
	     WHERE tcd.app_sid = security_pkg.GetApp
		   AND dc.locked_by_sid IS NULL -- only set if current doc version needs approval or it has been marked as deleted
		   ) tcd
	  JOIN csr.doc_version dv ON dv.app_sid = security_pkg.GetApp AND dv.doc_id = tcd.doc_id AND dv.version = tcd.version;

-- ugh -> this looks nasty -- analytic function or store the id?
-- hang on? Bizarre. It doesn't even _use_ sal2??!
CREATE OR REPLACE VIEW csr.v$section_attach_log_last AS
	SELECT sal.app_sid,
			sal.section_attach_log_id,
			sal.section_sid,
			sal.attachment_id,
			sal.log_date changed_dtm,
			sal.csr_user_sid changed_by_sid,
			cu.full_name changed_by_name,
			sal.summary,
			sal.description
	  FROM section_attach_log sal
	  JOIN csr_user cu ON sal.csr_user_sid = cu.csr_user_sid AND sal.app_sid = cu.app_sid
	  JOIN (
		SELECT app_sid, attachment_id, MAX(log_date) log_date
		  FROM section_attach_log
		 GROUP BY app_sid, attachment_id
	) sal2 ON sal.app_sid = sal2.app_sid AND sal.log_date = sal2.log_date AND sal.attachment_id = sal2.attachment_id;



CREATE OR REPLACE VIEW csr.v$est_account AS
	SELECT a.app_sid, a.est_account_sid, a.est_account_id, a.account_customer_id,
		g.connect_job_interval, g.last_connect_job_dtm,
		a.share_job_interval, a.last_share_job_dtm,
		a.building_job_interval, a.meter_job_interval,
		a.auto_map_customer, a.allow_delete
	 FROM csr.est_account a
	 JOIN csr.est_account_global g ON a.est_account_id = g.est_account_id
;

CREATE OR REPLACE VIEW csr.V$ENHESA_TOPIC AS
    SELECT t.app_sid, t.topic_id, t.country_code, ecn.name country, stn.status_id, stn.name status,
        t.report_dtm, t.adoption_dtm, t.importance, t.archived, t.version topic_version, t.url, t.region_sid,
        tt.version text_version, tt.version_pub_dtm text_version_pub_dtm, tt.title, tt.abstract, tt.analysis, tt.affected_ops,
        tt.reg_citation, tt.biz_impact, t.flow_item_id, fs.label flow_state_label, fs.state_colour, fs.lookup_key state_lookup_key
      FROM csr.enhesa_topic t
      JOIN csr.enhesa_topic_text tt ON t.topic_id = tt.topic_id AND tt.lang = 'en'
      JOIN csr.enhesa_status_name stn ON t.status_id = stn.status_id AND stn.lang = 'en'
      JOIN csr.enhesa_country_name ecn ON t.country_code = ecn.country_code AND ecn.lang = 'en'
      JOIN csr.flow_item fi ON t.flow_item_id = fi.flow_item_id AND t.app_sid = fi.app_sid
      JOIN csr.flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
    ;

CREATE OR REPLACE VIEW csr.V$ENHESA_TOPIC_REGION AS
    SELECT tr.topic_id, tr.country_code, cn.name country, tr.region_code, crn.name region
      FROM csr.enhesa_topic_region tr
      JOIN csr.enhesa_country_name cn ON tr.country_code = cn.country_code AND cn.lang = 'en'
      JOIN csr.enhesa_country_region_name crn ON tr.country_code = crn.country_code AND tr.region_code = crn.region_code AND crn.lang = 'en'
    ;

CREATE OR REPLACE VIEW csr.V$ENHESA_TOPIC_KEYWORD AS
    SELECT tk.topic_id, tk.keyword_id, kt.main, kt.category
      FROM csr.enhesa_topic_keyword tk
      JOIN csr.enhesa_keyword_text kt ON tk.keyword_id = kt.keyword_id AND kt.lang = 'en'
    ;

CREATE OR REPLACE VIEW csr.V$ENHESA_TOPIC_REG AS
    SELECT tr.topic_id, tr.reg_id, r.parent_reg_id, r.reg_ref, rt.title, r.ref_dtm, r.link, r.archived, r.version reg_version,
        r.reg_level, rt.version reg_text_version, rt.version_pub_dtm reg_text_version_pub_dtm
      FROM csr.enhesa_topic_reg tr
      JOIN csr.enhesa_reg r ON tr.reg_id = r.reg_id
      JOIN csr.enhesa_reg_text rt ON r.reg_id = rt.reg_id AND rt.lang = 'en'
    ;

CREATE OR REPLACE VIEW csr.v$est_error_description
AS
	SELECT est_error_id, help_text
	  FROM (
		SELECT est_error_id,
			   help_text,
			   ROW_NUMBER() OVER(PARTITION BY e.est_error_id ORDER BY e.error_code) ix
		  FROM csr.est_error e
		  LEFT JOIN csr.property p ON p.region_sid = e.region_sid
		  LEFT JOIN csr.est_space s ON s.pm_space_id = e.pm_space_id
		  LEFT JOIN csr.est_meter m ON m.pm_meter_id = e.pm_meter_id
		  LEFT JOIN csr.est_building b ON b.pm_building_id = e.pm_building_id
		  LEFT JOIN csr.property sp ON sp.region_sid = s.region_sid
		  LEFT JOIN csr.property mp ON mp.region_sid = m.region_sid
		  LEFT JOIN csr.property bp ON bp.region_sid = b.region_sid
		  LEFT JOIN csr.est_error_description ed
			ON e.error_code = ed.error_no
		   AND (e.request_url IS NULL OR
				ed.msg_pattern IS NULL OR
				REGEXP_LIKE(e.request_url, ed.url_pattern, 'i'))
		   AND (ed.msg_pattern IS NULL OR
				REGEXP_LIKE(e.error_message, ed.msg_pattern, 'i'))
		   AND ((ed.applies_to_space = 1 AND e.pm_space_id IS NOT NULL) OR
				(ed.applies_to_meter = 1 AND e.pm_meter_id IS NOT NULL) OR
				(ed.applies_to_push = 1 AND (
					p.energy_star_push = 1 OR
					sp.energy_star_push = 1 OR
					mp.energy_star_push = 1 OR
					bp.energy_star_push = 1)
				)
			)
	 )
	 WHERE ix = 1;

CREATE OR REPLACE VIEW CSR.V$EST_ERROR AS
	SELECT APP_SID, EST_ERROR_ID, REGION_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID, PM_BUILDING_ID, PM_SPACE_ID, PM_METER_ID,
		ERROR_LEVEL, ERROR_DTM, ERROR_CODE, ERROR_MESSAGE, REQUEST_URL, REQUEST_HEADER, REQUEST_BODY, RESPONSE
	  FROM CSR.EST_ERROR
	 WHERE ACTIVE = 1
	;
	
CREATE OR REPLACE VIEW csr.v$flow_capability AS
	SELECT NULL app_sid, flow_capability_id, flow_alert_class, description,
		   perm_type, default_permission_set, NULL lookup_key
	  FROM flow_capability
	 UNION
	SELECT app_sid, flow_capability_id, flow_alert_class, description,
		   perm_type, default_permission_set, lookup_key
	  FROM customer_flow_capability;

CREATE OR REPLACE VIEW CSR.V$PATCHED_METER_LIVE_DATA AS
	SELECT app_sid, region_sid, meter_input_id, aggregator, meter_bucket_id,
			priority, start_dtm, end_dtm, meter_raw_data_id, modified_dtm, consumption
	  FROM (
		SELECT mld.app_sid, mld.region_sid, mld.meter_input_id, mld.aggregator, mld.meter_bucket_id,
				mld.priority, mld.start_dtm, mld.end_dtm, mld.meter_raw_data_id, mld.modified_dtm, mld.consumption,
			ROW_NUMBER() OVER (PARTITION BY mld.app_sid, mld.region_sid, mld.meter_input_id, mld.aggregator, mld.meter_bucket_id, mld.start_dtm ORDER BY mld.priority DESC) rn
		  FROM csr.meter_live_data mld
	 )
	 WHERE rn = 1;

CREATE OR REPLACE VIEW csr.v$corp_rep_capability AS
	SELECT sec.app_sid, sec.section_sid, fsrc.flow_capability_id,
	   MAX(BITAND(fsrc.permission_set, 1)) + -- security_pkg.PERMISSION_READ
	   MAX(BITAND(fsrc.permission_set, 2)) permission_set -- security_pkg.PERMISSION_WRITE
	  FROM csr.section sec
	  JOIN csr.section_module secmod ON sec.app_sid = secmod.app_sid
	   AND sec.module_root_sid = secmod.module_root_sid 
	  JOIN csr.flow_item fi ON sec.app_sid = fi.app_sid 
	   AND sec.flow_item_id = fi.flow_item_id
	  JOIN csr.flow_state_role_capability fsrc ON fi.app_sid = fsrc.app_sid 
	   AND fi.current_state_id = fsrc.flow_state_id  
	  LEFT JOIN csr.region_role_member rrm ON sec.app_sid = rrm.app_sid 
	   AND secmod.region_sid = rrm.region_sid
	   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND rrm.role_sid = fsrc.role_sid
	 WHERE sec.active = 1
	   AND rrm.role_sid IS NOT NULL
	 GROUP BY sec.app_sid, sec.section_sid, fsrc.flow_capability_id;

CREATE OR REPLACE VIEW CSR.V$EST_METER_TYPE_MAPPING AS
	SELECT a.app_sid, a.est_account_sid, t.meter_type, m.meter_type_id
	  FROM csr.est_meter_type t
	  CROSS JOIN csr.est_account a
	  LEFT JOIN csr.est_meter_type_mapping m
			 ON a.app_sid = m.app_sid
			AND a.est_account_sid = m.est_account_sid
			AND t.meter_type = m.meter_type
;

CREATE OR REPLACE VIEW CSR.V$EST_CONV_MAPPING AS
	SELECT a.app_sid, a.est_account_sid, c.meter_type, c.uom, m.measure_sid, m.measure_conversion_id
	  FROM csr.est_meter_conv c
	  CROSS JOIN csr.est_account a
	  LEFT JOIN csr.est_conv_mapping m
			 ON a.app_sid = m.app_sid
			AND a.est_account_sid = m.est_account_sid
			AND c.meter_type = m.meter_type
			AND c.uom = m.uom
;

CREATE OR REPLACE VIEW csr.v$sso_log AS
    SELECT c.host AS saml_log_host, log.log_dtm AS log_dtm, log.saml_request_id AS saml_request_id,
           log.message_sequence AS message_sequence, log.message AS saml_log_msg,
           d.saml_assertion AS saml_log_data, c.app_sid AS app_sid
      FROM csr.customer c
      JOIN csr.saml_log log
        ON c.app_sid = log.app_sid
        JOIN (
            SELECT saml_request_id, log_dtm
              FROM (
                SELECT SAML_REQUEST_ID, LOG_DTM
                  FROM CSR.SAML_LOG
                 WHERE MESSAGE_SEQUENCE = 1
              ORDER BY LOG_DTM DESC
            )
        ) s
        ON s.saml_request_id = log.saml_request_id
 LEFT JOIN csr.saml_assertion_log d
        ON log.saml_request_id = d.saml_request_id
;

CREATE OR REPLACE VIEW csr.v$training_flow_item AS
     SELECT fi.app_sid, fi.flow_sid, fi.flow_item_id, 
			ut.user_sid,
			f.label flow_label,
			fs.flow_state_id current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key,
			fs.state_colour current_state_colour,
			fs.is_deleted flow_state_is_deleted,
			fi.last_flow_state_log_id, fi.last_flow_state_transition_id,
			fi.survey_response_id, fi.dashboard_instance_id,
			fs.flow_state_nature_id,
			fsn.label flow_state_nature,
			ut.course_id,
			ut.course_schedule_id
       FROM flow_item fi
	   JOIN flow f ON fi.flow_sid = f.flow_sid
	   JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
	   JOIN user_training ut ON fi.app_sid = ut.app_sid AND fi.flow_item_id = ut.flow_item_id
  LEFT JOIN flow_state_nature fsn ON fsn.flow_state_nature_id = fs.flow_state_nature_id;

CREATE OR REPLACE VIEW csr.v$training_line_manager AS  
	SELECT c.app_sid, c.course_id, c.course_type_id, ur.parent_user_sid line_manager_sid, ur.child_user_sid trainee_sid
	  FROM course c
	  JOIN course_type ct
			 ON ct.app_sid = c.app_sid
			AND ct.course_type_id = c.course_type_id
	 JOIN user_relationship ur
			 ON ur.app_sid = ct.app_sid
			AND ur.user_relationship_type_id = ct.user_relationship_type_id;

-- factor type, including whether it's active for the site and in use and mapped to an indicator.
CREATE OR REPLACE VIEW csr.v$factor_type AS
SELECT f.factor_type_id, f.parent_id, f.name, f.info_note, f.std_measure_id, f.egrid, af.active, uf.in_use, mf.mapped, f.enabled, f.visible
  FROM csr.factor_type f
  LEFT JOIN (
    SELECT factor_type_id, 1 mapped FROM (
          SELECT DISTINCT f.factor_type_id
            FROM csr.factor_type f
                 START WITH f.factor_type_id
                  IN (
              SELECT DISTINCT f.factor_type_id
                FROM csr.factor_type f
                JOIN csr.ind i ON i.factor_type_id = f.factor_type_id
                 AND i.app_sid = security.security_pkg.getApp
               WHERE std_measure_id IS NOT NULL
            )
          CONNECT BY PRIOR parent_id = f.factor_type_id
        )) mf ON f.factor_type_id = mf.factor_type_id
  LEFT JOIN (
    SELECT factor_type_id, 1 active FROM (
          SELECT DISTINCT af.factor_type_id
            FROM csr.factor_type af
           START WITH af.factor_type_id
            IN (
              SELECT DISTINCT aaf.factor_type_id
                FROM csr.factor_type aaf
                JOIN csr.std_factor sf ON sf.factor_type_id = aaf.factor_type_id
                JOIN csr.std_factor_set_active sfa ON sfa.std_factor_set_id = sf.std_factor_set_id
            )
           CONNECT BY PRIOR parent_id = af.factor_type_id
          UNION
          SELECT DISTINCT f.factor_type_id
            FROM csr.factor_type f
                 START WITH f.factor_type_id
                  IN (
              SELECT DISTINCT f.factor_type_id
                FROM csr.factor_type f
                JOIN csr.custom_factor sf ON sf.factor_type_id = f.factor_type_id
                 AND sf.app_sid = security.security_pkg.getApp
               WHERE std_measure_id IS NOT NULL
            )
          CONNECT BY PRIOR parent_id = f.factor_type_id
          UNION
          SELECT 3 factor_type_id -- factor_pkg.UNSPECIFIED_FACTOR_TYPE
            FROM dual
        )) af ON f.factor_type_id = af.factor_type_id
   LEFT JOIN (
    SELECT factor_type_id, 1 in_use FROM (
      SELECT factor_type_id
        FROM csr.factor_type
       START WITH factor_type_id
          IN (
          SELECT DISTINCT factor_type_id
            FROM csr.factor
           WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
      )
      CONNECT BY PRIOR parent_id = factor_type_id
      UNION
      SELECT DISTINCT f.factor_type_id
        FROM csr.factor_type f
             START WITH f.factor_type_id
              IN (
          SELECT DISTINCT f.factor_type_id
            FROM csr.factor_type f
            JOIN csr.custom_factor sf ON sf.factor_type_id = f.factor_type_id
             AND sf.app_sid = security.security_pkg.getApp
           WHERE std_measure_id IS NOT NULL
        )
      CONNECT BY PRIOR parent_id = f.factor_type_id
      UNION
      SELECT factor_type_id
        FROM csr.factor_type
       START WITH factor_type_id
          IN (
          SELECT DISTINCT factor_type_id
            FROM csr.factor
           WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
      )
      CONNECT BY PRIOR factor_type_id = parent_id
      UNION
      SELECT 3 factor_type_id -- factor_pkg.UNSPECIFIED_FACTOR_TYPE
        FROM dual
        )) uf ON f.factor_type_id = uf.factor_type_id;

create or replace view csr.v$scrag_usage as
select c.app_sid, c.host, case when msr.scenario_run_sid is null then 'val' when ms.file_based = 1 then 'scrag++' else 'scenario_run_val' end merged,
	   case when usr.scenario_run_sid is null then 'on the fly' when us.file_based = 1 then 'scrag++' else 'scenario_run_val' end unmerged,
	   nvl(spp_scenarios, 0) other_spp_scenarios, nvl(scenarios, 0) - nvl(spp_scenarios, 0) other_old_scenarios
  from csr.customer c
  left join csr.scenario_run msr on c.app_sid = msr.app_sid and c.merged_scenario_run_sid = msr.scenario_run_sid
  left join csr.scenario ms on ms.app_sid = msr.app_sid and ms.scenario_sid = msr.scenario_sid
  left join csr.scenario_run usr on c.app_sid = usr.app_sid and c.unmerged_scenario_run_sid = usr.scenario_run_sid
  left join csr.scenario us on us.app_sid = usr.app_sid and us.scenario_sid = usr.scenario_sid
  left join (select s.app_sid, sum(s.file_based) spp_scenarios, count(*) scenarios
			   from csr.scenario s
			  where (s.app_sid, s.scenario_sid) not in (
					select s.app_sid, s.scenario_sid
					  from csr.customer c
					  join csr.scenario_run sr on c.app_sid = sr.app_sid and c.merged_scenario_run_sid = sr.scenario_run_sid
					  join csr.scenario s on sr.app_sid = s.app_sid and sr.scenario_sid = s.scenario_sid
					 union all
					select s.app_sid, s.scenario_sid
					  from csr.customer c
					  join csr.scenario_run sr on c.app_sid = sr.app_sid and c.unmerged_scenario_run_sid = sr.scenario_run_sid
					  join csr.scenario s on sr.app_sid = s.app_sid and sr.scenario_sid = s.scenario_sid)
			  group by s.app_sid) o on c.app_sid = o.app_sid;

CREATE OR REPLACE VIEW CSR.V$METER_ORPHAN_DATA_SUMMARY AS
	SELECT od.app_sid, od.serial_id, od.meter_input_id, od.priority, ds.label,
		MIN(rd.received_dtm) created_dtm, MAX(rd.received_dtm) updated_dtm, 
		MIN(od.start_dtm) start_dtm, NVL(MAX(od.end_dtm), MAX(od.start_dtm)) end_dtm, 
		SUM(od.consumption) consumption,
		MAX(od.has_overlap) has_overlap,
		MAX(od.region_sid) region_sid,
		MAX(od.error_type_id) KEEP (DENSE_RANK LAST ORDER BY rd.received_dtm) error_type_id
	  FROM meter_orphan_data od
	  JOIN meter_raw_data rd ON rd.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND rd.meter_raw_data_id = od.meter_raw_data_id
	  JOIN meter_raw_data_source ds ON ds.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND ds.raw_data_source_id = rd.raw_data_source_id
	 WHERE od.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	 GROUP BY od.app_sid, od.serial_id, od.meter_input_id, od.priority, ds.label
;

CREATE OR REPLACE VIEW csr.v$compliance_item_rag AS 
	SELECT t.region_sid, t.total_items, t.compliant_items, t.pct_compliant, 
		TRIM(TO_CHAR ((
			SELECT DISTINCT FIRST_VALUE(text_colour)
			  OVER (ORDER BY st.max_value ASC) AS text_colour
			  FROM csr.compliance_options co
			  JOIN csr.score_threshold st ON co.score_type_id = st.score_type_id AND st.app_sid = co.app_sid
			 WHERE co.app_sid = security.security_pkg.GetApp
				 AND t.pct_compliant <= st.max_value
		), 'XXXXXX')) pct_compliant_colour
	FROM (
		SELECT app_sid, region_sid, total_items, compliant_items, DECODE(total_items, 0, 0, ROUND(100*compliant_items/total_items)) pct_compliant
		 FROM (
			SELECT cir.app_sid, cir.region_sid, COUNT(*) total_items, SUM(DECODE(fsn.label, 'Compliant', 1, 0)) compliant_items
				FROM csr.compliance_item_region cir
				JOIN csr.compliance_item ci ON cir.compliance_item_id = ci.compliance_item_id
				JOIN csr.flow_item fi ON fi.flow_item_id = cir.flow_item_id
				JOIN csr.flow_state fs ON fi.current_state_id = fs.flow_state_id
				LEFT JOIN csr.flow_state_nature fsn ON fsn.flow_state_nature_id = fs.flow_state_nature_id
			 WHERE fsn.flow_alert_class IN ('regulation', 'requirement')
				 AND lower(fsn.label) NOT IN ('retired', 'not applicable')
			 GROUP BY cir.app_sid, cir.region_sid
		)
		ORDER BY region_sid
	) t
;

CREATE OR REPLACE VIEW csr.v$my_compliance_items AS
	SELECT cir.compliance_item_id, cir.region_sid, cir.flow_item_id
	  FROM csr.compliance_item_region cir
	  JOIN csr.flow_item fi ON cir.app_sid = fi.app_sid AND cir.flow_item_id = fi.flow_item_id
	 WHERE  (EXISTS (
			SELECT 1
			  FROM csr.region_role_member rrm
			  JOIN csr.flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
			 WHERE rrm.app_sid = cir.app_sid
			   AND rrm.region_sid = cir.region_sid
			   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND fsr.flow_state_id = fi.current_state_id
		)
		OR EXISTS (
			SELECT 1
			  FROM csr.flow_state_role fsr
			  JOIN security.act act ON act.sid_id = fsr.group_sid
			 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
			   AND fsr.flow_state_id = fi.current_state_id
		)
	);

CREATE OR REPLACE VIEW csr.v$comp_item_rollout_location AS
	SELECT cir.app_sid, cir.compliance_item_id,
			listagg(pc.name, ', ') within GROUP(ORDER BY pc.name) AS countries,
			listagg(pr.name, ', ') within GROUP(order by pr.name) AS regions,
			listagg(rg.group_name, ', ') within GROUP(ORDER BY region_group_id) AS region_group_names,
			listagg(cg.group_name, ', ') within GROUP(ORDER BY country_group_id) AS country_group_names
	  FROM csr.compliance_item_rollout cir
	  LEFT JOIN postcode.country pc ON cir.country = pc.country
	  LEFT JOIN postcode.region pr ON cir.country = pr.country AND cir.region = pr.region
	  LEFT JOIN csr.region_group rg ON cir.region_group = rg.region_group_id
	  LEFT JOIN csr.country_group cg ON cir.country_group = cg.country_group_id
	 GROUP BY cir.app_Sid, cir.compliance_item_id
;

CREATE OR REPLACE VIEW csr.v$question AS
	SELECT qv.app_sid, qv.question_id, qv.question_version, qv.question_draft, qv.parent_id, qv.parent_version, qv.parent_draft, qv.label, qv.pos, qv.score, qv.max_score, qv.upload_score, 
		qv.weight, qv.dont_normalise_score, qv.has_score_expression, qv.has_max_score_expr, qv.remember_answer, qv.count_question, qv.action,
		q.owned_by_survey_sid, q.question_type, q.custom_question_type_id, q.lookup_key, q.maps_to_ind_sid, q.measure_sid
	  FROM csr.question_version qv
	  JOIN csr.question q ON q.question_id = qv.question_id AND q.app_sid = qv.app_sid;
  
CREATE OR REPLACE VIEW csr.v$quick_survey_question AS
	SELECT qsq.question_id, qsq.question_version, qsq.survey_sid, qsq.survey_version, qsq.is_visible, q.label, q.parent_id, q.parent_version, q.pos, 
	  q.score, q.max_score, q.upload_score, q.weight, q.dont_normalise_score, q.has_score_expression, q.has_max_score_expr, q.remember_answer, q.count_question, 
	  q.action,	q.owned_by_survey_sid, q.question_type, q.custom_question_type_id, q.lookup_key, q.maps_to_ind_sid, q.measure_sid
	  FROM csr.quick_survey_question qsq
	  JOIN csr.v$question q ON qsq.question_id = q.question_id AND qsq.question_version = q.question_version AND qsq.app_sid = q.app_sid AND qsq.question_draft = q.question_draft AND (q.owned_by_survey_sid IS NULL OR q.owned_by_survey_sid = qsq.survey_sid)
	 WHERE qsq.question_draft = 0;

CREATE OR REPLACE VIEW csr.v$permit_item_rag AS 
	SELECT t.region_sid, t.total_items, t.compliant_items, t.pct_compliant, 
		TRIM(TO_CHAR ((
			SELECT DISTINCT FIRST_VALUE(text_colour)
			  OVER (ORDER BY st.max_value ASC) AS text_colour
			  FROM csr.compliance_options co
			  JOIN csr.score_threshold st ON co.permit_score_type_id = st.score_type_id AND st.app_sid = co.app_sid
			 WHERE co.app_sid = security.security_pkg.GetApp
				 AND t.pct_compliant <= st.max_value
		), 'XXXXXX')) pct_compliant_colour
	FROM (
		SELECT app_sid, region_sid, total_items, compliant_items, DECODE(total_items, 0, 0, ROUND(100*compliant_items/total_items)) pct_compliant
		 FROM (
		 SELECT cp.app_sid, cp.region_sid, SUM(DECODE(cpc.condition_type_id, NULL, NULL, 1)) total_items, SUM(DECODE(LOWER(fsn.label), 'compliant', 1, 0)) compliant_items
		  FROM csr.compliance_permit cp
		  LEFT JOIN csr.compliance_permit_condition cpc ON cpc.compliance_permit_id = cp.compliance_permit_id
		  LEFT JOIN csr.compliance_item_region cir ON cpc.compliance_item_id = cir.compliance_item_id
		  LEFT JOIN csr.flow_item fi ON fi.flow_item_id = cir.flow_item_id
		  LEFT JOIN csr.flow_state fs ON fi.current_state_id = fs.flow_state_id
		  LEFT JOIN csr.flow_state_nature fsn ON fsn.flow_state_nature_id = fs.flow_state_nature_id
		 WHERE lower(fsn.label) != 'inactive'
		 GROUP BY cp.app_sid, cp.region_sid
		)
		ORDER BY region_sid
	) t;

CREATE OR REPLACE VIEW csr.v$current_raw_compl_perm_score AS
	SELECT 
		   compliance_permit_id, score_type_id, compliance_permit_score_id,
		   score_threshold_id, score, is_override, set_dtm, valid_until_dtm, 
		   comment_text, changed_by_user_sid, score_source_type, score_source_id
	  FROM compliance_permit_score cps
	 WHERE cps.set_dtm <= SYSDATE
	   AND (cps.valid_until_dtm IS NULL OR cps.valid_until_dtm > SYSDATE)
	   AND cps.is_override = 0
	   AND NOT EXISTS (
			SELECT NULL
			  FROM compliance_permit_score cps2
			 WHERE cps2.app_sid = cps.app_sid
			   AND cps2.compliance_permit_id = cps.compliance_permit_id
			   AND cps2.score_type_id = cps.score_type_id
			   AND cps2.is_override = 0
			   AND cps2.set_dtm > cps.set_dtm
			   AND cps2.set_dtm <= SYSDATE
		);

CREATE OR REPLACE VIEW csr.v$current_ovr_compl_perm_score AS
	SELECT 
		   compliance_permit_id, score_type_id, compliance_permit_score_id,
		   score_threshold_id, score, is_override, set_dtm, valid_until_dtm, 
		   comment_text, changed_by_user_sid, score_source_type, score_source_id
	  FROM compliance_permit_score cps
	 WHERE cps.set_dtm <= SYSDATE
	   AND (cps.valid_until_dtm IS NULL OR cps.valid_until_dtm > SYSDATE)
	   AND cps.is_override = 1
	   AND NOT EXISTS (
			SELECT NULL
			  FROM compliance_permit_score cps2
			 WHERE cps2.app_sid = cps.app_sid
			   AND cps2.compliance_permit_id = cps.compliance_permit_id
			   AND cps2.score_type_id = cps.score_type_id
			   AND cps2.is_override = 1
			   AND cps2.set_dtm > cps.set_dtm
			   AND cps2.set_dtm <= SYSDATE
		);
		
CREATE OR REPLACE VIEW csr.v$current_compl_perm_score_all AS
	SELECT 
		   compliance_permit_id, score_type_id, 
		   --
		   MAX(compliance_permit_score_id) raw_compliance_permit_score_id, 
		   MAX(score_threshold_id) raw_score_threshold_id, 
		   MAX(score) raw_score, 
		   MAX(set_dtm) raw_set_dtm, 
		   MAX(valid_until_dtm) raw_valid_until_dtm, 
		   MAX(changed_by_user_sid) raw_changed_by_user_sid, 
		   MAX(score_source_type) raw_score_source_type, 
		   MAX(score_source_id) raw_score_source_id, 
		   --
		   MAX(ovr_compliance_permit_score_id) ovr_compliance_permit_score_id, 
		   MAX(ovr_score_threshold_id) ovr_score_threshold_id, 
		   MAX(ovr_score) ovr_score, 
		   MAX(ovr_set_dtm) ovr_set_dtm, 
		   MAX(ovr_valid_until_dtm) ovr_valid_until_dtm,  
		   MAX(ovr_changed_by_user_sid) ovr_changed_by_user_sid, 
		   MAX(ovr_score_source_type) ovr_score_source_type, 
		   MAX(ovr_score_source_id) ovr_score_source_id
	  FROM (
			SELECT 
				   compliance_permit_id, score_type_id, 
				   --
				   compliance_permit_score_id, score_threshold_id, score, is_override, set_dtm, valid_until_dtm, 
				   changed_by_user_sid, score_source_type, score_source_id, 
				   --
				   NULL ovr_compliance_permit_score_id, NULL ovr_score_threshold_id, NULL ovr_score, NULL ovr_is_override, NULL ovr_set_dtm, NULL ovr_valid_until_dtm, 
				   NULL ovr_changed_by_user_sid, NULL ovr_score_source_type, NULL ovr_score_source_id
			  FROM v$current_raw_compl_perm_score
			 UNION ALL
			SELECT 
				   compliance_permit_id, score_type_id, 
				   --
				   NULL compliance_permit_score_id, NULL score_threshold_id, score, NULL is_override, NULL set_dtm, NULL valid_until_dtm, 
				   NULL changed_by_user_sid, NULL score_source_type, NULL score_source_id, 
				   --
				   compliance_permit_score_id ovr_compliance_permit_score_id, score_threshold_id ovr_score_threshold_id, score ovr_score, is_override ovr_is_override,
				   set_dtm ovr_set_dtm, valid_until_dtm ovr_valid_until_dtm, changed_by_user_sid ovr_changed_by_user_sid, score_source_type ovr_score_source_type, 
				   score_source_id ovr_score_source_id
			  FROM v$current_ovr_compl_perm_score
	)
	GROUP BY compliance_permit_id, score_type_id; 

CREATE OR REPLACE VIEW csr.v$current_compl_perm_score AS
	SELECT 
		   compliance_permit_id, score_type_id, 
		   --
		   NVL(ovr_score_threshold_id, raw_score_threshold_id) score_threshold_id, 
		   NVL(ovr_score, raw_score) score, 
		   NVL2(ovr_score, ovr_set_dtm, raw_set_dtm) set_dtm, 
		   NVL2(ovr_score, ovr_valid_until_dtm, raw_valid_until_dtm) valid_until_dtm, 
		   NVL2(ovr_score, ovr_changed_by_user_sid, raw_changed_by_user_sid) changed_by_user_sid, 
		   NVL2(ovr_score, ovr_score_source_type, raw_score_source_type) score_source_type, 
		   NVL2(ovr_score, ovr_score_source_id, raw_score_source_id) score_source_id
	  FROM v$current_compl_perm_score_all;

/* Materialized views */
GRANT CREATE TABLE TO CSR;
BEGIN
	EXECUTE IMMEDIATE 'DROP materialized VIEW csr.meter_param_cache';
EXCEPTION
	WHEN OTHERS THEN NULL;
END;
/

CREATE materialized view csr.meter_param_cache REFRESH FORCE ON DEMAND
START WITH TO_DATE('01-01-2021 00:01:00', 'DD-MM-YYYY HH24:MI:SS') NEXT SYSDATE + 1
AS
	SELECT app_sid, MIN(mld.start_dtm) min_start_date, MAX(mld.start_dtm) max_start_date
	  FROM csr.meter_live_data mld
	 GROUP BY app_sid;

REVOKE CREATE TABLE FROM CSR;