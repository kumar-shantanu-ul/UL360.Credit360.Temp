CREATE OR REPLACE PACKAGE BODY CSR.dataset_legacy_pkg AS

PROCEDURE GetRegionTags(
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT region_sid, tag_id
		  FROM region_tag
		 WHERE app_sid = in_app_sid;
END;


PROCEDURE GetReportingPeriods(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT DISTINCT reporting_period_sid, name, start_dtm, end_dtm 
          FROM reporting_period
         WHERE app_sid = in_app_sid;
END;

PROCEDURE GetCustomerFields(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid 						IN	security_pkg.T_SID_ID,
    out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		-- it seems a seriously bad idea to copy these since we end up dumping stuff into the wrong outbox.
		--system_mail_address, tracker_mail_address, 
		SELECT alert_mail_address, alert_mail_name, contact_email,
			   ind_info_xml_fields, region_info_xml_fields, user_info_xml_fields, 
			   status, current_reporting_period_sid, lock_start_dtm, lock_end_dtm,
			   use_tracker, audit_calc_changes, use_user_sheets, allow_val_edit, calc_sum_zero_fill,
			   fully_hide_sheets, create_sheets_at_period_end, target_line_col_from_gradient, 
			   use_carbon_emission, allow_deleg_plan
		  FROM customer
		 WHERE app_sid = in_app_sid;
END;

PROCEDURE GetAccuracyTypes(
	in_act_id							IN	security_pkg.T_ACT_ID,
	in_app_sid							IN	security_pkg.T_SID_ID,
	out_cur								OUT	SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT accuracy_type_id, label, q_or_c, max_score
          FROM accuracy_type
         WHERE app_sid = in_app_sid;
END;

PROCEDURE GetAccuracyTypeOptions(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_cur FOR
		SELECT accuracy_type_option_id, ato.accuracy_type_id, ato.label, accuracy_weighting
		  FROM accuracy_type_option ato, accuracy_type aty
		 WHERE ato.accuracy_type_id = aty.accuracy_type_Id
		   AND aty.app_sid = in_app_sid;
END;

PROCEDURE GetTranslationSets(
	in_act							IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT lang, hidden
		  FROM aspen2.translation_set
		 WHERE application_sid = in_app_sid;
END;

PROCEDURE GetTags(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR		   
   		SELECT t.tag_id, t.tag, t.explanation
		  FROM v$tag t, tag_group_member tgm, tag_group tg
		 WHERE t.tag_id = tgm.tag_id
		   AND tgm.tag_group_id = tg.tag_group_id
		   AND tg.app_sid = in_app_sid;
END;

PROCEDURE GetTagGroups(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT tag_group_id, name, multi_select, mandatory, applies_to_inds, applies_to_regions 
		  FROM v$tag_group
		 WHERE app_sid = in_app_sid;
END;

PROCEDURE GetTagGroupMembers(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR		   
   		SELECT tgm.tag_group_id, tag_id, pos
		  FROM tag_group_member tgm, tag_group tg
		 WHERE tgm.tag_group_id = tg.tag_group_id
		   AND tg.app_sid = in_app_sid;
END;		   

PROCEDURE GetMeasures(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT measure_sid, name, description, scale, format_mask, custom_field, std_measure_conversion_id, pct_ownership_applies
		  FROM measure 
		 WHERE app_sid = in_app_sid;
END;

PROCEDURE GetMeasureConversions(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT mc.measure_conversion_id, mc.measure_sid, mc.description, mc.a, mc.b, mc.c
		  FROM measure_conversion mc, measure m 
		 WHERE mc.measure_sid = m.measure_sid 
		   AND m.app_sid = in_app_sid;
END;

PROCEDURE GetMeasureConversionPeriods(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT mcp.measure_conversion_id, mcp.start_dtm, mcp.end_dtm, mcp.a, mcp.b, mcp.c
 		  FROM measure_conversion_period mcp, measure_conversion mc, measure m 
 		 WHERE mcp.measure_conversioN_id = mc.measure_conversion_id
  		   AND mc.measure_sid = m.measure_sid 
  		   AND m.app_sid = in_app_sid;
END;

PROCEDURE GetIndicators(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_ind_cur						OUT	SYS_REFCURSOR
)
AS
	v_ind_root_sid	security_pkg.T_SID_ID;
BEGIN
	-- figure out ind root sid
	SELECT ind_root_sid
	  INTO v_ind_root_sid
	  FROM customer
	 WHERE app_sid = in_app_sid;
		
	-- store all our indicator sids for use in other queries
	SELECT ind_sid
	       BULK COLLECT INTO m_ind_sids
	  FROM ind
	 WHERE app_sid = in_app_sid
		   START WITH app_sid = in_app_sid AND parent_sid = v_ind_root_sid
	 	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR ind_sid = parent_sid;
		
	-- we want parents that aren't inds (i.e the root node) to return null
	OPEN out_ind_cur FOR
		SELECT i.ind_sid, DECODE(i.parent_sid, v_ind_root_sid, null, i.parent_sid) parent_sid, i.name, id.description, 
			   i.lookup_key, i.measure_sid, i.multiplier, i.scale, i.format_mask, i.last_modified_dtm, 
			   i.active, i.gri, i.target_direction, i.pos, i.ind_type, i.start_month, 
			   NVL(i.divisibility, m.divisibility) divisibility, i.aggregate, i.calc_start_dtm_adjustment,
			   i.calc_end_dtm_adjustment, i.period_set_id, i.period_interval_id, i.do_temporal_aggregation,
			   i.calc_description, i.info_xml, i.calc_xml,
			   i.pct_lower_tolerance, i.pct_upper_tolerance, i.tolerance_type, i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average, 
			   i.ind_activity_type_id, i.core, i.factor_type_Id, i.gas_measure_sid, i.gas_type_id, 
			   i.map_to_ind_sid, i.roll_forward, i.normalize, i.prop_down_region_tree_sid, i.is_system_managed,
			   i.calc_fixed_start_dtm, i.calc_fixed_end_dtm, i.calc_output_round_dp,			   
			   CASE WHEN rm.ind_sid IS NOT NULL THEN 1 ELSE 0 END is_region_metric
		  FROM (SELECT app_sid, ind_sid, parent_sid, name, lookup_key, measure_sid, multiplier, scale, format_mask,
		  			   last_modified_dtm, active, gri, target_direction, pos, ind_type, start_month,
		  			   divisibility, aggregate, calc_start_dtm_adjustment, calc_end_dtm_adjustment,
					   period_set_id, period_interval_id,
		  			   do_temporal_aggregation, calc_description, info_xml, calc_xml, pct_lower_tolerance,
		  			   pct_upper_tolerance, tolerance_type, tolerance_number_of_periods, tolerance_number_of_standard_deviations_from_average, ind_activity_type_id, core, factor_type_id,
		  			   gas_measure_sid, gas_type_id, map_to_ind_sid, roll_forward, normalize,
		  			   prop_down_region_tree_sid, is_system_managed, calc_fixed_start_dtm,
		  			   calc_fixed_end_dtm, calc_output_round_dp
		  		  FROM ind
				  	   START WITH app_sid = in_app_sid AND parent_sid = v_ind_root_sid
				  	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR ind_sid = parent_sid) i
		  JOIN ind_description id
	 	 	ON id.app_sid = i.app_sid and i.ind_sid = id.ind_sid 
	   	   AND id.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
		  LEFT JOIN measure m ON i.app_sid = m.app_sid AND i.measure_sid = m.measure_sid
		  LEFT JOIN region_metric rm ON i.app_sid = rm.app_sid AND i.ind_sid = rm.ind_sid
		 WHERE i.app_sid = in_app_sid;
END;

PROCEDURE GetIndicatorTags(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF m_ind_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetIndicators first');
	END IF;
	OPEN out_cur FOR
   		SELECT it.tag_id, it.ind_sid
		  FROM ind_tag it, tag t, tag_group_member tgm, tag_group tg, TABLE(m_ind_sids) i
		 WHERE it.tag_id = t.tag_id
		   AND t.tag_id = tgm.tag_id
		   AND tgm.tag_group_id = tg.tag_group_id
		   AND it.ind_sid = i.column_value
		   AND tg.app_sid = in_app_sid;
END;


PROCEDURE GetIndAccuracyTypes(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF m_ind_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetIndicators first');
	END IF;
    OPEN out_cur FOR
        SELECT ind_sid, accuracy_type_id
          FROM ind_accuracy_type
         WHERE ind_sid IN (
            SELECT column_value
              FROM TABLE(m_ind_sids) 
          );
END;

PROCEDURE GetIndOther(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_validation_rule				OUT	SYS_REFCURSOR	
)
AS
BEGIN
	IF m_ind_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetIndicators first');
	END IF;
	
	OPEN out_validation_rule FOR
		SELECT ind_validation_rule_id, ind_sid, expr, message, position, type  
		  FROM ind_validation_rule, TABLE(m_ind_sids) i
		 WHERE ind_sid = i.column_value;
END;

END;
/
