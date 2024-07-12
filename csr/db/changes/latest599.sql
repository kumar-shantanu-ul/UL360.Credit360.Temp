-- Please update version.sql too -- this keeps clean builds in sync
define version=599
@update_header

-- more unindexed fks
create index csr.ix_approval_step_model_sid on csr.approval_step_model (app_sid, model_sid);
create index csr.ix_approval_step_user_sid on csr.approval_step_sheet_alert (app_sid, user_sid);
create index csr.ix_csr_user_csr_user_sid on csr.csr_user (csr_user_sid);
create index csr.ix_factor_geo_country on csr.factor (geo_country);
create index csr.ix_imp_conflict_ind_sid on csr.imp_conflict (app_sid, ind_sid);
create index csr.ix_imp_conflict_region_sid on csr.imp_conflict (app_sid, region_sid);
create index csr.ix_ind_gas_type_id on csr.ind (gas_type_id);
create index csr.ix_selected_axis_axis_member_i on csr.selected_axis_task (app_sid, axis_member_id, action_tag_id);
create index csr.ix_selected_axis_reporting_per on csr.selected_axis_task (app_sid, reporting_period_sid);
create index csr.ix_selected_axis_task_sid_acti on csr.selected_axis_task (app_sid, task_sid, action_tag_id);
create index csr.ix_supplier_logo_file_sid on csr.supplier (logo_file_sid);
create index csr.ix_tab_portlet_u_csr_user_sid on csr.tab_portlet_user_state (app_sid, csr_user_sid);

@update_tail
