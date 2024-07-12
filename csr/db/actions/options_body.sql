CREATE OR REPLACE PACKAGE BODY ACTIONS.options_pkg
IS

PROCEDURE GetOptions(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading app sid '||in_app_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT app_sid, show_regions, restrict_by_region, browse_shows_children, 
			aggregate_task_tree, show_weightings, show_action_type, greyout_unassoc_tasks, 
			allow_perf_override, allow_parent_override, use_actions_v2, show_task_period_pct,
			default_value_script_id, action_grid_path, aggr_action_grid_path,
			initiative_end_dtm, region_picker_config, use_standard_region_picker, 
			initiative_name_gen_proc, initiative_hide_ongoing_radio, gantt_period_colour,
			my_initiatives_options, auto_complete_date
		  FROM customer_options
		 WHERE app_sid = in_app_sid;
END;

PROCEDURE GetScript(
	in_script_id	IN	script.script_id%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT script_id, script 
		  FROM script
		 WHERE script_id = in_script_id;
END;

END options_pkg;
/
