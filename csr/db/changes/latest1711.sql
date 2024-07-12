-- Please update version.sql too -- this keeps clean builds in sync
define version=1711
@update_header

DECLARE
	v_count			number(10);
	TYPE t_idxs IS TABLE OF VARCHAR2(4000);
	v_list t_idxs := t_idxs(
		'create index csr.ix_alert_mail_to_company_si on csr.alert_mail (app_sid, to_company_sid)',
		'create index csr.ix_all_meter_demand_ind_si on csr.all_meter (app_sid, demand_ind_sid)',
		'create index csr.ix_all_meter_demand_measur on csr.all_meter (app_sid, demand_measure_conversion_id)',
		'create index csr.ix_dataview_tren_ind_sid on csr.dataview_trend (app_sid, ind_sid)',
		'create index csr.ix_deleg_report__deleg_plan_si on csr.deleg_report_deleg_plan (app_sid, deleg_plan_sid)',
		'create index csr.ix_deleg_report__root_region_s on csr.deleg_report_region (app_sid, root_region_sid)',
		'create index csr.ix_dataview_tren_region_sid on csr.dataview_trend (app_sid, region_sid)',
		'create index csr.ix_dataview_tren_dataview_sid on csr.dataview_trend (app_sid, dataview_sid)',
		'create index csr.ix_est_building_region_sid on csr.est_building (app_sid, region_sid)',
		'create index csr.ix_est_energy_me_region_sid on csr.est_energy_meter (app_sid, region_sid)',
		'create index csr.ix_est_space_region_sid on csr.est_space (app_sid, region_sid)',
		'create index csr.ix_est_water_met_region_sid on csr.est_water_meter (app_sid, region_sid)',
		'create index csr.ix_imp_val_set_region_me on csr.imp_val (app_sid, set_region_metric_val_id)',
		'create index csr.ix_issue_custom__issue_state_i on csr.issue_custom_field_state_perm (issue_state_id)',
		'create index csr.ix_issue_type_st_issue_state_i on csr.issue_type_state_perm (issue_state_id)',
		'create index csr.ix_meter_ind_days_ind_sid on csr.meter_ind (app_sid, days_ind_sid)',
		'create index csr.ix_meter_ind_demand_ind_si on csr.meter_ind (app_sid, demand_ind_sid)',
		'create index csr.ix_meter_ind_costdays_ind_ on csr.meter_ind (app_sid, costdays_ind_sid)',
		'create index csr.ix_meter_ind_cost_ind_sid on csr.meter_ind (app_sid, cost_ind_sid)',
		'create index csr.ix_model_instanc_model_instanc on csr.model_instance_region (app_sid, model_instance_sid, base_model_sid)',
		'create index csr.ix_quick_survey__question_id_q on csr.quick_survey_answer (app_sid, question_id, question_option_id)',
		'create index csr.ix_route_step_vo_user_sid on csr.route_step_vote (app_sid, user_sid)',
		'create index csr.ix_route_step_vo_dest_route_st on csr.route_step_vote (app_sid, dest_route_step_id)',
		'create index csr.ix_route_step_vo_dest_flow_sta on csr.route_step_vote (app_sid, dest_flow_state_id)',
		'create index csr.ix_sheet_value_set_by_user_s on csr.sheet_value (app_sid, set_by_user_sid)',
		'create index csr.ix_worksheet_worksheet_typ on csr.worksheet (worksheet_type_id)',
		'create index csr.ix_worksheet_col_column_type_i on csr.worksheet_column (column_type_id)',
		'create index csr.ix_worksheet_col_value_mapper_ on csr.worksheet_column_type (value_mapper_id)',
		'create index csr.ix_worksheet_col_worksheet_typ on csr.worksheet_column_type (worksheet_type_id)',
		'create index csr.ix_worksheet_col_value_map_id_ on csr.worksheet_column_value_map (app_sid, value_map_id, value_mapper_id, column_type_id)',
		'create index csr.ix_worksheet_val_value_mapper_ on csr.worksheet_value_map (value_mapper_id)',
		'create index csr.ix_worksheet_val_column_type_i on csr.worksheet_value_map_value (column_type_id)'
	);
BEGIN
	FOR i IN 1 .. v_list.count 
	LOOP
		BEGIN
			EXECUTE IMMEDIATE v_list(i);
		EXCEPTION
			WHEN OTHERS THEN
				NULL;
		END;
	END LOOP;
END;
/

@update_tail
